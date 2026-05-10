// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title WallHook — Uniswap v4 hook for $WALL
/// @notice TODO: Day 3-4. Routes 5% total swap tax:
///         - 2% to dev wallet (ETH)
///         - 1% to brick owner pool (Sushi-style accumulator, by brick count)
///         - 2% auto-compound into LP
///
/// @dev Will use afterSwap hook to:
///       1. Take 3% delta from swap output (in ETH)
///       2. Send 2% to dev multisig
///       3. Update feePerBrick accumulator with 1% portion (totalFees / 9500)
///       4. Re-add 2% as liquidity to the pool
///       Pool LP fee tier itself is set to 2% (handled via PoolKey.fee)
///
///       Brick owners pull via claim():
///         owed = (brickCount[wallet] * feePerBrick) - claimed[wallet]
///
/// Deps to install before implementing:
///   forge install Uniswap/v4-core
///   forge install Uniswap/v4-periphery
///
/// Reference patterns:
///   https://github.com/Uniswap/v4-template
///   https://github.com/Uniswap/v4-periphery/tree/main/src/utils
contract WallHook {
    // Placeholder. Implementation lands Day 3-4.
}
