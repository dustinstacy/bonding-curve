// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {LinearBondingCurve} from "src/LinearBondingCurve.sol";

contract LinearBondingCurveTest is Test {
    LinearBondingCurve public linCurve;

    // Curve Variables
    uint256 scalingFactor = 10000; // True linear curve
    uint256 initialCost = 0.001 ether;

    // Test Variables
    uint256 supply;
    uint256 value;

    function setUp() public {
        linCurve = new LinearBondingCurve();
    }

    function test_LIN_BC_BuyFirstWholeToken() public {
        supply = 0;
        value = initialCost;

        uint256 actualReturn = linCurve.getRawPurchaseReturn(supply, initialCost, value);
        uint256 expectedReturn = 1e18;

        console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
        assertEq(actualReturn, expectedReturn);
    }

    function test_LIN_BC_BuyFirstPieceOfToken() public {
        supply = 0;
        value = initialCost / 2;

        uint256 actualReturn = linCurve.getRawPurchaseReturn(supply, initialCost, value);
        uint256 expectedReturn = 5e17;

        console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
        assertEq(actualReturn, expectedReturn);
    }

    function test_LIN_BC_BuySecondPieceOfTokenLessThanSupplyOfOne() public {
        supply = 0;
        value = initialCost / 2;

        uint256 actualReturn = linCurve.getRawPurchaseReturn(supply, initialCost, value);
        uint256 expectedReturn = 5e17;

        console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
        assertEq(actualReturn, expectedReturn);

        supply = 5e17;
        value = initialCost / 2;

        actualReturn = linCurve.getRawPurchaseReturn(supply, initialCost, value);
        expectedReturn = 5e17;

        console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
        assertEq(actualReturn, expectedReturn);
    }

    function test_LIN_BC_BuySecondWholeToken() public {
        supply = 1e18;
        value = initialCost * 2;

        uint256 actualReturn = linCurve.getRawPurchaseReturn(supply, initialCost, value);
        uint256 expectedReturn = 1e18;

        console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
        assertEq(actualReturn, expectedReturn);
    }

    function test_LIN_BC_BuyPartialToken() public {
        supply = 1e18;
        value = initialCost;

        uint256 actualReturn = linCurve.getRawPurchaseReturn(supply, initialCost, value);
        uint256 expectedReturn = 5e17;

        console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
        assertEq(actualReturn, expectedReturn);
    }

    function test_LIN_BC_LargeValueAndSupply() public {
        supply = 3523.68e18;
        value = 13e18;

        uint256 actualReturn = linCurve.getRawPurchaseReturn(supply, initialCost, value);

        // Expected value calculated using the formula:
        //     currentDiscreetTokenPrice = initialCost + (((supply / PRECISION) * tokenPriceIncrement)) =
        //     0.001 ether + (((3523_680_000_000_000_000_000 / 1_000_000_000_000_000_000) * 0.001 ether))
        //     currentDiscreetTokenPrice = 3_524_000_000_000_000_000

        //     uint256 percentDiscreetTokenRemaining = (PRECISION - supply % PRECISION) =
        //     (1_000_000_000_000_000_000 - 3523_680_000_000_000_000_000 % 1_000_000_000_000_000_000)
        //     percentDiscreetTokenRemaining = _320_000_000_000_000_000 (32%)

        //     uint256 remainingCurrentDiscreetTokenPrice = (percentTokenRemaining * currentPrice) / PRECISION =
        //     (_320_000_000_000_000_000 * 3_524_000_000_000_000_000) / 1_000_000_000_000_000_000 = 1_127_680_000_000_000_000
        //     remainingCurrentTokenPrice = 1_127_680_000_000_000_000

        // Enter while loop
        // value = 13_000_000_000_000_000_000;
        // while (value > 0) {
        // if (remainingCurrentDiscreetTokenPrice < currentDiscreetTokenPrice) {
        //     rawPurchaseReturn += PRECISION * value / currentDiscreetTokenPrice; // Partial token purchased
        //     supply += (PRECISION * percentDiscreetTokenRemaining); // Move to the next token
        //     currentDiscreetTokenPrice = initialCost + ((supply / PRECISION) * tokenPriceIncrement);
        //     remainingCurrentDiscreetTokenPrice = currentDiscreetTokenPrice;
        //     percentDiscreetTokenRemaining = (PRECISION - supply % PRECISION);
        //     break;
        // } else if (value < remainingCurrentDiscreetTokenPrice) {
        //     rawPurchaseReturn += (value * PRECISION) / remainingCurrentDiscreetTokenPrice;
        //     break;
        // } else {
        //     value -= remainingCurrentDiscreetTokenPrice;
        //     rawPurchaseReturn += PRECISION; // Whole token purchased
        //     supply += PRECISION; // Move to the next token
        //     currentDiscreetTokenPrice = initialCost + ((supply / PRECISION) * tokenPriceIncrement);
        // }

        // Each pass through the loop:
        // if 1 {
        // value = 13_000_000_000_000_000_000 - 1_127_680_000_000_000_000 = 11_872_320_000_000_000_000
        // rawPurchaseReturn = _320_000_000_000_000_000
        // supply = 3523_680_000_000_000_000_000 + _320_000_000_000_000_000 = 3_524_000_000_000_000_000;
        // currentDiscreetTokenPrice = 0.001 ether + ((3_524_000_000_000_000_000 / 10e18) * 0.001 ether) = 3_525_000_000_000_000_000 (Token 3525)
        // remainingCurrentDiscreetTokenPrice = 3_525_000_000_000_000_000
        // percentDiscreetTokenRemaining = 1_000_000_000_000_000_000 - 3525e18 % 1_000_000_000_000_000_000 = 1_000_000_000_000_000_000 (100%)
        // break;
        //}

        // else 1 {
        //  value = 11_872_320_000_000_000_000 - 3_525_000_000_000_000_000 = 8_347_320_000_000_000_000
        //  rawPurchaseReturn = 1_000_000_000_000_000_000 + _320_000_000_000_000_000 = 1_320_000_000_000_000_000
        //  supply = 3_524_000_000_000_000_000 + 1_000_000_000_000_000_000 = 3_525_000_000_000_000_000
        //  currentDiscreetTokenPrice = 0.001 ether + (3_525_000_000_000_000_000 / 10e18) * 0.001 ether = 3_526_000_000_000_000_000 (Token 3526)
        // }

        // else 2 {
        //  value = 8_347_320_000_000_000_000 - 3_526_000_000_000_000_000 = 4_821_320_000_000_000_000
        //  rawPurchaseReturn = 1_320_000_000_000_000_000 + 1_000_000_000_000_000_000 = 2_320_000_000_000_000_000
        //  supply = 3_525_000_000_000_000_000 + 1_000_000_000_000_000_000 = 3_526_000_000_000_000_000
        //  currentDiscreetTokenPrice = 0.001 ether + (3_526_000_000_000_000_000 / 10e18) * 0.001 ether = 3_527_000_000
        // }

        // else 3 {
        //  value = 4_821_320_000_000_000_000 - 3_527_000_000_000_000_000 = 1_294_320_000_000_000_000
        //  rawPurchaseReturn = 2_320_000_000_000_000_000 + 1_000_000_000_000_000_000 = 3_320_000_000_000_000_000
        //  supply = 3_526_000_000_000_000_000 + 1_000_000_000_000_000_000 = 3_527_000_000_000_000_000
        //  currentDiscreetTokenPrice = 0.001 ether + (3_527_000_000_000_000_000 / 10e18) * 0.001 ether = 3_528_000_000_000_000_000
        // }

        // else if {
        //  rawPurchaseReturn = rawPurchaseReturn + (1_294_320_000_000_000_000 * 1_000_000_000_000_000_000 / 3_528_000_000_000_000_000)=
        //  3_320_000_000_000_000_000 + 366_870_748_299_319_727 = 3_686_870_748_299_319_727
        //  supply = 3_527_000_000_000_000_000 + 366_870_748_299_319_727 = 3_527_366_870_748_299_319_727;
        //}

        // expectedReturn = 3_686_870_748_299_319_727
        // expectedSupply = 3_527_366_870_748_299_319_727;

        uint256 expectedReturn = 3686870748299319727; // 3.686870748299319727
        console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
        assertEq(actualReturn, expectedReturn);
        uint256 expectedSupply = 3527366870748299319727; // 3.527366870748299319727
        console2.log("New Supply: ", supply + expectedReturn, "Expected Supply: ", expectedSupply);
        assertEq(supply + expectedReturn, expectedSupply);
    }
}
