// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "murky/Merkle.sol";
import "../src/Edition.sol";

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

contract ContractTest is BaseTest, HelperContract {
    function setUp() public {
        edition = new Edition("NAME", "SYMBOL");
    }

    function testName() public {
        assertEq(edition.name(), "NAME");
    }

    function testSymbol() public {
        assertEq(edition.symbol(), "SYMBOL");
    }

    function testSetMerkleRoot() public {
        Merkle m = new Merkle();
        bytes32[] memory data = new bytes32[](4);
        data[0] = bytes32("0x0");
        data[1] = bytes32("0x1");
        data[2] = bytes32("0x2");
        data[3] = bytes32("0x3");
        bytes32 root = m.getRoot(data);
        edition.setMerkleRoot(root);
        assertEq(edition.merkleRoot(), root);
    }

    function testPresaleMintInvalidProof() public {
        Merkle m = new Merkle();
        bytes32[] memory data = new bytes32[](4);
        // address alice = mkaddr("alice");
        address alice = address(0x5dad7600C5D89fE3824fFa99ec1c3eB8BF3b0501);
        bytes32 b = bytes32(uint256(uint160(alice)));
        data[0] = bytes32("0x0");
        data[1] = bytes32("0x1");
        data[2] = b;
        data[3] = bytes32("0x3");
        bytes32 root = m.getRoot(data);
        bytes32[] memory proof = m.getProof(data, 2); // will get proof for 0x2 value
        edition.setMerkleRoot(root);

        bool verified = m.verifyProof(root, proof, data[2]); // true!
        // vm.expectRevert("Address not in accepted list");
        vm.prank(alice); //
        // console2.log(proof);
        // console2.log(root);
        // console2.log(alice);
        console2.log("end");
        // edition.presaleMint(proof);
    }
}
