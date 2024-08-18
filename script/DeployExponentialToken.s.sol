// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ExponentialToken} from "src/exponential-curve/ExponentialToken.sol";
import {Script} from "forge-std/Script.sol";

/// @title DeployExponentialToken
/// @notice Script for deploying the ExponentialToken contract.
contract DeployExponentialToken is Script {
    /// @dev Executes the deployment of the ExponentialToken contract.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param curveAddress The address of the ExponentialBondingCurve contract.
    /// @return token The deployed ExponentialToken contract instance.
    function run(string memory name, string memory symbol, address curveAddress)
        external
        returns (ExponentialToken token)
    {
        // Start broadcasting deployment transactions
        vm.startBroadcast();
        // Deploy ExponentialToken contract
        token = new ExponentialToken(name, symbol, curveAddress);
        // Stop broadcasting deployment transactions
        vm.stopBroadcast();
        // Return deployed contract instance
        return token;
    }
}
