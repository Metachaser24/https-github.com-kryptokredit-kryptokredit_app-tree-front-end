// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ValidatorNFT is Ownable, ERC721Holder, ERC721 {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    uint256 public mintCount;

    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public staked;

    event Staked(address indexed staker, uint256 amount, uint256 tokenId);
    event Unstaked(address indexed unstaker, uint256 amount, uint256 tokenId);
    event WhitelistAdded(address indexed admin, address indexed account);
    event WhitelistRemoved(address indexed admin, address indexed account);

    constructor(address _stakingToken)
        ERC721("ValidatorNFT", "VFT")
    {
        stakingToken = IERC20(_stakingToken);
        mintCount = 0;
    }

    function getStake(address _staker) public view returns (uint) {
        return staked[_staker];
    }

    function stake(uint256 _stakingAmount) public {
        require(whitelisted[msg.sender], "You are not whitelisted");
        stakingToken.safeTransferFrom(
            msg.sender,
            address(this),
            _stakingAmount
        );
        mintCount++;
        uint256 tokenId = mintCount;

        staked[msg.sender] += _stakingAmount;
        _safeMint(msg.sender, tokenId);

        emit Staked(msg.sender, _stakingAmount, tokenId);
    }

    function unstake() public {
        uint256 tokenId = balanceOf(msg.sender);
        require(tokenId > 0, "You don't have any NFTs to unstake");

        uint256 stakedAmount = staked[msg.sender];
        stakingToken.safeTransfer(msg.sender, stakedAmount);
        staked[msg.sender] = 0;

        safeTransferFrom(msg.sender, address(this), tokenId);
        _burn(tokenId);

        emit Unstaked(msg.sender, stakedAmount, tokenId);
    }

    function addWhitelistedAddress(address _address) public onlyOwner {
        whitelisted[_address] = true;

        emit WhitelistAdded(msg.sender, _address);
    }

    function removeWhitelistedAddress(address _address) public onlyOwner {
        whitelisted[_address] = false;

        emit WhitelistRemoved(msg.sender, _address);
    }
}
