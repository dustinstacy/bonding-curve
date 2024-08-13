// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ExponentialBondingCurve} from "src/ExponentialBondingCurve.sol";

/// @title ExponentialCurveToken
/// @author Dustin Stacy
/// @notice This contract implements a simple ERC20 token that can be bought and sold using an exponential bonding curve.
///         The price of the token is determined by the bonding curve, which adjusts based on the total supply.
///         The bonding curve is defined by a scaling factor, which determines the steepness of the curve.
///         As implemented, the scaling factor can be adjusted by the owner of the contract.
///         This will allow us to experiment with different curve shapes and determine the best fit for our use case.
///         If it's determined that the scaling factor should be fixed, we can remove the ability to adjust it.
///         Then the i_reserveRatio can be relocated to the ExponentialBondingCurve contract.
///         To do so, an interface must be created to exchange the ExponentialBondingCurve instance state variable for a standardized bonding curve interface.
///         This would allow the same token to be used with any bonding curve that implements the interface.
///         Note, it may still be desirable to have separate contracts for different bonding curve tokens to allow for different parameters if changes arise.
///@dev Similar to the Bancor curve, this curve is also based on a total reserve balance.
///     This balance will have to be set to greater than 0 at initialization.
///     Standardizing this value will ensure consistency across all implementations.
///     This value will be set in Wei (or other reserve currency).
///     The host will have to be responsible for sending this value to the contract.
contract EXPToken is ERC20Burnable {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Emitted when attempting to perform an action with an amount that must be more than zero.
    error EXPToken__AmountMustBeMoreThanZero();

    /// @dev Emitted if the buyer does not send enough Ether to purchase the tokens.
    error EXPToken__InsufficientFundingForTransaction();

    /// @dev Emitted when attempting to burn an amount that exceeds the sender's balance.
    error EXPToken__BurnAmountExceedsBalance();

    /*///////////////////////////////////////////////////////////////
                             STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice Instance of a Bonding Curve contract used to determine the price of tokens.
    /// @dev In the case of an upgradeable implementation, this should be a proxy contract.
    ExponentialBondingCurve private immutable i_bondingCurve;

    /// @notice i_reserveRatio is used to define the steepness of the bonding curve.
    ///         Represented in ppm, 1-1000000.
    ///         1/3 corresponds to y= multiple * x^2
    ///         1/2 corresponds to y= multiple * x
    ///         2/3 corresponds to y= multiple * x^1/2
    ///         With lower values, the price of the token will increase more rapidly.
    ///         With higher values, the price of the token will increase more slowly.
    uint256 public immutable i_reserveRatio;

    /// @notice The total amount of Ether held in the contract.
    /// @dev This value should be used to determine the reserve balance of the contract.
    /// @dev For now it will be instantiated to a set value for testing purposes.
    /// @dev In the future, a decision will need to be made as to how to initialize this value.
    uint256 public reserveBalance;

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
    /// @param _reserveRatio The scaling factor used to determine the price of tokens.
    /// @param _bcAddress The address of the ExponentialBondingCurve contract.
    /// @dev   If the ExponentialBondingCurve contract is upgradeable, `_bcAddress` should be the proxy address.
    /// @dev   If initialCost is predetermined, this can be set as a constant in the contract.
    /// @dev   If scaling is not desired, this can be set as a constant in the contract.
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _reserveRatio,
        address _bcAddress,
        uint256 _reserveBalance
    ) ERC20(_name, _symbol) {
        i_reserveRatio = _reserveRatio;
        i_bondingCurve = ExponentialBondingCurve(_bcAddress);
        reserveBalance = _reserveBalance;
    }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Allows a user to mint tokens by sending ether to the contract.
    /// @dev The amount of tokens minted is determined by the bonding curve.
    /// @dev Need to implement a gas limit to prevent front-running attacks.
    function mintTokens() external payable {
        if (msg.value == 0) {
            revert EXPToken__AmountMustBeMoreThanZero();
        }

        uint256 amount =
            i_bondingCurve.calculatePurchaseReturn(totalSupply(), reserveBalance, msg.value, i_reserveRatio);
        reserveBalance += msg.value;

        // Mint tokens to the buyer
        _mint(msg.sender, amount);

        emit TokensPurchased(msg.sender, msg.value, amount);
    }

    /// @param amount The amount of tokens to burn.
    /// @dev Need to implement a gas limit to prevent front-running attacks.
    /// @dev CEI is implemented here so is OZ nonReentrant modifier necessary?
    function burnTokens(uint256 amount) external {
        if (amount == 0) {
            revert EXPToken__AmountMustBeMoreThanZero();
        }

        uint256 balance = balanceOf(msg.sender);

        // Check if the seller has enough tokens to burn.
        if (balance < amount) {
            revert EXPToken__BurnAmountExceedsBalance();
        }

        uint256 salePrice = i_bondingCurve.calculateSaleReturn(totalSupply(), reserveBalance, amount, i_reserveRatio);

        // should not be possible
        if (address(this).balance < salePrice) {
            revert EXPToken__InsufficientFundingForTransaction();
        }

        // Burn tokens from the seller
        burnFrom(msg.sender, amount);

        // Transfer Ether to the seller
        payable(msg.sender).transfer(salePrice);

        emit TokensSold(msg.sender, salePrice, amount);
    }
}
