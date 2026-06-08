// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IYieldStreamRedeemer} from "../interfaces/IYieldStreamRedeemer.sol";

contract FutureYieldToken is ERC20 {
    error OnlyHook();
    error AlreadySettled();

    uint256 public immutable epochId;
    address public immutable hook;
    bool public settled;
    uint256 public feesPerToken0;
    uint256 public feesPerToken1;

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

    function settle(uint256 _feesPerToken0, uint256 _feesPerToken1) external onlyHook {
        if (settled) revert AlreadySettled();
        settled = true;
        feesPerToken0 = _feesPerToken0;
        feesPerToken1 = _feesPerToken1;
    }

    function redeem(address recipient) external returns (uint256 fees0, uint256 fees1) {
        return IYieldStreamRedeemer(hook).redeemFYTFor(msg.sender, recipient, balanceOf[msg.sender]);
    }
}
