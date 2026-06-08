// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {ReactivePingOrigin} from "../src/rsc/ReactivePingOrigin.sol";
import {ReactivePingReceiver} from "../src/rsc/ReactivePingReceiver.sol";

contract DeployReactivePingDestination is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address callbackProxy = vm.envAddress("CALLBACK_PROXY");
        address expectedReactiveSender = vm.envOr("EXPECTED_REACTIVE_SENDER", address(0));
        uint256 receiverFunding = vm.envOr("PING_RECEIVER_FUNDING", uint256(0));

        vm.startBroadcast(deployerKey);
        ReactivePingOrigin origin = new ReactivePingOrigin();
        ReactivePingReceiver receiver = new ReactivePingReceiver{value: receiverFunding}(
            callbackProxy, expectedReactiveSender, vm.addr(deployerKey)
        );
        vm.stopBroadcast();

        console2.log("ReactivePingOrigin", address(origin));
        console2.log("ReactivePingReceiver", address(receiver));
        console2.log("Callback proxy", callbackProxy);
        console2.log("Expected reactive sender", expectedReactiveSender);
        console2.log("Receiver funding", receiverFunding);
    }
}
