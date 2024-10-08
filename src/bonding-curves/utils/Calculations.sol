// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Calculations
/// @author Dustin Stacy
/// @notice This library contains the math functions for converting between token amounts and USD values.
/// @dev In context of this project, this library may not be necessary, but it is included to demonstrate potential use cases.
library Calculations {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev Used to adjust decimals of price feed results.
    /// @notice This precision returns USD value with 4 decimal places i.e. $0.0000;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e4;

    /// @dev Used to adjust decimals to relative USD value.
    uint256 private constant PRECISION = 1e18;

    /// @notice The number of basis points in 100%.
    uint256 private constant BASIS_POINTS_PRECISION = 1e4;

    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculates the scaling factor percent used to determine the token price increment.
    /// @dev Compensates for solidity's lack of floating point numbers.
    /// @param scalingFactor The scaling factor used to determine the price of tokens.
    function calculateScalingFactorPercent(uint256 scalingFactor) external pure returns (uint256) {
        return scalingFactor * PRECISION / BASIS_POINTS_PRECISION;
    }

    function calculatePriceIncrement(uint256 initialCost, uint256 scalingFactorPercent)
        external
        pure
        returns (uint256)
    {
        return initialCost * scalingFactorPercent / PRECISION;
    }

    /// @notice Calculates the initial cost adjustment based on the initial cost and scaling factor percent.
    /// @dev Returns int256 because the return value can be negative if the scaling factor is greater than 100%.
    /// @param initialCost The initial cost of the token.
    function calculateInitialCostAdjustment(uint256 initialCost, uint256 priceIncrement)
        external
        pure
        returns (int256)
    {
        return int256(initialCost) - int256(priceIncrement);
    }

    /// @notice Calculates the USD value of the tokens.
    /// @param ethPrice The latest price of ETH.
    /// @param amount The amount of tokens.
    /// @return usdValue The USD value of the tokens.
    /// @dev For now the ethPrice is passed in as a parameter, but in a real world scenario, it would be fetched from a price feed.
    function calculateUSDValue(uint256 ethPrice, uint256 amount) external pure returns (uint256 usdValue) {
        return ((ethPrice * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @return The `ADDITIONAL_FEED_PRECISION` constant.
    function getAdditionaFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    /// @return The `PRECISION` constant.
    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    /// @return The `BASIS_POINTS` constant.
    function getBasisPoints() external pure returns (uint256) {
        return BASIS_POINTS_PRECISION;
    }
}
