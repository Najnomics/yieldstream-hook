// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {ReactivePingRSC} from "../src/rsc/ReactivePingRSC.sol";

contract DeployReactivePingRSC is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("REACTIVE_PRIVATE_KEY");
        uint256 destinationChainId = vm.envUint("DESTINATION_CHAIN_ID");
        address origin = vm.envAddress("PING_ORIGIN_ADDRESS");
        address receiver = vm.envAddress("PING_RECEIVER_ADDRESS");
        uint64 callbackGasLimit = uint64(vm.envOr("CALLBACK_GAS_LIMIT", uint256(300_000)));
        uint256 value = vm.envOr("REACTIVE_DEPLOY_VALUE", uint256(1 ether));
        bool retrySubscription = vm.envOr("RETRY_SUBSCRIPTION", false);

        vm.startBroadcast(deployerKey);
        ReactivePingRSC rsc = new ReactivePingRSC{value: value}(destinationChainId, origin, receiver, callbackGasLimit);
        if (retrySubscription) rsc.configureSubscription();
        vm.stopBroadcast();

        console2.log("ReactivePingRSC", address(rsc));
        console2.log("Destination chain", destinationChainId);
        console2.log("Origin", origin);
        console2.log("Receiver", receiver);
        console2.log("Callback gas limit", callbackGasLimit);
        console2.log("Initial funding", value);
        console2.log("Subscription configured", rsc.subscriptionConfigured());
    }
}
