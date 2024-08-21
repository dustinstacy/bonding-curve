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

contract MintLinearToken is Script {
    function run(address contractAddress) external payable {
        LinearToken(contractAddress).mintTokens{value: msg.value}();
    }
}

contract BurnLinearToken is Script {
    function run(address contractAddress, uint256 amount, address sender) external {
        LinearToken(contractAddress).burnTokens(amount, sender);
    }
}
