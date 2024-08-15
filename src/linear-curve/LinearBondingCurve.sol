// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {console} from "forge-std/console.sol";

/// @title LinearBondingCurve
/// @author Dustin Stacy
/// @notice This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
///         The price of tokens increases linearly with the supply.
/// @dev    Math needs to be rigorously test for edge cases including zero values and overflow.
/// @dev    Need to add access controls
contract LinearBondingCurve is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/
    /// @notice The address to send protocol fees to.
    address public protocolFeeDestination;

    /// @notice The percentage of the transaction to send to the protocol fee destination in basis points.
    uint256 public protocolFeeBasisPoints;

    /// @dev Value to represent the protocol fee as a percentage for use in calculations.
    uint256 private protocolFeePercent;

    /// @notice The initial cost of the token.
    uint256 public initialCost;

    /// @notice The maximum gas limit for transactions.
    /// @dev This value should be set to prevent front-running attacks.
    uint256 public maxGasLimit;

    /// @dev Solidity does not support floating point numbers, so we use fixed point math.
    /// @dev Precision also acts as the number 1 commonly used in curve calculations.
    uint256 private constant PRECISION = 1e18;

    /// @dev Precision for basis points calculations.
    /// @dev This is used to convert the protocol fee to a fraction.
    uint256 private constant BASIS_POINTS_PRECISION = 1e4;

    /*///////////////////////////////////////////////////////////////
                        INITIALIZER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Disables the default initializer function.
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract with the owner address.
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Function to calculate the amount of continuous tokens to return based on reserve tokens received.
    /// @param currentSupply The current supply of continuous tokens (in 1e18 format).
    /// @param reserveBalance The balance of reserve tokens (in wei).
    /// @param reserveTokensReceived The amount of reserve tokens received (in wei).
    /// @return purchaseReturn The amount of continuous tokens to mint (in 1e18 format).
    /// @return fees The amount of protocol fees to send to the protocol fee destination (in wei).
    /// @dev This function is gas inefficient and needs to be optimized.
    function calculatePurchaseReturn(uint256 currentSupply, uint256 reserveBalance, uint256 reserveTokensReceived)
        external
        returns (uint256 purchaseReturn, uint256 fees)
    {
        // Calculate protocol fees
        fees = (reserveTokensReceived * protocolFeePercent) / PRECISION;
        uint256 remainingReserveTokens = reserveTokensReceived - fees;

        uint256 newReserveBalance = reserveBalance + remainingReserveTokens;
        uint256 n = currentSupply / PRECISION;

        while (totalCost(n) <= newReserveBalance) {
            n++;
        }

        uint256 remainingBalance = newReserveBalance - totalCost(n - 1);
        uint256 remainingFragment = (remainingBalance * PRECISION) / n;
        purchaseReturn = (n - 1) * PRECISION + remainingFragment;

        // // Variables to store the current token prices
        // uint256 currentDiscreteTokenPrice;
        // uint256 remainingCurrentDiscreteTokenPrice;
        // uint256 percentDiscreteTokenRemaining;

        // // Get amount remaining within current token price
        // currentDiscreteTokenPrice = initialCost + (((currentSupply / PRECISION) * initialCost));
        // percentDiscreteTokenRemaining = (PRECISION - currentSupply % PRECISION);
        // remainingCurrentDiscreteTokenPrice = (percentDiscreteTokenRemaining * currentDiscreteTokenPrice) / PRECISION;

        // // Loop through the remainingReserveTokens to calculate the amount of tokens that can be purchased
        // while (remainingReserveTokens > 0) {
        //     if (remainingCurrentDiscreteTokenPrice < currentDiscreteTokenPrice) {
        //         remainingReserveTokens -= remainingCurrentDiscreteTokenPrice;
        //         purchaseReturn += percentDiscreteTokenRemaining; // Partial token purchased
        //         currentSupply += percentDiscreteTokenRemaining; // Move to the next token
        //         currentDiscreteTokenPrice = initialCost + ((currentSupply / PRECISION) * initialCost);
        //         remainingCurrentDiscreteTokenPrice = currentDiscreteTokenPrice;
        //         percentDiscreteTokenRemaining = (PRECISION - currentSupply % PRECISION);
        //     } else if (remainingReserveTokens < currentDiscreteTokenPrice) {
        //         purchaseReturn += (remainingReserveTokens * PRECISION / remainingCurrentDiscreteTokenPrice);
        //         currentSupply += (remainingReserveTokens * PRECISION / remainingCurrentDiscreteTokenPrice);
        //         break;
        //     } else {
        //         remainingReserveTokens -= remainingCurrentDiscreteTokenPrice;
        //         purchaseReturn += PRECISION; // Whole token purchased
        //         currentSupply += PRECISION; // Move to the next token
        //         currentDiscreteTokenPrice = initialCost + ((currentSupply / PRECISION) * initialCost);
        //         remainingCurrentDiscreteTokenPrice = currentDiscreteTokenPrice;
        //     }
        // }

        // Transfer protocol fees to the protocol fee destination
        (bool success,) = protocolFeeDestination.call{value: fees}("");
        if (!success) {
            revert("Protocol fee transfer failed");
        }

        return (purchaseReturn, fees);
    }

    /// @notice Function to calculate the total cost of tokens given the number of tokens.
    function totalCost(uint256 n) public view returns (uint256) {
        return (n * (n + 1) * initialCost) / 2;
    }

    /// @notice Calculates the amount of ether that can be returned for the given amount of tokens.
    /// @param currentSupply supply of tokens.
    /// @param reserveBalance The balance of reserve tokens (in wei).
    /// @param amount The amount of tokens to sell.
    function calculateSaleReturn(uint256 currentSupply, uint256 reserveBalance, uint256 amount)
        external
        returns (uint256 saleReturn, uint256 fees)
    {
        // Variables to store the current token prices
        uint256 currentDiscreteTokenPrice;
        uint256 remainingCurrentDiscreteTokenPrice;
        uint256 percentDiscreteTokenRemaining;

        // Variables to calculate the sale return
        uint256 rawSaleReturn;
        uint256 tokensRemaining = amount;

        // Get amount remaining within current token price
        currentDiscreteTokenPrice = initialCost + (((currentSupply / PRECISION) - 1) * initialCost);
        percentDiscreteTokenRemaining = (PRECISION - currentSupply % PRECISION);
        remainingCurrentDiscreteTokenPrice = (percentDiscreteTokenRemaining * currentDiscreteTokenPrice) / PRECISION;

        while (tokensRemaining > 0) {
            if (tokensRemaining < percentDiscreteTokenRemaining) {
                rawSaleReturn += (tokensRemaining * remainingCurrentDiscreteTokenPrice) / PRECISION;
                break;
            } else {
                rawSaleReturn += remainingCurrentDiscreteTokenPrice;
                tokensRemaining -= percentDiscreteTokenRemaining;
                currentSupply -= percentDiscreteTokenRemaining;
                currentDiscreteTokenPrice = initialCost + ((currentSupply / PRECISION) * initialCost);
                remainingCurrentDiscreteTokenPrice = currentDiscreteTokenPrice;
                percentDiscreteTokenRemaining = (PRECISION - currentSupply % PRECISION);
            }
        }

        // Calculate protocol fees
        fees = (rawSaleReturn * protocolFeePercent) / PRECISION;
        saleReturn = rawSaleReturn - fees;

        // Transfer protocol fees to the protocol fee destination
        (bool success,) = protocolFeeDestination.call{value: fees}("");
        if (!success) {
            revert("Protocol fee transfer failed");
        }

        return (saleReturn, fees);
    }

    /*//////////////////////////////////////////////////////////////
                            SETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param _feeDestination The address to send protocol fees to.
    function setFeeDestination(address _feeDestination) public {
        protocolFeeDestination = _feeDestination;
    }

    /// @param _feePercent The percentage of the transaction to send to the protocol fee destination.
    function setProtocolFeePercent(uint256 _feePercent) public {
        protocolFeePercent = _feePercent;
    }

    /// @param _initialCost The initial cost of the token.
    function setInitialCost(uint256 _initialCost) public {
        initialCost = _initialCost;
    }

    /// @param _maxGasLimit The maximum gas limit for transactions.
    function setMaxGasLimit(uint256 _maxGasLimit) public {
        maxGasLimit = _maxGasLimit;
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @return The `PRECISION` constant.
    function getPrecision() public pure returns (uint256) {
        return PRECISION;
    }

    /// @return The `BASIS_POINTS_PRECISION` constant.
    function getBasisPointsPrecision() public pure returns (uint256) {
        return BASIS_POINTS_PRECISION;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override {}
}
