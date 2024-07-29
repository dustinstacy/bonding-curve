// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title BondingCurve
/// @author Dustin Stacy
/// @notice This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
///         The curve is defined by a reserve ratio, which determines the steepness of the curve.
///         The contract is designed to work with ERC20 tokens.
contract BondingCurve {
    /// @param amount Amount of tokens to buy.
    /// @dev update with a more complex curve.
    function getPrice(uint256 totalSupply, uint256 amount) public pure returns (uint256) {
        return (totalSupply + amount) * 1e16;
    }

    /// @dev update with a more complex curve.
    function getSalePrice(uint256 totalSupply) public pure returns (uint256) {
        return (totalSupply) * 1e16;
    }
}
