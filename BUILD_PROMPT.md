# Build Prompt: YieldStream Hook Production Build

You are Codex working in the repository:

`/Users/najnomics/Documents/audits/yieldstream-hook`

Your mission is to build YieldStream Hook from specification to a production-quality hackathon submission: Solidity contracts, full Foundry test suite, fork tests, demo scripts, and a judge/user-facing frontend.

Do not start coding until you complete the context pass below.

## 1. Required Context Pass

First read and understand the project documents:

1. `README.md`
2. `SPEC.md`
3. `context/README.md`

Then inspect the reference context folders. Build an internal map of the relevant files, patterns, and APIs before implementation:

1. UHI workshops:
   - `context/uhi-workshops/workshops`
2. Uniswap docs:
   - `context/uniswap-docs/docs`
3. Reactive Network docs and examples:
   - `context/reactive-network/documentation`
   - `context/reactive-network/reactive-smart-contract-demos`
   - `context/reactive-network/reactive-hardhat-demos`
   - `context/reactive-network/hackathon`
   - `context/reactive-network/reactive-lib`
   - `context/reactive-network/reactive-lib-omni`
   - `context/reactive-network/reactive-test-lib`
   - `context/reactive-network/system-smart-contracts`

Also use the installed global Uniswap Codex skills when relevant:

1. `v4-security-foundations`
2. `v4-hook-generator`
3. `v4-sdk-integration`
4. `viem-integration`
5. `swap-integration`
6. `liquidity-planner`
7. `swap-planner`

Important context links:

1. Reactive docs: https://dev.reactive.network/
2. Reactive education course: https://dev.reactive.network/education/introduction
3. Reactive demos: https://github.com/Reactive-Network/reactive-smart-contract-demos
4. Reactive Telegram: https://t.me/reactivedevs

Context pass output requirement:

Before making edits, write a short implementation plan in your working notes or progress update that identifies:

1. The Uniswap v4 hook base/library versions available in `lib/`.
2. The exact Reactive Network base contracts and callback pattern to use.
3. The test harness pattern from `v4-hooks-public` or UHI workshops.
4. Any spec items that need a pragmatic MVP implementation versus full production integration.

## 2. Product Goal

Build YieldStream, a Uniswap v4 hook that splits LP positions into:

1. `FYT` or Future Yield Token: ERC-20 claim on epoch swap fees.
2. `PT` or Principal Token: ERC-20 claim on principal/capital after settlement.

The hook must:

1. Mint FYT and PT after liquidity is added.
2. Track block-based epochs.
3. Accrue swap fees per epoch.
4. Emit `FeesAccrued` events for Reactive Network.
5. Lock LP exits until epoch settlement.
6. Allow Reactive Network callback settlement through `settleEpoch`.
7. Allow FYT redemption for fees after settlement.
8. Allow PT redemption for principal/capital after settlement.
9. Include a permissionless fallback settlement trigger if Reactive settlement is delayed.
10. Include a Morpho adapter interface or production-safe mock adapter if a real Morpho market integration is not feasible within the repo.

## 3. Required Contract Layout

Create or complete:

```text
src/
  YieldStreamHook.sol
  tokens/
    FutureYieldToken.sol
    PrincipalToken.sol
  rsc/
    YieldStreamRSC.sol
  adapters/
    MorphoAdapter.sol
  interfaces/
    ...
test/
  YieldStreamHook.t.sol
  YieldStreamIntegration.t.sol
  YieldStreamFork.t.sol
  YieldStreamFuzz.t.sol
  utils/
    YieldStreamTestHelper.sol
script/
  Deploy.s.sol
  DemoYieldStream.s.sol
  MineHookAddress.s.sol
frontend/
  ...
foundry.toml
remappings.txt
```

If the existing repo structure differs, adapt conservatively and document the final structure in `README.md`.

## 4. Solidity Implementation Requirements

Use Solidity 0.8.x and the installed Foundry dependencies:

