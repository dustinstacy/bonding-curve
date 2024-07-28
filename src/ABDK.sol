// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@abdk-consulting/abdk-libraries-solidity/ABDKMath64x64.sol";

// contract BondingCurve is Ownable {
//     using ABDKMath64x64 for int128;

//     IERC20 public token;
//     int128 public reserveRatio; // Reserve ratio in 64.64 fixed-point format (e.g., 0.5 for 50%)

//     uint256 public totalSupply;
//     uint256 public reserveBalance;

//     event Buy(address indexed buyer, uint256 amount);
//     event Sell(address indexed seller, uint256 amount);

//     constructor(address _token, int128 _reserveRatio) Ownable() {
//         token = IERC20(_token);
//         reserveRatio = _reserveRatio;
//     }

//     // Function to buy tokens
//     function buy(uint256 amount) external payable {
//         require(amount > 0, "Amount must be greater than 0");

//         // Calculate the price using ABDK
//         int128 amountInt = ABDKMath64x64.fromUInt(amount);
//         int128 supplyInt = ABDKMath64x64.fromUInt(totalSupply);
//         int128 price = getBuyPrice(supplyInt, amountInt);
//         uint256 cost = ABDKMath64x64.toUInt(price);

//         require(msg.value >= cost, "Insufficient ETH sent");

//         reserveBalance += msg.value;
//         totalSupply += amount;

//         token.transfer(msg.sender, amount);

//         emit Buy(msg.sender, amount);
//     }

//     // Function to sell tokens
//     function sell(uint256 amount) external {
//         require(amount > 0, "Amount must be greater than 0");
//         require(token.balanceOf(msg.sender) >= amount, "Insufficient token balance");

//         // Calculate the refund using ABDK
//         int128 amountInt = ABDKMath64x64.fromUInt(amount);
//         int128 supplyInt = ABDKMath64x64.fromUInt(totalSupply);
//         int128 refund = getSellPrice(supplyInt, amountInt);
//         uint256 refundAmount = ABDKMath64x64.toUInt(refund);

//         require(address(this).balance >= refundAmount, "Insufficient contract balance");

//         totalSupply -= amount;
//         reserveBalance -= refundAmount;

//         token.transferFrom(msg.sender, address(this), amount);
//         payable(msg.sender).transfer(refundAmount);

//         emit Sell(msg.sender, amount);
//     }

//     // Calculate the buy price using ABDK
//     function getBuyPrice(int128 supply, int128 amount) internal view returns (int128) {
//         int128 newSupply = supply.add(amount);
//         int128 sum1 = supply.mul(supply.add(1)).mul(supply.mul(2).add(1)).div(ABDKMath64x64.fromUInt(6));
//         int128 sum2 = newSupply.mul(newSupply.add(1)).mul(newSupply.mul(2).add(1)).div(ABDKMath64x64.fromUInt(6));
//         int128 price = sum2.sub(sum1).div(reserveRatio);
//         return price;
//     }

//     // Calculate the sell price using ABDK
//     function getSellPrice(int128 supply, int128 amount) internal view returns (int128) {
//         int128 newSupply = supply.sub(amount);
//         int128 sum1 = supply.mul(supply.add(1)).mul(supply.mul(2).add(1)).div(ABDKMath64x64.fromUInt(6));
//         int128 sum2 = newSupply.mul(newSupply.add(1)).mul(newSupply.mul(2).add(1)).div(ABDKMath64x64.fromUInt(6));
//         int128 refund = reserveRatio.mul(sum1.sub(sum2));
//         return refund;
//     }

//     // Allow the owner to withdraw ETH from the contract
//     function withdraw(uint256 amount) external onlyOwner {
//         require(address(this).balance >= amount, "Insufficient balance");
//         payable(owner()).transfer(amount);
//     }

//     // Allow the owner to update the reserve ratio
//     function setReserveRatio(int128 _reserveRatio) external onlyOwner {
//         reserveRatio = _reserveRatio;
//     }

//     // Fallback function to receive ETH
//     receive() external payable {}
// }
