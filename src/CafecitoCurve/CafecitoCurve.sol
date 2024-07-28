// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./CalculateCost.sol";

contract CafecitoCurve is CalculateCost {
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
        uint256 cost = costOfN(curve, start, amount, initCost);
        return cost;
    }

    /// @notice Fetches the current token cost calculation
    /// @dev
    /// @param start The number of tokens already minted from the curve
    function getCurrentCost(uint256 start) public view returns (uint256) {
        return getCostAmount(start, 0);
    }
}
