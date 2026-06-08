// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-hooks-public/src/utils/HookMiner.sol";
import {YieldStreamHook} from "../src/YieldStreamHook.sol";

contract MineHookAddress is Script {
    function run() external view {
        address deployer = vm.envOr("DEPLOYER", address(this));
        address poolManager = vm.envOr("POOL_MANAGER", address(0));
        address morphoAdapter = vm.envOr("MORPHO_ADAPTER", address(0));
        address callbackProxy = vm.envOr("CALLBACK_PROXY", address(0));
        address directSettlementCaller = vm.envOr("DIRECT_SETTLEMENT_CALLER", deployer);
        address owner = vm.envOr("OWNER", deployer);

        uint160 flags =
            uint160(Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_SWAP_FLAG);
        bytes memory args =
            abi.encode(IPoolManager(poolManager), morphoAdapter, callbackProxy, directSettlementCaller, owner);
        (address hookAddress, bytes32 salt) = HookMiner.find(deployer, flags, type(YieldStreamHook).creationCode, args);

        console2.log("YieldStream hook flags", flags);
        console2.log("Mined hook address", hookAddress);
        console2.logBytes32(salt);
    }
}
