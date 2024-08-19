// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title DeployExponentialBondingCurve
/// @notice Script for deploying the ExponentialBondingCurve contract.
contract DeployExponentialBondingCurve is Script {
    function run() external {
        deployCurve();
    }

    /// @notice Deploys the ExponentialBondingCurve contract and sets it up as a proxy.
    /// @notice Deploys the HelperConfig contract and encodes the parameters for the ExponentialBondingCurve contract.
    /// @return proxy The address of the deployed ExponentialBondingCurve proxy.
    /// @return helperConfig The address of the deployed HelperConfig contract.
    function deployCurve() public returns (address proxy, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        HelperConfig.CurveConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        // Deploy the ExponentialBondingCurve implementation contract.
        ExponentialBondingCurve bondingCurve = new ExponentialBondingCurve();

        // Encode the parameters for the ExponentialBondingCurve contract.
        bytes memory data = abi.encodeWithSelector(
            bondingCurve.initialize.selector,
            config.owner,
            config.protocolFeeDestination,
            config.protocolFeePercent,
            config.feeSharePercent,
            config.initialReserve,
            config.reserveRatio,
            config.maxGasLimit
        );

        // Deploy the ERC1967Proxy contract and set the ExponentialBondingCurve contract as the implementation.
        ERC1967Proxy proxyContract = new ERC1967Proxy(address(bondingCurve), data);
        proxy = address(proxyContract);
        vm.stopBroadcast();
        return (proxy, helperConfig);
    }
}
