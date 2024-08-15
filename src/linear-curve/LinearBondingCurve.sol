// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {console} from "forge-std/console.sol";

/// @title LinearBondingCurve
/// @author Dustin Stacy
/// @notice This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
///         The price of tokens increases linearly with the supply.
/// @dev    Math needs to be rigorously test for edge cases including zero values and overflow.
/// @dev    Need to add access controls
contract LinearBondingCurve is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/
    /// @notice The address to send protocol fees to.
    address public protocolFeeDestination;

    /// @notice The percentage of the transaction to send to the protocol fee destination in basis points.
    uint256 public protocolFeeBasisPoints;

    /// @dev Value to represent the protocol fee as a percentage for use in calculations.
    uint256 private protocolFeePercent;

    /// @notice The initial cost of the token.
    uint256 public initialCost;

    /// @notice The maximum gas limit for transactions.
    /// @dev This value should be set to prevent front-running attacks.
    uint256 public maxGasLimit;

    /// @dev Solidity does not support floating point numbers, so we use fixed point math.
    /// @dev Precision also acts as the number 1 commonly used in curve calculations.
    uint256 private constant PRECISION = 1e18;

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
    /// @param reserveBalance The balance of reserve tokens (in wei).
    /// @param reserveTokensReceived The amount of reserve tokens received (in wei).
    /// @return purchaseReturn The amount of continuous tokens to mint (in 1e18 format).
    /// @return fees The amount of protocol fees to send to the protocol fee destination (in wei).
    ///
    /// Gas Report     | min             | avg   | median | max   | # calls |
    ///                | 4661            | 6661  | 6661   | 8661  | 4       |
    ///
    function calculatePurchaseReturn(uint256 currentSupply, uint256 reserveBalance, uint256 reserveTokensReceived)
        external
        view
        returns (uint256 purchaseReturn, uint256 fees)
    {
        // Calculate Protocol Fees.
        fees = ((reserveTokensReceived * PRECISION / (protocolFeePercent + PRECISION)) * protocolFeePercent) / PRECISION;
        uint256 remainingReserveTokens = reserveTokensReceived - fees;

        // Determine next token.
        uint256 n = (currentSupply / PRECISION) + 1;

        // Calculate the current token fragment.
        uint256 currentFragmentBalance = _totalCost(n) - reserveBalance;
        uint256 currentFragment = ((currentFragmentBalance * PRECISION) / n) / PRECISION;

        // If the reserve tokens are less than the current fragment balance, return portion of the current fragment.
        if (remainingReserveTokens < currentFragmentBalance) {
            purchaseReturn = (remainingReserveTokens * PRECISION) / (_totalCost(n) - _totalCost(n - 1));
            return (purchaseReturn, fees);
        }

        // Calibrate variables for the next token price threshold.
        remainingReserveTokens -= currentFragmentBalance;
        purchaseReturn += currentFragment;
        n++;

        // Iterate through the curve until the remaining reserve tokens are less than the next token price threshold.
        while (_totalCost(n) - _totalCost(n - 1) <= remainingReserveTokens) {
            purchaseReturn += PRECISION;
            remainingReserveTokens -= _totalCost(n) - _totalCost(n - 1);
            n++;
        }

        // Calculate the remaining fragment if the remaining reserve tokens are less than the next token price threshold.
        uint256 remainingFragment = (remainingReserveTokens * PRECISION) / (_totalCost(n) - _totalCost(n - 1));
        purchaseReturn += remainingFragment;

        return (purchaseReturn, fees);
    }

    /// @notice Calculates the amount of ether that can be returned for the given amount of tokens.
    /// @param currentSupply supply of tokens.
    /// @param reserveBalance The balance of reserve tokens (in wei).
    /// @param amount The amount of tokens to sell.
    function calculateSaleReturn(uint256 currentSupply, uint256 reserveBalance, uint256 amount)
        external
        returns (uint256 saleReturn, uint256 fees)
    {
        // Calculate the raw sale return
        uint256 rawSaleReturn = 0;
        // Calculate protocol fees
        fees = (rawSaleReturn * protocolFeePercent) / PRECISION;
        saleReturn = rawSaleReturn - fees;

        return (saleReturn, fees);
    }

    /*//////////////////////////////////////////////////////////////
                            SETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param _feeDestination The address to send protocol fees to.
    function setProtocolFeeDestination(address _feeDestination) public {
        protocolFeeDestination = _feeDestination;
    }

    /// @param _basisPoints The percentage of the transaction to send to the protocol fee destination.
    function setProtocolFeeBasisPoints(uint256 _basisPoints) public {
        protocolFeeBasisPoints = _basisPoints;
        protocolFeePercent = protocolFeeBasisPoints * PRECISION / BASIS_POINTS_PRECISION;
    }

    /// @param _initialCost The initial cost of the token.
    function setInitialCost(uint256 _initialCost) public {
        initialCost = _initialCost;
    }

    /// @param _maxGasLimit The maximum gas limit for transactions.
    function setMaxGasLimit(uint256 _maxGasLimit) public {
        maxGasLimit = _maxGasLimit;
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @return The `PRECISION` constant.
    function getPrecision() public pure returns (uint256) {
        return PRECISION;
    }

    /// @return The `BASIS_POINTS_PRECISION` constant.
    function getBasisPointsPrecision() public pure returns (uint256) {
        return BASIS_POINTS_PRECISION;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override {}

    /// @notice Function to calculate the total cost of tokens given the number of tokens.
    function _totalCost(uint256 n) internal view returns (uint256) {
        return (n * (n + 1) * initialCost) / 2;
    }
}