1. `lib/forge-std`
2. `lib/v4-hooks-public`

Use Uniswap v4 patterns from the local docs and examples. Do not hand-roll PoolManager semantics if a local library/test helper exists.

Implement these contracts:

### YieldStreamHook.sol

Must support the hook permissions from `SPEC.md`:

1. `afterAddLiquidity`
2. `beforeRemoveLiquidity`
3. `afterSwap`

Must include:

1. Epoch state mapping.
2. Position metadata mapping.
3. FYT/PT contract lookup per epoch.
4. Epoch fee accounting for token0 and token1.
5. RSC caller authorization.
6. Permissionless fallback settlement after epoch end.
7. Reentrancy protection for settlement and redemption.
8. Clear events from the spec.

Security requirements:

1. Only PoolManager may call hook callbacks.
2. `settleEpoch` must be restricted to the configured RSC caller.
3. Fallback settlement must only work after the epoch has ended and must not bypass accounting.
4. Do not enable return-delta permissions unless explicitly needed and fully tested.
5. Use checks-effects-interactions.
6. Use precise math for fee-per-token distribution.
7. Validate epoch IDs and settlement state.

### FutureYieldToken.sol

ERC-20 token for per-epoch fee claims.

Must include:

1. Immutable `epochId`.
2. Immutable `hook`.
3. Hook-only mint/burn/settle controls.
4. Transferability.
5. Redemption accounting that prevents double claims.

### PrincipalToken.sol

ERC-20 token for per-epoch principal claims.

Must include:

1. Immutable `epochId`.
2. Immutable `hook`.
3. Hook-only mint/burn/redemption enablement.
4. Transferability.
5. Redemption accounting that prevents double claims.

### YieldStreamRSC.sol

Implement the Reactive Network settlement trigger using patterns from the local Reactive docs/examples.

Must include:

1. Subscription to `FeesAccrued`.
2. Persistent epoch tracking.
3. Callback emission to `settleEpoch(uint256)`.
4. Configurable destination chain and hook address.
5. Tests or simulation harness proving the callback payload is correct.

### MorphoAdapter.sol

Implement a safe adapter abstraction. If a real Morpho integration is impractical in the local test environment, implement:

1. A production-facing interface.
2. A deterministic test/mock adapter.
3. Clear README disclosure of what is real versus mocked.

## 5. Test Requirements

Build the test suite to target 100% meaningful coverage across project contracts.

Use Foundry. Include:

1. Unit tests.
2. Integration tests.
3. Fuzz tests.
4. Invariant tests where useful.
5. Fork tests.
6. Demo script tests or script dry-run verification.

Run and pass:

```bash
forge fmt
forge test -vvv
forge coverage
forge coverage --report lcov
```

Coverage target:

1. 100% lines for project-owned contracts where feasible.
2. 100% branches for critical accounting, settlement, and redemption paths where feasible.
3. If exact 100% cannot be reached because of inherited/library code or defensive unreachable branches, document the gap explicitly in `README.md` and provide a coverage table.

Minimum tests to implement:

Epoch management:

1. `currentEpoch` returns correct ID.
2. Epoch contracts deploy on first deposit.
3. Same epoch reuses existing FYT/PT contracts.
4. Epoch increments at block boundary.

Deposit and minting:

1. `afterAddLiquidity` mints FYT and PT.
2. Single LP receives expected amounts.
3. Multiple LPs receive fair amounts.
4. Late epoch deposits receive correctly weighted FYT.
5. PT claim remains tied to capital share.

Fee accrual:

1. `afterSwap` accrues fees to epoch.
2. `FeesAccrued` emits correct indexed data.
3. Multiple swaps accumulate correctly.
4. Zero-fee swaps do not corrupt state.

Settlement:

1. `settleEpoch` only RSC.
2. Fallback settlement only after epoch end.
3. Reverts if already settled.
4. Reverts if epoch not ended.
5. Sets settlement flags.
6. Computes fee-per-token correctly.
7. Enables PT redemption.
8. Emits `EpochSettled`.

