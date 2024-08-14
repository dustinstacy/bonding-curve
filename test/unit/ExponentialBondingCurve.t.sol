// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";

contract ExponentialBondingCurveTest is Test {
    ExponentialBondingCurve public expCurve;

    uint256 private constant PRECISION = 1e18;
    uint256 private constant BASIS_POINTS_PRECISION = 1e4;

    // Test Variables;
    uint256 supply;
    uint256 reserveBalance;
    uint256 value;
    uint256 tokensToBurn;
    uint256 protocolFeePercent;

    // Update tests to incorporate fees!

    // function setUp() public {
    //     expCurve = new ExponentialBondingCurve();
    //     expCurve.setProtocolFeeBasisPoints(100);
    //     expCurve.setFeeDestination(address(this));
    //     expCurve.setReserveRatioPPM(500000);
    //     protocolFeePercent = expCurve.protocolFeeBasisPoints() * PRECISION / BASIS_POINTS_PRECISION;
    // }

    // function test_EXP_BC_CalculatePurchaseReturn() public {
    //     supply = 1e18;
    //     reserveBalance = 0.0001 ether;
    //     value = 0.0001 ether;

    //     uint256 expectedRawReturn = 1e18;
    //     uint256 expectedFees = expectedRawReturn * protocolFeePercent / PRECISION;
    //     uint256 expectedReturn = expectedRawReturn - expectedFees;

    //     (uint256 actualReturn, uint256 fees) = expCurve.calculatePurchaseReturn(supply, reserveBalance, value);
    //     assertEq(actualReturn, expectedReturn);
    // }

    // function test_EXP_BC_CalculatePurchaseReturnTwo() public {
    //     supply = 1e18;
    //     reserveBalance = 0.0001 ether;
    //     value = 0.00015 ether;

    //     uint256 expectedRawReturn = 1e18;
    //     uint256 expectedFees = expectedRawReturn * protocolFeePercent / PRECISION;
    //     uint256 expectedReturn = expectedRawReturn - expectedFees;

    //     (uint256 actualReturn, uint256 fees) = expCurve.calculatePurchaseReturn(supply, reserveBalance, value);
    //     assertEq(actualReturn, expectedReturn);
    // }

    // function test_EXP_BC_CalculatePurchaseReturnThree() public {
    //     supply = 1e18;
    //     reserveBalance = 0.0001 ether;
    //     value = 23001230012300;

    //     uint256 expectedRawReturn = 1e18;
    //     uint256 expectedFees = expectedRawReturn * protocolFeePercent / PRECISION;
    //     uint256 expectedReturn = expectedRawReturn - expectedFees;

    //     (uint256 actualReturn, uint256 fees) = expCurve.calculatePurchaseReturn(supply, reserveBalance, value);
    //     assertApproxEqRel(actualReturn, expectedReturn, 1e4);
    // }

    // function test_EXP_BC_CalculateBurnTokenOne() public {
    //     // starting varaibles
    //     supply = 2e18;
    //     reserveBalance = 0.0001 ether;
    //     tokensToBurn = 1e18;

    //     (uint256 saleValue, uint256 fees) = expCurve.calculateSaleReturn(supply, reserveBalance, tokensToBurn);

    //     assertEq(supply, supply - tokensToBurn);
    // }

    // function test_EXP_BC_CalculateBurnTokenTwo() public {
    //     // starting varaibles
    //     supply = 5e18;
    //     reserveBalance = 0.0002 ether;
    //     tokensToBurn = 1e18;

    //     (uint256 saleValue, uint256 fees) = expCurve.calculateSaleReturn(supply, reserveBalance, tokensToBurn);
    //     assertEq(saleValue, value);
    //     assertEq(supply, supply - tokensToBurn);
    // }
}
