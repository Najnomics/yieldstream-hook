# YieldStream Hook — Technical Specification
**Version:** 1.0  
**Author:** Najnomics  
**Hackathon:** UHI9 — Impermanent Loss & Yield Systems  
**Hookathon:** May 25, 2026 | **Demo Day:** June 19, 2026  
**Prize targets:** UHI9 Special Prize · Reactive Network Sponsor Prize · Uniswap General Prize

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Solution Overview](#3-solution-overview)
4. [Product Design](#4-product-design)
5. [Architecture Overview](#5-architecture-overview)
6. [Contract Specifications](#6-contract-specifications)
   - 6.1 [YieldStreamHook.sol](#61-yieldstreamhooksol)
   - 6.2 [FutureYieldToken.sol (FYT)](#62-futureyieldtokensol-fyt)
   - 6.3 [PrincipalToken.sol (PT)](#63-principaltokensol-pt)
   - 6.4 [YieldStreamRSC.sol](#64-yieldstreamrscsol)
   - 6.5 [MorphoAdapter.sol](#65-morphoadaptersol)
7. [Data Structures](#7-data-structures)
8. [Function Signatures](#8-function-signatures)
9. [Event Schema](#9-event-schema)
10. [State Machine](#10-state-machine)
11. [RSC Architecture — Deep Dive](#11-rsc-architecture--deep-dive)
12. [Epoch Lifecycle](#12-epoch-lifecycle)
13. [Token Economics](#13-token-economics)
14. [Risk Model](#14-risk-model)
15. [Security Considerations](#15-security-considerations)
16. [Test Plan](#16-test-plan)
17. [Deployment Plan](#17-deployment-plan)
18. [Known Limitations & Future Work](#18-known-limitations--future-work)

---

## 1. Executive Summary

YieldStream is a Uniswap v4 hook that splits every LP position into two tradeable ERC-20 tokens at the moment of deposit:

- **FYT (Future Yield Token)** — a claim on all swap fees the position earns over an epoch
- **PT (Principal Token)** — a claim on the underlying LP capital redeemable at epoch end

This enables LPs to sell their future fee income upfront for immediate, fixed liquidity — converting volatile, unpredictable swap fee revenue into a guaranteed payment today. A **Reactive Smart Contract (RSC)** on Reactive Network autonomously settles each epoch by monitoring fee accrual events and firing settlement callbacks without any keeper, multisig, or manual trigger.

**One-sentence pitch:** YieldStream does for LP yield what Pendle did for DeFi yield — it makes illiquid, unpredictable fee income tradeable, priceable, and sellable as a structured financial instrument, natively inside a Uniswap v4 hook for the first time.

**Risk in one sentence:** FYT buyers absorb yield variance (fees may be higher or lower than price paid); PT holders absorb IL (capital returned at epoch end may be worth less if price diverged during the epoch).

**White space status:** Genuinely unbuilt — listed as white space #1 in the official UHI9 brainstorm guide across ~300 hooks reviewed from cohorts 1–8.

---

## 2. Problem Statement

### 2.1 The Core LP Yield Problem

When a liquidity provider deposits into a Uniswap v4 pool, they accept three interlinked liabilities:

| Liability | Description | Current tooling |
|-----------|-------------|-----------------|
| **Impermanent Loss** | Position value falls relative to holding when price diverges | Hedging hooks, rebalancing hooks |
| **Yield illiquidity** | Fee income cannot be sold, borrowed against, or priced forward | None in v4 |
| **Yield unpredictability** | Fee revenue varies with pool volume — no fixed returns possible | None in v4 |

The first liability (IL) has been addressed in various forms across 8 UHI cohorts. The second and third have never been addressed inside a v4 hook. This is the white space YieldStream occupies.

### 2.2 Why This Matters at Scale

Fixed-income DeFi is a proven multi-billion dollar market:
- **Pendle Finance**: $700M+ TVL at peak — built entirely on the concept of separating yield from principal
- **Notional Finance**: $1B+ TVL peak — fixed-rate lending via yield tokenization
- **Element Finance**: $200M+ TVL — early yield tokenization for DeFi

None of these exist natively inside an AMM. Pendle operates on wrapped yield-bearing tokens from external protocols. YieldStream brings this mechanism directly into the LP position itself — no external wrapper, no protocol hop, no yield source other than the pool's own swap fees.

### 2.3 Specific Pain Points Solved

**For LPs who want certainty:**
> "I'm providing $100k in ETH/USDC liquidity. I think I'll earn around $2k in fees this month, but I have no idea — and I can't access that money until I withdraw. I'd happily take $1.5k today guaranteed."

YieldStream lets this LP sell their FYT for $1.5k upfront, lock in their return, and keep their PT (capital claim) for the end of the epoch.

**For yield buyers who want exposure:**
> "I want to bet on Uniswap trading volume being high this month. How do I get pure fee exposure without running an LP position?"

YieldStream lets this participant buy FYT at a discount to expected fees — earning a premium if volume is high, losing the discount if volume is low.

**For PT buyers who want capital efficiency:**
> "I want LP exposure without the fee uncertainty. I want to know exactly what I'm getting back."

PT buyers get the capital at epoch end (minus IL) without any fee variance risk — a cleaner risk profile than a standard LP position.

---

## 3. Solution Overview

### 3.1 What YieldStream Builds

```
Standard LP position:
    LP deposits → gets LP token → earns fees (variable) → withdraws capital + fees (variable)

YieldStream position:
    LP deposits → gets FYT + PT
                  ↓              ↓
              sells FYT       holds PT
              immediately      to epoch end
              (upfront cash)   (capital return)
    
    RSC autonomously settles epoch → distributes fees to FYT holders → unlocks PT redemption
```

### 3.2 Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Settlement trigger | Reactive Network RSC | Trustless, no keeper, no multisig |
| Epoch boundary | Block number (not timestamp) | More predictable, manipulation-resistant |
| FYT fungibility | Per-epoch ERC-20 | All positions entered in same epoch share one FYT |
| PT fungibility | Per-position ERC-721 or per-epoch ERC-20 | See §4.2 for tradeoff analysis |
| Idle capital yield | Morpho | Best risk-adjusted yield, composable |
| Fee accrual | Hook-level (not PoolManager) | Full control over fee accounting |

---

## 4. Product Design

### 4.1 User Flows

#### Flow A: LP Who Wants Fixed Return (FYT Seller)

```
1. LP calls addLiquidity() via PoolManager with YieldStream hook
2. Hook mints:
   - FYT[epochId] tokens proportional to liquidity share
   - PT[epochId] tokens representing full capital claim
3. LP immediately lists FYT on a secondary DEX (e.g. Uniswap v3/v4 FYT/USDC pool)
4. LP sells FYT for USDC at market price — locking in a fixed return today
5. LP holds PT until epoch end
6. RSC settles epoch → LP redeems PT for underlying capital (minus IL)
```

#### Flow B: Yield Speculator (FYT Buyer)

```
1. Buyer purchases FYT[epochId] on secondary market at a discount to expected fees
2. Holds FYT through epoch
3. RSC settles epoch → FYT buyer claims pro-rata share of all fees generated
4. Profit = (actual fees received) - (FYT purchase price)
```

#### Flow C: Capital-Efficiency Seeker (PT Buyer)

```
1. LP sells both FYT and PT on secondary market (full position exit pre-epoch)
2. PT buyer holds PT until epoch end
3. RSC settles → PT buyer redeems capital
4. PT buyer gains: clean capital exposure to Uniswap LP without fee variance
```

#### Flow D: LP Who Holds Both (Standard LP)

```
1. LP deposits, receives FYT + PT
2. Holds both tokens — equivalent to standard LP position
3. Epoch settles — redeems FYT for fees + PT for capital
4. Net result: identical to standard LP experience
```

### 4.2 FYT and PT Fungibility Design

**Option A — Per-Epoch Fungible ERC-20s (Recommended)**

All deposits within the same epoch share one FYT ERC-20 contract and one PT ERC-20 contract. Amounts are pro-rata by liquidity share.

- `FYT_EPOCH_1` ERC-20: represents claim on epoch 1 fees, proportional to balance
- `PT_EPOCH_1` ERC-20: represents claim on epoch 1 capital, proportional to balance

Pros: fully fungible, tradeable on DEXs as a single pair, simpler secondary market  
Cons: LP entry point within epoch matters (early depositor vs late depositor both get same epoch FYT, but different liquidity durations — handled via liquidity-weighted shares)

**Option B — Per-Position NFT PTs (Alternative)**

Each LP position gets a unique PT NFT encoding exact entry block, tick range, and liquidity amount.

Pros: precise capital accounting, no fungibility edge cases  
Cons: illiquid NFTs are harder to trade on secondary markets

**Recommendation:** Implement Option A for the hackathon (simpler, better demo, more tradeable). Document Option B in future work.

### 4.3 Epoch Design

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Epoch length | 50,400 blocks (~7 days at 12s/block) | Weekly epochs match institutional and retail planning horizons |
| Epoch ID | `block.number / EPOCH_LENGTH` | Deterministic, no storage needed for epoch boundaries |
| Settlement window | RSC fires within 1 block of epoch boundary | RSC monitors block numbers on ReactVM |
| Lockup | LP cannot remove liquidity before epoch ends | Enforced in `beforeRemoveLiquidity` |
| Early exit | LP can sell PT on secondary market instead | No on-chain early exit from hook |

---

## 5. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER LAYER                               │
│  LP Depositor    FYT Trader    PT Holder    Yield Speculator    │
└──────────┬───────────┬──────────────┬──────────────────────────┘
           │           │              │
           ▼           ▼              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   UNISWAP v4 LAYER                              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   PoolManager                           │   │
│  │  afterAddLiquidity ──►  YieldStreamHook                 │   │
│  │  afterSwap         ──►  YieldStreamHook                 │   │
│  │  beforeRemoveLiq   ──►  YieldStreamHook                 │   │
│  └────────────────────────────┬────────────────────────────┘   │
│                               │                                 │
│  ┌────────────────────────────▼────────────────────────────┐   │
│  │               YieldStreamHook.sol                       │   │
│  │                                                         │   │
│  │  EpochState mapping    FYT minting    PT minting        │   │
│  │  Fee accrual           FeesAccrued event emission       │   │
│  │  settleEpoch()  ◄── (RSC callback only)                │   │
│  └──────┬──────────────────────────────────────────────────┘   │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────┐    ┌───────────────────────────────┐     │
│  │  FYT ERC-20      │    │  PT ERC-20                    │     │
│  │  (per epoch)     │    │  (per epoch)                  │     │
│  └──────────────────┘    └───────────────────────────────┘     │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │               MorphoAdapter.sol                         │   │
│  │  Idle LP capital deposited → earns yield for PT holders │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────┬───────────────────────────────────┘
                              │ emits FeesAccrued event
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  REACTIVE NETWORK LAYER                         │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │               YieldStreamRSC.sol                        │   │
│  │                                                         │   │
│  │  Subscribes to: FeesAccrued(epochId, amount)           │   │
│  │  ReactVM state: epochFeeAccumulator[epochId]           │   │
│  │  ReactVM state: lastSettledEpoch                       │   │
│  │                                                         │   │
│  │  Logic: if currentEpoch > lastSettledEpoch:            │   │
│  │           emit Callback(settleEpoch(lastSettledEpoch)) │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Contract Specifications

### 6.1 YieldStreamHook.sol

**Inherits:** `BaseHook` (v4-periphery), `Ownable`  
**Hook flags required:**
```solidity
Hooks.Permissions({
    beforeInitialize: false,
    afterInitialize: false,
    beforeAddLiquidity: false,
    afterAddLiquidity: true,    // mint FYT + PT
    beforeRemoveLiquidity: true, // enforce lockup, settle
    afterRemoveLiquidity: false,
    beforeSwap: false,
    afterSwap: true,            // accrue fees, emit FeesAccrued
    beforeDonate: false,
    afterDonate: false,
    beforeSwapReturnDelta: false,
    afterSwapReturnDelta: false,
    afterAddLiquidityReturnDelta: false,
    afterRemoveLiquidityReturnDelta: false
})
```

**Storage layout:**
```solidity
// Epoch state: epochId → EpochState
mapping(uint256 => EpochState) public epochs;

// LP positions: positionKey → PositionInfo
mapping(bytes32 => PositionInfo) public positions;

// FYT contracts: epochId → FYT ERC-20 address
mapping(uint256 => address) public fytContracts;

// PT contracts: epochId → PT ERC-20 address
mapping(uint256 => address) public ptContracts;

// RSC caller address (set on deploy, immutable after)
address public immutable RSC_CALLER;

// Epoch length in blocks
uint256 public constant EPOCH_LENGTH = 50_400;

// Morpho adapter
address public immutable morphoAdapter;

// Fee accrual: epochId → total fees accumulated (in token0 + token1 separately)
mapping(uint256 => uint256) public epochFees0;
mapping(uint256 => uint256) public epochFees1;
```

---

### 6.2 FutureYieldToken.sol (FYT)

**Standard:** ERC-20  
**Minting:** Only callable by YieldStreamHook  
**Burning:** Only callable by YieldStreamHook (at redemption)  
**Transferability:** Fully transferable — enables secondary market trading  
**Naming convention:** `FYT-WETH-USDC-EPOCH-{epochId}` / symbol `FYT-{epochId}`

```solidity
contract FutureYieldToken is ERC20, Ownable {
    uint256 public immutable epochId;
    address public immutable hook;
    bool public settled;
    
    // Total fees distributed per token (set at settlement)
    uint256 public feesPerToken0;
    uint256 public feesPerToken1;
    
    // Redemption: FYT holder burns tokens to claim fees
    function redeem(address recipient) external returns (uint256 fees0, uint256 fees1);
    
    // Called by hook RSC callback at settlement
    function settle(uint256 _feesPerToken0, uint256 _feesPerToken1) external onlyHook;
    
    // Hook mints at LP deposit
    function mint(address to, uint256 amount) external onlyHook;
    
    // Hook burns at redemption
    function burn(address from, uint256 amount) external onlyHook;
}
```

---

### 6.3 PrincipalToken.sol (PT)

**Standard:** ERC-20  
**Minting:** Only callable by YieldStreamHook  
**Burning:** Only callable by YieldStreamHook (at redemption)  
**Transferability:** Fully transferable — enables secondary market sale before epoch end  
**Naming convention:** `PT-WETH-USDC-EPOCH-{epochId}` / symbol `PT-{epochId}`

```solidity
contract PrincipalToken is ERC20, Ownable {
    uint256 public immutable epochId;
    address public immutable hook;
    bool public redeemable; // set true after RSC settles epoch
    
    // Capital per token (set at settlement after IL accounting)
    uint256 public capitalPerToken0;
    uint256 public capitalPerToken1;
    
    // Redemption: PT holder burns tokens to claim capital
    function redeem(address recipient) external returns (uint256 capital0, uint256 capital1);
    
    // Called by hook at settlement — records final capital amounts
    function enableRedemption(uint256 _capitalPerToken0, uint256 _capitalPerToken1) external onlyHook;
    
    // Hook mints at LP deposit
    function mint(address to, uint256 amount) external onlyHook;
    
    // Hook burns at redemption
    function burn(address from, uint256 amount) external onlyHook;
}
```

---

### 6.4 YieldStreamRSC.sol

**Deployed on:** Reactive Network (ReactVM)  
**Inherits:** `AbstractReactive` (Reactive Network base contract)  
**Purpose:** Autonomous epoch settlement trigger  

```solidity
contract YieldStreamRSC is AbstractReactive {
    // Chain ID of the destination chain (where hook is deployed)
    uint256 public immutable DESTINATION_CHAIN_ID;
    
    // Hook contract address to callback
    address public immutable HOOK_ADDRESS;
    
    // Topic0 of FeesAccrued event — used for subscription
    bytes32 public constant FEES_ACCRUED_TOPIC =
        keccak256("FeesAccrued(uint256,uint256,uint256)");
    
    // ReactVM state
    uint256 private lastSettledEpoch;
    mapping(uint256 => uint256) private epochFeeAccumulator;
    
    constructor(
        uint256 destinationChainId,
        address hookAddress,
        address hookChainRpc  // Reactive Network subscription config
    ) {
        DESTINATION_CHAIN_ID = destinationChainId;
        HOOK_ADDRESS = hookAddress;
        
        // Subscribe to FeesAccrued events from hook
        _subscribe(
            destinationChainId,
            hookAddress,
            FEES_ACCRUED_TOPIC,
            REACTIVE_IGNORE, // topic1 wildcard
            REACTIVE_IGNORE, // topic2 wildcard
            REACTIVE_IGNORE  // topic3 wildcard
        );
    }
    
    // Called by Reactive Network when FeesAccrued event fires
    function react(
        uint256 chainId,
        address _contract,
        uint256 topics0,
        uint256 epochId,      // topic1 (indexed)
        uint256 amount,       // topic2 (indexed)
        bytes calldata data   // non-indexed data
    ) external onlyReactiveNetwork {
        // Accumulate fees for this epoch
        epochFeeAccumulator[epochId] += amount;
        
        // Check if we've crossed into a new epoch
        uint256 currentEpoch = _getCurrentEpoch();
        
        if (currentEpoch > lastSettledEpoch && lastSettledEpoch > 0) {
            // Previous epoch has ended — trigger settlement
            uint256 epochToSettle = lastSettledEpoch;
            lastSettledEpoch = currentEpoch;
            
            // Emit callback to hook on destination chain
            emit Callback(
                DESTINATION_CHAIN_ID,
                HOOK_ADDRESS,
                GAS_LIMIT,
                abi.encodeWithSignature(
                    "settleEpoch(uint256)",
                    epochToSettle
                )
            );
        } else if (lastSettledEpoch == 0) {
            // First event — initialize epoch tracking
            lastSettledEpoch = currentEpoch;
        }
    }
    
    // Compute current epoch from block number
    // Note: ReactVM has access to block context
    function _getCurrentEpoch() internal view returns (uint256) {
        return block.number / EPOCH_LENGTH;
    }
}
```

**Key RSC design constraints:**
- RSC fires on `FeesAccrued` events only — no native scheduler
- `block.number` is available on ReactVM for epoch computation
- `lastSettledEpoch` persists between `react()` calls — RSC is stateful
- Callback gas limit must cover `settleEpoch()` execution — estimate 300,000 gas

---

### 6.5 MorphoAdapter.sol

**Purpose:** Deploy idle epoch capital into Morpho to earn additional yield for PT holders  
**Deployed on:** Same chain as hook

```solidity
contract MorphoAdapter {
    IMorpho public immutable morpho;
    address public immutable hook; // only hook can call
    
    // Deposit idle capital into Morpho market
    function deposit(
        address token,
        uint256 amount,
        MarketParams calldata marketParams
    ) external onlyHook returns (uint256 shares);
    
    // Withdraw before epoch settlement
    function withdraw(
        address token,
        uint256 shares,
        MarketParams calldata marketParams
    ) external onlyHook returns (uint256 assets);
    
    // View: current accrued yield for an epoch
    function pendingYield(
        uint256 epochId,
        address token
    ) external view returns (uint256 yield);
}
```

---

## 7. Data Structures

```solidity
/// @notice State for a single epoch
struct EpochState {
    uint256 epochId;
    uint256 startBlock;
    uint256 endBlock;           // startBlock + EPOCH_LENGTH
    uint256 totalLiquidity;     // aggregate liquidity across all positions this epoch
    uint256 totalFees0;         // total token0 fees accrued
    uint256 totalFees1;         // total token1 fees accrued
    uint256 morphoYield0;       // additional yield from Morpho on idle capital
    uint256 morphoYield1;
    bool settled;               // set true by settleEpoch()
    address fytContract;        // FYT ERC-20 for this epoch
    address ptContract;         // PT ERC-20 for this epoch
}

/// @notice Per-LP position metadata
struct PositionInfo {
    uint256 epochId;            // which epoch this position belongs to
    uint256 liquidity;          // liquidity units deposited
    uint256 fytMinted;          // FYT tokens minted for this position
    uint256 ptMinted;           // PT tokens minted for this position
    int24 tickLower;
    int24 tickUpper;
    address owner;
    uint256 depositBlock;
}

/// @notice Parameters passed to afterAddLiquidity
struct AddLiquidityParams {
    address sender;
    PoolKey key;
    IPoolManager.ModifyLiquidityParams params;
    bytes hookData;
}

/// @notice Token amounts for dual-token fee/capital accounting
struct TokenAmounts {
    uint256 amount0;
    uint256 amount1;
}
```

---

## 8. Function Signatures

### YieldStreamHook.sol — Public / External

```solidity
/// @notice Hook callback — mints FYT + PT for new LP position
/// @dev Called by PoolManager after liquidity is added
function afterAddLiquidity(
    address sender,
    PoolKey calldata key,
    IPoolManager.ModifyLiquidityParams calldata params,
    BalanceDelta delta,
    BalanceDelta feesAccrued,
    bytes calldata hookData
) external override onlyPoolManager returns (bytes4, BalanceDelta);

/// @notice Hook callback — accrues fees, emits FeesAccrued for RSC
/// @dev Called by PoolManager after every swap
function afterSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) external override onlyPoolManager returns (bytes4, int128);

/// @notice Hook callback — enforces epoch lockup on LP exit
/// @dev Reverts if epoch not yet settled; allows exit if settled
function beforeRemoveLiquidity(
    address sender,
    PoolKey calldata key,
    IPoolManager.ModifyLiquidityParams calldata params,
    bytes calldata hookData
) external override onlyPoolManager returns (bytes4);

/// @notice Settle a completed epoch — distribute fees to FYT, unlock PT
/// @dev RESTRICTED: only callable by RSC_CALLER (Reactive Network callback)
/// @param epochId The epoch to settle
function settleEpoch(uint256 epochId) external onlyRSC;

/// @notice LP redeems PT after epoch settlement for underlying capital
/// @param epochId Epoch whose PT to redeem
/// @param ptAmount Amount of PT tokens to burn
function redeemPT(uint256 epochId, uint256 ptAmount) external;

/// @notice FYT holder redeems for fee share after settlement
/// @param epochId Epoch whose FYT to redeem
/// @param fytAmount Amount of FYT tokens to burn
function redeemFYT(uint256 epochId, uint256 fytAmount) external;

/// @notice View: current epoch ID based on block number
function currentEpoch() external view returns (uint256);

/// @notice View: FYT contract address for a given epoch
function getFYTContract(uint256 epochId) external view returns (address);

/// @notice View: PT contract address for a given epoch
function getPTContract(uint256 epochId) external view returns (address);

/// @notice View: total fees accrued in an epoch so far
function getEpochFees(uint256 epochId) external view returns (uint256 fees0, uint256 fees1);
```

### YieldStreamHook.sol — Internal

```solidity
/// @dev Compute position key for storage lookup
function _positionKey(
    address owner,
    int24 tickLower,
    int24 tickUpper,
    uint256 epochId
) internal pure returns (bytes32);

/// @dev Mint FYT proportional to liquidity share of epoch total
function _mintFYT(
    address to,
    uint256 epochId,
    uint256 liquidity,
    uint256 epochTotalLiquidity
) internal returns (uint256 fytAmount);

/// @dev Mint PT equal to liquidity amount (1:1 with deposited capital units)
function _mintPT(
    address to,
    uint256 epochId,
    uint256 liquidity
) internal returns (uint256 ptAmount);

/// @dev Deploy or fetch FYT + PT ERC-20 contracts for epoch
function _ensureEpochContracts(uint256 epochId) internal;

/// @dev Compute fee delta from swap BalanceDelta
function _extractFees(BalanceDelta delta) internal pure returns (uint256 fee0, uint256 fee1);

/// @dev Deposit idle capital into Morpho after epoch lock
function _depositToMorpho(uint256 epochId, uint256 amount0, uint256 amount1) internal;

/// @dev Withdraw from Morpho at epoch settlement
function _withdrawFromMorpho(uint256 epochId) internal returns (uint256 yield0, uint256 yield1);
```

---

## 9. Event Schema

```solidity
/// @notice Emitted by afterSwap — RSC subscribes to this
/// @param epochId Current epoch ID (indexed — enables RSC topic filter)
/// @param amount0 Token0 fees accrued in this swap
/// @param amount1 Token1 fees accrued in this swap
event FeesAccrued(
    uint256 indexed epochId,
    uint256 indexed amount0,
    uint256 amount1
);

/// @notice Emitted when a new epoch begins (first deposit in epoch)
event EpochStarted(
    uint256 indexed epochId,
    uint256 startBlock,
    address fytContract,
    address ptContract
);

/// @notice Emitted when RSC triggers epoch settlement
event EpochSettled(
    uint256 indexed epochId,
    uint256 totalFees0,
    uint256 totalFees1,
    uint256 morphoYield0,
    uint256 morphoYield1,
    uint256 totalLiquidity
);

/// @notice Emitted when LP deposits and receives FYT + PT
event PositionCreated(
    address indexed owner,
    uint256 indexed epochId,
    uint256 liquidity,
    uint256 fytMinted,
    uint256 ptMinted,
    int24 tickLower,
    int24 tickUpper
);

/// @notice Emitted when FYT redeemed for fees
event FYTRedeemed(
    address indexed redeemer,
    uint256 indexed epochId,
    uint256 fytBurned,
    uint256 fees0Received,
    uint256 fees1Received
);

/// @notice Emitted when PT redeemed for capital
event PTRedeemed(
    address indexed redeemer,
    uint256 indexed epochId,
    uint256 ptBurned,
    uint256 capital0Received,
    uint256 capital1Received
);
```

**RSC subscription configuration:**
```
Event signature:  FeesAccrued(uint256 indexed epochId, uint256 indexed amount0, uint256 amount1)
Topic0 (keccak):  keccak256("FeesAccrued(uint256,uint256,uint256)")
Topic1 filter:    REACTIVE_IGNORE (subscribe to all epochIds)
Topic2 filter:    REACTIVE_IGNORE (subscribe to all amounts)
Chain ID:         (Unichain mainnet or Sepolia — per deployment)
Contract filter:  YieldStreamHook address (specific — not wildcard)
```

---

## 10. State Machine

### Epoch State Machine

```
                     ┌─────────────┐
                     │   INACTIVE  │
                     │  (no epoch) │
                     └──────┬──────┘
                            │ first deposit in new epoch
                            │ _ensureEpochContracts()
                            ▼
                     ┌─────────────┐
              swap   │   ACTIVE    │◄─────────────────────┐
           ────────► │  (accruing  │                      │
           fees emit │   fees)     │   more swaps         │
           FeesAccrd └──────┬──────┘   more deposits      │
                            │                             │
                            │ RSC detects epoch boundary  │
                            │ emits Callback(settleEpoch) │
                            ▼                             │
                     ┌─────────────┐                      │
                     │  SETTLING   │                      │
                     │ (settleEpoch│                      │
                     │  executing) │                      │
                     └──────┬──────┘                      │
                            │                             │
                            │ fees distributed to FYT     │
                            │ PT unlocked for redemption  │
                            │ Morpho yield withdrawn      │
                            ▼                             │
                     ┌─────────────┐                      │
                     │  SETTLED    │                      │
                     │ (redeemable)│      next epoch ─────┘
                     └─────────────┘
```

### LP Position State Machine

```
                ┌──────────────┐
                │   NO POSITION│
                └──────┬───────┘
                       │ addLiquidity()
                       ▼
                ┌──────────────┐
                │   ACTIVE     │
                │ holds FYT+PT │◄── can sell FYT or PT on secondary market
                └──────┬───────┘
                       │ epoch settles (RSC callback)
                       ▼
                ┌──────────────┐
                │   SETTLED    │
                │ can redeem   │
                └──────┬───────┘
                       │ redeemFYT() + redeemPT()
                       ▼
                ┌──────────────┐
                │   EXITED     │
                └──────────────┘
```

---

## 11. RSC Architecture — Deep Dive

### 11.1 How Reactive Network Works (Relevant Subset)

Reactive Smart Contracts (RSCs) are Solidity contracts deployed on Reactive Network that:
1. Subscribe to specific event logs on any EVM-compatible chain using `_subscribe(chainId, contractAddress, topic0, ...)`
2. Execute their `react()` function automatically when a matching event fires — no external trigger needed
3. Can maintain persistent state between `react()` calls on ReactVM
4. Emit `Callback` events that Reactive Network submits as transactions on the destination chain

**Critical constraint:** RSCs have NO native scheduler. They only fire when a subscribed event fires. For YieldStream, this means settlement only triggers when a `FeesAccrued` event fires AFTER the epoch boundary has passed — in practice, on the first swap of the new epoch.

### 11.2 Settlement Timing Analysis

```
Epoch 1: blocks 0 – 50,399
Epoch 2: blocks 50,400 – 100,799

Timeline:
  Block 50,399: last swap of epoch 1 → emits FeesAccrued(epochId=1, ...)
                RSC react(): currentEpoch = 50399/50400 = 0 → epoch 1
                lastSettledEpoch = 1 → no settlement triggered yet

  Block 50,400: first swap of epoch 2 → emits FeesAccrued(epochId=2, ...)
                RSC react(): currentEpoch = 50400/50400 = 1 → epoch 2
                currentEpoch (2) > lastSettledEpoch (1) → TRIGGER SETTLEMENT
                RSC emits Callback(settleEpoch(1))
                Reactive Network submits settleEpoch(1) to hook

Settlement lag: 1 swap after epoch boundary = typically minutes in liquid pools
Worst case: if pool goes idle at epoch boundary, settlement waits for next swap
```

**Handling idle pools:** If a pool receives zero swaps for an extended period spanning an epoch boundary, settlement is delayed until the next swap. This is acceptable and disclosed in the README. Future work: add a permissionless `triggerSettlement()` function that anyone can call after the epoch boundary — serves as manual fallback.

### 11.3 RSC Deployment Steps

```
1. Deploy YieldStreamHook on destination chain (Unichain / Sepolia)
   → Record hook address: 0x...

2. Deploy YieldStreamRSC on Reactive Network
   Constructor args:
     - destinationChainId: 1301 (Unichain) or 11155111 (Sepolia)
     - hookAddress: 0x... (from step 1)
   
3. RSC constructor calls _subscribe() — registers subscription
   → Reactive Network begins monitoring for FeesAccrued events
   
4. Fund RSC with REACT tokens for callback gas
   → Estimate: 0.1 REACT per epoch settlement (300k gas × gas price)

5. Verify subscription on Reactive Network explorer
   → Should show: contract=hookAddress, topic0=FEES_ACCRUED_TOPIC, status=ACTIVE

6. Run integration test:
   → Execute a swap on hook pool
   → Verify FeesAccrued event emitted on destination chain
   → Verify RSC react() executed on Reactive Network
   → At epoch boundary: verify settleEpoch() callback submitted to hook
```

---

## 12. Epoch Lifecycle

### 12.1 Full Lifecycle Walkthrough

**Week 1, Monday 00:00 UTC — Epoch 1 Starts (block N)**
```
Alice deposits 10 ETH + 20,000 USDC
→ afterAddLiquidity fires
→ _ensureEpochContracts(epochId=1) deploys FYT_1 and PT_1 ERC-20s
→ EpochState[1] initialized: startBlock=N, totalLiquidity=0
→ Alice's liquidity: 1000 units (hypothetical)
→ epochState[1].totalLiquidity += 1000
→ FYT_1.mint(Alice, 1000) — Alice gets 1000 FYT_1
→ PT_1.mint(Alice, 1000)  — Alice gets 1000 PT_1
→ emit PositionCreated(Alice, 1, 1000, 1000, 1000, ...)
→ Idle capital deposited into Morpho (via MorphoAdapter)
```

**Alice sells FYT_1 immediately:**
```
Alice → Uniswap v3 FYT_1/USDC pool → sells 1000 FYT_1 for 150 USDC
Alice has locked in: 150 USDC upfront, regardless of actual fees earned
FYT_1 buyer now holds 1000 FYT_1 — betting fees will exceed 150 USDC
```

**Week 1, various times — Swaps occur:**
```
Each swap → afterSwap fires → fees extracted from BalanceDelta
→ epochFees0[1] += fee0
→ epochFees1[1] += fee1
→ emit FeesAccrued(epochId=1, amount0=fee0, amount1=fee1)
→ RSC react() fires, accumulates fees in ReactVM state
```

**Week 1, Sunday 23:59 UTC — Epoch 1 ends (block N + 50,399)**
```
Last swap: emits FeesAccrued(epochId=1, ...)
RSC: currentEpoch = 1, lastSettledEpoch = 1 → no action yet
```

**Week 2, Monday 00:01 UTC — First swap of Epoch 2 (block N + 50,400)**
```
Swap emits: FeesAccrued(epochId=2, ...)
RSC react(): currentEpoch = 2, lastSettledEpoch = 1
→ 2 > 1 → trigger settlement of epoch 1
→ emit Callback(settleEpoch(1))
→ Reactive Network submits settleEpoch(1) to hook
```

**settleEpoch(1) executes on hook:**
```
1. Verify epoch 1 is past end block ✓
2. Withdraw Morpho yield: morphoYield0, morphoYield1
3. Compute total distribution:
   - totalFees0[1] = 0.5 ETH (accumulated over week)
   - totalFees1[1] = 800 USDC
   - morphoYield0  = 0.01 ETH
   - morphoYield1  = 20 USDC
   - FYT distribution: 0.5 ETH + 0.01 ETH = 0.51 ETH, 820 USDC
4. FYT_1.settle(feesPerToken0=0.51e18/1000, feesPerToken1=820e6/1000)
5. PT_1.enableRedemption(capitalPerToken0=..., capitalPerToken1=...)
6. epochState[1].settled = true
7. emit EpochSettled(1, totalFees0, totalFees1, morphoYield0, morphoYield1, 1000)
```

**FYT_1 buyer redeems:**
```
FYT buyer (holds 1000 FYT_1) calls redeemFYT(epochId=1, amount=1000)
→ FYT_1.redeem(buyer)
→ Receives: 0.51 ETH + 820 USDC
→ Paid 150 USDC for the FYT → net profit: 0.51 ETH + 670 USDC
```

**Alice redeems PT_1:**
```
Alice (holds 1000 PT_1) calls redeemPT(epochId=1, amount=1000)
→ PT_1.redeem(Alice)
→ Receives: underlying capital (10 ETH + 20,000 USDC minus IL)
→ Guaranteed result regardless of fee revenue
```

---

## 13. Token Economics

### 13.1 FYT Pricing Model

FYT fair value at any point in an epoch:
```
FYT_fair_value = (fees_accrued_so_far + expected_remaining_fees) / total_FYT_supply

Where:
  expected_remaining_fees = trailing_7d_fees_per_block × blocks_remaining_in_epoch
  (this is what secondary market participants will model)
```

FYT discount to fair value (seller's cost of certainty):
```
FYT_sell_price = FYT_fair_value × (1 - discount_rate)
discount_rate  = f(pool_volatility, epoch_time_remaining, LP_risk_preference)
```

### 13.2 PT Pricing Model

PT fair value accounts for IL:
```
PT_fair_value = deposited_capital × (1 - expected_IL_by_epoch_end)

Expected IL = 2√(price_ratio) / (1 + price_ratio) - 1
  where price_ratio = current_price / entry_price
```

### 13.3 FYT Supply Calculation

FYT minted per LP = proportional to liquidity share:
```
fyt_minted = (lp_liquidity / epoch_total_liquidity) × FYT_PRECISION
```

Where `FYT_PRECISION = 1e18` ensures no precision loss for small liquidity shares.

Late deposits within same epoch receive fewer FYT relative to early deposits (they provided liquidity for fewer blocks). Implementation:
```
liquidity_blocks = liquidity × (epoch_end_block - deposit_block)
fyt_minted = (liquidity_blocks / epoch_total_liquidity_blocks) × FYT_PRECISION
```

This rewards early LPs correctly and prevents gaming via late-epoch deposits.

### 13.4 Fee Distribution Formula

At settlement:
```
fees_per_fyt_token0 = epochFees0[epochId] / FYT_total_supply
fees_per_fyt_token1 = epochFees1[epochId] / FYT_total_supply

FYT holder receives:
  fees0 = fyt_balance × fees_per_fyt_token0 / FYT_PRECISION
  fees1 = fyt_balance × fees_per_fyt_token1 / FYT_PRECISION
```

---

## 14. Risk Model

### 14.1 Risk Matrix

| Risk | Who bears it | Magnitude | Mitigation |
|------|-------------|-----------|------------|
| Yield variance (fees lower than FYT price paid) | FYT buyer | Medium | Secondary market pricing reflects expected fees |
| Impermanent loss | PT holder | Medium–High | Fully disclosed; PT price reflects expected IL |
| Settlement delay (idle pool) | All parties | Low | Permissionless `triggerSettlement()` fallback |
| RSC failure / Reactive Network downtime | All parties | Low | Permissionless fallback trigger; 7-day settlement window |
| Smart contract bug | All parties | High | Foundry tests, audit before mainnet |
| Morpho protocol risk | PT holders | Low | Morpho is blue-chip; idle capital withdrawal at settlement |
| FYT price manipulation | FYT buyers | Low | FYT pricing determined by open secondary market |
| Epoch lockup risk | LPs | Low | LPs can sell PT on secondary market to exit early |

### 14.2 Where the Risk Goes — One Sentence

> FYT buyers absorb all fee variance risk; PT holders absorb all IL risk; the hook's Morpho integration absorbs none — it only amplifies PT holders' returns on idle capital.

### 14.3 Edge Cases

**Edge case 1: Zero swaps in an epoch**
- No fees accrued → `epochFees0 = epochFees1 = 0`
- FYT settles at zero value — FYT buyer receives nothing
- PT holders receive full capital return (no IL from zero swaps likely)
- Mitigation: FYT secondary market price will reflect low-volume risk

**Edge case 2: Partial epoch deposit (LP deposits on last day of epoch)**
- LP receives fewer FYT due to `liquidity_blocks` weighting
- LP still receives full PT (capital claim unaffected by timing)
- Important to document clearly in UX

**Edge case 3: Pool price goes to zero (token rug)**
- PT holders receive near-zero capital at redemption
- FYT holders received their fees — unaffected by price
- No hook-specific mitigation — standard LP risk

**Edge case 4: Multiple LPs depositing at different points in epoch**
- All share the same FYT_epochId and PT_epochId ERC-20 contracts
- `liquidity_blocks` weighting ensures fair distribution
- Stress test: verify 100 LPs depositing at random blocks within epoch all receive correct shares

---

## 15. Security Considerations

### 15.1 Access Control

```
settleEpoch(uint256 epochId)
  modifier: onlyRSC
  check: msg.sender == RSC_CALLER
  RSC_CALLER: set in constructor, immutable
  → Prevents any EOA or contract from settling epoch prematurely

redeemFYT(uint256 epochId, uint256 amount)
  check: epochState[epochId].settled == true
  → Prevents redemption before settlement

redeemPT(uint256 epochId, uint256 amount)  
  check: PT[epochId].redeemable == true
  → Prevents capital withdrawal before settlement

FYT.mint() / PT.mint()
  modifier: onlyHook
  check: msg.sender == hookAddress
  → Only hook can mint tokens

FYT.settle() / PT.enableRedemption()
  modifier: onlyHook
  check: msg.sender == hookAddress
  → Only hook can trigger settlement logic on token contracts
```

### 15.2 Reentrancy

All state changes in `settleEpoch()`, `redeemFYT()`, and `redeemPT()` follow checks-effects-interactions:
1. Update `settled` flag / `redeemable` flag FIRST
2. Update accounting storage
3. Transfer tokens LAST

Use `nonReentrant` modifier on `settleEpoch`, `redeemFYT`, `redeemPT`.

### 15.3 Epoch ID Validation

```solidity
function settleEpoch(uint256 epochId) external onlyRSC nonReentrant {
    require(!epochState[epochId].settled, "Already settled");
    require(block.number > epochState[epochId].endBlock, "Epoch not ended");
    require(epochId == currentEpoch() - 1, "Can only settle previous epoch");
    // ... settlement logic
}
```

### 15.4 Integer Overflow / Precision

- Use Solidity 0.8.x built-in overflow protection
- FYT/PT amounts use `uint256` with `1e18` precision
- Fee-per-token division: use `mulDiv` from `FullMath` (v4-core) to avoid precision loss
- All token amounts in native decimals (token0, token1)

### 15.5 Liquidity Withdrawal Guard

```solidity
function beforeRemoveLiquidity(...) external override onlyPoolManager returns (bytes4) {
    bytes32 posKey = _positionKey(sender, params.tickLower, params.tickUpper, currentEpoch());
    PositionInfo memory pos = positions[posKey];
    
    require(
        epochState[pos.epochId].settled,
        "YieldStream: epoch not yet settled — sell PT on secondary market to exit early"
    );
    
    return BaseHook.beforeRemoveLiquidity.selector;
}
```

---

## 16. Test Plan

### 16.1 Unit Tests (Foundry)

```
test/YieldStreamHook.t.sol

Epoch Management:
  ✓ test_currentEpoch_returnsCorrectId
  ✓ test_epochContracts_deployedOnFirstDeposit
  ✓ test_epochContracts_reuseExistingForSameEpoch
  ✓ test_epochId_incrementsCorrectlyAtBoundary

Deposit & Minting:
  ✓ test_afterAddLiquidity_mintsFYTAndPT
  ✓ test_afterAddLiquidity_correctFYTAmount_singleLP
  ✓ test_afterAddLiquidity_correctFYTAmount_multipleLP
  ✓ test_afterAddLiquidity_liquidityBlocksWeighting
  ✓ test_afterAddLiquidity_lateEpochDeposit_receivesLessFYT

Fee Accrual:
  ✓ test_afterSwap_accruesToEpochFees
  ✓ test_afterSwap_emitsFeesAccruedEvent
  ✓ test_afterSwap_correctFeeExtraction
  ✓ test_afterSwap_accumulatesAcrossMultipleSwaps

Settlement:
  ✓ test_settleEpoch_onlyRSC
  ✓ test_settleEpoch_revertsIfAlreadySettled
  ✓ test_settleEpoch_revertsIfEpochNotEnded
  ✓ test_settleEpoch_setsSettledFlag
  ✓ test_settleEpoch_distributesFeesProperly
  ✓ test_settleEpoch_withdrawsMorphoYield
  ✓ test_settleEpoch_emitsEpochSettledEvent

Redemption:
  ✓ test_redeemFYT_revertsBeforeSettlement
  ✓ test_redeemFYT_correctFeeShare_singleHolder
  ✓ test_redeemFYT_correctFeeShare_multipleHolders
  ✓ test_redeemFYT_burnsFYTTokens
  ✓ test_redeemPT_revertsBeforeSettlement
  ✓ test_redeemPT_returnsCapital
  ✓ test_redeemPT_burnsPTTokens

Lockup:
  ✓ test_beforeRemoveLiquidity_revertsIfNotSettled
  ✓ test_beforeRemoveLiquidity_allowsAfterSettlement

Edge Cases:
  ✓ test_zeroFeeEpoch_FYTSettlesAtZero_PTUnaffected
  ✓ test_singleLPGetsAllFees
  ✓ test_100LPs_allReceiveCorrectShares
  ✓ test_FYT_transferability_doesNotAffectRedemption
  ✓ test_PT_transferability_newOwnerCanRedeem
```

### 16.2 Integration Tests

```
test/YieldStreamIntegration.t.sol

Full Lifecycle:
  ✓ test_fullEpoch_singleLP_holdsAll
  ✓ test_fullEpoch_LP_sellsFYT_holdsThirdPartyRedeems
  ✓ test_fullEpoch_LP_sellsBoth_thirdPartiesRedeem
  ✓ test_multipleEpochs_consecutiveLifecycles
  ✓ test_epochBoundary_firstSwapTriggersRSCSettlement

RSC Simulation:
  ✓ test_rscCallback_simulation_settlesCorrectly
  ✓ test_rscCallback_onlyAuthorizedCaller
  ✓ test_settlementDelay_idlePool_manualFallback
```

### 16.3 Fuzz Tests

```
  ✓ fuzz_feeDistribution_invariant(uint256 lpCount, uint256[] liquidities)
    Invariant: sum(FYT_redeemed_fees) == epochFees (within rounding)
    
  ✓ fuzz_ptRedemption_invariant(uint256 lpCount, uint256[] liquidities)  
    Invariant: sum(PT_redeemed_capital) <= totalDepositedCapital
    
  ✓ fuzz_liquidityBlockWeighting(uint256[] depositBlocks, uint256[] liquidities)
    Invariant: early depositors always receive >= late depositors per unit liquidity
```

### 16.4 Stress Tests

```
  ✓ stress_100LPs_random_epochs_no_lost_funds
  ✓ stress_settlement_with_10000_pending_redemptions
  ✓ stress_morpho_deposit_withdraw_rounding
```

---

## 17. Deployment Plan

### 17.1 Contracts to Deploy

| Contract | Chain | Order | Constructor args |
|----------|-------|-------|-----------------|
| `MorphoAdapter` | Unichain / Sepolia | 1st | `morphoAddress` |
| `YieldStreamHook` | Unichain / Sepolia | 2nd | `poolManager, morphoAdapter, RSC_CALLER` |
| `YieldStreamRSC` | Reactive Network | 3rd | `destinationChainId, hookAddress` |

### 17.2 Hook Address Mining

Uniswap v4 hook addresses must have specific bit flags in the address. Use `HookMiner.find()` from v4-periphery:

```solidity
// Required flags for YieldStream
uint160 flags = uint160(
    Hooks.AFTER_ADD_LIQUIDITY_FLAG |
    Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
    Hooks.AFTER_SWAP_FLAG
);

// Mine address with correct flags
(address hookAddress, bytes32 salt) = HookMiner.find(
    deployer,
    flags,
    type(YieldStreamHook).creationCode,
    abi.encode(poolManager, morphoAdapter, RSC_CALLER)
);
```

### 17.3 Pool Initialization

```solidity
// Initialize test pool: WETH/USDC with 0.3% fee tier
PoolKey memory key = PoolKey({
    currency0: Currency.wrap(WETH),
    currency1: Currency.wrap(USDC),
    fee: 3000,
    tickSpacing: 60,
    hooks: IHooks(hookAddress)
});

poolManager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);
```

### 17.4 RSC Funding

```bash
# Fund RSC with REACT tokens for callback gas
# Minimum: 1 REACT (covers ~10 epoch settlements at testnet gas prices)
reactive-cli fund --contract $RSC_ADDRESS --amount 1.0
```

### 17.5 Deployment Script

```solidity
// script/Deploy.s.sol
contract DeployYieldStream is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        
        vm.startBroadcast(deployerKey);
        
        // 1. Deploy Morpho adapter
        MorphoAdapter morphoAdapter = new MorphoAdapter(MORPHO_ADDRESS);
        
        // 2. Mine hook address with correct flags
        (address hookAddress, bytes32 salt) = HookMiner.find(
            deployer, FLAGS,
            type(YieldStreamHook).creationCode,
            abi.encode(POOL_MANAGER, address(morphoAdapter), RSC_CALLER_PLACEHOLDER)
        );
        
        // 3. Deploy hook at mined address
        YieldStreamHook hook = new YieldStreamHook{salt: salt}(
            IPoolManager(POOL_MANAGER),
            address(morphoAdapter),
            RSC_CALLER_PLACEHOLDER // will update after RSC deploy
        );
        
        require(address(hook) == hookAddress, "Hook address mismatch");
        
        vm.stopBroadcast();
        
        console.log("MorphoAdapter:", address(morphoAdapter));
        console.log("YieldStreamHook:", address(hook));
        console.log("Deploy RSC on Reactive Network with hookAddress:", address(hook));
    }
}
```

---

## 18. Known Limitations & Future Work

### 18.1 Current Limitations

| Limitation | Impact | Workaround |
|------------|--------|------------|
| Settlement requires a swap after epoch boundary | Idle pools may have delayed settlement | Permissionless `triggerSettlement()` fallback |
| FYT pricing requires secondary market liquidity | Low-volume pools may have illiquid FYT market | Bootstrap FYT/USDC pool as part of launch |
| Single-pool per hook (one pair) | Each pool needs its own hook deployment | Deploy multiple instances |
| No partial epoch exits on-chain | LPs locked until epoch end | PT tradeable on secondary market |
| Morpho market selection is fixed at deploy | Cannot dynamically optimize yield source | Future: add yield router |

### 18.2 Future Work

- **Multi-epoch FYT rolling:** Let LPs auto-roll into the next epoch without re-depositing
- **FYT options:** Build put/call options on FYT for more sophisticated yield management
- **Cross-pool FYT aggregation:** Aggregate fee yield from multiple pools into a single FYT
- **Yield router:** Dynamic selection of Morpho vs Aave vs Compound for idle capital
- **Pendle integration:** List FYT on Pendle's secondary market for deeper yield trading liquidity
- **EigenLayer AVS:** Replace RSC with an EigenLayer AVS for additional economic security on settlement
- **Fixed-APY tranching:** Combine YieldStream with FixedIncomeTranche hook — senior buys PT + FYT coverage guarantee, junior provides yield floor

---

## Appendix A — File Structure

```
yieldstream/
├── src/
│   ├── YieldStreamHook.sol          # Main hook contract
│   ├── tokens/
│   │   ├── FutureYieldToken.sol     # FYT ERC-20
│   │   └── PrincipalToken.sol       # PT ERC-20
│   ├── rsc/
│   │   └── YieldStreamRSC.sol       # Reactive Smart Contract
│   └── adapters/
│       └── MorphoAdapter.sol        # Morpho yield integration
├── test/
│   ├── YieldStreamHook.t.sol        # Unit tests
│   ├── YieldStreamIntegration.t.sol # Integration tests
│   └── utils/
│       └── YieldStreamTestHelper.sol
├── script/
│   └── Deploy.s.sol                 # Deployment script
├── SPEC.md                          # This document
├── README.md                        # Judge-facing README
└── foundry.toml
```

## Appendix B — Glossary

| Term | Definition |
|------|------------|
| **FYT** | Future Yield Token — ERC-20 representing claim on an epoch's swap fees |
| **PT** | Principal Token — ERC-20 representing claim on underlying LP capital at epoch end |
| **Epoch** | Fixed time window (50,400 blocks ≈ 7 days) over which fees are accumulated |
| **RSC** | Reactive Smart Contract — deployed on Reactive Network, fires settlement callbacks |
| **ReactVM** | Reactive Network's execution environment where RSC logic runs |
| **Settlement** | RSC-triggered epoch close — fees distributed to FYT, capital unlocked for PT |
| **IL** | Impermanent Loss — loss in LP position value relative to holding when price diverged |
| **BalanceDelta** | v4 primitive representing token balance changes from a swap or liquidity event |
| **Hook flags** | Bitmask in hook address encoding which callbacks the hook uses |
| **liquidity_blocks** | Liquidity weighted by blocks provided — used for fair FYT share calculation |

---

*YieldStream · UHI9 Hookathon · @najnomics*
