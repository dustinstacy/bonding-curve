// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";

contract LinearBondingCurveTest is Test {
    LinearBondingCurve public linCurve;

    // Test Variables
    uint256 supply;
    uint256 reserverBalance;
    uint256 value;
    uint256 amount;

    function setUp() public {
        linCurve = new LinearBondingCurve();
        linCurve.setInitialCost(1 ether);
        linCurve.setProtocolFeeDestination(address(linCurve));
        linCurve.setProtocolFeeBasisPoints(100);
    }

    function test_Fees() public {
        supply = 1e18;
        reserverBalance = 1e18;
        value = 2.02 ether;

        uint256 expectedCurveTokens = 1e18;

        // 1% fee
        uint256 expectedFees = 0.02 ether;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.calculatePurchaseReturn(supply, reserverBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);

        // 2% fee
        linCurve.setProtocolFeeBasisPoints(200);
        value = 2.04 ether;

        uint256 expectedFeesTwo = 0.04 ether;

        (uint256 returnedCurveTokensTwo, uint256 feesTwo) =
            linCurve.calculatePurchaseReturn(supply, reserverBalance, value);
        assertEq(returnedCurveTokensTwo, expectedCurveTokens);
        assertEq(feesTwo, expectedFeesTwo);

        // 3% fee
        linCurve.setProtocolFeeBasisPoints(300);
        value = 2.06 ether;

        uint256 expectedFeesThree = 0.06 ether;

        (uint256 returnedCurveTokensThree, uint256 feesThree) =
            linCurve.calculatePurchaseReturn(supply, reserverBalance, value);
        assertEq(returnedCurveTokensThree, expectedCurveTokens);
        assertEq(feesThree, expectedFeesThree);

        // 7.85% fee
        linCurve.setProtocolFeeBasisPoints(785);
        value = 2.157 ether;

        uint256 expectedFeesFour = 0.157 ether;

        (uint256 returnedCurveTokensFour, uint256 feesFour) =
            linCurve.calculatePurchaseReturn(supply, reserverBalance, value);
        assertEq(returnedCurveTokensFour, expectedCurveTokens);
        assertEq(feesFour, expectedFeesFour);
    }

    function test_CalculatePurchaseReturn() public {
        supply = 25e17;
        reserverBalance = 45e17;
        value = 10.1 ether;

        uint256 expectedCurveTokens = 24e17;
        uint256 expectedFees = 0.1 ether;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.calculatePurchaseReturn(supply, reserverBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_CalculateSaleReturn() public {
        supply = 2e18;
        reserverBalance = 3e18;
        amount = 1e18;

        uint256 expectedSaleValue = 1.98 ether;
        uint256 expectedFees = 0.02 ether;

        (uint256 returnedSaleValue, uint256 fees) = linCurve.calculateSaleReturn(supply, reserverBalance, amount);
        assertEq(returnedSaleValue, expectedSaleValue);
        assertEq(fees, expectedFees);

        supply = 75e17;
        reserverBalance = 32e18;
        amount = 35e17;

        uint256 expectedSaleValueTwo = 21.78 ether;
        uint256 expectedFeesTwo = 0.22 ether;

        (uint256 returnedSaleValueTwo, uint256 feesTwo) = linCurve.calculateSaleReturn(supply, reserverBalance, amount);
        assertEq(returnedSaleValueTwo, expectedSaleValueTwo);
        assertEq(feesTwo, expectedFeesTwo);
    }
}
