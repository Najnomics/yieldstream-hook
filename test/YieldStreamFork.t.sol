// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

contract YieldStreamForkTest is Test {
    function testForkHarness_UsesConfiguredMainnetRpcWhenAvailable() public {
        string memory rpc = vm.envOr("MAINNET_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            assertTrue(true);
            return;
        }
        uint256 forkId = vm.createFork(rpc);
        vm.selectFork(forkId);
        assertGt(block.number, 0);
    }
}
