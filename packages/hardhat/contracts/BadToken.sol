// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BadNFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    struct NFT {
        address sender;
        address recipient;
    }
    mapping (uint256 => NFT) private _tokenData;

    constructor() ERC721("BadToken", "BBT") {}

    function safeMint(address to, uint256 tokenId, string memory uri)
        public
        onlyTokenSender(tokenId)
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenData[tokenId] = NFT({ sender: msg.sender, recipient: to });
    }

    modifier onlyTokenSender(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        require(_msgSender() == _tokenData[tokenId].sender, "Only the token sender can perform this action");
        _;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyTokenSender(tokenId) {
        super.transferFrom(from, to, tokenId);
        _tokenData[tokenId].sender = to;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) onlyTokenSender(tokenId) {
        super._burn(tokenId);
        delete _tokenData[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}