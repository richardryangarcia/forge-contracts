// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "murky/Merkle.sol";
import "../src/Edition.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";


abstract contract HelperContract {
    Edition edition;
}

contract BaseTest is Test {
    // 0xb4c79dab8f259c7aee6e5b2aa729821864227e84 owner

    // 0x5dad7600c5d89fe3824ffa99ec1c3eb8bf3b0501 alice
    function mkaddr(string memory name) public returns (address) {
        address addr =
            address(uint160(uint256(keccak256(abi.encodePacked(name)))));
        vm.label(addr, name);
        return addr;
    }
}

contract ContractTest is BaseTest, HelperContract {
    address bob = address(0x1778);
    function setUp() public {
        edition = new Edition("NAME", "SYMBOL", "ipfs://QmYVsw73haPgm9jK9BopsuKtzuxLANjYn75xeHLpht13D5");
    }

    function testName() public {
        assertEq(edition.name(), "NAME");
    }

    function testSymbol() public {
        assertEq(edition.symbol(), "SYMBOL");
    }

    function testSetBaseUrlNotOwner() public {
        address alice = address(0x5dad7600C5D89fE3824fFa99ec1c3eB8BF3b0501);
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alice);
        edition.setBaseURI("http://new-base-url");
    }

    function testSetBaseUrlOwner() public {
        address owner = address(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        vm.prank(owner);
        edition.setBaseURI("http://new-base-url/");
        string memory newUri = edition.baseTokenURI();
        assertEq(newUri, "http://new-base-url/");
    }

    function testMerkleProof() public {
        bytes32 encodedAddress = bytes32(keccak256(abi.encodePacked(bob)));

        // define allow list
        bytes32[] memory data = new bytes32[](4);
        data[0] = bytes32("0x0");
        data[1] = encodedAddress;
        data[2] = bytes32("0x2");
        data[3] = bytes32("0x3");

        // set merkle root
        Merkle m = new Merkle();
        bytes32 root = m.getRoot(data);
        edition.setMerkleRoot(root);

        // verify proof is valid 
        bytes32[] memory proof = m.getProof(data, 1); 
        bool verifiedProof = m.verifyProof(root, proof, data[1]);
        assertEq(verifiedProof, true);

        // try and mint via presale allowlist
        vm.prank(bob);
        edition.presaleMint(proof);
    }

    function testCannotMintViaAllowList() public {
        bytes32 encodedAddress = bytes32(keccak256(abi.encodePacked(bob)));

        // define allow list
        bytes32[] memory data = new bytes32[](4);
        data[0] = bytes32("0x0");
        data[1] = encodedAddress;
        data[2] = bytes32("0x2");
        data[3] = bytes32("0x3");

        // set merkle root
        Merkle m = new Merkle();
        bytes32 root = m.getRoot(data);
        edition.setMerkleRoot(root);

        // verify proof is valid 
        bytes32[] memory proof = m.getProof(data, 1); 
        bool verifiedProof = m.verifyProof(root, proof, data[1]);
        assertEq(verifiedProof, true);

        // try and mint via presale allowlist
        vm.expectRevert("Address not in allow list");
        edition.presaleMint(proof);
    }




    function testSupportsInterface() public  {
        bool supportsRoyalty = edition.supportsInterface(type(IERC2981).interfaceId); // 0x2a55205a

        bool supportsErc721 = edition.supportsInterface(type(IERC721).interfaceId); // 0x80ac58cd

        bool supportsErc721Metadata = edition.supportsInterface(type(IERC721Metadata).interfaceId); // 0x5b5e139f

        assertEq(supportsRoyalty, true);
        assertEq(supportsErc721, true);
        assertEq(supportsErc721Metadata, true);
    }

}
