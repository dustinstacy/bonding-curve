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
    uint256 supply = 0;
    uint256 initialCost = 0.001 ether;
    uint256 scalingFactor = 10000;
    uint256 amount = 100;
    uint256 singleToken = 1;

    modifier onlyForSupplyGreaterThanZero() {
        if (supply == 0) {
            return;
        }
        _;
    }

    function setUp() public {
        expCurve = new ExponentialBondingCurve();
        ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
    }

    function test_EXP_BC_GetFirstTokenPrice() public view {
        uint256 actualPrice = expCurve.getRawPrice(0, initialCost, scalingFactor, singleToken);

        console.log("Price: ", actualPrice, "Expected Price: ", initialCost);
        assertEq(actualPrice, initialCost);
    }

    function test_EXP_BC_GetAnyTokenBeyondFirstTokenPrice() public view onlyForSupplyGreaterThanZero {
        uint256 actualPrice = expCurve.getRawPrice(supply, initialCost, scalingFactor, singleToken);

        uint256 sum1 = (supply - 1) * (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = (supply - 1 + singleToken) * (supply + singleToken) * (2 * (supply - 1 + singleToken) + 1) / 6;
        uint256 totalSum = sum2 - sum1;
        uint256 expectedPrice = (totalSum * initialCost / (scalingFactor)) + initialCost * singleToken;

        console.log("Price: ", actualPrice, "Expected Price: ", expectedPrice);
        assertEq(actualPrice, expectedPrice);
    }

    function test_EXP_BC_GetBulkTokenPrice() public view {
        uint256 actualPrice = expCurve.getRawPrice(supply, initialCost, scalingFactor, amount);

        uint256 expectedPrice;
        for (uint256 i = 0; i < amount; i++) {
            expectedPrice += expCurve.getRawPrice(supply + i, initialCost, scalingFactor, singleToken);
        }

        console.log("Price: ", actualPrice, "Expected Price: ", expectedPrice);
        // Using the sum of squares in getRawPrice() results in values that extend beyond the precision of the solidity.
        // For each token accounted for in a batch getRawPrice() call, there is a loss of precision of around .5 wei.
        // This is due to the nature of the calculations in the contract and the limitations of the EVM.
        // To account for this, we will use an approximate equality check with a margin of error of half the amount of tokens.
        assertApproxEqAbs(actualPrice, expectedPrice, (amount / 2));
    }
}
