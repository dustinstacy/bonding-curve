// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {Script} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title DeployExponentialBondingCurve
/// @notice Script for deploying the ExponentialBondingCurve contract.
contract DeployExponentialBondingCurve is Script {
    /// @return proxy The address of the deployed ExponentialBondingCurve proxy.
    function run() external returns (address proxy) {
        return proxy = deployCurve();
    }

    /// @notice Deploys the ExponentialBondingCurve contract and sets it up as a proxy.
    /// @return The address of the deployed ExponentialBondingCurve proxy.
    function deployCurve() public returns (address) {
        vm.startBroadcast();
        // Deploy the ExponentialBondingCurve contract.
        ExponentialBondingCurve bondingCurve = new ExponentialBondingCurve();
        // Deploy the ERC1967Proxy contract and set the ExponentialBondingCurve contract as the implementation.
        ERC1967Proxy proxy = new ERC1967Proxy(address(bondingCurve), "");
        vm.stopBroadcast();
        return address(proxy);
    }
}
