// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

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

    /// @notice Calculates the amount of tokens that can be purchased with the given value.
    /// @param currentSupply The current currentSupply of tokens.
    /// @param value The amount of ether sent to purchase tokens.
    /// @dev Currently tested for precision down to the wei.
    /// @dev This function is gas inefficient and needs to be optimized.
    function calculatePurchaseReturn(uint256 currentSupply, uint256 value) external returns (uint256 purchaseReturn) {
        require(initialCost > 0, "Initial cost must be greater than zero");
        require(value > 0, "Value must be greater than zero");

        // Variables to store the current token prices
        uint256 currentDiscreteTokenPrice;
        uint256 remainingCurrentDiscreteTokenPrice;
        uint256 percentDiscreteTokenRemaining;
        uint256 rawPurchaseReturn;

        // Check if initial supply is zero for correct initialization
        if (currentSupply == 0) {
            remainingCurrentDiscreteTokenPrice = initialCost;
            currentDiscreteTokenPrice = initialCost;
        } else {
            // Get amount remaining within current token price
            currentDiscreteTokenPrice = initialCost + (((currentSupply / PRECISION) * initialCost));
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
                currentDiscreteTokenPrice = initialCost + ((currentSupply / PRECISION) * initialCost);
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
                currentDiscreteTokenPrice = initialCost + ((currentSupply / PRECISION) * initialCost);
                remainingCurrentDiscreteTokenPrice = currentDiscreteTokenPrice;
            }
        }

        uint256 fees = (rawPurchaseReturn * protocolFeePercent) / PRECISION;
        purchaseReturn = rawPurchaseReturn - fees;

        // Transfer protocol fees to the protocol fee destination
        (bool success,) = protocolFeeDestination.call{value: fees}("");
        if (!success) {
            revert("Protocol fee transfer failed");
        }

        return purchaseReturn;
    }

    /// @notice Calculates the amount of ether that can be returned for the given amount of tokens.
    /// @param currentSupply supply of tokens.
    /// @param amount The amount of tokens to sell.
    /// @dev Need to add a sell penalty to the calculation.
    /// @dev Do protocol fees apply to the sale of tokens as well?
    function calculateSaleReturn(uint256 currentSupply, uint256 amount) external returns (uint256 saleReturn) {
        // Variables to store the current token prices
        uint256 currentDiscreteTokenPrice;
        uint256 remainingCurrentDiscreteTokenPrice;
        uint256 percentDiscreteTokenRemaining;

        if (amount == currentSupply) {
            if (currentSupply <= PRECISION) {
                return (initialCost * amount / PRECISION);
            }
            return initialCost + (((currentSupply / PRECISION)) * initialCost);
        }

        // Get amount remaining within current token price
        currentDiscreteTokenPrice = initialCost + (((currentSupply / PRECISION) - 1) * initialCost);
        percentDiscreteTokenRemaining = (PRECISION - currentSupply % PRECISION);
        remainingCurrentDiscreteTokenPrice = (percentDiscreteTokenRemaining * currentDiscreteTokenPrice) / PRECISION;

        uint256 rawSaleReturn;
        uint256 tokensRemaining = amount;

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

        uint256 fees = (rawSaleReturn * protocolFeePercent) / PRECISION;
        saleReturn = rawSaleReturn - fees;

        // Transfer protocol fees to the protocol fee destination
        (bool success,) = protocolFeeDestination.call{value: fees}("");
        if (!success) {
            revert("Protocol fee transfer failed");
        }

        return saleReturn;
    }

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

    /// @param _initialCost The initial cost of the token.
    function setInitialCost(uint256 _initialCost) public onlyOwner {
        initialCost = _initialCost;
    }

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
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
