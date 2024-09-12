// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ExponentialBondingCurve} from "src/bonding-curves/ExponentialBondingCurve.sol";
import {ExponentialBondingCurveUpgradeMock} from "test/mocks/ExponentialBondingCurveUpgradeMock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeCurve is Script {
    function run(address proxyAddress) external returns (address) {
        vm.startBroadcast();
        ExponentialBondingCurveUpgradeMock newCurve = new ExponentialBondingCurveUpgradeMock();
        vm.stopBroadcast();
        address proxy = upgradeCurve(proxyAddress, address(newCurve));
        return proxy;
    }

    function upgradeCurve(address proxyAddress, address newCurve) public returns (address) {
        vm.startBroadcast();
        ExponentialBondingCurve proxy = ExponentialBondingCurve(payable(proxyAddress));
        proxy.upgradeToAndCall(address(newCurve), "");
        vm.stopBroadcast();
        return address(proxy);
    }
}
