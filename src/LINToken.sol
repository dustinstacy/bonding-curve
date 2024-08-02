// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {LinearBondingCurve} from "src/LinearBondingCurve.sol";
import {Calculations} from "src/libraries/Calculations.sol";

/// @title LinearCurveToken
/// @author Dustin Stacy
/// @notice This contract implements a simple ERC20 token that can be bought and sold using a linear bonding curve.
contract BondingCurveToken is ERC20Burnable {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Emitted when attempting to perform an action with an amount that must be more than zero.
    error BondingCurveToken__AmountMustBeMoreThanZero();

    /// @dev Emitted if the buyer does not send enough Ether to purchase the tokens.
    error BondingCurveToken__InsufficientFundingForTransaction();

    /// @dev Emitted when attempting to burn an amount that exceeds the sender's balance.
    error BondingCurveToken__BurnAmountExceedsBalance();

    /*///////////////////////////////////////////////////////////////
                             STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice Instance of a Bonding Curve contract used to determine the price of tokens.
    /// @dev In the case of an upgradeable implementation, this should be a proxy contract.
    LinearBondingCurve private immutable i_bondingCurve;

    /// @notice The initial cost of the token.
    /// @dev This value should be set in Wei (or other reserve currency).
    uint256 public immutable i_initialCost;

    /// @notice i_scalingFactor is used to define the steepness of the bonding curve.
    ///         It's specified in basis points, where 100 basis points equal 1 percent.
    uint256 public immutable i_scalingFactor;

    /// @notice The initial cost adjustment of the token based on the scaling factor.
    /// @dev This value is combined with the scaled price increment to retain the base value of the token.
    ///      Example:
    ///      initialCost = 1 ether (intended cost of the first token).
    ///      scalingFactor = 1000 (10%) (percent of the initial cost each token will increase by).
    ///      tokenPriceIncrement = 1 ether * 1000 / 10000 = 0.1 ether (value each token will increase by).
    ///      initialCostAdjustment = 1 ether - 0.1 ether = 0.9 ether (initial cost minus the token increment).
    ///      Token 1 price = 0.1 ether + initialCostAdjustment = 1 ether (initial cost is retained for the first token).
    ///      Each subsequent token will also have this initalCostAdjustment to preserve the ratio of the initial cost.
    int256 public immutable i_initialCostAdjustment;

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
    /// @param _scalingFactor The scaling factor used to determine the price of tokens.
    /// @param _bcAddress The address of the LinearBondingCurve contract.
    /// @dev   If the LinearBondingCurve contract is upgradeable, `_bcAddress` should be the proxy address.
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialCost,
        uint256 _scalingFactor,
        address _bcAddress
    ) ERC20(_name, _symbol) {
        i_initialCost = _initialCost;
        i_scalingFactor = Calculations.calculateScalingFactorPercent(_scalingFactor);
        i_initialCostAdjustment = Calculations.calculateInitialCostAdjustment(_initialCost, i_scalingFactor);
        i_bondingCurve = LinearBondingCurve(_bcAddress);
    }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @param amount The amount of tokens to buy.
    /// @dev Needs UI with getTotalPrice function to determine correct value to send before calling this function.
    /// @dev getTotalPrice will return the raw price of the token as well as the protocol fee and gas fee.
    function buyTokens(uint256 amount) external payable {
        if (amount == 0) {
            revert BondingCurveToken__AmountMustBeMoreThanZero();
        }

        /// @dev Update to getTotalPrice function.
        /// @dev Checking to ensure the price has not updated since the user queried the price.
        uint256 price = i_bondingCurve.getRawBuyPrice(
            totalSupply(), i_initialCost, i_scalingFactor, amount, i_initialCostAdjustment
        );

        /// @dev Allow users to send extra to cover changes in supply before the transaction is processed?
        /// @dev If so a refund mechanism should be implemented.
        if (msg.value < price) {
            revert BondingCurveToken__InsufficientFundingForTransaction();
        }

        // Mint tokens to the buyer
        _mint(msg.sender, amount);

        emit TokensPurchased(msg.sender, price, amount);
    }

    // /// @param amount The amount of tokens to sell.
    // function sellTokens(uint256 amount) external {
    //     if (amount == 0) {
    //         revert BondingCurveToken__AmountMustBeMoreThanZero();
    //     }

    //     uint256 salePrice = i_bondingCurve.getSalePrice(totalSupply(), i_scalingFactor, i_initialCost, amount);

    //     // should not be possible
    //     if (address(this).balance < salePrice) {
    //         revert BondingCurveToken__InsufficientFundingForTransaction();
    //     }

    //     uint256 balance = balanceOf(msg.sender);

    //     // Check if the seller has enough tokens to sell.
    //     if (balance < amount) {
    //         revert BondingCurveToken__BurnAmountExceedsBalance();
    //     }

    //     // Burn tokens from the seller
    //     burnFrom(msg.sender, amount);

    //     // Transfer Ether to the seller
    //     payable(msg.sender).transfer(salePrice);

    //     emit TokensSold(msg.sender, salePrice, amount);
    // }
}
