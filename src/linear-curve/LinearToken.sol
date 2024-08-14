// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {Calculations} from "src/libraries/Calculations.sol";

/// @title LinearCurveToken
/// @author Dustin Stacy
/// @notice This contract implements a simple ERC20 token that can be bought and sold using a linear bonding curve.
///         The price of the token is determined by the bonding curve, which adjusts based on the total supply.
contract LinearToken is ERC20Burnable {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Emitted when attempting to perform an action with an amount that must be more than zero.
    error LinearToken__AmountMustBeMoreThanZero();

    /// @dev Emitted if the buyer does not send enough Ether to purchase the tokens.
    error LinearToken__InsufficientFundingForTransaction();

    /// @dev Emitted when attempting to burn an amount that exceeds the sender's balance.
    error LinearToken__BurnAmountExceedsBalance();

    /// @dev Emitted when attempting to reduce the total supply below one.
    error ExponentialToken__SupplyCannotBeReducedBelowOne();

    /*///////////////////////////////////////////////////////////////
                             STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice Instance of a Bonding Curve contract used to determine the price of tokens.
    /// @dev In the case of an upgradeable implementation, this should be a proxy contract.
    LinearBondingCurve private immutable i_bondingCurve;

    /// @notice The maximum gas limit for transactions.
    /// @dev This value should be set to prevent front-running attacks.
    uint256 public maxGasLimit;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Event to log token purchases.
    event TokensPurchased(address indexed buyer, uint256 amountSpent, uint256 tokensMinted);

    /// @notice Event to log token sales.
    event TokensSold(address indexed seller, uint256 amountReceived, uint256 tokensBurnt);

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    modifier validGasPrice() {
        require(tx.gasprice <= maxGasLimit, "Transaction gas price cannot exceed maximum gas limit.");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /// @param _name The name of the token.
    /// @param _symbol The symbol of the token.
    /// @param _bcAddress The address of the LinearBondingCurve contract.
    /// @dev   If the LinearBondingCurve contract is upgradeable, `_bcAddress` should be the proxy address.
    constructor(string memory _name, string memory _symbol, address _bcAddress) ERC20(_name, _symbol) {
        i_bondingCurve = LinearBondingCurve(_bcAddress);
        maxGasLimit = i_bondingCurve.maxGasLimit();
    }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Allows a user to mint tokens by sending Ether to the contract.
    /// @dev The amount of tokens minted is determined by the bonding curve.
    /// @dev Need to implement a gas limit to prevent front-running attacks.
    function mintTokens() external payable validGasPrice {
        if (msg.value == 0) {
            revert LinearToken__AmountMustBeMoreThanZero();
        }

        // Calculate the amount of tokens to mint
        uint256 amount = i_bondingCurve.calculatePurchaseReturn(totalSupply(), msg.value);

        // Mint tokens to the buyer
        _mint(msg.sender, amount);

        // Emit an event to log the purchase.
        emit TokensPurchased(msg.sender, msg.value, amount);
    }

    /// @param amount The amount of tokens to burn.
    /// @dev Need to implement a gas limit to prevent front-running attacks.
    /// @dev CEI is implemented here so is OZ nonReentrant modifier necessary?
    function burnTokens(uint256 amount) external validGasPrice {
        if (amount == 0) {
            revert LinearToken__AmountMustBeMoreThanZero();
        }

        /// Do we want to enforce this to prevent bricking the contract?
        if (totalSupply() - amount < 1e18) {
            revert ExponentialToken__SupplyCannotBeReducedBelowOne();
        }

        // Check if the seller has enough tokens to burn.
        uint256 balance = balanceOf(msg.sender);
        if (balance < amount) {
            revert LinearToken__BurnAmountExceedsBalance();
        }

        // Calculate the amount of Ether to return to the seller
        uint256 salePrice = i_bondingCurve.calculateSaleReturn(totalSupply(), amount);

        // Burn tokens from the seller
        burnFrom(msg.sender, amount);

        // Transfer Ether to the seller
        payable(msg.sender).transfer(salePrice);

        // Emit an event to log the sale
        emit TokensSold(msg.sender, salePrice, amount);
    }
}
