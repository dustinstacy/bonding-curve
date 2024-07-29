//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {BancorBondingCurve} from "src/BancorBondingCurve.sol";

contract ContinuousToken is Ownable, ERC20, BancorBondingCurve {
    event Minted(address sender, uint256 amount, uint256 deposit);
    event Burned(address sender, uint256 amount, uint256 refund);

    // Reserve balance state
    uint256 private _reserveBalance;

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply, uint32 _reserveRatio)
        ERC20(_name, _symbol)
        BancorBondingCurve(_reserveRatio)
        Ownable(msg.sender)
    {
        _mint(msg.sender, _initialSupply);
        _reserveBalance = 0; // Initialize reserve balance, adjust according to your needs
    }

    function continuousSupply() public view override returns (uint256) {
        return totalSupply(); // Continuous Token total supply
    }

    function reserveBalance() public view override returns (uint256) {
        return _reserveBalance; // Return the reserve balance
    }

    function _continuousMint(uint256 _deposit) internal returns (uint256) {
        require(_deposit > 0, "Deposit must be non-zero.");

        uint256 rewardAmount = getContinuousMintReward(_deposit);
        _mint(msg.sender, rewardAmount);
        emit Minted(msg.sender, rewardAmount, _deposit);
        return rewardAmount;
    }

    function _continuousBurn(uint256 _amount) internal returns (uint256) {
        require(_amount > 0, "Amount must be non-zero.");
        require(balanceOf(msg.sender) >= _amount, "Insufficient tokens to burn.");

        uint256 refundAmount = getContinuousBurnRefund(_amount);
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount, refundAmount);
        return refundAmount;
    }

    function sponsoredBurn(uint256 _amount) public {
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount, 0);
    }
}
