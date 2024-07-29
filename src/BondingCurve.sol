// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SimpleCoin} from "./token/SimpleCoin.sol";

/// @title BondingCurve
/// @author Dustin Stacy
/// @notice This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
///         The curve is defined by a reserve ratio, which determines the steepness of the curve.
///         The contract is designed to work with ERC20 tokens.
contract BondingCurve {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Emitted when attempting to perform an action with an amount that must be more than zero.
    error BondingCurve__AmountMustBeMoreThanZero();

    /// @dev Emitted if minting is unsuccesful.
    error BondingCurve__MintFailed();

    /// @dev Emitted if the buyer does not send enough Ether to purchase the tokens.
    error BondingCurve__InsufficientFunds();

    /*///////////////////////////////////////////////////////////////
                             STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice Instance of the SimpleCoin contract used to mint and burn tokens.
    /// @dev Implement as an array to target creators specific token address
    /// @dev Better yet, Tokens should extend the Bonding Curve contract, not the other way around.
    SimpleCoin private immutable i_simpleCoin;

    /// @notice  reserveBalance keeps track of the total amount of Ether (or other reserve currency)
    ///          held by the contract.
    ///          This balance is crucial for the functioning of the bonding curve as it influences
    ///          the price of tokens.
    /// @dev Each token needs its own reserve balance. Plus one for coins managing their own state.
    uint256 public reserveBalance;

    /// @notice reserveRatio is used to define the steepness or shape of the bonding curve. It's
    ///         specified in basis points, where 100 basis points equal 1 percent. For example,
    ///         a reserve ratio of 5000 corresponds to a 50% reserve ratio.
    /// @dev Each token needs its own reserve ratio chosen by the creator.
    uint32 public reserveRatio;

    /// @notice tokenSupply keeps track of the total amount of tokens in circulation.
    /// @dev Each token clearly needs its own supply.
    uint256 public totalSupply;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Event to log token purchases.
    event TokensPurchased(address indexed buyer, uint256 amountSpent, uint256 tokensMinted);

    /// @notice Event to log token sales.
    event TokensSold(address indexed seller, uint256 amountReceived, uint256 tokensMinted);

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/
    /// @param scAddress Address of the SimpleCoin contract.
    /// @param _reserveRatio Reserve ratio of the bonding curve.
    /// @dev When reversing the relationship, the token should be passing the bonding curve address in it's constructor.
    ///      If upgradeability is desired, the token should then pass the proxy address of the bonding curve.
    ///      This way the bonding curve can be upgraded without affecting the token.
    ///      Each upgrade would then point the proxy to the new bonding curve implementation.
    constructor(address scAddress, uint32 _reserveRatio) {
        i_simpleCoin = SimpleCoin(scAddress);
        reserveRatio = _reserveRatio;
    }

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @param amount Amount of tokens to purchase
    /// @dev Enforce natural number arguments only?
    function buyTokens(uint256 amount) external payable {
        if (amount == 0) {
            revert BondingCurve__AmountMustBeMoreThanZero();
        }

        uint256 price = getPrice(amount);

        if (msg.value < price) {
            revert BondingCurve__InsufficientFunds();
        }

        // Update reserve balance and total supply
        reserveBalance += price;
        totalSupply += amount;

        // Mint tokens to the buyer
        bool minted = i_simpleCoin.mint(msg.sender, amount);
        if (!minted) {
            revert BondingCurve__MintFailed();
        }

        emit TokensPurchased(msg.sender, price, amount);
    }

    /// @param amount Amount of tokens to purchase
    /// @dev Enforce natural number arguments only?
    function sellTokens(uint256 amount) external {
        if (amount == 0) {
            revert BondingCurve__AmountMustBeMoreThanZero();
        }

        uint256 price = getSalePrice();

        if (price > reserveBalance) {
            revert BondingCurve__InsufficientFunds();
        }

        // Update reserve balance and total supply
        reserveBalance -= price;
        totalSupply -= amount;

        // Burn tokens from the seller
        i_simpleCoin.burnFrom(msg.sender, amount);

        // Send Ether to the seller
        payable(msg.sender).transfer(price);

        emit TokensSold(msg.sender, price, amount);
    }

    /*///////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @param amount Amount of tokens to buy.
    /// @dev update with a more complex curve.
    function getPrice(uint256 amount) public view returns (uint256) {
        return (totalSupply + amount) * 1e16;
    }

    /// @dev update with a more complex curve.
    function getSalePrice() public view returns (uint256) {
        return (totalSupply) * 1e16;
    }
}
