# Utils
[Git Source](https://github.com/dustinstacy/bonding-curve/blob/7a2c4a7e41ef04642ab28f4be4017b9996da4af2/src/exponential-curve/Utils.sol)


## Functions
### greaterThanZero


```solidity
modifier greaterThanZero(uint256 _amount);
```

### validAddress


```solidity
modifier validAddress(address _address);
```

### notThis


```solidity
modifier notThis(address _address);
```

### safeAdd

*returns the sum of _x and _y, asserts if the calculation overflows*


```solidity
function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_x`|`uint256`|  value 1|
|`_y`|`uint256`|  value 2|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|sum|


### safeMul

*returns the product of multiplying _x by _y, asserts if the calculation overflows*


```solidity
function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_x`|`uint256`|  factor 1|
|`_y`|`uint256`|  factor 2|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|product|


