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
        // Acts like linear curve. Maybe no need for seperate curve?
        expCurve.setReserveRatio(500000);
    }

    function test_ExponentialCurveV2_CalculatePurchaseReturnOne() public {
        supply = 1e18;
        reserveBalance = 1 ether;
        value = 1.01 ether;

        uint256 expectedCurveTokens = 414213562373095048;
        uint256 expectedFees = 0.01 ether;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_ExponentialCurveV2_CalculatePurchaseReturnTwo() public {
        supply = 1414213562373095048;
        reserveBalance = 2 ether;
        value = 1.01 ether;

        uint256 expectedCurveTokens = 317837245195782244;
        uint256 expectedFees = 0.01 ether;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_ExponentialCurveV2_CalculateSaleReturnOne() public {
        supply = 1414213562373095048;
        console.log("Supply: ", supply);
        reserveBalance = 2 ether;
        amount = 414213562373095048;

        uint256 expectedValue = 0.99 ether;
        uint256 expectedFees = 0.01 ether;

        (uint256 returnedValue, uint256 fees) = expCurve.getSaleReturn(supply, reserveBalance, amount);
        assertApproxEqAbs(returnedValue, expectedValue, 10);
        assertApproxEqAbs(fees, expectedFees, 10);
    }

    function test_ExponentialCurveV2_CalculateSaleReturnTwo() public {
        supply = 1732050807568877292;
        console.log("Supply: ", supply);
        reserveBalance = 3 ether;
        amount = 317837245195782244;

        uint256 expectedValue = 0.99 ether;
        uint256 expectedFees = 0.01 ether;

        (uint256 returnedValue, uint256 fees) = expCurve.getSaleReturn(supply, reserveBalance, amount);
        assertApproxEqAbs(returnedValue, expectedValue, 10);
        assertApproxEqAbs(fees, expectedFees, 10);
    }
}
