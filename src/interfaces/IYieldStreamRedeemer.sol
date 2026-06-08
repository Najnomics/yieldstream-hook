// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IYieldStreamRedeemer {
    function redeemFYTFor(address holder, address recipient, uint256 amount)
        external
        returns (uint256 fees0, uint256 fees1);

    function redeemPTFor(address holder, address recipient, uint256 amount)
        external
        returns (uint256 capital0, uint256 capital1);
}
