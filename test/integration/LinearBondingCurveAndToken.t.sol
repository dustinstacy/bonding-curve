//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {LinearToken} from "src/linear-curve/LinearToken.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployLinearBondingCurve} from "script/DeployLinearBondingCurve.s.sol";
import {DeployLinearToken} from "script/LinearInteractions.s.sol";

contract LinearBondingCurveAndToken is Test {
    LinearBondingCurve public linCurve;
    LinearToken public linToken;
    HelperConfig.CurveConfig public config;
    DeployLinearBondingCurve public curveDeployer;
    DeployLinearToken public tokenDeployer;

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
    uint256 value;
    uint256 amount;

    // Addresses
    address public host = makeAddr("host");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    // User Balances
    uint256 STARTING_BALANCE = 1000 ether;

    function setUp() public {
        curveDeployer = new DeployLinearBondingCurve();
        tokenDeployer = new DeployLinearToken();
        (address curveProxy, HelperConfig helper) = curveDeployer.deployCurve();
        config = helper.getConfig();

        owner = config.owner;
        protocolFeeDestination = config.protocolFeeDestination;
        protocolFeePercent = config.protocolFeePercent;
        feeSharePercent = config.feeSharePercent;
        initialReserve = config.initialReserve;
        maxGasLimit = config.maxGasLimit;

        vm.deal(host, STARTING_BALANCE);
        vm.deal(user1, STARTING_BALANCE);
        vm.deal(user2, STARTING_BALANCE);

        linCurve = LinearBondingCurve(payable(curveProxy));

        vm.prank(host);
        linToken = tokenDeployer.run{value: initialReserve}(name, symbol, curveProxy, host);
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
}
