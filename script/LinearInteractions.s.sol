// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {LinearToken} from "src/linear-curve/LinearToken.sol";

contract LaunchToken is Script {
    function run(string memory name, string memory symbol) external payable {
        // address of the most recently deployed bonding curve
        address mostRecentlyDeployed;

        vm.startBroadcast();
        LinearBondingCurve curve = LinearBondingCurve(mostRecentlyDeployed);
        LinearToken token = new LinearToken(name, symbol, address(curve));
        mintFirstToken(token, msg.value);
        vm.stopBroadcast();
    }

    function mintFirstToken(LinearToken token, uint256 value) public payable {
        vm.startBroadcast();
        token.hostMint{value: value}();
        vm.stopBroadcast();
    }
}

contract MintToken is Script {}

contract BurnToken is Script {}
