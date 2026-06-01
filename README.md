# YieldStream Hook

YieldStream is a Uniswap v4 hook that turns LP fee income into a tradable fixed-income primitive.

When an LP deposits into a YieldStream-enabled pool, the hook splits the position into two ERC-20 claims:

- **FYT (Future Yield Token):** claim on the swap fees earned during an epoch
- **PT (Principal Token):** claim on the underlying LP capital after the epoch settles

LPs can sell FYT immediately for upfront cash, hold PT until settlement, and turn uncertain future fees into a fixed payment today. FYT buyers take the opposite side: they get pure exposure to future pool volume and fee generation without running the LP position themselves.

## Why It Matters

AMM LPs currently face three linked risks:

- Impermanent loss
- Illiquid fee income
- Unpredictable yield

Many hooks address IL. YieldStream focuses on the less explored problem: LP yield itself is not currently separable, tradeable, or priceable inside Uniswap v4. YieldStream brings a Pendle-like principal/yield split directly to LP positions.

## One-Sentence Pitch

YieldStream does for Uniswap v4 LP fees what Pendle did for DeFi yield: it makes future yield tradeable, priceable, and sellable upfront.

## Core Flow

```text
LP deposits into YieldStream pool
        |
        v
Hook mints FYT + PT for the current epoch
        |
        +--> LP sells FYT for upfront fixed liquidity
        |
        +--> LP holds or sells PT as principal claim
        |
        v
Swaps accrue fees during epoch
        |
        v
Reactive Network RSC observes FeesAccrued events
        |
        v
RSC triggers settleEpoch()
        |
        +--> FYT holders redeem accrued fees
        |
        +--> PT holders redeem underlying capital
```

## Architecture

YieldStream has five planned contracts:

| Contract | Purpose |
|----------|---------|
| `YieldStreamHook.sol` | Main Uniswap v4 hook. Mints FYT/PT, tracks epochs, accrues fees, and settles epochs. |
| `FutureYieldToken.sol` | ERC-20 token representing claim on epoch swap fees. |
| `PrincipalToken.sol` | ERC-20 token representing claim on LP capital at epoch end. |
| `YieldStreamRSC.sol` | Reactive Network contract that listens for fee events and triggers settlement callbacks. |
| `MorphoAdapter.sol` | Optional adapter for deploying idle epoch capital into Morpho for extra PT-holder yield. |

## Reactive Settlement

YieldStream uses a Reactive Smart Contract (RSC) instead of a centralized keeper.

The hook emits:

```solidity
event FeesAccrued(
    uint256 indexed epochId,
    uint256 indexed amount0,
    uint256 amount1
);
```

The RSC subscribes to this event. When it observes that a new epoch has started, it emits a callback that calls:

```solidity
settleEpoch(uint256 epochId)
```

on the hook contract. Settlement distributes accumulated fees to FYT holders and unlocks PT redemption.

## Token Model

| Token | Holder receives | Main risk |
|-------|-----------------|-----------|
| FYT | Pro-rata epoch fees | Fees may be lower than the price paid for FYT |
| PT | LP principal at epoch end | Capital is exposed to impermanent loss |

Holding both FYT and PT is economically equivalent to holding the original LP position through the epoch. Selling FYT converts variable fee income into fixed upfront liquidity.

## Epoch Design

- Epoch length: `50,400` blocks, approximately 7 days at 12 seconds per block
- Epoch ID: `block.number / EPOCH_LENGTH`
- FYT and PT are planned as per-epoch ERC-20s
- LP exits are locked until epoch settlement
- Early exit is possible by selling PT on a secondary market

## Repository Status

This repository currently contains the product and technical specification for the UHI9 Hookathon submission.

Planned implementation layout:

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
test/
  YieldStreamHook.t.sol
  YieldStreamIntegration.t.sol
script/
  Deploy.s.sol
SPEC.md
README.md
foundry.toml
```

## Target Tracks

- UHI9 Special Prize
- Reactive Network Sponsor Prize
- Uniswap General Prize

## Documentation

See [SPEC.md](./SPEC.md) for the full technical specification, state machines, event schema, RSC design, token economics, test plan, and deployment plan.

## Author

Najnomics
