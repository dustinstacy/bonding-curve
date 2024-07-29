// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BondingCurve {
    /// @notice  reserveBalance keeps track of the total amount of Ether
    /// (or other reserve currency) held by the contract.
    /// This balance is crucial for the functioning of the bonding
    /// curve as it influences the price of tokens.
    uint256 public reserveBalance;

    /// @notice reserveRatio is used to define the steepness or shape of the bonding curve.
    /// It's specified in basis points, where 100 basis points equal 1 percent. For example,
    /// a reserve ratio of 5000 corresponds to a 50% reserve ratio.
    uint256 public reserveRatio;

    /// @notice tokenSupply keeps track of the total amount of tokens in circulation.
    uint256 public totalSupply;

    // Event to log purchases
    event TokensPurchased(address indexed buyer, uint256 amountSpent, uint256 tokensMinted);
    // Event to log sales
    event TokensSold(address indexed seller, uint256 tokensSold, uint256 amountReceived);

    constructor() {
        reserveBalance = 0;
        totalSupply = 0;
    }

    // Purchase tokens
    function buyTokens() external payable {
        require(msg.value > 0, "Send ETH to buy tokens");

        uint256 tokensToMint = calculatePurchaseReturn(msg.value);
        totalSupply += tokensToMint;
        reserveBalance += msg.value;

        emit TokensPurchased(msg.sender, msg.value, tokensToMint);
    }

    // Sell tokens
    function sellTokens(uint256 _amount) external {
        require(_amount > 0 && _amount <= totalSupply, "Invalid token amount");

        uint256 amountToSend = calculateSaleReturn(_amount);
        require(amountToSend <= reserveBalance, "Insufficient reserve balance");

        totalSupply -= _amount;
        reserveBalance -= amountToSend;

        payable(msg.sender).transfer(amountToSend);

        emit TokensSold(msg.sender, _amount, amountToSend);
    }

    // Calculate the number of tokens to mint for a given amount of ETH
    function calculatePurchaseReturn(uint256 _reserveTokensReceived) public view returns (uint256) {
        if (totalSupply == 0) {
            return _reserveTokensReceived * 100; // Initial minting rate
        }

        // Exponential increase calculation
        uint256 newSupply =
            totalSupply * ((1 + _reserveTokensReceived * 1e18 / reserveBalance) ** reserveRatio / 1e18 - 1);
        return newSupply - totalSupply;
    }

    // Calculate the amount of ETH to send for a given amount of tokens
    function calculateSaleReturn(uint256 _continuousTokensReceived) public view returns (uint256) {
        if (totalSupply == 0) {
            return _continuousTokensReceived / 100; // Initial selling rate
        }

        // Exponential decrease calculation
        uint256 amountToSend =
            reserveBalance * (1 - (1 - _continuousTokensReceived * 1e18 / totalSupply) ** (1e18 / reserveRatio) / 1e18);
        return amountToSend;
    }
}
