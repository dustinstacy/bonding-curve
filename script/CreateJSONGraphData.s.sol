// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {LinearBondingCurve} from "src/LinearBondingCurve.sol";
import {ExponentialBondingCurve} from "src/ExponentialBondingCurve.sol";
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
    uint256 supply = 0;
    uint256 initialCost = 0.001 ether;
    uint256 scalingFactor = 10000;
    uint256 amount = 100;
    uint256 value = 0.001 ether;

    uint256 singleToken = 1;
    uint256 priceIncrement;
    int256 initialCostAdjustment;

    // 0 = Linear, 1 = Exponential.
    uint256 curve = 0;

    // File destination
    string private constant DESTINATION = "/script/data/graphData.json";

    function run() public {
        if (curve == 0) {
            linCurve = new LinearBondingCurve();
            (uint256[] memory tokenIds, uint256[] memory priceInWei, uint256[] memory priceInUSD) = createLinearGraph();
            string memory json = _createJson(tokenIds, priceInWei, priceInUSD);
            vm.writeFile(string.concat(vm.projectRoot(), DESTINATION), json);
            console2.log("Complete: The JSON file has been created at: ", DESTINATION);
        } else {
            expCurve = new ExponentialBondingCurve();
            (uint256[] memory tokenIds, uint256[] memory priceInWei, uint256[] memory priceInUSD) =
                createExponentialGraph();
            string memory json = _createJson(tokenIds, priceInWei, priceInUSD);
            vm.writeFile(string.concat(vm.projectRoot(), DESTINATION), json);
            console2.log("Complete: The JSON file has been created at: ", DESTINATION);
        }
    }

    function createLinearGraph()
        public
        view
        returns (uint256[] memory tokenIds, uint256[] memory priceInWei, uint256[] memory priceInUSD)
    {
        tokenIds = new uint256[](amount);
        priceInWei = new uint256[](amount);
        priceInUSD = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            // Need to update this to work with the new bonding curve contracts.
            // uint256 tokenId = supply + i;
            // uint256 expectedPrice = linCurve.calculatePurchaseReturn(tokenId, initialCost, value);
            // uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), expectedPrice);

            // tokenIds[i] = tokenId;
            // priceInWei[i] = expectedPrice;
            // priceInUSD[i] = convertedPrice;
        }

        return (tokenIds, priceInWei, priceInUSD);
    }

    function createExponentialGraph()
        public
        view
        returns (uint256[] memory tokenIds, uint256[] memory priceInWei, uint256[] memory priceInUSD)
    {
        tokenIds = new uint256[](amount);
        priceInWei = new uint256[](amount);
        priceInUSD = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            // Need to update this to work with the new bonding curve contracts.
            // uint256 expectedPrice =
            //     expCurve.calculatePurchaseReturn(supply + i, initialCost, scalingFactor, singleToken);
            // uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), expectedPrice);

            // tokenIds[i] = supply + i + 1;
            // priceInWei[i] = expectedPrice;
            // priceInUSD[i] = convertedPrice;
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
                    '    { "Token": ',
                    vm.toString(tokens[i]),
                    ', "Price In Wei": ',
                    vm.toString(priceInWei[i]),
                    ', "Price In USD": ',
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
