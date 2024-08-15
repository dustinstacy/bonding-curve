// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";

contract LinearBondingCurveTest is Test {
    LinearBondingCurve public linCurve;

    // Test Variables
    uint256 supply;
    uint256 reserverBalance;
    uint256 value;
    uint256 amount;

    // Update tests to incorporate fees!

    function setUp() public {
        linCurve = new LinearBondingCurve();
        linCurve.setInitialCost(1 ether);
    }

    function test_SolveForN() public {
        supply = 1e18;
        reserverBalance = 1e18;
        value = 25e17;

        (uint256 test, uint256 fees) = linCurve.calculatePurchaseReturn(supply, reserverBalance, value);
    }

    // function test_LIN_BC_MintFirstWholeToken() public {
    //     supply = 0;
    //     value = initialCost;

    //     uint256 actualReturn = linCurve.calculatePurchaseReturn(supply, initialCost, value);
    //     uint256 expectedReturn = 1e18;

    //     assertEq(actualReturn, expectedReturn);
    // }

    // function test_LIN_BC_MintFirstPieceOfToken() public {
    //     supply = 0;
    //     value = initialCost / 2;

    //     uint256 actualReturn = linCurve.calculatePurchaseReturn(supply, initialCost, value);
    //     uint256 expectedReturn = 5e17;

    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);
    // }

    // function test_LIN_BC_MintSecondPieceOfTokenLessThanSupplyOfOne() public {
    //     supply = 0;
    //     value = initialCost / 2;

    //     uint256 actualReturn = linCurve.calculatePurchaseReturn(supply, initialCost, value);
    //     uint256 expectedReturn = 5e17;

    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);

    //     supply = 5e17;
    //     value = initialCost / 2;

    //     actualReturn = linCurve.calculatePurchaseReturn(supply, initialCost, value);
    //     expectedReturn = 5e17;

    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);
    // }

    // function test_LIN_BC_MintSecondWholeToken() public {
    //     supply = 1e18;
    //     value = initialCost * 2;

    //     uint256 actualReturn = linCurve.calculatePurchaseReturn(supply, initialCost, value);
    //     uint256 expectedReturn = 1e18;

    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);
    // }

    // function test_LIN_BC_MintPartialToken() public {
    //     supply = 1e18;
    //     value = initialCost;

    //     uint256 actualReturn = linCurve.calculatePurchaseReturn(supply, initialCost, value);
    //     uint256 expectedReturn = 5e17;

    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);
    // }

    // function test_LIN_BC_MintLargeValueAndSupply() public {
    //     supply = 3523.68e18;
    //     value = 13e18;

    //     uint256 actualReturn = linCurve.calculatePurchaseReturn(supply, initialCost, value);

    //     // Expected value calculated using the formula:
    //     //     currentDiscreetTokenPrice = initialCost + (((supply / PRECISION) * tokenPriceIncrement)) =
    //     //     0.001 ether + (((3523_680_000_000_000_000_000 / 1_000_000_000_000_000_000) * 0.001 ether))
    //     //     currentDiscreetTokenPrice = 3_524_000_000_000_000_000

    //     //     uint256 percentDiscreetTokenRemaining = (PRECISION - supply % PRECISION) =
    //     //     (1_000_000_000_000_000_000 - 3523_680_000_000_000_000_000 % 1_000_000_000_000_000_000)
    //     //     percentDiscreetTokenRemaining = _320_000_000_000_000_000 (32%)

    //     //     uint256 remainingCurrentDiscreetTokenPrice = (percentTokenRemaining * currentPrice) / PRECISION =
    //     //     (_320_000_000_000_000_000 * 3_524_000_000_000_000_000) / 1_000_000_000_000_000_000 = 1_127_680_000_000_000_000
    //     //     remainingCurrentTokenPrice = 1_127_680_000_000_000_000

    //     // Enter while loop
    //     // value = 13_000_000_000_000_000_000;
    //     // while (value > 0) {
    //     // if (remainingCurrentDiscreetTokenPrice < currentDiscreetTokenPrice) {
    //     //     rawPurchaseReturn += PRECISION * value / currentDiscreetTokenPrice; // Partial token purchased
    //     //     supply += (PRECISION * percentDiscreetTokenRemaining); // Move to the next token
    //     //     currentDiscreetTokenPrice = initialCost + ((supply / PRECISION) * tokenPriceIncrement);
    //     //     remainingCurrentDiscreetTokenPrice = currentDiscreetTokenPrice;
    //     //     percentDiscreetTokenRemaining = (PRECISION - supply % PRECISION);
    //     //     break;
    //     // } else if (value < remainingCurrentDiscreetTokenPrice) {
    //     //     rawPurchaseReturn += (value * PRECISION) / remainingCurrentDiscreetTokenPrice;
    //     //     break;
    //     // } else {
    //     //     value -= remainingCurrentDiscreetTokenPrice;
    //     //     rawPurchaseReturn += PRECISION; // Whole token purchased
    //     //     supply += PRECISION; // Move to the next token
    //     //     currentDiscreetTokenPrice = initialCost + ((supply / PRECISION) * tokenPriceIncrement);
    //     // }

    //     // Each pass through the loop:
    //     // if 1 {
    //     // value = 13_000_000_000_000_000_000 - 1_127_680_000_000_000_000 = 11_872_320_000_000_000_000
    //     // rawPurchaseReturn = _320_000_000_000_000_000
    //     // supply = 3523_680_000_000_000_000_000 + _320_000_000_000_000_000 = 3_524_000_000_000_000_000;
    //     // currentDiscreetTokenPrice = 0.001 ether + ((3_524_000_000_000_000_000 / 10e18) * 0.001 ether) = 3_525_000_000_000_000_000 (Token 3525)
    //     // remainingCurrentDiscreetTokenPrice = 3_525_000_000_000_000_000
    //     // percentDiscreetTokenRemaining = 1_000_000_000_000_000_000 - 3525e18 % 1_000_000_000_000_000_000 = 1_000_000_000_000_000_000 (100%)
    //     // break;
    //     //}

    //     // else 1 {
    //     //  value = 11_872_320_000_000_000_000 - 3_525_000_000_000_000_000 = 8_347_320_000_000_000_000
    //     //  rawPurchaseReturn = 1_000_000_000_000_000_000 + _320_000_000_000_000_000 = 1_320_000_000_000_000_000
    //     //  supply = 3_524_000_000_000_000_000 + 1_000_000_000_000_000_000 = 3_525_000_000_000_000_000
    //     //  currentDiscreetTokenPrice = 0.001 ether + (3_525_000_000_000_000_000 / 10e18) * 0.001 ether = 3_526_000_000_000_000_000 (Token 3526)
    //     // }

    //     // else 2 {
    //     //  value = 8_347_320_000_000_000_000 - 3_526_000_000_000_000_000 = 4_821_320_000_000_000_000
    //     //  rawPurchaseReturn = 1_320_000_000_000_000_000 + 1_000_000_000_000_000_000 = 2_320_000_000_000_000_000
    //     //  supply = 3_525_000_000_000_000_000 + 1_000_000_000_000_000_000 = 3_526_000_000_000_000_000
    //     //  currentDiscreetTokenPrice = 0.001 ether + (3_526_000_000_000_000_000 / 10e18) * 0.001 ether = 3_527_000_000
    //     // }

    //     // else 3 {
    //     //  value = 4_821_320_000_000_000_000 - 3_527_000_000_000_000_000 = 1_294_320_000_000_000_000
    //     //  rawPurchaseReturn = 2_320_000_000_000_000_000 + 1_000_000_000_000_000_000 = 3_320_000_000_000_000_000
    //     //  supply = 3_526_000_000_000_000_000 + 1_000_000_000_000_000_000 = 3_527_000_000_000_000_000
    //     //  currentDiscreetTokenPrice = 0.001 ether + (3_527_000_000_000_000_000 / 10e18) * 0.001 ether = 3_528_000_000_000_000_000
    //     // }

    //     // else if {
    //     //  rawPurchaseReturn = rawPurchaseReturn + (1_294_320_000_000_000_000 * 1_000_000_000_000_000_000 / 3_528_000_000_000_000_000)=
    //     //  3_320_000_000_000_000_000 + 366_870_748_299_319_727 = 3_686_870_748_299_319_727
    //     //  supply = 3_527_000_000_000_000_000 + 366_870_748_299_319_727 = 3_527_366_870_748_299_319_727;
    //     //}

    //     // expectedReturn = 3_686_870_748_299_319_727
    //     // expectedSupply = 3_527_366_870_748_299_319_727;

    //     uint256 expectedReturn = 3686870748299319727; // 3.686870748299319727
    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);
    //     uint256 expectedSupply = 3527366870748299319727; // 3.527366870748299319727
    //     console2.log("New Supply: ", supply + expectedReturn, "Expected Supply: ", expectedSupply);
    //     assertEq(supply + expectedReturn, expectedSupply);
    // }

    // function test_LIN_BC_GetNextFullTokenPrice() public {
    //     supply = 0;

    //     uint256 actualValue = linCurve.calculateReserveTokensNeeded(supply, initialCost);
    //     uint256 expectedValue = initialCost;

    //     console2.log("Value: ", actualValue, "Expected Value: ", expectedValue);
    //     assertEq(actualValue, expectedValue);
    // }

    // function test_LIN_BC_GetNextFullTokenPriceTwo() public {
    //     supply = 0.5e18;

    //     uint256 actualValue = linCurve.calculateReserveTokensNeeded(supply, initialCost);
    //     uint256 expectedValue = 0.0015 ether;

    //     console2.log("Value: ", actualValue, "Expected Value: ", expectedValue);
    //     assertEq(actualValue, expectedValue);
    // }

    // function test_LIN_BC_GetNextFullTokenPriceThree() public {
    //     supply = 145.8e18;

    //     uint256 actualValue = linCurve.calculateReserveTokensNeeded(supply, initialCost);

    //     // Expected value calculated using the formula:
    //     // currentDiscreteTokenPrice = initialCost + (((currentSupply / PRECISION) * tokenPriceIncrement));
    //     // percentDiscreteTokenRemaining = (PRECISION - currentSupply % PRECISION);
    //     // remainingCurrentDiscreteTokenPrice = (percentDiscreteTokenRemaining * currentDiscreteTokenPrice) / PRECISION;

    //     // if (remainingCurrentDiscreteTokenPrice < currentDiscreteTokenPrice) {
    //     //     reserveTokensNeeded += remainingCurrentDiscreteTokenPrice;
    //     //     currentSupply += PRECISION;
    //     //     currentDiscreteTokenPrice = initialCost + ((currentSupply / PRECISION) * tokenPriceIncrement);
    //     //     uint256 percentNextDiscreteTokenRemaining = (PRECISION - percentDiscreteTokenRemaining % PRECISION);
    //     //     remainingCurrentDiscreteTokenPrice =
    //     //         (percentNextDiscreteTokenRemaining * currentDiscreteTokenPrice) / PRECISION;
    //     //     reserveTokensNeeded += remainingCurrentDiscreteTokenPrice;
    //     // } else {
    //     //     reserveTokensNeeded = currentDiscreteTokenPrice;
    //     // }

    //     // currentDiscreteTokenPrice = 0.001 ether + (((145.8e18 / 1e18) * 0.001 ether) = 0.1468 ether
    //     // percentDiscreteTokenRemaining = 1e18 - 145.8e18 % 1e18 = _200_000_000_000_000_000 (20%)
    //     // remainingCurrentDiscreteTokenPrice = (200e18 * 0.1468 ether) / 1e18 = 0.0292 ether

    //     // if {
    //     // reserveTokensNeeded += 0.0292 ether
    //     // currentSupply += _200_000_000_000_000_000 = 146e18
    //     // currentDiscreteTokenPrice = 0.001 ether + ((146e18 / 1e18) * 0.001 ether) = 0.147 ether
    //     // percentNextDiscreteTokenRemaining = 1e18 - _200_000_000_000_000_000 % 1e18 = 800e18 (80%)
    //     // remainingCurrentDiscreteTokenPrice = (800e18 * 0.147 ether) / 1e18 = 0.1176 ether
    //     // reserveTokensNeeded += 0.1176 ether
    //     // total = 0.0292 ether + 0.1176 ether = 0.1468 ether
    //     uint256 expectedValue = 0.1468 ether;

    //     console2.log("Value: ", actualValue, "Expected Value: ", expectedValue);
    //     assertEq(actualValue, expectedValue);
    // }

    // function test_LIN_BC_SellTokenOne() public {
    //     supply = 1e18;
    //     amount = 1e18;

    //     uint256 actualReturn = linCurve.calculateSaleReturn(supply, initialCost, amount);
    //     uint256 expectedReturn = initialCost;

    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);
    // }

    // function test_LIN_BC_SellTokenTwo() public {
    //     supply = 2e18;
    //     amount = 1e18;

    //     uint256 actualReturn = linCurve.calculateSaleReturn(supply, initialCost, amount);
    //     uint256 expectedReturn = initialCost * 2;

    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);
    // }

    // function test_LIN_BC_SellFirstPieceOfToken() public {
    //     supply = 1e18;
    //     amount = 5e17;

    //     uint256 actualReturn = linCurve.calculateSaleReturn(supply, initialCost, amount);
    //     uint256 expectedReturn = initialCost / 2;

    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);
    // }

    // function test_LIN_BC_SellSecondPieceOfToken() public {
    //     supply = 1e18;
    //     amount = 5e17;

    //     uint256 actualReturn = linCurve.calculateSaleReturn(supply, initialCost, amount);
    //     uint256 expectedReturn = initialCost / 2;

    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);

    //     supply = 5e17;
    //     amount = 5e17;

    //     actualReturn = linCurve.calculateSaleReturn(supply, initialCost, amount);
    //     expectedReturn = initialCost / 2;

    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);
    // }

    // function test_LIN_BC_SellDownToZero() public {
    //     supply = 2e18;
    //     amount = 2e18;

    //     uint256 actualReturn = linCurve.calculateSaleReturn(supply, initialCost, amount);
    //     uint256 expectedReturn = initialCost * 3;

    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);
    // }

    // function test_LIN_BC_SellLargeValueAndSupply() public {
    //     supply = 3523.68e18;
    //     amount = 13e18;

    //     // looooong math not shown here
    //     uint256 expectedReturn = 93842680000000000000; // 93.84268
    //     uint256 actualReturn = linCurve.calculateSaleReturn(supply, initialCost, amount);

    //     console2.log("Return: ", actualReturn, "Expected Return: ", expectedReturn);
    //     assertEq(actualReturn, expectedReturn);

    //     uint256 expectedSupply = 3510680000000000000000; // 3.51068
    //     uint256 newSupply = supply - amount;
    //     console2.log("New Supply: ", newSupply, "Expected Supply: ", expectedSupply);
    //     assertEq(newSupply, expectedSupply);
    // }
}
