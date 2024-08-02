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
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;

    /// @notice The precision used in calculations.
    uint256 private constant PRECISION = 1e18;

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

    /// @notice Function to calculate the buy price of tokens based on a bonding curve formula.
    /// @param supply Supply of tokens in circulation.
    /// @param initialCost Initial cost of the token.
    /// @param scalingFactor Scaling factor used to determine the price of tokens.
    /// @param amount Amount of tokens to buy.
    /// @return totalPrice Price of tokens in the reserve currency.
    /// @dev Need to implement protocol fees and gas calculations.
    /// @dev Need to set a max gas price to prevent frontrunning.
    function getRawBuyPrice(
        uint256 supply,
        uint256 initialCost,
        uint256 scalingFactor,
        uint256 amount,
        int256 initialCostAdjustment
    ) external pure returns (uint256 totalPrice) {
        for (uint256 i = 1; i <= amount; i++) {
            uint256 price = ((supply + i) * (initialCost));
            uint256 scaledTotalPrice = price * scalingFactor / PRECISION; // Adjust price by scaling factor
            totalPrice += uint256(int256(scaledTotalPrice) + initialCostAdjustment);
        }

        return totalPrice;
    }

    /// @notice Function to calculate the sell price of tokens based on a bonding curve formula.
    /// @param supply Supply of tokens in circulation.
    /// @param initialCost Initial cost of the token.
    /// @param scalingFactor Scaling factor used to determine the price of tokens.
    /// @param amount Amount of tokens to sell.
    /// @return totalPrice Price of tokens in the reserve currency.
    /// @dev Need to implement protocol fees and gas calculations.
    /// @dev Need to set a max gas price to prevent frontrunning.
    function getRawSellPrice(
        uint256 supply,
        uint256 initialCost,
        uint256 scalingFactor,
        uint256 amount,
        int256 initialCostAdjustment
    ) external pure returns (uint256 totalPrice) {
        for (uint256 i = 0; i <= amount - 1; i++) {
            uint256 price = ((supply - i) * (initialCost));
            uint256 scaledTotalPrice = price * scalingFactor / PRECISION; // Adjust price by scaling factor
            totalPrice += uint256(int256(scaledTotalPrice) + initialCostAdjustment);
        }

        return totalPrice;
    }

    /// @return The `PRECISION` constant.
    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }
}
