// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ReactivePingOrigin {
    uint256 public nonce;

    event Ping(uint256 indexed nonce, address indexed sender, uint256 blockNumber);

    function ping() external returns (uint256 nextNonce) {
        nextNonce = ++nonce;
        emit Ping(nextNonce, msg.sender, block.number);
    }
}
