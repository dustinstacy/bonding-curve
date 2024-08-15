// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

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
    /// @notice The address to send protocol fees to.
    address public protocolFeeDestination;

    /// @notice The percentage of the transaction to send to the protocol fee destination represented in basis points.
    uint256 public protocolFeeBasisPoints;

    /// @dev Value to represent the protocol fee as a percentage for use in calculations.
    uint256 private protocolFeePercent;

    /// @notice reserveRatio is used to define the steepness of the bonding curve.
    ///         Represented in ppm, 1-1000000.
    ///         1/3 corresponds to y= multiple * x^2
    ///         1/2 corresponds to y= multiple * x
    ///         2/3 corresponds to y= multiple * x^1/2
    ///         With lower values, the price of the token will increase more rapidly.
    ///         With higher values, the price of the token will increase more slowly.
    uint256 public reserveRatioPPM;

    /// @dev Value to represent the reserve ratio for use in calculations.
    uint256 private reserveRatio;

    /// @notice The maximum gas limit for transactions.
    /// @dev This value should be set to prevent front-running attacks.
    uint256 public maxGasLimit;

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
    /// @return purchaseReturn The amount of continuous tokens to mint (in 1e18 format).
    /// @return fees The amount of protocol fees to send to the protocol fee destination (in wei).
    function calculatePurchaseReturn(uint256 currentSupply, uint256 reserveTokenBalance, uint256 reserveTokensReceived)
        external
        returns (uint256 purchaseReturn, uint256 fees)
    {
        fees = (reserveTokensReceived * protocolFeePercent) / PRECISION;
        uint256 remainingReserveTokens = reserveTokensReceived - fees;

        // Calculate the amount of tokens to return
        uint256 result =
            (((remainingReserveTokens * PRECISION / reserveTokenBalance) + PRECISION) * reserveRatio) / PRECISION;
        purchaseReturn = (currentSupply * result) / PRECISION;

        // Transfer protocol fees to the protocol fee destination
        (bool success,) = protocolFeeDestination.call{value: fees}("");
        if (!success) {
            revert("Protocol fee transfer failed");
        }

        // Return the amount of tokens to mint
        return (purchaseReturn, fees);
    }

    /// @notice Calculates the amount of ether that can be returned for the given amount of tokens.
    /// @param currentSupply The current supply of continuous tokens (in 1e18 format).
    /// @param reserveTokenBalance The balance of reserve tokens (in wei).
    /// @param tokensToBurn The amount of continuous tokens to mint (in 1e18 format).
    function calculateSaleReturn(uint256 currentSupply, uint256 reserveTokenBalance, uint256 tokensToBurn)
        external
        returns (uint256 saleValue, uint256 fees)
    {
        // Calculate the new supply after burning tokens
        uint256 newSupply = currentSupply - tokensToBurn;

        // Calculate the amount of tokens to return
        uint256 result = ((tokensToBurn * PRECISION / newSupply) * PRECISION) / reserveRatio;
        uint256 newReserveTokenBalance = reserveTokenBalance * PRECISION / result;
        uint256 rawSaleValue = reserveTokenBalance - newReserveTokenBalance;
        fees = (rawSaleValue * protocolFeePercent) / PRECISION;
        saleValue = rawSaleValue - fees;

        // Transfer protocol fees to the protocol fee destination
        (bool success,) = protocolFeeDestination.call{value: fees}("");
        if (!success) {
            revert("Protocol fee transfer failed");
        }

        // Return the amount of ether to send to the seller
        return (saleValue, fees);
    }

    /*//////////////////////////////////////////////////////////////
                            SETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param _feeDestination The address to send protocol fees to.
    function setProtocolFeeDestination(address _feeDestination) public {
        protocolFeeDestination = _feeDestination;
    }

    /// @param _basisPoints The percentage of the transaction to send to the protocol fee destination represented in basis points.
    function setProtocolFeeBasisPoints(uint256 _basisPoints) public {
        protocolFeeBasisPoints = _basisPoints;
        protocolFeePercent = protocolFeeBasisPoints * PRECISION / BASIS_POINTS_PRECISION;
    }

    /// @param _reserveRatioPPM The reserve ratio used to define the steepness of the bonding curve in ppm.
    function setReserveRatioPPM(uint256 _reserveRatioPPM) public {
        reserveRatioPPM = _reserveRatioPPM;
        reserveRatio = reserveRatioPPM * PRECISION / PPM_PRECISION;
    }

    /// @param _maxGasLimit The maximum gas limit for transactions.
    function setMaxGasLimit(uint256 _maxGasLimit) public {
        maxGasLimit = _maxGasLimit;
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @return The `PRECISION` constant.
    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    /// @return The `PPM_PRECISION` constant.
    function getPPMPrecision() external pure returns (uint256) {
        return PPM_PRECISION;
    }

    /// @return The `BASIS_POINTS_PRECISION` constant.
    function getBasisPointsPrecision() external pure returns (uint256) {
        return BASIS_POINTS_PRECISION;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override {}
}
