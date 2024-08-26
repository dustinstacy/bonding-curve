//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {ExponentialToken} from "src/exponential-curve/ExponentialToken.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployExponentialBondingCurve} from "script/DeployExponentialBondingCurve.s.sol";
import {DeployExponentialToken} from "script/ExponentialInteractions.s.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";

contract ExponentialBondingCurveAndTokenTest is Test, CodeConstants {
    ExponentialBondingCurve public expCurve;
    ExponentialToken public expToken;
    HelperConfig public helperConfig;
    HelperConfig.CurveConfig public config;
    DeployExponentialBondingCurve public curveDeployer;
    DeployExponentialToken public tokenDeployer;
    address expProxy;

    // Token Contract Variables
    string public name = "HaTOKEN";
    string public symbol = "HTK";

    // Curve Variables;
    address public owner;
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public feeSharePercent;
    uint256 public initialReserve;
    uint32 public reserveRatio;
    uint256 public maxGasLimit;

    // Test Variables
    uint256 supply;
    uint256 reserve;
    uint256 value;
    uint256 amount;

    // Addresses
    address public host = makeAddr("host");
    address public user1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // Constants
    uint256 public constant STARTING_BALANCE = 1000 ether;
    uint256 public constant PRECISION = 1e18;

    function setUp() public {
        owner = FOUNDRY_DEFAULT_SENDER;
        curveDeployer = new DeployExponentialBondingCurve();
        tokenDeployer = new DeployExponentialToken();
        (expProxy, expCurve, helperConfig) = curveDeployer.deployCurve(owner, owner);
        config = helperConfig.getConfig();

        protocolFeeDestination = config.protocolFeeDestination;
        protocolFeePercent = config.protocolFeePercent;
        feeSharePercent = config.feeSharePercent;
        initialReserve = config.initialReserve;
        reserveRatio = config.reserveRatio;
        maxGasLimit = config.maxGasLimit;

        vm.deal(owner, STARTING_BALANCE);
        vm.deal(host, STARTING_BALANCE);
        vm.deal(user1, STARTING_BALANCE);

        vm.prank(host);
        expToken = tokenDeployer.run{value: initialReserve}(name, symbol, expProxy, host);
    }

    function test_ExponentialTokenConstructor() public view {
        assertEq(expToken.name(), name);
        assertEq(expToken.symbol(), symbol);
        assertEq(expToken.totalSupply(), 1 ether);
        assertEq(expToken.reserveBalance(), initialReserve);
        assertEq(expToken.balanceOf(host), 1 ether);
        assertEq(expToken.balanceOf(address(this)), 0);
        assertEq(expToken.getBondingCurveProxyAddress(), address(expCurve));
    }

    function test_RevertsWhen_ExponentialTokenMintingWithoutValue() public {
        vm.expectRevert(ExponentialToken.ExponentialToken__AmountMustBeMoreThanZero.selector);
        expToken.mintTokens();
    }

    function test_ExponentialTokenUserMintAndBurnToken() public {
        // Set starting values
        supply = expToken.totalSupply();
        reserve = expToken.reserveBalance();
        uint256 startingProtocolBalance = owner.balance;

        // Calculate required value to mint 1 token
        (uint256 depositAmount, uint256 expectedFees) = expCurve.getApproxMintCost(supply, reserve);

        // Set expected post mint values
        uint256 expectedReturn = 1e18;
        uint256 expectedSupply = supply + expectedReturn;
        uint256 expectedReserve = reserve + (depositAmount - expectedFees);
        uint256 expectedProtocolBalance = startingProtocolBalance + expectedFees;

        vm.prank(user1);
        expToken.mintTokens{value: depositAmount}();

        assertApproxEqAbs(expToken.totalSupply(), expectedSupply, 1e5);
        assertApproxEqAbs(expToken.reserveBalance(), expectedReserve, 10);
        assertApproxEqAbs(expToken.balanceOf(user1), expectedReturn, 1e5);
        assertApproxEqAbs(owner.balance, expectedProtocolBalance, 10);

        uint256 burnAmount = expToken.balanceOf(user1);
        uint256 userBalance = user1.balance;

        // Set expected post burn values
        (expectedReturn, expectedFees) = expCurve.getTokenPrice(expToken.totalSupply(), expToken.reserveBalance());
        expectedReserve = expToken.reserveBalance() - expectedReturn;
        expectedReturn -= expectedFees;
        expectedSupply = expToken.totalSupply() - burnAmount;
        expectedProtocolBalance = owner.balance + expectedFees;

        vm.startPrank(user1);
        expToken.approve(address(user1), burnAmount);
        expToken.burnTokens(burnAmount, user1);
        vm.stopPrank();

        assertEq(expToken.totalSupply(), expectedSupply);
        assertEq(expToken.reserveBalance(), expectedReserve);
        assertEq(expToken.balanceOf(user1), 0);
        assertEq(owner.balance, expectedProtocolBalance);
        assertEq(user1.balance, userBalance + expectedReturn);
    }
}
