// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Edition.sol";

// deploy to goerli
// forge script script/NFT.s.sol:MyScript --rpc-url $GOERLI_RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv

// deploy to local
// forge script script/Edition.s.sol:EditionScript --fork-url http://localhost:8545 \ --private-key 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6 --broadcast

contract EditionScript is Script {
    function run() external {
        vm.startBroadcast();

        Edition edition = new Edition("FOUNDRY", "SCRIPTING");

        vm.stopBroadcast();
    }
}