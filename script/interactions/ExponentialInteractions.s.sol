// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {ExponentialBondingCurve} from "src/bonding-curves/ExponentialBondingCurve.sol";
import {GroupToken} from "src/group/GroupToken.sol";

contract DeployGroupToken is Script {
    function run(string memory name, string memory symbol, address proxyAddress, address host)
        external
        payable
        returns (GroupToken token)
    {
        return token = new GroupToken{value: msg.value}(name, symbol, proxyAddress, host);
    }
}

contract MintGroupToken is Script {
    function run(address contractAddress) external payable {
        GroupToken(contractAddress).mintTokens{value: msg.value}();
    }
}

contract BurnGroupToken is Script {
    function run(address contractAddress, uint256 amount, address sender) external {
        GroupToken(contractAddress).burnTokens(amount, sender);
    }
}
