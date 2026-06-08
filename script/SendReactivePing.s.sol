// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {ReactivePingOrigin} from "../src/rsc/ReactivePingOrigin.sol";

contract SendReactivePing is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        ReactivePingOrigin origin = ReactivePingOrigin(vm.envAddress("PING_ORIGIN_ADDRESS"));

        vm.startBroadcast(deployerKey);
        uint256 nonce = origin.ping();
        vm.stopBroadcast();

        console2.log("ReactivePingOrigin", address(origin));
        console2.log("Ping nonce", nonce);
    }
}
