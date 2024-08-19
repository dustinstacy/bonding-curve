// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {LinearToken} from "src/linear-curve/LinearToken.sol";

contract LaunchToken is Script {
    function run(string memory name, string memory symbol) external payable returns (address) {
        // Address of deployed LinearBondingCurve proxy. Needs to be set before running this script.
        address proxyAddress;

        vm.startBroadcast();
        LinearToken token = new LinearToken{value: msg.value}(name, symbol, proxyAddress);
        vm.stopBroadcast();

        return address(token);
    }
}

contract MintToken is Script {}

contract BurnToken is Script {}
