// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {console} from "forge-std/console.sol";

/// @title LinearBondingCurve
/// @author Dustin Stacy
/// @notice This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
///         The price of tokens increases linearly with the supply.
contract LinearBondingCurve is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/
    /// @notice The address to send protocol fees to.
    address public protocolFeeDestination;

    /// @notice The percentage of the transaction value to send to the protocol fee destination.
    uint256 public protocolFeePercent;

    /// @dev The percentage of the collected fees to share with the token contract.
    uint256 public feeSharePercent;

    /// @notice The balance of reserve tokens to initialize the bonding curve token with.
    uint256 public initialReserve;

    /// @notice The maximum gas limit for transactions.
    /// @dev This value should be set to prevent front-running attacks.
    uint256 public maxGasLimit;

    /// @notice Precision for calculations.
    /// @dev Solidity does not support floating point numbers, so we use fixed point math.
    /// @dev Precision also acts as the number 1 commonly used in curve calculations.
    uint256 private constant PRECISION = 1e18;

    /// @notice Precision for basis points calculations.
    /// @dev This is used to convert the protocol fee to a fraction.
    uint256 private constant BASIS_POINTS_PRECISION = 1e4;

    /// @dev The maximum value for basis points.
    uint256 private constant MAX_BASIS_POINTS = 1e5;

    /*///////////////////////////////////////////////////////////////
                        INITIALIZER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Disables the default initializer function.
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the bonding curve with the given parameters.
    /// @param _owner The owner of the contract.
    /// @param _protocolFeeDestination The address to send protocol fees to.
    /// @param _protocolFeePercent The protocol fee percentage represented in basis points.
    /// @param _feeSharePercent The collected fee share percentage represented in basis points.
    /// @param _initialReserve The balance of reserve tokens to initialize the bonding curve token with.
    /// @param _maxGasLimit The maximum gas limit for transactions.
    function initialize(
        address _owner,
        address _protocolFeeDestination,
        uint256 _protocolFeePercent,
        uint256 _feeSharePercent,
        uint256 _initialReserve,
        uint256 _maxGasLimit
    ) public initializer {
        require(
            _owner != address(0) && _protocolFeeDestination != address(0) && _protocolFeePercent > 0
                && _protocolFeePercent < MAX_BASIS_POINTS && _feeSharePercent < MAX_BASIS_POINTS && _initialReserve > 0
                && _maxGasLimit > 0,
            "LinearBondingCurve: Invalid parameters"
        );
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
        protocolFeeDestination = _protocolFeeDestination;
        protocolFeePercent = _protocolFeePercent * PRECISION / BASIS_POINTS_PRECISION;
        initialReserve = _initialReserve;
        maxGasLimit = _maxGasLimit;

        if (_feeSharePercent > 0) {
            feeSharePercent = _feeSharePercent * PRECISION / BASIS_POINTS_PRECISION;
        } else {
            feeSharePercent = 0;
        }
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
    ///                | 4726            | 6813  | 4726   | 11161 | 5       |
    ///
    function calculatePurchaseReturn(uint256 currentSupply, uint256 reserveBalance, uint256 reserveTokensReceived)
        external
        view
        returns (uint256 purchaseReturn, uint256 fees)
    {
        // Calculate Protocol Fees.
        fees = ((reserveTokensReceived * PRECISION / (protocolFeePercent + PRECISION)) * protocolFeePercent) / PRECISION;
        uint256 remainingReserveTokens = reserveTokensReceived - fees;

        // Determine the next token threshold.
        uint256 n = (currentSupply / PRECISION) + 1;

        // Calculate the current token fragment.
        uint256 currentFragmentBalance = _totalCost(n) - reserveBalance;
        uint256 currentFragment = (currentFragmentBalance * PRECISION / (_totalCost(n) - _totalCost(n - 1)));

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
        purchaseReturn += (remainingReserveTokens * PRECISION) / (_totalCost(n) - _totalCost(n - 1));

        return (purchaseReturn, fees);
    }

    /// @notice Calculates the amount of ether that can be returned for the given amount of tokens.
    /// @param currentSupply supply of tokens.
    /// @param reserveBalance The balance of reserve tokens (in wei).
    /// @param amount The amount of tokens to sell.
    /// @return saleReturn The amount of ether to return to the seller.
    /// @return fees The amount of protocol fees to send to the protocol fee destination.
    ///
    /// Gas Report     | min             | avg   | median | max   | # calls |
    ///                | 6695            | 7345  | 7345   | 7995  | 2       |
    ///
    function calculateSaleReturn(uint256 currentSupply, uint256 reserveBalance, uint256 amount)
        external
        view
        returns (uint256 saleReturn, uint256 fees)
    {
        // Determine the current token threshold.
        uint256 n = (currentSupply / PRECISION);

        // Calculate the current token fragment.
        uint256 remainingCurrentTokenBalance = reserveBalance - _totalCost(n);
        uint256 remainingCurrentTokenFragment = ((remainingCurrentTokenBalance * PRECISION) / (n + 1)) / PRECISION;

        // If the amount of tokens to sell is less than the current token fragment, return a portion of the current fragment.
        if (amount < remainingCurrentTokenFragment) {
            saleReturn = amount * PRECISION / _totalCost(n + 1);
            fees = (saleReturn * protocolFeePercent) / PRECISION;
            return (saleReturn, fees);
        }

        // Calibrate variables for the next token price threshold.
        amount -= remainingCurrentTokenFragment;
        saleReturn += remainingCurrentTokenBalance;

        // Iterate through the curve until the remaining amount of tokens to sell is less than the next token price threshold.
        while (amount >= PRECISION) {
            saleReturn += (_totalCost(n) - _totalCost(n - 1));
            amount -= PRECISION;
            n--;
        }

        // Calculate the remaining fragment if the remaining amount of tokens to sell is less than the next token price threshold.
        saleReturn += (amount * _totalCost(n)) / PRECISION;

        // Calculate protocol fees
        fees = (saleReturn * protocolFeePercent) / PRECISION;

        return (saleReturn, fees);
    }

    function calculateMintCost(uint256 currentSupply, uint256 reserveBalance)
        external
        view
        returns (uint256 depositAmount)
    {
        // We want to mint exactly 1 token, scaled by PRECISION
        uint256 targetReturn = PRECISION;

        // Determine the next token threshold.
        uint256 n = (currentSupply / PRECISION) + 1;

        // Calculate the current token fragment.
        uint256 currentFragmentBalance = _totalCost(n) - reserveBalance;
        uint256 currentFragment = (currentFragmentBalance * PRECISION / (_totalCost(n) - _totalCost(n - 1)));

        if (currentFragment == targetReturn) {
            return depositAmount = currentFragmentBalance;
        }

        // Calibrate variables for the next token price threshold.
        depositAmount += currentFragmentBalance;
        targetReturn -= currentFragment;
        n++;

        uint256 remainingFragment = ((_totalCost(n) - _totalCost(n - 1)) * targetReturn) / PRECISION;

        depositAmount += remainingFragment;
    }

    /*//////////////////////////////////////////////////////////////
                            SETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param _feeDestination The address to send protocol fees to.
    function setProtocolFeeDestination(address _feeDestination) public onlyOwner {
        require(_feeDestination != address(0), "LinearBondingCurve: protocol fee destination cannot be zero address");
        protocolFeeDestination = _feeDestination;
    }

    /// @param _basisPoints The percentage of the transaction to send to the protocol fee destination represented in basis points.
    function setProtocolFeePercent(uint256 _basisPoints) external onlyOwner {
        protocolFeePercent = _basisPoints * PRECISION / BASIS_POINTS_PRECISION;
    }

    /// @param _basisPoints The collected fee share percentage for selling tokens represented in basis points.
    function setFeeSharePercent(uint256 _basisPoints) external onlyOwner {
        feeSharePercent = _basisPoints * PRECISION / BASIS_POINTS_PRECISION;
    }

    /// @param _initialReserve The balance of reserve tokens to initialize the bonding curve token with.
    function setInitialReserve(uint256 _initialReserve) public onlyOwner {
        initialReserve = _initialReserve;
    }

    /// @param _maxGasLimit The maximum gas limit for transactions.
    function setMaxGasLimit(uint256 _maxGasLimit) public onlyOwner {
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

    /// @return The `MAX_BASIS_POINTS` constant.
    function getMaxBasisPoints() public pure returns (uint256) {
        return MAX_BASIS_POINTS;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override {}

    /// @notice Function to calculate the total cost of tokens given the number of tokens.
    function _totalCost(uint256 n) internal view returns (uint256) {
        return (n * (n + 1) * initialReserve) / 2;
    }
}
