// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title DeployLinearBondingCurve
/// @notice Script for deploying the LinearBondingCurve contract.
contract DeployLinearBondingCurve is Script {
    function run(address _owner, address _feeAddress)
        external
        returns (address proxy, LinearBondingCurve linCurve, HelperConfig helperConfig)
    {
        (proxy, linCurve, helperConfig) = deployCurve(_owner, _feeAddress);
    }

    /// @notice Deploys the LinearBondingCurve contract and sets it up as a proxy.
    /// @notice Deploys the HelperConfig contract and encodes the parameters for the LinearBondingCurve contract.
    /// @param _owner The address of the owner of the LinearBondingCurve contract.
    /// @return proxy The address of the deployed LinearBondingCurve proxy.
    /// @return linCurve The address of the deployed LinearBondingCurve contract.
    /// @return helperConfig The address of the deployed HelperConfig contract.
    function deployCurve(address _owner, address _feeAddress)
        public
        returns (address proxy, LinearBondingCurve linCurve, HelperConfig helperConfig)
    {
        helperConfig = new HelperConfig();
        HelperConfig.CurveConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        // Deploy the LinearBondingCurve implementation contract.
        LinearBondingCurve bondingCurve = new LinearBondingCurve();

        // Encode the parameters for the LinearBondingCurve contract.
        bytes memory data = abi.encodeWithSelector(
            bondingCurve.initialize.selector,
            _owner,
            _feeAddress,
            config.protocolFeePercent,
            config.feeSharePercent,
            config.initialReserve,
            config.maxGasLimit
        );
        // Deploy the ERC1967Proxy contract and set the LinearBondingCurve contract as the implementation.
        ERC1967Proxy proxyContract = new ERC1967Proxy(address(bondingCurve), data);
        proxy = address(proxyContract);
        linCurve = LinearBondingCurve(payable(proxy));
        vm.stopBroadcast();

        return (proxy, linCurve, helperConfig);
    }
}
