# YieldStream Hook

> A Uniswap v4 hook that turns LP fee income into tradable, epoch-scoped fixed-income claims.

YieldStream splits a hook-managed Uniswap v4 LP position into two transferable ERC-20 claims:

- **FYT**, the Future Yield Token, represents a claim on an epoch's fee stream.
- **PT**, the Principal Token, represents a claim on the LP capital after epoch settlement.

The goal is to make LP yield sellable, priceable, and separable from principal. LPs can sell FYT upfront to lock in immediate liquidity while keeping PT. FYT buyers get direct exposure to pool fee generation. PT holders keep the LP capital exposure, including impermanent-loss risk.

This repository contains the contracts, Reactive Network integration, Foundry tests, deployment scripts, testnet proof runs, and a judge-facing frontend simulator for the YieldStream Hook demo.

## Why YieldStream Exists

Uniswap LPs take on several risks at once:

- Fee revenue is variable and hard to price forward.
- Fee income cannot easily be sold separately from the LP position.
- LP capital remains exposed to price movement and impermanent loss.

YieldStream separates those exposures. FYT buyers underwrite fee variability. PT holders retain capital exposure. Holding both FYT and PT remains economically similar to holding the original LP position through the epoch, while selling FYT converts uncertain future fees into upfront liquidity.

## What Is Built

The current implementation is a working demo-grade protocol build with:

- A Uniswap v4 `BaseHook` implementation.
- Hook-managed liquidity custody for demo deposits.
- Epoch-scoped FYT and PT ERC-20 token creation.
- Liquidity-block weighting so earlier LPs receive more FYT per unit of liquidity than later LPs.
- Backed testnet fee reporting through a restricted fee reporter.
- Reactive Network settlement on Lasna testnet.
- Base Sepolia and Unichain Sepolia demo deployments.
- Live end-to-end txid proofs showing origin events, Lasna RVM processing, queued callbacks, and destination `EpochSettled` callbacks.
- Foundry unit, integration, fuzz, fork-gated, and adapter tests.
- A Vite/React frontend simulator for judging and walkthroughs.

## Current Status

| Area | Status |
|------|--------|
| Hook core | Implemented and tested |
| FYT/PT tokenization | Implemented and tested |
| Hook-owned liquidity accounting | Implemented and tested |
| Reactive settlement | Live on Lasna for Base Sepolia and Unichain Sepolia demos |
| Testnet proof | Completed with destination callback txids |
| Morpho adapter | Deployed/tested as an adapter, not active in live hook settlement |
| Production fee capture | Not finalized; demo uses restricted, backed fee reporting |
| Mainnet deployment | Not live |

## How It Works

```text
LP deposits through YieldStream's managed-liquidity entrypoint
  -> YieldStreamHook owns and tracks the v4 liquidity position
  -> hook mints FYT and PT for the active epoch
  -> LP can hold or sell FYT/PT
  -> fee reporter transfers real token backing and emits FeesAccrued
  -> YieldStreamRSC observes FeesAccrued on Reactive Network
  -> after the epoch boundary, the RSC queues a settlement callback
  -> Reactive callback proxy calls settleEpochFromReactive(...)
  -> hook settles fees and principal accounting
  -> FYT holders redeem fees
  -> PT holders redeem capital
```

## Architecture

```text
User / Demo Actor
  |
  v
YieldStreamHook.sol
  |-- owns hook-managed v4 liquidity
  |-- starts and settles epochs
  |-- mints FYT/PT through YieldStreamTokenFactory
  |-- accepts backed fee reports
  |-- validates Reactive callback proxy + RVM identity
  |
  |--> FutureYieldToken.sol
  |--> PrincipalToken.sol
  |--> MorphoAdapter.sol
  |
  v
FeesAccrued(epochId, amount0, amount1)
  |
  v
YieldStreamRSC.sol on Lasna
  |-- subscribes to FeesAccrued
  |-- reads IReactive.LogRecord
  |-- queues Callback(destinationChainId, hook, gasLimit, payload)
  |
  v
Destination callback proxy
  |
  v
YieldStreamHook.settleEpochFromReactive(rvmId, epochId)
```

## Major Components

