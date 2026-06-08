// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {TestERC20} from "../test/utils/TestERC20.sol";
import {FutureYieldToken} from "../src/tokens/FutureYieldToken.sol";
import {PrincipalToken} from "../src/tokens/PrincipalToken.sol";
import {YieldStreamHook} from "../src/YieldStreamHook.sol";
import {MorphoAdapter} from "../src/adapters/MorphoAdapter.sol";

contract LiveYieldStreamE2E is Script {
    uint160 internal constant SQRT_PRICE_1_1 = 79_228_162_514_264_337_593_543_950_336;
    string internal constant STATE_PATH = "./broadcast/yieldstream-live-demo-addresses.json";

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        string memory network = vm.envOr("YIELDSTREAM_E2E_NETWORK", string("base"));
        bool useUnichain = keccak256(bytes(network)) == keccak256(bytes("unichain"));

        address poolManager =
            useUnichain ? vm.envAddress("UNICHAIN_SEPOLIA_POOL_MANAGER") : vm.envAddress("BASE_SEPOLIA_POOL_MANAGER");
        address swapRouter = useUnichain
            ? vm.envAddress("UNICHAIN_SEPOLIA_POOL_SWAP_TEST")
            : vm.envAddress("BASE_SEPOLIA_POOL_SWAP_TEST");
        address hookAddress = useUnichain
            ? vm.envOr("UNICHAIN_SEPOLIA_YIELDSTREAM_HOOK_DEMO", vm.envAddress("UNICHAIN_SEPOLIA_YIELDSTREAM_HOOK"))
            : vm.envOr("BASE_SEPOLIA_YIELDSTREAM_HOOK_DEMO", vm.envAddress("BASE_SEPOLIA_YIELDSTREAM_HOOK"));
        address adapterAddress = useUnichain
            ? vm.envOr(
                "UNICHAIN_SEPOLIA_YIELDSTREAM_ADAPTER_DEMO", vm.envAddress("UNICHAIN_SEPOLIA_YIELDSTREAM_ADAPTER")
            )
            : vm.envOr("BASE_SEPOLIA_YIELDSTREAM_ADAPTER_DEMO", vm.envAddress("BASE_SEPOLIA_YIELDSTREAM_ADAPTER"));
        address rscAddress = useUnichain
            ? vm.envOr("UNICHAIN_SEPOLIA_YIELDSTREAM_RSC_DEMO", vm.envAddress("UNICHAIN_SEPOLIA_YIELDSTREAM_RSC"))
            : vm.envOr("BASE_SEPOLIA_YIELDSTREAM_RSC_DEMO", vm.envAddress("BASE_SEPOLIA_YIELDSTREAM_RSC"));

        console2.log("YieldStream live E2E network", useUnichain ? "unichain-sepolia" : "base-sepolia");
        console2.log("deployer", deployer);
        console2.log("poolManager", poolManager);
        console2.log("swapRouter", swapRouter);
        console2.log("hook", hookAddress);
        console2.log("adapter", adapterAddress);
        console2.log("rsc", rscAddress);

        vm.startBroadcast(deployerKey);

        TestERC20 rawA = new TestERC20("YieldStream E2E Token A", "YSE2EA");
        TestERC20 rawB = new TestERC20("YieldStream E2E Token B", "YSE2EB");
        (TestERC20 token0, TestERC20 token1) = address(rawA) < address(rawB) ? (rawA, rawB) : (rawB, rawA);

        token0.mint(deployer, 1_000_000 ether);
        token1.mint(deployer, 1_000_000 ether);
        token0.mint(hookAddress, 1_000_000 ether);
        token1.mint(hookAddress, 1_000_000 ether);

        token0.approve(swapRouter, type(uint256).max);
        token1.approve(swapRouter, type(uint256).max);
        token0.approve(hookAddress, type(uint256).max);
        token1.approve(hookAddress, type(uint256).max);

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hookAddress)
        });

        IPoolManager(poolManager).initialize(key, SQRT_PRICE_1_1);

        uint256 epochId = YieldStreamHook(payable(hookAddress)).currentEpoch();
        console2.log("currentEpoch", epochId);

        (uint256 depositEpoch, uint256 amount0Deposited, uint256 amount1Deposited) =
            YieldStreamHook(payable(hookAddress)).depositManagedLiquidity(
                YieldStreamHook.ManagedLiquidityParams({
                    key: key,
                    tickLower: -60,
                    tickUpper: 60,
                    liquidity: uint128(1 ether),
                    salt: bytes32(0),
                    maxAmount0: 10 ether,
                    maxAmount1: 10 ether
                })
            );
        epochId = depositEpoch;
        console2.log("managed deposit epoch", epochId);
        console2.log("managed deposit amount0", amount0Deposited);
        console2.log("managed deposit amount1", amount1Deposited);

        address fytAddress = YieldStreamHook(payable(hookAddress)).fytContracts(epochId);
        address ptAddress = YieldStreamHook(payable(hookAddress)).ptContracts(epochId);
        FutureYieldToken fyt = FutureYieldToken(fytAddress);
        PrincipalToken pt = PrincipalToken(ptAddress);
        address positionOwner = deployer;

        console2.log("fyt", fytAddress);
        console2.log("pt", ptAddress);
        console2.log("position owner", positionOwner);
        console2.log("position owner FYT", fyt.balanceOf(positionOwner));
        console2.log("position owner PT", pt.balanceOf(positionOwner));

        console2.log("swap 1: executes against the active epoch");
        PoolSwapTest(swapRouter)
            .swap(
                key,
                SwapParams({
                zeroForOne: true, amountSpecified: -0.01 ether, sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
                PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
                ""
            );
        YieldStreamHook(payable(hookAddress)).reportFees(key, epochId, 0.001 ether, 0.002 ether);

        bool triggerSettlementSwap = vm.envOr("YIELDSTREAM_TRIGGER_SETTLEMENT_SWAP", true);
        uint256 maxWaitSeconds = vm.envOr("YIELDSTREAM_SETTLEMENT_WAIT_SECONDS", uint256(90));
        if (triggerSettlementSwap) {
            uint256 waited;
            while (YieldStreamHook(payable(hookAddress)).currentEpoch() <= epochId && waited < maxWaitSeconds) {
                vm.sleep(2);
                waited += 2;
            }

            uint256 observedEpoch = YieldStreamHook(payable(hookAddress)).currentEpoch();
            if (observedEpoch > epochId) {
                console2.log("settlement trigger epoch", observedEpoch);
                console2.log("swap 2: executes after boundary; reportFees should queue reactive settlement");
                PoolSwapTest(swapRouter)
                    .swap(
                        key,
                        SwapParams({
                        zeroForOne: false,
                        amountSpecified: -0.01 ether,
                        sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
                    }),
                        PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
                        ""
                    );
                YieldStreamHook(payable(hookAddress)).reportFees(key, epochId, 0.003 ether, 0.004 ether);
            } else {
                console2.log("settlement trigger skipped: epoch did not advance within wait seconds", maxWaitSeconds);
            }
        }

        (uint256 fees0, uint256 fees1) = YieldStreamHook(payable(hookAddress)).getEpochFees(epochId);
        (uint256 totalLiquidity, uint256 totalFees0, uint256 totalFees1, uint256 totalCapital0, uint256 totalCapital1) =
            YieldStreamHook(payable(hookAddress)).getEpochTotals(epochId);

        console2.log("epoch fees0", fees0);
        console2.log("epoch fees1", fees1);
        console2.log("totalLiquidity", totalLiquidity);
        console2.log("totalFees0", totalFees0);
        console2.log("totalFees1", totalFees1);
        console2.log("totalCapital0", totalCapital0);
        console2.log("totalCapital1", totalCapital1);
        console2.log("owner", YieldStreamHook(payable(hookAddress)).owner());
        console2.log("callbackProxy", YieldStreamHook(payable(hookAddress)).callbackProxy());
        console2.log("reactiveSender", YieldStreamHook(payable(hookAddress)).reactiveSender());
        console2.log("epochLength", YieldStreamHook(payable(hookAddress)).epochLength());
        console2.log("adapter hook", MorphoAdapter(adapterAddress).hook());
        console2.log("adapter morpho", MorphoAdapter(adapterAddress).morpho());

        vm.stopBroadcast();

        console2.log("Live proof complete: hook-owned liquidity and swap callbacks executed on deployed v4 PoolManager.");
        console2.log("Reactive settlement is expected only if a second FeesAccrued was emitted after the epoch boundary.");

        string memory root = "liveDemo";
        vm.serializeString(root, "network", useUnichain ? "unichain-sepolia" : "base-sepolia");
        vm.serializeUint(root, "destinationChainId", block.chainid);
        vm.serializeAddress(root, "deployer", deployer);
        vm.serializeAddress(root, "poolManager", poolManager);
        vm.serializeAddress(root, "swapRouter", swapRouter);
        vm.serializeAddress(root, "hook", hookAddress);
        vm.serializeAddress(root, "adapter", adapterAddress);
        vm.serializeAddress(root, "rsc", rscAddress);
        vm.serializeAddress(root, "token0", address(token0));
        vm.serializeAddress(root, "token1", address(token1));
        vm.serializeAddress(root, "fyt", fytAddress);
        vm.serializeAddress(root, "pt", ptAddress);
        vm.serializeAddress(root, "positionOwner", positionOwner);
        vm.serializeUint(root, "epochId", epochId);
        vm.serializeUint(root, "epochLength", YieldStreamHook(payable(hookAddress)).epochLength());
        vm.serializeUint(root, "fees0", fees0);
        string memory json = vm.serializeUint(root, "fees1", fees1);
        vm.writeJson(json, STATE_PATH);
    }
}
