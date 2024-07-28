// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseBondingCurve is Ownable {
    IERC20 public token;

    /// @notice  reserveBalance keeps track of the total amount of Ether
    /// (or other reserve currency) held by the contract.
    /// This balance is crucial for the functioning of the bonding
    /// curve as it influences the price of tokens.
    uint256 public reserveBalance;

    /// @notice reserveRatio is used to define the steepness or shape of the bonding curve.
    /// It's specified in basis points, where 100 basis points equal 1 percent. For example,
    /// a reserve ratio of 5000 corresponds to a 50% reserve ratio.
    uint256 public reserveRatio;

    uint256 public initialPrice = 1e10;

    event Buy(address indexed buyer, uint256 amount);
    event Sell(address indexed seller, uint256 amount);

    constructor(address _token, uint256 _reserveRatio) Ownable(msg.sender) {
        token = IERC20(_token);
        reserveRatio = _reserveRatio;
    }

    // Function to buy tokens
    function buy(uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than 0");

        uint256 cost = calculateBuyPrice(amount);
        require(msg.value >= cost, "Insufficient ETH sent");

        reserveBalance += msg.value;
        token.transfer(msg.sender, amount);

        emit Buy(msg.sender, amount);
    }

    // Function to sell tokens
    function sell(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient token balance");

        uint256 refund = calculateSellPrice(amount);
        require(address(this).balance >= refund, "Insufficient contract balance");

        reserveBalance -= refund;
        token.transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(refund);

        emit Sell(msg.sender, amount);
    }

    // Calculate buy price using the bonding curve formula
    function calculateBuyPrice(uint256 amount) public view returns (uint256) {
        if (reserveBalance == 0) {
            // Set a default or initial price when reserveBalance is zero
            return initialPrice * amount;
        } else {
            // Use bonding curve formula
            return amount * (reserveBalance + amount) / reserveBalance;
        }
    }

    // Calculate sell price using the bonding curve formula
    function calculateSellPrice(uint256 amount) public view returns (uint256) {
        return (reserveBalance * amount) / (reserveBalance + amount);
    }

    // Allow the owner to withdraw ETH from the contract
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner()).transfer(amount);
    }

    // Allow the owner to update the reserve ratio
    function setReserveRatio(uint256 _reserveRatio) external onlyOwner {
        reserveRatio = _reserveRatio;
    }
}
