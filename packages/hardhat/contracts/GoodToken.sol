// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract GoodNFT is Context, ERC165, IERC721, IERC721Metadata {
using Address for address;
using Strings for uint256;

string private _name = "GoodToken";
string private _symbol = "GBT";

struct NFT {
    address owner;
    address payer;
    bool soulbound;
    string tokenURI;
}

mapping(uint256 => NFT) private _nfts;
mapping(address => uint256[]) private _ownedTokens;
mapping(uint256 => uint256) private _ownedTokensIndex;
mapping(uint256 => address) private _tokenApprovals;
mapping(address => mapping(address => bool)) private _operatorApprovals;

constructor() {}

function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
{
    return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
}

function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
{
    require(
        owner != address(0),
        "ERC721: address zero is not a valid owner"
    );
    return _ownedTokens[owner].length;
}

function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
{
    address owner = _nfts[tokenId].owner;
    require(owner != address(0), "ERC721: invalid token ID");
    return owner;
}

function name() public view virtual override returns (string memory) {
    return _name;
}

function symbol() public view virtual override returns (string memory) {
    return _symbol;
}

function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
{
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return
        bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : "";
}

function _baseURI() internal view virtual returns (string memory) {
    return "";
}

function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
) internal virtual {
    _transfer(from, to, tokenId);
    require(
        _checkOnERC721Received(from, to, tokenId, data),
        "ERC721: transfer to non ERC721Receiver implementer"
    );
}

function _exists(uint256 tokenId) internal view virtual returns(bool) {
return _nfts[tokenId].owner != address(0);
}

function _safeMint1(address to, uint256 tokenId, address _payer,    string memory uri) internal virtual {
    _safeMint11(to, tokenId, _payer,"",uri);
}

function _safeMint11(
    address to,
    uint256 tokenId,
    address _payer,
    bytes memory data,
    string memory uri
) internal virtual {
    _mint(to, tokenId, _payer, false,uri);
    require(
        _checkOnERC721Received(address(0), to, tokenId, data),
        "ERC721: transfer to non ERC721Receiver implementer"
    );
}

function _mint(
    address to,
    uint256 tokenId,
    address _payerAddress,
    bool soulbound,
    string memory uri
) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId, 1);

    unchecked {
        _ownedTokens[to].push(tokenId);
        _nfts[tokenId] = NFT({
            owner: to,
            payer: _payerAddress,
            soulbound: soulbound,
            tokenURI: uri
        });
    }

    _ownedTokensIndex[tokenId] = _ownedTokens[to].length - 1;

    if (bytes(uri).length > 0) {
        _setTokenURI(tokenId, uri);
    }

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId, 1);
}

function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    require(_exists(tokenId), "ERC721: URI set of nonexistent token");
    _nfts[tokenId].tokenURI = _tokenURI;
}

function _transfer(
    address from,
    address to,
    uint256 tokenId
) internal virtual {
    require(
        ownerOf(tokenId) == from,
        "ERC721: transfer of token that is not owned"
    );
    require(
        !_nfts[tokenId].soulbound,
        "ERC721: token is soulbound and cannot be transferred"
    );
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId, 1);

    unchecked {
        _ownedTokens[from][_ownedTokensIndex[tokenId]] = _ownedTokens[from][
            _ownedTokens[from].length - 1
        ];
        _ownedTokens[from].pop();
        _ownedTokens[to].push(tokenId);
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length - 1;
    }

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId, 1);
}

function _requireMinted(uint256 tokenId) internal view virtual {
    require(_exists(tokenId), "ERC721: invalid token ID");
}

function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
) private returns (bool) {
    if (to.isContract()) {
        try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                data
            )
        returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert(
                    "ERC721: transfer to non ERC721Receiver implementer"
                );
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    } else {
        return true;
    }
}

function _beforeTokenTransfer(
    address from,
    address to,
    uint256, /* firstTokenId */
    uint256 batchSize
) internal virtual {
    if (batchSize > 1){
        if (from != address(0)) {
            for (uint256 i = _ownedTokens[from].length - batchSize; i < _ownedTokens[from].length; i++) {
                delete _ownedTokensIndex[_ownedTokens[from][i]];
            }
        }
        if (to != address(0)) {
            uint256 start = _ownedTokens[to].length;
            for (uint256 i = start; i < start + batchSize; i++) {
                _ownedTokens[to].push(0);
                _ownedTokensIndex[_ownedTokens[to][i]] = i;
            }
        }
    }
}


function approve(address to, uint256 tokenId) external override {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
        _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
        "ERC721: approve caller is not owner nor approved for all"
    );

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
}

function getApproved(uint256 tokenId)
    public
    view
    override
    returns (address operator)
{
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    return _tokenApprovals[tokenId];
}

function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
{
    return _operatorApprovals[owner][operator];
}

function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
) external override {
    _safeTransfer(from, to, tokenId, data);
}

function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
) external override {
    _safeTransfer(from, to, tokenId, "");
}

function transferFrom(
    address from,
    address to,
    uint256 tokenId
) external override {
    //solhint-disable-next-line max-line-length
    require(
        _isApprovedOrOwner(_msgSender(), tokenId),
        "ERC721: transfer caller is not owner nor approved"
    );
    _transfer(from, to, tokenId);
}

function setApprovalForAll(address operator, bool _approved)
    external
    override
{
    require(operator != _msgSender(), "ERC721: approve to caller");

    _operatorApprovals[_msgSender()][operator] = _approved;
    emit ApprovalForAll(_msgSender(), operator, _approved);
}

function _afterTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
) internal virtual {
    if (batchSize > 1){
        if (from != address(0)) {
            for (uint256 i = _ownedTokens[from].length - batchSize; i < _ownedTokens[from].length; i++) {
                _ownedTokensIndex[_ownedTokens[from][i]] = i;
            }
        }
        if (to != address(0)) {
            for (uint256 i = _ownedTokens[to].length - batchSize; i < _ownedTokens[to].length; i++) {
                _ownedTokensIndex[_ownedTokens[to][i]] = i;
            }
        }
    } else {
        _ownedTokensIndex[firstTokenId] = _ownedTokens[to].length - 1;
    }
}

function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    returns (bool)
{
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner ||
        getApproved(tokenId) == spender ||
        isApprovedForAll(owner, spender));
}

function isSoulbound(uint256 tokenId) public view returns (bool) {
    return _nfts[tokenId].soulbound;
}

function getNFTInfo(uint256 tokenId)
    public
    view
    returns (
        address owner,
        string memory _tokenURI,
        address approvedAddress,
        bool _isApprovedForAll,
        uint256 balance,
        bool soulbound,
        address payer
    )
{
    owner = _nfts[tokenId].owner;
    _tokenURI = tokenURI(tokenId);
    approvedAddress = _tokenApprovals[tokenId];
    _isApprovedForAll = _operatorApprovals[owner][msg.sender];
    balance = balanceOf(owner);
    soulbound = _nfts[tokenId].soulbound;
    payer = _nfts[tokenId].payer;
}

function soulbind(uint256 tokenId) public {
    require(ownerOf(tokenId) == _msgSender(), "ERC721: caller is not the owner of the token");
    require(!_nfts[tokenId].soulbound, "ERC721: token is already soulbound");
    _nfts[tokenId].soulbound = true;
}
}