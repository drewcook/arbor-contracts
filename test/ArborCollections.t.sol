// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployArborCollections} from "../script/DeployArborCollections.s.sol";
import {ArborCollections} from "../src/ArborCollections.sol";

contract ArborCollectionsTest is Test {
    DeployArborCollections deployer;
    ArborCollections collections;

    function setUp() external {
        deployer = new DeployArborCollections();
        collections = deployer.run();
    }

    function test_NameAndSymbol() external {
        string memory actualName = collections.name();
        string memory actualSymbol = collections.symbol();
        string memory expectedSymbol = "ARBOR";
        string memory expectedName = "ArborAudio";
        assertEq(actualName, expectedName);
        assertEq(actualSymbol, expectedSymbol);
    }
}