| Path | Purpose |
|------|---------|
| `src/YieldStreamHook.sol` | Main Uniswap v4 hook. Tracks epochs, managed liquidity, fee accounting, settlement, callback auth, and redemptions. |
| `src/tokens/FutureYieldToken.sol` | ERC-20 FYT token for an epoch's fee claim. |
| `src/tokens/PrincipalToken.sol` | ERC-20 PT token for an epoch's capital claim. |
| `src/tokens/YieldStreamTokenFactory.sol` | Token factory used to keep the hook below the EIP-170 runtime size limit. |
| `src/rsc/YieldStreamRSC.sol` | Reactive Smart Contract deployed on Lasna. Observes `FeesAccrued` and queues settlement callbacks. |
| `src/adapters/MorphoAdapter.sol` | Morpho adapter shell. Tested independently, but not active in live demo settlement. |
| `script/testnet-demo-with-txids.sh` | Judge-facing live testnet demo runner that prints destination and Lasna txids. |
| `script/verify-reactive-integration.sh` | Readback verifier for hook, RSC, callback proxy, RVM ID, and gas configuration. |
| `frontend/` | Vite/React lifecycle simulator. |
| `docs/DEPLOYMENTS.md` | Current deployments, txids, readbacks, and live proof. |
| `docs/e2e.md` | Historical end-to-end txid ledger. |

## Hook Permissions

YieldStream enables only these Uniswap v4 hook permissions:

- `afterAddLiquidity`
- `beforeRemoveLiquidity`
- `afterSwap`

The deployable hook deliberately does not use return-delta permissions.

## Reactive Network Integration

YieldStream uses the legacy Reactive Network Lasna endpoint and library:

```text
Lasna RPC: https://lasna-rpc.rnk.dev/
Lasna chain ID: 5318007
Currency: lREACT
System contract: 0x0000000000000000000000000000000000fffFfF
Library: Reactive-Network/reactive-lib
```

The RSC subscribes to:

```solidity
FeesAccrued(uint256 indexed epochId, uint256 indexed amount0, uint256 amount1)
```

The destination hook authorizes callbacks with two checks:

```solidity
msg.sender == callbackProxy
rvmId == reactiveSender
```

The current RSC explicitly encodes the RVM/deployer identity as the first callback argument because the legacy callback path does not rewrite that payload:

```solidity
settleEpochFromReactive(address rvmId, uint256 epochId)
```

## Demo / Live Proof

Short-epoch testnet deployments use `epochLength = 20` blocks for judge and investor demos. The production default remains `50,400` blocks.

### Base Sepolia

| Item | Value |
|------|-------|
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| TokenFactory | `0xF6E0AC636cDb1dacfE68D758CAa880b5A09f0a98` |
| MorphoAdapter | `0xDa24f7eaB509aad5EdE5aa6c762CefAbcdfF0f47` |
| Lasna RSC | `0xD4342b1B631a5a465E09b81d1b99E6438c61d453` |

Latest successful end-to-end proof:

| Step | Tx hash | URL |
|------|---------|-----|
| Hook-managed liquidity deposit | `0x69c8fb75c48bdf08488bf5d87d0b81df9989586652de92e3c8c592e99ef02fbd` | https://base-sepolia.blockscout.com/tx/0x69c8fb75c48bdf08488bf5d87d0b81df9989586652de92e3c8c592e99ef02fbd |
| FeesAccrued event 1 | `0x2fdd7fb41fd787f6b2a97612a0e64d37929ca1189c7464004a515a672298316a` | https://base-sepolia.blockscout.com/tx/0x2fdd7fb41fd787f6b2a97612a0e64d37929ca1189c7464004a515a672298316a |
| Lasna RVM observed event 1 | `0xea60015f0c65c364f88a9075b32b728b6b632a2e18334617f8af03a185a6c637` | https://lasna.reactscan.net/tx/0xea60015f0c65c364f88a9075b32b728b6b632a2e18334617f8af03a185a6c637 |
| FeesAccrued boundary event | `0xaf0f052341722586a4114b40ab034e596db948916a2139bb0321eff432cd6b51` | https://base-sepolia.blockscout.com/tx/0xaf0f052341722586a4114b40ab034e596db948916a2139bb0321eff432cd6b51 |
| Lasna RVM queued callback | `0x87a7ace4028833c752a319d79f3676fd360d54fae436a013f04a8f55b0f9ff52` | https://lasna.reactscan.net/tx/0x87a7ace4028833c752a319d79f3676fd360d54fae436a013f04a8f55b0f9ff52 |
| Reactive destination callback / EpochSettled | `0x0444c396d5b1f47b49bc8cd350affb6fecb38de199fa587ed97b8b121bae5541` | https://base-sepolia.blockscout.com/tx/0x0444c396d5b1f47b49bc8cd350affb6fecb38de199fa587ed97b8b121bae5541 |

### Unichain Sepolia

| Item | Value |
|------|-------|
| Hook | `0x4C7734FfB1C9F054E1b16f1BBdcD9aEa98E80640` |
| TokenFactory | `0x97bf008af093831Aa3CCde2565c2de89d52643a5` |
| MorphoAdapter | `0xf15CE9D5855CDFFeF4a9F9AbdC013Dc07cb3F0cD` |
| Lasna RSC | `0xf9C557b4097f399dBa99EB1DB2caf5fc7ADfE786` |

