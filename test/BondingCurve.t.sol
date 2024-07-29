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

    address public user = makeAddr("user");
    address public user2 = makeAddr("user2");

    function setUp() public {
        curve = new BondingCurve();
        // proxy = new SimpleProxy();
        // proxy.setImplementation(address(curve));
        proxy = new ERC1967Proxy(address(curve), "");
        token = new SimpleToken("SimpleToken", "KISS", address(proxy), 50000);
        vm.deal(user, 1 ether);
        vm.deal(user2, 1 ether);
    }

    modifier buyToken() {
        uint256 currentPrice = curve.getPrice(token.totalSupply(), token.reserveBalance(), token.reserveRatio(), 1);
        vm.prank(user);
        token.buyTokens{value: currentPrice}(1);
        _;
    }

    function test_BuyTokens() public {
        uint256 startingBalance = token.balanceOf(user);
        uint256 startingEther = address(user).balance;
        uint256 currentPrice = curve.getPrice(token.totalSupply(), token.reserveBalance(), token.reserveRatio(), 1);
        vm.prank(user);
        token.buyTokens{value: currentPrice}(1);
        uint256 endingBalance = token.balanceOf(user);
        uint256 endingEther = address(user).balance;
        console.log("Starting Balance: ", startingBalance);
        console.log("Ending Balance: ", endingBalance);
        console.log("Starting Ether: ", startingEther);
        console.log("Ending Ether: ", endingEther);
        assertEq(endingBalance, 1);
    }

    function test_BuyTokentokenurve() public {
        for (uint256 i = 1; i < 10; i++) {
            address newUser = address(uint160(i));
            hoax(newUser, 1 ether);
            uint256 currentPrice = curve.getPrice(token.totalSupply(), token.reserveBalance(), token.reserveRatio(), 1);
            console.log("Current Price ", i, " :", currentPrice);
            token.buyTokens{value: currentPrice}(1);
            console.log("Reserve Balance ", i, " :", token.reserveBalance());
            console.log("Total Supply ", i, " :", token.totalSupply());
        }
    }

    function test_SellTokensOneUser() public buyToken {
        uint256 startingBalance = token.balanceOf(user);
        uint256 startingEther = address(user).balance;

        vm.startPrank(user);
        token.approve(address(user), 1);
        token.sellTokens(1);
        vm.stopPrank();
        uint256 endingBalance = token.balanceOf(user);
        uint256 endingEther = address(user).balance;
        console.log("Starting Balance: ", startingBalance);
        console.log("Ending Balance: ", endingBalance);
        console.log("Starting Ether: ", startingEther);
        console.log("Ending Ether: ", endingEther);
        assertEq(endingBalance, 0);
    }

    function test_SellTokentokenurve() public {
        for (uint256 i = 1; i < 10; i++) {
            address newUser = address(uint160(i));
            hoax(newUser, 1 ether);
            uint256 currentPrice = curve.getPrice(token.totalSupply(), token.reserveBalance(), token.reserveRatio(), 1);
            console.log("Current Price ", i, " :", currentPrice);
            token.buyTokens{value: currentPrice}(1);
            console.log("Reserve Balance ", i, " :", token.reserveBalance());
            console.log("Total Supply ", i, " :", token.totalSupply());
        }
    }
}
