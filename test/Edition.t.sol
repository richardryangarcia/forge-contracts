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
    // 0x5dad7600c5d89fe3824ffa99ec1c3eb8bf3b0501 alice
    // 0x5dad7600C5D89fE3824fFa99ec1c3eB8BF3b0501 checksummed alice
    function mkaddr(string memory name) public returns (address) {
        address addr =
            address(uint160(uint256(keccak256(abi.encodePacked(name)))));
        vm.label(addr, name);
        return addr;
    }
}

// owner address
// 0xb4c79dab8f259c7aee6e5b2aa729821864227e84

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

    // function testSetMerkleRoot() public {
    //     address alice = address(0x5dad7600C5D89fE3824fFa99ec1c3eB8BF3b0501);
    //     address bob = address(0x3440326f551B8A7ee198cEE35cb5D517f2d296a2);
    //     address candice = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    //     Merkle m = new Merkle();
    //     bytes32[] memory data = new bytes32[](3);
    //     data[0] = bytes32(uint256(uint160(alice)));
    //     data[1] = bytes32(uint256(uint160(bob)));
    //     data[2] = bytes32(uint256(uint160(candice)));
    //     bytes32 root = m.getRoot(data);

    //     assertEq(edition.merkleRoot(), root);
    //     // bytes32[] memory proof = m.getProof(data, 2); // will get proof for 0x2 value

    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = bytes32(0x38baca365d4813ff51600e5a271bb8f003e270ec24773ef307257c0e7fb97ccf);
    //     console2.logBytes32(proof[0]);

    //     vm.prank(candice);
    //     edition.presaleMint(proof);
    // }

    function testSupportsInterface() public  {
        bool supportsRoyalty = edition.supportsInterface(type(IERC2981).interfaceId); // 0x2a55205a

        bool supportsErc721 = edition.supportsInterface(type(IERC721).interfaceId); // 0x80ac58cd

        bool supportsErc721Metadata = edition.supportsInterface(type(IERC721Metadata).interfaceId); // 0x5b5e139f

        assertEq(supportsRoyalty, true);
        assertEq(supportsErc721, true);
        assertEq(supportsErc721Metadata, true);
    }

}
