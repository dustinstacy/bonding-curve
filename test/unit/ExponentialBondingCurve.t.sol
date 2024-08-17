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

    function test_ExponentialCurve_CalculatePurchaseReturnOne() public {
        supply = 1e18;
        reserveBalance = 1 ether;
        value = 1.01 ether;

        uint256 expectedCurveTokens = 414213562373095048;
        uint256 expectedFees = 0.01 ether;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_ExponentialCurve_CalculatePurchaseReturnTwo() public {
        supply = 1414213562373095048;
        reserveBalance = 2 ether;
        value = 1.01 ether;

        uint256 expectedCurveTokens = 317837245195782244;
        uint256 expectedFees = 0.01 ether;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_ExponentialCurve_CalculateSaleReturnOne() public {
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

    function test_ExponentialCurve_CalculateSaleReturnTwo() public {
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

    function test_calculateMintCost() public {
        supply = 1e18;
        reserveBalance = 1 ether;

        uint256 expectedDepositAmount = 1 ether;

        uint256 depositAmount = expCurve.calculateMintCost(supply, reserveBalance);
        assertEq(depositAmount, expectedDepositAmount);
    }

    function test_calculateMintCostTwo() public {
        supply = 1e18;
        reserveBalance = 1 ether;
        value = 3.03 ether;

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 0.03 ether;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertApproxEqAbs(returnedCurveTokens, expectedCurveTokens, 10);
        assertApproxEqAbs(fees, expectedFees, 10);
    }

    function test_calculateMintCostThree() public {
        supply = 2345e18;
        reserveBalance = 4535215 ether;

        uint256 expectedDepositAmount = 3868811937570751178619;

        uint256 depositAmount = expCurve.calculateMintCost(supply, reserveBalance);
        assertEq(depositAmount, expectedDepositAmount);
    }

    function test_calculateMintCostFour() public {
        supply = 2345e18;
        reserveBalance = 4535215 ether;
        value = 3868811937570751178619 + 38688119375707511786;

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 38688119375707511786;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_calculateMintCostFive() public {
        supply = 251e17;
        reserveBalance = 0.00234 ether;

        uint256 expectedDepositAmount = 190168410025238;

        uint256 depositAmount = expCurve.calculateMintCost(supply, reserveBalance);
        assertEq(depositAmount, expectedDepositAmount);
    }

    function test_calculateMintCostSix() public {
        supply = 251e17;
        reserveBalance = 0.00234 ether;
        value = 190168410025238 + 1901684100252;

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 1901684100252;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertApproxEqAbs(returnedCurveTokens, expectedCurveTokens, 1e5);
        assertApproxEqAbs(fees, expectedFees, 1e5);
    }
}
