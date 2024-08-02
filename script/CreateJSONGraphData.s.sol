// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {LinearBondingCurve} from "src/LinearBondingCurve.sol";
import {ExponentialBondingCurve} from "src/ExponentialBondingCurve.sol";
import {Calculations} from "src/libraries/Calculations.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract CreateJSONGraphData is Script {
    LinearBondingCurve public linCurve;
    ExponentialBondingCurve public expCurve;
    MockV3Aggregator ethUSDPriceFeed;

    //curve variables
    uint256 supply = 100;
    uint256 initialCost = 0.001 ether;
    uint256 scalingFactor = 1000;
    uint256 amount = 100;
    uint256 singleToken = 1;
    int256 initialCostAdjustment;
    // 0 = Linear, 1 = Exponential.
    uint256 curve = 1;

    string private constant DESTINATION = "/script/data/graphData.json";
    uint8 private constant DECIMALS = 8;
    int256 private constant ETH_USD_PRICE = 3265;

    function run() public {
        ethUSDPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);

        if (curve == 0) {
            linCurve = new LinearBondingCurve();
            scalingFactor = Calculations.calculateScalingFactorPercent(scalingFactor);
            initialCostAdjustment = Calculations.calculateInitialCostAdjustment(initialCost, scalingFactor);
            (uint256[] memory tokenIds, uint256[] memory priceInWei, uint256[] memory prices) = createLinearGraph();
            string memory json = _createJson(tokenIds, priceInWei, prices);
            vm.writeFile(string.concat(vm.projectRoot(), DESTINATION), json);
            console2.log("Complete: The JSON file has been created at: ", DESTINATION);
        } else {
            expCurve = new ExponentialBondingCurve();
            (uint256[] memory tokenIds, uint256[] memory priceInWei, uint256[] memory prices) = createExponentialGraph();
            string memory json = _createJson(tokenIds, priceInWei, prices);
            vm.writeFile(string.concat(vm.projectRoot(), DESTINATION), json);
            console2.log("Complete: The JSON file has been created at: ", DESTINATION);
        }
    }

    function createLinearGraph()
        public
        view
        returns (uint256[] memory tokenIds, uint256[] memory priceInWei, uint256[] memory prices)
    {
        tokenIds = new uint256[](amount);
        priceInWei = new uint256[](amount);
        prices = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = supply + i;
            uint256 expectedPrice =
                linCurve.getRawBuyPrice(tokenId, initialCost, scalingFactor, singleToken, initialCostAdjustment);
            uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), expectedPrice);

            tokenIds[i] = tokenId;
            priceInWei[i] = expectedPrice;
            prices[i] = convertedPrice;
        }

        return (tokenIds, priceInWei, prices);
    }

    function createExponentialGraph()
        public
        view
        returns (uint256[] memory tokenIds, uint256[] memory priceInWei, uint256[] memory prices)
    {
        tokenIds = new uint256[](amount);
        priceInWei = new uint256[](amount);
        prices = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            uint256 expectedPrice = expCurve.getRawPrice(supply + i, initialCost, scalingFactor, singleToken);
            uint256 convertedPrice = Calculations.calculateUSDValue(address(ethUSDPriceFeed), expectedPrice);

            tokenIds[i] = supply + i + 1;
            priceInWei[i] = expectedPrice;
            prices[i] = convertedPrice;
        }

        return (tokenIds, priceInWei, prices);
    }

    function _createJson(uint256[] memory tokens, uint256[] memory priceInWei, uint256[] memory prices)
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
                    ', "price": ',
                    vm.toString(prices[i]),
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
