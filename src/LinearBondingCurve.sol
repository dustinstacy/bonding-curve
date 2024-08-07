// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {console2} from "forge-std/console2.sol"; // remove from production

/// @title LinearBondingCurve
/// @author Dustin Stacy
/// @notice This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
///         The price of tokens increases linearly with the supply.
contract LinearBondingCurve is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;

    /// @notice The precision used in calculations.
    uint256 private constant PRECISION = 1e18;

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

    /// @notice Calculates the amount of tokens that can be purchased with the given value.
    /// @param currentSupply The current currentSupply of tokens.
    /// @param initialCost The initial cost of the token.
    /// @param value The amount of ether sent to purchase tokens.
    /// @dev This is the function getPurchaseReturn should call to determine the amount of tokens to mint after fees.
    /// @dev Currently tested for precision down to the wei.
    /// @dev This function is gas inefficient and needs to be optimized.
    function calculatePurchaseReturn(uint256 currentSupply, uint256 initialCost, uint256 value)
        external
        pure
        returns (uint256 rawPurchaseReturn)
    {
        // Placeholder until scaling introduced
        uint256 tokenPriceIncrement = initialCost;

        // Variables to store the current token prices
        uint256 currentDiscreteTokenPrice;
        uint256 remainingCurrentDiscreteTokenPrice;
        uint256 percentDiscreteTokenRemaining;

        // Check if initial supply is zero for correct initialization
        if (currentSupply == 0) {
            remainingCurrentDiscreteTokenPrice = initialCost;
            currentDiscreteTokenPrice = initialCost;
        } else {
            // Get amount remaining within current token price
            currentDiscreteTokenPrice = initialCost + (((currentSupply / PRECISION) * tokenPriceIncrement));
            percentDiscreteTokenRemaining = (PRECISION - currentSupply % PRECISION);
            remainingCurrentDiscreteTokenPrice = (percentDiscreteTokenRemaining * currentDiscreteTokenPrice) / PRECISION;
        }

        // Loop through the value to calculate the amount of tokens that can be purchased
        /// @dev This loop is the primary gas inefficiency in the contract.
        while (value > 0) {
            if (remainingCurrentDiscreteTokenPrice < currentDiscreteTokenPrice) {
                value -= remainingCurrentDiscreteTokenPrice;
                rawPurchaseReturn += percentDiscreteTokenRemaining; // Partial token purchased
                currentSupply += percentDiscreteTokenRemaining; // Move to the next token
                currentDiscreteTokenPrice = initialCost + ((currentSupply / PRECISION) * tokenPriceIncrement);
                remainingCurrentDiscreteTokenPrice = currentDiscreteTokenPrice;
                percentDiscreteTokenRemaining = (PRECISION - currentSupply % PRECISION);
            } else if (value < currentDiscreteTokenPrice) {
                rawPurchaseReturn += (value * PRECISION / remainingCurrentDiscreteTokenPrice);
                currentSupply += (value * PRECISION / remainingCurrentDiscreteTokenPrice);
                break;
            } else {
                value -= remainingCurrentDiscreteTokenPrice;
                rawPurchaseReturn += PRECISION; // Whole token purchased
                currentSupply += PRECISION; // Move to the next token
                currentDiscreteTokenPrice = initialCost + ((currentSupply / PRECISION) * tokenPriceIncrement);
                remainingCurrentDiscreteTokenPrice = currentDiscreteTokenPrice;
            }
        }
    }

    /// @notice Calculates the amount of ether needed to purchase the next full token.
    /// @param currentSupply supply of tokens.
    /// @param initialCost The initial cost of the token.
    /// @dev If fees are implemented, this function should return the total cost of the token after fees.
    /// @dev Could just boil down to current supply * initial cost + token price increment?
    function calculateReserveTokensNeeded(uint256 currentSupply, uint256 initialCost)
        external
        pure
        returns (uint256 reserveTokensNeeded)
    {
        // Placeholder until scaling introduced
        uint256 tokenPriceIncrement = initialCost;

        // Variables to store the current token prices
        uint256 currentDiscreteTokenPrice;
        uint256 remainingCurrentDiscreteTokenPrice;
        uint256 percentDiscreteTokenRemaining;

        currentDiscreteTokenPrice = initialCost + (((currentSupply / PRECISION) * tokenPriceIncrement));
        percentDiscreteTokenRemaining = (PRECISION - currentSupply % PRECISION);
        remainingCurrentDiscreteTokenPrice = (percentDiscreteTokenRemaining * currentDiscreteTokenPrice) / PRECISION;

        if (remainingCurrentDiscreteTokenPrice < currentDiscreteTokenPrice) {
            reserveTokensNeeded += remainingCurrentDiscreteTokenPrice;
            currentSupply += percentDiscreteTokenRemaining;
            currentDiscreteTokenPrice = initialCost + ((currentSupply / PRECISION) * tokenPriceIncrement);
            console2.log("currentDiscreteTokenPrice", currentDiscreteTokenPrice);
            uint256 percentNextDiscreteTokenRemaining = (PRECISION - percentDiscreteTokenRemaining % PRECISION);
            console2.log("percentNextDiscreteTokenRemaining", percentNextDiscreteTokenRemaining);
            remainingCurrentDiscreteTokenPrice =
                (percentNextDiscreteTokenRemaining * currentDiscreteTokenPrice) / PRECISION;
            reserveTokensNeeded += remainingCurrentDiscreteTokenPrice;
        } else {
            reserveTokensNeeded = currentDiscreteTokenPrice;
        }

        return reserveTokensNeeded;
    }

    /// @notice Calculates the purchase return after protocol fees are deducted.
    /// @param currentSupply supply of tokens.
    /// @param initialCost The initial cost of the token.
    /// @param value The amount of ether sent to purchase tokens.
    /// @dev This is the function the token contract should call to determine the amount of tokens to mint.
    /// @dev If fees are implemented, this function should return the amount of tokens to mint after fees.
    function getBuyPriceAfterFees(uint256 currentSupply, uint256 initialCost, uint256 value)
        external
        pure
        returns (uint256)
    {}

    /// @notice Calculates the amount of ether that can be returned for the given amount of tokens.
    /// @param currentSupply supply of tokens.
    /// @param initialCost The initial cost of the token.
    /// @param amount The amount of tokens to sell.
    /// @dev Need to add a sell penalty to the calculation.
    function getSaleReturn(uint256 currentSupply, uint256 initialCost, uint256 amount)
        external
        pure
        returns (uint256)
    {}

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param _feeDestination The address to send protocol fees to.
    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    /// @param _feePercent The percentage of the transaction to send to the protocol fee destination.
    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
    }

    /// @return The `PRECISION` constant.
    function getPrecision() public pure returns (uint256) {
        return PRECISION;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // Saving if reserve context is needed for future optimization.
    // function _getReserveAmount(uint256 currentSupply, uint256 initialCost)
    //     internal
    //     pure
    //     returns (uint256)
    // {
    //     // Convert inputs to fixed-point arithmetic
    //     uint256 scaledInitialCost = initialCost * PRECISION;
    //     uint256 scaledTokenPriceIncrement = scaledInitialCost;

    //     // Handle the case where currentSupply is zero
    //     if (currentSupply == 0) {
    //         return 0;
    //     }

    //     // Total Reserve = currentSupply * initialCost + tokenPriceIncrement * ((currentSupply - 1) * currentSupply / 2)
    //     uint256 sumOfIncrements;

    //     // Use fixed-point arithmetic for accurate calculation
    //     if (currentSupply >= PRECISION) {
    //         sumOfIncrements = (scaledTokenPriceIncrement * (currentSupply - PRECISION) * currentSupply) / (2 * PRECISION);
    //     } else {
    //         sumOfIncrements = 0;
    //     }

    //     uint256 totalReserve = (currentSupply * scaledInitialCost) / PRECISION + sumOfIncrements / PRECISION;
    //     return (totalReserve / PRECISION);
    // }
}
