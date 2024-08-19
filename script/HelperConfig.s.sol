//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

abstract contract CodeConstants {
    /* Chain IDs */
    uint256 public constant MERLIN_CHAIN_ID = 4200;
    uint256 public constant MERLIN_TESTNET_CHAIN_ID = 686868;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    /* Addresses */
    address public FOUNDRY_DEFAULT_SENDER = address(uint160(uint256(keccak256("foundry default caller"))));
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    struct CurveConfig {
        address owner;
        address protocolFeeDestination;
        uint256 protocolFeePercent;
        uint256 feeSharePercent;
        uint256 initialReserve;
        uint32 reserveRatio;
        uint256 maxGasLimit;
    }

    CurveConfig public localCurveConfig;
    mapping(uint256 chainId => CurveConfig) public curveConfigs;

    function getConfig() public returns (CurveConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (CurveConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getOrCreateAnvilConfig() public returns (CurveConfig memory) {
        if (localCurveConfig.owner != address(0)) {
            return localCurveConfig;
        }

        localCurveConfig = CurveConfig({
            owner: FOUNDRY_DEFAULT_SENDER, // update to dao address
            protocolFeeDestination: FOUNDRY_DEFAULT_SENDER, // update to dao address
            protocolFeePercent: 100, // 1%
            feeSharePercent: 100, // 1%
            initialReserve: 0.0001 ether,
            reserveRatio: 500000, // 50.0%
            maxGasLimit: 1000000 // 1M Gwei
        });

        return localCurveConfig;
    }
}
