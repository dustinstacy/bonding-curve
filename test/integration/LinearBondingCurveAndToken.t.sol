//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {LinearBondingCurve} from "src/bonding-curves/LinearBondingCurve.sol";
import {LinearToken} from "src/bonding-curves/curve-tokens/LinearToken.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";
import {DeployLinearBondingCurve} from "script/deploy/DeployLinearBondingCurve.s.sol";
import {DeployLinearToken} from "script/interactions/LinearInteractions.s.sol";
import {CodeConstants} from "script/utils/HelperConfig.s.sol";

contract LinearBondingCurveAndTokenTest is Test, CodeConstants {
    LinearBondingCurve public linCurve;
    LinearToken public linToken;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    HelperConfig.CurveConfig public curveConfig;
    DeployLinearBondingCurve public curveDeployer;
    DeployLinearToken public tokenDeployer;
    address linProxy;

    // Token Contract Variables
    string public name = "HaTOKEN";
    string public symbol = "HTK";

    // Curve Variables;
    address public owner;
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public feeSharePercent;
    uint256 public initialReserve;
    uint256 public maxGasLimit;

    // Test Variables
    uint256 supply;
    uint256 reserve;
    uint256 value;
    uint256 amount;

    // Addresses
    address public host = makeAddr("host");
    address public user1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // User Balances
    uint256 STARTING_BALANCE = 1000 ether;
    uint256 public constant PRECISION = 1e18;

    function setUp() public {
        helperConfig = new HelperConfig();
        (curveConfig, networkConfig) = helperConfig.getConfig();
        owner = networkConfig.admin;
        curveDeployer = new DeployLinearBondingCurve();
        tokenDeployer = new DeployLinearToken();
        (linProxy, linCurve, helperConfig) = curveDeployer.run();

        protocolFeePercent = curveConfig.protocolFeePercent;
        feeSharePercent = curveConfig.feeSharePercent;
        initialReserve = curveConfig.initialReserve;
        maxGasLimit = curveConfig.maxGasLimit;

        vm.deal(host, STARTING_BALANCE);
        vm.deal(user1, STARTING_BALANCE);

        vm.prank(host);
        linToken = tokenDeployer.run{value: initialReserve}(name, symbol, linProxy, host);
    }

    function test_LinearTokenContractConstructor() public view {
        assertEq(linToken.name(), name);
        assertEq(linToken.symbol(), symbol);
        assertEq(linToken.totalSupply(), 1 ether);
        assertEq(linToken.reserveBalance(), initialReserve);
        assertEq(linToken.balanceOf(host), 1 ether);
        assertEq(linToken.balanceOf(address(this)), 0);
        assertEq(linToken.getBondingCurveProxyAddress(), address(linCurve));
    }

    function test_RevertsWhen_LinearTokenMintingWithoutValue() public {
        vm.expectRevert(LinearToken.LinearToken__AmountMustBeMoreThanZero.selector);
        linToken.mintTokens();
    }

    function test_LinearTokenUserMintAndBurnToken() public {
        // Set starting values
        supply = linToken.totalSupply();
        reserve = linToken.reserveBalance();
        uint256 startingProtocolBalance = owner.balance;

        // Calculate required value to mint 1 token
        (uint256 depositAmount, uint256 expectedFees) = linCurve.getMintCost(supply, reserve);

        // Set expected post mint values
        uint256 expectedReturn = 1e18;
        uint256 expectedSupply = supply + expectedReturn;
        uint256 expectedReserve = reserve + (depositAmount - expectedFees);
        uint256 expectedProtocolBalance = startingProtocolBalance + expectedFees;

        vm.prank(user1);
        linToken.mintTokens{value: depositAmount}();

        assertEq(linToken.totalSupply(), expectedSupply);
        assertEq(linToken.reserveBalance(), expectedReserve);
        assertEq(owner.balance, expectedProtocolBalance);
        assertEq(linToken.balanceOf(user1), expectedReturn);

        uint256 burnAmount = 1e18;
        uint256 userBalance = user1.balance;

        // Set expected post burn values
        (expectedReturn, expectedFees) = linCurve.getTokenPrice(linToken.totalSupply(), linToken.reserveBalance());
        expectedReserve = linToken.reserveBalance() - expectedReturn;
        expectedReturn -= expectedFees;
        expectedSupply = linToken.totalSupply() - burnAmount;
        expectedProtocolBalance = owner.balance + expectedFees;

        vm.startPrank(user1);
        linToken.approve(address(user1), burnAmount);
        linToken.burnTokens(burnAmount, user1);
        vm.stopPrank();

        assertEq(linToken.totalSupply(), expectedSupply);
        assertEq(linToken.reserveBalance(), expectedReserve);
        assertEq(linToken.balanceOf(user1), 0);
        assertEq(owner.balance, expectedProtocolBalance);
        assertEq(user1.balance, userBalance + expectedReturn);
    }
}
