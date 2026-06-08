# Testing

Run:

```bash
forge test -vvv
forge coverage --ir-minimum
forge coverage --ir-minimum --report lcov
```

Suites:

- `YieldStreamHook.t.sol`: unit coverage for permissions, minting, fee accrual, settlement, redemption, lockup, and RSC callback payloads.
- `YieldStreamIntegration.t.sol`: complete Alice/Bob lifecycle.
- `YieldStreamFuzz.t.sol`: fuzzed fee distribution, PT redemption, and early-vs-late FYT weighting.
- `YieldStreamFork.t.sol`: optional RPC-gated fork harness.
- `MorphoAdapter.t.sol`: deterministic coverage for the production-facing Morpho adapter shell.

Rounding assertions use small absolute tolerances because fee-per-token and capital-per-token values are integer fixed-point divisions.

## Coverage Notes

Foundry coverage is run with `--ir-minimum` because the hook's callback surface otherwise trips a `stack too deep` compiler error when coverage disables the normal optimizer path.

The latest measured coverage was generated with:

```bash
forge coverage --ir-minimum
forge coverage --ir-minimum --report lcov
```

Latest measured rows from June 8, 2026:

| File | Lines | Statements | Branches | Functions |
|------|-------|------------|----------|-----------|
| `src/YieldStreamHook.sol` | 60.89% | 57.59% | 22.86% | 66.04% |
| `src/adapters/MorphoAdapter.sol` | 58.62% | 48.15% | 28.57% | 87.50% |
| `src/rsc/YieldStreamRSC.sol` | 72.22% | 78.79% | 33.33% | 60.00% |
| `src/tokens/FutureYieldToken.sol` | 93.75% | 83.33% | 0.00% | 100.00% |
| `src/tokens/PrincipalToken.sol` | 93.75% | 83.33% | 0.00% | 100.00% |
| `src/tokens/YieldStreamTokenFactory.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| Total including scripts/demo/context/harnesses | 34.94% | 31.28% | 18.42% | 54.92% |

The suite is focused on meaningful project-owned behavior rather than inherited library code. It is not yet at 100% coverage. Remaining gaps are primarily defensive branches, script/demo files that are verified through `forge script`, and callback paths that require live PoolManager/Reactive infrastructure. A credible 100% target would require additional unit harnesses for every owner/error path, script coverage strategy, token failure branches, native-token rejection branches, and callback payment/debt paths.
