// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FriendtechSharesV1} from "src/references/FriendTechCurve.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {Calculations} from "src/libraries/Calculations.sol";

contract PriceGettersTest is Test {
    FriendtechSharesV1 ftCurve;
    MockV3Aggregator ethUSDPriceFeed;

    uint8 private constant DECIMALS = 0;
    int256 private constant ETH_USD_PRICE = 3265;

    function setUp() public {
        ftCurve = new FriendtechSharesV1();
        ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
    }

    function test_GetPrice() public view {
        uint256 scalingFactor = 100;
        for (uint256 i = 0; i < 10; i++) {
            uint256 price = ftCurve.getPrice(i, i + 1, scalingFactor);
            uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), price);
            console.log("Amount: ", i + 1, "Converted price: ", convertedPrice);
            console.log("Amount: ", i + 1, "Price: ", price);
        }
    }
}
