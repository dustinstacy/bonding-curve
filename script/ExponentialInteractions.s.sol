// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {ExponentialToken} from "src/exponential-curve/ExponentialToken.sol";

contract DeployExponentialToken is Script {
    function run(string memory name, string memory symbol, address proxyAddress, address host)
        external
        payable
        returns (ExponentialToken token)
    {
        return token = new ExponentialToken{value: msg.value}(name, symbol, proxyAddress, host);
    }
}

contract MintToken is Script {}

contract BurnToken is Script {}
