// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Edition.sol";
import "../src/Escrow.sol";

// source .env

// deploy to goerli
// forge script script/Edition.s.sol:EditionScript --rpc-url $GOERLI_RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv

// deploy to local
// forge script script/Edition.s.sol:EditionScript --fork-url http://localhost:8545 \ --private-key 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6 --broadcast

contract EditionScript is Script {
    function run() external {
        vm.startBroadcast();

        new Bet("Nate Diaz", "https://dmxg5wxfqgb4u.cloudfront.net/styles/background_image_xl/s3/2019-10/nate-diaz-hero.jpg?gnoID3v6MGXg6eXxtrxpUtl9G5ZYiSwX&itok=xTG6B7fW", "Tony Furgeson", "https://imgs.search.brave.com/ihbhFZxU60AZig7AsJBhq0B-5_cPxX4TeEQao9hbeFA/rs:fit:1200:1200:1/g:ce/aHR0cHM6Ly93d3cu/bG93a2lja21tYS5j/b20vd3AtY29udGVu/dC91cGxvYWRzLzIw/MjAvMDkvTklOVENI/REJQSUNUMDAwNTgx/NzExNTczLXNjYWxl/ZC5qcGc");

        vm.stopBroadcast();
    }
}