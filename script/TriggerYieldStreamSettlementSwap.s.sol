// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {TestERC20} from "../test/utils/TestERC20.sol";
import {YieldStreamHook} from "../src/YieldStreamHook.sol";

contract TriggerYieldStreamSettlementSwap is Script {
    string internal constant STATE_PATH = "./broadcast/yieldstream-live-demo-addresses.json";

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        string memory json = vm.readFile(STATE_PATH);
        string memory network = vm.parseJsonString(json, ".network");
        bool useUnichain = keccak256(bytes(network)) == keccak256(bytes("unichain-sepolia"));

        address swapRouter = useUnichain
            ? vm.envAddress("UNICHAIN_SEPOLIA_POOL_SWAP_TEST")
            : vm.envAddress("BASE_SEPOLIA_POOL_SWAP_TEST");
        address hookAddress = vm.parseJsonAddress(json, ".hook");
        address token0 = vm.parseJsonAddress(json, ".token0");
        address token1 = vm.parseJsonAddress(json, ".token1");
        uint256 originalEpoch = vm.parseJsonUint(json, ".epochId");

        uint256 currentEpoch = YieldStreamHook(payable(hookAddress)).currentEpoch();
        require(currentEpoch > originalEpoch, "YieldStream: epoch has not advanced");

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hookAddress)
        });

        vm.startBroadcast(deployerKey);
        TestERC20(token0).approve(swapRouter, type(uint256).max);
        TestERC20(token1).approve(swapRouter, type(uint256).max);
        TestERC20(token0).approve(hookAddress, type(uint256).max);
        TestERC20(token1).approve(hookAddress, type(uint256).max);
        PoolSwapTest(swapRouter).swap(
            key,
            SwapParams({zeroForOne: false, amountSpecified: -0.01 ether, sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1}),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ""
        );
        YieldStreamHook(payable(hookAddress)).reportFees(key, originalEpoch, 0.003 ether, 0.004 ether);
        vm.stopBroadcast();

        console2.log("Settlement trigger swap complete");
        console2.log("hook", hookAddress);
        console2.log("original epoch", originalEpoch);
        console2.log("current epoch", currentEpoch);
    }
}
