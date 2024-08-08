// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ExponentialBondingCurve} from "src/ExponentialBondingCurve.sol";

contract ExponentialBondingCurveTest is Test {
    ExponentialBondingCurve public expCurve;

    uint8 private constant DECIMALS = 8;
    int256 private constant ETH_USD_PRICE = 3265;

    // Test Variables;
    uint256 supply;
    uint256 reserveBalance;
    uint256 value;
    uint256 reserveRatio;
    uint256 tokensToReturn;

    function setUp() public {
        expCurve = new ExponentialBondingCurve();
    }

    function test_EXP_BC_CalculatePurchaseReturn() public {
        supply = 1e18;
        reserveBalance = 0.0001 ether;
        reserveRatio = 500000;
        value = 0.0001 ether;
        tokensToReturn = 1e18;

        //reserveRatio = 500000 (50%)
        //value = 100000000000000
        //fraction = 1000000000000000000
        //base = 2000000000000000000
        //exp = 1000000000000000000
        //expected return = 1000000000000000000

        uint256 neededValueForExpectedReturn =
            expCurve.calculateReserveTokensNeeded(supply, reserveBalance, tokensToReturn, reserveRatio);
        uint256 actualReturn = expCurve.calculatePurchaseReturn(supply, reserveBalance, value, reserveRatio);
        assertEq(neededValueForExpectedReturn, value);
        assertEq(actualReturn, tokensToReturn);
    }

    function test_EXP_BC_CalculatePurchaseReturnTwo() public {
        supply = 1e18;
        reserveBalance = 0.0001 ether;
        reserveRatio = 400000;
        value = 0.00015 ether;
        tokensToReturn = 1e18;

        //reserveRatio = 500000 (40%)
        //value = 150000000000000
        //fraction = 1500000000000000000
        //base = 2500000000000000000
        //exp = 1000000000000000000
        //expected return = 1000000000000000000

        uint256 neededValueForExpectedReturn =
            expCurve.calculateReserveTokensNeeded(supply, reserveBalance, tokensToReturn, reserveRatio);
        uint256 actualReturn = expCurve.calculatePurchaseReturn(supply, reserveBalance, value, reserveRatio);
        assertEq(neededValueForExpectedReturn, value);
        assertEq(actualReturn, tokensToReturn);
    }

    function test_EXP_BC_CalculatePurchaseReturnThree() public {
        supply = 1e18;
        reserveBalance = 0.0001 ether;
        reserveRatio = 813000;
        value = 23001230012300;
        tokensToReturn = 1e18;

        //reserveRatio = 813000 (81.3%)
        //value = 23001230012300
        //fraction = 23001230012300000000
        //base = 2500000000000000000
        //exp = 1000000000000000000
        //expected return = 1000000000000000000

        uint256 neededValueForExpectedReturn =
            expCurve.calculateReserveTokensNeeded(supply, reserveBalance, tokensToReturn, reserveRatio);
        uint256 actualReturn = expCurve.calculatePurchaseReturn(supply, reserveBalance, value, reserveRatio);
        assertEq(neededValueForExpectedReturn, value);
        assertApproxEqRel(actualReturn, tokensToReturn, 1e4);
    }

    function test_EXP_BC_GetFirstTokenMintPrice() public {
        supply = 1e18;
        reserveBalance = 0.0001 ether;
        reserveRatio = 500000;
        tokensToReturn = 1e18;
        value = 0.0001 ether;

        //reserveRatio = 500000 (50%)
        //return =  1000000000000000000
        //exp = 1000000000000000000
        //base = 2000000000000000000
        //fraction = 1000000000000000000
        //expected value = 100000000000000

        uint256 neededReturnForExpectedValue =
            expCurve.calculatePurchaseReturn(supply, reserveBalance, value, reserveRatio);
        uint256 actualValue =
            expCurve.calculateReserveTokensNeeded(supply, reserveBalance, tokensToReturn, reserveRatio);
        assertEq(neededReturnForExpectedValue, tokensToReturn);
        assertEq(actualValue, value);
    }

    function test_EXP_BC_GetFirstTokenMintPriceTwo() public {
        supply = 1e18;
        reserveBalance = 0.0001 ether;
        reserveRatio = 400000;
        tokensToReturn = 1e18;
        value = 0.00015 ether;

        //reserveRatio = 400000 (40%)
        //return = 1000000000000000000
        //exp = 1000000000000000000
        //base = 2500000000000000000
        //fraction = 1500000000000000000
        //expected value = 150000000000000;

        uint256 neededReturnForExpectedValue =
            expCurve.calculatePurchaseReturn(supply, reserveBalance, value, reserveRatio);
        uint256 actualValue =
            expCurve.calculateReserveTokensNeeded(supply, reserveBalance, tokensToReturn, reserveRatio);
        assertEq(neededReturnForExpectedValue, tokensToReturn);
        assertEq(actualValue, value);
    }

    function test_EXP_BC_GetFirstTokenMintPriceThree() public {
        supply = 1e18;
        reserveBalance = 0.0001 ether;
        reserveRatio = 813000;
        tokensToReturn = 1e18;
        value = 23001230012300;

        //reserveRatio = 813000 (81.3%)
        //return = 1000000000000000000
        //exp = 1000000000000000000
        //base = 2500000000000000000
        //fraction = 23001230012300000000
        //expected value = 23001230012300;

        uint256 neededReturnForExpectedValue =
            expCurve.calculatePurchaseReturn(supply, reserveBalance, value, reserveRatio);
        uint256 actualValue =
            expCurve.calculateReserveTokensNeeded(supply, reserveBalance, tokensToReturn, reserveRatio);
        assertApproxEqRel(neededReturnForExpectedValue, tokensToReturn, 1e4);
        assertEq(actualValue, value);
    }

    function test_EXP_BC_CalculateBurnTokenOne() public {
        // starting varaibles
        supply = 1e18;
        reserveBalance = 0.0001 ether;
        reserveRatio = 500000;
        value = 0.0001 ether;
        tokensToReturn = 1e18;

        uint256 tokensMinted = expCurve.calculatePurchaseReturn(supply, reserveBalance, value, reserveRatio);
        uint256 costOfToken =
            expCurve.calculateReserveTokensNeeded(supply, reserveBalance, tokensToReturn, reserveRatio);
        uint256 newSupply = supply + tokensMinted;
        uint256 newReserveBalance = reserveBalance + value;

        //sell 1 token
        uint256 tokensToBurn = 1e18;

        uint256 saleValue = expCurve.calculateSaleReturn(newSupply, newReserveBalance, tokensToBurn, reserveRatio);
        assertEq(saleValue, costOfToken);
        assertEq(supply, newSupply - tokensToBurn);
    }

    function test_EXP_BC_CalculateBurnTokenTwo() public {
        // starting varaibles
        supply = 5e18;
        reserveBalance = 0.0002 ether;
        reserveRatio = 500000;
        value = 0.005 ether;

        uint256 tokensMinted = expCurve.calculatePurchaseReturn(supply, reserveBalance, value, reserveRatio);
        //   tokensMinted results:
        //   fraction:  25000000000000000000
        //   base:  26000000000000000000
        //   exp:  13000000000000000000
        //   purchaseReturn:  65000000000000000000

        uint256 newSupply = supply + tokensMinted;
        uint256 newReserveBalance = reserveBalance + value;

        //sell minted tokens
        uint256 tokensToBurn = tokensMinted;

        uint256 saleValue = expCurve.calculateSaleReturn(newSupply, newReserveBalance, tokensToBurn, reserveRatio);
        console.log("saleValue: ", saleValue);
        assertEq(saleValue, value);
        assertEq(supply, newSupply - tokensToBurn);
    }
}
