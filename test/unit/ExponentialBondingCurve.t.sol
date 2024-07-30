// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ExponentialBondingCurve} from "src/ExponentialBondingCurve.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {Calculations} from "src/libraries/Calculations.sol";

contract BondingCurveTest is Test {
    ExponentialBondingCurve public expCurve;
    MockV3Aggregator ethUSDPriceFeed;

    uint8 private constant DECIMALS = 8;
    int256 private constant ETH_USD_PRICE = 3265;

    // Curve Variables
    uint256 supply = 0;
    uint256 initialCost = 0.001 ether;
    uint256 maxCost = 10000 ether;
    uint256 scalingFactor = 1000;
    uint256 amount = 100;
    uint256 singleToken = 1;

    function setUp() public {
        expCurve = new ExponentialBondingCurve();
        ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
    }

    function test_BuyFirstToken() public view {
        uint256 zeroSupply = 0;
        uint256 actualPrice = expCurve.getPrice(zeroSupply, initialCost, maxCost, scalingFactor, singleToken);
        uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), actualPrice);
        console.log("Price: ", actualPrice, "Converted price: ", convertedPrice);
    }

    function test_BuySecondToken() public view {
        uint256 oneSupply = 1;
        uint256 actualPrice = expCurve.getPrice(oneSupply, initialCost, maxCost, scalingFactor, singleToken);
        uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), actualPrice);
        console.log("Price: ", actualPrice, "Converted price: ", convertedPrice);
    }

    function test_BuyTokensInBulk() public view {
        uint256 expectedPrice;

        for (uint256 i = 0; i < amount; i++) {
            expectedPrice += expCurve.getPrice(supply + i, initialCost, maxCost, scalingFactor, singleToken);
            console.log("Total New Supply: ", supply + i, "Price: ", expectedPrice);
        }

        uint256 actualPrice = expCurve.getPrice(supply, initialCost, maxCost, scalingFactor, amount);
        uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), expectedPrice);
        console.log("Price: ", actualPrice, "Converted price: ", convertedPrice);

        assertEq(actualPrice, expectedPrice);
    }

    // function test_BuyTokensCurve() public view {
    //     // uint256 totalPrice;
    //     uint256 amount = 100;

    //     for (uint256 i = 0; i < amount; i++) {
    //         uint256 currentPrice = expCurve.getPrice(supply, initialCost, maxCost, scalingFactor, amount);
    //         // totalPrice += currentPrice;
    //         uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), currentPrice);
    //         console.log("Total Supply: ", supply, "Converted price: ", convertedPrice);
    //         console.log("New Total Supply: ", supply);
    //     }

    //     // uint256 expectedTotalPrice = initialCost * (amount * (amount + 1) / 2);

    //     // assertEq(totalPrice, expectedTotalPrice);
    // }
}
