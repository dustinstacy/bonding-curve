// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ExponentialBondingCurve} from "src/ExponentialBondingCurve.sol";

contract ExponentialBondingCurveTest is Test {
    ExponentialBondingCurve public expCurve;

    uint256 private constant PRECISION = 1e18;
    uint256 private constant BASIS_POINTS_PRECISION = 1e4;

    // Test Variables;
    uint256 supply;
    uint256 reserveBalance;
    uint256 value;
    uint256 reserveRatio;
    uint256 tokensToReturn;

    uint256 protocolFeePercent;

    function setUp() public {
        expCurve = new ExponentialBondingCurve();
        expCurve.setProtocolFeeBasisPoints(100);
        expCurve.setFeeDestination(address(this));
        protocolFeePercent = expCurve.protocolFeeBasisPoints() * PRECISION / BASIS_POINTS_PRECISION;
    }

    function test_EXP_BC_CalculatePurchaseReturn() public {
        supply = 1e18;
        reserveBalance = 0.0001 ether;
        reserveRatio = 500000;
        value = 0.0001 ether;

        uint256 expectedRawReturn = 1e18;
        uint256 expectedFees = expectedRawReturn * protocolFeePercent / PRECISION;
        uint256 expectedReturn = expectedRawReturn - expectedFees;

        uint256 actualReturn = expCurve.calculatePurchaseReturn(supply, reserveBalance, value, reserveRatio);
        assertEq(actualReturn, expectedReturn);
    }

    function test_EXP_BC_CalculatePurchaseReturnTwo() public {
        supply = 1e18;
        reserveBalance = 0.0001 ether;
        reserveRatio = 400000;
        value = 0.00015 ether;

        uint256 expectedRawReturn = 1e18;
        uint256 expectedFees = expectedRawReturn * protocolFeePercent / PRECISION;
        uint256 expectedReturn = expectedRawReturn - expectedFees;

        uint256 actualReturn = expCurve.calculatePurchaseReturn(supply, reserveBalance, value, reserveRatio);
        assertEq(actualReturn, expectedReturn);
    }

    function test_EXP_BC_CalculatePurchaseReturnThree() public {
        supply = 1e18;
        reserveBalance = 0.0001 ether;
        reserveRatio = 813000;
        value = 23001230012300;
        tokensToReturn = 1e18;

        uint256 expectedRawReturn = 1e18;
        uint256 expectedFees = expectedRawReturn * protocolFeePercent / PRECISION;
        uint256 expectedReturn = expectedRawReturn - expectedFees;

        uint256 actualReturn = expCurve.calculatePurchaseReturn(supply, reserveBalance, value, reserveRatio);
        assertApproxEqRel(actualReturn, expectedReturn, 1e4);
    }

    function test_EXP_BC_CalculateBurnTokenOne() public {
        // starting varaibles
        supply = 2e18;
        reserveBalance = 0.0001 ether;
        reserveRatio = 500000;
        value = 0.0001 ether;

        uint256 fees = (value * protocolFeePercent) / PRECISION;
        uint256 totalValue = value + fees;

        uint256 tokensMinted = expCurve.calculatePurchaseReturn(supply, reserveBalance, totalValue, reserveRatio);
        console.log("tokensMinted: ", tokensMinted);
        uint256 newSupply = supply + tokensMinted;
        console.log("newSupply: ", newSupply);
        uint256 newReserveBalance = reserveBalance + value;
        console.log("newReserveBalance: ", newReserveBalance);

        //sell 1 token
        uint256 tokensToBurn = 1e18;

        uint256 saleValue = expCurve.calculateSaleReturn(newSupply, newReserveBalance, tokensToBurn, reserveRatio);
        console.log("saleValue: ", saleValue);

        assertEq(supply, newSupply - tokensToBurn);
    }

    function test_EXP_BC_CalculateBurnTokenTwo() public {
        // starting varaibles
        supply = 5e18;
        reserveBalance = 0.0002 ether;
        reserveRatio = 500000;
        value = 0.005 ether;

        uint256 tokensMinted = expCurve.calculatePurchaseReturn(supply, reserveBalance, value, reserveRatio);
        //   tokensMinted results:
        //   fraction:  25000000000000000000
        //   base:  26000000000000000000
        //   exp:  13000000000000000000
        //   purchaseReturn:  65000000000000000000

        uint256 newSupply = supply + tokensMinted;
        uint256 newReserveBalance = reserveBalance + value;

        //sell minted tokens
        uint256 tokensToBurn = tokensMinted;

        uint256 saleValue = expCurve.calculateSaleReturn(newSupply, newReserveBalance, tokensToBurn, reserveRatio);
        console.log("saleValue: ", saleValue);
        assertEq(saleValue, value);
        assertEq(supply, newSupply - tokensToBurn);
    }
}
