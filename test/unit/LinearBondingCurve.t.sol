// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {LinearBondingCurve} from "src/LinearBondingCurve.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {Calculations} from "src/libraries/Calculations.sol";

contract LinearBondingCurveTest is Test {
    LinearBondingCurve public linCurve;
    MockV3Aggregator ethUSDPriceFeed;

    uint8 private constant DECIMALS = 8;
    int256 private constant ETH_USD_PRICE = 3265;

    // Curve Variables
    uint256 supply = 0;
    uint256 initialCost = 0.001 ether;
    uint256 scalingFactor = 10000;
    uint256 amount = 100;
    uint256 singleToken = 1;
    int256 initialCostAdjustment;
    uint256 priceIncrement;

    function setUp() public {
        linCurve = new LinearBondingCurve();
        ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        scalingFactor = Calculations.calculateScalingFactorPercent(scalingFactor);
        initialCostAdjustment = Calculations.calculateInitialCostAdjustment(initialCost, scalingFactor);
        priceIncrement = initialCost * scalingFactor / linCurve.getPrecision();
    }

    function test_LIN_BC_GetFirstTokenPrice() public view {
        uint256 actualPrice = linCurve.getRawPrice(0, initialCost, scalingFactor, singleToken, initialCostAdjustment);

        console.log("Price: ", actualPrice, "Expected Price: ", initialCost);
        assertEq(actualPrice, initialCost);
    }

    function test_LIN_BC_GetAnyTokenPrice() public view {
        uint256 actualPrice =
            linCurve.getRawPrice(supply, initialCost, scalingFactor, singleToken, initialCostAdjustment);

        uint256 expectedPrice = supply * priceIncrement + initialCost;

        console.log("Price: ", actualPrice, "Expected Price: ", expectedPrice);
        assertEq(actualPrice, expectedPrice);
    }

    function test_LIN_BC_GetBatchTokenPrice() public view {
        uint256 actualPrice = linCurve.getRawPrice(supply, initialCost, scalingFactor, amount, initialCostAdjustment);

        uint256 expectedPrice;
        for (uint256 i = 0; i < amount; i++) {
            expectedPrice +=
                linCurve.getRawPrice(supply + i, initialCost, scalingFactor, singleToken, initialCostAdjustment);
        }

        console.log("Price: ", actualPrice, "Expected Price: ", expectedPrice);
        assertEq(actualPrice, expectedPrice);
    }
}
