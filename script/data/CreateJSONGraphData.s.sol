// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {LinearBondingCurve} from "src/linear-curve/LinearBondingCurve.sol";
import {ExponentialBondingCurve} from "src/exponential-curve/ExponentialBondingCurve.sol";
import {Calculations} from "src/libraries/Calculations.sol";

/// @title CreateJSONGraphData
/// @author Dustin Stacy
/// @notice This script is used to create a JSON file that contains the data for a bonding curve graph.
/// @dev The JSON file will contain the token ID, price in wei, and price in USD for a specified number of tokens.
/// @dev Running the script will create a JSON file at the specified destination.
/// @dev Launching the index.html file in the browser (Localhost) will display the graph.
/// @dev Warning! The script overwrites the existing JSON file at the specified destination.
///
///      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
///      !!!!!!!!!! Needs to be updated to work with the new bonding curve contracts !!!!!!!!!!
///      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
///
contract CreateJSONGraphData is Script {
    LinearBondingCurve public linCurve;
    ExponentialBondingCurve public expCurve;

    //curve variables
    uint256 supply;
    uint256 initialCost = 0.0001 ether;
    uint256 reserveBalance;
    uint256 amount = 100;

    // 0 = Linear, 1 = Exponential.
    uint256 curve = 1;

    // File destination
    string private constant DESTINATION = "/script/data/graphData.json";

    // Precision
    uint256 private constant PRECISION = 1e18;

    // Set the price of ETH in USD.
    uint256 private constant ethUSDPrice = 2600;

    function run() public {
        if (curve == 0) {
            linCurve = new LinearBondingCurve();
            linCurve.setInitialReserve(initialCost);
            (uint256[] memory tokenIds, uint256[] memory priceInWei, uint256[] memory priceInUSD) = createLinearGraph();
            string memory json = _createJson(tokenIds, priceInWei, priceInUSD);
            vm.writeFile(string.concat(vm.projectRoot(), DESTINATION), json);
            console2.log("Complete: The JSON file has been created at: ", DESTINATION);
        } else {
            expCurve = new ExponentialBondingCurve();
            expCurve.setReserveRatio(425000);
            (uint256[] memory tokenIds, uint256[] memory priceInWei, uint256[] memory priceInUSD) =
                createExponentialGraph();
            string memory json = _createJson(tokenIds, priceInWei, priceInUSD);
            vm.writeFile(string.concat(vm.projectRoot(), DESTINATION), json);
            console2.log("Complete: The JSON file has been created at: ", DESTINATION);
        }
    }

    function createLinearGraph()
        public
        returns (uint256[] memory tokenIds, uint256[] memory priceInWei, uint256[] memory priceInUSD)
    {
        tokenIds = new uint256[](amount);
        priceInWei = new uint256[](amount);
        priceInUSD = new uint256[](amount);
        reserveBalance = initialCost;

        for (uint256 i = 0; i < amount; i++) {
            supply += PRECISION;
            uint256 expectedPrice = linCurve.getMintCost(supply, reserveBalance);
            uint256 convertedPrice = Calculations.calculateUSDValue(ethUSDPrice, expectedPrice);

            tokenIds[i] = supply / PRECISION;
            priceInWei[i] = expectedPrice;
            priceInUSD[i] = convertedPrice;
            reserveBalance += expectedPrice;
        }

        return (tokenIds, priceInWei, priceInUSD);
    }

    function createExponentialGraph()
        public
        returns (uint256[] memory tokenIds, uint256[] memory priceInWei, uint256[] memory priceInUSD)
    {
        tokenIds = new uint256[](amount);
        priceInWei = new uint256[](amount);
        priceInUSD = new uint256[](amount);
        reserveBalance = 0.00001 ether;

        for (uint256 i = 0; i < amount; i++) {
            supply += PRECISION;
            uint256 expectedPrice = expCurve.calculateMintCost(supply, reserveBalance);
            uint256 convertedPrice = Calculations.calculateUSDValue(ethUSDPrice, expectedPrice);

            tokenIds[i] = supply / PRECISION;
            priceInWei[i] = expectedPrice;
            priceInUSD[i] = convertedPrice;
            reserveBalance += expectedPrice;
        }

        return (tokenIds, priceInWei, priceInUSD);
    }

    function _createJson(uint256[] memory tokens, uint256[] memory priceInWei, uint256[] memory priceInUSD)
        internal
        pure
        returns (string memory)
    {
        string memory json = "{\n";
        json = string(abi.encodePacked(json, '  "data": [\n'));

        for (uint256 i = 0; i < tokens.length; i++) {
            json = string(
                abi.encodePacked(
                    json,
                    '    { "token": ',
                    vm.toString(tokens[i]),
                    ', "priceInWei": ',
                    vm.toString(priceInWei[i]),
                    ', "priceInUSD": ',
                    vm.toString(priceInUSD[i]),
                    " }"
                )
            );
            if (i < tokens.length - 1) {
                json = string(abi.encodePacked(json, ",\n"));
            }
        }

        json = string(abi.encodePacked(json, "\n  ]\n}"));

        return json;
    }
}
