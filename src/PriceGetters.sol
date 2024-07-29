// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PiecewiseLogic} from "src/libraries/PiecewiseLogic.sol";

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

    /// @notice tokenSupply keeps track of the total amount of tokens in circulation.
    uint256 public tokenSupply;

    /// @notice initPrice is the initial price of the token.
    uint256 public initPrice;

    /// @notice rftCurve is the piecewise curve that defines the price of the token.
    int256[] public rftCurve;

    constructor(uint256 _reserveRatio, uint256 _initPrice) payable {
        reserveBalance = msg.value;
        reserveRatio = _reserveRatio;
        initPrice = _initPrice;
        // rftCurve = _rftCurve;
    }

    function getPrice(uint256 supply, uint256 amount, uint256 scalingFactor) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1) * (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = supply == 0 && amount == 1
            ? 0
            : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / (scalingFactor * 1e5); // scaling factor controls curve steepness
    }

    // Calculate buy price based on bonding curve formula
    function calculateBuyPrice(uint256 amount) public view returns (uint256) {
        if (tokenSupply == 0) {
            // Special case for initial token purchase
            return reserveBalance * reserveRatio / 1e4; // Initial price
        } else {
            // General case for buying tokens
            uint256 newTokenSupply = tokenSupply + amount;
            uint256 price = reserveBalance * ((newTokenSupply * 1e4) ** reserveRatio) / (tokenSupply * 1e4);
            return price;
        }
    }

    function costOfN(int256[] memory curve, uint256 start, uint256 n) public view returns (uint256) {
        int256 res = PiecewiseLogic.evaluateFunction(curve, start, n);
        require(res >= 0, "Error: Cost cannot be negative");
        uint256 cost = uint256(res) * initPrice;
        return cost;
    }
}
