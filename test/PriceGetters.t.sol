// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {PriceGetters} from "src/PriceGetters.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {Calculations} from "src/libraries/Calculations.sol";

contract PriceGettersTest is Test {
    PriceGetters pg;
    MockV3Aggregator ethUSDPriceFeed;

    uint8 private constant DECIMALS = 0;
    int256 private constant ETH_USD_PRICE = 3265;

    function setUp() public {
        pg = new PriceGetters{value: 0.1 ether}(1000, 0.001 ether);
        ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
    }

    function test_GetPrice() public view {
        uint256 scalingFactor = 100;
        for (uint256 i = 0; i < 10; i++) {
            uint256 price = pg.getPrice(i, i + 1, scalingFactor);
            uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), price);
            console.log("Amount: ", i + 1, "Converted price: ", convertedPrice);
            console.log("Amount: ", i + 1, "Price: ", price);
        }
    }

    function test_calculateBuyPrice() public view {
        for (uint256 i = 0; i < 10; i++) {
            uint256 price = pg.calculateBuyPrice(i);
            console.log("Amount: ", i, "Price: ", price);
        }
    }
}
