// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {Script} from "forge-std/Script.sol";

/// @title DeployLinearBondingCurve
/// @notice Script for deploying the LinearBondingCurve contract.
contract DeployLinearBondingCurve is Script {
    /// @dev Executes the deployment of the LinearBondingCurve contract.
    /// @return bondingCurve The deployed LinearBondingCurve contract instance.
    function run() external returns (LinearBondingCurve bondingCurve) {
        // Start broadcasting deployment transactions
        vm.startBroadcast();
        // Deploy LinearBondingCurve contract
        bondingCurve = new LinearBondingCurve();
        // Stop broadcasting deployment transactions
        vm.stopBroadcast();
        // Return deployed contract instance
        return bondingCurve;
    }
}
