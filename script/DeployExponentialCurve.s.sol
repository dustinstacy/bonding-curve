// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {Script} from "forge-std/Script.sol";

/// @title DeployExponentialBondingCurve
/// @notice Script for deploying the ExponentialBondingCurve contract.
contract DeployExponentialBondingCurve is Script {
    /// @dev Executes the deployment of the ExponentialBondingCurve contract.
    /// @return bondingCurve The deployed ExponentialBondingCurve contract instance.
    function run() external returns (ExponentialBondingCurve bondingCurve) {
        // Start broadcasting deployment transactions
        vm.startBroadcast();
        // Deploy ExponentialBondingCurve contract
        bondingCurve = new ExponentialBondingCurve();
        // Stop broadcasting deployment transactions
        vm.stopBroadcast();
        // Return deployed contract instance
        return bondingCurve;
    }
}
