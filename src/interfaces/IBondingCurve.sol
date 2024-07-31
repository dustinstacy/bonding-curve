// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBondingCurve {
    /**
     * @dev Given a token amount to purchase, calculates the price of the tokens with maxCost argument.
     */
    function getPrice(uint256 supply, uint256 scalingFactor, uint256 initialCost, uint256 maxCost, uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @dev Given a token amount to purchase, calculates the price of the tokens without maxCost argument.
     */
    function getPrice(uint256 supply, uint256 scalingFactor, uint256 initialCost, uint256 amount)
        external
        view
        returns (uint256);
}
