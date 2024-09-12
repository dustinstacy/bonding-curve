//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {AlphaMarketToken} from "src/dao/AlphaMarketToken.sol";
import {DeployAlphaMarketToken} from "script/deploy/DeployAlphaMarketToken.s.sol";
import {TimeLock} from "src/dao/TimeLock.sol";
import {DeployTimeLock} from "script/deploy/DeployTimeLock.s.sol";
import {AlphaMarketDAO} from "src/dao/AlphaMarketDAO.sol";
import {DeployAlphaMarketDAO} from "script/deploy/DeployAlphaMarketDAO.s.sol";
import {ExponentialBondingCurve} from "src/bonding-curves/ExponentialBondingCurve.sol";
import {DeployExponentialBondingCurve} from "script/deploy/DeployExponentialBondingCurve.s.sol";
import {LinearBondingCurve} from "src/bonding-curves/LinearBondingCurve.sol";
import {DeployLinearBondingCurve} from "script/deploy/DeployLinearBondingCurve.s.sol";
import {HelperConfig} from "script/utils/HelperConfig.s.sol";
import {ExponentialBondingCurveUpgradeMock} from "test/mocks/ExponentialBondingCurveUpgradeMock.sol";
import {CodeConstants} from "script/utils/HelperConfig.s.sol";

contract AlphaMarketDAOTest is Test, CodeConstants {
    AlphaMarketToken public alphaMarketToken;
    TimeLock public timeLock;
    AlphaMarketDAO public alphaMarket;
    ExponentialBondingCurve public expCurve;
    LinearBondingCurve public linCurve;
    ExponentialBondingCurveUpgradeMock public upgradeMock;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    HelperConfig.CurveConfig public curveConfig;
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
        helperConfig = new HelperConfig();
        (curveConfig, networkConfig) = helperConfig.getConfig();
        admin = networkConfig.admin;

        DeployAlphaMarketToken deployToken = new DeployAlphaMarketToken();
        DeployTimeLock deployLock = new DeployTimeLock();
        DeployAlphaMarketDAO deployMarket = new DeployAlphaMarketDAO();
        DeployExponentialBondingCurve deployExpCurve = new DeployExponentialBondingCurve();
        DeployLinearBondingCurve deployLinCurve = new DeployLinearBondingCurve();

        alphaMarketToken = deployToken.run();
        timeLock = deployLock.run();
        alphaMarket = deployMarket.deployAlphaMarketDAO(admin, alphaMarketToken, timeLock);
        deployMarket.updateRoles(address(alphaMarket), admin, timeLock);
        (expProxy, expCurve, helperConfig) = deployExpCurve.deployCurve(address(timeLock), admin, curveConfig);
        (linProxy, linCurve,) = deployLinCurve.run();

        vm.prank(admin);
        alphaMarketToken.mint(voter, 1000);

        vm.prank(voter);
        alphaMarketToken.delegate(voter);

        protocolFeePercent = curveConfig.protocolFeePercent;
        feeSharePercent = curveConfig.feeSharePercent;
        initialReserve = curveConfig.initialReserve;
        reserveRatio = curveConfig.reserveRatio;
        maxGasLimit = curveConfig.maxGasLimit;

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
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        console.log("Proposal State:", uint256(alphaMarket.state(proposalId)));

        // Execute the proposal
        vm.prank(executors[0]);
        alphaMarket.execute(addressesToCall, values, functionCalls, descriptionHash);

        console.log("Proposal State:", uint256(alphaMarket.state(proposalId)));

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
