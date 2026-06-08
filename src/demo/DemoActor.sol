// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {YieldStreamHook} from "../YieldStreamHook.sol";
import {FutureYieldToken} from "../tokens/FutureYieldToken.sol";
import {PrincipalToken} from "../tokens/PrincipalToken.sol";

contract DemoActor {
    error TransferFailed();

    string public name;

    event DemoFYTTransferred(address indexed token, address indexed recipient, uint256 amount);
    event DemoFYTRedeemed(uint256 indexed epochId, uint256 amount, uint256 fees0, uint256 fees1);
    event DemoPTRedeemed(uint256 indexed epochId, uint256 amount, uint256 capital0, uint256 capital1);

    constructor(string memory _name) {
        name = _name;
    }

    function transferAllFYT(address fyt, address recipient) external returns (uint256 amount) {
        amount = FutureYieldToken(fyt).balanceOf(address(this));
        if (!FutureYieldToken(fyt).transfer(recipient, amount)) revert TransferFailed();
        emit DemoFYTTransferred(fyt, recipient, amount);
    }

    function redeemAllFYT(YieldStreamHook hook, uint256 epochId) external returns (uint256 fees0, uint256 fees1) {
        FutureYieldToken fyt = FutureYieldToken(hook.fytContracts(epochId));
        uint256 amount = fyt.balanceOf(address(this));
        (fees0, fees1) = hook.redeemFYT(epochId, amount);
        emit DemoFYTRedeemed(epochId, amount, fees0, fees1);
    }

    function redeemAllPT(YieldStreamHook hook, uint256 epochId) external returns (uint256 capital0, uint256 capital1) {
        PrincipalToken pt = PrincipalToken(hook.ptContracts(epochId));
        uint256 amount = pt.balanceOf(address(this));
        (capital0, capital1) = hook.redeemPT(epochId, amount);
        emit DemoPTRedeemed(epochId, amount, capital0, capital1);
    }
}
