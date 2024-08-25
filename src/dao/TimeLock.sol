//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {console} from "forge-std/console.sol";

contract TimeLock is TimelockController {
    /// @param minDelay Minimum delay for timelock
    /// @param proposers List of addresses that can propose a transaction
    /// @param executors List of addresses that can execute a transaction
    /// @param admin Address that can change the proposers, executors, and delay
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin)
        TimelockController(minDelay, proposers, executors, admin)
    {}
}
