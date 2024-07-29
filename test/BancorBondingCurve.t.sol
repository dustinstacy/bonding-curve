// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ContinuousToken} from "src/token/ContinuousToken.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {Calculations} from "src/libraries/Calculations.sol";

contract BancorBondingCurveTest is Test {
    ContinuousToken public ct;

    function setUp() public {
        ct = new ContinuousToken("ContinuousToken", "CT", 1000, 500000);
    }
}
