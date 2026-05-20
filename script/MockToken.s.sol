// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MockToken} from "../src/MockToken.sol";

contract MockTokenScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        console.log("Current Sender:", msg.sender); 

        new MockToken(msg.sender, msg.sender);

        vm.stopBroadcast();
    }
}
