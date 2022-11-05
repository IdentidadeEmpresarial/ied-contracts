pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Credential.sol";
import "../src/Verifier.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VerifierTest is Test {
    Credential public credential;
    Verifier public verifier;

    string subjectId = "0132456";
    string credentialType = "Certidao Negativa X";
    string key = "";

    function getSignature(uint256 addr, bytes32 dataHash) public returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(addr, dataHash);
        return abi.encodePacked(r, s, v);
    }

    function setUp() public {
        credential = new Credential();
        verifier = new Verifier();
    }

    function testVerify() public {
        uint256 expires = 1699143646;
        bytes memory credentialData = "CONSTA_DEBITO";
        bytes memory data = bytes(
            string.concat(
                Strings.toString(expires),
                ";",
                string(credentialData)
            )
        );
        bytes32 dataHash = ECDSA.toEthSignedMessageHash(data);

        bytes memory signature = getSignature(0x1, dataHash);

        credential.safeMint(vm.addr(0x1), subjectId, credentialType, "", dataHash, signature, key);

        vm.warp(expires);
        vm.prank(vm.addr(0x1));
        vm.expectRevert(bytes("Credential is expired"));
        verifier.verifyCredential(0, expires, credentialData, credential);

        vm.warp(expires - 1);
        vm.prank(vm.addr(0x2));
        vm.expectRevert(bytes("Caller must be the credential holder"));
        verifier.verifyCredential(0, expires, credentialData, credential);

        vm.warp(expires - 1);
        vm.prank(vm.addr(0x1));
        vm.expectRevert(bytes("Credential or expire date doesn't match"));
        verifier.verifyCredential(0, expires, "NAO_CONSTA_DEBITO", credential);

        vm.warp(expires);
        vm.prank(vm.addr(0x1));
        vm.expectRevert(bytes("Credential or expire date doesn't match"));
        verifier.verifyCredential(0, expires + 100, credentialData, credential);

        vm.warp(expires - 1);
        vm.prank(vm.addr(0x1));
        verifier.verifyCredential(0, expires, credentialData, credential);

    }
}
