// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GoodToken.sol";
import "./Invoice.sol";

contract NFTMinter is GoodNFT {
    GoodNFT private _soulboundNFT;
    NFTInvoice private _otherNFT;

    constructor(address otherNFTAddress) {
        _otherNFT = NFTInvoice(otherNFTAddress);
    }

    function mintSoulboundNFT(uint256 otherNFTTokenId, address payer, string memory uri) external {
        address otherNFTOwner = _otherNFT.ownerOf(otherNFTTokenId);
        require(
            otherNFTOwner == msg.sender,
            "You must be the owner of the other NFT to mint a SoulboundNFT"
        );
        _safeMint1(payer, otherNFTTokenId, payer,uri);
        soulbind(otherNFTTokenId);
    }
}