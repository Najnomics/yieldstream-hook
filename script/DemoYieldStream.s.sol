// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDeltaLibrary, toBalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {FutureYieldToken} from "../src/tokens/FutureYieldToken.sol";
import {PrincipalToken} from "../src/tokens/PrincipalToken.sol";
import {YieldStreamHookHarness} from "../test/utils/YieldStreamHookHarness.sol";
import {TestERC20} from "../test/utils/TestERC20.sol";

contract DemoYieldStream is Script {
    bytes4 internal constant MANAGED_LIQUIDITY_MAGIC = bytes4(keccak256("YieldStreamManagedLiquidity"));

    function run() external {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);
        address swapper = address(0xD00D);

        vm.roll(100);
        TestERC20 token0 = new TestERC20("Demo WETH", "dWETH");
        TestERC20 token1 = new TestERC20("Demo USDC", "dUSDC");
        YieldStreamHookHarness hook = new YieldStreamHookHarness(
            IPoolManager(address(0xCAFE)), address(0), address(0xCABB1E), address(0x1234), 0
        );
        PoolKey memory key =
            PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(address(hook)));

        token0.mint(address(hook), 1_000_000 ether);
        token1.mint(address(hook), 1_000_000 ether);

        console2.log("YieldStream demo starting");
        console2.log("Hook", address(hook));

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
        console2.log("FYT", address(fyt));
        console2.log("PT", address(pt));
        console2.log("Alice FYT minted", fyt.balanceOf(alice));
        console2.log("Alice PT minted", pt.balanceOf(alice));

        uint256 aliceFyt = fyt.balanceOf(alice);
        vm.prank(alice);
        fyt.transfer(bob, aliceFyt);
        console2.log("Alice sold/transferred FYT to Bob");

        token0.mint(address(this), 5 ether);
        token1.mint(address(this), 7 ether);
        token0.approve(address(hook), 5 ether);
        token1.approve(address(hook), 7 ether);
        hook.reportFees(key, 0, 5 ether, 7 ether);
        hook.exposedAfterSwap(swapper, key, SwapParams(true, -1 ether, 0), BalanceDeltaLibrary.ZERO_DELTA, "");
        console2.log("Accrued fees: 5 token0, 7 token1");

        vm.roll(50_401);
        hook.triggerSettlement(0);
        console2.log("Epoch 0 settled");

        uint256 bobFyt = fyt.balanceOf(bob);
        vm.prank(bob);
        hook.redeemFYT(0, bobFyt);
        console2.log("Bob redeemed FYT fees");
        console2.log("Bob token0", token0.balanceOf(bob));
        console2.log("Bob token1", token1.balanceOf(bob));

        uint256 alicePt = pt.balanceOf(alice);
        vm.prank(alice);
        hook.redeemPT(0, alicePt);
        console2.log("Alice redeemed PT principal");
        console2.log("Alice token0", token0.balanceOf(alice));
        console2.log("Alice token1", token1.balanceOf(alice));
    }
}
