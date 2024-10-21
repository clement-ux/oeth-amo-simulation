// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

library VaultStorage {
    type UnitConversion is uint8;

    struct Asset {
        bool isSupported;
        UnitConversion unitConversion;
        uint8 decimals;
        uint16 allowedOracleSlippageBps;
    }
}

interface IOETHVaultCore {
    event AllocateThresholdUpdated(uint256 _threshold);
    event AssetAllocated(address _asset, address _strategy, uint256 _amount);
    event AssetDefaultStrategyUpdated(address _asset, address _strategy);
    event AssetRemoved(address _asset);
    event AssetSupported(address _asset);
    event CapitalPaused();
    event CapitalUnpaused();
    event DripperChanged(address indexed _dripper);
    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);
    event MaxSupplyDiffChanged(uint256 maxSupplyDiff);
    event Mint(address _addr, uint256 _value);
    event NetOusdMintForStrategyThresholdChanged(uint256 _threshold);
    event OusdMetaStrategyUpdated(address _ousdMetaStrategy);
    event PendingGovernorshipTransfer(address indexed previousGovernor, address indexed newGovernor);
    event PriceProviderUpdated(address _priceProvider);
    event RebasePaused();
    event RebaseThresholdUpdated(uint256 _threshold);
    event RebaseUnpaused();
    event Redeem(address _addr, uint256 _value);
    event RedeemFeeUpdated(uint256 _redeemFeeBps);
    event StrategistUpdated(address _address);
    event StrategyAddedToMintWhitelist(address indexed strategy);
    event StrategyApproved(address _addr);
    event StrategyRemoved(address _addr);
    event StrategyRemovedFromMintWhitelist(address indexed strategy);
    event SwapAllowedUndervalueChanged(uint256 _basis);
    event SwapSlippageChanged(address _asset, uint256 _basis);
    event Swapped(
        address indexed _fromAsset, address indexed _toAsset, uint256 _fromAssetAmount, uint256 _toAssetAmount
    );
    event SwapperChanged(address _address);
    event TrusteeAddressChanged(address _address);
    event TrusteeFeeBpsChanged(uint256 _basis);
    event VaultBufferUpdated(uint256 _vaultBuffer);
    event WithdrawalClaimable(uint256 _claimable, uint256 _newClaimable);
    event WithdrawalClaimed(address indexed _withdrawer, uint256 indexed _requestId, uint256 _amount);
    event WithdrawalRequested(
        address indexed _withdrawer, uint256 indexed _requestId, uint256 _amount, uint256 _queued
    );
    event YieldDistribution(address _to, uint256 _yield, uint256 _fee);

    fallback() external;

    function CLAIM_DELAY() external view returns (uint256);
    function addWithdrawalQueueLiquidity() external;
    function allocate() external;
    function assetDefaultStrategies(address) external view returns (address);
    function autoAllocateThreshold() external view returns (uint256);
    function burnForStrategy(uint256 _amount) external;
    function cacheWETHAssetIndex() external;
    function calculateRedeemOutputs(uint256 _amount) external view returns (uint256[] memory);
    function capitalPaused() external view returns (bool);
    function checkBalance(address _asset) external view returns (uint256);
    function claimGovernance() external;
    function claimWithdrawal(uint256 _requestId) external returns (uint256 amount);
    function claimWithdrawals(uint256[] memory _requestIds)
        external
        returns (uint256[] memory amounts, uint256 totalAmount);
    function dripper() external view returns (address);
    function getAllAssets() external view returns (address[] memory);
    function getAllStrategies() external view returns (address[] memory);
    function getAssetConfig(address _asset) external view returns (VaultStorage.Asset memory config);
    function getAssetCount() external view returns (uint256);
    function getStrategyCount() external view returns (uint256);
    function governor() external view returns (address);
    function initialize(address _priceProvider, address _oToken) external;
    function isGovernor() external view returns (bool);
    function isMintWhitelistedStrategy(address) external view returns (bool);
    function isSupportedAsset(address _asset) external view returns (bool);
    function maxSupplyDiff() external view returns (uint256);
    function mint(address _asset, uint256 _amount, uint256 _minimumOusdAmount) external;
    function mintForStrategy(uint256 _amount) external;
    function netOusdMintForStrategyThreshold() external view returns (uint256);
    function netOusdMintedForStrategy() external view returns (int256);
    function ousdMetaStrategy() external view returns (address);
    function priceProvider() external view returns (address);
    function priceUnitMint(address asset) external view returns (uint256 price);
    function priceUnitRedeem(address asset) external view returns (uint256 price);
    function rebase() external;
    function rebasePaused() external view returns (bool);
    function rebaseThreshold() external view returns (uint256);
    function redeem(uint256 _amount, uint256 _minimumUnitAmount) external;
    function redeemAll(uint256 _minimumUnitAmount) external;
    function redeemFeeBps() external view returns (uint256);
    function requestWithdrawal(uint256 _amount) external returns (uint256 requestId, uint256 queued);
    function setAdminImpl(address newImpl) external;
    function strategistAddr() external view returns (address);
    function totalValue() external view returns (uint256 value);
    function transferGovernance(address _newGovernor) external;
    function trusteeAddress() external view returns (address);
    function trusteeFeeBps() external view returns (uint256);
    function vaultBuffer() external view returns (uint256);
    function weth() external view returns (address);
    function wethAssetIndex() external view returns (uint256);
    function withdrawalQueueMetadata()
        external
        view
        returns (uint128 queued, uint128 claimable, uint128 claimed, uint128 nextWithdrawalIndex);
    function withdrawalRequests(uint256)
        external
        view
        returns (address withdrawer, bool claimed, uint40 timestamp, uint128 amount, uint128 queued);
}
