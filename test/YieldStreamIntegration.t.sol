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

contract YieldStreamIntegrationTest is Test {
    bytes4 internal constant MANAGED_LIQUIDITY_MAGIC = bytes4(keccak256("YieldStreamManagedLiquidity"));

    YieldStreamHookHarness hook;
    TestERC20 token0;
    TestERC20 token1;
    PoolKey key;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        vm.roll(100);
        token0 = new TestERC20("Token 0", "TK0");
        token1 = new TestERC20("Token 1", "TK1");
        hook = new YieldStreamHookHarness(
            IPoolManager(address(0xCAFE)), address(0), address(0xCABB1E), address(0x1234), 0
        );
        key = PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(address(hook)));
        token0.mint(address(hook), 1_000_000 ether);
        token1.mint(address(hook), 1_000_000 ether);
    }

    function test_fullLifecycle_LPSellsFYT_BobRedeemsFees_AliceRedeemsPrincipal() public {
        hook.exposedAfterAddLiquidity(
            address(hook),
            key,
            ModifyLiquidityParams(-60, 60, int256(1 ether), bytes32(0)),
            toBalanceDelta(-10 ether, -20 ether),
            BalanceDeltaLibrary.ZERO_DELTA,
            abi.encode(MANAGED_LIQUIDITY_MAGIC, alice, uint256(0))
        );

        FutureYieldToken fyt = FutureYieldToken(hook.fytContracts(0));
        PrincipalToken pt = PrincipalToken(hook.ptContracts(0));
        uint256 fytBalance = fyt.balanceOf(alice);

        vm.prank(alice);
        fyt.transfer(bob, fytBalance);

        token0.mint(address(this), 5 ether);
        token1.mint(address(this), 7 ether);
        token0.approve(address(hook), 5 ether);
        token1.approve(address(hook), 7 ether);
        hook.reportFees(key, 0, 5 ether, 7 ether);
        hook.exposedAfterSwap(
            address(this), key, SwapParams(true, -1 ether, 0), BalanceDeltaLibrary.ZERO_DELTA, ""
        );

        vm.roll(50_401);
        hook.triggerSettlement(0);

        uint256 bob0 = token0.balanceOf(bob);
        uint256 bob1 = token1.balanceOf(bob);
        uint256 bobFyt = fyt.balanceOf(bob);
        vm.prank(bob);
        hook.redeemFYT(0, bobFyt);
        assertApproxEqAbs(token0.balanceOf(bob) - bob0, 5 ether, 100_000);
        assertApproxEqAbs(token1.balanceOf(bob) - bob1, 7 ether, 100_000);

        uint256 alice0 = token0.balanceOf(alice);
        uint256 alice1 = token1.balanceOf(alice);
        uint256 ptBalance = pt.balanceOf(alice);
        vm.prank(alice);
        hook.redeemPT(0, ptBalance);
        assertEq(token0.balanceOf(alice) - alice0, 10 ether);
        assertEq(token1.balanceOf(alice) - alice1, 20 ether);
    }
}
