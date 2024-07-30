// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";

/// @title Calculations
/// @author Dustin Stacy
/// @notice This library contains the math functions for converting between token amounts and USD values.
library Calculations {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev Used to adjust decimals of price feed results.
    /// @notice This precision returns USD value with 4 decimal places i.e. $0.0000;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e4;

    /// @dev Used to adjust decimals to relative USD value.
    uint256 private constant PRECISION = 1e18;

    /// @notice Retrieves the latest price from the Chainlink price feed using `latestRoundData()`,
    /// which returns a value with 8 decimals. To increase precision, `ADDITIONAL_FEED_PRECISION`
    /// is used to scale the price to the desired decimals length before dividing by `PRECISION` to obtain the USD value.
    /// @param tokenPriceFeed The token price feed address.
    /// @param amount The amount of tokens.
    /// @return usdValue The USD value of the tokens.
    function calculateUSDValue(address tokenPriceFeed, uint256 amount) external view returns (uint256 usdValue) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenPriceFeed);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    /// @param tokenPriceFeed The token price feed address.
    /// @param usdAmountInWei The USD value in Wei.
    /// @return The token amount.
    function calculateTokenAmountFromUSD(address tokenPriceFeed, uint256 usdAmountInWei)
        public
        view
        returns (uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenPriceFeed);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

    /// @return The `ADDITIONAL_FEED_PRECISION` constant.
    function getAdditionaFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    /// @return The `PRECISION` constant.
    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }
}
