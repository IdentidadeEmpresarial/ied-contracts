// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Credential.sol";

contract CredentialTest is Test {
    Credential public credential;

    function setUp() public {
        credential = new Credential();
    }

    function testMint() public {
        assertEq(credential.balanceOf(address(1)), 0, "should have no token");
        credential.safeMint(address(1), "01324", "Certidao Negativa X", "", "QmNrgEMcUygbKzZeZgipFoskd27VE9KnWbyUD73bKZJ3bGi", "awoeifjwoefi");

        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        credential.safeMint(address(1), "01324", "Certidao Negativa X", "", "QmNrgEMcUygbKzZeZgipFoskd27VE9KnWbyUD73bKZJ3bGi", "awoeifjwoefi");

        vm.prank(address(this));
        credential.safeMint(address(1), "01324", "Certidao Negativa X", "", "QmNrgEMcUygbKzZeZgipFoskd27VE9KnWbyUD73bKZJ3bGi", "awoeifjwoefi");
        assertEq(credential.balanceOf(address(1)), 2, "should have minted only 2 NFTs");
    }

    function testTransfers() public {

        credential.safeMint(address(1), "01324", "Certidao Negativa X", "", "QmNrgEMcUygbKzZeZgipFoskd27VE9KnWbyUD73bKZJ3bGi", "awoeifjwoefi");

        vm.expectRevert(bytes("ERC721: caller is not token owner nor approved"));
        credential.transferFrom(address(this), address(1), 0);
        
        vm.prank(address(1));
        vm.expectRevert(bytes("0: not allowed to transfer"));
        credential.safeTransferFrom(address(1), address(2), 0);
    }

    function testBurn() public {

        credential.safeMint(address(1), "01324", "Certidao Negativa X", "", "QmNrgEMcUygbKzZeZgipFoskd27VE9KnWbyUD73bKZJ3bGi", "awoeifjwoefi");
        credential.safeMint(address(1), "01324", "Certidao Negativa X", "", "QmNrgEMcUygbKzZeZgipFoskd27VE9KnWbyUD73bKZJ3bGi", "awoeifjwoefi");
        assertEq(credential.balanceOf(address(1)), 2, "should mint two tokens");


        vm.prank(address(2));
        vm.expectRevert(bytes( "caller must own token or this contract"));
        credential.burn(0);
        assertEq(credential.balanceOf(address(1)), 2, "random user should not have burned any token");

        vm.prank(address(1));
        credential.burn(1);
        assertEq(credential.balanceOf(address(1)), 1, "token's owner should have burned one token");

        credential.burn(0);
        assertEq(credential.balanceOf(address(this)), 0, "contract's owner should have burned one token");

    }

    function testGetAllTokensByOwner() public {
        assertEq(credential.getAllTokensByOwner(address(1)).length, 0, "should not have nay token");
        credential.safeMint(address(1), "01324", "Certidao Negativa X", "", "QmNrgEMcUygbKzZeZgipFoskd27VE9KnWbyUD73bKZJ3bGi", "awoeifjwoefi");
        credential.safeMint(address(1), "01324", "Certidao Negativa X", "", "QmNrgEMcUygbKzZeZgipFoskd27VE9KnWbyUD73bKZJ3bGi", "awoeifjwoefi");
        assertEq(credential.getAllTokensByOwner(address(1)).length, 2, "should have 2 tokens");
        assertEq(credential.getAllTokensByOwner(address(1))[0], 0, "should own first minted token with id 0");

        credential.safeMint(address(2), "01324", "Certidao Negativa X", "", "QmNrgEMcUygbKzZeZgipFoskd27VE9KnWbyUD73bKZJ3bGi", "awoeifjwoefi");
        assertEq(credential.getAllTokensByOwner(address(2)).length, 1);

        credential.burn(0);
        assertEq(credential.getAllTokensByOwner(address(1)).length, 1);
        assertEq(credential.getAllTokensByOwner(address(1))[0], 1);

        credential.burn(2);
        assertEq(credential.getAllTokensByOwner(address(2)).length, 0);
    }

}
