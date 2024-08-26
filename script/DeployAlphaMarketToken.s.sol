// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {AlphaMarketToken} from "src/dao/AlphaMarketToken.sol";

/// @title DeployExponentialBondingCurve
/// @notice Script for deploying the AlphaMarket protocol.
contract DeployAlphaMarketToken is Script {
    function run(address _admin) external returns (AlphaMarketToken token) {
        token = deployAlphaMarketToken(_admin);
    }

    /// @notice Deploys the AlphaMarketToken contract.
    /// @param _admin The address of the admin of the AlphaMarketToken contract.
    /// @return token The address of the deployed AlphaMarketToken contract.
    function deployAlphaMarketToken(address _admin) public returns (AlphaMarketToken token) {
        vm.startBroadcast();
        token = new AlphaMarketToken(_admin);
        vm.stopBroadcast();
        return token;
    }
}
