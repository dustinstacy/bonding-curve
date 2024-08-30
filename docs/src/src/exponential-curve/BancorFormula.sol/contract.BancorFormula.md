# BancorFormula
[Git Source](https://github.com/dustinstacy/bonding-curve/blob/7a2c4a7e41ef04642ab28f4be4017b9996da4af2/src/exponential-curve/BancorFormula.sol)

**Inherits:**
[Utils](/src/exponential-curve/Utils.sol/abstract.Utils.md)


## State Variables
### VERSION

```solidity
string private constant VERSION = "0.3";
```


### ONE

```solidity
uint256 private constant ONE = 1;
```


### MAX_WEIGHT

```solidity
uint32 private constant MAX_WEIGHT = 1000000;
```


### MIN_PRECISION

```solidity
uint8 private constant MIN_PRECISION = 32;
```


### MAX_PRECISION

```solidity
uint8 private constant MAX_PRECISION = 127;
```


### FIXED_1
Auto-generated via 'PrintIntScalingFactors.py'


```solidity
uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
```


### FIXED_2

```solidity
uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
```


### MAX_NUM

```solidity
uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;
```


### LN2_NUMERATOR
Auto-generated via 'PrintLn2ScalingFactors.py'


```solidity
uint256 private constant LN2_NUMERATOR = 0x3f80fe03f80fe03f80fe03f80fe03f8;
```


### LN2_DENOMINATOR

```solidity
uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;
```


### OPT_LOG_MAX_VAL
Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'


```solidity
uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
```


### OPT_EXP_MAX_VAL

```solidity
uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;
```


### maxExpArray
Auto-generated via 'PrintFunctionConstructor.py'


```solidity
uint256[128] private maxExpArray;
```


## Functions
### constructor


```solidity
constructor();
```

### calculatePurchaseReturn

*given a token supply, connector balance, weight and a deposit amount (in the connector token),
calculates the return for a given conversion (in the main token)
Formula:
Return = _supply * ((1 + _depositAmount / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)*


```solidity
function calculatePurchaseReturn(
    uint256 _supply,
    uint256 _connectorBalance,
    uint32 _connectorWeight,
    uint256 _depositAmount
) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_supply`|`uint256`|             token total supply|
|`_connectorBalance`|`uint256`|   total connector balance|
|`_connectorWeight`|`uint32`|    connector weight, represented in ppm, 1-1000000|
|`_depositAmount`|`uint256`|      deposit amount, in connector token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|purchase return amount|


### calculateSaleReturn

*given a token supply, connector balance, weight and a sell amount (in the main token),
calculates the return for a given conversion (in the connector token)
Formula:
Return = _connectorBalance * (1 - (1 - _sellAmount / _supply) ^ (1 / (_connectorWeight / 1000000)))*


```solidity
function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount)
    public
    view
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_supply`|`uint256`|             token total supply|
|`_connectorBalance`|`uint256`|   total connector|
|`_connectorWeight`|`uint32`|    constant connector Weight, represented in ppm, 1-1000000|
|`_sellAmount`|`uint256`|         sell amount, in the token itself|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|sale return amount|


### calculateCrossConnectorReturn

*given two connector balances/weights and a sell amount (in the first connector token),
calculates the return for a conversion from the first connector token to the second connector token (in the second connector token)
Formula:
Return = _toConnectorBalance * (1 - (_fromConnectorBalance / (_fromConnectorBalance + _amount)) ^ (_fromConnectorWeight / _toConnectorWeight))*


```solidity
function calculateCrossConnectorReturn(
    uint256 _fromConnectorBalance,
    uint32 _fromConnectorWeight,
    uint256 _toConnectorBalance,
    uint32 _toConnectorWeight,
    uint256 _amount
) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fromConnectorBalance`|`uint256`|   input connector balance|
|`_fromConnectorWeight`|`uint32`|    input connector weight, represented in ppm, 1-1000000|
|`_toConnectorBalance`|`uint256`|     output connector balance|
|`_toConnectorWeight`|`uint32`|      output connector weight, represented in ppm, 1-1000000|
|`_amount`|`uint256`|                 input connector amount|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|second connector amount|


### power

General Description:
Determine a value of precision.
Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
Return the result along with the precision used.
Detailed Description:
Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
The larger "precision" is, the more accurately this value represents the real value.
However, the larger "precision" is, the more bits are required in order to store this value.
And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".


```solidity
function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal view returns (uint256, uint8);
```

### generalLog

Compute log(x / FIXED_1) * FIXED_1.
This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.


```solidity
function generalLog(uint256 x) internal pure returns (uint256);
```

### floorLog2

Compute the largest integer smaller than or equal to the binary logarithm of the input.


```solidity
function floorLog2(uint256 _n) internal pure returns (uint8);
```

### findPositionInMaxExpArray

The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
- This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
- This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]


```solidity
function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8);
```

### generalExp

This function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
It approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
It returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".


```solidity
function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256);
```

### optimalLog

Return log(x / FIXED_1) * FIXED_1
Input range: FIXED_1 <= x <= LOG_EXP_MAX_VAL - 1
Auto-generated via 'PrintFunctionOptimalLog.py'
Detailed description:
- Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
- The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
- The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
- The natural logarithm of the input is calculated by summing up the intermediate results above
- For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)


```solidity
function optimalLog(uint256 x) internal pure returns (uint256);
```

### optimalExp

Return e ^ (x / FIXED_1) * FIXED_1
Input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
Auto-generated via 'PrintFunctionOptimalExp.py'
Detailed description:
- Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
- The exponentiation of each binary exponent is given (pre-calculated)
- The exponentiation of r is calculated via Taylor series for e^x, where x = r
- The exponentiation of the input is calculated by multiplying the intermediate results above
- For example: e^5.021692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859


```solidity
function optimalExp(uint256 x) internal pure returns (uint256);
```

