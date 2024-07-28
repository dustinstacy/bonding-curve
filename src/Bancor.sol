// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BancorBondingCurve
 * @dev This contract implements the Bancor bonding curve formula for buying and selling tokens.
 */
contract BancorBondingCurve is Ownable {
    uint32 private constant MAX_RESERVE_RATIO = 1000000;
    uint256 private constant FIXED_POINT_SCALAR = 1e18;

    // State variables
    /// @notice  reserveBalance keeps track of the total amount of Ether
    /// (or other reserve currency) held by the contract.
    /// This balance is crucial for the functioning of the bonding
    /// curve as it influences the price of tokens.
    uint256 public reserveBalance;

    /// @notice reserveRatio is used to define the steepness or shape of the bonding curve.
    /// It's specified in basis points, where 100 basis points equal 1 percent. For example,
    /// a reserve ratio of 5000 corresponds to a 50% reserve ratio.
    uint32 public reserveRatio;
    IERC20 public token;

    // Events
    event Buy(address indexed buyer, uint256 amount);
    event Sell(address indexed seller, uint256 amount);

    constructor(address _token, uint32 _reserveRatio) Ownable(msg.sender) {
        token = IERC20(_token);
        reserveRatio = _reserveRatio;
    }

    /**
     * @dev Calculate the amount of tokens to be received for a given deposit amount.
     * @param _supply Total supply of tokens
     * @param _reserveBalance Total reserve token balance
     * @param _reserveRatio Reserve ratio in basis points
     * @param _depositAmount Amount of reserve tokens to deposit
     * @return Amount of continuous tokens received
     */
    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _depositAmount
    ) public pure returns (uint256) {
        require(
            _supply > 0 && _reserveBalance > 0 && _reserveRatio > 0 && _reserveRatio <= MAX_RESERVE_RATIO,
            "Invalid input"
        );

        // Special case for 0 deposit amount
        if (_depositAmount == 0) {
            return 0;
        }

        // Special case if the ratio = 100%
        if (_reserveRatio == MAX_RESERVE_RATIO) {
            return _supply * _depositAmount / _reserveBalance;
        }

        // Use fixed-point arithmetic for precision
        uint256 baseN = (_depositAmount + _reserveBalance) * FIXED_POINT_SCALAR;
        uint256 exponent = (_reserveRatio * FIXED_POINT_SCALAR) / MAX_RESERVE_RATIO;

        uint256 result = fixedPointPower(baseN, exponent);
        uint256 newTokenSupply = (_supply * result) / FIXED_POINT_SCALAR;
        return newTokenSupply - _supply;
    }

    /**
     * @dev Calculate the amount of reserve tokens to be received for a given amount of tokens sold.
     * @param _supply Total supply of tokens
     * @param _reserveBalance Total reserve token balance
     * @param _reserveRatio Reserve ratio in basis points
     * @param _sellAmount Amount of continuous tokens to sell
     * @return Amount of reserve tokens received
     */
    function calculateSaleReturn(uint256 _supply, uint256 _reserveBalance, uint32 _reserveRatio, uint256 _sellAmount)
        public
        pure
        returns (uint256)
    {
        require(
            _supply > 0 && _reserveBalance > 0 && _reserveRatio > 0 && _reserveRatio <= MAX_RESERVE_RATIO
                && _sellAmount <= _supply,
            "Invalid input"
        );

        // Special case for 0 sell amount
        if (_sellAmount == 0) {
            return 0;
        }

        // Special case for selling the entire supply
        if (_sellAmount == _supply) {
            return _reserveBalance;
        }

        // Special case if the ratio = 100%
        if (_reserveRatio == MAX_RESERVE_RATIO) {
            return _reserveBalance * _sellAmount / _supply;
        }

        // Fixed-point arithmetic for precision
        uint256 base = (_supply * FIXED_POINT_SCALAR) / (_supply - _sellAmount);
        uint256 exponent = FIXED_POINT_SCALAR / ((_reserveRatio * FIXED_POINT_SCALAR) / MAX_RESERVE_RATIO);

        uint256 result = fixedPointPower(base, exponent);
        uint256 oldBalance = (_reserveBalance * FIXED_POINT_SCALAR) / result;
        uint256 newBalance = _reserveBalance;

        return oldBalance - newBalance;
    }

    /**
     * @dev Compute fixed-point power.
     * @param base The base value
     * @param exponent The exponent value
     * @return Result of base^exponent
     */
    function fixedPointPower(uint256 base, uint256 exponent) internal pure returns (uint256) {
        uint256 result = FIXED_POINT_SCALAR;
        uint256 x = base;
        uint256 n = exponent;

        while (n > 0) {
            if (n % 2 == 1) {
                result = (result * x) / FIXED_POINT_SCALAR;
            }
            x = (x * x) / FIXED_POINT_SCALAR;
            n /= 2;
        }

        return result;
    }

    /**
     * @dev Function to buy tokens.
     * @param amount Amount of tokens to buy
     */
    function buy(uint256 amount) external payable {
        uint256 cost = calculatePurchaseReturn(token.totalSupply(), reserveBalance, reserveRatio, msg.value);
        require(msg.value >= cost, "Insufficient ETH sent");

        reserveBalance += msg.value;
        token.transfer(msg.sender, amount);

        emit Buy(msg.sender, amount);
    }

    /**
     * @dev Function to sell tokens.
     * @param amount Amount of tokens to sell
     */
    function sell(uint256 amount) external {
        uint256 refund = calculateSaleReturn(token.totalSupply(), reserveBalance, reserveRatio, amount);
        require(address(this).balance >= refund, "Insufficient contract balance");

        reserveBalance -= refund;
        token.transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(refund);

        emit Sell(msg.sender, amount);
    }

    /**
     * @dev Function to withdraw ETH from the contract.
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner()).transfer(amount);
    }

    /**
     * @dev Function to update the reserve ratio.
     * @param _reserveRatio New reserve ratio
     */
    function setReserveRatio(uint32 _reserveRatio) external onlyOwner {
        reserveRatio = _reserveRatio;
    }
}
