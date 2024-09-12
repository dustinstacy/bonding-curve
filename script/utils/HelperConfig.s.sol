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
        uint256 protocolFeePercent;
        uint256 feeSharePercent;
        uint256 initialReserve;
        uint32 reserveRatio;
        uint256 maxGasLimit;
    }

    struct NetworkConfig {
        address admin;
        address protocolFeeDestination;
    }

    CurveConfig public activeCurveConfig;
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == MERLIN_TESTNET_CHAIN_ID) {
            (activeCurveConfig, activeNetworkConfig) = getMerlinTestnetConfig();
        } else if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            (activeCurveConfig, activeNetworkConfig) = getEthSepoliaConfig();
        } else if (block.chainid == LOCAL_CHAIN_ID) {
            (activeCurveConfig, activeNetworkConfig) = getOrCreateAnvilConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public view returns (CurveConfig memory, NetworkConfig memory) {
        return (activeCurveConfig, activeNetworkConfig);
    }

    function getMerlinTestnetConfig() public returns (CurveConfig memory, NetworkConfig memory) {
        activeCurveConfig = CurveConfig({
            protocolFeePercent: 100, // 1%
            feeSharePercent: 0, // 0%
            initialReserve: 100000000000000,
            reserveRatio: 500000, // 50.0%
            maxGasLimit: 1000000 // 1M Gwei
        });

        activeNetworkConfig = NetworkConfig({
            admin: 0x3ef270a74CaAe5Ca4b740a66497085abBf236655,
            protocolFeeDestination: 0x3ef270a74CaAe5Ca4b740a66497085abBf236655
        });

        return (activeCurveConfig, activeNetworkConfig);
    }

    function getEthSepoliaConfig() public returns (CurveConfig memory, NetworkConfig memory) {
        activeCurveConfig = CurveConfig({
            protocolFeePercent: 100, // 1%
            feeSharePercent: 0, // 0%
            initialReserve: 0.0001 ether,
            reserveRatio: 500000, // 50.0%
            maxGasLimit: 1000000 // 1M Gwei
        });

        activeNetworkConfig = NetworkConfig({
            admin: 0x3ef270a74CaAe5Ca4b740a66497085abBf236655,
            protocolFeeDestination: 0x3ef270a74CaAe5Ca4b740a66497085abBf236655
        });

        return (activeCurveConfig, activeNetworkConfig);
    }

    function getOrCreateAnvilConfig() public returns (CurveConfig memory, NetworkConfig memory) {
        activeCurveConfig = CurveConfig({
            protocolFeePercent: 100, // 1%
            feeSharePercent: 0, // 0%
            initialReserve: 0.0001 ether,
            reserveRatio: 500000, // 50.0%
            maxGasLimit: 1000000 // 1M Gwei
        });

        address admin = makeAddr("admin");

        activeNetworkConfig = NetworkConfig({admin: admin, protocolFeeDestination: admin});

        return (activeCurveConfig, activeNetworkConfig);
    }
}
