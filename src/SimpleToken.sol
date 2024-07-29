// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {BondingCurve} from "src/BondingCurve.sol";

/// @title SimpleToken
/// @author Dustin Stacy
/// @notice This contract implements a simple ERC20 token that can be bought and sold using a bonding curve.
///         It is designed to work with a bonding curve that is defined by a reserve ratio.
contract SimpleToken is ERC20Burnable {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Emitted when attempting to perform an action with an amount that must be more than zero.
    error SimpleToken__AmountMustBeMoreThanZero();

    /// @dev Emitted if the buyer does not send enough Ether to purchase the tokens.
    error SimpleToken__InsufficientFundingForTransaction();

    /// @dev Emitted when attempting to burn an amount that exceeds the sender's balance.
    error SimpleToken__BurnAmountExceedsBalance();

    /*///////////////////////////////////////////////////////////////
                             STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice Instance of the BondingCurve contract used to determine the price of tokens.
    /// @dev In the case of an upgradeable implementation, this should be a proxy contract.
    BondingCurve private immutable i_bondingCurve;

    /// @notice  reserveBalance keeps track of the total amount of Ether (or other reserve currency)
    ///          held by the contract.
    ///          This balance is crucial for the functioning of the bonding curve as it influences
    ///          the price of tokens.
    uint256 public reserveBalance;

    /// @notice reserveRatio is used to define the steepness or shape of the bonding curve. It's
    ///         specified in basis points, where 100 basis points equal 1 percent. For example,
    ///         a reserve ratio of 5000 corresponds to a 50% reserve ratio.
    uint32 public reserveRatio;

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
    /// @param bcAddress The address of the BondingCurve contract.
    ///        If the BondingCurve contract is upgradeable, this should be the proxy address.
    /// @param _reserveRatio The reserve ratio used to determine the price of tokens.
    constructor(string memory _name, string memory _symbol, address bcAddress, uint32 _reserveRatio)
        ERC20(_name, _symbol)
    {
        i_bondingCurve = BondingCurve(bcAddress);
        reserveRatio = _reserveRatio;
    }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @param amount The amount of tokens to buy.
    function buyTokens(uint256 amount) external payable {
        if (amount == 0) {
            revert SimpleToken__AmountMustBeMoreThanZero();
        }

        uint256 price = i_bondingCurve.getPrice(totalSupply(), reserveBalance, reserveRatio, amount);

        if (msg.value < price) {
            revert SimpleToken__InsufficientFundingForTransaction();
        }

        // Update reserve balance and total supply
        reserveBalance += price;

        // Mint tokens to the buyer
        _mint(msg.sender, amount);

        emit TokensPurchased(msg.sender, price, amount);
    }

    /// @param amount The amount of tokens to sell.
    function sellTokens(uint256 amount) external {
        if (amount == 0) {
            revert SimpleToken__AmountMustBeMoreThanZero();
        }

        uint256 salePrice = i_bondingCurve.getSalePrice(totalSupply(), reserveBalance, reserveRatio, amount);

        // Check if the contract has enough reserve to buy the tokens.
        if (salePrice > reserveBalance) {
            revert SimpleToken__InsufficientFundingForTransaction();
        }

        uint256 balance = balanceOf(msg.sender);

        // Check if the seller has enough tokens to sell.
        if (balance < amount) {
            revert SimpleToken__BurnAmountExceedsBalance();
        }

        // Update reserve balance and total supply
        reserveBalance -= salePrice;

        // Burn tokens from the seller
        burnFrom(msg.sender, amount);

        // Transfer Ether to the seller
        payable(msg.sender).transfer(salePrice);

        emit TokensSold(msg.sender, salePrice, amount);
    }
}
