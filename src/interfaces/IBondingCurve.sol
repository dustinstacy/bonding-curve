// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBondingCurve {
    /**
     * @dev Get raw price of linear bonding curve tokens.
     */
    function getRawPrice(
        uint256 supply,
        uint256 initialCost,
        uint256 scalingFactor,
        uint256 amount,
        int256 initialCostAdjustment
    ) external view returns (uint256);

    /**
     * @dev Get raw price of exponential bonding curve tokens.
     */
    function getRawPrice(uint256 supply, uint256 scalingFactor, uint256 initialCost, uint256 amount)
        external
        view
        returns (uint256);
}
