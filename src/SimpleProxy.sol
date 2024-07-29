// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

contract SimpleProxy is Proxy {
    // This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setImplementation(address newImplementation) public {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    function _implementation() internal view override returns (address implementationAddress) {
        assembly {
            implementationAddress := sload(_IMPLEMENTATION_SLOT)
        }
    }

    function getDataForBuyTokens(uint256 totalSupply, uint256 reserveBalance, uint256 reserveRatio, uint256 amount)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSignature(
            "getPrice(uint256,uint256,uint256,uint256)", totalSupply, reserveBalance, reserveRatio, amount
        );
    }

    function getDataForSellTokens(uint256 totalSupply, uint256 reserveBalance, uint256 reserveRatio, uint256 amount)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSignature(
            "getSalePrice(uint256,uint256,uint256,uint256)", totalSupply, reserveBalance, reserveRatio, amount
        );
    }

    receive() external payable {
        _fallback();
    }
}
