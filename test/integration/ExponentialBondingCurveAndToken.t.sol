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
    HelperConfig.CurveConfig public config;
    DeployExponentialBondingCurve public curveDeployer;
    DeployExponentialToken public tokenDeployer;

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
    address public user2 = makeAddr("user2");

    // Constants
    uint256 public constant STARTING_BALANCE = 1000 ether;
    uint256 public constant PRECISION = 1e18;

    /// @notice Event to log token purchases.
    event TokensPurchased(address indexed buyer, uint256 amountSpent, uint256 fees, uint256 tokensMinted);

    /// @notice Event to log token sales.
    event TokensSold(address indexed seller, uint256 amountReceived, uint256 fees, uint256 tokensBurnt);

    function setUp() public {
        curveDeployer = new DeployExponentialBondingCurve();
        tokenDeployer = new DeployExponentialToken();
        (address curveProxy, HelperConfig helper) = curveDeployer.deployCurve();
        config = helper.getConfig();

        owner = config.owner;
        protocolFeeDestination = config.protocolFeeDestination;
        protocolFeePercent = config.protocolFeePercent;
        feeSharePercent = config.feeSharePercent;
        initialReserve = config.initialReserve;
        reserveRatio = config.reserveRatio;
        maxGasLimit = config.maxGasLimit;

        vm.deal(host, STARTING_BALANCE);
        vm.deal(user1, STARTING_BALANCE);
        vm.deal(user2, STARTING_BALANCE);

        expCurve = ExponentialBondingCurve(payable(curveProxy));

        vm.prank(host);
        expToken = tokenDeployer.run{value: initialReserve}(name, symbol, curveProxy, host);
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

    function test_RevertsWhen_MintingWithoutValue() public {
        vm.expectRevert(ExponentialToken.ExponentialToken__AmountMustBeMoreThanZero.selector);
        expToken.mintTokens();
    }

    function test_ExponentialTokenUserMintAndBurnToken() public {
        // Set starting values
        supply = expToken.totalSupply();
        reserve = expToken.reserveBalance();
        uint256 startingProtocolBalance = FOUNDRY_DEFAULT_SENDER.balance;

        // Calculate required value to mint 1 token
        (uint256 depositAmount, uint256 expectedFees) = expCurve.getApproxMintCost(supply, reserve);

        // Set expected mint values
        uint256 expectedReturn = 1e18;
        uint256 expectedSupply = supply + expectedReturn;
        uint256 expectedReserve = reserve + (depositAmount - expectedFees);
        uint256 expectedProtocolBalance = startingProtocolBalance + expectedFees;

        vm.prank(user1);

        expToken.mintTokens{value: depositAmount}();

        assertApproxEqAbs(expToken.totalSupply(), expectedSupply, 1e5);
        assertApproxEqAbs(expToken.reserveBalance(), expectedReserve, 10);
        assertApproxEqAbs(expToken.balanceOf(user1), expectedReturn, 1e5);
        assertApproxEqAbs(FOUNDRY_DEFAULT_SENDER.balance, expectedProtocolBalance, 10);

        uint256 burnAmount = expToken.balanceOf(user1);
        uint256 userBalance = user1.balance;

        // Set expected burn values
        (expectedReturn, expectedFees) = expCurve.getTokenPrice(expToken.totalSupply(), expToken.reserveBalance());
        expectedReserve = expToken.reserveBalance() - expectedReturn;
        expectedReturn -= expectedFees;
        expectedSupply = expToken.totalSupply() - burnAmount;
        expectedProtocolBalance = FOUNDRY_DEFAULT_SENDER.balance + expectedFees;

        vm.startPrank(user1);
        expToken.approve(address(user1), burnAmount);
        expToken.burnTokens(burnAmount, user1);
        vm.stopPrank();

        assertEq(expToken.totalSupply(), expectedSupply);
        assertEq(expToken.reserveBalance(), expectedReserve);
        assertEq(expToken.balanceOf(user1), 0);
        assertEq(FOUNDRY_DEFAULT_SENDER.balance, expectedProtocolBalance);
        assertEq(user1.balance, userBalance + expectedReturn);
    }
}
