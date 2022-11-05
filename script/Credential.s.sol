// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/Credential.sol";

contract CredentialScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("CDID_PRIVATE_KEY"));

        vm.startBroadcast(deployerPrivateKey);

        Credential credential = new Credential();
        credential.addIssuer(vm.envAddress("SAMPLE_ISSUER_ADDRESS"));

        vm.stopBroadcast();
    }
}
