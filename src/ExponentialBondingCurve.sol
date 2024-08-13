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
/// @dev    Math needs to be rigorously test for edge cases including zero values and overflow.
/// @dev    Need to add access controls
contract ExponentialBondingCurve is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/
    address public protocolFeeDestination;
    uint256 public protocolFeeBasisPoints;

    /// @dev Solidity does not support floating point numbers, so we use fixed point math.
    /// @dev Precision also acts as the number 1 commonly used in curve calculations.
    uint256 private constant PRECISION = 1e18;

    /// @dev Precision for parts per million calculations.
    /// @dev This is used to convert the reserve ratio to a fraction.
    uint256 private constant PPM_PRECISION = 1e6;

    /// @dev Precision for basis points calculations.
    /// @dev This is used to convert the protocol fee to a fraction.
    uint256 private constant BASIS_POINTS_PRECISION = 1e4;

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
    /// @param reserveRatioPPM The reserve ratio in parts per million (PPM).
    /// @return tokensToReturn The amount of continuous tokens to mint (in 1e18 format).
    function calculatePurchaseReturn(
        uint256 currentSupply,
        uint256 reserveTokenBalance,
        uint256 reserveTokensReceived,
        uint256 reserveRatioPPM
    ) public returns (uint256 tokensToReturn) {
        // Some double checks to ensure the inputs are valid
        // Need to remove these checks in production and replace with custom errors where necessary.
        require(currentSupply > 0, "Current supply must be greater than zero");
        require(reserveTokenBalance > 0, "Reserve token balance must be greater than zero");
        require(reserveTokensReceived > 0, "Token to return must be greater than zero");
        require(reserveRatioPPM > 0, "Reserve ratio must be greater than zero");

        // Convert reserveRatioPPM and ProtocolFeeBasisPoints to fractions
        uint256 reserveRatio = reserveRatioPPM * PRECISION / PPM_PRECISION;
        uint256 protocolFeePercent = protocolFeeBasisPoints * PRECISION / BASIS_POINTS_PRECISION;

        // Calculate the amount of tokens to return
        uint256 result =
            (((reserveTokensReceived * PRECISION / reserveTokenBalance) + PRECISION) * reserveRatio) / PRECISION;
        uint256 rawPurchaseReturn = (currentSupply * result) / PRECISION;
        uint256 fees = (rawPurchaseReturn * protocolFeePercent) / PRECISION;
        uint256 purchaseReturn = rawPurchaseReturn - fees;

        // Transfer protocol fees to the protocol fee destination
        (bool success,) = protocolFeeDestination.call{value: fees}("");
        if (!success) {
            revert("Protocol fee transfer failed");
        }

        // Return the amount of tokens to mint
        return purchaseReturn;
    }

    /// @notice Calculates the amount of ether that can be returned for the given amount of tokens.
    /// @param currentSupply The current supply of continuous tokens (in 1e18 format).
    /// @param reserveTokenBalance The balance of reserve tokens (in wei).
    /// @param tokensToBurn The amount of continuous tokens to mint (in 1e18 format).
    /// @param reserveRatioPPM The reserve ratio (in PRECISIONd format, such as 1e18).
    /// @dev Need to add a sell penalty to the calculation.
    /// @dev Do protocol fees apply to the sale of tokens as well?
    /// @dev Need to update variable names to be more descriptive.
    function calculateSaleReturn(
        uint256 currentSupply,
        uint256 reserveTokenBalance,
        uint256 tokensToBurn,
        uint256 reserveRatioPPM
    ) external returns (uint256 saleValue) {
        // Some double checks to ensure the inputs are valid
        // Need to remove these checks in production and replace with custom errors where necessary.
        require(currentSupply > 0, "Current supply must be greater than zero");
        require(reserveTokenBalance > 0, "Reserve token balance must be greater than zero");
        require(tokensToBurn > 0, "Token to return must be greater than zero");
        require(reserveRatioPPM > 0, "Reserve ratio must be greater than zero");

        // Convert reserveRatioPPM and ProtocolFeeBasisPoints to fractions
        uint256 reserveRatio = reserveRatioPPM * PRECISION / PPM_PRECISION;
        uint256 protocolFeePercent = protocolFeeBasisPoints * PRECISION / BASIS_POINTS_PRECISION;
        uint256 newSupply = currentSupply - tokensToBurn;

        // Calculate the amount of tokens to return
        uint256 result = ((tokensToBurn * PRECISION / newSupply) * PRECISION) / reserveRatio;
        uint256 newReserveTokenBalance = reserveTokenBalance * PRECISION / result;
        uint256 rawSaleValue = reserveTokenBalance - newReserveTokenBalance;
        uint256 fees = (rawSaleValue * protocolFeePercent) / PRECISION;
        saleValue = rawSaleValue - fees;

        // Transfer protocol fees to the protocol fee destination
        (bool success,) = protocolFeeDestination.call{value: fees}("");
        if (!success) {
            revert("Protocol fee transfer failed");
        }

        // Return the amount of ether to send to the seller
        return saleValue;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param _feeDestination The address to send protocol fees to.
    function setFeeDestination(address _feeDestination) public {
        protocolFeeDestination = _feeDestination;
    }

    /// @param _basisPoints The percentage of the transaction to send to the protocol fee destination represented in basis points.
    function setProtocolFeeBasisPoints(uint256 _basisPoints) public {
        protocolFeeBasisPoints = _basisPoints;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override {}
}
