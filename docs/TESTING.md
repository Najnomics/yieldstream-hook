# Testing

Run:

```bash
forge test -vvv
forge coverage --ir-minimum --exclude-tests --no-match-coverage 'script|src/demo|src/rsc/ReactivePing|test'
forge coverage --ir-minimum --exclude-tests --no-match-coverage 'script|src/demo|src/rsc/ReactivePing|test' --report lcov
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
forge coverage --ir-minimum --exclude-tests --no-match-coverage 'script|src/demo|src/rsc/ReactivePing|test'
forge coverage --ir-minimum --exclude-tests --no-match-coverage 'script|src/demo|src/rsc/ReactivePing|test' --report lcov
```

Latest measured rows from June 8, 2026:

| File | Lines | Statements | Branches | Functions |
|------|-------|------------|----------|-----------|
| `src/YieldStreamHook.sol` | 98.04% | 93.97% | 64.29% | 100.00% |
| `src/adapters/MorphoAdapter.sol` | 96.55% | 96.30% | 100.00% | 100.00% |
| `src/rsc/YieldStreamRSC.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `src/tokens/FutureYieldToken.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `src/tokens/PrincipalToken.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `src/tokens/YieldStreamTokenFactory.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| Total | 98.25% | 94.76% | 71.26% | 100.00% |

The suite is focused on meaningful project-owned behavior rather than inherited library code, demo-only contracts, and script entrypoints. It now covers the full protocol-owned function surface, including managed liquidity custody, settlement, redemption, Reactive subscription/callback queuing, token entrypoint auth, Morpho-backed success paths, and token failure guards.

It is still not honest to claim 100% line/branch coverage. Remaining misses include defensive branches that require contrived failing PoolManager/token/payment behavior, plus Foundry `viaIR` source-map artifacts where exercised assignments such as `ptAmount = liquidity` and Morpho's mock `return amount` are reported as uncovered.
