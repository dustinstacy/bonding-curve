//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {ExponentialToken} from "src/exponential-curve/ExponentialToken.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployExponentialBondingCurve} from "script/DeployExponentialBondingCurve.s.sol";
import {DeployExponentialToken} from "script/DeployExponentialToken.s.sol";

contract ExponentialBondingCurveAndToken is Test {}
