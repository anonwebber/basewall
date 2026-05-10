// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Brick — basewall billboard NFT
/// @notice 10,000 brick NFTs forming a 125x80 onchain billboard (1.56:1).
///         9,100 outer bricks public mint @ 0.001 ETH (FCFS, 100/wallet).
///         900 reserved for dev treasury: 4 corners (10x10 each) + center (25x20).
/// @dev NOTE: contiguous DEV_RESERVE_START is a TEMPORARY placeholder.
///      Next session patches in `isDevReserved()` for non-contiguous corners+center,
///      plus random allocation via committed seed and `mintBannerCluster()`.
contract Brick is ERC721, Ownable, ReentrancyGuard {
    uint256 public constant GRID_W = 125;
    uint256 public constant GRID_H = 80;
    uint256 public constant TOTAL_SUPPLY = 10_000; // GRID_W * GRID_H
    uint256 public constant PUBLIC_SUPPLY = 9_100; // TOTAL - 4*100 corners - 500 center
    uint256 public constant DEV_RESERVE_START = 9_101; // placeholder; superseded by isDevReserved()
    uint256 public constant MINT_PRICE = 0.001 ether;
    uint256 public constant MAX_PER_WALLET = 100;

    mapping(uint256 => string) public contentURI;
    mapping(address => uint256) public publicMintedBy;

    uint256 public publicMintCount;

    event ContentUpdated(uint256 indexed tokenId, address indexed owner, string uri);
    event PublicMint(address indexed buyer, uint256 quantity, uint256 startTokenId);
    event DevReserveMinted(uint256 count);

    error ZeroQuantity();
    error InsufficientETH();
    error WalletCapExceeded();
    error PublicSoldOut();
    error NotOwner();
    error InvalidTokenId();
    error TransferFailed();

    constructor(address treasury) ERC721("BaseWall Brick", "BRICK") Ownable(treasury) {}

    function mint(uint256 quantity) external payable nonReentrant {
        if (quantity == 0) revert ZeroQuantity();
        if (msg.value < MINT_PRICE * quantity) revert InsufficientETH();
        if (publicMintedBy[msg.sender] + quantity > MAX_PER_WALLET) revert WalletCapExceeded();
        if (publicMintCount + quantity > PUBLIC_SUPPLY) revert PublicSoldOut();

        uint256 startId = publicMintCount + 1;
        for (uint256 i = 0; i < quantity; i++) {
            unchecked { ++publicMintCount; }
            _safeMint(msg.sender, publicMintCount);
        }
        publicMintedBy[msg.sender] += quantity;

        emit PublicMint(msg.sender, quantity, startId);
    }

    /// @notice Mints all 500 dev-reserved center bricks to the treasury (owner). One-time.
    function mintDevReserve() external onlyOwner {
        for (uint256 id = DEV_RESERVE_START; id <= TOTAL_SUPPLY; id++) {
            if (_ownerOf(id) == address(0)) {
                _safeMint(owner(), id);
            }
        }
        emit DevReserveMinted(TOTAL_SUPPLY - DEV_RESERVE_START + 1);
    }

    function updateContent(uint256 tokenId, string calldata uri) external {
        if (_ownerOf(tokenId) != msg.sender) revert NotOwner();
        contentURI[tokenId] = uri;
        emit ContentUpdated(tokenId, msg.sender, uri);
    }

    /// @notice Returns (x, y) coordinates on the 125x80 grid for a given tokenId (1-indexed).
    function coordinates(uint256 tokenId) public pure returns (uint256 x, uint256 y) {
        if (tokenId == 0 || tokenId > TOTAL_SUPPLY) revert InvalidTokenId();
        uint256 idx = tokenId - 1;
        x = idx % GRID_W;
        y = idx / GRID_W;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return contentURI[tokenId];
    }

    function withdraw(address payable to) external onlyOwner {
        (bool ok,) = to.call{value: address(this).balance}("");
        if (!ok) revert TransferFailed();
    }
}
