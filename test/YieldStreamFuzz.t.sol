// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDeltaLibrary, toBalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {FutureYieldToken} from "../src/tokens/FutureYieldToken.sol";
import {PrincipalToken} from "../src/tokens/PrincipalToken.sol";
import {YieldStreamHookHarness} from "./utils/YieldStreamHookHarness.sol";
import {TestERC20} from "./utils/TestERC20.sol";

contract YieldStreamFuzzTest is Test {
    bytes4 internal constant MANAGED_LIQUIDITY_MAGIC = bytes4(keccak256("YieldStreamManagedLiquidity"));

    YieldStreamHookHarness hook;
    TestERC20 token0;
    TestERC20 token1;
    PoolKey key;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        vm.roll(10);
        token0 = new TestERC20("Token 0", "TK0");
        token1 = new TestERC20("Token 1", "TK1");
        hook = new YieldStreamHookHarness(
            IPoolManager(address(0xCAFE)), address(0), address(0xCABB1E), address(0x1234), 0
        );
        key = PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(address(hook)));
        token0.mint(address(hook), type(uint128).max);
        token1.mint(address(hook), type(uint128).max);
    }

    function testFuzz_feeDistributionInvariant(uint96 liquidityRaw, uint96 fee0Raw, uint96 fee1Raw) public {
        uint256 liquidity = bound(uint256(liquidityRaw), 1e12, 1e18);
        uint256 fee0 = bound(uint256(fee0Raw), 1, 1e24);
        uint256 fee1 = bound(uint256(fee1Raw), 1, 1e24);

        _deposit(alice, liquidity, 10 ether, 20 ether);
        token0.mint(address(this), fee0);
        token1.mint(address(this), fee1);
        token0.approve(address(hook), fee0);
        token1.approve(address(hook), fee1);
        hook.reportFees(key, 0, fee0, fee1);
        hook.exposedAfterSwap(
            address(this), key, SwapParams(true, -1 ether, 0), BalanceDeltaLibrary.ZERO_DELTA, ""
        );
        FutureYieldToken fyt = FutureYieldToken(hook.fytContracts(0));
        vm.roll(50_401);
        hook.triggerSettlement(0);
        uint256 before0 = token0.balanceOf(alice);
        uint256 before1 = token1.balanceOf(alice);
        uint256 balance = fyt.balanceOf(alice);
        vm.prank(alice);
        hook.redeemFYT(0, balance);
        assertLe(fee0 - (token0.balanceOf(alice) - before0), 100_000);
        assertLe(fee1 - (token1.balanceOf(alice) - before1), 100_000);
    }

    function testFuzz_earlyDepositorGetsAtLeastLateDepositorPerLiquidity(uint32 lateBlockRaw) public {
        uint256 lateBlock = bound(uint256(lateBlockRaw), 11, 50_399);
        _deposit(alice, 1 ether, 10 ether, 20 ether);
        uint256 aliceFyt = FutureYieldToken(hook.fytContracts(0)).balanceOf(alice);
        vm.roll(lateBlock);
        _deposit(bob, 1 ether, 10 ether, 20 ether);
        uint256 bobFyt = FutureYieldToken(hook.fytContracts(0)).balanceOf(bob);
        assertGe(aliceFyt, bobFyt);
    }

    function testFuzz_ptRedemptionInvariant(uint96 liquidityRaw, uint96 capital0Raw, uint96 capital1Raw) public {
        uint256 liquidity = bound(uint256(liquidityRaw), 1e12, 1e18);
        uint256 capital0 = bound(uint256(capital0Raw), 1, 1e24);
        uint256 capital1 = bound(uint256(capital1Raw), 1, 1e24);
        _deposit(alice, liquidity, capital0, capital1);
        PrincipalToken pt = PrincipalToken(hook.ptContracts(0));
        vm.roll(50_401);
        hook.triggerSettlement(0);
        uint256 before0 = token0.balanceOf(alice);
        uint256 before1 = token1.balanceOf(alice);
        uint256 ptBalance = pt.balanceOf(alice);
        vm.prank(alice);
        hook.redeemPT(0, ptBalance);
        assertApproxEqAbs(token0.balanceOf(alice) - before0, capital0, 100_000);
        assertApproxEqAbs(token1.balanceOf(alice) - before1, capital1, 100_000);
    }

    function _deposit(address owner, uint256 liquidity, uint256 capital0, uint256 capital1) internal {
        hook.exposedAfterAddLiquidity(
            address(hook),
            key,
            ModifyLiquidityParams(-60, 60, int256(liquidity), bytes32(0)),
            toBalanceDelta(-int128(uint128(capital0)), -int128(uint128(capital1))),
            BalanceDeltaLibrary.ZERO_DELTA,
            abi.encode(MANAGED_LIQUIDITY_MAGIC, owner, hook.currentEpoch())
        );
    }
}
