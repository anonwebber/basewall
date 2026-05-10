// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {Brick} from "../src/Brick.sol";
import {WallToken} from "../src/WallToken.sol";

/// @notice Deploy script — TODO: lands Day 5 once contracts complete.
///         For now: deploys Brick + WallToken to set treasury.
///         Day 5+: also deploys WallHook + creates Uniswap v4 pool + seeds LP.
contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address treasury = vm.addr(pk);

        vm.startBroadcast(pk);

        Brick brick = new Brick(treasury);
        console2.log("Brick deployed at:", address(brick));

        WallToken wall = new WallToken(treasury, treasury, treasury);
        console2.log("WallToken deployed at:", address(wall));

        vm.stopBroadcast();
    }
}
