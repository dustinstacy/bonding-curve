// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Treasury is Ownable {
    IERC20 public token;

    event Deposited(address indexed from, uint256 amount);
    event Funded(address indexed to, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    constructor(IERC20 _token, address _timeLock) Ownable(_timeLock) {
        token = _token;
    }

    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit Deposited(msg.sender, amount);
    }

    function fund(uint256 amount, address to) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(token.transfer(to, amount), "Transfer failed");
        emit Funded(to, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function setToken(IERC20 _token) external onlyOwner {
        token = _token;
    }
}
