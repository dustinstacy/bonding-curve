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
    /// @param supply The current supply of tokens.
    /// @param initialCost The initial cost of the token.
    /// @param value The amount of ether sent to purchase tokens.
    function getRawPurchaseReturn(uint256 supply, uint256 initialCost, uint256 value)
        external
        pure
        returns (uint256 rawPurchaseReturn)
    {
        // Placeholder until scaling introduced
        uint256 tokenPriceIncrement = initialCost;

        // Variables to store the current token prices
        uint256 currentDiscreetTokenPrice;
        uint256 remainingCurrentDiscreetTokenPrice;
        uint256 percentDiscreetTokenRemaining;

        // Check if initial supply is zero for correct initialization
        if (supply == 0) {
            remainingCurrentDiscreetTokenPrice = initialCost;
            currentDiscreetTokenPrice = initialCost;
        } else {
            // Get amount remaining within current token price
            currentDiscreetTokenPrice = initialCost + (((supply / PRECISION) * tokenPriceIncrement));
            percentDiscreetTokenRemaining = (PRECISION - supply % PRECISION);
            remainingCurrentDiscreetTokenPrice = (percentDiscreetTokenRemaining * currentDiscreetTokenPrice) / PRECISION;
        }

        // Loop through the value to calculate the amount of tokens that can be purchased
        /// @dev This loop is gas inefficient and should be optimized.
        while (value > 0) {
            if (remainingCurrentDiscreetTokenPrice < currentDiscreetTokenPrice) {
                value -= remainingCurrentDiscreetTokenPrice;
                rawPurchaseReturn += percentDiscreetTokenRemaining; // Partial token purchased
                supply += percentDiscreetTokenRemaining; // Move to the next token
                currentDiscreetTokenPrice = initialCost + ((supply / PRECISION) * tokenPriceIncrement);
                remainingCurrentDiscreetTokenPrice = currentDiscreetTokenPrice;
                percentDiscreetTokenRemaining = (PRECISION - supply % PRECISION);
            } else if (value < currentDiscreetTokenPrice) {
                console2.log("Value: ", value);
                console2.log(value * PRECISION / remainingCurrentDiscreetTokenPrice);
                rawPurchaseReturn += (value * PRECISION / remainingCurrentDiscreetTokenPrice);
                console2.log("Raw Purchase Return: ", rawPurchaseReturn);
                supply += (value * PRECISION / remainingCurrentDiscreetTokenPrice);
                console2.log("Supply: ", supply);
                break;
            } else {
                value -= remainingCurrentDiscreetTokenPrice;
                rawPurchaseReturn += PRECISION; // Whole token purchased
                supply += PRECISION; // Move to the next token
                currentDiscreetTokenPrice = initialCost + ((supply / PRECISION) * tokenPriceIncrement);
                remainingCurrentDiscreetTokenPrice = currentDiscreetTokenPrice;
            }
        }
    }

    // function getNextFullTokenPrice(uint256 supply, uint256 initialCost, uint256 tokenPriceIncrement)
    //     external
    //     pure
    //     returns (uint256)
    // {
    //     uint256 currentFractionRemaining = getRemainingcurrentDiscreetTokenPrice(supply, initialCost, tokenPriceIncrement);
    // }

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

    // Save if reserve context is needed
    // function _getReserveAmount(uint256 supply, uint256 initialCost)
    //     internal
    //     pure
    //     returns (uint256)
    // {
    //     // Convert inputs to fixed-point arithmetic
    //     uint256 scaledInitialCost = initialCost * PRECISION;
    //     uint256 scaledTokenPriceIncrement = scaledInitialCost;

    //     // Handle the case where supply is zero
    //     if (supply == 0) {
    //         return 0;
    //     }

    //     // Total Reserve = supply * initialCost + tokenPriceIncrement * ((supply - 1) * supply / 2)
    //     uint256 sumOfIncrements;

    //     // Use fixed-point arithmetic for accurate calculation
    //     if (supply >= PRECISION) {
    //         sumOfIncrements = (scaledTokenPriceIncrement * (supply - PRECISION) * supply) / (2 * PRECISION);
    //     } else {
    //         sumOfIncrements = 0;
    //     }

    //     uint256 totalReserve = (supply * scaledInitialCost) / PRECISION + sumOfIncrements / PRECISION;
    //     return (totalReserve / PRECISION);
    // }
}
