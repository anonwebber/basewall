// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {Brick} from "../src/Brick.sol";

contract BrickTest is Test {
    Brick public brick;
    address public treasury = address(0xBEEF);
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        brick = new Brick(treasury);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function test_PublicMint_Single() public {
        vm.prank(alice);
        brick.mint{value: 0.001 ether}(1);
        assertEq(brick.ownerOf(1), alice);
        assertEq(brick.publicMintCount(), 1);
    }

    function test_PublicMint_Batch() public {
        vm.prank(alice);
        brick.mint{value: 0.1 ether}(100);
        assertEq(brick.publicMintedBy(alice), 100);
        assertEq(brick.balanceOf(alice), 100);
    }

    function test_RevertWhen_WalletCapExceeded() public {
        vm.prank(alice);
        vm.expectRevert(Brick.WalletCapExceeded.selector);
        brick.mint{value: 0.101 ether}(101);
    }

    function test_RevertWhen_InsufficientETH() public {
        vm.prank(alice);
        vm.expectRevert(Brick.InsufficientETH.selector);
        brick.mint{value: 0.0001 ether}(1);
    }

    function test_DevReserve_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        brick.mintDevReserve();
    }

    function test_DevReserve_MintsAll500() public {
        vm.prank(treasury);
        brick.mintDevReserve();
        assertEq(brick.balanceOf(treasury), 500);
        assertEq(brick.ownerOf(9501), treasury);
        assertEq(brick.ownerOf(10000), treasury);
    }

    function test_UpdateContent_OnlyOwner() public {
        vm.prank(alice);
        brick.mint{value: 0.001 ether}(1);

        vm.prank(bob);
        vm.expectRevert(Brick.NotOwner.selector);
        brick.updateContent(1, "ipfs://test");

        vm.prank(alice);
        brick.updateContent(1, "ipfs://test");
        assertEq(brick.contentURI(1), "ipfs://test");
    }

    function test_Coordinates() public view {
        (uint256 x, uint256 y) = brick.coordinates(1);
        assertEq(x, 0);
        assertEq(y, 0);

        (x, y) = brick.coordinates(100);
        assertEq(x, 99);
        assertEq(y, 0);

        (x, y) = brick.coordinates(101);
        assertEq(x, 0);
        assertEq(y, 1);

        (x, y) = brick.coordinates(10000);
        assertEq(x, 99);
        assertEq(y, 99);
    }
}
