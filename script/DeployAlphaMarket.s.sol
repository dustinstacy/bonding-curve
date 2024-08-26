// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {AlphaMarket} from "src/dao/AlphaMarket.sol";
import {AlphaMarketToken} from "src/dao/AlphaMarketToken.sol";
import {TimeLock} from "src/dao/TimeLock.sol";

/// @title DeployExponentialBondingCurve
/// @notice Script for deploying the AlphaMarket protocol.
contract DeployAlphaMarket is Script {
    function run(address _admin, AlphaMarketToken token, TimeLock lock) external returns (AlphaMarket market) {
        market = deployAlphaMarket(_admin, token, lock);
        updateRoles(address(market), _admin, lock);

        return (market);
    }

    /// @notice Deploys the AlphaMarket contract.
    /// @param _admin The address of the admin of the TimeLock contract.
    /// @param alphaMarketToken The instance of the AlphaMarketToken contract.
    /// @param timeLock The instance of the TimeLock contract.
    /// @return alphaMarket The address of the deployed AlphaMarket contract.
    function deployAlphaMarket(address _admin, AlphaMarketToken alphaMarketToken, TimeLock timeLock)
        public
        returns (AlphaMarket alphaMarket)
    {
        vm.startBroadcast(_admin);
        alphaMarket = new AlphaMarket(alphaMarketToken, timeLock);
        vm.stopBroadcast();
        return alphaMarket;
    }

    /// @notice Grants the proposer and executor roles to the admin of the TimeLock contract.
    /// @param alphaMarket The address of the AlphaMarket contract.
    /// @param timeLock The instance of the TimeLock contract.
    function updateRoles(address alphaMarket, address _admin, TimeLock timeLock) public {
        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();

        vm.startBroadcast(_admin);
        timeLock.grantRole(proposerRole, alphaMarket);
        timeLock.grantRole(executorRole, alphaMarket);
        vm.stopBroadcast();
    }
}
