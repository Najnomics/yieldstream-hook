// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BaseHook} from "v4-hooks-public/src/base/BaseHook.sol";
import {YieldStreamHook} from "../YieldStreamHook.sol";
import {FutureYieldToken} from "../tokens/FutureYieldToken.sol";
import {PrincipalToken} from "../tokens/PrincipalToken.sol";
import {YieldStreamTokenFactory} from "../tokens/YieldStreamTokenFactory.sol";

contract DemoYieldStreamHookHarness is YieldStreamHook {
    constructor(
        IPoolManager poolManager,
        address morphoAdapter,
        address callbackProxy,
        address directSettlementCaller,
        uint256 epochLength
    )
        YieldStreamHook(
            poolManager,
            address(new YieldStreamTokenFactory()),
            morphoAdapter,
            callbackProxy,
            directSettlementCaller,
            msg.sender,
            epochLength
        )
    {}

    function validateHookAddress(BaseHook) internal pure override {}

    function exposedAfterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external returns (bytes4, BalanceDelta) {
        return _afterAddLiquidity(sender, key, params, delta, feesAccrued, hookData);
    }

    function exposedAfterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4, int128) {
        return _afterSwap(sender, key, params, delta, hookData);
    }

    function exposedBeforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external view returns (bytes4) {
        return _beforeRemoveLiquidity(sender, key, params, hookData);
    }

    function demoSettleEpoch(uint256 epochId) external {
        EpochState storage epoch = _epochs[epochId];
        if (epoch.fytContract == address(0)) revert EpochNotStarted();
        if (epoch.settled) revert EpochSettledAlready();

        epoch.settled = true;

        uint256 fytSupply = FutureYieldToken(epoch.fytContract).totalSupply();
        uint256 ptSupply = PrincipalToken(epoch.ptContract).totalSupply();
        uint256 feesPerToken0 = fytSupply == 0 ? 0 : (epoch.totalFees0 * PRECISION) / fytSupply;
        uint256 feesPerToken1 = fytSupply == 0 ? 0 : (epoch.totalFees1 * PRECISION) / fytSupply;
        uint256 capitalPerToken0 = ptSupply == 0 ? 0 : (epoch.totalCapital0 * PRECISION) / ptSupply;
        uint256 capitalPerToken1 = ptSupply == 0 ? 0 : (epoch.totalCapital1 * PRECISION) / ptSupply;

        FutureYieldToken(epoch.fytContract).settle(feesPerToken0, feesPerToken1);
        PrincipalToken(epoch.ptContract).enableRedemption(capitalPerToken0, capitalPerToken1);

        emit EpochSettled(
            epochId, epoch.totalFees0, epoch.totalFees1, 0, 0, epoch.totalLiquidity
        );
    }
}
