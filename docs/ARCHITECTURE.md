# Architecture

YieldStream splits LP exposure into epoch-scoped ERC-20 claims.

## Contracts

- `YieldStreamHook`: v4 hook that mints claims, tracks epochs, accrues fees, locks exits, and settles epochs.
- `FutureYieldToken`: transferable FYT claim on epoch fees.
- `PrincipalToken`: transferable PT claim on epoch principal.
- `YieldStreamRSC`: Reactive Network contract that observes `FeesAccrued` and queues settlement callbacks.
- `MorphoAdapter`: adapter shell for idle-capital yield integration.

## Epoch Accounting

Epoch IDs are `block.number / 50_400`. FYT is minted as `liquidity * remainingBlocks`, so earlier LPs receive more fee claim per unit of liquidity than later LPs. PT is minted one-to-one with liquidity units.

## Settlement

Settlement can happen through the configured Reactive callback sender or through permissionless fallback after epoch end. Settlement stores fee-per-FYT and capital-per-PT values, then enables redemption.

## Production Boundaries

The current build is production-shaped but uses deterministic test/demo funding and fee injection. Live deployment work remains around exact PoolManager fee custody, selected Morpho market params, and CREATE2 hook deployment.
