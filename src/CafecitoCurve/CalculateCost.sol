// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "lib/cafecito-swap/PiecewiseLogic.sol";

contract CalculateCost {
    /// @notice Fetches the cost of n tokens
    /// @dev
    /// @param curve g
    /// @param start g
    /// @param nth g
    /// @param initCost g
    function costOfN(int256[] memory curve, uint256 start, uint256 nth, uint256 initCost)
        public
        pure
        returns (uint256)
    {
        int256 res = PiecewiseLogic.evaluateFunction(curve, start, nth);
        require(res >= 0, "Error: Cost cannot be negative");
        uint256 cost = uint256(res) * initCost;
        return cost;
    }
}
