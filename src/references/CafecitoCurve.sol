// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PiecewiseLogic} from "src/libraries/PiecewiseLogic.sol";

contract CafecitoCurve {
    uint256 public initCost;
    int256[] public rftCurve;

    constructor(uint256 _initCost, int256[] memory _rftCurve) {
        initCost = _initCost;
        rftCurve = _rftCurve;
    }

    /// @notice Fetches the curve array
    function getCurve() public view returns (int256[] memory) {
        return rftCurve;
    }

    /// @notice Fetches the cost from start plus the amount of tokens
    /// @dev
    /// @param start The beginning of the count
    /// @param amount The number of tokens to calculate cost
    function getCostAmount(uint256 start, uint256 amount) public view returns (uint256) {
        int256[] memory curve = rftCurve;
        uint256 cost = costOfN(curve, start, amount);
        return cost;
    }

    /// @notice Fetches the current token cost calculation
    /// @dev
    /// @param start The number of tokens already minted from the curve
    function getCurrentCost(uint256 start) public view returns (uint256) {
        return getCostAmount(start, 0);
    }

    /// @notice Fetches the cost of n tokens
    /// @dev
    /// @param curve g
    /// @param start g
    /// @param nth g
    function costOfN(int256[] memory curve, uint256 start, uint256 nth) public view returns (uint256) {
        int256 res = PiecewiseLogic.evaluateFunction(curve, start, nth);
        require(res >= 0, "Error: Cost cannot be negative");
        uint256 cost = uint256(res) * initCost;
        return cost;
    }
}
