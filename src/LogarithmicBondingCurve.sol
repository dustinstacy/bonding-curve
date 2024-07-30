// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {console2} from "forge-std/console2.sol";

/// @title LogarithmicBondingCurve
/// @author Dustin Stacy
/// @notice This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
///         The curve is defined by a scaling factor and a logarithmic dampener, which determines the steepness of the curve.
contract LogarithmicBondingCurve is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;

    /// @dev Using to assess the number of decimal places to use in the price calculation.
    /// @dev Ideally the formula will be updated to use a more accurate way of calculating the price.
    uint256 private constant DECIMALS = 1e2;

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
    // @param maxCost Maximum cost of the token.
    /// @param amount Amount of tokens to buy.
    /// @return price Price of tokens in the reserve currency.
    /// @dev Need to address how to adjust the rate at which the logarithmic curve increases.
    /// @dev Need to implement protocol fees and gas calculations.
    /// @dev Need to set a max gas price to prevent frontrunning.
    function getPrice(uint256 supply, uint256 scalingFactor, uint256 initialCost, uint256, /* maxCost */ uint256 amount)
        external
        pure
        returns (uint256 price)
    {
        if (supply == 0 && amount == 1) {
            return initialCost;
        }

        for (uint256 i = 1; i <= amount; i++) {
            price += ((((initialCost * ((log2(supply + i)) * supply)) / scalingFactor)) * DECIMALS) + initialCost;
        }
    }

    // function getSalePrice(uint256 totalSupply, uint256 scalingFactor, uint256 initialCost, uint256 amount)
    //     public
    //     pure
    //     returns (uint256 price)
    // {
    //     price = (totalSupply - 1) * scalingFactor * DECIMALS;
    // }

    /// @notice Function to calculate the log base 2 of a number.
    /// @dev Need to assess the gas cost of this function versus the assembly version.
    function log2(uint256 b) public pure returns (uint256) {
        //if(b==0){return 0;}
        uint256 up = 256;
        uint256 down = 0;
        uint256 attempt = (up + down) / 2;
        while (up > down + 4) {
            if (b >= (2 ** attempt)) {
                down = attempt;
            } else {
                up = attempt;
            }
            attempt = (up + down) / 2;
        }
        uint256 temp = 2 ** down;
        while (temp <= b) {
            down++;
            temp = temp * 2;
        }
        return down;
    }

    // Assembly version of log2
    // function log2(uint256 x) public pure returns (uint256 y) {
    //     assembly {
    //         let arg := x
    //         x := sub(x, 1)
    //         x := or(x, div(x, 0x02))
    //         x := or(x, div(x, 0x04))
    //         x := or(x, div(x, 0x10))
    //         x := or(x, div(x, 0x100))
    //         x := or(x, div(x, 0x10000))
    //         x := or(x, div(x, 0x100000000))
    //         x := or(x, div(x, 0x10000000000000000))
    //         x := or(x, div(x, 0x100000000000000000000000000000000))
    //         x := add(x, 1)
    //         let m := mload(0x40)
    //         mstore(m, 0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
    //         mstore(add(m, 0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
    //         mstore(add(m, 0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
    //         mstore(add(m, 0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
    //         mstore(add(m, 0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
    //         mstore(add(m, 0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
    //         mstore(add(m, 0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
    //         mstore(add(m, 0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
    //         mstore(0x40, add(m, 0x100))
    //         let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
    //         let shift := 0x100000000000000000000000000000000000000000000000000000000000000
    //         let a := div(mul(x, magic), shift)
    //         y := div(mload(add(m, sub(255, a))), shift)
    //         y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
    //     }
    // }
}
