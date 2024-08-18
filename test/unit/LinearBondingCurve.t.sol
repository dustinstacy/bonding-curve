// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

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

    function test_LinearCurve_Fees() public {
        supply = 1e18;
        reserverBalance = 1 ether;
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

    function test_LinearCurve_CalculatePurchaseReturnOne() public {
        supply = 1e18;
        reserverBalance = 1 ether;
        value = 2.02 ether;

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 0.02 ether;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.calculatePurchaseReturn(supply, reserverBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_CalculatePurchaseReturnTwo() public {
        supply = 25e17;
        reserverBalance = 4.5 ether;
        value = 10.1 ether;

        uint256 expectedCurveTokens = 24e17;
        uint256 expectedFees = 0.1 ether;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.calculatePurchaseReturn(supply, reserverBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_CalculatePurchaseReturnThree() public {
        supply = 1e18;
        reserverBalance = 0.001 ether;
        value = 0.00202 ether;

        linCurve.setInitialCost(0.001 ether);

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 0.00002 ether;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.calculatePurchaseReturn(supply, reserverBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_CalculatePurchaseReturnFour() public {
        supply = 1000000e18;
        reserverBalance = 500000500000 ether;
        value = 1010001.01 ether;

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 10000.01 ether;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.calculatePurchaseReturn(supply, reserverBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_CalculateSaleReturnOne() public {
        supply = 2e18;
        reserverBalance = 3 ether;
        amount = 1e18;

        uint256 expectedSaleValue = 1.98 ether;
        uint256 expectedFees = 0.02 ether;

        (uint256 returnedSaleValue, uint256 fees) = linCurve.calculateSaleReturn(supply, reserverBalance, amount);
        assertEq(returnedSaleValue, expectedSaleValue);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_CalculateSaleReturnTwo() public {
        supply = 75e17;
        reserverBalance = 32 ether;
        amount = 35e17;

        uint256 expectedSaleValue = 21.78 ether;
        uint256 expectedFees = 0.22 ether;

        (uint256 returnedSaleValue, uint256 fees) = linCurve.calculateSaleReturn(supply, reserverBalance, amount);
        assertEq(returnedSaleValue, expectedSaleValue);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_CalculateSaleReturnThree() public {
        supply = 2e18;
        reserverBalance = 0.003 ether;
        amount = 1e18;

        linCurve.setInitialCost(0.001 ether);

        uint256 expectedSaleValue = 0.00198 ether;
        uint256 expectedFees = 0.00002 ether;

        (uint256 returnedSaleValue, uint256 fees) = linCurve.calculateSaleReturn(supply, reserverBalance, amount);
        assertEq(returnedSaleValue, expectedSaleValue);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_CalculateSaleReturnFour() public {
        supply = 1000000e18;
        reserverBalance = 500000500000 ether;
        amount = 1e18;

        uint256 expectedSaleValue = 990000 ether;
        uint256 expectedFees = 10000 ether;

        (uint256 returnedSaleValue, uint256 fees) = linCurve.calculateSaleReturn(supply, reserverBalance, amount);
        assertEq(returnedSaleValue, expectedSaleValue);
        assertEq(fees, expectedFees);
    }

    function test_CalculateMintCost() public {
        supply = 1e18;
        reserverBalance = 1 ether;

        uint256 expectedCost = 2 ether;

        uint256 cost = linCurve.calculateMintCost(supply, reserverBalance);
        assertEq(cost, expectedCost);
    }

    function test_CaclutateMintCost() public {
        supply = 1e18;
        reserverBalance = 0.001 ether;

        linCurve.setInitialCost(0.001 ether);

        uint256 expectedCost = 0.002 ether;

        uint256 cost = linCurve.calculateMintCost(supply, reserverBalance);
        assertEq(cost, expectedCost);
    }

    function test_CalculateMintCostTwo() public {
        supply = 1568e17;
        reserverBalance = 12371.6 ether;

        uint256 expectedCost = 157800000000000000000;

        uint256 cost = linCurve.calculateMintCost(supply, reserverBalance);
        assertEq(cost, expectedCost);
    }

    function test_CalculateMintCostThree() public {
        supply = 1568e17;
        reserverBalance = 12371.6 ether;
        value = 157800000000000000000 + 1578000000000000000;

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 1578000000000000000;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.calculatePurchaseReturn(supply, reserverBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }
}
