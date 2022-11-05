// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Credential.sol";
import "forge-std/console2.sol";

contract Verifier {

    function verifyCredential (
        uint256 credentialId,
        uint256 expires,
        bytes calldata credential,
        Credential credentialContract
    ) public {

        require(
            credentialContract.ownerOf(credentialId) == msg.sender,
            "Caller must be the credential holder"
        );

        require(block.timestamp < expires, "Credential is expired");

        (address issuer,
        string memory subjectId,
        string memory credentialType,
        string memory encryptedData,
        bytes32 dataHash,
        string memory dataKey) = credentialContract.attributes(credentialId);

        bytes memory data = bytes(
            string.concat(
                Strings.toString(expires),
                ";",
                string(credential)
            )
        );

        bytes32 computedHash = ECDSA.toEthSignedMessageHash(data);
        require(computedHash == dataHash, "Credential or expire date doesn't match");
    }
}
