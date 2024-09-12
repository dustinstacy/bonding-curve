// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
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
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

///////////////////////////////////////////////////////////////////////////////
///////// !!!!!!!!!! NOT TESTED !!!!!!!!!!! ///////////////////////////////////
/////// Need more testnet funds to deploy the protocol ////////////////////////
///////////////////////////////////////////////////////////////////////////////

/// @title DeployExponentialBondingCurve
/// @notice Script for deploying the AlphaMarketDAO protocol.
contract DeployProtocol is Script {
    function run()
        external
        returns (
            AlphaMarketToken token,
            TimeLock lock,
            AlphaMarketDAO market,
            address expProxy,
            ExponentialBondingCurve expCurve,
            address linProxy,
            LinearBondingCurve linCurve,
            HelperConfig helper
        )
    {
        (token, lock, market, expProxy, expCurve, linProxy, linCurve, helper) = deployProtocol();
    }

    /// @notice Deploys the AlphaMarketDAO protocol.
    /// @return token The instance of the AlphaMarketToken contract.
    /// @return lock The instance of the TimeLock contract.
    /// @return market The instance of the AlphaMarketDAO contract.
    /// @return expProxy The address of the ExponentialBondingCurve proxy.
    /// @return expCurve The instance of the ExponentialBondingCurve contract.
    /// @return linProxy The address of the LinearBondingCurve proxy.
    /// @return linCurve The instance of the LinearBondingCurve contract.
    /// @return helper The instance of the HelperConfig contract.
    function deployProtocol()
        public
        returns (
            AlphaMarketToken token,
            TimeLock lock,
            AlphaMarketDAO market,
            address expProxy,
            ExponentialBondingCurve expCurve,
            address linProxy,
            LinearBondingCurve linCurve,
            HelperConfig helper
        )
    {
        DeployAlphaMarketToken deployToken = new DeployAlphaMarketToken();
        DeployTimeLock deployLock = new DeployTimeLock();
        DeployAlphaMarketDAO deployMarket = new DeployAlphaMarketDAO();
        DeployExponentialBondingCurve deployExpCurve = new DeployExponentialBondingCurve();
        DeployLinearBondingCurve deployLinCurve = new DeployLinearBondingCurve();

        token = deployToken.run();
        lock = deployLock.run();
        market = deployMarket.run();
        (expProxy, expCurve, helper) = deployExpCurve.run();
        (linProxy, linCurve,) = deployLinCurve.run();
    }
}
