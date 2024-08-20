//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console} from "forge-std/console.sol";

contract LinearFormula {
    /// @notice Precision for calculations.
    /// @dev Solidity does not support floating point numbers, so we use fixed point math.
    /// @dev Precision also acts as the number 1 commonly used in curve calculations.
    uint256 private constant PRECISION = 1e18;

    /// @notice Function to calculate the amount of continuous tokens to return based on reserve tokens received.
    /// @param currentSupply The current supply of continuous tokens (in 1e18 format).
    /// @param reserveBalance The balance of reserve tokens (in wei).
    /// @param initialReserve The initial reserve balance (in wei).
    /// @param reserveTokensReceived The amount of reserve tokens received (in wei).
    /// @param protocolFeePercent The protocol fee percentage (in 1e18 format).
    /// @return purchaseReturn The amount of continuous tokens to mint (in 1e18 format).
    /// @return fees The amount of protocol fees to send to the protocol fee destination (in wei).
    function calculatePurchaseReturn(
        uint256 currentSupply,
        uint256 reserveBalance,
        uint256 initialReserve,
        uint256 reserveTokensReceived,
        uint256 protocolFeePercent
    ) public pure returns (uint256 purchaseReturn, uint256 fees) {
        // Calculate Protocol Fees.
        fees = ((reserveTokensReceived * PRECISION / (protocolFeePercent + PRECISION)) * protocolFeePercent) / PRECISION;
        uint256 remainingReserveTokens = reserveTokensReceived - fees;

        // Determine the next token threshold.
        uint256 n = (currentSupply / PRECISION) + 1;

        // Calculate the current token fragment.
        uint256 currentFragmentBalance = _totalCost(n, initialReserve) - reserveBalance;

        uint256 currentFragment =
            (currentFragmentBalance * PRECISION / (_totalCost(n, initialReserve) - _totalCost(n - 1, initialReserve)));

        // If the reserve tokens are less than the current fragment balance, return portion of the current fragment.
        if (remainingReserveTokens < currentFragmentBalance) {
            purchaseReturn = (remainingReserveTokens * PRECISION)
                / (_totalCost(n, initialReserve) - _totalCost(n - 1, initialReserve));
            return (purchaseReturn, fees);
        }

        // Calibrate variables for the next token price threshold.
        remainingReserveTokens -= currentFragmentBalance;
        purchaseReturn += currentFragment;
        n++;

        // Iterate through the curve until the remaining reserve tokens are less than the next token price threshold.
        while (_totalCost(n, initialReserve) - _totalCost(n - 1, initialReserve) <= remainingReserveTokens) {
            purchaseReturn += PRECISION;
            remainingReserveTokens -= _totalCost(n, initialReserve) - _totalCost(n - 1, initialReserve);
            n++;
        }

        // Calculate the remaining fragment if the remaining reserve tokens are less than the next token price threshold.
        purchaseReturn +=
            (remainingReserveTokens * PRECISION) / (_totalCost(n, initialReserve) - _totalCost(n - 1, initialReserve));

        return (purchaseReturn, fees);
    }

    /// @notice Function to calculate the amount of reserve tokens to return based on continuous tokens sold.
    /// @param currentSupply The current supply of continuous tokens (in 1e18 format).
    /// @param reserveBalance The balance of reserve tokens (in wei).
    /// @param intialReserve The initial reserve balance (in wei).
    /// @param amount The amount of continuous tokens to sell (in 1e18 format).
    /// @param protocolFeePercent The protocol fee percentage (in 1e18 format).
    /// @return saleReturn The amount of reserve tokens to return (in wei).
    /// @return fees The amount of protocol fees to send to the protocol fee destination (in wei).
    function calculateSaleReturn(
        uint256 currentSupply,
        uint256 reserveBalance,
        uint256 intialReserve,
        uint256 amount,
        uint256 protocolFeePercent
    ) public pure returns (uint256 saleReturn, uint256 fees) {
        // Determine the current token threshold.
        uint256 remainingCurrentTokenFragment;
        uint256 n = (currentSupply / PRECISION);

        uint256 remainingCurrentTokenBalance = reserveBalance - _totalCost(n, intialReserve);
        console.log("remainingCurrentTokenBalance: %s", remainingCurrentTokenBalance);

        if (remainingCurrentTokenBalance == 0) {
            remainingCurrentTokenBalance = _totalCost(n, intialReserve) - _totalCost(n - 1, intialReserve);
            remainingCurrentTokenFragment = PRECISION;
        } else {
            remainingCurrentTokenFragment = (
                (remainingCurrentTokenBalance * PRECISION)
                    / ((_totalCost(n + 1, intialReserve)) - _totalCost(n, intialReserve))
            );
        }

        // If the amount of tokens to sell is less than the current token fragment, return a portion of the current fragment.
        if (amount < remainingCurrentTokenFragment) {
            saleReturn = amount * PRECISION / _totalCost(n, intialReserve);
            fees = (saleReturn * protocolFeePercent) / PRECISION;
            return (saleReturn, fees);
        } else if (remainingCurrentTokenFragment == 0) {
            n--;
            saleReturn = _totalCost(n, intialReserve);
            _totalCost(n - 1, intialReserve);
            fees = (saleReturn * protocolFeePercent) / PRECISION;
            return (saleReturn, fees);
        }

        // Calibrate variables for the next token price threshold.
        amount -= remainingCurrentTokenFragment;
        saleReturn += remainingCurrentTokenBalance;

        if (n != 1) {
            n--;
        }

        // Iterate through the curve until the remaining amount of tokens to sell is less than the next token price threshold.
        while (amount >= PRECISION) {
            saleReturn += (_totalCost(n + 1, intialReserve) - _totalCost(n, intialReserve));
            amount -= PRECISION;
            if (n != 1) {
                n--;
            }
        }

        // Calculate the remaining fragment if the remaining amount of tokens to sell is less than the next token price threshold.
        saleReturn += ((amount * (_totalCost(n + 1, intialReserve) - _totalCost(n, intialReserve))) / PRECISION);

        // Calculate protocol fees
        fees = (saleReturn * protocolFeePercent) / PRECISION;

        return (saleReturn, fees);
    }

    /// @notice Function to calculate the amount of reserve tokens required to mint a token.
    /// @param currentSupply The current supply of continuous tokens (in 1e18 format).
    /// @param reserveBalance The balance of reserve tokens (in wei).
    /// @param initialReserve The initial reserve balance (in wei).
    /// @return depositAmount The amount of reserve tokens required to mint a token (in wei).
    function calculateMintCost(uint256 currentSupply, uint256 reserveBalance, uint256 initialReserve)
        public
        pure
        returns (uint256 depositAmount)
    {
        // We want to mint exactly 1 token, scaled by PRECISION
        uint256 targetReturn = PRECISION;

        // Determine the next token threshold.
        uint256 n = (currentSupply / PRECISION) + 1;

        // Calculate the current token fragment.
        uint256 currentFragmentBalance = _totalCost(n, initialReserve) - reserveBalance;
        uint256 currentFragment =
            (currentFragmentBalance * PRECISION / (_totalCost(n, initialReserve) - _totalCost(n - 1, initialReserve)));

        if (currentFragment == targetReturn) {
            return depositAmount = currentFragmentBalance;
        }

        // Calibrate variables for the next token price threshold.
        depositAmount += currentFragmentBalance;
        targetReturn -= currentFragment;
        n++;

        uint256 remainingFragment =
            ((_totalCost(n, initialReserve) - _totalCost(n - 1, initialReserve)) * targetReturn) / PRECISION;

        depositAmount += remainingFragment;
    }

    /// @notice Function to calculate the total cost of tokens given the number of tokens.
    function _totalCost(uint256 n, uint256 initialReserve) internal pure returns (uint256) {
        return (n * (n + 1) * initialReserve) / 2;
    }
}
