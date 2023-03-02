// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IValidatorNFT {
    function stake(uint256 _stakingAmount) external;
    function unstake() external;
    function addWhitelistedAddress(address _address) external;
    function removeWhitelistedAddress(address _address) external;
    function getStaked(address _staker) external returns (uint);
    function stakingToken() external view returns (address);
    function mintCount() external view returns (uint256);
    function whitelisted(address _address) external view returns (bool);
    function getStake(address _address) external view returns (uint256);

    event Staked(address indexed staker, uint256 amount, uint256 tokenId);
    event Unstaked(address indexed unstaker, uint256 amount, uint256 tokenId);
    event WhitelistAdded(address indexed admin, address indexed account);
    event WhitelistRemoved(address indexed admin, address indexed account);
}