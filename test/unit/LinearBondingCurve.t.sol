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
    uint256 scalingFactor = Calculations.calculateScalingFactorPercent(5000);
    uint256 amount = 100;
    uint256 singleToken = 1;
    int256 initialCostAdjustment;

    function setUp() public {
        linCurve = new LinearBondingCurve();
        ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        initialCostAdjustment = Calculations.calculateInitialCostAdjustment(initialCost, scalingFactor);
    }

    function test_LIN_BC_GetEachTokenPrice() public view {
        uint256 expectedPrice;

        for (uint256 i = 0; i < amount; i++) {
            expectedPrice =
                linCurve.getPrice(supply + i, initialCost, scalingFactor, singleToken, initialCostAdjustment);
            uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), expectedPrice);
            console.log("Token: ", supply + i + 1);
            console.log("Price: ", expectedPrice, "Converted price: ", convertedPrice);
        }
    }

    function test_LIN_BC_GetBulkTokenPrice() public view {
        uint256 expectedPrice;

        for (uint256 i = 0; i < amount; i++) {
            expectedPrice +=
                linCurve.getPrice(supply + i, initialCost, scalingFactor, singleToken, initialCostAdjustment);
            uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), expectedPrice);
            console.log("Tokens: ", supply + 1, " - ", supply + i + 1);
            console.log("Price: ", expectedPrice, "Converted price: ", convertedPrice);
        }

        uint256 actualPrice = linCurve.getPrice(supply, initialCost, scalingFactor, amount, initialCostAdjustment);
        assertEq(actualPrice, expectedPrice);
        console.log("Price: ", actualPrice, "Expected Price: ", expectedPrice);
    }
}
