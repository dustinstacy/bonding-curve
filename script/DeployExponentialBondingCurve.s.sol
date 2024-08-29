// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

/// @title DeployExponentialBondingCurve
/// @notice Script for deploying the ExponentialBondingCurve contract.
contract DeployExponentialBondingCurve is Script {
    function run() external returns (address proxy, ExponentialBondingCurve expCurve, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        HelperConfig.CurveConfig memory config;
        HelperConfig.NetworkConfig memory networkConfig;
        (config, networkConfig) = helperConfig.getConfig();

        if (block.chainid != 31337) {
            address mostRecentTimeLock = DevOpsTools.get_most_recent_deployment("TimeLock", block.chainid);
            (proxy, expCurve, helperConfig) =
                deployCurve(mostRecentTimeLock, networkConfig.protocolFeeDestination, config);
        } else {
            (proxy, expCurve, helperConfig) =
                deployCurve(networkConfig.protocolFeeDestination, networkConfig.protocolFeeDestination, config);
        }
    }

    /// @notice Deploys the ExponentialBondingCurve contract and sets it up as a proxy.
    /// @notice Deploys the HelperConfig contract and encodes the parameters for the ExponentialBondingCurve contract.
    /// @param _owner The address of the owner of the ExponentialBondingCurve contract.
    /// @param _feeAddress The address of the fee address for the ExponentialBondingCurve contract.
    /// @return proxy The address of the deployed ExponentialBondingCurve proxy.
    /// @return expCurve The address of the deployed ExponentialBondingCurve contract.
    /// @return helperConfig The address of the deployed HelperConfig contract.
    function deployCurve(address _owner, address _feeAddress, HelperConfig.CurveConfig memory config)
        public
        returns (address proxy, ExponentialBondingCurve expCurve, HelperConfig helperConfig)
    {
        vm.startBroadcast();
        // Deploy the ExponentialBondingCurve implementation contract.
        expCurve = new ExponentialBondingCurve();

        console.log("initialReserve", config.initialReserve);
        // Encode the parameters for the ExponentialBondingCurve contract.
        bytes memory data = abi.encodeWithSelector(
            expCurve.initialize.selector,
            _owner,
            _feeAddress,
            config.protocolFeePercent,
            config.feeSharePercent,
            config.initialReserve,
            config.reserveRatio,
            config.maxGasLimit
        );

        // Deploy the ERC1967Proxy contract and set the ExponentialBondingCurve contract as the implementation.

        ERC1967Proxy proxyContract = new ERC1967Proxy(address(expCurve), data);
        proxy = address(proxyContract);
        expCurve = ExponentialBondingCurve(proxy);
        vm.stopBroadcast();

        return (proxy, expCurve, helperConfig);
    }
}
