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

    function setUp() public {
        linCurve = new LinearBondingCurve();
        ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
    }

    // function test_LIN_BC_BuyFirstToken() public view {
    //     uint256 zeroSupply = 0;
    //     uint256 actualPrice = linCurve.getPrice(zeroSupply, initialCost, scalingFactor, singleToken);
    //     uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), actualPrice);
    //     console.log("Price: ", actualPrice, "Converted price: ", convertedPrice);
    // }

    // function test_LIN_BC_BuySecondToken() public view {
    //     uint256 oneSupply = 1;
    //     uint256 actualPrice = linCurve.getPrice(oneSupply, initialCost, scalingFactor, singleToken);
    //     uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), actualPrice);
    //     console.log("Price: ", actualPrice, "Converted price: ", convertedPrice);
    // }

    function test_LIN_BC_GetEachTokenPrice() public view {
        uint256 expectedPrice;

        for (uint256 i = 0; i < amount; i++) {
            expectedPrice = linCurve.getPrice(supply + i, initialCost, scalingFactor, singleToken);
            uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), expectedPrice);
            console.log("Token: ", i + 1);
            console.log("Price: ", expectedPrice, "Converted price: ", convertedPrice);
        }
    }

    function test_LIN_BC_GetBulkTokenPrice() public view {
        uint256 expectedPrice;

        for (uint256 i = 0; i < amount; i++) {
            expectedPrice += linCurve.getPrice(supply + i, initialCost, scalingFactor, singleToken);
            uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), expectedPrice);
            console.log("Tokens: ", supply, " - ", i + 1);
            console.log("Price: ", expectedPrice, "Converted price: ", convertedPrice);
        }

        uint256 actualPrice = linCurve.getPrice(supply, initialCost, scalingFactor, amount);
        assertEq(actualPrice, expectedPrice);
        console.log("Price: ", actualPrice, "Expected Price: ", expectedPrice);
    }

    // function test_LIN_BC_BuyTokensCurve() public view {
    //     // uint256 totalPrice;
    //     uint256 amount = 100;

    //     for (uint256 i = 0; i < amount; i++) {
    //         uint256 currentPrice = linCurve.getPrice(supply, initialCost,  scalingFactor, amount);
    //         // totalPrice += currentPrice;
    //         uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), currentPrice);
    //         console.log("Total Supply: ", supply, "Converted price: ", convertedPrice);
    //         console.log("New Total Supply: ", supply);
    //     }

    //     // uint256 linectedTotalPrice = initialCost * (amount * (amount + 1) / 2);

    //     // assertEq(totalPrice, linectedTotalPrice);
    // }
}
