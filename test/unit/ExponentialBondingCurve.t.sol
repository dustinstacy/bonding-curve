// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ExponentialBondingCurve} from "src/ExponentialBondingCurve.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {Calculations} from "src/libraries/Calculations.sol";

contract ExponentialBondingCurveTest is Test {
    ExponentialBondingCurve public expCurve;
    MockV3Aggregator ethUSDPriceFeed;

    uint8 private constant DECIMALS = 8;
    int256 private constant ETH_USD_PRICE = 3265;

    // Curve Variables
    uint256 supply = 10000;
    uint256 initialCost = 0.001 ether;
    uint256 scalingFactor = 10000;
    uint256 amount = 100;
    uint256 singleToken = 1;

    function setUp() public {
        expCurve = new ExponentialBondingCurve();
        ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
    }

    function test_EXP_BC_GetSingleTokenPrice() public view {
        uint256 expectedPrice = expCurve.getRawPrice(supply, initialCost, scalingFactor, singleToken);
        uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), expectedPrice);
        console.log("Token: ", supply + 1);
        console.log("Price: ", expectedPrice, "Converted price: ", convertedPrice);
    }

    function test_EXP_BC_GetEachTokenPrice() public view {
        uint256 expectedPrice;

        for (uint256 i = 0; i < amount; i++) {
            expectedPrice = expCurve.getRawPrice(supply + i, initialCost, scalingFactor, singleToken);
            uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), expectedPrice);
            console.log("Token: ", supply + i + 1);
            console.log("Price: ", expectedPrice, "Converted price: ", convertedPrice);
        }
    }

    function test_EXP_BC_GetBulkTokenPrice() public view {
        uint256 expectedPrice;

        for (uint256 i = 0; i < amount; i++) {
            expectedPrice += expCurve.getRawPrice(supply + i, initialCost, scalingFactor, singleToken);
            uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), expectedPrice);
            console.log("Tokens: ", supply + 1, " - ", supply + i + 1);
            console.log("Price: ", expectedPrice, "Converted price: ", convertedPrice);
        }

        uint256 actualPrice = expCurve.getRawPrice(supply, initialCost, scalingFactor, amount);
        assertApproxEqAbs(actualPrice, expectedPrice, (amount / 2));
        console.log("Price: ", actualPrice, "Expected Price: ", expectedPrice);
    }
}
