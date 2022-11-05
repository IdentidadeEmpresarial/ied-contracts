// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/Credential.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CredentialTest is Test {
    Credential public credential;

    string subjectId = "0132456";
    string credentialType = "Certidao Negativa X";
    bytes data = "credential data";
    bytes32 dataHash;
    string key = "";
    address address1 = vm.addr(0x1);
    address address2 = vm.addr(0x2);
    address address3 = vm.addr(0x3);
    bytes address1Signature;
    bytes address2Signature;
    bytes address3Signature;

    function fromVRS( uint8 v, bytes32 r, bytes32 s) internal pure returns (bytes memory) {
        return abi.encodePacked(r, s, v);
    }

    function setUp() public {
        credential = new Credential();
        dataHash = ECDSA.toEthSignedMessageHash( data);
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(0x1, dataHash);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(0x2, dataHash);
        (uint8 v3, bytes32 r3, bytes32 s3) = vm.sign(0x3, dataHash);
        address1Signature = fromVRS(v1, r1, s1);
        address2Signature = fromVRS(v2, r2, s2);
        address3Signature = fromVRS(v3, r3, s3);
    }

    function testMint() public {
        assertEq(credential.balanceOf(address1), 0, "should have no token");
        credential.safeMint( address1, subjectId, credentialType, "", dataHash, address1Signature, key);

        vm.prank(address1);
        vm.expectRevert("only owner or allowed issuer should mint token");
        credential.safeMint( address1, subjectId, credentialType, "", dataHash, address1Signature, key);
        vm.prank(address(this));
        credential.safeMint( address1, subjectId, credentialType, "", dataHash, address1Signature, key);
        assertEq( credential.balanceOf(address1), 2, "should have minted only 2 NFTs");
    }

    function testTransfers() public {
        credential.safeMint( address1, subjectId, credentialType, "", dataHash, address1Signature, key);

        vm.expectRevert( bytes("ERC721: caller is not token owner nor approved"));
        credential.transferFrom(address(this), address1, 0);

        vm.prank(address1);
        vm.expectRevert(bytes("Credential is not transferable"));
        credential.safeTransferFrom(address1, address2, 0);
    }

    function testBurn() public {
        credential.safeMint( address1, subjectId, credentialType, "", dataHash, address1Signature, key);
        credential.safeMint( address1, subjectId, credentialType, "", dataHash, address1Signature, key);
        assertEq(credential.balanceOf(address1), 2, "should mint two tokens");

        vm.prank(address2);
        vm.expectRevert(bytes("caller must own token or this contract"));
        credential.burn(0);
        assertEq( credential.balanceOf(address1), 2, "random user should not have burned any token");

        vm.prank(address1);
        credential.burn(1);
        assertEq( credential.balanceOf(address1), 1, "token's owner should have burned one token");

        credential.burn(0);
        assertEq( credential.balanceOf(address(this)), 0, "contract's owner should have burned one token");
    }

    function testGetAllTokensByOwner() public {
        assertEq( credential.getAllTokensByOwner(address1).length, 0, "should not have any token");
        credential.safeMint( address1, subjectId, credentialType, "", dataHash, address1Signature, key);
        credential.safeMint( address1, subjectId, credentialType, "", dataHash, address1Signature, key);
        assertEq( credential.getAllTokensByOwner(address1).length, 2, "should have 2 tokens");
        assertEq( credential.getAllTokensByOwner(address1)[0], 0, "should own first minted token with id 0");

        credential.safeMint( address2, subjectId, credentialType, "", dataHash, address2Signature, key);
        assertEq(credential.getAllTokensByOwner(address2).length, 1);

        credential.burn(0);
        assertEq(credential.getAllTokensByOwner(address1).length, 1);
        assertEq(credential.getAllTokensByOwner(address1)[0], 1);

        credential.burn(2);
        assertEq(credential.getAllTokensByOwner(address2).length, 0);
    }

    function testIssuersAllowList() public {
        credential.addIssuer(address1);
        assertEq( credential.issuers(0), address1, "should have added 1 issuer");

        vm.prank(address1);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        credential.addIssuer(address2);

        vm.prank(address1);
        credential.safeMint( address2, subjectId, credentialType, "", dataHash, address2Signature, key);
        assertEq(credential.getAllTokensByOwner(address2).length, 1);

        vm.prank(address2);
        vm.expectRevert( bytes("only owner or allowed issuer should mint token"));
        credential.safeMint( address3, subjectId, credentialType, "", dataHash, address3Signature, key);
    }

    function testHolderSignature() public {
        vm.expectRevert("invalid holder signature");
        credential.safeMint(address1, subjectId, credentialType, "", dataHash, address2Signature, key);

        bytes32 newDataHash = keccak256("new credential data");
        vm.expectRevert("invalid holder signature");
        credential.safeMint(address1, subjectId, credentialType, "", newDataHash, address1Signature, key);

    }
}
