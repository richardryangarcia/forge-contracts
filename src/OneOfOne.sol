// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import {MerkleProof} from
    "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract OneOfOne is ERC721, IERC2981, Ownable {
    using Counters for Counters.Counter;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    mapping(uint256 => RoyaltyInfo) private _royalties;

    Counters.Counter private _tokenIdCount;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function _setRoyalties(uint256 _tokenId, address recipient, uint256 value)
        internal
    {
        require(value <= 10000, "Royalty Fraction Too high");
        _royalties[_tokenId] = RoyaltyInfo(recipient, uint24(value));
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _royalties[_tokenId];

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / 10000;

        return (royalty.receiver, royaltyAmount);
    }
}
