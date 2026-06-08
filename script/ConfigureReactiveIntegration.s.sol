// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {YieldStreamHook} from "../src/YieldStreamHook.sol";

contract ConfigureReactiveIntegration is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address hook = vm.envAddress("HOOK_ADDRESS");
        address callbackProxy = vm.envAddress("CALLBACK_PROXY");
        address rvmId = vm.envAddress("RVM_ID");

        vm.startBroadcast(deployerKey);
        YieldStreamHook(payable(hook)).setCallbackProxy(callbackProxy);
        YieldStreamHook(payable(hook)).setReactiveSender(rvmId);
        vm.stopBroadcast();

        console2.log("Hook", hook);
        console2.log("Callback proxy", YieldStreamHook(payable(hook)).callbackProxy());
        console2.log("Reactive RVM ID", YieldStreamHook(payable(hook)).reactiveSender());
    }
}
