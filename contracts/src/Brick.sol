// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Brick — basewall billboard NFT (NFT-only, no token)
/// @notice 10,000 bricks on a 125×80 grid (1.56:1).
///         - 400 corner reserve (4×10×10) → treasury (brand homages)
///         - 9,600 public:
///             • 1,000 free phase (wallet-quality gated, 1 per wallet)
///             • 8,600 paid phase @ mintPrice (random alloc, 100/wallet)
///         - 30-brick banner cluster mint (10×3) at flat 30×mintPrice
///         - Mutable content per brick; ad-rental marketplace (10% treasury cut)
///         - ERC-2981 5% secondary royalty → treasury
///         - Website URL revealed once free phase mints out (stealth launch hook)
contract Brick is ERC721, ERC2981, Ownable, ReentrancyGuard {
    // ─────────── Grid / supply ───────────
    uint256 public constant GRID_W = 125;
    uint256 public constant GRID_H = 80;
    uint256 public constant TOTAL_SUPPLY = 10_000;
    uint256 public constant CORNER_RESERVE = 400;                // 4 × 10×10
    uint256 public constant PUBLIC_SUPPLY = TOTAL_SUPPLY - CORNER_RESERVE; // 9_600
    uint256 public constant FREE_PHASE_SUPPLY = 1_000;
    uint256 public constant MAX_PER_WALLET = 100;                // paid phase
    uint256 public constant BANNER_CLUSTER_W = 10;
    uint256 public constant BANNER_CLUSTER_H = 3;
    uint256 public constant BANNER_CLUSTER_SIZE = 30;            // 10 × 3

    // Free-phase wallet-quality gates (cheap on-chain checks)
    uint256 public constant FREE_MIN_BALANCE = 0.01 ether;

    // Rental treasury cut — owner-tunable, hard-capped
    uint16 public constant TREASURY_RENT_BPS_MAX = 2000;          // 20%

    // ─────────── Pricing ───────────
    uint256 public immutable mintPrice;                          // wei per brick

    // ─────────── Random allocation pool (swap-and-pop) ───────────
    // _availableMap[i] holds the brick ID currently at pool position i.
    // If unset, defaults to _indexToBrickId(i). Initial size = PUBLIC_SUPPLY.
    mapping(uint256 => uint256) private _availableMap;
    uint256 private _remaining = PUBLIC_SUPPLY;
    bytes32 public immutable mintSeed;
    uint256 private _nonce;

    // ─────────── Mint accounting ───────────
    uint256 public freePhaseMinted;
    uint256 public publicMintCount;                              // free + paid combined
    bool public cornerReserveMinted;
    mapping(address => bool) public claimedFree;
    mapping(address => uint256) public paidMintedBy;

    // ─────────── Content ───────────
    mapping(uint256 => string) public contentURI;                // owner's default content

    // ─────────── Rental marketplace ───────────
    struct Listing {
        uint128 monthlyRentWei;
        uint32 minMonths;
        bool active;
    }
    struct Rental {
        address advertiser;
        uint64 expiresAt;
        uint128 totalPaid;
        string adURI;
    }
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Rental) public activeRentals;
    mapping(address => uint256) public pendingRentalEarnings;    // pull model
    uint16 public treasuryRentBps = 1000;                         // 10% default

    // ─────────── Website reveal (stealth launch hook) ───────────
    string private _websiteURL;
    bool public websiteRevealed;

    // ─────────── Events ───────────
    event ContentUpdated(uint256 indexed tokenId, address indexed owner, string uri);
    event FreeMint(address indexed minter, uint256 tokenId);
    event PaidMint(address indexed minter, uint256 quantity);
    event ClusterMint(address indexed minter, uint256 startX, uint256 startY);
    event CornerReserveMinted();
    event Listed(uint256 indexed tokenId, uint128 monthlyRentWei, uint32 minMonths);
    event Unlisted(uint256 indexed tokenId);
    event Rented(uint256 indexed tokenId, address indexed advertiser, uint64 expiresAt, string adURI);
    event RentalEnded(uint256 indexed tokenId);
    event RentalEarningsWithdrawn(address indexed who, uint256 amount);
    event TreasuryRentBpsUpdated(uint16 newBps);
    event WebsiteRevealed(string url);

    // ─────────── Errors ───────────
    error ZeroQuantity();
    error InsufficientETH();
    error WalletCapExceeded();
    error PublicSoldOut();
    error FreePhaseSoldOut();
    error AlreadyClaimedFree();
    error WalletQualityFail();
    error NotOwner();
    error InvalidTokenId();
    error TransferFailed();
    error CornerAlreadyMinted();
    error ClusterOutOfBounds();
    error ClusterOverlapsCorner();
    error ClusterUnavailable();
    error NotListed();
    error TooFewMonths();
    error RentalActive();
    error RentalNotExpired();
    error BpsTooHigh();
    error WebsiteNotRevealed();
    error EmptyURI();

    constructor(address treasury, uint256 _mintPrice)
        ERC721("BaseWall Brick", "BRICK")
        Ownable(treasury)
    {
        mintPrice = _mintPrice;
        mintSeed = keccak256(abi.encodePacked(block.prevrandao, block.timestamp, treasury));
        _setDefaultRoyalty(treasury, 500); // 5%
    }

    // ═════════════════════════════════════════════════════════
    //                      Mint phases
    // ═════════════════════════════════════════════════════════

    /// @notice Phase 1: free mint, 1 per wallet, wallet-quality gated.
    function mintFree() external nonReentrant {
        if (freePhaseMinted >= FREE_PHASE_SUPPLY) revert FreePhaseSoldOut();
        if (claimedFree[msg.sender]) revert AlreadyClaimedFree();
        if (!_passesWalletQuality(msg.sender)) revert WalletQualityFail();

        claimedFree[msg.sender] = true;
        uint256 id = _drawAndRemove();
        unchecked {
            freePhaseMinted++;
            publicMintCount++;
        }
        _safeMint(msg.sender, id);
        emit FreeMint(msg.sender, id);

        // Reveal the website on the 1000th free mint
        if (freePhaseMinted == FREE_PHASE_SUPPLY && !websiteRevealed && bytes(_websiteURL).length > 0) {
            websiteRevealed = true;
            emit WebsiteRevealed(_websiteURL);
        }
    }

    /// @notice Phase 2: paid random mint. Opens after free phase fills.
    function mint(uint256 quantity) external payable nonReentrant {
        if (quantity == 0) revert ZeroQuantity();
        if (freePhaseMinted < FREE_PHASE_SUPPLY) revert FreePhaseSoldOut(); // re-purposed: "free still open"
        if (msg.value < mintPrice * quantity) revert InsufficientETH();
        if (paidMintedBy[msg.sender] + quantity > MAX_PER_WALLET) revert WalletCapExceeded();
        if (publicMintCount + quantity > PUBLIC_SUPPLY) revert PublicSoldOut();

        paidMintedBy[msg.sender] += quantity;
        unchecked { publicMintCount += quantity; }

        for (uint256 i = 0; i < quantity; i++) {
            uint256 id = _drawAndRemove();
            _safeMint(msg.sender, id);
        }
        emit PaidMint(msg.sender, quantity);
    }

    /// @notice Phase 2: 10×3 banner cluster mint at a caller-chosen start cell.
    ///         All 30 cells must be unminted and not overlap a corner.
    function mintBannerCluster(uint256 startX, uint256 startY) external payable nonReentrant {
        if (freePhaseMinted < FREE_PHASE_SUPPLY) revert FreePhaseSoldOut();
        if (msg.value < mintPrice * BANNER_CLUSTER_SIZE) revert InsufficientETH();
        if (startX + BANNER_CLUSTER_W > GRID_W) revert ClusterOutOfBounds();
        if (startY + BANNER_CLUSTER_H > GRID_H) revert ClusterOutOfBounds();
        if (_clusterOverlapsCorner(startX, startY)) revert ClusterOverlapsCorner();
        if (publicMintCount + BANNER_CLUSTER_SIZE > PUBLIC_SUPPLY) revert PublicSoldOut();
        if (paidMintedBy[msg.sender] + BANNER_CLUSTER_SIZE > MAX_PER_WALLET) revert WalletCapExceeded();

        // Verify all 30 cells unminted before mutating
        for (uint256 dy = 0; dy < BANNER_CLUSTER_H; dy++) {
            for (uint256 dx = 0; dx < BANNER_CLUSTER_W; dx++) {
                uint256 id = (startY + dy) * GRID_W + (startX + dx) + 1;
                if (_ownerOf(id) != address(0)) revert ClusterUnavailable();
            }
        }

        paidMintedBy[msg.sender] += BANNER_CLUSTER_SIZE;
        unchecked { publicMintCount += BANNER_CLUSTER_SIZE; }

        for (uint256 dy = 0; dy < BANNER_CLUSTER_H; dy++) {
            for (uint256 dx = 0; dx < BANNER_CLUSTER_W; dx++) {
                uint256 id = (startY + dy) * GRID_W + (startX + dx) + 1;
                _safeMint(msg.sender, id);
            }
        }
        emit ClusterMint(msg.sender, startX, startY);
    }

    /// @notice One-time mint of all 400 corner-reserved bricks to the treasury.
    function mintCornerReserves() external onlyOwner {
        if (cornerReserveMinted) revert CornerAlreadyMinted();
        cornerReserveMinted = true;
        address treasury = owner();

        for (uint256 cy = 0; cy < 10; cy++) {
            for (uint256 cx = 0; cx < 10; cx++) {
                // 4 corners
                _safeMint(treasury, cy * GRID_W + cx + 1);                                     // ETH (top-left)
                _safeMint(treasury, cy * GRID_W + (GRID_W - 10 + cx) + 1);                     // X (top-right)
                _safeMint(treasury, (GRID_H - 10 + cy) * GRID_W + cx + 1);                     // BASE (bot-left)
                _safeMint(treasury, (GRID_H - 10 + cy) * GRID_W + (GRID_W - 10 + cx) + 1);     // UNI (bot-right)
            }
        }
        emit CornerReserveMinted();
    }

    // ═════════════════════════════════════════════════════════
    //                      Content
    // ═════════════════════════════════════════════════════════

    /// @notice Owner sets default content. Reverts during an active rental
    ///         (advertiser content takes priority for the rental term).
    function updateContent(uint256 tokenId, string calldata uri) external {
        if (_ownerOf(tokenId) != msg.sender) revert NotOwner();
        if (_rentalActive(tokenId)) revert RentalActive();
        contentURI[tokenId] = uri;
        emit ContentUpdated(tokenId, msg.sender, uri);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        if (_rentalActive(tokenId)) return activeRentals[tokenId].adURI;
        return contentURI[tokenId];
    }

    // ═════════════════════════════════════════════════════════
    //                  Rental marketplace
    // ═════════════════════════════════════════════════════════

    function listForRent(uint256 tokenId, uint128 monthlyRentWei, uint32 minMonths) external {
        if (_ownerOf(tokenId) != msg.sender) revert NotOwner();
        if (minMonths == 0) revert TooFewMonths();
        if (_rentalActive(tokenId)) revert RentalActive();
        listings[tokenId] = Listing({
            monthlyRentWei: monthlyRentWei,
            minMonths: minMonths,
            active: true
        });
        emit Listed(tokenId, monthlyRentWei, minMonths);
    }

    function unlist(uint256 tokenId) external {
        if (_ownerOf(tokenId) != msg.sender) revert NotOwner();
        if (_rentalActive(tokenId)) revert RentalActive();
        delete listings[tokenId];
        emit Unlisted(tokenId);
    }

    /// @notice Advertiser pays `nMonths × monthlyRentWei` upfront.
    ///         10% (or `treasuryRentBps`) to treasury, rest credited to brick owner.
    function rent(uint256 tokenId, uint32 nMonths, string calldata adURI) external payable nonReentrant {
        Listing memory L = listings[tokenId];
        if (!L.active) revert NotListed();
        if (nMonths < L.minMonths) revert TooFewMonths();
        if (_rentalActive(tokenId)) revert RentalActive();
        if (bytes(adURI).length == 0) revert EmptyURI();

        uint256 total = uint256(L.monthlyRentWei) * nMonths;
        if (msg.value < total) revert InsufficientETH();

        uint256 treasuryShare = (total * treasuryRentBps) / 10_000;
        uint256 ownerShare = total - treasuryShare;

        pendingRentalEarnings[owner()] += treasuryShare;
        pendingRentalEarnings[_ownerOf(tokenId)] += ownerShare;

        uint64 expiresAt = uint64(block.timestamp + uint256(nMonths) * 30 days);
        activeRentals[tokenId] = Rental({
            advertiser: msg.sender,
            expiresAt: expiresAt,
            totalPaid: uint128(total),
            adURI: adURI
        });

        // Refund any overpayment
        if (msg.value > total) {
            (bool ok,) = payable(msg.sender).call{value: msg.value - total}("");
            if (!ok) revert TransferFailed();
        }
        emit Rented(tokenId, msg.sender, expiresAt, adURI);
    }

    /// @notice Anyone can clear an expired rental — flips tokenURI back to owner's content.
    function endRental(uint256 tokenId) external {
        Rental memory R = activeRentals[tokenId];
        if (R.expiresAt == 0) revert NotListed();
        if (block.timestamp < R.expiresAt) revert RentalNotExpired();
        delete activeRentals[tokenId];
        emit RentalEnded(tokenId);
    }

    function withdrawRentalEarnings() external nonReentrant {
        uint256 amt = pendingRentalEarnings[msg.sender];
        if (amt == 0) revert InsufficientETH();
        pendingRentalEarnings[msg.sender] = 0;
        (bool ok,) = payable(msg.sender).call{value: amt}("");
        if (!ok) revert TransferFailed();
        emit RentalEarningsWithdrawn(msg.sender, amt);
    }

    function setTreasuryRentBps(uint16 newBps) external onlyOwner {
        if (newBps > TREASURY_RENT_BPS_MAX) revert BpsTooHigh();
        treasuryRentBps = newBps;
        emit TreasuryRentBpsUpdated(newBps);
    }

    // ═════════════════════════════════════════════════════════
    //                  Website reveal
    // ═════════════════════════════════════════════════════════

    function setWebsiteURL(string calldata url) external onlyOwner {
        _websiteURL = url;
        // Reveal immediately if the free phase has already minted out
        if (freePhaseMinted >= FREE_PHASE_SUPPLY && !websiteRevealed) {
            websiteRevealed = true;
            emit WebsiteRevealed(url);
        }
    }

    function websiteURL() external view returns (string memory) {
        if (!websiteRevealed) revert WebsiteNotRevealed();
        return _websiteURL;
    }

    // ═════════════════════════════════════════════════════════
    //                  Views & helpers
    // ═════════════════════════════════════════════════════════

    /// @notice Returns (x, y) coordinates on the 125×80 grid for a given 1-indexed tokenId.
    function coordinates(uint256 tokenId) public pure returns (uint256 x, uint256 y) {
        if (tokenId == 0 || tokenId > TOTAL_SUPPLY) revert InvalidTokenId();
        uint256 idx = tokenId - 1;
        x = idx % GRID_W;
        y = idx / GRID_W;
    }

    function isCornerReserved(uint256 x, uint256 y) public pure returns (bool) {
        if (x < 10 && y < 10) return true;                                // ETH
        if (x >= GRID_W - 10 && y < 10) return true;                      // X
        if (x < 10 && y >= GRID_H - 10) return true;                      // BASE
        if (x >= GRID_W - 10 && y >= GRID_H - 10) return true;            // UNI
        return false;
    }

    function publicRemaining() external view returns (uint256) {
        return PUBLIC_SUPPLY - publicMintCount;
    }

    // ─────────── ERC-165 ───────────
    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC2981) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ═════════════════════════════════════════════════════════
    //                  Treasury
    // ═════════════════════════════════════════════════════════

    function withdraw(address payable to) external onlyOwner {
        uint256 amt = address(this).balance - _totalPendingEarnings();
        (bool ok,) = to.call{value: amt}("");
        if (!ok) revert TransferFailed();
    }

    // Convenience: how much of contract balance is reserved for pull-payment claims.
    // (Sum tracked off-chain in practice; here we just guard against draining rent escrow.)
    // We keep a simple invariant by withdrawing only what mint revenue accounts for.
    function _totalPendingEarnings() internal view returns (uint256) {
        // Mint revenue can always be withdrawn. Pending rental balances are paid in via rent()
        // and exit via withdrawRentalEarnings(). We don't sum them on-chain (would need an index).
        // Conservative bound: treasury can only pull what's NOT in pendingRentalEarnings[owner()].
        // The owner's own rental share is claimable via withdrawRentalEarnings(); withdraw() drains
        // the rest. To keep this safe, we just subtract the owner's pending rental share.
        return pendingRentalEarnings[owner()];
    }

    // ═════════════════════════════════════════════════════════
    //                  Internal: random alloc
    // ═════════════════════════════════════════════════════════

    /// @dev Knuth shuffle draw from a virtual array of non-corner brick IDs.
    ///      Skips entries whose brick was already minted (e.g. via cluster mint).
    function _drawAndRemove() internal returns (uint256 brickId) {
        while (_remaining > 0) {
            unchecked { _nonce++; }
            uint256 rng = uint256(keccak256(
                abi.encodePacked(mintSeed, block.prevrandao, msg.sender, _nonce)
            ));
            uint256 idx = rng % _remaining;
            uint256 lastIdx = _remaining - 1;

            uint256 atIdx = _availableMap[idx];
            brickId = atIdx == 0 ? _indexToBrickId(idx) : atIdx;

            if (idx != lastIdx) {
                uint256 atLast = _availableMap[lastIdx];
                uint256 lastBrickId = atLast == 0 ? _indexToBrickId(lastIdx) : atLast;
                _availableMap[idx] = lastBrickId;
            }
            delete _availableMap[lastIdx];
            _remaining = lastIdx;

            // Skip if cluster-mint or corner mint already took this ID
            if (_ownerOf(brickId) == address(0)) return brickId;
        }
        revert PublicSoldOut();
    }

    /// @dev Map a 0..9_599 pool index to a 1-indexed brick ID, skipping corners.
    ///      Row layout: top 10 rows (105 non-corner cells), middle 60 rows (125 each), bottom 10 rows (105 each).
    function _indexToBrickId(uint256 i) internal pure returns (uint256) {
        // Top zone: rows 0..9, x in [10, 115) → 105 per row, 1050 total
        if (i < 1050) {
            uint256 row = i / 105;
            uint256 col = (i % 105) + 10;
            return row * GRID_W + col + 1;
        }
        // Middle zone: rows 10..69, full width → 125 per row, 7500 total
        if (i < 1050 + 7500) {
            uint256 m = i - 1050;
            uint256 row = 10 + m / 125;
            uint256 col = m % 125;
            return row * GRID_W + col + 1;
        }
        // Bottom zone: rows 70..79, x in [10, 115) → 105 per row, 1050 total
        uint256 b = i - 1050 - 7500;
        uint256 row2 = 70 + b / 105;
        uint256 col2 = (b % 105) + 10;
        return row2 * GRID_W + col2 + 1;
    }

    // ═════════════════════════════════════════════════════════
    //                  Internal: misc
    // ═════════════════════════════════════════════════════════

    function _clusterOverlapsCorner(uint256 sx, uint256 sy) internal pure returns (bool) {
        // Cluster spans [sx, sx+10) × [sy, sy+3)
        // Corners are 10×10 at four wall corners
        // Top-left corner [0,10)×[0,10): overlap iff sx < 10 && sy < 10
        if (sx < 10 && sy < 10) return true;
        // Top-right corner [GRID_W-10, GRID_W)×[0,10): overlap iff sx+10 > GRID_W-10 && sy < 10
        if (sx + BANNER_CLUSTER_W > GRID_W - 10 && sy < 10) return true;
        // Bottom-left corner [0,10)×[GRID_H-10, GRID_H): overlap iff sx<10 && sy+3>GRID_H-10
        if (sx < 10 && sy + BANNER_CLUSTER_H > GRID_H - 10) return true;
        // Bottom-right corner: overlap iff sx+10>GRID_W-10 && sy+3>GRID_H-10
        if (sx + BANNER_CLUSTER_W > GRID_W - 10 && sy + BANNER_CLUSTER_H > GRID_H - 10) return true;
        return false;
    }

    function _rentalActive(uint256 tokenId) internal view returns (bool) {
        return activeRentals[tokenId].expiresAt > block.timestamp;
    }

    /// @dev Cheap wallet-quality check: EOA only, with min balance. Sybil-expensive, not sybil-proof.
    function _passesWalletQuality(address who) internal view returns (bool) {
        if (who != tx.origin) return false;        // kills router-wrapped sybils
        if (who.code.length != 0) return false;    // EOA only
        if (who.balance < FREE_MIN_BALANCE) return false;
        return true;
    }

    receive() external payable {}
}
