// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IYieldStreamRedeemer} from "../interfaces/IYieldStreamRedeemer.sol";

contract PrincipalToken is ERC20 {
    error OnlyHook();
    error AlreadyRedeemable();

    uint256 public immutable epochId;
    address public immutable hook;
    bool public redeemable;
    uint256 public capitalPerToken0;
    uint256 public capitalPerToken1;

    modifier onlyHook() {
        if (msg.sender != hook) revert OnlyHook();
        _;
    }

    constructor(uint256 _epochId, address _hook, string memory name_, string memory symbol_) ERC20(name_, symbol_, 18) {
        epochId = _epochId;
        hook = _hook;
    }

    function mint(address to, uint256 amount) external onlyHook {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyHook {
        _burn(from, amount);
    }

    function enableRedemption(uint256 _capitalPerToken0, uint256 _capitalPerToken1) external onlyHook {
        if (redeemable) revert AlreadyRedeemable();
        redeemable = true;
        capitalPerToken0 = _capitalPerToken0;
        capitalPerToken1 = _capitalPerToken1;
    }

    function redeem(address recipient) external returns (uint256 capital0, uint256 capital1) {
        return IYieldStreamRedeemer(hook).redeemPTFor(msg.sender, recipient, balanceOf[msg.sender]);
    }
}
