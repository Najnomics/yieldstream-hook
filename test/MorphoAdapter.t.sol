// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {MorphoAdapter} from "../src/adapters/MorphoAdapter.sol";
import {TestERC20} from "./utils/TestERC20.sol";

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

    function test_morphoBackedDepositAndWithdraw() public {
        TestERC20 loanToken = new TestERC20("Loan", "LOAN");
        MockMorphoBlue mockMorpho = new MockMorphoBlue();
        MorphoAdapter liveAdapter = new MorphoAdapter(address(mockMorpho));
        liveAdapter.setHook(hook);

        MorphoAdapter.MarketParams memory market = MorphoAdapter.MarketParams({
            loanToken: address(loanToken),
            collateralToken: address(0xB0),
            oracle: address(0xC0),
            irm: address(0xD0),
            lltv: 0.86 ether
        });

        loanToken.mint(hook, 10 ether);
        vm.prank(hook);
        loanToken.approve(address(liveAdapter), 10 ether);

        vm.prank(hook);
        uint256 shares = liveAdapter.deposit(address(loanToken), 10 ether, market);
        assertEq(shares, 10 ether);
        assertEq(mockMorpho.suppliedAssets(), 10 ether);

        loanToken.mint(address(liveAdapter), 12 ether);
        mockMorpho.setWithdrawAssets(12 ether);

        vm.prank(hook);
        uint256 assets = liveAdapter.withdraw(address(loanToken), shares, market);
        assertEq(assets, 12 ether);
        assertEq(loanToken.balanceOf(hook), 12 ether);
    }

    function test_morphoBackedDepositRevertsOnTokenFailures() public {
        MockMorphoBlue mockMorpho = new MockMorphoBlue();
        MorphoAdapter liveAdapter = new MorphoAdapter(address(mockMorpho));
        liveAdapter.setHook(hook);
        FailingToken failingToken = new FailingToken();
        MorphoAdapter.MarketParams memory market = _marketFor(address(failingToken));

        failingToken.setTransferFromResult(false);
        vm.prank(hook);
        vm.expectRevert(MorphoAdapter.TokenTransferFromFailed.selector);
        liveAdapter.deposit(address(failingToken), 1 ether, market);

        failingToken.setTransferFromResult(true);
        failingToken.setApproveResult(false);
        vm.prank(hook);
        vm.expectRevert(MorphoAdapter.TokenApprovalFailed.selector);
        liveAdapter.deposit(address(failingToken), 1 ether, market);
    }

    function test_morphoBackedWithdrawRevertsOnTokenTransferFailure() public {
        MockMorphoBlue mockMorpho = new MockMorphoBlue();
        MorphoAdapter liveAdapter = new MorphoAdapter(address(mockMorpho));
        liveAdapter.setHook(hook);
        FailingToken failingToken = new FailingToken();
        MorphoAdapter.MarketParams memory market = _marketFor(address(failingToken));

        mockMorpho.setWithdrawAssets(1 ether);
        failingToken.setTransferResult(false);

        vm.prank(hook);
        vm.expectRevert(MorphoAdapter.TokenTransferFailed.selector);
        liveAdapter.withdraw(address(failingToken), 1 ether, market);
    }

    function _market() internal view returns (MorphoAdapter.MarketParams memory) {
        return _marketFor(token);
    }

    function _marketFor(address marketToken) internal pure returns (MorphoAdapter.MarketParams memory) {
        return MorphoAdapter.MarketParams({
            loanToken: marketToken,
            collateralToken: address(0xB0),
            oracle: address(0xC0),
            irm: address(0xD0),
            lltv: 0.86 ether
        });
    }
}

contract MockMorphoBlue {
    uint256 public suppliedAssets;
    uint256 public withdrawAssets;

    function setWithdrawAssets(uint256 assets) external {
        withdrawAssets = assets;
    }

    function supply(
        MorphoAdapter.MarketParams calldata,
        uint256 assets,
        uint256,
        address,
        bytes calldata
    ) external returns (uint256 assetsSupplied, uint256 sharesSupplied) {
        suppliedAssets += assets;
        return (assets, assets);
    }

    function withdraw(
        MorphoAdapter.MarketParams calldata,
        uint256,
        uint256 shares,
        address,
        address
    ) external view returns (uint256 assetsWithdrawn, uint256 sharesWithdrawn) {
        return (withdrawAssets == 0 ? shares : withdrawAssets, shares);
    }
}

contract FailingToken {
    bool public transferFromResult = true;
    bool public approveResult = true;
    bool public transferResult = true;

    function setTransferFromResult(bool value) external {
        transferFromResult = value;
    }

    function setApproveResult(bool value) external {
        approveResult = value;
    }

    function setTransferResult(bool value) external {
        transferResult = value;
    }

    function transferFrom(address, address, uint256) external view returns (bool) {
        return transferFromResult;
    }

    function approve(address, uint256) external view returns (bool) {
        return approveResult;
    }

    function transfer(address, uint256) external view returns (bool) {
        return transferResult;
    }
}
