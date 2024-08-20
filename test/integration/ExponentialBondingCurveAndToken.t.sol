//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {ExponentialToken} from "src/exponential-curve/ExponentialToken.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployExponentialBondingCurve} from "script/DeployExponentialBondingCurve.s.sol";
import {DeployExponentialToken} from "script/ExponentialInteractions.s.sol";

contract ExponentialBondingCurveAndTokenTest is Test {
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
    uint256 value;
    uint256 amount;

    // Addresses
    address public host = makeAddr("host");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    // User Balances
    uint256 STARTING_BALANCE = 1000 ether;

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

    function test_ExponentialTokenUserMint() public {}

    function test_ExponentialTokenUserBurn() public {}
}
