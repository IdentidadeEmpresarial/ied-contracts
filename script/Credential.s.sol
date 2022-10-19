// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Credential.sol";

contract CredentialScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("ISSUER_PRIVATE_KEY"));

        vm.startBroadcast(deployerPrivateKey);

        new Credential();

        vm.stopBroadcast();
    }
}
