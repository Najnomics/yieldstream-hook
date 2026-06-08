// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "v4-hooks-public/src/base/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IUnlockCallback} from "@uniswap/v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {FutureYieldToken} from "./tokens/FutureYieldToken.sol";
import {PrincipalToken} from "./tokens/PrincipalToken.sol";
import {IYieldStreamRedeemer} from "./interfaces/IYieldStreamRedeemer.sol";

interface IERC20Transfer {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IReactivePayable {
    function debt(address contract_) external view returns (uint256 debt_);
}

interface IYieldStreamTokenFactory {
    function createTokens(uint256 epochId, address hook) external returns (address fyt, address pt);
}

contract YieldStreamHook is BaseHook, IYieldStreamRedeemer, IUnlockCallback {
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencyLibrary for Currency;

    error OnlyRSC();
    error OnlyEpochToken();
    error EpochActive();
    error EpochSettledAlready();
    error EpochNotStarted();
    error NothingToRedeem();
    error NoPosition();
    error OnlyOwner();
    error InvalidAddress();
    error TokenTransferFailed();
    error TransferFailed();
    error UnsupportedPool();
    error OnlyFeeReporter();
    error NativeFeeReportUnsupported();
    error OnlyHookManagedLiquidity();
    error OnlyPoolManagerUnlock();
    error SlippageExceeded();

    uint256 public constant DEFAULT_EPOCH_LENGTH = 50_400;
    uint256 public constant PRECISION = 1e18;
    bytes4 internal constant MANAGED_LIQUIDITY_MAGIC = bytes4(keccak256("YieldStreamManagedLiquidity"));

    struct EpochState {
        uint256 epochId;
        uint256 startBlock;
        uint256 endBlock;
        uint256 totalLiquidity;
        uint256 totalLiquidityBlocks;
        uint256 totalFees0;
        uint256 totalFees1;
        uint256 totalCapital0;
        uint256 totalCapital1;
        bool settled;
        address fytContract;
        address ptContract;
        Currency currency0;
        Currency currency1;
        bool hasManagedPositions;
    }

    struct PositionInfo {
        uint256 epochId;
        uint256 liquidity;
        uint256 fytMinted;
        uint256 ptMinted;
        int24 tickLower;
        int24 tickUpper;
        address owner;
        uint256 depositBlock;
        bytes32 salt;
        bool managed;
        bool withdrawn;
    }

    struct ManagedLiquidityParams {
        PoolKey key;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        bytes32 salt;
        uint256 maxAmount0;
        uint256 maxAmount1;
    }

    struct UnlockData {
        uint8 action;
        address beneficiary;
        uint256 epochId;
        PoolKey key;
        ModifyLiquidityParams params;
    }

    mapping(uint256 => EpochState) internal _epochs;
    mapping(bytes32 => PositionInfo) public positions;
    mapping(uint256 => address) public fytContracts;
    mapping(uint256 => address) public ptContracts;
    mapping(uint256 => uint256) public epochFees0;
    mapping(uint256 => uint256) public epochFees1;
    mapping(bytes32 => uint256) public activePositionEpochPlusOne;
    mapping(uint256 => bytes32[]) internal _epochPositionKeys;

    address public owner;
    address public callbackProxy;
    address public reactiveSender;
    address public directSettlementCaller;
    address public feeReporter;
    address public immutable tokenFactory;
    address public immutable morphoAdapter;
    uint256 public immutable epochLength;
    bytes32 public poolKeyHash;
    bool public poolConfigured;
    Currency internal configuredCurrency0;
    Currency internal configuredCurrency1;
    uint24 internal configuredFee;
    int24 internal configuredTickSpacing;
    IHooks internal configuredHooks;

    event FeesAccrued(uint256 indexed epochId, uint256 indexed amount0, uint256 amount1);
    event EpochStarted(uint256 indexed epochId, uint256 startBlock, address fytContract, address ptContract);
    event EpochSettled(
        uint256 indexed epochId,
        uint256 totalFees0,
        uint256 totalFees1,
        uint256 morphoYield0,
        uint256 morphoYield1,
        uint256 totalLiquidity
    );
    event PositionCreated(
        address indexed owner,
        uint256 indexed epochId,
        uint256 liquidity,
        uint256 fytMinted,
        uint256 ptMinted,
        int24 tickLower,
        int24 tickUpper
    );
    event FYTRedeemed(
        address indexed redeemer,
        uint256 indexed epochId,
        uint256 fytBurned,
        uint256 fees0Received,
        uint256 fees1Received
    );
    event PTRedeemed(
        address indexed redeemer,
        uint256 indexed epochId,
        uint256 ptBurned,
        uint256 capital0Received,
        uint256 capital1Received
    );
    event ReactiveSenderUpdated(address indexed reactiveSender);
    event CallbackProxyUpdated(address indexed callbackProxy);
    event DirectSettlementCallerUpdated(address indexed directSettlementCaller);
    event FeeReporterUpdated(address indexed feeReporter);
    event PoolConfigured(bytes32 indexed poolKeyHash, Currency indexed currency0, Currency indexed currency1);
    event ManagedLiquidityDeposited(
        address indexed owner,
        uint256 indexed epochId,
        bytes32 indexed positionKey,
        uint256 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    event ManagedLiquidityWithdrawn(
        uint256 indexed epochId, bytes32 indexed positionKey, uint256 liquidity, uint256 amount0, uint256 amount1
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyDirectSettlementCaller() {
        if (msg.sender != directSettlementCaller) revert OnlyRSC();
        _;
    }

    modifier onlyFeeReporter() {
        if (msg.sender != feeReporter) revert OnlyFeeReporter();
        _;
    }

    constructor(
        IPoolManager poolManager,
        address _tokenFactory,
        address _morphoAdapter,
        address _callbackProxy,
        address _directSettlementCaller,
        address _owner,
        uint256 _epochLength
    ) BaseHook(poolManager) {
        if (_owner == address(0)) revert InvalidAddress();
        owner = _owner;
        feeReporter = _owner;
        tokenFactory = _tokenFactory;
        morphoAdapter = _morphoAdapter;
        callbackProxy = _callbackProxy;
        directSettlementCaller = _directSettlementCaller;
        epochLength = _epochLength == 0 ? DEFAULT_EPOCH_LENGTH : _epochLength;
        emit OwnershipTransferred(address(0), _owner);
        emit FeeReporterUpdated(_owner);
        emit CallbackProxyUpdated(_callbackProxy);
        emit DirectSettlementCallerUpdated(_directSettlementCaller);
    }

    receive() external payable {}

    function pay(uint256 amount) external {
        if (msg.sender != callbackProxy) revert OnlyRSC();
        _pay(payable(msg.sender), amount);
    }

    function coverCallbackDebt() external {
        _pay(payable(callbackProxy), IReactivePayable(callbackProxy).debt(address(this)));
    }

    function callbackDebt() external view returns (uint256) {
        return IReactivePayable(callbackProxy).debt(address(this));
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function currentEpoch() public view returns (uint256) {
        return block.number / epochLength;
    }

    function getFYTContract(uint256 epochId) external view returns (address) {
        return fytContracts[epochId];
    }

    function getPTContract(uint256 epochId) external view returns (address) {
        return ptContracts[epochId];
    }

    function getEpochFees(uint256 epochId) external view returns (uint256 fees0, uint256 fees1) {
        return (epochFees0[epochId], epochFees1[epochId]);
    }

    function isEpochSettled(uint256 epochId) external view returns (bool) {
        return _epochs[epochId].settled;
    }

    function getEpochTotals(uint256 epochId)
        external
        view
        returns (
            uint256 totalLiquidity,
            uint256 totalFees0,
            uint256 totalFees1,
            uint256 totalCapital0,
            uint256 totalCapital1
        )
    {
        EpochState storage epoch = _epochs[epochId];
        return (epoch.totalLiquidity, epoch.totalFees0, epoch.totalFees1, epoch.totalCapital0, epoch.totalCapital1);
    }

    function setReactiveSender(address _reactiveSender) external onlyOwner {
        if (_reactiveSender == address(0)) revert InvalidAddress();
        reactiveSender = _reactiveSender;
        emit ReactiveSenderUpdated(_reactiveSender);
    }

    function setCallbackProxy(address _callbackProxy) external onlyOwner {
        if (_callbackProxy == address(0)) revert InvalidAddress();
        callbackProxy = _callbackProxy;
        emit CallbackProxyUpdated(_callbackProxy);
    }

    function setDirectSettlementCaller(address _directSettlementCaller) external onlyOwner {
        if (_directSettlementCaller == address(0)) revert InvalidAddress();
        directSettlementCaller = _directSettlementCaller;
        emit DirectSettlementCallerUpdated(_directSettlementCaller);
    }

    function setFeeReporter(address _feeReporter) external onlyOwner {
        if (_feeReporter == address(0)) revert InvalidAddress();
        feeReporter = _feeReporter;
        emit FeeReporterUpdated(_feeReporter);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function settleEpoch(uint256 epochId) external onlyDirectSettlementCaller {
        _settleEpoch(epochId);
    }

    function settleEpochFromReactive(address sender, uint256 epochId) external {
        if (msg.sender != callbackProxy || sender != reactiveSender) revert OnlyRSC();
        _settleEpoch(epochId);
    }

    function triggerSettlement(uint256 epochId) external {
        _settleEpoch(epochId);
    }

    function depositManagedLiquidity(ManagedLiquidityParams calldata params)
        external
        returns (uint256 epochId, uint256 amount0, uint256 amount1)
    {
        if (params.liquidity == 0) revert NoPosition();
        _validatePool(params.key);
        epochId = currentEpoch();

        _pullDeposit(params.key.currency0, params.maxAmount0);
        _pullDeposit(params.key.currency1, params.maxAmount1);

        bytes32 custodySalt = _custodySalt(msg.sender, epochId, params.tickLower, params.tickUpper, params.salt);
        ModifyLiquidityParams memory modifyParams = ModifyLiquidityParams({
            tickLower: params.tickLower,
            tickUpper: params.tickUpper,
            liquidityDelta: int256(uint256(params.liquidity)),
            salt: custodySalt
        });

        BalanceDelta delta = abi.decode(
            poolManager.unlock(
                abi.encode(
                    UnlockData({
                        action: 1,
                        beneficiary: msg.sender,
                        epochId: epochId,
                        key: params.key,
                        params: modifyParams
                    })
                )
            ),
            (BalanceDelta)
        );

        amount0 = delta.amount0() < 0 ? _abs(delta.amount0()) : 0;
        amount1 = delta.amount1() < 0 ? _abs(delta.amount1()) : 0;
        if (amount0 > params.maxAmount0 || amount1 > params.maxAmount1) revert SlippageExceeded();
        _refundDeposit(params.key.currency0, msg.sender, params.maxAmount0 - amount0);
        _refundDeposit(params.key.currency1, msg.sender, params.maxAmount1 - amount1);

        _recordManagedPosition(
            params.key,
            msg.sender,
            epochId,
            params.tickLower,
            params.tickUpper,
            custodySalt,
            params.liquidity,
            amount0,
            amount1
        );

        bytes32 posKey =
            _positionKey(poolKeyHash, msg.sender, params.tickLower, params.tickUpper, custodySalt, epochId);
        emit ManagedLiquidityDeposited(msg.sender, epochId, posKey, params.liquidity, amount0, amount1);
    }

    function unlockCallback(bytes calldata rawData) external override returns (bytes memory) {
        if (msg.sender != address(poolManager)) revert OnlyPoolManagerUnlock();
        UnlockData memory data = abi.decode(rawData, (UnlockData));

        if (data.action == 1) {
            (BalanceDelta delta,) = poolManager.modifyLiquidity(
                data.key, data.params, abi.encode(MANAGED_LIQUIDITY_MAGIC, data.beneficiary, data.epochId)
            );
            _settleOrTake(data.key.currency0, delta.amount0());
            _settleOrTake(data.key.currency1, delta.amount1());
            return abi.encode(delta);
        }

        if (data.action == 2) {
            (BalanceDelta delta,) = poolManager.modifyLiquidity(
                data.key, data.params, abi.encode(MANAGED_LIQUIDITY_MAGIC, data.beneficiary, data.epochId)
            );
            _settleOrTake(data.key.currency0, delta.amount0());
            _settleOrTake(data.key.currency1, delta.amount1());
            return abi.encode(delta);
        }

        revert NoPosition();
    }

    function reportFees(PoolKey calldata key, uint256 epochId, uint256 amount0, uint256 amount1)
        external
        onlyFeeReporter
    {
        _validatePool(key);
        EpochState storage epoch = _epochs[epochId];
        if (epoch.fytContract == address(0)) revert EpochNotStarted();
        if (epoch.settled) revert EpochSettledAlready();
        if (amount0 == 0 && amount1 == 0) revert NothingToRedeem();

        _pullReportedFees(epoch.currency0, amount0);
        _pullReportedFees(epoch.currency1, amount1);

        epoch.totalFees0 += amount0;
        epoch.totalFees1 += amount1;
        epochFees0[epochId] += amount0;
        epochFees1[epochId] += amount1;
        emit FeesAccrued(epochId, amount0, amount1);
    }

    function redeemFYT(uint256 epochId, uint256 amount) external returns (uint256 fees0, uint256 fees1) {
        return _redeemFYT(epochId, msg.sender, msg.sender, amount);
    }

    function redeemPT(uint256 epochId, uint256 amount) external returns (uint256 capital0, uint256 capital1) {
        return _redeemPT(epochId, msg.sender, msg.sender, amount);
    }

    function redeemFYTFor(address holder, address recipient, uint256 amount)
        external
        returns (uint256 fees0, uint256 fees1)
    {
        uint256 epochId = FutureYieldToken(msg.sender).epochId();
        if (msg.sender != fytContracts[epochId]) revert OnlyEpochToken();
        return _redeemFYT(epochId, holder, recipient, amount);
    }

    function redeemPTFor(address holder, address recipient, uint256 amount)
        external
        returns (uint256 capital0, uint256 capital1)
    {
        uint256 epochId = PrincipalToken(msg.sender).epochId();
        if (msg.sender != ptContracts[epochId]) revert OnlyEpochToken();
        return _redeemPT(epochId, holder, recipient, amount);
    }

    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        (address beneficiary, uint256 managedEpochId, bool managed) = _decodeManagedHookData(sender, hookData);
        if (!managed) revert OnlyHookManagedLiquidity();

        uint256 epochId = currentEpoch();
        if (managedEpochId != epochId) revert EpochActive();
        bytes32 poolHash = _validatePool(key);
        _ensureEpochContracts(epochId, key);

        uint256 liquidity = _abs(params.liquidityDelta);
        if (liquidity == 0) revert NoPosition();

        uint256 remainingBlocks =
            _epochs[epochId].endBlock > block.number ? _epochs[epochId].endBlock - block.number : 1;
        uint256 fytAmount = liquidity * remainingBlocks;
        uint256 ptAmount = liquidity;
        (uint256 capital0, uint256 capital1) = _capitalFromDelta(delta);

        _epochs[epochId].totalLiquidity += liquidity;
        _epochs[epochId].totalLiquidityBlocks += fytAmount;
        _epochs[epochId].totalCapital0 += capital0;
        _epochs[epochId].totalCapital1 += capital1;

        FutureYieldToken(fytContracts[epochId]).mint(beneficiary, fytAmount);
        PrincipalToken(ptContracts[epochId]).mint(beneficiary, ptAmount);

        bytes32 basePosKey = _basePositionKey(poolHash, beneficiary, params.tickLower, params.tickUpper, params.salt);
        bytes32 posKey = _positionKey(poolHash, beneficiary, params.tickLower, params.tickUpper, params.salt, epochId);
        PositionInfo storage position = positions[posKey];
        bool poolBacked = msg.sender == address(poolManager);
        if (position.owner == address(0)) {
            position.epochId = epochId;
            position.tickLower = params.tickLower;
            position.tickUpper = params.tickUpper;
            position.owner = beneficiary;
            position.depositBlock = block.number;
            position.salt = params.salt;
            position.managed = poolBacked;
            activePositionEpochPlusOne[basePosKey] = epochId + 1;
            if (poolBacked) _epochPositionKeys[epochId].push(posKey);
        }
        position.liquidity += liquidity;
        position.fytMinted += fytAmount;
        position.ptMinted += ptAmount;
        if (poolBacked) _epochs[epochId].hasManagedPositions = true;

        emit PositionCreated(beneficiary, epochId, liquidity, fytAmount, ptAmount, params.tickLower, params.tickUpper);
        return (BaseHook.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }

    function _beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) internal view override returns (bytes4) {
        (address beneficiary, uint256 managedEpochId, bool managed) = _decodeManagedHookData(sender, hookData);
        if (!managed) revert OnlyHookManagedLiquidity();
        bytes32 poolHash = _poolKeyHash(key);
        if (!poolConfigured || poolHash != poolKeyHash) revert UnsupportedPool();
        uint256 epochPlusOne =
            activePositionEpochPlusOne[
                _basePositionKey(poolHash, beneficiary, params.tickLower, params.tickUpper, params.salt)
            ];
        if (epochPlusOne == 0) revert NoPosition();
        uint256 epochId = epochPlusOne - 1;
        if (managedEpochId != epochId) revert NoPosition();
        bytes32 posKey = _positionKey(poolHash, beneficiary, params.tickLower, params.tickUpper, params.salt, epochId);
        if (positions[posKey].owner == address(0)) revert NoPosition();
        if (!_epochs[epochId].settled) revert EpochActive();
        return BaseHook.beforeRemoveLiquidity.selector;
    }

    function _afterSwap(address, PoolKey calldata key, SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        uint256 epochId = currentEpoch();
        _validatePool(key);
        _ensureEpochContracts(epochId, key);
        return (BaseHook.afterSwap.selector, 0);
    }

    function _settleEpoch(uint256 epochId) internal {
        EpochState storage epoch = _epochs[epochId];
        if (epoch.fytContract == address(0)) revert EpochNotStarted();
        if (epoch.settled) revert EpochSettledAlready();
        if (block.number <= epoch.endBlock) revert EpochActive();

        epoch.settled = true;
        if (epoch.hasManagedPositions) {
            epoch.totalCapital0 = 0;
            epoch.totalCapital1 = 0;
            _withdrawManagedLiquidity(epochId);
        }

        uint256 fytSupply = FutureYieldToken(epoch.fytContract).totalSupply();
        uint256 ptSupply = PrincipalToken(epoch.ptContract).totalSupply();
        uint256 feesPerToken0 = fytSupply == 0 ? 0 : (epoch.totalFees0 * PRECISION) / fytSupply;
        uint256 feesPerToken1 = fytSupply == 0 ? 0 : (epoch.totalFees1 * PRECISION) / fytSupply;
        uint256 capitalPerToken0 = ptSupply == 0 ? 0 : (epoch.totalCapital0 * PRECISION) / ptSupply;
        uint256 capitalPerToken1 = ptSupply == 0 ? 0 : (epoch.totalCapital1 * PRECISION) / ptSupply;

        FutureYieldToken(epoch.fytContract).settle(feesPerToken0, feesPerToken1);
        PrincipalToken(epoch.ptContract).enableRedemption(capitalPerToken0, capitalPerToken1);

        emit EpochSettled(
            epochId, epoch.totalFees0, epoch.totalFees1, 0, 0, epoch.totalLiquidity
        );
    }

    function _redeemFYT(uint256 epochId, address holder, address recipient, uint256 amount)
        internal
        returns (uint256 fees0, uint256 fees1)
    {
        EpochState storage epoch = _epochs[epochId];
        if (!epoch.settled) revert EpochActive();
        if (amount == 0) revert NothingToRedeem();

        FutureYieldToken token = FutureYieldToken(epoch.fytContract);
        fees0 = (amount * token.feesPerToken0()) / PRECISION;
        fees1 = (amount * token.feesPerToken1()) / PRECISION;
        token.burn(holder, amount);
        if (fees0 != 0) epoch.currency0.transfer(recipient, fees0);
        if (fees1 != 0) epoch.currency1.transfer(recipient, fees1);
        emit FYTRedeemed(holder, epochId, amount, fees0, fees1);
    }

    function _redeemPT(uint256 epochId, address holder, address recipient, uint256 amount)
        internal
        returns (uint256 capital0, uint256 capital1)
    {
        EpochState storage epoch = _epochs[epochId];
        if (!epoch.settled) revert EpochActive();
        if (amount == 0) revert NothingToRedeem();

        PrincipalToken token = PrincipalToken(epoch.ptContract);
        capital0 = (amount * token.capitalPerToken0()) / PRECISION;
        capital1 = (amount * token.capitalPerToken1()) / PRECISION;
        token.burn(holder, amount);
        if (capital0 != 0) epoch.currency0.transfer(recipient, capital0);
        if (capital1 != 0) epoch.currency1.transfer(recipient, capital1);
        emit PTRedeemed(holder, epochId, amount, capital0, capital1);
    }

    function _ensureEpochContracts(uint256 epochId, PoolKey calldata key) internal {
        EpochState storage epoch = _epochs[epochId];
        if (epoch.fytContract != address(0)) {
            if (
                Currency.unwrap(epoch.currency0) != Currency.unwrap(key.currency0)
                    || Currency.unwrap(epoch.currency1) != Currency.unwrap(key.currency1)
            ) revert UnsupportedPool();
            return;
        }

        uint256 startBlock = epochId * epochLength;
        (address fyt, address pt) = IYieldStreamTokenFactory(tokenFactory).createTokens(epochId, address(this));

        epoch.epochId = epochId;
        epoch.startBlock = startBlock;
        epoch.endBlock = startBlock + epochLength;
        epoch.fytContract = fyt;
        epoch.ptContract = pt;
        epoch.currency0 = key.currency0;
        epoch.currency1 = key.currency1;
        fytContracts[epochId] = fyt;
        ptContracts[epochId] = pt;

        emit EpochStarted(epochId, startBlock, fyt, pt);
    }

    function _recordManagedPosition(
        PoolKey calldata key,
        address beneficiary,
        uint256 epochId,
        int24 tickLower,
        int24 tickUpper,
        bytes32 custodySalt,
        uint256 liquidity,
        uint256 capital0,
        uint256 capital1
    ) internal {
        _ensureEpochContracts(epochId, key);

        uint256 remainingBlocks =
            _epochs[epochId].endBlock > block.number ? _epochs[epochId].endBlock - block.number : 1;
        uint256 fytAmount = liquidity * remainingBlocks;
        uint256 ptAmount = liquidity;

        _epochs[epochId].totalLiquidity += liquidity;
        _epochs[epochId].totalLiquidityBlocks += fytAmount;
        _epochs[epochId].totalCapital0 += capital0;
        _epochs[epochId].totalCapital1 += capital1;
        _epochs[epochId].hasManagedPositions = true;

        FutureYieldToken(fytContracts[epochId]).mint(beneficiary, fytAmount);
        PrincipalToken(ptContracts[epochId]).mint(beneficiary, ptAmount);

        bytes32 basePosKey = _basePositionKey(poolKeyHash, beneficiary, tickLower, tickUpper, custodySalt);
        bytes32 posKey = _positionKey(poolKeyHash, beneficiary, tickLower, tickUpper, custodySalt, epochId);
        PositionInfo storage position = positions[posKey];
        if (position.owner == address(0)) {
            position.epochId = epochId;
            position.tickLower = tickLower;
            position.tickUpper = tickUpper;
            position.owner = beneficiary;
            position.depositBlock = block.number;
            position.salt = custodySalt;
            position.managed = true;
            activePositionEpochPlusOne[basePosKey] = epochId + 1;
            _epochPositionKeys[epochId].push(posKey);
        }
        position.liquidity += liquidity;
        position.fytMinted += fytAmount;
        position.ptMinted += ptAmount;

        emit PositionCreated(beneficiary, epochId, liquidity, fytAmount, ptAmount, tickLower, tickUpper);
    }

    function _withdrawManagedLiquidity(uint256 epochId) internal {
        PoolKey memory key = _configuredPoolKey();
        bytes32[] storage positionKeys = _epochPositionKeys[epochId];

        for (uint256 i; i < positionKeys.length; i++) {
            bytes32 posKey = positionKeys[i];
            PositionInfo storage position = positions[posKey];
            if (!position.managed || position.withdrawn || position.liquidity == 0) continue;

            position.withdrawn = true;
            ModifyLiquidityParams memory params = ModifyLiquidityParams({
                tickLower: position.tickLower,
                tickUpper: position.tickUpper,
                liquidityDelta: -int256(position.liquidity),
                salt: position.salt
            });

            BalanceDelta delta = abi.decode(
                poolManager.unlock(
                    abi.encode(
                        UnlockData({
                            action: 2,
                            beneficiary: position.owner,
                            epochId: epochId,
                            key: key,
                            params: params
                        })
                    )
                ),
                (BalanceDelta)
            );

            uint256 amount0 = _positive(delta.amount0());
            uint256 amount1 = _positive(delta.amount1());
            _epochs[epochId].totalCapital0 += amount0;
            _epochs[epochId].totalCapital1 += amount1;

            bytes32 basePosKey =
                _basePositionKey(poolKeyHash, position.owner, position.tickLower, position.tickUpper, position.salt);
            delete activePositionEpochPlusOne[basePosKey];

            emit ManagedLiquidityWithdrawn(epochId, posKey, position.liquidity, amount0, amount1);
        }
    }

    function _validatePool(PoolKey calldata key) internal returns (bytes32 expectedHash) {
        expectedHash = _poolKeyHash(key);
        if (!poolConfigured) {
            poolConfigured = true;
            poolKeyHash = expectedHash;
            configuredCurrency0 = key.currency0;
            configuredCurrency1 = key.currency1;
            configuredFee = key.fee;
            configuredTickSpacing = key.tickSpacing;
            configuredHooks = key.hooks;
            emit PoolConfigured(expectedHash, key.currency0, key.currency1);
            return expectedHash;
        }
        if (
            expectedHash != poolKeyHash || Currency.unwrap(key.currency0) != Currency.unwrap(configuredCurrency0)
                || Currency.unwrap(key.currency1) != Currency.unwrap(configuredCurrency1) || key.fee != configuredFee
                || key.tickSpacing != configuredTickSpacing || address(key.hooks) != address(configuredHooks)
        ) revert UnsupportedPool();
    }

    function _configuredPoolKey() internal view returns (PoolKey memory) {
        return PoolKey({
            currency0: configuredCurrency0,
            currency1: configuredCurrency1,
            fee: configuredFee,
            tickSpacing: configuredTickSpacing,
            hooks: configuredHooks
        });
    }

    function _poolKeyHash(PoolKey calldata key) internal pure returns (bytes32) {
        return keccak256(abi.encode(key.currency0, key.currency1, key.fee, key.tickSpacing, key.hooks));
    }

    function _basePositionKey(bytes32 poolHash, address positionOwner, int24 tickLower, int24 tickUpper, bytes32 salt)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(poolHash, positionOwner, tickLower, tickUpper, salt));
    }

    function _positionKey(
        bytes32 poolHash,
        address positionOwner,
        int24 tickLower,
        int24 tickUpper,
        bytes32 salt,
        uint256 epochId
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(poolHash, positionOwner, tickLower, tickUpper, salt, epochId));
    }

    function _custodySalt(address beneficiary, uint256 epochId, int24 tickLower, int24 tickUpper, bytes32 salt)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(beneficiary, epochId, tickLower, tickUpper, salt));
    }

    function _decodeManagedHookData(address sender, bytes calldata hookData)
        internal
        view
        returns (address beneficiary, uint256 epochId, bool managed)
    {
        if (hookData.length != 96 || sender != address(this)) return (address(0), 0, false);
        bytes4 magic;
        (magic, beneficiary, epochId) = abi.decode(hookData, (bytes4, address, uint256));
        if (magic != MANAGED_LIQUIDITY_MAGIC || beneficiary == address(0)) return (address(0), 0, false);
        return (beneficiary, epochId, true);
    }

    function _capitalFromDelta(BalanceDelta delta) internal pure returns (uint256 capital0, uint256 capital1) {
        return (_abs(delta.amount0()), _abs(delta.amount1()));
    }

    function _abs(int256 value) internal pure returns (uint256) {
        return uint256(value < 0 ? -value : value);
    }

    function _positive(int128 value) internal pure returns (uint256) {
        return value > 0 ? uint256(uint128(value)) : 0;
    }

    function _pullDeposit(Currency currency, uint256 amount) internal {
        if (amount == 0) return;
        address token = Currency.unwrap(currency);
        if (token == address(0)) revert NativeFeeReportUnsupported();
        if (!IERC20Transfer(token).transferFrom(msg.sender, address(this), amount)) revert TokenTransferFailed();
    }

    function _refundDeposit(Currency currency, address recipient, uint256 amount) internal {
        if (amount == 0) return;
        address token = Currency.unwrap(currency);
        if (token == address(0)) revert NativeFeeReportUnsupported();
        if (!IERC20Transfer(token).transfer(recipient, amount)) revert TokenTransferFailed();
    }

    function _settleOrTake(Currency currency, int128 delta) internal {
        if (delta < 0) {
            uint256 amount = _abs(delta);
            if (currency.isAddressZero()) revert NativeFeeReportUnsupported();
            poolManager.sync(currency);
            if (!IERC20Transfer(Currency.unwrap(currency)).transfer(address(poolManager), amount)) {
                revert TokenTransferFailed();
            }
            poolManager.settle();
        } else if (delta > 0) {
            poolManager.take(currency, address(this), uint256(uint128(delta)));
        }
    }

    function _pullReportedFees(Currency currency, uint256 amount) internal {
        if (amount == 0) return;
        address token = Currency.unwrap(currency);
        if (token == address(0)) revert NativeFeeReportUnsupported();
        if (!IERC20Transfer(token).transferFrom(msg.sender, address(this), amount)) revert TokenTransferFailed();
    }

    function _pay(address payable recipient, uint256 amount) internal {
        if (amount == 0) return;
        if (address(this).balance < amount) revert TransferFailed();
        (bool success,) = recipient.call{value: amount}("");
        if (!success) revert TransferFailed();
    }
}
