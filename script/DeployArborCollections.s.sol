// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ArborCollections} from "../src/ArborCollections.sol";

contract DeployArborCollections is Script {
    function run() external returns (ArborCollections collections) {
        vm.startBroadcast();
        collections = new ArborCollections();
        vm.stopBroadcast();
    }
}
