// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// import {Script} from "forge-std/Script.sol";

// contract UpgradeBondingCurve is Script {
//     function run() external returns (address proxy) {
//         // address of the most recently deployed bonding curve
//         address mostRecentlyDeployed;

//         vm.startBroadcast();

//         // deploy new bonding curve
//         /* ExponentialBondingCurveV2 newCurve = new ExponentialBondingCurveV2(); */

//         vm.stopBroadcast();

//         // upgrade the most recently deployed bonding curve
//         /* return proxy = upgradeBox(mostRecentlyDeployed, address(newCurve)); */
//     }

//     function upgradeBox(address proxyAddress, address newImplementation) public returns (address) {
//         vm.startBroadcast();

//         // Get the proxy
//         /* ExponentialBondingCurveV1 proxy = ExponentialBondingCurveV1(proxyAddress); */

//         // Call upgradeToAndCall on the proxy
//         /* proxy.upgradeToAndCall(address(newImplementation), ""); */

//         vm.stopBroadcast();
//         /* return address(proxy); */
//     }
// }