Redemption:

1. FYT cannot redeem before settlement.
2. PT cannot redeem before settlement.
3. FYT redeems exact fee share.
4. PT redeems exact capital share.
5. Transfers of FYT/PT before redemption work.
6. Burn prevents double redemption.

Lockup:

1. Liquidity removal reverts before settlement.
2. Liquidity removal is allowed after settlement.

Fuzz/invariant:

1. Sum of FYT redemptions equals total fees within rounding tolerance.
2. Sum of PT redemptions equals available capital within rounding tolerance.
3. Earlier depositors never receive less FYT per unit liquidity than later depositors for the same epoch.
4. Random LP deposits/swaps/settlements do not lose funds.

Fork tests:

1. Use a real v4-capable or documented test deployment where possible.
2. If a live v4 fork target is unavailable, implement a fork-style harness and document the limitation.

## 6. Demo Requirements

Create `script/DemoYieldStream.s.sol` that demonstrates the full lifecycle:

1. Deploy or load mock tokens.
2. Deploy/mine the hook address with correct v4 flags.
3. Initialize a pool with YieldStreamHook.
4. Add liquidity as Alice.
5. Mint FYT/PT.
6. Transfer or "sell" FYT to Bob in the demo.
7. Execute swaps to accrue fees.
8. Advance blocks beyond epoch end.
9. Simulate Reactive RSC callback settlement.
10. Bob redeems FYT fees.
11. Alice redeems PT principal.
12. Print useful console output for judges.

The demo must be runnable with a documented command, for example:

```bash
forge script script/DemoYieldStream.s.sol -vvv
```

## 7. Frontend Requirements

Build a judge/user-facing frontend in `frontend/`.

The frontend should be an actual app, not a landing page. It should let users understand and interact with the YieldStream lifecycle.

Required screens or panels:

1. Pool/epoch dashboard.
2. Add liquidity flow.
3. FYT/PT balances.
4. Sell/transfer FYT demo flow.
5. Fee accrual visualization.
6. Epoch settlement status.
7. Redeem FYT/PT flow.
8. Risk panel showing who bears yield variance versus IL.
9. Demo mode that works against local/demo contract addresses or mocked data.

Use a practical stack already present or easy to add, such as Vite + React + TypeScript + viem. Use the installed Uniswap/viem skills and local docs.

Frontend quality bar:

1. Polished, responsive, judge-ready UI.
2. No marketing-only hero page.
3. Clear state transitions.
4. Works locally with documented commands.
5. Include `.env.example`.
6. Include screenshots or a documented verification path if possible.

Start the dev server after implementation and provide the local URL.

## 8. README and Docs Updates

Update `README.md` so judges can run everything:

1. Project summary.
2. Architecture.
3. Contract list.
4. Setup commands.
5. Test commands.
6. Coverage commands and result summary.
7. Demo script command.
8. Frontend command.
9. Known limitations.
10. Reactive Network integration notes.
11. Morpho integration/mock notes.
12. Security considerations.

Add any additional docs that improve judge comprehension:

1. `docs/ARCHITECTURE.md`
2. `docs/TESTING.md`
3. `docs/DEMO.md`

Only add docs that are useful. Avoid filler.

## 9. Production Quality Bar

Before final response, verify:

1. `forge fmt` passes.
2. `forge test -vvv` passes.
3. `forge coverage` runs and results are summarized.
4. Frontend installs and builds.
5. Demo script runs or dry-runs successfully.
6. Git status is understood and summarized.

Do not fake passing tests. If something cannot be completed, state exactly what failed, why, and what remains.

## 10. Final Response Requirements

In the final response, include:

1. What was built.
2. The important files changed.
3. Test and coverage results.
4. Demo command.
5. Frontend URL or run command.
6. Any honest limitations.

Stay concise and concrete.
