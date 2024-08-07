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
    uint256 initialCost = 0.001 ether;
    uint256 scalingFactor = 3000;

    // Test Variables;
    uint256 supply;
    uint256 reserveBalance;
    uint256 value;
    uint256 reserveRatio;

    // modifier onlyForSupplyGreaterThanZero() {
    //     if (supply == 0) {
    //         console.log("Supply is zero. Adjust arguments to validate this test.");
    //         return;
    //     }
    //     _;
    // }

    // modifier onlyForSupplyGreaterThanAmount() {
    //     if (supply < amount) {
    //         console.log("Supply is less than amount. Adjust arguments to validate this test.");
    //         return;
    //     }
    //     _;
    // }

    function setUp() public {
        expCurve = new ExponentialBondingCurve();
        ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
    }

    function test_EXP_BC_GetFirstTokenBuyPrice() public {
        supply = 2.32e18;
        reserveBalance = 0.0011 ether;
        // 2_000_000_000_000_000_000
        value = 0.001 ether;
        reserveRatio = 4000;

        // _017_716_363_636_363_635

        // _442_909_090_909_090_908

        // 1_320_000_000_000_000_000

        // _180_000_000_000_000_000

        // _200_000_000_000_000_000

        // _120_000_000_000_000_000

        // _066_000_000_000_000_000

        // _006_600_000_000_000_000

        // 12_000_000_000_000_000

        // _004_000_000_000_000_000

        // 3_000_000_000_000_000_000

        // _012_000_000_000_000_000

        uint256 actualReturn = expCurve.getRawPurchaseReturn(supply, reserveBalance, value, reserveRatio);
        console.log("Return: ", actualReturn);
        // _005_999_999_999_999_999
        // _008_999_999_999_999_999
        // _003_026_699_999_999_998
        // _032_999_999_999_999_999
        // _303_000_000_000_000_000
        // 3_003_000_000_000_000_000
        // _064_000_000_000_000_000
    }

    // function test_EXP_BC_GetAnyTokenBeyondFirstTokenBuyPrice() public view onlyForSupplyGreaterThanZero {
    //     uint256 actualPrice = expCurve.getRawBuyPrice(supply, initialCost, scalingFactor, singleToken);

    //     uint256 sum1 = (supply - 1) * (supply) * (2 * (supply - 1) + 1) / 6;
    //     uint256 sum2 = (supply - 1 + singleToken) * (supply + singleToken) * (2 * (supply - 1 + singleToken) + 1) / 6;
    //     uint256 totalSum = sum2 - sum1;
    //     uint256 expectedPrice = (totalSum * initialCost / (scalingFactor)) + initialCost * singleToken;

    //     console.log("Price: ", actualPrice, "Expected Price: ", expectedPrice);
    //     assertEq(actualPrice, expectedPrice);
    // }

    // function test_EXP_BC_GetBulkTokenBuyPrice() public view {
    //     uint256 actualPrice = expCurve.getRawBuyPrice(supply, initialCost, scalingFactor, amount);

    //     uint256 expectedPrice;
    //     for (uint256 i = 0; i < amount; i++) {
    //         expectedPrice += expCurve.getRawBuyPrice(supply + i, initialCost, scalingFactor, singleToken);
    //     }

    //     // 10028500000000000
    //     console.log("Price: ", actualPrice, "Expected Price: ", expectedPrice);
    //     // Using the sum of squares in getRawBuyPrice() results in values that extend beyond the precision of the solidity.
    //     // For each token accounted for in a batch getRawBuyPrice() call, there is a loss of precision of around .5 wei.
    //     // This is due to the nature of the calculations in the contract and the limitations of the EVM.
    //     // To account for this, we will use an approximate equality check with a margin of error of half the amount of tokens.
    //     assertApproxEqAbs(actualPrice, expectedPrice, (amount / 2));
    // }

    // function test_EXP_BC_GetFirstTokenSellPrice() public view {
    //     uint256 actualPrice = expCurve.getRawSellPrice(1, initialCost, scalingFactor, singleToken);
    //     console.log("Price: ", actualPrice, "Expected Price: ", initialCost);
    //     assertEq(actualPrice, initialCost);
    // }

    // function test_EXP_BC_GetAnyTokenBeyondFirstTokenSellPrice() public view onlyForSupplyGreaterThanZero {
    //     uint256 actualPrice = expCurve.getRawSellPrice(supply, initialCost, scalingFactor, singleToken);
    //     uint256 expectedPrice = expCurve.getRawBuyPrice(supply - 1, initialCost, scalingFactor, singleToken);

    //     console.log("Price: ", actualPrice, "Expected Price: ", expectedPrice);
    //     assertEq(actualPrice, expectedPrice);
    // }

    // function test_EXP_BC_GetBulkTokenSellPrice() public view onlyForSupplyGreaterThanAmount {
    //     uint256 actualPrice = expCurve.getRawSellPrice(supply, initialCost, scalingFactor, amount);
    //     uint256 expectedPrice = expCurve.getRawBuyPrice(supply - amount, initialCost, scalingFactor, amount);

    //     console.log("Price: ", actualPrice, "Expected Price: ", expectedPrice);
    //     // Using the sum of squares in getRawSellPrice() results in values that extend beyond the precision of the solidity.
    //     // For each token accounted for in a batch getRawSellPrice() call, there is a loss of precision of around .5 wei.
    //     // This is due to the nature of the calculations in the contract and the limitations of the EVM.
    //     // To account for this, we will use an approximate equality check with a margin of error of half the amount of tokens.
    //     assertApproxEqAbs(actualPrice, expectedPrice, (amount / 2));
    // }
}