Latest successful end-to-end proof:

| Step | Tx hash | URL |
|------|---------|-----|
| Hook-managed liquidity deposit | `0xa2247bdb86acbd764d504033a8783fe7877a28cb857749d07a584d126f46e886` | https://unichain-sepolia.blockscout.com/tx/0xa2247bdb86acbd764d504033a8783fe7877a28cb857749d07a584d126f46e886 |
| FeesAccrued event 1 | `0x20686899687ae1014513aed573c4ae92e21fa39e57e906145642eafcf1a9a55f` | https://unichain-sepolia.blockscout.com/tx/0x20686899687ae1014513aed573c4ae92e21fa39e57e906145642eafcf1a9a55f |
| Lasna RVM observed event 1 | `0xd53475e95c4658874a0eafa7159bc6175c66ac2dff6ed9d4c160d9d0395f4387` | https://lasna.reactscan.net/tx/0xd53475e95c4658874a0eafa7159bc6175c66ac2dff6ed9d4c160d9d0395f4387 |
| FeesAccrued boundary event | `0x792e873841ffacc1d4ad99a1ff25c528ec2ca5a87f430c41afc1620aa23546b4` | https://unichain-sepolia.blockscout.com/tx/0x792e873841ffacc1d4ad99a1ff25c528ec2ca5a87f430c41afc1620aa23546b4 |
| Lasna RVM queued callback | `0x87c79b9f2dac613a8ceff9ec5d2a48fce55bb71ca4c90eef0fe23abe6d5eea79` | https://lasna.reactscan.net/tx/0x87c79b9f2dac613a8ceff9ec5d2a48fce55bb71ca4c90eef0fe23abe6d5eea79 |
| Reactive destination callback / EpochSettled | `0x6b8a3f668ae2c0d8e6f5d106443f829933c3c7314671fd7182d9b29686623fbc` | https://unichain-sepolia.blockscout.com/tx/0x6b8a3f668ae2c0d8e6f5d106443f829933c3c7314671fd7182d9b29686623fbc |

Full deployment records are in [docs/DEPLOYMENTS.md](docs/DEPLOYMENTS.md). Historical live-run txids are in [docs/e2e.md](docs/e2e.md).

## Installation

Prerequisites:

- Foundry
- Node.js and npm for the frontend
- Git submodules enabled for dependencies

Clone with submodules:

```bash
git clone --recursive https://github.com/Najnomics/yieldstream-hook.git
cd yieldstream-hook
```

If the repository was already cloned without submodules:

```bash
git submodule update --init --recursive
```

Install/build:

```bash
forge build

cd frontend
npm install
npm run build
```

## Configuration

Create a local `.env` file for live scripts. `.env` is intentionally ignored by git.

Common variables used by scripts:

```bash
PRIVATE_KEY=
REACTIVE_PRIVATE_KEY=

BASE_SEPOLIA_RPC_URL=
UNICHAIN_SEPOLIA_RPC_URL=
LASNA_RPC_URL=https://lasna-rpc.rnk.dev/

MAINNET_RPC_URL=
```

The deployment and demo scripts also read the deployed hook, token factory, callback proxy, PoolManager, and RSC addresses documented in [docs/DEPLOYMENTS.md](docs/DEPLOYMENTS.md).

## Usage

Run the local simulation:

```bash
forge script script/DemoYieldStream.s.sol -vvv
```

Run the judge-facing live demo on Base Sepolia:

```bash
YIELDSTREAM_E2E_NETWORK=base bash script/testnet-demo-with-txids.sh
```

Run the same demo on Unichain Sepolia:

```bash
YIELDSTREAM_E2E_NETWORK=unichain bash script/testnet-demo-with-txids.sh
```

The live runner prints a judge-readable workflow:

1. Lasna subscription and RNK filter proof.
2. LP funding, approvals, and hook-managed liquidity deposit.
3. FYT/PT token address and balance readback.
4. Backed `FeesAccrued` emission on the destination chain.
5. ReactVM observation and callback queue proof on Lasna.
6. Destination `EpochSettled` callback txid.
7. Final settlement state and txid ledger append to `docs/e2e.md`.

Verify live Reactive wiring:

```bash
YIELDSTREAM_E2E_NETWORK=base bash script/verify-reactive-integration.sh
YIELDSTREAM_E2E_NETWORK=unichain bash script/verify-reactive-integration.sh
```

Run the frontend:

```bash
cd frontend
npm run dev -- --port 5173
```

Open:

```text
http://127.0.0.1:5173/
```

## Testing

Run all tests:

```bash
forge test -vvv
```

Run coverage:

