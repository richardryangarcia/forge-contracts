// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/Escrow.sol";
import "forge-std/Test.sol";

abstract contract HelperContract {
    Ufc277 escrow;
}
contract ContractTest is Test, HelperContract {
    function setUp() public {
        escrow = new Ufc277("Amanda Nunez", -275, "Julianna Pena" , 230);
    }

    // function testWithdraw() public {
    //     escrow.withdrawalAllowed();
    // }
}