// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {LinearBondingCurve} from "src/LinearBondingCurve.sol";
import {Calculations} from "src/libraries/Calculations.sol";

/// @title LinearCurveToken
/// @author Dustin Stacy
/// @notice This contract implements a simple ERC20 token that can be bought and sold using a linear bonding curve.
/// @dev The Linear Bonding curve token differs from the Exponential token in that it sets and initial cost adjustment variable.
///      If sublinear or superlinear curves are not desired, this variable can be eliminated and both tokens can use the same contract.
///      To do so, an interface must be created to exchange the LinearBondingCurve instance state variable for a standardized bonding curve interface.
///      This would allow the same token to be used with any bonding curve that implements the interface.
///      Note, it may still be desirable to have separate contracts for different bonding curve tokens to allow for different parameters if changes arise.
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

    /// @notice Instance of a Bonding Curve contract used to determine the price of tokens.
    /// @dev In the case of an upgradeable implementation, this should be a proxy contract.
    LinearBondingCurve private immutable i_bondingCurve;

    /// @notice The initial cost of the token.
    /// @dev This value should be set in Wei (or other reserve currency).
    uint256 public immutable i_initialCost;

    /// @notice i_scalingFactor is used to define the steepness of the bonding curve.
    ///         It's specified in basis points, where 100 basis points equal 1 percent.
    ///         This allows for the creating of sublinear or superlinear curves.
    ///         A value of 10000 (100%) will create a true linear curve.
    ///         Sublinear and superlinear curves can be created by using values less than or greater than 10000.
    ///         For example, a value of 5000 (50%) will create a sublinear curve where the price of tokens increases at 50% of the initial cost.
    ///         i.e. 1 ether => 1.5 ether => 2 ether => 2.5 ether => 3 ether etc.
    uint256 public immutable i_scalingFactor;

    /// @notice The price increment of the token based on the scaling factor.
    /// @dev This value is used to determine the price increase of each token based on the scaling factor.
    uint256 public immutable i_tokenPriceIncrement;

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
    /// @dev   If initialCost is predetermined, this can be set as a constant in the contract.
    /// @dev   If scaling is not desired, this can be set as a constant in the contract. (or potentially removed altogether)
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialCost,
        uint256 _scalingFactor,
        address _bcAddress
    ) ERC20(_name, _symbol) {
        i_initialCost = _initialCost;
        i_scalingFactor = Calculations.calculateScalingFactorPercent(_scalingFactor);
        i_tokenPriceIncrement = Calculations.calculatePriceIncrement(_initialCost, i_scalingFactor);
        i_initialCostAdjustment = Calculations.calculateInitialCostAdjustment(_initialCost, i_tokenPriceIncrement);
        i_bondingCurve = LinearBondingCurve(_bcAddress);
    }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Allows a user to purchase tokens by sending Ether to the contract.
    /// @dev The amount of tokens minted is determined by the bonding curve.
    /// @dev Need to implement a gas limit to prevent front-running attacks.
    /// @dev Function will be updated to call getBuyPriceAfterFees function.
    function buyTokens() external payable {
        if (msg.value == 0) {
            revert LINToken__AmountMustBeMoreThanZero();
        }

        /// @dev Update to getTotalPurchaseReturn function.
        uint256 amount = i_bondingCurve.getRawPurchaseReturn(totalSupply(), i_initialCost, msg.value);

        // Mint tokens to the buyer
        _mint(msg.sender, amount);

        emit TokensPurchased(msg.sender, msg.value, amount);
    }

    /// @notice Returns the current price of a whole token.
    /// @dev Is there a need/desire to implement a buyWholeToken function?
    /// @dev Or is the query of the price sufficient for the user to determine the amount to send?
    function getFullTokenPrice() external view returns (uint256) {
        return i_bondingCurve.getFullTokenPrice(totalSupply(), i_initialCost);
    }

    /// @param amount The amount of tokens to sell.
    /// @dev Needs UI with getTotalSellPrice function to determine correct amount to transfer before calling this function.
    /// @dev getTotalSalePrice will return the raw sell price of the token(s) minus the protocol fee and gas fee.
    /// @dev Need to implement a gas limit to prevent front-running attacks?
    /// @dev CEI is implemented here so is OZ nonReentrant modifier necessary?
    function sellTokens(uint256 amount) external {
        if (amount == 0) {
            revert LINToken__AmountMustBeMoreThanZero();
        }

        uint256 balance = balanceOf(msg.sender);

        // Check if the seller has enough tokens to sell.
        if (balance < amount) {
            revert LINToken__BurnAmountExceedsBalance();
        }

        /// @dev Update to getTotalSellPrice function.
        /// @dev Need to implement a check to ensure the price has not updated since the user queried it.
        uint256 salePrice = i_bondingCurve.getSaleReturn(totalSupply(), i_initialCost, amount);

        // should not be possible
        if (address(this).balance < salePrice) {
            revert LINToken__InsufficientFundingForTransaction();
        }

        // Burn tokens from the seller
        burnFrom(msg.sender, amount);

        // Transfer Ether to the seller
        payable(msg.sender).transfer(salePrice);

        emit TokensSold(msg.sender, salePrice, amount);
    }
}
