// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleCoin is ERC20Burnable {
    /// @dev Emitted when attempting to perform an action with an amount that must be more than zero.
    error SimpleCoin__AmountMustBeMoreThanZero();

    /// @dev Emitted when attempting to burn an amount that exceeds the sender's balance.
    error SimpleCoin__BurnAmountExceedsBalance();

    /// @dev Emitted when attempting to perform an action with a zero address.
    error SimpleCoin__NotZeroAddress();

    constructor() ERC20("SimpleCoin", "KISS") {}

    /// @dev Function to mint tokens
    /// @param _to The address that will receive the minted tokens
    /// @param _amount The amount of tokens to mint
    /// @return A boolean that indicates if the operation was successful
    function mint(address _to, uint256 _amount) external returns (bool) {
        if (_to == address(0)) {
            revert SimpleCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert SimpleCoin__AmountMustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }

    /// @dev Function to burn tokens
    /// @param _amount The amount of tokens to burn
    /// @inheritdoc ERC20Burnable
    function burn(uint256 _amount) public override {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert SimpleCoin__AmountMustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert SimpleCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }
}
