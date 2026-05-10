// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title $WALL — basewall token
/// @notice Total supply 1,000,000,000. Allocated:
///         - 600M to LP seed
///         - 475M brick mint rewards (50,000 per public brick × 9,500)
///         - 50M dev wallet (vested 6mo, manual)
///         - 50M marketing
///         - 25M burn at deploy
contract WallToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;

    // Per-allocation buckets (tracked for clarity, minted on construction)
    uint256 public constant LP_SEED = 600_000_000 ether;
    uint256 public constant BRICK_REWARDS = 475_000_000 ether;
    uint256 public constant DEV_WALLET = 50_000_000 ether;
    uint256 public constant MARKETING = 50_000_000 ether;
    uint256 public constant DEPLOY_BURN = 25_000_000 ether;

    address public brickRewards;

    constructor(address treasury, address _brickRewards, address marketing)
        ERC20("BaseWall", "WALL")
        Ownable(treasury)
    {
        brickRewards = _brickRewards;

        // Mint allocations
        _mint(treasury, LP_SEED);                    // for LP creation
        _mint(_brickRewards, BRICK_REWARDS);         // distributor contract holds these
        _mint(treasury, DEV_WALLET);                 // treasury holds, manual vest
        _mint(treasury, MARKETING);                  // marketing wallet
        _mint(address(0xdead), DEPLOY_BURN);         // burn

        require(totalSupply() == MAX_SUPPLY, "Allocation mismatch");
    }
}
