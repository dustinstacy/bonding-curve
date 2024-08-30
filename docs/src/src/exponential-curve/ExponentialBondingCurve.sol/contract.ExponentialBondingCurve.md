# ExponentialBondingCurve
[Git Source](https://github.com/dustinstacy/bonding-curve/blob/7a2c4a7e41ef04642ab28f4be4017b9996da4af2/src/exponential-curve/ExponentialBondingCurve.sol)

**Inherits:**
Initializable, OwnableUpgradeable, UUPSUpgradeable, [BancorFormula](/src/exponential-curve/BancorFormula.sol/contract.BancorFormula.md)

**Author:**
Dustin Stacy

This contract implements the Bancor bonding curve.
The curve is defined by a reserveRatio, which determines the steepness and bend of the curve.


## State Variables
### protocolFeeDestination
The address to send protocol fees to.


```solidity
address public protocolFeeDestination;
```


### protocolFeePercent
The percentage of the transaction value to send to the protocol fee destination.


```solidity
uint256 public protocolFeePercent;
```


### feeSharePercent
*The percentage of the collected fees to share with the token contract.*


```solidity
uint256 public feeSharePercent;
```


### initialReserve
The balance of reserve tokens to initialize the bonding curve token with.


```solidity
uint256 public initialReserve;
```


### reserveRatio
*Value to represent the reserve ratio for use in calculations (in ppm).*


```solidity
uint32 public reserveRatio;
```


### maxGasLimit
The maximum gas limit for transactions.

*This value should be set to prevent front-running attacks.*


```solidity
uint256 public maxGasLimit;
```


### PRECISION
*Solidity does not support floating point numbers, so we use fixed point math.*

*Precision also acts as the number 1 commonly used in curve calculations.*


```solidity
uint256 private constant PRECISION = 1e18;
```


### BASIS_POINTS_PRECISION
*Precision for basis points calculations.*

*This is used to convert the protocol fee to a fraction.*


```solidity
uint256 private constant BASIS_POINTS_PRECISION = 1e4;
```


### MAX_BASIS_POINTS
*The maximum value for basis points.*


```solidity
uint256 private constant MAX_BASIS_POINTS = 1e5;
```


### MAX_RESERVE_RATIO
*The maximum value for the reserve ratio.*


```solidity
uint32 private constant MAX_RESERVE_RATIO = 1e7;
```


## Functions
### constructor

*Disables the default initializer function.*


```solidity
constructor();
```

### initialize

Initializes the bonding curve with the given parameters.


```solidity
function initialize(
    address _owner,
    address _protocolFeeDestination,
    uint256 _protocolFeePercent,
    uint256 _feeSharePercent,
    uint256 _initialReserve,
    uint32 _reserveRatio,
    uint256 _maxGasLimit
) public initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|The owner of the contract.|
|`_protocolFeeDestination`|`address`|The address to send protocol fees to.|
|`_protocolFeePercent`|`uint256`|The protocol fee percentage represented in basis points.|
|`_feeSharePercent`|`uint256`|The collected fee share percentage represented in basis points.|
|`_initialReserve`|`uint256`|The balance of reserve tokens to initialize the bonding curve token with.|
|`_reserveRatio`|`uint32`|The reserve ratio in ppm.|
|`_maxGasLimit`|`uint256`|The maximum gas limit for transactions.|


### getPurchaseReturn

Function to calculate the amount of continuous tokens to return based on reserve tokens received.


```solidity
function getPurchaseReturn(uint256 currentSupply, uint256 reserveTokenBalance, uint256 reserveTokensReceived)
    public
    view
    returns (uint256 purchaseReturn, uint256 fees);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentSupply`|`uint256`|The current supply of continuous tokens (in 1e18 format).|
|`reserveTokenBalance`|`uint256`|The balance of reserve tokens (in wei).|
|`reserveTokensReceived`|`uint256`|The amount of reserve tokens received (in wei).|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`purchaseReturn`|`uint256`|The amount of continuous tokens to mint (in 1e18 format).|
|`fees`|`uint256`|The amount of protocol fees to send to the protocol fee destination (in wei). Gas Report     | min             | avg   | median | max   | # calls | | 18854           | 18979 | 18979  | 19105 | 2       ||


### getSaleReturn

Calculates the amount of ether that can be returned for the given amount of tokens.


```solidity
function getSaleReturn(uint256 currentSupply, uint256 reserveTokenBalance, uint256 tokensToBurn)
    public
    view
    returns (uint256 saleValue, uint256 fees);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentSupply`|`uint256`|The current supply of continuous tokens (in 1e18 format).|
|`reserveTokenBalance`|`uint256`|The balance of reserve tokens (in wei).|
|`tokensToBurn`|`uint256`|The amount of continuous tokens to burn (in 1e18 format).|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`saleValue`|`uint256`|The amount of ether to return (in wei).|
|`fees`|`uint256`|The amount of protocol fees to send to the protocol fee destination (in wei). Gas Report     | min             | avg   | median | max   | # calls | | 18565           | 18690 | 18690  | 18816 | 2       ||


### getApproxMintCost

Function to calculate the amount of reserve tokens needed to mint a continuous token.

*This function is very gas intensive and should be used with caution.
Gas Report     | min             | avg    | median | max     | # calls |
| 690082          | 867621 | 846733 | 1066050 | 3       |*


```solidity
function getApproxMintCost(uint256 currentSupply, uint256 reserveTokenBalance)
    external
    view
    returns (uint256 depositAmount, uint256 fees);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentSupply`|`uint256`|The current supply of continuous tokens (in 1e18 format).|
|`reserveTokenBalance`|`uint256`|The balance of reserve tokens (in wei).|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositAmount`|`uint256`|The amount of reserve tokens needed to mint a continuous token (in wei).|
|`fees`|`uint256`||


### getTokenPrice

Function to calculate the current price of the continuous token.


```solidity
function getTokenPrice(uint256 currentSupply, uint256 reserveTokenBalance)
    external
    view
    returns (uint256 tokenPrice, uint256 fees);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentSupply`|`uint256`|The current supply of continuous tokens (in 1e18 format).|
|`reserveTokenBalance`|`uint256`|The balance of reserve tokens (in wei).|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenPrice`|`uint256`|The current price of the continuous token (in wei).|
|`fees`|`uint256`|The amount of protocol fees to send to the protocol fee destination (in wei).|


### setProtocolFeeDestination


```solidity
function setProtocolFeeDestination(address _feeDestination) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_feeDestination`|`address`|The address to send protocol fees to.|


### setProtocolFeePercent


```solidity
function setProtocolFeePercent(uint256 _basisPoints) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_basisPoints`|`uint256`|The percentage of the transaction to send to the protocol fee destination represented in basis points.|


### setFeeSharePercent


```solidity
function setFeeSharePercent(uint256 _basisPoints) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_basisPoints`|`uint256`|The collected fee share percentage for selling tokens represented in basis points.|


### setInitialReserve


```solidity
function setInitialReserve(uint256 _initialReserve) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_initialReserve`|`uint256`|The balance of reserve tokens to initialize the bonding curve token with.|


### setReserveRatio


```solidity
function setReserveRatio(uint32 _reserveRatio) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_reserveRatio`|`uint32`|The reserve ratio used to define the steepness of the bonding curve in ppm.|


### setMaxGasLimit


```solidity
function setMaxGasLimit(uint256 _maxGasLimit) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_maxGasLimit`|`uint256`|The maximum gas limit for transactions.|


### getPrecision


```solidity
function getPrecision() external pure returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The `PRECISION` constant.|


### getBasisPointsPrecision


```solidity
function getBasisPointsPrecision() external pure returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The `BASIS_POINTS_PRECISION` constant.|


### getMaxBasisPoints


```solidity
function getMaxBasisPoints() external pure returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The `MAX_BASIS_POINTS` constant.|


### getMaxReserveRatio


```solidity
function getMaxReserveRatio() external pure returns (uint32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|The `MAX_RESERVE_RATIO` constant.|


### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newImplementation`|`address`|The address of the new implementation contract.|


