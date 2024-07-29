// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title BondingCurve
/// @author Dustin Stacy
/// @notice This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
///         The curve is defined by a reserve ratio, which determines the steepness of the curve.
///         The contract is designed to work with ERC20 tokens.
contract BondingCurve is Initializable, OwnableUpgradeable, UUPSUpgradeable {
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

    /// @param amount Amount of tokens to buy.
    /// @dev update with a more complex curve.
    function getPrice(uint256 totalSupply, uint256 reserveBalance, uint256 reserveRatio, uint256 amount)
        public
        pure
        returns (uint256)
    {
        return (totalSupply + amount) * 1e16;
    }

    /// @dev update with a more complex curve.
    function getSalePrice(uint256 totalSupply, uint256 reserveBalance, uint256 reserveRatio, uint256 amount)
        public
        pure
        returns (uint256)
    {
        return (totalSupply) * 1e16;
    }
}
