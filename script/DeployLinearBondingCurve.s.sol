// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title DeployLinearBondingCurve
/// @notice Script for deploying the LinearBondingCurve contract.
contract DeployLinearBondingCurve is Script {
    function run() external {
        deployCurve();
    }

    /// @notice Deploys the LinearBondingCurve contract and sets it up as a proxy.
    /// @notice Deploys the HelperConfig contract and encodes the parameters for the LinearBondingCurve contract.
    /// @return proxy The address of the deployed LinearBondingCurve proxy.
    /// @return helperConfig The address of the deployed HelperConfig contract.
    function deployCurve() public returns (address proxy, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        HelperConfig.CurveConfig memory config = helperConfig.getConfig();

        bytes memory data = abi.encodeWithSelector(
            LinearBondingCurve.initialize.selector,
            config.owner,
            config.protocolFeeDestination,
            config.protocolFeePercent,
            config.feeSharePercent,
            config.initialReserve,
            config.maxGasLimit
        );

        vm.startBroadcast();
        // Deploy the LinearBondingCurve contract.
        LinearBondingCurve bondingCurve = new LinearBondingCurve();
        // Deploy the ERC1967Proxy contract and set the LinearBondingCurve contract as the implementation.
        ERC1967Proxy proxyContract = new ERC1967Proxy(address(bondingCurve), data);
        proxy = address(proxyContract);
        vm.stopBroadcast();
        return (proxy, helperConfig);
    }
}
