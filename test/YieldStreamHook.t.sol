// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IUnlockCallback} from "@uniswap/v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary, toBalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BaseHook} from "v4-hooks-public/src/base/BaseHook.sol";
import {FutureYieldToken} from "../src/tokens/FutureYieldToken.sol";
import {PrincipalToken} from "../src/tokens/PrincipalToken.sol";
import {YieldStreamTokenFactory} from "../src/tokens/YieldStreamTokenFactory.sol";
import {YieldStreamHook} from "../src/YieldStreamHook.sol";
import {YieldStreamRSC} from "../src/rsc/YieldStreamRSC.sol";
import {ReactivePingRSC} from "../src/rsc/ReactivePingRSC.sol";
import {MorphoAdapter} from "../src/adapters/MorphoAdapter.sol";
import {IReactive} from "reactive-lib/interfaces/IReactive.sol";
import {YieldStreamHookHarness} from "./utils/YieldStreamHookHarness.sol";
import {TestERC20} from "./utils/TestERC20.sol";

contract YieldStreamHookTest is Test {
    using BalanceDeltaLibrary for BalanceDelta;

    address internal constant REACTIVE_SYSTEM = 0x0000000000000000000000000000000000fffFfF;
    bytes4 internal constant MANAGED_LIQUIDITY_MAGIC = bytes4(keccak256("YieldStreamManagedLiquidity"));

    YieldStreamHookHarness hook;
    MorphoAdapter adapter;
    TestERC20 token0;
    TestERC20 token1;
    PoolKey key;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address rsc = address(0x1234);
    address callbackProxy = address(0xCABB1E);

    function setUp() public {
        vm.roll(10);
        vm.etch(REACTIVE_SYSTEM, address(new MockLegacySystem()).code);
        token0 = new TestERC20("Token 0", "TK0");
        token1 = new TestERC20("Token 1", "TK1");
        adapter = new MorphoAdapter(address(0xBEEF));
        hook = new YieldStreamHookHarness(IPoolManager(address(0xCAFE)), address(adapter), callbackProxy, rsc, 0);
        adapter.setHook(address(hook));
        key = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });
        token0.mint(address(hook), 1_000_000 ether);
        token1.mint(address(hook), 1_000_000 ether);
    }

    function test_hookPermissions() public view {
        Hooks.Permissions memory p = hook.getHookPermissions();
        assertTrue(p.afterAddLiquidity);
        assertTrue(p.beforeRemoveLiquidity);
        assertTrue(p.afterSwap);
        assertFalse(p.beforeSwapReturnDelta);
        assertFalse(p.afterSwapReturnDelta);
    }

    function test_currentEpoch_returnsCorrectId() public {
        vm.roll(50_399);
        assertEq(hook.currentEpoch(), 0);
        vm.roll(50_400);
        assertEq(hook.currentEpoch(), 1);
    }

    function test_adminSettersAndOwnershipGuards() public {
        vm.prank(bob);
        vm.expectRevert(YieldStreamHook.OnlyOwner.selector);
        hook.setReactiveSender(address(0xA));

        vm.expectRevert(YieldStreamHook.InvalidAddress.selector);
        hook.setReactiveSender(address(0));
        vm.expectRevert(YieldStreamHook.InvalidAddress.selector);
        hook.setCallbackProxy(address(0));
        vm.expectRevert(YieldStreamHook.InvalidAddress.selector);
        hook.setDirectSettlementCaller(address(0));
        vm.expectRevert(YieldStreamHook.InvalidAddress.selector);
        hook.setFeeReporter(address(0));
        vm.expectRevert(YieldStreamHook.InvalidAddress.selector);
        hook.transferOwnership(address(0));

        hook.setReactiveSender(address(0xA));
        hook.setCallbackProxy(address(0xB));
        hook.setDirectSettlementCaller(address(0xC));
        hook.setFeeReporter(address(0xD));
        assertEq(hook.reactiveSender(), address(0xA));
        assertEq(hook.callbackProxy(), address(0xB));
        assertEq(hook.directSettlementCaller(), address(0xC));
        assertEq(hook.feeReporter(), address(0xD));

        hook.transferOwnership(bob);
        assertEq(hook.owner(), bob);
        vm.expectRevert(YieldStreamHook.OnlyOwner.selector);
        hook.setFeeReporter(address(this));
        vm.prank(bob);
        hook.setFeeReporter(address(this));
        assertEq(hook.feeReporter(), address(this));
    }

    function test_customEpochLength_shortDemoEpoch() public {
        YieldStreamHookHarness shortHook =
            new YieldStreamHookHarness(IPoolManager(address(0xCAFE)), address(adapter), callbackProxy, rsc, 20);
        assertEq(shortHook.epochLength(), 20);
        vm.roll(19);
        assertEq(shortHook.currentEpoch(), 0);
        vm.roll(20);
        assertEq(shortHook.currentEpoch(), 1);
    }

    function test_constructorRejectsZeroOwner() public {
        vm.expectRevert(YieldStreamHook.InvalidAddress.selector);
        new CustomOwnerYieldStreamHookHarness(
            IPoolManager(address(0xCAFE)), address(adapter), callbackProxy, rsc, address(0), 20
        );
    }

    function test_afterAddLiquidity_mintsFYTAndPT_andStartsEpoch() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        uint256 epochId = hook.currentEpoch();
        address fyt = hook.fytContracts(epochId);
        address pt = hook.ptContracts(epochId);
        assertTrue(fyt != address(0));
        assertTrue(pt != address(0));
        assertEq(FutureYieldToken(fyt).balanceOf(alice), 1 ether * (50_400 - block.number));
        assertEq(PrincipalToken(pt).balanceOf(alice), 1 ether);
    }

    function test_epochViewsReturnExpectedValues() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        assertEq(hook.getFYTContract(0), hook.fytContracts(0));
        assertEq(hook.getPTContract(0), hook.ptContracts(0));
        (uint256 totalLiquidity, uint256 totalFees0, uint256 totalFees1, uint256 totalCapital0, uint256 totalCapital1)
        = hook.getEpochTotals(0);
        assertEq(totalLiquidity, 1 ether);
        assertEq(totalFees0, 0);
        assertEq(totalFees1, 0);
        assertEq(totalCapital0, 10 ether);
        assertEq(totalCapital1, 20 ether);
    }

    function test_depositManagedLiquidityOwnsPositionAndSettlementWithdraws() public {
        MockPoolManager poolManager = new MockPoolManager();
        MorphoAdapter managedAdapter = new MorphoAdapter(address(0xBEEF));
        YieldStreamHookHarness managedHook =
            new YieldStreamHookHarness(IPoolManager(address(poolManager)), address(managedAdapter), callbackProxy, rsc, 20);
        managedAdapter.setHook(address(managedHook));
        PoolKey memory managedKey = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(managedHook))
        });

        poolManager.setDeltas(toBalanceDelta(-10 ether, -20 ether), toBalanceDelta(10 ether, 20 ether));
        token0.mint(alice, 15 ether);
        token1.mint(alice, 25 ether);

        vm.startPrank(alice);
        token0.approve(address(managedHook), 15 ether);
        token1.approve(address(managedHook), 25 ether);
        (uint256 epochId, uint256 amount0, uint256 amount1) = managedHook.depositManagedLiquidity(
            YieldStreamHook.ManagedLiquidityParams({
                key: managedKey,
                tickLower: -60,
                tickUpper: 60,
                liquidity: uint128(1 ether),
                salt: bytes32("demo"),
                maxAmount0: 15 ether,
                maxAmount1: 25 ether
            })
        );
        vm.stopPrank();

        assertEq(epochId, 0);
        assertEq(amount0, 10 ether);
        assertEq(amount1, 20 ether);
        assertEq(token0.balanceOf(alice), 5 ether);
        assertEq(token1.balanceOf(alice), 5 ether);
        assertEq(token0.balanceOf(address(poolManager)), 10 ether);
        assertEq(token1.balanceOf(address(poolManager)), 20 ether);

        PrincipalToken pt = PrincipalToken(managedHook.ptContracts(0));
        assertEq(pt.balanceOf(alice), 1 ether);

        vm.roll(21);
        managedHook.triggerSettlement(0);
        assertTrue(managedHook.isEpochSettled(0));
        assertEq(token0.balanceOf(address(managedHook)), 10 ether);
        assertEq(token1.balanceOf(address(managedHook)), 20 ether);

        uint256 before0 = token0.balanceOf(alice);
        uint256 before1 = token1.balanceOf(alice);
        uint256 alicePt = pt.balanceOf(alice);
        vm.prank(alice);
        managedHook.redeemPT(0, alicePt);
        assertEq(token0.balanceOf(alice) - before0, 10 ether);
        assertEq(token1.balanceOf(alice) - before1, 20 ether);
    }

    function test_depositManagedLiquidityRejectsZeroLiquidityAndSlippage() public {
        MockPoolManager poolManager = new MockPoolManager();
        MorphoAdapter managedAdapter = new MorphoAdapter(address(0xBEEF));
        YieldStreamHookHarness managedHook =
            new YieldStreamHookHarness(IPoolManager(address(poolManager)), address(managedAdapter), callbackProxy, rsc, 20);
        managedAdapter.setHook(address(managedHook));
        PoolKey memory managedKey = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(managedHook))
        });

        vm.expectRevert(YieldStreamHook.NoPosition.selector);
        managedHook.depositManagedLiquidity(
            YieldStreamHook.ManagedLiquidityParams({
                key: managedKey,
                tickLower: -60,
                tickUpper: 60,
                liquidity: 0,
                salt: bytes32(0),
                maxAmount0: 0,
                maxAmount1: 0
            })
        );

        poolManager.setDeltas(toBalanceDelta(-10 ether, -20 ether), toBalanceDelta(10 ether, 20 ether));
        token0.mint(address(managedHook), 1 ether);
        token0.mint(alice, 9 ether);
        token1.mint(alice, 20 ether);
        vm.startPrank(alice);
        token0.approve(address(managedHook), 9 ether);
        token1.approve(address(managedHook), 20 ether);
        vm.expectRevert(YieldStreamHook.SlippageExceeded.selector);
        managedHook.depositManagedLiquidity(
            YieldStreamHook.ManagedLiquidityParams({
                key: managedKey,
                tickLower: -60,
                tickUpper: 60,
                liquidity: uint128(1 ether),
                salt: bytes32(0),
                maxAmount0: 9 ether,
                maxAmount1: 20 ether
            })
        );
        vm.stopPrank();
    }

    function test_unlockCallbackGuardsCallerAndAction() public {
        MockPoolManager poolManager = new MockPoolManager();
        YieldStreamHookHarness managedHook =
            new YieldStreamHookHarness(IPoolManager(address(poolManager)), address(adapter), callbackProxy, rsc, 20);
        PoolKey memory managedKey = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(managedHook))
        });
        YieldStreamHook.UnlockData memory data = YieldStreamHook.UnlockData({
            action: 9,
            beneficiary: alice,
            epochId: 0,
            key: managedKey,
            params: _params(1 ether, -60, 60)
        });

        vm.expectRevert(YieldStreamHook.OnlyPoolManagerUnlock.selector);
        managedHook.unlockCallback(abi.encode(data));

        vm.prank(address(poolManager));
        vm.expectRevert(YieldStreamHook.NoPosition.selector);
        managedHook.unlockCallback(abi.encode(data));
    }

    function test_unlockCallbackRejectsNativeCurrencySettlement() public {
        MockPoolManager poolManager = new MockPoolManager();
        YieldStreamHookHarness managedHook =
            new YieldStreamHookHarness(IPoolManager(address(poolManager)), address(adapter), callbackProxy, rsc, 20);
        PoolKey memory nativeKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(managedHook))
        });
        poolManager.setDeltas(toBalanceDelta(-1 ether, 0), toBalanceDelta(0, 0));
        YieldStreamHook.UnlockData memory data = YieldStreamHook.UnlockData({
            action: 1,
            beneficiary: alice,
            epochId: 0,
            key: nativeKey,
            params: _params(1 ether, -60, 60)
        });

        vm.prank(address(poolManager));
        vm.expectRevert(YieldStreamHook.NativeFeeReportUnsupported.selector);
        managedHook.unlockCallback(abi.encode(data));
    }

    function test_epochContracts_reuseExistingForSameEpoch() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        address fyt = hook.fytContracts(0);
        address pt = hook.ptContracts(0);
        _deposit(bob, 2 ether, -120, 120, 11 ether, 21 ether);
        assertEq(hook.fytContracts(0), fyt);
        assertEq(hook.ptContracts(0), pt);
    }

    function test_lateEpochDeposit_receivesLessFYTPerLiquidity() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        uint256 aliceFyt = FutureYieldToken(hook.fytContracts(0)).balanceOf(alice);
        vm.roll(40_000);
        _deposit(bob, 1 ether, -120, 120, 10 ether, 20 ether);
        uint256 bobFyt = FutureYieldToken(hook.fytContracts(0)).balanceOf(bob);
        assertGt(aliceFyt, bobFyt);
    }

    function test_afterSwap_accruesFeesAndEmits() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        vm.recordLogs();
        _swapFees(3 ether, 4 ether);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool found;
        bytes32 feesSig = keccak256("FeesAccrued(uint256,uint256,uint256)");
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics[0] == feesSig && logs[i].topics[1] == bytes32(uint256(0))) {
                found = true;
            }
        }
        assertTrue(found);
        (uint256 fees0, uint256 fees1) = hook.getEpochFees(0);
        assertEq(fees0, 3 ether);
        assertEq(fees1, 4 ether);
    }

    function test_afterSwap_ignoresCallerForgedHookDataFees() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        hook.exposedAfterSwap(
            address(this),
            key,
            SwapParams({zeroForOne: true, amountSpecified: -1 ether, sqrtPriceLimitX96: 0}),
            BalanceDeltaLibrary.ZERO_DELTA,
            abi.encode(uint256(99 ether), uint256(101 ether))
        );
        (uint256 fees0, uint256 fees1) = hook.getEpochFees(0);
        assertEq(fees0, 0);
        assertEq(fees1, 0);
    }

    function test_reportFees_requiresFeeReporterAndTransfersBacking() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        token0.mint(bob, 3 ether);
        token1.mint(bob, 4 ether);

        vm.startPrank(bob);
        token0.approve(address(hook), 3 ether);
        token1.approve(address(hook), 4 ether);
        vm.expectRevert(YieldStreamHook.OnlyFeeReporter.selector);
        hook.reportFees(key, 0, 3 ether, 4 ether);
        vm.stopPrank();

        token0.mint(address(this), 3 ether);
        token1.mint(address(this), 4 ether);
        token0.approve(address(hook), 3 ether);
        token1.approve(address(hook), 4 ether);
        uint256 hookBefore0 = token0.balanceOf(address(hook));
        uint256 hookBefore1 = token1.balanceOf(address(hook));
        hook.reportFees(key, 0, 3 ether, 4 ether);
        assertEq(token0.balanceOf(address(hook)) - hookBefore0, 3 ether);
        assertEq(token1.balanceOf(address(hook)) - hookBefore1, 4 ether);
    }

    function test_reportFees_revertsForUnstartedZeroAndSettledEpochs() public {
        vm.expectRevert(YieldStreamHook.EpochNotStarted.selector);
        hook.reportFees(key, 0, 1 ether, 0);

        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);

        vm.expectRevert(YieldStreamHook.NothingToRedeem.selector);
        hook.reportFees(key, 0, 0, 0);

        vm.roll(50_401);
        hook.triggerSettlement(0);
        vm.expectRevert(YieldStreamHook.EpochSettledAlready.selector);
        hook.reportFees(key, 0, 1 ether, 0);
    }

    function test_settleEpoch_onlyRSC() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        vm.roll(50_401);
        vm.expectRevert(YieldStreamHook.OnlyRSC.selector);
        hook.settleEpoch(0);
        vm.prank(rsc);
        hook.settleEpoch(0);
        assertTrue(_epochSettled(0));
    }

    function test_settleEpochFromReactive_requiresProxyAndReactiveSender() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        vm.roll(50_401);

        vm.expectRevert(YieldStreamHook.OnlyRSC.selector);
        vm.prank(callbackProxy);
        hook.settleEpochFromReactive(rsc, 0);

        hook.setReactiveSender(rsc);

        vm.expectRevert(YieldStreamHook.OnlyRSC.selector);
        vm.prank(address(0xBAD));
        hook.settleEpochFromReactive(rsc, 0);

        vm.expectRevert(YieldStreamHook.OnlyRSC.selector);
        vm.prank(callbackProxy);
        hook.settleEpochFromReactive(address(0xBAD), 0);

        vm.prank(callbackProxy);
        hook.settleEpochFromReactive(rsc, 0);
        assertTrue(_epochSettled(0));
    }

    function test_triggerSettlement_permissionlessAfterEpochEnd() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        vm.expectRevert(YieldStreamHook.EpochActive.selector);
        hook.triggerSettlement(0);
        vm.roll(50_401);
        hook.triggerSettlement(0);
        assertTrue(_epochSettled(0));
    }

    function test_callbackProxyPaymentSurface() public {
        MockReactivePayable proxy = new MockReactivePayable();
        YieldStreamHookHarness paymentHook =
            new YieldStreamHookHarness(IPoolManager(address(0xCAFE)), address(adapter), address(proxy), rsc, 0);

        vm.deal(address(paymentHook), 2 ether);
        proxy.setDebt(address(paymentHook), 0.25 ether);

        assertEq(paymentHook.callbackDebt(), 0.25 ether);

        vm.prank(address(0xBAD));
        vm.expectRevert(YieldStreamHook.OnlyRSC.selector);
        paymentHook.pay(0.1 ether);

        vm.prank(address(proxy));
        paymentHook.pay(0.1 ether);
        assertEq(address(proxy).balance, 0.1 ether);

        paymentHook.coverCallbackDebt();
        assertEq(address(proxy).balance, 0.35 ether);
    }

    function test_settleEpoch_revertsIfAlreadySettled() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        vm.roll(50_401);
        hook.triggerSettlement(0);
        vm.expectRevert(YieldStreamHook.EpochSettledAlready.selector);
        hook.triggerSettlement(0);
    }

    function test_redeemFYT_transferredHolderReceivesFees() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        _swapFees(3 ether, 4 ether);
        FutureYieldToken fyt = FutureYieldToken(hook.fytContracts(0));
        uint256 aliceFyt = fyt.balanceOf(alice);
        vm.prank(alice);
        fyt.transfer(bob, aliceFyt);
        vm.roll(50_401);
        hook.triggerSettlement(0);
        uint256 before0 = token0.balanceOf(bob);
        uint256 before1 = token1.balanceOf(bob);
        uint256 bobFyt = fyt.balanceOf(bob);
        vm.prank(bob);
        hook.redeemFYT(0, bobFyt);
        assertApproxEqAbs(token0.balanceOf(bob) - before0, 3 ether, 100_000);
        assertApproxEqAbs(token1.balanceOf(bob) - before1, 4 ether, 100_000);
        assertEq(fyt.balanceOf(bob), 0);
    }

    function test_redeemPT_returnsCapitalAndBurns() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        PrincipalToken pt = PrincipalToken(hook.ptContracts(0));
        vm.roll(50_401);
        hook.triggerSettlement(0);
        uint256 before0 = token0.balanceOf(alice);
        uint256 before1 = token1.balanceOf(alice);
        uint256 alicePt = pt.balanceOf(alice);
        vm.prank(alice);
        hook.redeemPT(0, alicePt);
        assertEq(token0.balanceOf(alice) - before0, 10 ether);
        assertEq(token1.balanceOf(alice) - before1, 20 ether);
        assertEq(pt.balanceOf(alice), 0);
    }

    function test_redeemGuardsZeroAndActiveEpoch() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        vm.expectRevert(YieldStreamHook.EpochActive.selector);
        hook.redeemFYT(0, 1);
        vm.expectRevert(YieldStreamHook.EpochActive.selector);
        hook.redeemPT(0, 1);

        vm.roll(50_401);
        hook.triggerSettlement(0);
        vm.expectRevert(YieldStreamHook.NothingToRedeem.selector);
        hook.redeemFYT(0, 0);
        vm.expectRevert(YieldStreamHook.NothingToRedeem.selector);
        hook.redeemPT(0, 0);
    }

    function test_tokenRedeemEntryPointsWork() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        _swapFees(1 ether, 2 ether);
        FutureYieldToken fyt = FutureYieldToken(hook.fytContracts(0));
        PrincipalToken pt = PrincipalToken(hook.ptContracts(0));
        vm.roll(50_401);
        hook.triggerSettlement(0);
        vm.prank(alice);
        fyt.redeem(alice);
        vm.prank(alice);
        pt.redeem(alice);
        assertEq(fyt.balanceOf(alice), 0);
        assertEq(pt.balanceOf(alice), 0);
    }

    function test_epochTokenOnlyHookAndAlreadySettledGuards() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        FutureYieldToken fyt = FutureYieldToken(hook.fytContracts(0));
        PrincipalToken pt = PrincipalToken(hook.ptContracts(0));

        vm.expectRevert(FutureYieldToken.OnlyHook.selector);
        fyt.mint(alice, 1);
        vm.expectRevert(FutureYieldToken.OnlyHook.selector);
        fyt.burn(alice, 1);
        vm.expectRevert(FutureYieldToken.OnlyHook.selector);
        fyt.settle(1, 1);

        vm.expectRevert(PrincipalToken.OnlyHook.selector);
        pt.mint(alice, 1);
        vm.expectRevert(PrincipalToken.OnlyHook.selector);
        pt.burn(alice, 1);
        vm.expectRevert(PrincipalToken.OnlyHook.selector);
        pt.enableRedemption(1, 1);

        vm.roll(50_401);
        hook.triggerSettlement(0);

        vm.prank(address(hook));
        vm.expectRevert(FutureYieldToken.AlreadySettled.selector);
        fyt.settle(1, 1);
        vm.prank(address(hook));
        vm.expectRevert(PrincipalToken.AlreadyRedeemable.selector);
        pt.enableRedemption(1, 1);
    }

    function test_beforeRemoveLiquidity_enforcesLockup() public {
        ModifyLiquidityParams memory params = _params(1 ether, -60, 60);
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        vm.expectRevert(YieldStreamHook.EpochActive.selector);
        hook.exposedBeforeRemoveLiquidity(address(hook), key, params, _managedHookData(alice, 0));
        vm.roll(50_401);
        hook.triggerSettlement(0);
        bytes4 selector = hook.exposedBeforeRemoveLiquidity(address(hook), key, params, _managedHookData(alice, 0));
        assertEq(selector, hook.beforeRemoveLiquidity.selector);
    }

    function test_beforeRemoveLiquidity_ignoresCallerSuppliedSettledEpochBypass() public {
        ModifyLiquidityParams memory params = _params(1 ether, -60, 60);
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        vm.roll(50_401);
        hook.triggerSettlement(0);

        vm.roll(50_410);
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);

        vm.expectRevert(YieldStreamHook.NoPosition.selector);
        hook.exposedBeforeRemoveLiquidity(address(hook), key, params, _managedHookData(alice, 0));
    }

    function test_secondPoolRevertsInsteadOfSharingEpochTokens() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        TestERC20 other0 = new TestERC20("Other 0", "O0");
        TestERC20 other1 = new TestERC20("Other 1", "O1");
        PoolKey memory otherKey = PoolKey({
            currency0: Currency.wrap(address(other0)),
            currency1: Currency.wrap(address(other1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });
        uint256 epochId = hook.currentEpoch();

        vm.expectRevert(YieldStreamHook.UnsupportedPool.selector);
        hook.exposedAfterAddLiquidity(
            address(hook),
            otherKey,
            _params(1 ether, -60, 60),
            toBalanceDelta(-10 ether, -20 ether),
            BalanceDeltaLibrary.ZERO_DELTA,
            _managedHookData(bob, epochId)
        );
    }

    function test_afterAddLiquidityRejectsUnmanagedWrongEpochAndZeroLiquidity() public {
        vm.expectRevert(YieldStreamHook.OnlyHookManagedLiquidity.selector);
        hook.exposedAfterAddLiquidity(
            alice,
            key,
            _params(1 ether, -60, 60),
            toBalanceDelta(-10 ether, -20 ether),
            BalanceDeltaLibrary.ZERO_DELTA,
            ""
        );

        uint256 wrongEpoch = hook.currentEpoch() + 1;
        vm.expectRevert(YieldStreamHook.EpochActive.selector);
        hook.exposedAfterAddLiquidity(
            address(hook),
            key,
            _params(1 ether, -60, 60),
            toBalanceDelta(-10 ether, -20 ether),
            BalanceDeltaLibrary.ZERO_DELTA,
            _managedHookData(alice, wrongEpoch)
        );

        uint256 epochId = hook.currentEpoch();
        vm.expectRevert(YieldStreamHook.NoPosition.selector);
        hook.exposedAfterAddLiquidity(
            address(hook),
            key,
            _params(0, -60, 60),
            BalanceDeltaLibrary.ZERO_DELTA,
            BalanceDeltaLibrary.ZERO_DELTA,
            _managedHookData(alice, epochId)
        );
    }

    function test_redeemForRejectsSpoofedEpochTokenCallers() public {
        _deposit(alice, 1 ether, -60, 60, 10 ether, 20 ether);
        FakeEpochToken fake = new FakeEpochToken(0);

        vm.expectRevert(YieldStreamHook.OnlyEpochToken.selector);
        fake.callRedeemFYTFor(hook, alice, bob, 1);

        vm.expectRevert(YieldStreamHook.OnlyEpochToken.selector);
        fake.callRedeemPTFor(hook, alice, bob, 1);
    }

    function test_rscQueuesSettlementCallbackAtEpochBoundary() public {
        YieldStreamRSC reactive = new YieldStreamRSC(1, address(hook), 300_000, 0);
        assertTrue(reactive.subscriptionConfigured());
        _pretendLegacyVm(address(reactive));
        IReactive.LogRecord memory first = _log(0, 1 ether, 10);
        vm.prank(REACTIVE_SYSTEM);
        reactive.react(first);

        vm.recordLogs();
        vm.prank(REACTIVE_SYSTEM);
        reactive.react(_log(0, 2 ether, 50_410));
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool found;
        bytes32 queuedSig = keccak256("SettlementCallbackQueued(uint256,address)");
        bytes32 callbackSig = keccak256("Callback(uint256,address,uint64,bytes)");
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics[0] == queuedSig && uint256(logs[i].topics[1]) == 0) found = true;
            if (logs[i].topics[0] == callbackSig) {
                bytes memory payload = abi.decode(logs[i].data, (bytes));
                bytes4 selector;
                address callbackSender;
                uint256 callbackEpoch;
                assembly {
                    selector := mload(add(payload, 32))
                    callbackSender := mload(add(payload, 36))
                    callbackEpoch := mload(add(payload, 68))
                }
                assertEq(selector, YieldStreamHook.settleEpochFromReactive.selector);
                assertEq(callbackSender, address(this));
                assertEq(callbackEpoch, 0);
            }
        }
        assertTrue(found);
    }

    function test_rscConfigureSubscriptionAdminAndVmBranches() public {
        YieldStreamRSC reactive = new YieldStreamRSC(1, address(hook), 300_000, 20);
        assertTrue(reactive.subscriptionConfigured());

        vm.prank(bob);
        vm.expectRevert(YieldStreamRSC.OnlySubscriptionAdmin.selector);
        reactive.configureSubscription();

        reactive.configureSubscription();

        _pretendLegacyVm(address(reactive));
        vm.recordLogs();
        reactive.configureSubscription();
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 unavailableSig = keccak256("SubscriptionUnavailable()");
        bool unavailable;
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics[0] == unavailableSig) unavailable = true;
        }
        assertTrue(unavailable);
    }

    function test_rscConfigureSubscriptionRevertsWhenLegacySystemFails() public {
        vm.etch(REACTIVE_SYSTEM, address(new MockFailingLegacySystem()).code);
        YieldStreamRSC reactive = new YieldStreamRSC(1, address(hook), 300_000, 20);
        assertFalse(reactive.subscriptionConfigured());

        vm.expectRevert(YieldStreamRSC.SubscriptionFailed.selector);
        reactive.configureSubscription();
    }

    function test_rscDoesNotQueueBeforeEpochBoundary() public {
        YieldStreamRSC reactive = new YieldStreamRSC(1, address(hook), 300_000, 20);
        assertTrue(reactive.subscriptionConfigured());
        _pretendLegacyVm(address(reactive));

        vm.recordLogs();
        vm.prank(REACTIVE_SYSTEM);
        reactive.react(_log(1, 1 ether, 39));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        bytes32 queuedSig = keccak256("SettlementCallbackQueued(uint256,address)");
        bool queued;
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics[0] == queuedSig) queued = true;
        }
        assertFalse(queued);
        assertFalse(reactive.settlementQueued(1));
    }

    function test_rscCustomEpochLengthQueuesAtShortBoundary() public {
        YieldStreamRSC reactive = new YieldStreamRSC(1, address(hook), 300_000, 20);
        assertTrue(reactive.subscriptionConfigured());
        _pretendLegacyVm(address(reactive));
        vm.prank(REACTIVE_SYSTEM);
        reactive.react(_log(0, 1 ether, 10));

        vm.recordLogs();
        vm.prank(REACTIVE_SYSTEM);
        reactive.react(_log(0, 2 ether, 21));
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool found;
        bytes32 queuedSig = keccak256("SettlementCallbackQueued(uint256,address)");
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics[0] == queuedSig && uint256(logs[i].topics[1]) == 0) found = true;
        }
        assertTrue(found);
    }

    function test_rscQueuesOnlyEventEpochAcrossIdleGap() public {
        YieldStreamRSC reactive = new YieldStreamRSC(1, address(hook), 300_000, 20);
        assertTrue(reactive.subscriptionConfigured());
        _pretendLegacyVm(address(reactive));
        vm.prank(REACTIVE_SYSTEM);
        reactive.react(_log(5, 1 ether, 101));

        vm.recordLogs();
        vm.prank(REACTIVE_SYSTEM);
        reactive.react(_log(7, 2 ether, 161));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        bytes32 queuedSig = keccak256("SettlementCallbackQueued(uint256,address)");
        bool queued7;
        bool queued5Or6;
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics[0] != queuedSig) continue;
            if (uint256(logs[i].topics[1]) == 7) queued7 = true;
            if (uint256(logs[i].topics[1]) == 5 || uint256(logs[i].topics[1]) == 6) queued5Or6 = true;
        }
        assertTrue(queued7);
        assertFalse(queued5Or6);
        assertEq(reactive.lastObservedEpoch(), 7);
    }

    function test_rscDoesNotQueueDuplicateSettlementForSameEpoch() public {
        YieldStreamRSC reactive = new YieldStreamRSC(1, address(hook), 300_000, 20);
        assertTrue(reactive.subscriptionConfigured());
        _pretendLegacyVm(address(reactive));
        vm.prank(REACTIVE_SYSTEM);
        reactive.react(_log(3, 1 ether, 81));
        assertTrue(reactive.settlementQueued(3));

        vm.recordLogs();
        vm.prank(REACTIVE_SYSTEM);
        reactive.react(_log(3, 2 ether, 82));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        bytes32 queuedSig = keccak256("SettlementCallbackQueued(uint256,address)");
        bool found;
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics[0] == queuedSig) found = true;
        }
        assertFalse(found);
        assertEq(reactive.epochFeeAccumulator0(3), 3 ether);
    }

    function test_reactivePingRscSubscribesAndQueuesCallback() public {
        address origin = address(0x0A61);
        address receiver = address(0x0BEEF);
        ReactivePingRSC ping = new ReactivePingRSC(1, origin, receiver, 300_000);
        assertTrue(ping.subscriptionConfigured());
        _pretendLegacyVm(address(ping));

        vm.recordLogs();
        vm.prank(REACTIVE_SYSTEM);
        ping.react(_pingLog(origin, 7, alice, 123));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        bool observed;
        bool queued;
        bool callback;
        bytes32 observedSig = keccak256("PingObserved(uint256,address,uint256)");
        bytes32 queuedSig = keccak256("PingCallbackQueued(uint256,address)");
        bytes32 callbackSig = keccak256("Callback(uint256,address,uint64,bytes)");
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics[0] == observedSig) observed = true;
            if (logs[i].topics[0] == queuedSig) queued = true;
            if (logs[i].topics[0] == callbackSig) callback = true;
        }
        assertTrue(observed);
        assertTrue(queued);
        assertTrue(callback);
        assertEq(ping.observedCount(), 1);
    }

    function _pretendLegacyVm(address reactive) internal {
        vm.store(reactive, bytes32(uint256(2)), bytes32(uint256(1)));
    }

    function _deposit(
        address owner,
        uint256 liquidity,
        int24 tickLower,
        int24 tickUpper,
        uint256 capital0,
        uint256 capital1
    ) internal {
        hook.exposedAfterAddLiquidity(
            address(hook),
            key,
            _params(liquidity, tickLower, tickUpper),
            toBalanceDelta(-int128(uint128(capital0)), -int128(uint128(capital1))),
            BalanceDeltaLibrary.ZERO_DELTA,
            _managedHookData(owner, hook.currentEpoch())
        );
    }

    function _swapFees(uint256 fee0, uint256 fee1) internal {
        token0.mint(address(this), fee0);
        token1.mint(address(this), fee1);
        token0.approve(address(hook), fee0);
        token1.approve(address(hook), fee1);
        hook.reportFees(key, hook.currentEpoch(), fee0, fee1);
        hook.exposedAfterSwap(
            address(this),
            key,
            SwapParams({zeroForOne: true, amountSpecified: -1 ether, sqrtPriceLimitX96: 0}),
            BalanceDeltaLibrary.ZERO_DELTA,
            abi.encode(fee0, fee1)
        );
    }

    function _params(uint256 liquidity, int24 tickLower, int24 tickUpper)
        internal
        pure
        returns (ModifyLiquidityParams memory)
    {
        return ModifyLiquidityParams({
            tickLower: tickLower, tickUpper: tickUpper, liquidityDelta: int256(liquidity), salt: bytes32(0)
        });
    }

    function _managedHookData(address beneficiary, uint256 epochId) internal pure returns (bytes memory) {
        return abi.encode(MANAGED_LIQUIDITY_MAGIC, beneficiary, epochId);
    }

    function _epochSettled(uint256 epochId) internal view returns (bool settled) {
        return hook.isEpochSettled(epochId);
    }

    function _log(uint256 epochId, uint256 fee0, uint256 blockNumber)
        internal
        view
        returns (IReactive.LogRecord memory)
    {
        return IReactive.LogRecord({
            chain_id: 1,
            _contract: address(hook),
            topic_0: uint256(keccak256("FeesAccrued(uint256,uint256,uint256)")),
            topic_1: epochId,
            topic_2: fee0,
            topic_3: 0,
            data: "",
            block_number: blockNumber,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
    }

    function _pingLog(address origin, uint256 nonce, address sender, uint256 blockNumber)
        internal
        pure
        returns (IReactive.LogRecord memory)
    {
        return IReactive.LogRecord({
            chain_id: 1,
            _contract: origin,
            topic_0: uint256(keccak256("Ping(uint256,address,uint256)")),
            topic_1: nonce,
            topic_2: uint256(uint160(sender)),
            topic_3: 0,
            data: "",
            block_number: blockNumber,
            op_code: 0,
            block_hash: 0,
            tx_hash: 0,
            log_index: 0
        });
    }
}

contract MockReactivePayable {
    mapping(address => uint256) public debt;

    receive() external payable {}

    function setDebt(address account, uint256 amount) external {
        debt[account] = amount;
    }
}

contract MockLegacySystem {
    event MockSubscription(
        uint256 chainId, address contractAddress, uint256 topic0, uint256 topic1, uint256 topic2, uint256 topic3
    );

    function subscribe(
        uint256 chainId,
        address contractAddress,
        uint256 topic0,
        uint256 topic1,
        uint256 topic2,
        uint256 topic3
    ) external {
        emit MockSubscription(chainId, contractAddress, topic0, topic1, topic2, topic3);
    }
}

contract MockFailingLegacySystem {
    function subscribe(uint256, address, uint256, uint256, uint256, uint256) external pure {
        revert("subscription failed");
    }
}

contract FakeEpochToken {
    uint256 public immutable epochId;

    constructor(uint256 _epochId) {
        epochId = _epochId;
    }

    function callRedeemFYTFor(YieldStreamHook hook, address holder, address recipient, uint256 amount) external {
        hook.redeemFYTFor(holder, recipient, amount);
    }

    function callRedeemPTFor(YieldStreamHook hook, address holder, address recipient, uint256 amount) external {
        hook.redeemPTFor(holder, recipient, amount);
    }
}

contract CustomOwnerYieldStreamHookHarness is YieldStreamHook {
    constructor(
        IPoolManager poolManager,
        address morphoAdapter,
        address callbackProxy,
        address directSettlementCaller,
        address owner,
        uint256 epochLength
    )
        YieldStreamHook(
            poolManager,
            address(new YieldStreamTokenFactory()),
            morphoAdapter,
            callbackProxy,
            directSettlementCaller,
            owner,
            epochLength
        )
    {}

    function validateHookAddress(BaseHook) internal pure override {}
}

interface IERC20Minimal {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract MockPoolManager {
    using BalanceDeltaLibrary for BalanceDelta;

    BalanceDelta public addDelta;
    BalanceDelta public removeDelta;

    function setDeltas(BalanceDelta _addDelta, BalanceDelta _removeDelta) external {
        addDelta = _addDelta;
        removeDelta = _removeDelta;
    }

    function unlock(bytes calldata data) external returns (bytes memory) {
        return IUnlockCallback(msg.sender).unlockCallback(data);
    }

    function modifyLiquidity(PoolKey memory, ModifyLiquidityParams memory params, bytes calldata)
        external
        view
        returns (BalanceDelta callerDelta, BalanceDelta feesAccrued)
    {
        callerDelta = params.liquidityDelta >= 0 ? addDelta : removeDelta;
        feesAccrued = BalanceDeltaLibrary.ZERO_DELTA;
    }

    function sync(Currency) external {}

    function settle() external payable returns (uint256 paid) {
        return msg.value;
    }

    function take(Currency currency, address to, uint256 amount) external {
        IERC20Minimal(Currency.unwrap(currency)).transfer(to, amount);
    }
}
