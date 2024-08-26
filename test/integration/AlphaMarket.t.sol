//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {AlphaMarketToken} from "src/dao/AlphaMarketToken.sol";
import {DeployAlphaMarketToken} from "script/DeployAlphaMarketToken.s.sol";
import {TimeLock} from "src/dao/TimeLock.sol";
import {DeployTimeLock} from "script/DeployTimeLock.s.sol";
import {AlphaMarket} from "src/dao/AlphaMarket.sol";
import {DeployAlphaMarket} from "script/DeployAlphaMarket.s.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {DeployExponentialBondingCurve} from "script/DeployExponentialBondingCurve.s.sol";
import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {DeployLinearBondingCurve} from "script/DeployLinearBondingCurve.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ExponentialBondingCurveUpgradeMock} from "test/mocks/ExponentialBondingCurveUpgradeMock.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";

contract AlphaMarketTest is Test, CodeConstants {
    AlphaMarketToken public alphaMarketToken;
    TimeLock public timeLock;
    AlphaMarket public alphaMarket;
    ExponentialBondingCurve public expCurve;
    LinearBondingCurve public linCurve;
    ExponentialBondingCurveUpgradeMock public upgradeMock;
    HelperConfig public helperConfig;
    HelperConfig.CurveConfig public config;
    DeployExponentialBondingCurve public curveDeployer;
    address expProxy;
    address linProxy;

    address[] proposers;
    address[] executors;
    address admin;

    bytes32 proposerRole;
    bytes32 executorRole;

    bytes[] functionCalls;
    address[] addressesToCall;
    uint256[] values;

    // Curve Variables;
    address owner;
    address protocolFeeDestination;
    uint256 protocolFeePercent;
    uint256 feeSharePercent;
    uint256 initialReserve;
    uint32 reserveRatio;
    uint256 maxGasLimit;

    // Constants
    uint256 public constant PRECISION = 1e18;
    uint256 public constant BASIS_POINTS_PRECISION = 1e4;
    uint256 public constant MIN_DELAY = 1; // How many blocks till a proposal vote becomes active
    uint256 public constant VOTING_DELAY = 7200; // How many blocks till a proposal vote becomes active
    uint256 public constant VOTING_PERIOD = 50400; // How many blocks till a proposal vote becomes active
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    address public voter = makeAddr("voter");

    function setUp() public {
        admin = makeAddr("admin");

        // alphaMarketToken = new AlphaMarketToken(admin);

        // vm.prank(admin);
        // timeLock = new TimeLock(MIN_DELAY, proposers, executors, admin);
        // alphaMarket = new AlphaMarket(alphaMarketToken, timeLock);

        // curveDeployer = new DeployExponentialBondingCurve();
        // (curveProxy, expCurve, helper) = curveDeployer.deployCurve(address(timeLock), address(alphaMarket));
        // config = helper.getConfig();

        // owner = config.owner;
        // protocolFeeDestination = config.protocolFeeDestination;
        // protocolFeePercent = config.protocolFeePercent;
        // feeSharePercent = config.feeSharePercent;
        // initialReserve = config.initialReserve;
        // reserveRatio = config.reserveRatio;
        // maxGasLimit = config.maxGasLimit;

        // expCurve = ExponentialBondingCurve(payable(curveProxy));

        DeployAlphaMarketToken deployToken = new DeployAlphaMarketToken();
        DeployTimeLock deployLock = new DeployTimeLock();
        DeployAlphaMarket deployMarket = new DeployAlphaMarket();
        DeployExponentialBondingCurve deployExpCurve = new DeployExponentialBondingCurve();
        DeployLinearBondingCurve deployLinCurve = new DeployLinearBondingCurve();

        alphaMarketToken = deployToken.run(admin);
        timeLock = deployLock.run(admin);
        alphaMarket = deployMarket.run(admin, alphaMarketToken, timeLock);
        (expProxy, expCurve, helperConfig) = deployExpCurve.run(address(timeLock), address(alphaMarket));
        (linProxy, linCurve,) = deployLinCurve.run(address(timeLock), address(alphaMarket));

        vm.prank(admin);
        alphaMarketToken.mint(voter, 1000);

        vm.prank(voter);
        alphaMarketToken.delegate(voter);

        config = helperConfig.getConfig();
        protocolFeeDestination = config.protocolFeeDestination;
        protocolFeePercent = config.protocolFeePercent;
        feeSharePercent = config.feeSharePercent;
        initialReserve = config.initialReserve;
        reserveRatio = config.reserveRatio;
        maxGasLimit = config.maxGasLimit;

        proposers = new address[](1);
        proposers[0] = makeAddr("proposer");

        executors = new address[](1);
        executors[0] = makeAddr("executor");

        proposerRole = timeLock.PROPOSER_ROLE();
        executorRole = timeLock.EXECUTOR_ROLE();

        vm.startPrank(admin);
        timeLock.grantRole(proposerRole, proposers[0]);
        timeLock.grantRole(executorRole, executors[0]);
        vm.stopPrank();
    }

    function test_CantUpdateBondingCurveWithoutGovernance() public {
        vm.expectRevert();
        expCurve.setProtocolFeeDestination(voter);
    }

    function test_GovernanceOfSetterFunctions() public {
        address newProtocolFeeDestination = makeAddr("newProtocolFeeDestination");

        string memory description = "Set new curve parameters";
        bytes memory encodedFunctionCalls =
            abi.encodeWithSignature("setProtocolFeeDestination(address)", newProtocolFeeDestination);

        addressesToCall.push(address(expCurve));
        values.push(0);
        functionCalls.push(encodedFunctionCalls);

        // Propose the change
        vm.prank(proposers[0]);
        uint256 proposalId = alphaMarket.propose(addressesToCall, values, functionCalls, description);
        console.log("Proposal State:", uint256(alphaMarket.state(proposalId)));

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        // Vote on the proposal
        string memory reason = "It gets the people going!";
        uint8 voteWay = 1;
        vm.prank(voter);
        alphaMarket.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("Proposal State:", uint256(alphaMarket.state(proposalId)));

        // Queue the proposal
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));

        alphaMarket.queue(addressesToCall, values, functionCalls, descriptionHash);
        console.log("here");
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // Execute the proposal
        vm.prank(executors[0]);
        alphaMarket.execute(addressesToCall, values, functionCalls, descriptionHash);

        assertEq(expCurve.protocolFeeDestination(), newProtocolFeeDestination);
    }

    function test_UpgradeBondingCurveContract() public {
        upgradeMock = new ExponentialBondingCurveUpgradeMock();

        string memory description = "Set new curve parameters";
        bytes memory encodedFunctionCalls =
            abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(upgradeMock), "");

        addressesToCall.push(address(expCurve));
        values.push(0);
        functionCalls.push(encodedFunctionCalls);

        // Propose the change
        vm.prank(proposers[0]);
        uint256 proposalId = alphaMarket.propose(addressesToCall, values, functionCalls, description);

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        // Vote on the proposal
        string memory reason = "Let me upgrade ya!";
        uint8 voteWay = 1;
        vm.prank(voter);
        alphaMarket.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        // Queue the proposal
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        alphaMarket.queue(addressesToCall, values, functionCalls, descriptionHash);
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // Execute the proposal
        vm.prank(executors[0]);
        alphaMarket.execute(addressesToCall, values, functionCalls, descriptionHash);

        uint256 expectedValue = 123456789;
        (uint256 actualValue,) = ExponentialBondingCurveUpgradeMock(expProxy).getTokenPrice();
        assertEq(actualValue, expectedValue);
    }
}
