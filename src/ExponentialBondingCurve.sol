// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {console2} from "forge-std/console2.sol"; // remove from production

/// @title ExponentialBondingCurve
/// @author Dustin Stacy
/// @notice This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
///         The curve is defined by a scaling factor, which determines the steepness and bend of the curve.
contract ExponentialBondingCurve is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;

    /// @dev Disables the default initializer function.
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract with the owner address.
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    /// @param _feeDestination The address to send protocol fees to.
    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    /// @param _feePercent The percentage of the transaction to send to the protocol fee destination.
    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
    }

    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Function to calculate the price of tokens based on a bonding curve formula.
    /// @param supply Supply of tokens in circulation.
    /// @param initialCost Initial cost of the token.
    /// @param scalingFactor Scaling factor used to determine the price of tokens.
    /// @param value Amount of ether sent to purchase tokens.
    /// @return totalTokens Amount of tokens to mint.
    /// @dev Need to implement protocol fees and gas calculations.
    /// @dev Need to set a max gas price to prevent frontrunning.
    /// @dev Need to inspect gas reduction with minting first token to the creator to remove checks.
    function getRawBuyPrice(uint256 supply, uint256 initialCost, uint256 scalingFactor, uint256 value)
        external
        pure
        returns (uint256 totalTokens)
    {
        // uint256 currentSupply = supply;
        // uint256 remainingValue = value;
        // uint256 totalTokens = 0;

        // if (supply == 0) {
        //     if (amount == 1) {
        //         return initialCost;
        //     } else {
        //         uint256 sum = (amount - 1) * (amount) * (2 * (amount - 1) + 1) / 6;
        //         return (sum * initialCost) / scalingFactor + initialCost * amount;
        //     }
        // } else {
        //     uint256 sum1 = (supply - 1) * (supply) * (2 * (supply - 1) + 1) / 6;
        //     uint256 sum2 = (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        //     uint256 totalSum = sum2 - sum1;
        //     return tokens = (totalSum * initialCost / (scalingFactor)) + initialCost * amount;
        // }
        // Start with initial values
        uint256 currentSupply = supply;
        uint256 remainingValue = value;
        totalTokens = 0;
        uint256 price;

        while (remainingValue > 0) {
            uint256 nextSupply = currentSupply + 1;
            price =
                ((initialCost * (nextSupply * nextSupply + currentSupply * nextSupply)) / scalingFactor) + initialCost;
            console2.log("Price: ", price, "Remaining Value: ", remainingValue);

            if (price > remainingValue) {
                // Calculate the fraction of the next token that can be purchased
                uint256 fractionalToken = (remainingValue * 1e18) / price;
                totalTokens += fractionalToken;
                break;
            }

            // Deduct the price from the remaining value
            remainingValue -= price;
            totalTokens += 1e18; // Add one full token to the total
            currentSupply = nextSupply;
        }

        return totalTokens;
    }

    // /// @notice Function to calculate the tokens of tokens based on a bonding curve formula.
    // /// @param supply Supply of tokens in circulation.
    // /// @param initialCost Initial cost of the token.
    // /// @param scalingFactor Scaling factor used to determine the price of tokens.
    // /// @param amount Amount of tokens to buy.
    // /// @return price Price of tokens in the reserve currency.
    // /// @dev Need to implement protocol fees and gas calculations.
    // /// @dev Need to set a max gas price to prevent frontrunning.
    // /// @dev Need to inspect gas reduction with minting first token to the creator to remove checks.
    // function getRawSellPrice(uint256 supply, uint256 initialCost, uint256 scalingFactor, uint256 amount)
    //     external
    //     pure
    //     returns (uint256 price)
    // {
    //     if (supply - amount == 0) {
    //         uint256 sum = (supply - 1) * supply * (2 * (supply - 1) + 1) / 6;
    //         return (sum * initialCost / scalingFactor) + initialCost * amount;
    //     } else if (supply == 1) {
    //         return initialCost;
    //     } else {
    //         uint256 sum1 = ((supply - amount) - 1) * ((supply - amount)) * (2 * ((supply - amount) - 1) + 1) / 6;
    //         uint256 sum2 = (supply - 1) * (supply) * (2 * (supply - 1) + 1) / 6;
    //         uint256 totalSum = sum2 - sum1;
    //         return price = (totalSum * initialCost / (scalingFactor)) + initialCost * amount;
    //     }
    // }
}
