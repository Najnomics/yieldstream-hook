// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FutureYieldToken} from "./FutureYieldToken.sol";
import {PrincipalToken} from "./PrincipalToken.sol";

contract YieldStreamTokenFactory {
    function createTokens(uint256 epochId, address hook) external returns (address fyt, address pt) {
        fyt = address(new FutureYieldToken(epochId, hook, "YieldStream Future Yield", "YS-FYT"));
        pt = address(new PrincipalToken(epochId, hook, "YieldStream Principal", "YS-PT"));
    }
}
