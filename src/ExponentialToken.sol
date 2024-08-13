// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ExponentialBondingCurve} from "src/ExponentialBondingCurve.sol";

/// @title ExponentialCurveToken
/// @author Dustin Stacy
/// @notice This contract implements a simple ERC20 token that can be bought and sold using an exponential bonding curve.
///         The price of the token is determined by the bonding curve, which adjusts based on the total supply.
///         The bonding curve is defined by a scaling factor, which determines the steepness of the curve.
/// @dev Similar to the Bancor curve, this curve is also based on a total reserve balance.
///      Standardizing this value will ensure consistency across all implementations.
///      This value will be set in Wei (or other reserve currency).
///      The host will have to be responsible for sending this value to the contract.
contract ExponentialToken is ERC20Burnable {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Emitted when attempting to perform an action with an amount that must be more than zero.
    error ExponentialToken__AmountMustBeMoreThanZero();

    /// @dev Emitted if the buyer does not send enough Ether to purchase the tokens.
    error ExponentialToken__InsufficientFundingForTransaction();

    /// @dev Emitted when attempting to burn an amount that exceeds the sender's balance.
    error ExponentialToken__BurnAmountExceedsBalance();

    /// @dev Emitted when attempting to reduce the total supply below one.
    error ExponentialToken__SupplyCannotBeReducedBelowOne();

    /*///////////////////////////////////////////////////////////////
                             STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice Instance of a Bonding Curve contract used to determine the price of tokens.
    /// @dev In the case of an upgradeable implementation, this should be a proxy contract.
    ExponentialBondingCurve private immutable i_bondingCurve;

    /// @notice The total amount of Ether held in the contract.
    /// @dev This value should be used to determine the reserve balance of the contract.
    /// @dev For now it will be instantiated to a set value for testing purposes.
    /// @dev In the future, a decision will need to be made as to how to initialize this value.
    uint256 public reserveBalance;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Event to log token purchases.
    event TokensPurchased(address indexed buyer, uint256 amountSpent, uint256 fees, uint256 tokensMinted);

    /// @notice Event to log token sales.
    event TokensSold(address indexed seller, uint256 amountReceived, uint256 fees, uint256 tokensBurnt);

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /// @param _name The name of the token.
    /// @param _symbol The symbol of the token.
    /// @param _bcAddress The address of the ExponentialBondingCurve contract.
    /// @dev   If the ExponentialBondingCurve contract is upgradeable, `_bcAddress` should be the proxy address.
    /// @dev   Need to implement a cleaner way to set the required reserve balance.
    constructor(string memory _name, string memory _symbol, address _bcAddress, uint256 _reserveBalance)
        ERC20(_name, _symbol)
    {
        require(_bcAddress != address(0), "ExponentialToken: bonding curve address cannot be zero address");
        require(_reserveBalance == 0.001 ether);
        i_bondingCurve = ExponentialBondingCurve(_bcAddress);
        reserveBalance = _reserveBalance;
        _mint(msg.sender, 1e18);
    }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Allows a user to mint tokens by sending ether to the contract.
    /// @dev The amount of tokens minted is determined by the bonding curve.
    /// @dev Need to implement a gas limit to prevent front-running attacks.
    function mintTokens() external payable {
        if (msg.value == 0) {
            revert ExponentialToken__AmountMustBeMoreThanZero();
        }

        // Calculate the amount of tokens to mint.
        (uint256 amount, uint256 fees) =
            i_bondingCurve.calculatePurchaseReturn(totalSupply(), reserveBalance, msg.value);

        // Update the reserve balance.
        reserveBalance += (msg.value - fees);

        // Mint tokens to the buyer
        _mint(msg.sender, amount);

        // Emit an event to log the purchase.
        emit TokensPurchased(msg.sender, msg.value, fees, amount);
    }

    /// @param amount The amount of tokens to burn.
    /// @dev Need to implement a gas limit to prevent front-running attacks.
    /// @dev CEI is implemented here so is OZ nonReentrant modifier necessary?
    function burnTokens(uint256 amount) external {
        if (amount == 0) {
            revert ExponentialToken__AmountMustBeMoreThanZero();
        }

        /// Do we want to enforce this to prevent bricking the contract?
        if (totalSupply() - amount < 1e18) {
            revert ExponentialToken__SupplyCannotBeReducedBelowOne();
        }

        // Check if the seller has enough tokens to burn.
        uint256 balance = balanceOf(msg.sender);
        if (balance < amount) {
            revert ExponentialToken__BurnAmountExceedsBalance();
        }

        // Calculate the amount of Ether to return to the seller.
        (uint256 salePrice, uint256 fees) = i_bondingCurve.calculateSaleReturn(totalSupply(), reserveBalance, amount);
        reserveBalance -= salePrice;

        // Burn tokens from the seller.
        burnFrom(msg.sender, amount);

        // Transfer Ether to the seller.
        payable(msg.sender).transfer(salePrice);

        // Emit an event to log the sale.
        emit TokensSold(msg.sender, salePrice, fees, amount);
    }
}
