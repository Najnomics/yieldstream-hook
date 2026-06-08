// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {DemoActor} from "../src/demo/DemoActor.sol";
import {DemoERC20} from "../src/demo/DemoERC20.sol";
import {DemoYieldStreamHookHarness} from "../src/demo/DemoYieldStreamHookHarness.sol";

contract DemoYieldStreamSettleRedeem is Script {
    string internal constant STATE_PATH = "./broadcast/yieldstream-demo-addresses.json";

    function run() external {
        string memory json = vm.readFile(STATE_PATH);
        uint256 epochId = vm.parseJsonUint(json, ".epochId");
        DemoYieldStreamHookHarness hook = DemoYieldStreamHookHarness(payable(vm.parseJsonAddress(json, ".hook")));
        DemoERC20 token0 = DemoERC20(vm.parseJsonAddress(json, ".token0"));
        DemoERC20 token1 = DemoERC20(vm.parseJsonAddress(json, ".token1"));
        DemoActor alice = DemoActor(vm.parseJsonAddress(json, ".alice"));
        DemoActor bob = DemoActor(vm.parseJsonAddress(json, ".bob"));

        vm.startBroadcast();

        hook.demoSettleEpoch(epochId);
        bob.redeemAllFYT(hook, epochId);
        alice.redeemAllPT(hook, epochId);

        vm.stopBroadcast();

        console2.log("YieldStream broadcast demo settled and redeemed");
        console2.log("Epoch", epochId);
        console2.log("Hook", address(hook));
        console2.log("Bob token0 fees", token0.balanceOf(address(bob)));
        console2.log("Bob token1 fees", token1.balanceOf(address(bob)));
        console2.log("Alice token0 principal", token0.balanceOf(address(alice)));
        console2.log("Alice token1 principal", token1.balanceOf(address(alice)));
    }
}
