// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

/// @title An NFT edition contract
/// @author Richard Ryan @ryanoffthewall
contract Edition is ERC721, IERC2981, Ownable, ReentrancyGuard  {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // ===== Variables =====
    string public baseTokenURI;

    bytes32 public merkleRoot;

    mapping(address => uint256) public userMints; 

    Counters.Counter private _tokenIdCount;

    Counters.Counter private _teamMintCount;

    SaleConfig public saleConfig;

    RoyaltyInfo private _royalties;

    // ===== Constants =====
    uint256 public constant MAX_SUPPLY = 100;

    uint256 public constant MAX_PER_WALLET = 5;

    uint256 public constant PRESALE_MAX = 2;

    uint256 public constant TEAM_RESERVE = 10;

    uint256 public constant SALE_PRICE = .69 ether;


    // ===== Structs =====
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    struct SaleConfig {
        uint64 presaleStart;
        uint64 presaleEnd;
        uint64 publicStart;
    }

    // ===== Modifiers =====
    modifier verifyMaxPerWallet() {
        require(userMints[msg.sender] < MAX_PER_WALLET, "Collection mints exceeded for this wallet address");
        _;
    }

    modifier verifyPresaleMax() {
        require(userMints[msg.sender] < PRESALE_MAX, "Presale mints exceeded for this wallet address");
        _;
    }

    modifier verifyMaxSupply() {
        require(_tokenIdCount.current() < MAX_SUPPLY, "Collection sold out");
        _;
    }

    modifier verifyEthAmount() {
        require(msg.value == SALE_PRICE, "Incorrect Eth Amount");
        _;
    }

    modifier verifyTeamMints() {
        require(_teamMintCount.current() < TEAM_RESERVE, "Team reserve reached");
        _;
    }

    modifier verifyPublicMints() {
        require(_tokenIdCount.current() - _teamMintCount.current() < MAX_SUPPLY - TEAM_RESERVE, "Public sale max reached");
        _;
    }

    modifier verifyAllowList(bytes32[] calldata _proof) {
        require(
            MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Address not in accepted list"
        );
        _;
    }

    // ===== Constructor =====
    constructor(string memory _name, string memory _symbol, string memory _baseTokenURI)
        ERC721(_name, _symbol)
    {
        setBaseURI(_baseTokenURI);
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

    // ===== Mints =====
    /// @dev Public sale mint
    function mint() external payable verifyMaxSupply verifyPublicMints verifyMaxPerWallet verifyEthAmount nonReentrant {
        _safeMint(msg.sender, _tokenIdCount.current());
        _tokenIdCount.increment();
    }

    /// @dev Pre sale mint
    function presaleMint(bytes32[] calldata _proof) external payable verifyAllowList(_proof) verifyMaxSupply verifyPublicMints verifyPresaleMax verifyEthAmount nonReentrant {
        _safeMint(msg.sender, _tokenIdCount.current());
        _tokenIdCount.increment();

    }

    function adminMint() external payable onlyOwner {}

    // ===== Allowlist =====
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }


    // ===== Royalties =====
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

    // ===== Sale Config =====
    function _presaleActive() internal view returns (bool) {
        return saleConfig.presaleStart <= block.timestamp && block.timestamp < saleConfig.presaleEnd;
    }


    function _publicSaleActive() internal view returns (bool) {
        return saleConfig.publicStart <= block.timestamp;
    }
}
