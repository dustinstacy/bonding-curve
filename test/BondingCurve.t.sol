// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BondingCurve} from "src/BondingCurve.sol";
import {SimpleCoin} from "src/token/SimpleCoin.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {Calculations} from "src/libraries/Calculations.sol";

contract BondingCurveTest is Test {
    BondingCurve public bc;
    SimpleCoin public sc;

    address public user = makeAddr("user");
    address public user2 = makeAddr("user2");

    function setUp() public {
        sc = new SimpleCoin();
        bc = new BondingCurve(address(sc), 50000);
        vm.deal(user, 1 ether);
        vm.deal(user2, 1 ether);
    }

    modifier buyToken() {
        uint256 currentPrice = bc.getPrice(1);
        vm.prank(user);
        bc.buyTokens{value: currentPrice}(1);
        _;
    }

    function test_BuyTokens() public {
        uint256 startingBalance = sc.balanceOf(user);
        uint256 startingEther = address(user).balance;
        uint256 currentPrice = bc.getPrice(1);
        vm.prank(user);
        bc.buyTokens{value: currentPrice}(1);
        uint256 endingBalance = sc.balanceOf(user);
        uint256 endingEther = address(user).balance;
        console.log("Starting Balance: ", startingBalance);
        console.log("Ending Balance: ", endingBalance);
        console.log("Starting Ether: ", startingEther);
        console.log("Ending Ether: ", endingEther);
        assertEq(endingBalance, 1);
    }

    function test_BuyTokensCurve() public {
        for (uint256 i = 1; i < 10; i++) {
            address newUser = address(uint160(i));
            hoax(newUser, 1 ether);
            uint256 currentPrice = bc.getPrice(1);
            console.log("Current Price ", i, " :", currentPrice);
            bc.buyTokens{value: currentPrice}(1);
            console.log("Reserve Balance ", i, " :", bc.reserveBalance());
            console.log("Total Supply ", i, " :", bc.totalSupply());
        }
    }

    function test_SellTokens() public buyToken {
        uint256 startingBalance = sc.balanceOf(user);
        uint256 startingEther = address(user).balance;

        vm.startPrank(user);
        sc.approve(address(bc), 1);
        bc.sellTokens(1);
        vm.stopPrank();
        uint256 endingBalance = sc.balanceOf(user);
        uint256 endingEther = address(user).balance;
        console.log("Starting Balance: ", startingBalance);
        console.log("Ending Balance: ", endingBalance);
        console.log("Starting Ether: ", startingEther);
        console.log("Ending Ether: ", endingEther);
        assertEq(endingBalance, 0);
    }

    function test_SellTokensCurve() public {
        for (uint256 i = 1; i < 10; i++) {
            address newUser = address(uint160(i));
            hoax(newUser, 1 ether);
            uint256 currentPrice = bc.getPrice(1);
            console.log("Current Price ", i, " :", currentPrice);
            bc.buyTokens{value: currentPrice}(1);
            console.log("Reserve Balance ", i, " :", bc.reserveBalance());
            console.log("Total Supply ", i, " :", bc.totalSupply());
        }
    }
}
