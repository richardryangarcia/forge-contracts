// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import {MerkleProof} from
    "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

import "forge-std/console2.sol";

/// @title An NFT edition contract
/// @author Richard Ryan @ryanoffthewall
contract Edition is ERC721, IERC2981, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // ===== Variables =====
    string internal baseTokenURI;

    RoyaltyInfo private _royalties;

    Counters.Counter private _tokenIdCount;

    bytes32 public merkleRoot;


    // ===== Structs =====
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    // ===== Constructor =====
    constructor(string memory _name, string memory _symbol, string memory _baseTokenURI)
        ERC721(_name, _symbol)
    {
        setBaseURI(_baseTokenURI);
    }

    // ===== Token URI =====

    /// @dev Sets base content URI for entire collection
    /// @param _baseTokenURI Content uri i.e. (ipfs://)
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Used to form token URI
    /// @return Base content uri 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mint() external payable {}

    function presaleMint(bytes32[] calldata _proof) external payable {
        require(
            MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Address not in accepted list"
        );
        uint256 tokenId = _tokenIdCount.current();
        _safeMint(msg.sender, tokenId);
        _tokenIdCount.increment();

    }


    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, "Royalty Fraction Too high");
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _royalties;

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / 10000;

        return (royalty.receiver, royaltyAmount);
    }
}
