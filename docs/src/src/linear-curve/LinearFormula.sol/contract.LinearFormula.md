# LinearFormula
[Git Source](https://github.com/dustinstacy/bonding-curve/blob/7a2c4a7e41ef04642ab28f4be4017b9996da4af2/src/linear-curve/LinearFormula.sol)


## State Variables
### PRECISION
Precision for calculations.

*Solidity does not support floating point numbers, so we use fixed point math.*

*Precision also acts as the number 1 commonly used in curve calculations.*


```solidity
uint256 private constant PRECISION = 1e18;
```


## Functions
### calculatePurchaseReturn

Function to calculate the amount of continuous tokens to return based on reserve tokens received.


```solidity
function calculatePurchaseReturn(
    uint256 currentSupply,
    uint256 reserveBalance,
    uint256 initialReserve,
    uint256 reserveTokensReceived,
    uint256 protocolFeePercent
) public pure returns (uint256 purchaseReturn, uint256 fees);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentSupply`|`uint256`|The current supply of continuous tokens (in 1e18 format).|
|`reserveBalance`|`uint256`|The balance of reserve tokens (in wei).|
|`initialReserve`|`uint256`|The initial reserve balance (in wei).|
|`reserveTokensReceived`|`uint256`|The amount of reserve tokens received (in wei).|
|`protocolFeePercent`|`uint256`|The protocol fee percentage (in 1e18 format).|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`purchaseReturn`|`uint256`|The amount of continuous tokens to mint (in 1e18 format).|
|`fees`|`uint256`|The amount of protocol fees to send to the protocol fee destination (in wei).|


### calculateSaleReturn

Function to calculate the amount of reserve tokens to return based on continuous tokens sold.


```solidity
function calculateSaleReturn(
    uint256 currentSupply,
    uint256 reserveBalance,
    uint256 intialReserve,
    uint256 amount,
    uint256 protocolFeePercent
) public pure returns (uint256 saleReturn, uint256 fees);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentSupply`|`uint256`|The current supply of continuous tokens (in 1e18 format).|
|`reserveBalance`|`uint256`|The balance of reserve tokens (in wei).|
|`intialReserve`|`uint256`|The initial reserve balance (in wei).|
|`amount`|`uint256`|The amount of continuous tokens to sell (in 1e18 format).|
|`protocolFeePercent`|`uint256`|The protocol fee percentage (in 1e18 format).|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`saleReturn`|`uint256`|The amount of reserve tokens to return (in wei).|
|`fees`|`uint256`|The amount of protocol fees to send to the protocol fee destination (in wei).|


### calculateMintCost

Function to calculate the amount of reserve tokens required to mint a token.


```solidity
function calculateMintCost(
    uint256 currentSupply,
    uint256 reserveBalance,
    uint256 initialReserve,
    uint256 protocolFeePercent
) public pure returns (uint256 depositAmount, uint256 fees);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentSupply`|`uint256`|The current supply of continuous tokens (in 1e18 format).|
|`reserveBalance`|`uint256`|The balance of reserve tokens (in wei).|
|`initialReserve`|`uint256`|The initial reserve balance (in wei).|
|`protocolFeePercent`|`uint256`|The protocol fee percentage (in 1e18 format).|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositAmount`|`uint256`|The amount of reserve tokens required to mint a token (in wei).|
|`fees`|`uint256`||


### _totalCost

Function to calculate the total cost of tokens given the number of tokens.


```solidity
function _totalCost(uint256 n, uint256 initialReserve) internal pure returns (uint256);
```

