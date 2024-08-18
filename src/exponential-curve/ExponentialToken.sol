// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";

/// @title ExponentialCurveToken
/// @author Dustin Stacy
/// @notice This contract implements a simple ERC20 token that can be bought and sold using an exponential bonding curve.
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
    ExponentialBondingCurve private immutable i_bondingCurve;

    /// @notice The total amount of Ether held in the contract.
    uint256 public reserveBalance;

    /// @notice The maximum gas limit for transactions.
    /// @dev This value should be set to prevent front-running attacks.
    uint256 public maxGasLimit;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Event to log token purchases.
    event TokensPurchased(address indexed buyer, uint256 amountSpent, uint256 fees, uint256 tokensMinted);

    /// @notice Event to log token sales.
    event TokensSold(address indexed seller, uint256 amountReceived, uint256 fees, uint256 tokensBurnt);

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Modifier to check if the transaction gas price is below the maximum gas limit.
    modifier validGasPrice() {
        require(tx.gasprice <= maxGasLimit, "Transaction gas price cannot exceed maximum gas limit.");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /// @param _name The name of the token.
    /// @param _symbol The symbol of the token.
    /// @param _bcAddress The address of the ExponentialBondingCurve contract.
    constructor(string memory _name, string memory _symbol, address _bcAddress) ERC20(_name, _symbol) {
        require(_bcAddress != address(0), "ExponentialToken: bonding curve address cannot be zero address");
        i_bondingCurve = ExponentialBondingCurve(_bcAddress);
        maxGasLimit = i_bondingCurve.maxGasLimit();
        _mint(msg.sender, 1e18);
    }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Allows a user to mint tokens by sending ether to the contract.
    function mintTokens() external payable validGasPrice {
        if (msg.value == 0) {
            revert ExponentialToken__AmountMustBeMoreThanZero();
        }

        // Calculate the amount of tokens to mint.
        (uint256 amount, uint256 fees) = i_bondingCurve.getPurchaseReturn(totalSupply(), reserveBalance, msg.value);

        // Update the reserve balance.
        reserveBalance += (msg.value - fees);

        // Transfer protocol fees to the protocol fee destination
        (bool success,) = i_bondingCurve.protocolFeeDestination().call{value: fees}("");
        if (!success) {
            revert("Protocol fee transfer failed");
        }

        // Mint tokens to the buyer
        _mint(msg.sender, amount);

        // Emit an event to log the purchase.
        emit TokensPurchased(msg.sender, msg.value, fees, amount);
    }

    /// @notice Allows a user to burn tokens and receive ether from the contract.
    /// @param amount The amount of tokens to burn.
    function burnTokens(uint256 amount) external validGasPrice {
        if (amount == 0) {
            revert ExponentialToken__AmountMustBeMoreThanZero();
        }

        // Check if the seller has enough tokens to burn.
        uint256 balance = balanceOf(msg.sender);
        if (balance < amount) {
            revert ExponentialToken__BurnAmountExceedsBalance();
        }

        // Calculate the amount of Ether to return to the seller.
        (uint256 salePrice, uint256 fees) = i_bondingCurve.getSaleReturn(totalSupply(), reserveBalance, amount);
        reserveBalance -= salePrice;

        // Burn tokens from the seller.
        burnFrom(msg.sender, amount);

        // Emit an event to log the sale.
        emit TokensSold(msg.sender, salePrice, fees, amount);

        // Transfer protocol fees to the protocol fee destination
        (bool received,) = i_bondingCurve.protocolFeeDestination().call{value: fees}("");
        if (!received) {
            revert("Protocol fee transfer failed");
        }

        // Transfer Ether to the seller.
        (bool sent,) = payable(msg.sender).call{value: salePrice}("");
        if (!sent) {
            revert("Token sale transfer failed");
        }
    }
}
