// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {ExponentialToken} from "src/exponential-curve/ExponentialToken.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

/// @title DeployExponentialBondingCurve
/// @notice Script for deploying the Exponential protocol.
contract DeployExponentialToken is Script {
    function run() external returns (ExponentialToken token) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig;
        HelperConfig.CurveConfig memory curveConfig;
        (curveConfig, networkConfig) = helperConfig.getConfig();

        string memory name = "Exponential Token";
        string memory symbol = "EXP";
        address proxy = 0x3FE1EeFD8FcA939dD0670564700A2703BBfAFe96;
        uint256 value = curveConfig.initialReserve;

        token = deployExponentialToken(name, symbol, proxy, msg.sender, value);
    }

    /// @notice Deploys the ExponentialToken contract.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param proxy The address of the proxy contract.
    /// @param host The address of the host contract.
    /// @param value The initial reserve value.
    /// @return token The address of the deployed ExponentialToken contract.
    function deployExponentialToken(
        string memory name,
        string memory symbol,
        address proxy,
        address host,
        uint256 value
    ) public returns (ExponentialToken token) {
        vm.startBroadcast();
        token = new ExponentialToken{value: value}(name, symbol, proxy, host);
        vm.stopBroadcast();
        return token;
    }
}
