// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {console2} from "forge-std/console2.sol";

/// @title LinearBondingCurve
/// @author Dustin Stacy
/// @notice This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
///         The price of tokens increases linearly with the supply.
contract LinearBondingCurve is Initializable, OwnableUpgradeable, UUPSUpgradeable {
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
    /// @param initialCost Initial cost of the token.
    /// @param amount Amount of tokens to buy.
    /// @return price Price of tokens in the reserve currency.
    /// @dev Need to implement protocol fees and gas calculations.
    /// @dev Need to set a max gas price to prevent frontrunning.
    function getPrice(
        uint256 supply,
        uint256, /* scalingFactor */
        uint256 initialCost,
        uint256, /* maxCost */
        uint256 amount
    ) external pure returns (uint256 price) {
        for (uint256 i = 1; i <= amount; i++) {
            price += ((supply + i) * initialCost);
        }

        return price;
    }

    // function getSalePrice(uint256 totalSupply, uint256 scalingFactor, uint256 initialCost, uint256 amount)
    //     public
    //     pure
    //     returns (uint256 price)
    // {
    //     price = (totalSupply - 1) * scalingFactor * DECIMALS;
    // }
}
