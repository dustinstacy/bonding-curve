// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LinearToken} from "src/linear-curve/LinearToken.sol";
import {Script} from "forge-std/Script.sol";

/// @title DeployLinearToken
/// @notice Script for deploying the LinearToken contract.
contract DeployLinearToken is Script {
    /// @dev Executes the deployment of the LinearToken contract.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param curveAddress The address of the LinearBondingCurve contract.
    /// @return token The deployed LinearToken contract instance.
    function run(string memory name, string memory symbol, address curveAddress) external returns (LinearToken token) {
        // Start broadcasting deployment transactions
        vm.startBroadcast();
        // Deploy LinearToken contract
        token = new LinearToken(name, symbol, curveAddress);
        // Stop broadcasting deployment transactions
        vm.stopBroadcast();
        // Return deployed contract instance
        return token;
    }
}
