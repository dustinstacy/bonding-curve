// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {console2} from "forge-std/console2.sol";

/// @title ExponentialBondingCurve
/// @author Dustin Stacy
/// @notice This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
///         The curve is defined by a scaling factor, which determines the steepness of the curve.
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

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Function to calculate the price of tokens based on a bonding curve formula.
    /// @param supply Supply of tokens in circulation.
    /// @param scalingFactor Scaling factor used to determine the price of tokens.
    /// @param initialCost Initial cost of the token.
    /// @param amount Amount of tokens to buy.
    /// @return price Price of tokens in the reserve currency.
    /// @dev Need to implement protocol fees and gas calculations.
    /// @dev Need to set a max gas price to prevent frontrunning.
    /// @dev Need to inspect gas reduction with minting first token to the creator to remove checks.
    function getPrice(uint256 supply, uint256 scalingFactor, uint256 initialCost, uint256 amount)
        external
        pure
        returns (uint256 price)
    {
        if (supply == 0 && amount == 1) {
            return initialCost;
        } else if (supply == 0 && amount > 1) {
            uint256 sum1 = 0;
            uint256 sum2 = (supply + amount) * (supply + amount - 1) * (2 * (supply + amount) + 1) / 6;
            uint256 totalSum = sum2 - sum1;
            return price = (totalSum * initialCost / (scalingFactor)) + initialCost * 2;
        } else {
            uint256 sum1 = (supply - 1) * (supply) * (2 * (supply - 1) + 1) / 6;
            uint256 sum2 = (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
            uint256 totalSum = sum2 - sum1;
            return price = (totalSum * initialCost / (scalingFactor)) + initialCost;
        }
    }

    // function getSalePrice(uint256 totalSupply, uint256 scalingFactor, uint256 initialCost, uint256 amount)
    //     public
    //     pure
    //     returns (uint256 price)
    // {
    //     price = (totalSupply - 1) * scalingFactor * DECIMALS;
    // }

    //     )
}
