// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {Brick} from "../src/Brick.sol";

contract BrickTest is Test {
    Brick public brick;
    address public treasury = address(0xBEEF);
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);
    address public advertiser = address(0xAD);

    uint256 constant PRICE = 0.0005 ether;

    function setUp() public {
        brick = new Brick(treasury, PRICE);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(advertiser, 10 ether);
        vm.deal(treasury, 1 ether);
    }

    // ───────────── Corner reserve ─────────────

    function test_CornerReserve_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        brick.mintCornerReserves();
    }

    function test_CornerReserve_Mints400ToTreasury() public {
        vm.prank(treasury);
        brick.mintCornerReserves();
        assertEq(brick.balanceOf(treasury), 400);
        // Spot-check 4 corner cells (1-indexed)
        // Top-left (0,0) → id 1
        assertEq(brick.ownerOf(1), treasury);
        // Top-right (124,0) → id 125
        assertEq(brick.ownerOf(125), treasury);
        // Bottom-left (0,79) → id 79*125+1 = 9876
        assertEq(brick.ownerOf(79 * 125 + 1), treasury);
        // Bottom-right (124,79) → id 80*125 = 10000
        assertEq(brick.ownerOf(10000), treasury);
    }

    function test_CornerReserve_NotMintable_Twice() public {
        vm.startPrank(treasury);
        brick.mintCornerReserves();
        vm.expectRevert(Brick.CornerAlreadyMinted.selector);
        brick.mintCornerReserves();
        vm.stopPrank();
    }

    // ───────────── Free phase ─────────────

    function test_FreeMint_Single() public {
        vm.prank(alice, alice); // tx.origin = alice
        brick.mintFree();
        assertEq(brick.balanceOf(alice), 1);
        assertEq(brick.freePhaseMinted(), 1);
        assertTrue(brick.claimedFree(alice));
    }

    function test_FreeMint_OnePerWallet() public {
        vm.startPrank(alice, alice);
        brick.mintFree();
        vm.expectRevert(Brick.AlreadyClaimedFree.selector);
        brick.mintFree();
        vm.stopPrank();
    }

    function test_FreeMint_RevertWhen_LowBalance() public {
        address poor = address(0xDEADBEEF);
        vm.deal(poor, 0.001 ether); // below FREE_MIN_BALANCE
        vm.prank(poor, poor);
        vm.expectRevert(Brick.WalletQualityFail.selector);
        brick.mintFree();
    }

    function test_FreeMint_RevertWhen_Contract() public {
        // tx.origin != msg.sender path is harder to trigger via vm.prank.
        // Simpler: use a contract caller (code.length != 0)
        ContractCaller caller = new ContractCaller(address(brick));
        vm.deal(address(caller), 1 ether);
        vm.expectRevert(Brick.WalletQualityFail.selector);
        caller.callMintFree();
    }

    // ───────────── Paid phase ─────────────

    function test_PaidMint_RevertsBeforeFreeSoldOut() public {
        vm.prank(alice, alice);
        vm.expectRevert(Brick.FreePhaseSoldOut.selector);
        brick.mint{value: PRICE}(1);
    }

    function test_PaidMint_AfterFreePhase() public {
        _fillFreePhase();
        vm.prank(alice, alice);
        brick.mint{value: PRICE}(1);
        assertEq(brick.balanceOf(alice), 1);
        assertEq(brick.paidMintedBy(alice), 1);
    }

    function test_PaidMint_WalletCap() public {
        _fillFreePhase();
        vm.prank(alice, alice);
        brick.mint{value: PRICE * 100}(100);
        vm.prank(alice, alice);
        vm.expectRevert(Brick.WalletCapExceeded.selector);
        brick.mint{value: PRICE}(1);
    }

    function test_PaidMint_InsufficientETH() public {
        _fillFreePhase();
        vm.prank(alice, alice);
        vm.expectRevert(Brick.InsufficientETH.selector);
        brick.mint{value: PRICE - 1}(1);
    }

    // ───────────── Banner cluster ─────────────

    function test_ClusterMint_30Bricks() public {
        _fillFreePhase();
        // After ~10% wall density from free phase, scan for an available 10×3 spot.
        (uint256 sx, uint256 sy, bool found) = _findAvailableCluster();
        assertTrue(found, "no available cluster after free phase");

        uint256 aliceBefore = brick.balanceOf(alice);
        vm.prank(alice, alice);
        brick.mintBannerCluster{value: PRICE * 30}(sx, sy);
        assertEq(brick.balanceOf(alice) - aliceBefore, 30);
        // Spot-check a couple cells in the cluster
        assertEq(brick.ownerOf(sy * 125 + sx + 1), alice);
        assertEq(brick.ownerOf((sy + 2) * 125 + (sx + 9) + 1), alice);
    }

    function test_ClusterMint_RevertOnCornerOverlap() public {
        _fillFreePhase();
        vm.prank(alice, alice);
        vm.expectRevert(Brick.ClusterOverlapsCorner.selector);
        brick.mintBannerCluster{value: PRICE * 30}(0, 0); // top-left corner
    }

    function test_ClusterMint_RevertOnOOB() public {
        _fillFreePhase();
        vm.prank(alice, alice);
        vm.expectRevert(Brick.ClusterOutOfBounds.selector);
        brick.mintBannerCluster{value: PRICE * 30}(120, 40); // 120+10 > 125
    }

    // ───────────── Content + rentals ─────────────

    function test_UpdateContent_OwnerOnly() public {
        _fillFreePhase();
        vm.prank(alice, alice);
        brick.mint{value: PRICE}(1);
        uint256 id = _firstOwnedId(alice);

        vm.prank(bob);
        vm.expectRevert(Brick.NotOwner.selector);
        brick.updateContent(id, "ipfs://foo");

        vm.prank(alice);
        brick.updateContent(id, "ipfs://foo");
        assertEq(brick.tokenURI(id), "ipfs://foo");
    }

    function test_Rental_FullFlow() public {
        _fillFreePhase();
        vm.prank(alice, alice);
        brick.mint{value: PRICE}(1);
        uint256 id = _firstOwnedId(alice);

        // Alice lists at 0.01 ETH/month, min 2 months
        vm.prank(alice);
        brick.listForRent(id, 0.01 ether, 2);

        // Advertiser rents for 3 months
        uint256 cost = 0.03 ether;
        vm.prank(advertiser);
        brick.rent{value: cost}(id, 3, "ipfs://ad-banner");

        // tokenURI now serves the ad
        assertEq(brick.tokenURI(id), "ipfs://ad-banner");

        // Splits: 10% to treasury (=0.003), 90% to alice (=0.027)
        assertEq(brick.pendingRentalEarnings(treasury), 0.003 ether);
        assertEq(brick.pendingRentalEarnings(alice), 0.027 ether);

        // Owner can't update content mid-rental
        vm.prank(alice);
        vm.expectRevert(Brick.RentalActive.selector);
        brick.updateContent(id, "ipfs://own-content");

        // Can't end rental before expiry
        vm.expectRevert(Brick.RentalNotExpired.selector);
        brick.endRental(id);

        // Skip 91 days
        vm.warp(block.timestamp + 91 days);
        brick.endRental(id);

        // tokenURI reverts to owner's (empty) content
        assertEq(brick.tokenURI(id), "");

        // Alice withdraws her share
        uint256 before = alice.balance;
        vm.prank(alice);
        brick.withdrawRentalEarnings();
        assertEq(alice.balance - before, 0.027 ether);
    }

    function test_Rental_TreasuryBpsCap() public {
        vm.prank(treasury);
        vm.expectRevert(Brick.BpsTooHigh.selector);
        brick.setTreasuryRentBps(2001); // > 20%

        vm.prank(treasury);
        brick.setTreasuryRentBps(2000); // exactly 20%
        assertEq(brick.treasuryRentBps(), 2000);
    }

    // ───────────── Website reveal ─────────────

    function test_Website_HiddenUntilFreePhaseOut() public {
        vm.prank(treasury);
        brick.setWebsiteURL("https://basewall.fun");

        vm.expectRevert(Brick.WebsiteNotRevealed.selector);
        brick.websiteURL();

        _fillFreePhase();
        assertTrue(brick.websiteRevealed());
        assertEq(brick.websiteURL(), "https://basewall.fun");
    }

    function test_Website_SetAfterFreeOutAlsoReveals() public {
        _fillFreePhase();
        assertFalse(brick.websiteRevealed()); // URL wasn't set yet

        vm.prank(treasury);
        brick.setWebsiteURL("https://basewall.fun");
        assertTrue(brick.websiteRevealed());
        assertEq(brick.websiteURL(), "https://basewall.fun");
    }

    // ───────────── Treasury withdraw isolation (regression for rental escrow bug) ─────────────

    function test_Withdraw_OnlyPullsMintRevenue_NotRentalEscrow() public {
        _fillFreePhase();

        // Alice + Bob each mint a paid brick → 2 × 0.0005 = 0.001 ETH of mint revenue
        vm.prank(alice, alice);
        brick.mint{value: PRICE}(1);
        vm.prank(bob, bob);
        brick.mint{value: PRICE}(1);

        assertEq(brick.mintRevenue(), 2 * PRICE);
        uint256 contractBalBeforeRent = address(brick).balance;

        // Alice lists her brick, advertiser rents 2 months @ 0.05 ETH/mo = 0.1 ETH
        uint256 aliceId = _firstOwnedId(alice);
        vm.prank(alice);
        brick.listForRent(aliceId, 0.05 ether, 2);
        vm.prank(advertiser);
        brick.rent{value: 0.1 ether}(aliceId, 2, "ipfs://ad");

        // Of 0.1 ETH rent: 0.01 → treasury escrow, 0.09 → alice escrow
        assertEq(brick.pendingRentalEarnings(treasury), 0.01 ether);
        assertEq(brick.pendingRentalEarnings(alice), 0.09 ether);
        assertEq(address(brick).balance, contractBalBeforeRent + 0.1 ether);

        // Treasury can ONLY withdraw the 0.001 ETH mint revenue. Rental escrow stays locked.
        uint256 treasuryBefore = treasury.balance;
        vm.prank(treasury);
        brick.withdraw(payable(treasury));
        assertEq(treasury.balance - treasuryBefore, 2 * PRICE, "withdraw pulled wrong amount");
        assertEq(brick.mintRevenue(), 0, "mintRevenue not reset");
        // Contract still holds the entire 0.1 ETH of rental escrow
        assertEq(address(brick).balance, 0.1 ether, "rental escrow leaked");

        // Alice claims her 0.09 ETH share via the rental-earnings path
        uint256 aliceBefore = alice.balance;
        vm.prank(alice);
        brick.withdrawRentalEarnings();
        assertEq(alice.balance - aliceBefore, 0.09 ether);

        // Treasury claims its 0.01 ETH rental cut via the SAME path (not withdraw())
        uint256 treasuryBefore2 = treasury.balance;
        vm.prank(treasury);
        brick.withdrawRentalEarnings();
        assertEq(treasury.balance - treasuryBefore2, 0.01 ether);

        // Contract drained, no stuck funds
        assertEq(address(brick).balance, 0);
    }

    function test_Withdraw_RevertsWhenNoRevenue() public {
        vm.prank(treasury);
        vm.expectRevert(Brick.InsufficientETH.selector);
        brick.withdraw(payable(treasury));
    }

    // ───────────── Royalty ─────────────

    function test_Royalty_5PercentToTreasury() public {
        (address receiver, uint256 amount) = brick.royaltyInfo(1, 1 ether);
        assertEq(receiver, treasury);
        assertEq(amount, 0.05 ether); // 5%
    }

    // ───────────── Coordinates / corners ─────────────

    function test_Coordinates() public view {
        (uint256 x, uint256 y) = brick.coordinates(1);
        assertEq(x, 0); assertEq(y, 0);
        (x, y) = brick.coordinates(125);
        assertEq(x, 124); assertEq(y, 0);
        (x, y) = brick.coordinates(126);
        assertEq(x, 0); assertEq(y, 1);
        (x, y) = brick.coordinates(10000);
        assertEq(x, 124); assertEq(y, 79);
    }

    function test_IsCornerReserved() public view {
        assertTrue(brick.isCornerReserved(0, 0));
        assertTrue(brick.isCornerReserved(9, 9));
        assertFalse(brick.isCornerReserved(10, 9));
        assertTrue(brick.isCornerReserved(115, 0));
        assertTrue(brick.isCornerReserved(0, 70));
        assertTrue(brick.isCornerReserved(124, 79));
        assertFalse(brick.isCornerReserved(62, 40)); // ex-center is now public
    }

    // ───────────── helpers ─────────────

    /// @dev Drain the 1,000 free-phase mints across many fresh wallets.
    function _fillFreePhase() internal {
        for (uint256 i = 0; i < 1_000; i++) {
            address w = address(uint160(uint256(keccak256(abi.encodePacked("w", i)))));
            vm.deal(w, 1 ether);
            vm.prank(w, w);
            brick.mintFree();
        }
    }

    /// @dev Scan the grid (excluding corners) for the first available 10×3 cluster.
    function _findAvailableCluster() internal view returns (uint256 sx, uint256 sy, bool found) {
        // Search in middle rows (10..69) to skip top/bot corner overlap entirely
        for (uint256 y = 10; y + 3 <= 70; y++) {
            for (uint256 x = 10; x + 10 <= 115; x++) {
                bool ok = true;
                for (uint256 dy = 0; dy < 3 && ok; dy++) {
                    for (uint256 dx = 0; dx < 10 && ok; dx++) {
                        uint256 id = (y + dy) * 125 + (x + dx) + 1;
                        try brick.ownerOf(id) { ok = false; } catch {}
                    }
                }
                if (ok) return (x, y, true);
            }
        }
        return (0, 0, false);
    }

    function _firstOwnedId(address who) internal view returns (uint256) {
        // Cheap scan; tests own small numbers of bricks
        for (uint256 id = 1; id <= 10000; id++) {
            if (brick.balanceOf(who) == 0) return 0;
            try brick.ownerOf(id) returns (address o) {
                if (o == who) return id;
            } catch {}
        }
        return 0;
    }
}

contract ContractCaller {
    Brick public brick;
    constructor(address _brick) { brick = Brick(payable(_brick)); }
    function callMintFree() external { brick.mintFree(); }
}
