// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {Brick} from "../src/Brick.sol";

/// @notice Deploy script — NFT-only (no token, no v4 hook).
///         Deploys Brick + mints all 400 corner reserves to treasury in one tx.
contract Deploy is Script {
    uint256 public constant MINT_PRICE = 0.0005 ether;

    function run() external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address treasury = vm.addr(pk);

        vm.startBroadcast(pk);

        Brick brick = new Brick(treasury, MINT_PRICE);
        console2.log("Brick deployed at:", address(brick));
        console2.log("Treasury:", treasury);
        console2.log("Mint price (wei):", MINT_PRICE);

        brick.mintCornerReserves();
        console2.log("Corner reserves minted (400 bricks to treasury)");

        vm.stopBroadcast();
    }
}
