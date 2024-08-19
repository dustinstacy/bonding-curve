//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {LinearToken} from "src/linear-curve/LinearToken.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployLinearBondingCurve} from "script/DeployLinearBondingCurve.s.sol";
import {DeployLinearToken} from "script/DeployLinearToken.s.sol";

contract LinearBondingCurveAndToken is Test {}
