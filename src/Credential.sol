// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console.sol";

contract Credential is ERC721, Ownable {
    using Counters for Counters.Counter;

    struct Attr {
        address issuer;
        string subjectId;
        string credentialType;
        string data;
        bytes32 dataHash;
        string dataKey;
    }

    mapping(uint256 => Attr) public attributes;

    mapping(address => uint256[]) public tokensByAddress;

    Counters.Counter private _tokenIdCounter;

    address[] public issuers;

    event Issued(address indexed issuer, address indexed _to, bytes32 indexed _dataHash, uint _tokenId);

    modifier onlyOwnerOrIssuer {
        console.log("checking owner");
        if(msg.sender != owner()) {
            bool allowedIssuer = false;
            for (uint i = 0; i < issuers.length; i++){
                if(issuers[i] == msg.sender) {
                    allowedIssuer = true;
                    break;
                }
            }
            require(allowedIssuer, "only owner or allowed issuer should mint token");
        }
        _;
    }

    modifier checkHolderSignature(address holder, bytes32 dataHash, bytes memory holderSignature) {
        console.log("checking signature");
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(dataHash, holderSignature);
        require(error == ECDSA.RecoverError.NoError && recovered == holder, "invalid holder signature");
        console.log("checked signature");
        _;
    }

    constructor() ERC721("Credential", "CRD") {}

    function safeMint(
        address to,
        string memory _subjectId,
        string memory _credentialType,
        string memory _data,
        bytes32 _dataHash,
        bytes memory _holderSignature,
        string memory _dataKey
    ) public onlyOwnerOrIssuer checkHolderSignature(to, _dataHash, _holderSignature) {
        console.log("stared minting");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        attributes[tokenId] = Attr(msg.sender, _subjectId, _credentialType, _data, _dataHash, _dataKey);
        tokensByAddress[to].push(tokenId);
        console.log("minted");
        emit Issued(msg.sender, to, _dataHash, tokenId);
    }

    /**
     *  Only transfers from 0x0 and to 0x0 (mint and burn) ar allowed. All other transfers are blocked.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(from == address(0x0) || to == address(0x0), "Credential is not transferable");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or this contract.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        address tokenOwner = ownerOf(tokenId);
        require(
            _msgSender() == tokenOwner || _msgSender() == owner(),
            "caller must own token or this contract"
        );
        delete attributes[tokenId];
        _burn(tokenId);

        uint256[] storage ownedTokens = tokensByAddress[tokenOwner];

        for (uint i = 0; i < ownedTokens.length; i++){
            if(ownedTokens[i] == tokenId) {
                ownedTokens[i] = ownedTokens[ownedTokens.length - 1];
                ownedTokens.pop();
                break;
            }
        }

    }

    /**
     * @dev Lists credentials Ids by owner and type
     */
    function getAllTokensByOwner(address owner) public view virtual returns (uint256[] memory) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return tokensByAddress[owner];
    }

    /**
     * add allowed issuer to mint token
     */
    function addIssuer(address issuer) public onlyOwner virtual {
        for (uint i = 0; i < issuers.length; i++){
            if(issuers[i] == issuer) {
                return;
            }
        }
        issuers.push(issuer);
    }

    /**
     * revoke allowed issuer to mint token
     */
    function removeIssuer(address issuer) public onlyOwner virtual {
        for (uint i = 0; i < issuers.length; i++){
            if(issuers[i] == issuer) {
                issuers[i] = issuers[issuers.length - 1];
                issuers.pop();
                break;
            }
        }
    }
}
