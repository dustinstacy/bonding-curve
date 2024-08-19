// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {LinearToken} from "src/linear-curve/LinearToken.sol";

contract DeployLinearToken is Script {
    function run(string memory name, string memory symbol, address proxyAddress, address host)
        external
        payable
        returns (LinearToken token)
    {
        return token = new LinearToken{value: msg.value}(name, symbol, proxyAddress, host);
    }
}

contract MintToken is Script {}

contract BurnToken is Script {}
