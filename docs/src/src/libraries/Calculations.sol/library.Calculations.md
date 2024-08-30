# Calculations
[Git Source](https://github.com/dustinstacy/bonding-curve/blob/7a2c4a7e41ef04642ab28f4be4017b9996da4af2/src/libraries/Calculations.sol)

**Author:**
Dustin Stacy

This library contains the math functions for converting between token amounts and USD values.

*In context of this project, this library may not be necessary, but it is included to demonstrate potential use cases.*


## State Variables
### ADDITIONAL_FEED_PRECISION
This precision returns USD value with 4 decimal places i.e. $0.0000;

*Used to adjust decimals of price feed results.*


```solidity
uint256 private constant ADDITIONAL_FEED_PRECISION = 1e4;
```


### PRECISION
*Used to adjust decimals to relative USD value.*


```solidity
uint256 private constant PRECISION = 1e18;
```


### BASIS_POINTS_PRECISION
The number of basis points in 100%.


```solidity
uint256 private constant BASIS_POINTS_PRECISION = 1e4;
```


## Functions
### calculateScalingFactorPercent

Calculates the scaling factor percent used to determine the token price increment.

*Compensates for solidity's lack of floating point numbers.*


```solidity
function calculateScalingFactorPercent(uint256 scalingFactor) external pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`scalingFactor`|`uint256`|The scaling factor used to determine the price of tokens.|


### calculatePriceIncrement


```solidity
function calculatePriceIncrement(uint256 initialCost, uint256 scalingFactorPercent) external pure returns (uint256);
```

### calculateInitialCostAdjustment

Calculates the initial cost adjustment based on the initial cost and scaling factor percent.

*Returns int256 because the return value can be negative if the scaling factor is greater than 100%.*


```solidity
function calculateInitialCostAdjustment(uint256 initialCost, uint256 priceIncrement) external pure returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initialCost`|`uint256`|The initial cost of the token.|
|`priceIncrement`|`uint256`||


### calculateUSDValue

Calculates the USD value of the tokens.

*For now the ethPrice is passed in as a parameter, but in a real world scenario, it would be fetched from a price feed.*


```solidity
function calculateUSDValue(uint256 ethPrice, uint256 amount) external pure returns (uint256 usdValue);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ethPrice`|`uint256`|The latest price of ETH.|
|`amount`|`uint256`|The amount of tokens.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`usdValue`|`uint256`|The USD value of the tokens.|


### getAdditionaFeedPrecision


```solidity
function getAdditionaFeedPrecision() external pure returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The `ADDITIONAL_FEED_PRECISION` constant.|


### getPrecision


```solidity
function getPrecision() external pure returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The `PRECISION` constant.|


### getBasisPoints


```solidity
function getBasisPoints() external pure returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The `BASIS_POINTS` constant.|


