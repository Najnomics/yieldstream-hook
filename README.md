# YieldStream Hook

YieldStream is a Uniswap v4 hook that turns LP fee income into a tradable fixed-income primitive. On deposit, an LP receives two ERC-20 claims for the current epoch:

- **FYT**, the Future Yield Token, claims the epoch's swap fees.
- **PT**, the Principal Token, claims the LP capital after settlement.

LPs can sell FYT upfront for fixed liquidity while retaining PT. FYT buyers get pure exposure to pool fee generation. PT holders keep the LP capital and impermanent-loss exposure.

## What Is Built

```text
src/
  YieldStreamHook.sol
  tokens/FutureYieldToken.sol
  tokens/PrincipalToken.sol
  tokens/YieldStreamTokenFactory.sol
  rsc/YieldStreamRSC.sol
  adapters/MorphoAdapter.sol
test/
  YieldStreamHook.t.sol
  YieldStreamIntegration.t.sol
  YieldStreamFuzz.t.sol
  YieldStreamFork.t.sol
script/
  DemoYieldStream.s.sol
  DemoYieldStreamSetup.s.sol
  DemoYieldStreamSettleRedeem.s.sol
  demo-with-txids.sh
  MineHookAddress.s.sol
  Deploy.s.sol
frontend/
  Vite + React + TypeScript judge UI
```

## Core Flow

```text
LP deposits through the hook-managed liquidity entrypoint
  -> hook owns the v4 liquidity position
  -> hook mints FYT + PT
  -> LP transfers/sells FYT
  -> fee reporter transfers backed fees and emits FeesAccrued
  -> Reactive Network RSC queues settlement callback
  -> hook removes its managed v4 liquidity at settlement
  -> FYT holder redeems fees
  -> PT holder redeems principal
```

## Hook Permissions

YieldStream enables only:

- `afterAddLiquidity`
- `beforeRemoveLiquidity`
- `afterSwap`

It deliberately does not enable return-delta permissions.

## Setup

```bash
forge build
forge test -vvv
```

Frontend:

```bash
cd frontend
npm install
npm run build
npm run dev -- --port 5173
```

## Tests

```bash
forge fmt
forge test -vvv
forge coverage --ir-minimum
forge coverage --ir-minimum --report lcov
```

Current suite covers:

- epoch creation and boundaries
- hook-owned managed liquidity accounting
- FYT/PT minting
- liquidity-block FYT weighting
- backed fee reporting and fee accrual events
- RSC settlement callback payloads
- RSC post-boundary settlement for the observed epoch after idle gaps
- restricted and permissionless settlement
- FYT/PT redemption and token transferability
- LP lockup
- Morpho adapter guardrails
- fuzzed fee and PT redemption invariants
- fork harness activation when `MAINNET_RPC_URL` is configured

Coverage uses `--ir-minimum`; plain `forge coverage` hits a Solidity `stack too deep` path in the hook under coverage compilation. Current coverage is not claimed as exact 100%: the critical hook, token, RSC, adapter, lifecycle, and fuzz paths are covered, while some script/demo and defensive paths remain uncovered. See [Testing](docs/TESTING.md).

Latest project-owned coverage highlights:

| File | Lines | Functions |
|------|-------|-----------|
| `src/YieldStreamHook.sol` | 87.77% | 78.57% |
| `src/adapters/MorphoAdapter.sol` | 93.75% | 100.00% |
| `src/rsc/YieldStreamRSC.sol` | 95.65% | 100.00% |
| `src/tokens/FutureYieldToken.sol` | 93.75% | 100.00% |
| `src/tokens/PrincipalToken.sol` | 93.75% | 100.00% |

## Current Testnet Deployments

Short-epoch demo deployments use `epochLength = 20` blocks and are intended for judging and investor demos.

