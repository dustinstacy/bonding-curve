// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CafecitoCurve} from "src/references/CafecitoCurve.sol";

interface ICafecitoCurve {
    function getCurve() external view returns (int256[] memory);
    function getCostAmount(uint256 start, uint256 amount) external view returns (uint256);
    function getCurrentCost(uint256 start) external view returns (uint256);
}
