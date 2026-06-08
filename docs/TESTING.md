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

Latest measured rows:

| File | Lines | Statements | Branches | Functions |
|------|-------|------------|----------|-----------|
| `src/YieldStreamHook.sol` | 87.77% | 86.25% | 47.37% | 78.57% |
| `src/adapters/MorphoAdapter.sol` | 93.75% | 91.67% | 100.00% | 100.00% |
| `src/rsc/YieldStreamRSC.sol` | 95.65% | 95.45% | 66.67% | 100.00% |
| `src/tokens/FutureYieldToken.sol` | 93.75% | 83.33% | 0.00% | 100.00% |
| `src/tokens/PrincipalToken.sol` | 93.75% | 83.33% | 0.00% | 100.00% |
| Total including scripts/context/harnesses | 66.13% | 62.08% | 33.33% | 76.12% |

The suite is focused on meaningful project-owned behavior rather than inherited library code. Remaining gaps are primarily defensive branches, script/demo files that are verified through `forge script`, and callback paths that require live PoolManager/Reactive infrastructure.
