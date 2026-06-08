// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BaseHook} from "v4-hooks-public/src/base/BaseHook.sol";
import {YieldStreamHook} from "../../src/YieldStreamHook.sol";
import {YieldStreamTokenFactory} from "../../src/tokens/YieldStreamTokenFactory.sol";

contract YieldStreamHookHarness is YieldStreamHook {
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
}
