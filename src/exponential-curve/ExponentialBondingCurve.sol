// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {BancorFormula} from "src/exponential-curve/BancorFormula.sol";
import {console} from "forge-std/console.sol";

/// @title ExponentialBondingCurve
/// @author Dustin Stacy
/// @notice This contract implements the Bancor bonding curve.
///         The curve is defined by a reserveRatio, which determines the steepness and bend of the curve.
/// @dev    Need to add access controls
contract ExponentialBondingCurve is Initializable, OwnableUpgradeable, UUPSUpgradeable, BancorFormula {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    ///////////////////////////////////////////////////////////////*/
    /// @notice The address to send protocol fees to.
    address public protocolFeeDestination;

    /// @notice The percentage of the transaction to send to the protocol fee destination represented in basis points.
    uint256 public protocolFeeBasisPoints;

    /// @dev Value to represent the reserve ratio for use in calculations.
    uint32 public reserveRatio;

    /// @notice The maximum gas limit for transactions.
    /// @dev This value should be set to prevent front-running attacks.
    uint256 public maxGasLimit;

    /// @dev Value to represent the protocol fee as a percentage for use in calculations.
    uint256 private protocolFeePercent;

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
    /// @param reserveTokenBalance The balance of reserve tokens (in wei).
    /// @param reserveTokensReceived The amount of reserve tokens received (in wei).
    /// @return purchaseReturn The amount of continuous tokens to mint (in 1e18 format).
    /// @return fees The amount of protocol fees to send to the protocol fee destination (in wei).
    ///
    /// Gas Report     | min             | avg   | median | max   | # calls |
    ///                | 18854           | 18979 | 18979  | 19105 | 2       |
    ///
    function getPurchaseReturn(uint256 currentSupply, uint256 reserveTokenBalance, uint256 reserveTokensReceived)
        external
        view
        returns (uint256 purchaseReturn, uint256 fees)
    {
        // Calculate the protocol fees.
        fees = ((reserveTokensReceived * PRECISION / (protocolFeePercent + PRECISION)) * protocolFeePercent) / PRECISION;
        uint256 remainingReserveTokens = reserveTokensReceived - fees;

        // Calculate the amount of tokens to mint.
        purchaseReturn =
            calculatePurchaseReturn(currentSupply, reserveTokenBalance, reserveRatio, remainingReserveTokens);

        return (purchaseReturn, fees);
    }

    /// @notice Calculates the amount of ether that can be returned for the given amount of tokens.
    /// @param currentSupply The current supply of continuous tokens (in 1e18 format).
    /// @param reserveTokenBalance The balance of reserve tokens (in wei).
    /// @param tokensToBurn The amount of continuous tokens to burn (in 1e18 format).
    ///
    /// Gas Report     | min             | avg   | median | max   | # calls |
    ///                | 18565           | 18690 | 18690  | 18816 | 2       |
    ///
    function getSaleReturn(uint256 currentSupply, uint256 reserveTokenBalance, uint256 tokensToBurn)
        external
        view
        returns (uint256 saleValue, uint256 fees)
    {
        // Calculate the amount of ether returned for the given amount of tokens.
        uint256 result = calculateSaleReturn(currentSupply, reserveTokenBalance, reserveRatio, tokensToBurn);

        // Calculate the protocol fees.
        fees = (result * protocolFeePercent) / PRECISION;

        // Calculate the amount of ether to return to the user.
        saleValue = result - fees;
        return (saleValue, fees);
    }

    /// @notice Function to calculate the amount of reserve tokens needed to mint a continuous token.
    /// @param currentSupply The current supply of continuous tokens (in 1e18 format).
    /// @param reserveTokenBalance The balance of reserve tokens (in wei).
    /// @return depositAmount The amount of reserve tokens needed to mint a continuous token (in wei).
    function calculateMintCost(uint256 currentSupply, uint256 reserveTokenBalance)
        external
        view
        returns (uint256 depositAmount)
    {
        uint256 targetReturn = PRECISION; // We want to mint exactly 1 token, scaled by PRECISION

        // Binary search for the deposit amount
        uint256 low = 0;
        uint256 high = reserveTokenBalance;
        uint256 mid;

        while (high - low > 1) {
            mid = (low + high) / 2;

            // Calculate the return for depositing 'mid' amount of reserve tokens
            uint256 returnAmount = calculatePurchaseReturn(currentSupply, reserveTokenBalance, reserveRatio, mid);

            if (returnAmount < targetReturn) {
                low = mid;
            } else {
                high = mid;
            }
        }

        depositAmount = high;
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

    /// @param _reserveRatio The reserve ratio used to define the steepness of the bonding curve in ppm.
    function setReserveRatio(uint32 _reserveRatio) public {
        reserveRatio = _reserveRatio;
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
