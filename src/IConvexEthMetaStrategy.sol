// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

library InitializableAbstractStrategy {
    struct BaseStrategyConfig {
        address platformAddress;
        address vaultAddress;
    }
}

interface IConvexEthMetaStrategy {
    struct ConvexEthMetaConfig {
        address cvxDepositorAddress;
        address cvxRewardStakerAddress;
        uint256 cvxDepositorPTokenId;
        address oethAddress;
        address wethAddress;
    }

    event Deposit(address indexed _asset, address _pToken, uint256 _amount);
    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);
    event HarvesterAddressesUpdated(address _oldHarvesterAddress, address _newHarvesterAddress);
    event PTokenAdded(address indexed _asset, address _pToken);
    event PTokenRemoved(address indexed _asset, address _pToken);
    event PendingGovernorshipTransfer(address indexed previousGovernor, address indexed newGovernor);
    event RewardTokenAddressesUpdated(address[] _oldAddresses, address[] _newAddresses);
    event RewardTokenCollected(address recipient, address rewardToken, uint256 amount);
    event Withdrawal(address indexed _asset, address _pToken, uint256 _amount);

    receive() external payable;

    function ETH_ADDRESS() external view returns (address);
    function MAX_SLIPPAGE() external view returns (uint256);
    function assetToPToken(address) external view returns (address);
    function checkBalance(address _asset) external view returns (uint256 balance);
    function claimGovernance() external;
    function collectRewardTokens() external;
    function curvePool() external view returns (address);
    function cvxDepositorAddress() external view returns (address);
    function cvxDepositorPTokenId() external view returns (uint256);
    function cvxRewardStaker() external view returns (address);
    function deposit(address _weth, uint256 _amount) external;
    function depositAll() external;
    function ethCoinIndex() external view returns (uint128);
    function getRewardTokenAddresses() external view returns (address[] memory);
    function governor() external view returns (address);
    function harvesterAddress() external view returns (address);
    function initialize(address[] memory _rewardTokenAddresses, address[] memory _assets, address[] memory _pTokens)
        external;
    function initialize(address[] memory _rewardTokenAddresses, address[] memory _assets) external;
    function isGovernor() external view returns (bool);
    function lpToken() external view returns (address);
    function mintAndAddOTokens(uint256 _oTokens) external;
    function oeth() external view returns (address);
    function oethCoinIndex() external view returns (uint128);
    function platformAddress() external view returns (address);
    function removeAndBurnOTokens(uint256 _lpTokens) external;
    function removeOnlyAssets(uint256 _lpTokens) external;
    function removePToken(uint256 _assetIndex) external;
    function rewardTokenAddresses(uint256) external view returns (address);
    function safeApproveAllTokens() external;
    function setHarvesterAddress(address _harvesterAddress) external;
    function setPTokenAddress(address _asset, address _pToken) external;
    function setRewardTokenAddresses(address[] memory _rewardTokenAddresses) external;
    function supportsAsset(address _asset) external view returns (bool);
    function transferGovernance(address _newGovernor) external;
    function transferToken(address _asset, uint256 _amount) external;
    function vaultAddress() external view returns (address);
    function weth() external view returns (address);
    function withdraw(address _recipient, address _weth, uint256 _amount) external;
    function withdrawAll() external;
}
