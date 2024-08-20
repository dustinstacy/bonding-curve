//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {AlphaMarket} from "src/dao/AlphaMarket.sol";
import {AlphaMarketToken} from "src/dao/AlphaMarketToken.sol";
import {TimeLock} from "src/dao/TimeLock.sol";
import {DeployExponentialBondingCurve} from "script/DeployExponentialBondingCurve.s.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";

contract AlphaMarketTest is Test {
    AlphaMarket public alphaMarket;
    AlphaMarketToken public alphaMarketToken;
    TimeLock public timeLock;
    DeployExponentialBondingCurve public curveDeployer;
    ExponentialBondingCurve public expCurve;

    uint256 public constant MIN_DELAY = 3600;
    uint256 public constant QUORUM_PERCENTAGE = 4;
    uint256 public constant VOTING_PERIOD = 172800;
    uint256 public constant VOTING_DELAY = 1;

    address[] proposers;
    address[] executors;

    bytes[] functionCalls;
    address[] addressesToCall;
    uint256[] values;

    address public voter = makeAddr("voter");

    function setUp() public {}

    function test_SetterFunctions() public {}

    function test_UpgradeBondingCurveContract() public {}
}
