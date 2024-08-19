// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {Script} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title DeployLinearBondingCurve
/// @notice Script for deploying the LinearBondingCurve contract.
contract DeployLinearBondingCurve is Script {
    /// @return proxy The address of the deployed LinearBondingCurve proxy.
    function run() external returns (address proxy) {
        return proxy = deployCurve();
    }

    /// @notice Deploys the LinearBondingCurve contract and sets it up as a proxy.
    /// @return The address of the deployed LinearBondingCurve proxy.
    function deployCurve() public returns (address) {
        vm.startBroadcast();
        // Deploy the ExponentialBondingCurve contract.
        LinearBondingCurve bondingCurve = new LinearBondingCurve();
        // Deploy the ERC1967Proxy contract and set the LinearBondingCurve contract as the implementation.
        ERC1967Proxy proxy = new ERC1967Proxy(address(bondingCurve), "");
        vm.stopBroadcast();
        return address(proxy);
    }
}
