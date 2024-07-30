// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {LinearBondingCurve} from "src/LinearBondingCurve.sol";

/// @title LINToken
/// @author Dustin Stacy
/// @notice This contract implements a simple ERC20 token that can be bought and sold using a bonding curve.
///         It is designed to work with a bonding curve that is defined by a linear ratio.
contract LINToken is ERC20Burnable {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Emitted when attempting to perform an action with an amount that must be more than zero.
    error LINToken__AmountMustBeMoreThanZero();

    /// @dev Emitted if the buyer does not send enough Ether to purchase the tokens.
    error LINToken__InsufficientFundingForTransaction();

    /// @dev Emitted when attempting to burn an amount that exceeds the sender's balance.
    error LINToken__BurnAmountExceedsBalance();

    /*///////////////////////////////////////////////////////////////
                             STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice Instance of the BondingCurve contract used to determine the price of tokens.
    /// @dev In the case of an upgradeable implementation, this should be a proxy contract.
    LinearBondingCurve private immutable i_bondingCurve;

    /// @notice The initial cost of the token.
    /// @dev Cap the scaling factor at 10000 basis points (100%)?
    uint256 public immutable i_initialCost;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Event to log token purchases.
    event TokensPurchased(address indexed buyer, uint256 amountSpent, uint256 tokensMinted);

    /// @notice Event to log token sales.
    event TokensSold(address indexed seller, uint256 amountReceived, uint256 tokensBurnt);

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /// @param _name The name of the token.
    /// @param _symbol The symbol of the token.
    /// @param _initialCost The initial cost of the token.
    /// @param _bcAddress The address of the BondingCurve contract.
    /// @dev   If the ExponentialBondingCurve contract is upgradeable, `_bcAddress` should be the proxy address.
    constructor(string memory _name, string memory _symbol, address _bcAddress, uint256 _initialCost)
        ERC20(_name, _symbol)
    {
        i_initialCost = _initialCost;
        i_bondingCurve = LinearBondingCurve(_bcAddress);
    }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @param amount The amount of tokens to buy.
    /// @dev Needs UI to determine correct value to send before calling this function.
    /// @dev Allow users to send extra to cover changes in supply before the transaction is processed?
    /// @dev If so a refund mechanism should be implemented.
    function buyTokens(uint256 amount) external payable {
        if (amount == 0) {
            revert LINToken__AmountMustBeMoreThanZero();
        }

        uint256 price = i_bondingCurve.getPrice(totalSupply(), i_initialCost, amount);

        if (msg.value < price) {
            revert LINToken__InsufficientFundingForTransaction();
        }

        // Mint tokens to the buyer
        _mint(msg.sender, amount);

        emit TokensPurchased(msg.sender, price, amount);
    }

    // /// @param amount The amount of tokens to sell.
    // function sellTokens(uint256 amount) external {
    //     if (amount == 0) {
    //         revert LINToken__AmountMustBeMoreThanZero();
    //     }

    //     uint256 salePrice = i_bondingCurve.getSalePrice(totalSupply(),  i_initialCost, amount);

    //     // should not be possible
    //     if (address(this).balance < salePrice) {
    //         revert LINToken__InsufficientFundingForTransaction();
    //     }

    //     uint256 balance = balanceOf(msg.sender);

    //     // Check if the seller has enough tokens to sell.
    //     if (balance < amount) {
    //         revert LINToken__BurnAmountExceedsBalance();
    //     }

    //     // Burn tokens from the seller
    //     burnFrom(msg.sender, amount);

    //     // Transfer Ether to the seller
    //     payable(msg.sender).transfer(salePrice);

    //     emit TokensSold(msg.sender, salePrice, amount);
    // }
}
