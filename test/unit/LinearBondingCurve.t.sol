// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployLinearBondingCurve} from "script/DeployLinearBondingCurve.s.sol";

contract LinearBondingCurveTest is Test {
    LinearBondingCurve public linCurve;
    HelperConfig public helperConfig;

    // Curve Variables;
    address owner;
    address protocolFeeDestination;
    uint256 protocolFeePercent;
    uint256 feeSharePercent;
    uint256 initialReserve;
    uint256 maxGasLimit;

    // Test Variables
    uint256 supply;
    uint256 reserveBalance;
    uint256 value;
    uint256 amount;

    function setUp() public {
        DeployLinearBondingCurve deployer = new DeployLinearBondingCurve();
        (address proxy, HelperConfig helper) = deployer.deployCurve();
        HelperConfig.CurveConfig memory config = helper.getConfig();

        owner = config.owner;
        protocolFeeDestination = config.protocolFeeDestination;
        protocolFeePercent = config.protocolFeePercent;
        feeSharePercent = config.feeSharePercent;
        initialReserve = config.initialReserve;
        maxGasLimit = config.maxGasLimit;

        linCurve = LinearBondingCurve(payable(proxy));
        vm.prank(owner);
        linCurve.setInitialReserve(1 ether);
    }

    function test_LinearCurve_Fees() public {
        supply = 1e18;
        reserveBalance = 1 ether;
        value = 2.02 ether;

        uint256 expectedCurveTokens = 1e18;

        // 1% fee
        uint256 expectedFees = 0.02 ether;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);

        // 2% fee
        vm.prank(owner);
        linCurve.setProtocolFeePercent(200);
        value = 2.04 ether;

        uint256 expectedFeesTwo = 0.04 ether;

        (uint256 returnedCurveTokensTwo, uint256 feesTwo) = linCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokensTwo, expectedCurveTokens);
        assertEq(feesTwo, expectedFeesTwo);

        // 3% fee
        vm.prank(owner);
        linCurve.setProtocolFeePercent(300);
        value = 2.06 ether;

        uint256 expectedFeesThree = 0.06 ether;

        (uint256 returnedCurveTokensThree, uint256 feesThree) =
            linCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokensThree, expectedCurveTokens);
        assertEq(feesThree, expectedFeesThree);

        // 7.85% fee
        vm.prank(owner);
        linCurve.setProtocolFeePercent(785);
        value = 2.157 ether;

        uint256 expectedFeesFour = 0.157 ether;

        (uint256 returnedCurveTokensFour, uint256 feesFour) = linCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokensFour, expectedCurveTokens);
        assertEq(feesFour, expectedFeesFour);
    }

    function test_LinearCurve_getPurchaseReturnOne() public {
        supply = 1e18;
        reserveBalance = 1 ether;
        value = 2.02 ether;

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 0.02 ether;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_getPurchaseReturnTwo() public {
        supply = 25e17;
        reserveBalance = 4.5 ether;
        value = 10.1 ether;

        uint256 expectedCurveTokens = 24e17;
        uint256 expectedFees = 0.1 ether;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_getPurchaseReturnThree() public {
        supply = 1e18;
        reserveBalance = 0.001 ether;
        value = 0.00202 ether;

        vm.prank(owner);
        linCurve.setInitialReserve(0.001 ether);

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 0.00002 ether;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_getPurchaseReturnFour() public {
        supply = 1000000e18;
        reserveBalance = 500000500000 ether;
        value = 1010001.01 ether;

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 10000.01 ether;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_getSaleReturnOne() public {
        supply = 2e18;
        reserveBalance = 3 ether;
        amount = 1e18;

        uint256 expectedSaleValue = 2 ether;
        uint256 expectedFees = 0.02 ether;

        (uint256 returnedSaleValue, uint256 fees) = linCurve.getSaleReturn(supply, reserveBalance, amount);
        assertEq(returnedSaleValue, expectedSaleValue);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_getSaleReturnTwo() public {
        supply = 75e17;
        reserveBalance = 32 ether;
        amount = 35e17;

        uint256 expectedSaleValue = 22 ether;
        uint256 expectedFees = 0.22 ether;

        (uint256 returnedSaleValue, uint256 fees) = linCurve.getSaleReturn(supply, reserveBalance, amount);
        assertEq(returnedSaleValue, expectedSaleValue);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_getSaleReturnThree() public {
        supply = 2e18;
        reserveBalance = 0.003 ether;
        amount = 1e18;

        vm.prank(owner);
        linCurve.setInitialReserve(0.001 ether);

        uint256 expectedSaleValue = 0.002 ether;
        uint256 expectedFees = 0.00002 ether;

        (uint256 returnedSaleValue, uint256 fees) = linCurve.getSaleReturn(supply, reserveBalance, amount);
        assertEq(returnedSaleValue, expectedSaleValue);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurve_getSaleReturnFour() public {
        supply = 1000000e18;
        reserveBalance = 500000500000 ether;
        amount = 1e18;

        uint256 expectedSaleValue = 1000000 ether;
        uint256 expectedFees = 10000 ether;

        (uint256 returnedSaleValue, uint256 fees) = linCurve.getSaleReturn(supply, reserveBalance, amount);
        assertEq(returnedSaleValue, expectedSaleValue);
        assertEq(fees, expectedFees);
    }

    function test_LinearTokenGetMintCostOne() public {
        supply = 1e18;
        reserveBalance = 0.0001 ether;

        uint256 expectedDepositAmount = 0.0002 ether;
        uint256 expectedFees = 0.000002 ether;

        vm.prank(owner);
        linCurve.setInitialReserve(0.0001 ether);

        (uint256 depositAmount, uint256 depositFees) = linCurve.getMintCost(supply, reserveBalance);
        assertEq(depositAmount - depositFees, expectedDepositAmount);
        assertEq(depositFees, expectedFees);
    }

    function test_LinearTokenGetMintCostTwo() public {
        supply = 1e18;
        reserveBalance = 0.001 ether;

        vm.prank(owner);
        linCurve.setInitialReserve(0.001 ether);

        uint256 expectedCost = 0.00202 ether;

        (uint256 cost,) = linCurve.getMintCost(supply, reserveBalance);
        assertEq(cost, expectedCost);
    }

    function test_LinearTokenGetMintCostThree() public {
        supply = 1568e17;
        reserveBalance = 12371.6 ether;

        uint256 expectedCost = 157800000000000000000;

        (uint256 cost, uint256 fees) = linCurve.getMintCost(supply, reserveBalance);
        assertEq(cost - fees, expectedCost);
    }

    function test_LinearTokenGetMintCostFour() public {
        supply = 1568e17;
        reserveBalance = 12371.6 ether;
        value = 157800000000000000000 + 1578000000000000000;

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 1578000000000000000;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);
    }

    function test_LinearCurveGetTokenPriceOne() public {
        supply = 1e18;
        reserveBalance = 1 ether;

        uint256 expectedPrice = 1 ether;

        (uint256 price,) = linCurve.getTokenPrice(supply, reserveBalance);
        assertEq(price, expectedPrice);
    }

    function test_LinearCurveGetTokenPriceTwo() public {
        supply = 2e18;
        reserveBalance = 3 ether;

        uint256 expectedPrice = 2 ether;

        (uint256 price,) = linCurve.getTokenPrice(supply, reserveBalance);
        assertEq(price, expectedPrice);
    }

    function test_LinearCurveGetTokenPriceThree() public {
        supply = 25e17;
        reserveBalance = 4.5 ether;

        uint256 expectedPrice = 2.5 ether;

        (uint256 price,) = linCurve.getTokenPrice(supply, reserveBalance);
        assertEq(price, expectedPrice);
    }

    function test_LinearCurvegetTokenPriceFour() public {
        supply = 1568e17;
        reserveBalance = 12371.6 ether;
        value = 157800000000000000000 + 1578000000000000000;

        uint256 expectedCurveTokens = 1e18;
        uint256 expectedFees = 1578000000000000000;

        (uint256 returnedCurveTokens, uint256 fees) = linCurve.getPurchaseReturn(supply, reserveBalance, value);
        assertEq(returnedCurveTokens, expectedCurveTokens);
        assertEq(fees, expectedFees);

        uint256 newSupply = supply + returnedCurveTokens;
        uint256 newReserveBalance = reserveBalance + value - fees;

        (uint256 price,) = linCurve.getTokenPrice(newSupply, newReserveBalance);
        assertApproxEqAbs(value - fees, price, 10);
    }
}
