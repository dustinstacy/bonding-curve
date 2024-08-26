// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

import {TimeLock} from "src/dao/TimeLock.sol";

/// @title DeployExponentialBondingCurve
/// @notice Script for deploying the AlphaMarket protocol.
contract DeployTimeLock is Script {
    function run(address _admin) external returns (TimeLock lock) {
        lock = deployTimeLock(_admin);
    }

    /// @notice Deploys the TimeLock contract.
    /// @param _admin The address of the admin of the TimeLock contract.
    /// @return timeLock The address of the deployed TimeLock contract.
    function deployTimeLock(address _admin) public returns (TimeLock timeLock) {
        uint256 minDelay = 1;
        address[] memory proposers = new address[](1);
        proposers[0] = _admin;
        address[] memory executors = new address[](1);
        executors[0] = _admin;

        vm.startBroadcast();
        timeLock = new TimeLock(minDelay, proposers, executors, _admin);
        vm.stopBroadcast();
        return timeLock;
    }
}
