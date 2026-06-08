// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-hooks-public/src/utils/HookMiner.sol";
import {MorphoAdapter} from "../src/adapters/MorphoAdapter.sol";
import {YieldStreamHook} from "../src/YieldStreamHook.sol";
import {YieldStreamTokenFactory} from "../src/tokens/YieldStreamTokenFactory.sol";

contract DeployYieldStream is Script {
    address internal constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        address poolManager = vm.envAddress("POOL_MANAGER");
        address callbackProxy = vm.envAddress("CALLBACK_PROXY");
        address directSettlementCaller = vm.envOr("DIRECT_SETTLEMENT_CALLER", deployer);
        address reactiveSender = vm.envOr("REACTIVE_SENDER", address(0));
        address morpho = vm.envOr("MORPHO", address(0));
        uint256 epochLength = vm.envOr("EPOCH_LENGTH", uint256(0));

        vm.startBroadcast(deployerKey);
        YieldStreamTokenFactory tokenFactory = new YieldStreamTokenFactory();
        MorphoAdapter adapter = new MorphoAdapter(morpho);

        uint160 flags =
            uint160(Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_SWAP_FLAG);
        bytes memory args = abi.encode(
            IPoolManager(poolManager),
            address(tokenFactory),
            address(adapter),
            callbackProxy,
            directSettlementCaller,
            deployer,
            epochLength
        );
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(YieldStreamHook).creationCode, args);

        YieldStreamHook hook = new YieldStreamHook{salt: salt}(
            IPoolManager(poolManager),
            address(tokenFactory),
            address(adapter),
            callbackProxy,
            directSettlementCaller,
            deployer,
            epochLength
        );
        require(address(hook) == hookAddress, "YieldStream: hook address mismatch");
        adapter.setHook(address(hook));
        if (reactiveSender != address(0)) hook.setReactiveSender(reactiveSender);
        vm.stopBroadcast();

        console2.log("Deployer", deployer);
        console2.log("TokenFactory", address(tokenFactory));
        console2.log("MorphoAdapter", address(adapter));
        console2.log("YieldStreamHook", address(hook));
        console2.log("PoolManager", poolManager);
        console2.log("Callback proxy", callbackProxy);
        console2.log("Reactive sender", reactiveSender);
        console2.log("Direct settlement caller", directSettlementCaller);
        console2.log("Morpho", morpho);
        console2.log("Epoch length", hook.epochLength());
    }
}
