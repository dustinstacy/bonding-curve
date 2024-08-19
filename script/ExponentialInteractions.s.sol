// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {ExponentialToken} from "src/exponential-curve/ExponentialToken.sol";

contract LaunchToken is Script {
    function run(string memory name, string memory symbol) external payable {
        // address of the most recently deployed bonding curve
        address mostRecentlyDeployed;

        vm.startBroadcast();
        ExponentialBondingCurve curve = ExponentialBondingCurve(mostRecentlyDeployed);
        ExponentialToken token = new ExponentialToken(name, symbol, address(curve));
        mintFirstToken(token, msg.value);
        vm.stopBroadcast();
    }

    function mintFirstToken(ExponentialToken token, uint256 value) public payable {
        vm.startBroadcast();
        token.hostMint{value: value}();
        vm.stopBroadcast();
    }
}

contract MintToken is Script {}

contract BurnToken is Script {}
