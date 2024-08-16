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
    uint256 amount;

    function setUp() public {
        expCurve = new ExponentialBondingCurve();
        expCurve.setProtocolFeeDestination(address(expCurve));
        expCurve.setProtocolFeeBasisPoints(100);
        expCurve.setReserveRatioPPM(500000);
    }

    function test_ExponentialCurve_CalculatePurchaseReturnOne() public {
        supply = 1e18;
        reserveBalance = 1 ether;
        value = 2.02 ether;

        uint256 expectedCurveTokens = 15e17;
        uint256 expectedFees = 0.02 ether;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.calculatePurchaseReturn(supply, reserveBalance, value);
        console.log("returnedCurveTokens: ", returnedCurveTokens, "expectedCurveTokens: ", expectedCurveTokens);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        console.log("fees: ", fees, "expectedFees: ", expectedFees);
        assertEq(fees, expectedFees);
    }

    function test_CalculateSaleReturnOne() public {
        supply = 25e17;
        reserveBalance = 3 ether;
        amount = 15e17;

        uint256 expectedValue = 1.98 ether;
        uint256 expectedFees = 0.02 ether;

        (uint256 returnedValue, uint256 fees) = expCurve.calculateSaleReturn(supply, reserveBalance, amount);
        console.log("returnedValue: ", returnedValue, "expectedValue: ", expectedValue);
        assertEq(returnedValue, expectedValue);
        console.log("fees: ", fees, "expectedFees: ", expectedFees);
        assertEq(fees, expectedFees);
    }
}
