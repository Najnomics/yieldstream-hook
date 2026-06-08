// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {YieldStreamRSC} from "../src/rsc/YieldStreamRSC.sol";

contract DeployYieldStreamReactive is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("REACTIVE_PRIVATE_KEY");
        uint256 destinationChainId = vm.envUint("DESTINATION_CHAIN_ID");
        address hook = vm.envAddress("HOOK_ADDRESS");
        uint64 callbackGasLimit = uint64(vm.envOr("CALLBACK_GAS_LIMIT", uint256(300_000)));
        uint256 value = vm.envOr("REACTIVE_DEPLOY_VALUE", uint256(1 ether));
        uint256 epochLength = vm.envOr("EPOCH_LENGTH", uint256(0));
        bool retrySubscription = vm.envOr("RETRY_SUBSCRIPTION", false);

        vm.startBroadcast(deployerKey);
        YieldStreamRSC rsc = new YieldStreamRSC{value: value}(destinationChainId, hook, callbackGasLimit, epochLength);
        if (retrySubscription) rsc.configureSubscription();
        vm.stopBroadcast();

        console2.log("YieldStreamRSC", address(rsc));
        console2.log("Destination chain", destinationChainId);
        console2.log("Hook", hook);
        console2.log("Callback gas limit", callbackGasLimit);
        console2.log("Epoch length", rsc.EPOCH_LENGTH());
        console2.log("Initial funding", value);
        console2.log("Subscription configured", rsc.subscriptionConfigured());
        console2.log("Retried subscription", retrySubscription);
    }
}
