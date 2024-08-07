// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {console2} from "forge-std/console2.sol"; // remove from production

/// @title ExponentialBondingCurve
/// @author Dustin Stacy
/// @notice This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
///         The curve is defined by a reserveRatio, which determines the steepness and bend of the curve.
contract ExponentialBondingCurve is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;

    uint256 private constant PRECISION = 1e18;
    uint256 private constant PPM_PRECISION = 1e6;

    /*///////////////////////////////////////////////////////////////
                        INITIALIZER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Disables the default initializer function.
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract with the owner address.
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Function to calculate the amount of continuous tokens to return based on reserve tokens received.
    /// @param currentSupply The current supply of continuous tokens (in 1e18 format).
    /// @param reserveTokenBalance The balance of reserve tokens (in wei).
    /// @param reserveTokensReceived The amount of reserve tokens received (in wei).
    /// @param reserveRatioPPM The reserve ratio (in PRECISIONd format, such as 1e18).
    /// @return tokensToReturn The amount of continuous tokens to mint (in 1e18 format).
    function getRawPurchaseReturn(
        uint256 currentSupply,
        uint256 reserveTokenBalance,
        uint256 reserveTokensReceived,
        uint256 reserveRatioPPM
    ) external pure returns (uint256 tokensToReturn) {
        // Ensure that the reserveTokenBalance is not zero to prevent division by zero
        require(reserveTokenBalance > 0, "Reserve token balance must be greater than zero");
        // Ensure that the reserveRatio is positive
        require(reserveRatioPPM > 0, "Reserve ratio must be greater than zero");

        // Convert reserveRatioPPM to a fraction
        uint256 reserveRatio = reserveRatioPPM * PRECISION / PPM_PRECISION;
        // console2.log("Reserve Ratio: ", reserveRatio);

        uint256 fraction = (reserveTokensReceived * PRECISION) / reserveTokenBalance;
        uint256 base = PRECISION + fraction;
        uint256 exp = (base * reserveRatio) / PRECISION;
        uint256 purchaseReturn = currentSupply * exp / PRECISION;
        return purchaseReturn;
    }

    /// @notice Calculates the amount of ether needed to purchase the next full token.
    /// @param supply current supply of tokens.
    /// @param initialCost The initial cost of the token.
    /// @dev Need to implement a function to calculate the total cost of the next full token.
    /// @dev If fees are implemented, this function should return the total cost of the token after fees.
    function getFullTokenPrice(uint256 supply, uint256 initialCost) external pure returns (uint256) {}

    /// @notice Calculates the purchase return after protocol fees are deducted.
    /// @param supply The current supply of tokens.
    /// @param initialCost The initial cost of the token.
    /// @param value The amount of ether sent to purchase tokens.
    /// @dev This is the function the token contract should call to determine the amount of tokens to mint.
    /// @dev If fees are implemented, this function should return the amount of tokens to mint after fees.
    function getBuyPriceAfterFees(uint256 supply, uint256 initialCost, uint256 value) external pure returns (uint256) {}

    /// @notice Calculates the amount of ether that can be returned for the given amount of tokens.
    /// @param supply The current supply of tokens.
    /// @param initialCost The initial cost of the token.
    /// @param amount The amount of tokens to sell.
    /// @dev Need to add a sell penalty to the calculation.
    function getSaleReturn(uint256 supply, uint256 initialCost, uint256 amount) external pure returns (uint256) {}

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param _feeDestination The address to send protocol fees to.
    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    /// @param _feePercent The percentage of the transaction to send to the protocol fee destination.
    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
