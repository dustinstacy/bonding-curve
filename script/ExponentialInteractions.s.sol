// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {ExponentialToken} from "src/exponential-curve/ExponentialToken.sol";

contract LaunchToken is Script {
    function run(string memory name, string memory symbol) external payable returns (address) {
        // Address of deployed ExponentialBondingCurve proxy. Needs to be set before running this script.
        address proxyAddress;

        vm.startBroadcast();
        ExponentialToken token = new ExponentialToken{value: msg.value}(name, symbol, proxyAddress);
        vm.stopBroadcast();

        return address(token);
    }
}

contract MintToken is Script {}

contract BurnToken is Script {}
