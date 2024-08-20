// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployExponentialBondingCurve} from "script/DeployExponentialBondingCurve.s.sol";

contract ExponentialBondingCurveTest is Test {
    ExponentialBondingCurve public expCurve;
    HelperConfig public helperConfig;

    // Curve Variables;
    address owner;
    address protocolFeeDestination;
    uint256 protocolFeePercent;
    uint256 feeSharePercent;
    uint256 initialReserve;
    uint32 reserveRatio;
    uint256 maxGasLimit;

    // Test Variables
    uint256 supply;
    uint256 reserveBalance;
    uint256 value;
    uint256 amount;

    // Constants
    uint256 public constant PRECISION = 1e18;
    uint256 public constant BASIS_POINTS_PRECISION = 1e4;

    function setUp() public {
        DeployExponentialBondingCurve deployer = new DeployExponentialBondingCurve();
        (address proxy, HelperConfig helper) = deployer.deployCurve();
        HelperConfig.CurveConfig memory config = helper.getConfig();

        owner = config.owner;
        protocolFeeDestination = config.protocolFeeDestination;
        protocolFeePercent = (config.protocolFeePercent * PRECISION) / BASIS_POINTS_PRECISION;
        feeSharePercent = config.feeSharePercent;
        initialReserve = config.initialReserve;
        reserveRatio = config.reserveRatio;
        maxGasLimit = config.maxGasLimit;

        expCurve = ExponentialBondingCurve(payable(proxy));
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
        reserveBalance = 2 ether;
        amount = 414213562373095048;

        uint256 expectedValue = 1 ether;
        uint256 expectedFees = 0.01 ether;

        (uint256 returnedValue, uint256 fees) = expCurve.getSaleReturn(supply, reserveBalance, amount);
        assertApproxEqAbs(returnedValue, expectedValue, 10);
        assertApproxEqAbs(fees, expectedFees, 10);
    }

    function test_ExponentialCurve_CalculateSaleReturnTwo() public {
        supply = 1732050807568877292;
        reserveBalance = 3 ether;
        amount = 317837245195782244;

        uint256 expectedValue = 1 ether;
        uint256 expectedFees = 0.01 ether;

        (uint256 returnedValue, uint256 fees) = expCurve.getSaleReturn(supply, reserveBalance, amount);
        assertApproxEqAbs(returnedValue, expectedValue, 10);
        assertApproxEqAbs(fees, expectedFees, 10);
    }

    function test_ExponentialCurveCalculateMintCostOne() public {
        supply = 1e18;
        reserveBalance = 1 ether;

        uint256 expectedDepositAmount = 3.03 ether;
        uint256 expectedFees = 0.03 ether;

        (uint256 depositAmount, uint256 depositFees) = expCurve.getMintCost(supply, reserveBalance);
        assertApproxEqAbs(depositAmount, expectedDepositAmount, 10);
        assertApproxEqAbs(depositFees, expectedFees, 10);

        uint256 expectedCurveTokens = 1e18;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.getPurchaseReturn(supply, reserveBalance, depositAmount);
        assertApproxEqAbs(returnedCurveTokens, expectedCurveTokens, 1e5);
        assertApproxEqAbs(fees, depositFees, 10);
    }

    function test_ExponentialCurveCalculateMintCostTwo() public {
        supply = 2345e18;
        reserveBalance = 4535215 ether;

        uint256 expectedDepositAmount = 3907500056946458690405;
        uint256 expectedFees = 38688119375707511786;

        (uint256 depositAmount, uint256 depositFees) = expCurve.getMintCost(supply, reserveBalance);
        assertApproxEqAbs(depositAmount, expectedDepositAmount, 10);
        assertApproxEqAbs(depositFees, expectedFees, 10);

        uint256 expectedCurveTokens = 1e18;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.getPurchaseReturn(supply, reserveBalance, depositAmount);
        assertApproxEqAbs(returnedCurveTokens, expectedCurveTokens, 1e5);
        assertApproxEqAbs(fees, depositFees, 10);
    }

    function test_ExponentialCurveCalculateMintCostThree() public {
        supply = 251e17;
        reserveBalance = 0.00234 ether;

        uint256 expectedDepositAmount = 192070094125490;
        uint256 expectedFees = 1901684100252;

        (uint256 depositAmount, uint256 depositFees) = expCurve.getMintCost(supply, reserveBalance);
        assertApproxEqAbs(depositAmount, expectedDepositAmount, 10);
        assertApproxEqAbs(depositFees, expectedFees, 10);

        uint256 expectedCurveTokens = 1e18;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.getPurchaseReturn(supply, reserveBalance, depositAmount);
        assertApproxEqAbs(returnedCurveTokens, expectedCurveTokens, 1e5);
        assertApproxEqAbs(fees, depositFees, 10);
    }

    function test_ExponentialCurveCalculateMintCostFour() public {
        supply = 1e18;
        reserveBalance = 0.0001 ether;

        uint256 expectedDepositAmount = 0.000303 ether;
        uint256 expectedFees = 0.000003 ether;

        (uint256 depositAmount, uint256 depositFees) = expCurve.getMintCost(supply, reserveBalance);
        assertApproxEqAbs(depositAmount, expectedDepositAmount, 10);
        assertApproxEqAbs(depositFees, expectedFees, 10);

        uint256 expectedCurveTokens = 1e18;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.getPurchaseReturn(supply, reserveBalance, depositAmount);
        assertApproxEqAbs(returnedCurveTokens, expectedCurveTokens, 1e5);
        assertApproxEqAbs(fees, depositFees, 10);
    }

    function test_ExponentialCurveCalculateTokenPrice() public {
        supply = 1e18;
        reserveBalance = 1 ether;

        uint256 expectedPrice = 1 ether;

        uint256 price = expCurve.getTokenPrice(supply, reserveBalance);
        assertEq(price, expectedPrice);
    }

    function test_ExponentialCurveCalculateTokenPriceTwo() public {
        supply = 2e18;
        reserveBalance = 4 ether;

        uint256 expectedPrice = 3 ether;

        uint256 price = expCurve.getTokenPrice(supply, reserveBalance);
        assertApproxEqAbs(price, expectedPrice, 10);
    }

    function test_ExponentialCurveCalculateTokenPriceThree() public {
        supply = 2345e18;
        reserveBalance = 4535215 ether;
        value = 3868811937570751178619 + 38688119375707511786;

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 38688119375707511786;

        (uint256 returnedCurveTokens, uint256 fees) = expCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);

        uint256 newSupply = supply + returnedCurveTokens;
        uint256 newReserveBalance = reserveBalance + value - fees;

        uint256 price = expCurve.getTokenPrice(newSupply, newReserveBalance);
        assertApproxEqAbs(value - fees, price, 10);
    }
}
