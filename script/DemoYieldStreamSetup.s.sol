// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDeltaLibrary, toBalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {DemoActor} from "../src/demo/DemoActor.sol";
import {DemoERC20} from "../src/demo/DemoERC20.sol";
import {DemoYieldStreamHookHarness} from "../src/demo/DemoYieldStreamHookHarness.sol";
import {FutureYieldToken} from "../src/tokens/FutureYieldToken.sol";
import {PrincipalToken} from "../src/tokens/PrincipalToken.sol";

contract DemoYieldStreamSetup is Script {
    string internal constant STATE_PATH = "./broadcast/yieldstream-demo-addresses.json";
    bytes4 internal constant MANAGED_LIQUIDITY_MAGIC = bytes4(keccak256("YieldStreamManagedLiquidity"));

    function run() external {
        address broadcaster = msg.sender;

        vm.startBroadcast();

        DemoERC20 token0 = new DemoERC20("Demo WETH", "dWETH");
        DemoERC20 token1 = new DemoERC20("Demo USDC", "dUSDC");
        DemoYieldStreamHookHarness hook = new DemoYieldStreamHookHarness(
            IPoolManager(address(0xCAFE)), address(0), address(0xCABB1E), broadcaster, 0
        );
        DemoActor alice = new DemoActor("Alice LP");
        DemoActor bob = new DemoActor("Bob FYT Buyer");

        PoolKey memory key =
            PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(address(hook)));

        token0.mint(address(hook), 1_000_000 ether);
        token1.mint(address(hook), 1_000_000 ether);

        uint256 epochId = hook.currentEpoch();
        hook.exposedAfterAddLiquidity(
            address(hook),
            key,
            ModifyLiquidityParams(-60, 60, int256(1 ether), bytes32(0)),
            toBalanceDelta(-10 ether, -20 ether),
            BalanceDeltaLibrary.ZERO_DELTA,
            abi.encode(MANAGED_LIQUIDITY_MAGIC, address(alice), epochId)
        );

        FutureYieldToken fyt = FutureYieldToken(hook.fytContracts(epochId));
        PrincipalToken pt = PrincipalToken(hook.ptContracts(epochId));

        alice.transferAllFYT(address(fyt), address(bob));

        token0.mint(broadcaster, 5 ether);
        token1.mint(broadcaster, 7 ether);
        token0.approve(address(hook), 5 ether);
        token1.approve(address(hook), 7 ether);
        hook.reportFees(key, epochId, 5 ether, 7 ether);
        hook.exposedAfterSwap(address(0xD00D), key, SwapParams(true, -1 ether, 0), BalanceDeltaLibrary.ZERO_DELTA, "");

        vm.stopBroadcast();

        console2.log("YieldStream broadcast demo setup complete");
        console2.log("Epoch", epochId);
        console2.log("Hook", address(hook));
        console2.log("FYT", address(fyt));
        console2.log("PT", address(pt));
        console2.log("Alice actor", address(alice));
        console2.log("Bob actor", address(bob));
        console2.log("Bob FYT balance", fyt.balanceOf(address(bob)));
        console2.log("Alice PT balance", pt.balanceOf(address(alice)));
        (uint256 fees0, uint256 fees1) = hook.getEpochFees(epochId);
        console2.log("Accrued fees token0", fees0);
        console2.log("Accrued fees token1", fees1);

        string memory root = "demo";
        vm.serializeAddress(root, "token0", address(token0));
        vm.serializeAddress(root, "token1", address(token1));
        vm.serializeAddress(root, "hook", address(hook));
        vm.serializeAddress(root, "fyt", address(fyt));
        vm.serializeAddress(root, "pt", address(pt));
        vm.serializeAddress(root, "alice", address(alice));
        vm.serializeAddress(root, "bob", address(bob));
        string memory json = vm.serializeUint(root, "epochId", epochId);
        vm.writeJson(json, STATE_PATH);
    }
}
