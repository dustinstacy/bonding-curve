// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SimpleProxy} from "src/SimpleProxy.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BondingCurve} from "src/BondingCurve.sol";
import {SimpleToken} from "src/SimpleToken.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {Calculations} from "src/libraries/Calculations.sol";

contract BondingCurveTest is Test {
    BondingCurve public curve;
    // SimpleProxy public proxy;
    ERC1967Proxy public proxy;
    SimpleToken public token;
    MockV3Aggregator ethUSDPriceFeed;

    uint8 private constant DECIMALS = 8;
    int256 private constant ETH_USD_PRICE = 3265;

    address public user = makeAddr("user");

    function setUp() public {
        curve = new BondingCurve();
        // proxy = new SimpleProxy();
        // proxy.setImplementation(address(curve));
        proxy = new ERC1967Proxy(address(curve), "");
        token = new SimpleToken("SimpleToken", "KISS", address(proxy), 5000, 0.001 ether);
        ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        vm.deal(user, 10 ether);
    }

    modifier buyToken() {
        uint256 currentPrice = curve.getPrice(token.totalSupply(), token.i_scalingFactor(), token.i_initialCost(), 1);
        vm.prank(user);
        token.buyTokens{value: currentPrice}(1);
        _;
    }

    function test_BuyTokens() public {
        uint256 startingBalance = token.balanceOf(user);
        uint256 startingEther = address(user).balance;
        uint256 tokensToBuy = 10;
        uint256 currentPrice =
            curve.getPrice(token.totalSupply(), token.i_scalingFactor(), token.i_initialCost(), tokensToBuy);
        console.log("CurrentPrice", currentPrice);
        vm.prank(user);
        token.buyTokens{value: currentPrice}(tokensToBuy);
        uint256 endingBalance = token.balanceOf(user);
        uint256 endingEther = address(user).balance;
        uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), currentPrice);
        console.log("Converted price: ", convertedPrice);

        console.log("Starting Balance: ", startingBalance);
        console.log("Ending Balance: ", endingBalance);
        console.log("Starting Ether: ", startingEther);
        console.log("Ending Ether: ", endingEther);
        assertEq(endingBalance, tokensToBuy);
    }

    function test_BuyTokenCurve() public {
        for (uint256 i = 1; i < 102; i++) {
            address newUser = address(uint160(i));
            hoax(newUser, 1 ether);
            uint256 currentPrice =
                curve.getPrice(token.totalSupply(), token.i_scalingFactor(), token.i_initialCost(), 1);
            uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), currentPrice);
            console.log("Total Supply: ", token.totalSupply(), "Converted price: ", convertedPrice);
            token.buyTokens{value: currentPrice}(1);
            console.log("New Total Supply: ", token.totalSupply());
        }
    }

    // function test_SellTokens() public {
    //     uint256 startingBalance = token.balanceOf(user);
    //     uint256 startingEther = address(user).balance;

    //     uint256 currentPrice = curve.getPrice(token.totalSupply(), token.i_scalingFactor(), token.i_initialCost(), 1);
    //     vm.prank(user);
    //     token.buyTokens{value: currentPrice}(1);

    //     vm.startPrank(user);
    //     token.approve(address(user), 1);
    //     token.sellTokens(1);
    //     vm.stopPrank();
    //     uint256 endingBalance = token.balanceOf(user);
    //     uint256 endingEther = address(user).balance;
    //     console.log("Starting Balance: ", startingBalance);
    //     console.log("Ending Balance: ", endingBalance);
    //     console.log("Starting Ether: ", startingEther);
    //     console.log("Ending Ether: ", endingEther);
    //     assertEq(endingBalance, 0);
    // }

    // function test_SellTokensCurve() public {
    //     for (uint256 i = 1; i < 10; i++) {
    //         address newUser = address(uint160(i));
    //         hoax(newUser, 1 ether);
    //         uint256 currentPrice =
    //             curve.getPrice(token.totalSupply(), token.i_scalingFactor(), token.i_initialCost(), 1);
    //         token.buyTokens{value: currentPrice}(1);
    //         uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), currentPrice);
    //         console.log("Amount: ", i + 1, "Converted price: ", convertedPrice);
    //     }

    //     for (uint256 i = 1; i < 10; i++) {
    //         address newUser = address(uint160(i));
    //         hoax(newUser, 1 ether);
    //         uint256 currentPrice =
    //             curve.getPrice(token.totalSupply(), token.i_scalingFactor(), token.i_initialCost(), 1);
    //         console.log("Supply: ", token.totalSupply());
    //         token.buyTokens{value: currentPrice}(1);
    //         uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), currentPrice);
    //         console.log("Converted price: ", convertedPrice);
    //     }
    // }
}
