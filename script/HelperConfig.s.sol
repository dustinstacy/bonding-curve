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

    CurveConfig public activeCurveConfig;

    constructor() {
        if (block.chainid == MERLIN_TESTNET_CHAIN_ID) {
            activeCurveConfig = getMerlinTestnetConfig();
        } else if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            activeCurveConfig = getEthSepoliaConfig();
        } else if (block.chainid == LOCAL_CHAIN_ID) {
            activeCurveConfig = getOrCreateAnvilConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

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

    function getMerlinTestnetConfig() public pure returns (CurveConfig memory) {
        return CurveConfig({
            owner: 0x3ef270a74CaAe5Ca4b740a66497085abBf236655, // update to dao address
            protocolFeeDestination: 0x3ef270a74CaAe5Ca4b740a66497085abBf236655, // update to dao address
            protocolFeePercent: 100, // 1%
            feeSharePercent: 0, // 0%
            initialReserve: 0.0001 ether,
            reserveRatio: 500000, // 50.0%
            maxGasLimit: 1000000 // 1M Gwei
        });
    }

    function getEthSepoliaConfig() public pure returns (CurveConfig memory) {
        return CurveConfig({
            owner: 0x3ef270a74CaAe5Ca4b740a66497085abBf236655, // update to dao address
            protocolFeeDestination: 0x3ef270a74CaAe5Ca4b740a66497085abBf236655, // update to dao address
            protocolFeePercent: 100, // 1%
            feeSharePercent: 0, // 0%
            initialReserve: 0.0001 ether,
            reserveRatio: 500000, // 50.0%
            maxGasLimit: 1000000 // 1M Gwei
        });
    }

    function getOrCreateAnvilConfig() public returns (CurveConfig memory) {
        if (activeCurveConfig.owner != address(0)) {
            return activeCurveConfig;
        }

        activeCurveConfig = CurveConfig({
            owner: FOUNDRY_DEFAULT_SENDER, // update to dao address
            protocolFeeDestination: FOUNDRY_DEFAULT_SENDER, // update to dao address
            protocolFeePercent: 100, // 1%
            feeSharePercent: 0, // 0%
            initialReserve: 0.0001 ether,
            reserveRatio: 500000, // 50.0%
            maxGasLimit: 1000000 // 1M Gwei
        });

        return activeCurveConfig;
    }
}
