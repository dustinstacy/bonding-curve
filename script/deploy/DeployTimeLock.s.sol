// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {TimeLock} from "src/dao/TimeLock.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";

/// @title DeployExponentialBondingCurve
/// @notice Script for deploying the AlphaMarketDAO protocol.
contract DeployTimeLock is Script {
    function run() external returns (TimeLock lock) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig;
        (, networkConfig) = helperConfig.getConfig();

        lock = deployTimeLock(networkConfig.admin);
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
