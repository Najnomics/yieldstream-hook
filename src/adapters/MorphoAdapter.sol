// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20Like {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IMorphoBlue {
    struct MarketParams {
        address loanToken;
        address collateralToken;
        address oracle;
        address irm;
        uint256 lltv;
    }

    function supply(
        MarketParams calldata marketParams,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        bytes calldata data
    ) external returns (uint256 assetsSupplied, uint256 sharesSupplied);

    function withdraw(
        MarketParams calldata marketParams,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        address receiver
    ) external returns (uint256 assetsWithdrawn, uint256 sharesWithdrawn);
}

contract MorphoAdapter {
    error OnlyHook();
    error HookAlreadySet();
    error TokenApprovalFailed();
    error TokenTransferFromFailed();
    error TokenTransferFailed();

    struct MarketParams {
        address loanToken;
        address collateralToken;
        address oracle;
        address irm;
        uint256 lltv;
    }

    address public immutable morpho;
    address public hook;

    mapping(uint256 => mapping(address => uint256)) public depositedAssets;
    mapping(uint256 => mapping(address => uint256)) public mockYield;

    modifier onlyHook() {
        if (msg.sender != hook) revert OnlyHook();
        _;
    }

    constructor(address _morpho) {
        morpho = _morpho;
    }

    function setHook(address _hook) external {
        if (hook != address(0)) revert HookAlreadySet();
        hook = _hook;
    }

    function deposit(address token, uint256 amount, MarketParams calldata marketParams)
        external
        onlyHook
        returns (uint256 shares)
    {
        if (morpho.code.length != 0) {
            if (!IERC20Like(token).transferFrom(msg.sender, address(this), amount)) {
                revert TokenTransferFromFailed();
            }
            if (!IERC20Like(token).approve(morpho, amount)) revert TokenApprovalFailed();
            (, shares) = IMorphoBlue(morpho).supply(_toMorphoMarketParams(marketParams), amount, 0, address(this), "");
            depositedAssets[block.number][token] += amount;
            return shares;
        }

        depositedAssets[block.number][token] += amount;
        return amount;
    }

    function withdraw(address token, uint256 shares, MarketParams calldata marketParams)
        external
        onlyHook
        returns (uint256 assets)
    {
        if (morpho.code.length != 0) {
            (assets,) = IMorphoBlue(morpho)
                .withdraw(_toMorphoMarketParams(marketParams), 0, shares, address(this), address(this));
            if (!IERC20Like(token).transfer(hook, assets)) revert TokenTransferFailed();
            return assets;
        }

        return shares + mockYield[block.number][token];
    }

    function setMockYield(uint256 epochId, address token, uint256 amount) external onlyHook {
        mockYield[epochId][token] = amount;
    }

    function pendingYield(uint256 epochId, address token) external view returns (uint256 yieldAmount) {
        return mockYield[epochId][token];
    }

    function _toMorphoMarketParams(MarketParams calldata marketParams)
        internal
        pure
        returns (IMorphoBlue.MarketParams memory)
    {
        return IMorphoBlue.MarketParams({
            loanToken: marketParams.loanToken,
            collateralToken: marketParams.collateralToken,
            oracle: marketParams.oracle,
            irm: marketParams.irm,
            lltv: marketParams.lltv
        });
    }
}
