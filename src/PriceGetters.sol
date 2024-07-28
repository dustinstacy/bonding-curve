// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "src/libraries/PiecewiseLogic.sol";

contract PriceGetters {
    /// @notice  reserveBalance keeps track of the total amount of Ether
    /// (or other reserve currency) held by the contract.
    /// This balance is crucial for the functioning of the bonding
    /// curve as it influences the price of tokens.
    uint256 public reserveBalance;

    /// @notice reserveRatio is used to define the steepness or shape of the bonding curve.
    /// It's specified in basis points, where 100 basis points equal 1 percent. For example,
    /// a reserve ratio of 5000 corresponds to a 50% reserve ratio.
    uint256 public reserveRatio;

    constructor(uint256 _reserveRatio) {
        reserveRatio = _reserveRatio;
    }

    function getPrice(uint256 supply, uint256 amount, uint256 scalingFactor) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1) * (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = supply == 0 && amount == 1
            ? 0
            : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / (scalingFactor * 1e5); // scaling factor controls curve steepness
    }

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

    // Calculate buy price using the bonding curve formula
    function calculateBuyPrice(uint256 amount) public view returns (uint256) {
        return amount * (reserveBalance + amount) / reserveBalance;
    }
}
