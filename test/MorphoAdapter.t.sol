// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {MorphoAdapter} from "../src/adapters/MorphoAdapter.sol";

contract MorphoAdapterTest is Test {
    MorphoAdapter adapter;

    address morpho = address(0xBEEF);
    address hook = address(0xCAFE);
    address token = address(0xA0);

    function setUp() public {
        adapter = new MorphoAdapter(morpho);
        adapter.setHook(hook);
    }

    function test_constructorAndSetHook() public view {
        assertEq(adapter.morpho(), morpho);
        assertEq(adapter.hook(), hook);
    }

    function test_setHookOnlyOnce() public {
        vm.expectRevert(MorphoAdapter.HookAlreadySet.selector);
        adapter.setHook(address(0xD00D));
    }

    function test_onlyHookGuardsStateChangingSurface() public {
        MorphoAdapter.MarketParams memory market = _market();

        vm.expectRevert(MorphoAdapter.OnlyHook.selector);
        adapter.deposit(token, 1 ether, market);

        vm.expectRevert(MorphoAdapter.OnlyHook.selector);
        adapter.withdraw(token, 1 ether, market);

        vm.expectRevert(MorphoAdapter.OnlyHook.selector);
        adapter.setMockYield(0, token, 1 ether);
    }

    function test_depositWithdrawAndPendingYield() public {
        MorphoAdapter.MarketParams memory market = _market();

        vm.prank(hook);
        uint256 shares = adapter.deposit(token, 10 ether, market);
        assertEq(shares, 10 ether);
        assertEq(adapter.depositedAssets(block.number, token), 10 ether);

        vm.prank(hook);
        adapter.setMockYield(block.number, token, 2 ether);
        assertEq(adapter.pendingYield(block.number, token), 2 ether);

        vm.prank(hook);
        uint256 assets = adapter.withdraw(token, shares, market);
        assertEq(assets, 12 ether);
    }

    function _market() internal view returns (MorphoAdapter.MarketParams memory) {
        return MorphoAdapter.MarketParams({
            loanToken: token,
            collateralToken: address(0xB0),
            oracle: address(0xC0),
            irm: address(0xD0),
            lltv: 0.86 ether
        });
    }
}