```bash
forge coverage --ir-minimum --exclude-tests --no-match-coverage 'script|src/demo|src/rsc/ReactivePing|test'
forge coverage --ir-minimum --exclude-tests --no-match-coverage 'script|src/demo|src/rsc/ReactivePing|test' --report lcov
```

Coverage uses `--ir-minimum` because the hook's callback-heavy surface can hit `stack too deep` under Foundry coverage compilation without the IR path.

Current test suites:

| Suite | Scope |
|-------|-------|
| `test/YieldStreamHook.t.sol` | Hook permissions, minting, fee accrual, settlement, redemption, lockup, callback auth, RSC callback payloads. |
| `test/YieldStreamIntegration.t.sol` | Full Alice/Bob lifecycle. |
| `test/YieldStreamFuzz.t.sol` | Fee distribution, PT redemption, early-vs-late FYT weighting. |
| `test/YieldStreamFork.t.sol` | RPC-gated fork harness. |
| `test/MorphoAdapter.t.sol` | Morpho adapter guardrails. |

Latest verified local run:

```text
52 tests passed, 0 failed, 0 skipped
```

Latest measured coverage from June 8, 2026:

| File | Lines | Statements | Branches | Functions |
|------|-------|------------|----------|-----------|
| `src/YieldStreamHook.sol` | 98.04% | 93.97% | 64.29% | 100.00% |
| `src/adapters/MorphoAdapter.sol` | 96.55% | 96.30% | 100.00% | 100.00% |
| `src/rsc/YieldStreamRSC.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `src/tokens/FutureYieldToken.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `src/tokens/PrincipalToken.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `src/tokens/YieldStreamTokenFactory.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| Total | 98.25% | 94.76% | 71.26% | 100.00% |

The protocol-owned function surface is at 100% under the filtered command above. The suite does not honestly satisfy a 100% line/branch claim; the remaining gap is tracked in [docs/TESTING.md](docs/TESTING.md), with most missing coverage in defensive branches and Foundry `viaIR` source-map artifacts around simple assignments that are exercised in tests.

## Deployment

Deployment scripts live in `script/`.

| Script | Purpose |
|--------|---------|
| `script/MineHookAddress.s.sol` | Mine a valid Uniswap v4 hook address for the required flags. |
| `script/Deploy.s.sol` | Deploy token factory, Morpho adapter, and hook. |
| `script/DeployReactive.s.sol` | Deploy the Lasna RSC. |
| `script/ConfigureReactiveIntegration.s.sol` | Configure destination callback/RVM integration. |
| `script/LiveYieldStreamE2E.s.sol` | Broadcast live lifecycle transactions. |
| `script/testnet-demo-with-txids.sh` | End-to-end demo runner with labeled txids. |

Current demo deployments are documented in [docs/DEPLOYMENTS.md](docs/DEPLOYMENTS.md).

## Known Limitations

- **Fee reporting is demo-safe, not final production fee capture.** The current testnet path uses `reportFees(...)`, restricted to the configured fee reporter, and requires real token backing to be transferred into the hook before emitting `FeesAccrued`. Production should integrate the final selected Uniswap v4 fee-capture design.
- **Morpho is not active in live settlement.** `MorphoAdapter` is deployed and tested independently. The live hook settlement path does not route principal through Morpho.
- **Short epochs are demo-only.** Testnet deployments use `20` block epochs so judges can see Reactive settlement during a live demo. The default production epoch length remains `50,400` blocks.
- **Reactive settlement is event-driven.** Reactive has no native scheduler. Settlement is queued when a subscribed event arrives after the relevant epoch boundary. A permissionless fallback settlement path exists after epoch end.
- **No audit claim.** The code has tests and internal review notes, but this README does not claim a completed external audit.
- **Frontend advisories.** npm has reported moderate dependency advisories in the frontend dependency tree. No forced breaking upgrade has been applied.

## Roadmap

- Replace demo fee reporting with production-grade v4 fee capture.
- Activate Morpho routing with explicit market parameters and risk controls.
- Add rolling multi-epoch positions.
- Improve FYT/PT secondary-market UX.
- Add richer frontend wallet flows for live deposits, transfers, settlement, and redemption.
- Expand fork and integration coverage around PoolManager behavior.
- Prepare for external security review before any mainnet deployment.

## Documentation

- [Technical specification](SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Testing](docs/TESTING.md)
- [Demo guide](docs/DEMO.md)
- [Deployments and proof txids](docs/DEPLOYMENTS.md)
- [Historical E2E txid ledger](docs/e2e.md)
- [Reactive debug notes](docs/REACTIVE_DEBUG_NOTES.md)

## License

Solidity sources use `SPDX-License-Identifier: MIT`. A top-level `LICENSE` file should be added before a public release.

## Author

Najnomics
