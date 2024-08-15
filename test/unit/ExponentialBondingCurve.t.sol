// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";

contract ExponentialBondingCurveTest is Test {
    ExponentialBondingCurve public expCurve;

    // Test Variables;
    uint256 supply;
    uint256 reserveBalance;
    uint256 value;

    function setUp() public {
        expCurve = new ExponentialBondingCurve();
        expCurve.setProtocolFeeDestination(address(expCurve));
        expCurve.setProtocolFeeBasisPoints(100);
        expCurve.setReserveRatioPPM(500000);
    }
}