| Network | Hook | TokenFactory | MorphoAdapter | Lasna RSC |
|---------|------|--------------|---------------|-----------|
| Base Sepolia | `0x4DeEB34Db482d776e043539394Fa70b772890640` | `0xF6E0AC636cDb1dacfE68D758CAa880b5A09f0a98` | `0xDa24f7eaB509aad5EdE5aa6c762CefAbcdfF0f47` | `0xD4342b1B631a5a465E09b81d1b99E6438c61d453` |
| Unichain Sepolia | `0x4C7734FfB1C9F054E1b16f1BBdcD9aEa98E80640` | `0x97bf008af093831Aa3CCde2565c2de89d52643a5` | `0xf15CE9D5855CDFFeF4a9F9AbdC013Dc07cb3F0cD` | `0xf9C557b4097f399dBa99EB1DB2caf5fc7ADfE786` |

Both Lasna RSCs use the legacy Reactive endpoint/library, subscribe to the hook `FeesAccrued(uint256,uint256,uint256)` event, and were explicitly subscription-configured on Lasna after deployment.

## Demo

Fast simulation:

```bash
forge script script/DemoYieldStream.s.sol -vvv
```

The demo simulates Alice depositing LP capital, Alice transferring FYT to Bob, swaps accruing fees, epoch settlement, Bob redeeming FYT fees, and Alice redeeming PT principal.

Judge-facing broadcast demo with txids:

```bash
YIELDSTREAM_E2E_NETWORK=base bash script/testnet-demo-with-txids.sh
```

The testnet runner broadcasts against deployed testnet contracts, prints labeled destination and Lasna transaction ids, waits for the short demo epoch boundary, emits a second `FeesAccrued`, and then watches for Reactive settlement. Use `YIELDSTREAM_E2E_NETWORK=unichain` for Unichain Sepolia.

## Frontend

The frontend is a judge-facing lifecycle simulator:

- pool and epoch dashboard
- add liquidity action
- FYT transfer action
- fee accrual action
- settlement action
- FYT/PT redemption
- risk split between FYT buyers and PT holders

Local URL when running:

```text
http://127.0.0.1:5173/
```

## Reactive Network Notes

`YieldStreamRSC.sol` follows the local Reactive docs/examples and is deployed on Lasna for the Unichain Sepolia and Base Sepolia hooks:

- inherits `AbstractReactive`
- subscribes to `FeesAccrued(uint256,uint256,uint256)`
- processes `IReactive.LogRecord`
- emits `Callback(destinationChainId, hook, gasLimit, payload)`

Reactive callback payloads include the RVM identity as the first argument, so the hook exposes:

```solidity
settleEpochFromReactive(address rvmId, uint256 epochId)
```

The hook authorizes live callbacks with `msg.sender == callbackProxy && rvmId == reactiveSender`. It also exposes `settleEpoch(uint256)` for the configured direct settlement caller and `triggerSettlement(uint256)` as an idle-pool fallback after epoch end.

## Morpho Notes

`MorphoAdapter.sol` remains deployed and tested as an integration adapter. The current deployable hook keeps Morpho out of its runtime settlement path so the hook stays comfortably below the EIP-170 contract size limit after adding hook-owned v4 liquidity custody. Morpho routing is documented as a next integration step rather than claimed as live PT backing in these deployments.

## Known Limitations

- Testnet fee accrual uses `reportFees(...)`: a restricted fee reporter must transfer real token backing into the hook before `FeesAccrued` is emitted. This is secure for the demo path, but final production fee accounting should be integrated with the exact v4 fee capture mechanism selected for launch.
- Morpho capital routing is not part of the current hook settlement path; the adapter is deployed and tested separately.
- Fork test is environment-gated and activates when `MAINNET_RPC_URL` is set.
- npm currently reports two moderate frontend dependency advisories; no forced breaking upgrade was applied.

## More Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Testing](docs/TESTING.md)
- [Demo](docs/DEMO.md)
- [E2E txid ledger](docs/e2e.md)
- [Deployments](docs/DEPLOYMENTS.md)
- [Specification](SPEC.md)

## Author

Najnomics
