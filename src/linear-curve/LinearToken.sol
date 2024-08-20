// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";

/// @title LinearCurveToken
/// @author Dustin Stacy
/// @notice This contract implements a simple ERC20 token that can be bought and sold using a linear bonding curve.
contract LinearToken is ERC20Burnable {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Emitted when the buyer does not send the correct amount of Ether to mint the initial token.
    error LinearToken__IncorrectAmountOfEtherSent();

    /// @dev Emitted when attempting to perform an action with an amount that must be more than zero.
    error LinearToken__AmountMustBeMoreThanZero();

    /// @dev Emitted if the buyer does not send enough Ether to purchase the tokens.
    error LinearToken__InsufficientFundingForTransaction();

    /// @dev Emitted when attempting to burn an amount that exceeds the sender's balance.
    error LinearToken__BurnAmountExceedsBalance();

    /// @dev Emitted when attempting to reduce the total supply below one.
    error LinearToken__SupplyCannotBeReducedBelowOne();

    /*///////////////////////////////////////////////////////////////
                             STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice Instance of a Bonding Curve contract used to determine the price of tokens.
    /// @dev In the case of an upgradeable implementation, this should be a proxy contract.
    LinearBondingCurve private immutable i_bondingCurve;

    /// @notice The total amount of Ether held in the contract.
    uint256 public reserveBalance;

    /// @notice The total amount of fees collected by the contract.
    uint256 public collectedFees;

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
        require(tx.gasprice <= i_bondingCurve.maxGasLimit(), "Transaction gas price cannot exceed maximum gas limit.");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /// @param _name The name of the token.
    /// @param _symbol The symbol of the token.
    /// @param _bcAddress The address of the LinearBondingCurve contract.
    /// @param _host The address of the host contract.
    constructor(string memory _name, string memory _symbol, address _bcAddress, address _host)
        payable
        ERC20(_name, _symbol)
    {
        // Check if the bonding curve address is not the zero address and set the bonding curve instance.
        require(_bcAddress != address(0), "ExponentialToken: bonding curve address cannot be zero address");
        i_bondingCurve = LinearBondingCurve(_bcAddress);

        // Mint the initial token to the contract creator.
        if (msg.value != i_bondingCurve.initialReserve()) {
            revert LinearToken__IncorrectAmountOfEtherSent();
        }
        reserveBalance += msg.value;
        _mint(_host, 1e18);
    }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Allows a user to mint tokens by sending Ether to the contract.
    function mintTokens() external payable validGasPrice {
        if (msg.value == 0) {
            revert LinearToken__AmountMustBeMoreThanZero();
        }

        // Calculate the amount of tokens to mint
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

    /// @notice Allows a user to burn tokens and receive Ether from the contract.
    /// @param amount The amount of tokens to burn.
    function burnTokens(uint256 amount) external validGasPrice {
        if (amount == 0) {
            revert LinearToken__AmountMustBeMoreThanZero();
        }

        /// Do we want to enforce this to prevent bricking the contract?
        if (totalSupply() - amount < 1e18) {
            revert LinearToken__SupplyCannotBeReducedBelowOne();
        }

        // Check if the seller has enough tokens to burn.
        uint256 balance = balanceOf(msg.sender);
        if (balance < amount) {
            revert LinearToken__BurnAmountExceedsBalance();
        }

        // Calculate the amount of Ether to return to the seller
        (uint256 salePrice, uint256 fees) = i_bondingCurve.getSaleReturn(totalSupply(), reserveBalance, amount);
        reserveBalance -= salePrice;
        salePrice -= fees;

        // Calculate the share of fees to be collected by the contract.
        if (i_bondingCurve.feeSharePercent() != 0) {
            uint256 feeShare = (fees * i_bondingCurve.feeSharePercent()) / 1e18;
            collectedFees += feeShare;
            fees -= feeShare;
        }

        // Burn tokens from the seller
        burnFrom(msg.sender, amount);

        // Emit an event to log the sale
        emit TokensSold(msg.sender, salePrice, fees, amount);

        // Transfer protocol fees to the protocol fee destination
        (bool received,) = i_bondingCurve.protocolFeeDestination().call{value: fees}("");
        if (!received) {
            revert("Protocol fee transfer failed");
        }

        // Transfer Ether to the seller
        (bool sent,) = payable(msg.sender).call{value: salePrice}("");
        if (!sent) {
            revert("Token sale transfer failed");
        }
    }

    /*///////////////////////////////////////////////////////////////
                          GETTER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Returns the address of the ExponentialBondingCurve proxy contract.
    function getBondingCurveProxyAddress() external view returns (address) {
        return address(i_bondingCurve);
    }
}
