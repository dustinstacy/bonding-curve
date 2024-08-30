# LinearBondingCurve
[Git Source](https://github.com/dustinstacy/bonding-curve/blob/7a2c4a7e41ef04642ab28f4be4017b9996da4af2/src/linear-curve/LinearBondingCurve.sol)

**Inherits:**
Initializable, OwnableUpgradeable, UUPSUpgradeable, [LinearFormula](/src/linear-curve/LinearFormula.sol/contract.LinearFormula.md)

**Author:**
Dustin Stacy

This contract implements a bonding curve that adjusts the price of tokens based on the total supply.
The price of tokens increases linearly with the supply.


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


### maxGasLimit
The maximum gas limit for transactions.

*This value should be set to prevent front-running attacks.*


```solidity
uint256 public maxGasLimit;
```


### PRECISION
Precision for calculations.

*Solidity does not support floating point numbers, so we use fixed point math.*

*Precision also acts as the number 1 commonly used in curve calculations.*


```solidity
uint256 private constant PRECISION = 1e18;
```


### BASIS_POINTS_PRECISION
Precision for basis points calculations.

*This is used to convert the protocol fee to a fraction.*


```solidity
uint256 private constant BASIS_POINTS_PRECISION = 1e4;
```


### MAX_BASIS_POINTS
*The maximum value for basis points.*


```solidity
uint256 private constant MAX_BASIS_POINTS = 1e5;
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
|`_maxGasLimit`|`uint256`|The maximum gas limit for transactions.|


### getPurchaseReturn

Function to get the amount of continuous tokens to return based on reserve tokens received.


```solidity
function getPurchaseReturn(uint256 currentSupply, uint256 reserveBalance, uint256 reserveTokensReceived)
    external
    view
    returns (uint256 purchaseReturn, uint256 fees);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentSupply`|`uint256`|The current supply of continuous tokens (in 1e18 format).|
|`reserveBalance`|`uint256`|The balance of reserve tokens (in wei).|
|`reserveTokensReceived`|`uint256`|The amount of reserve tokens received (in wei).|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`purchaseReturn`|`uint256`|The amount of continuous tokens to mint (in 1e18 format).|
|`fees`|`uint256`|The amount of protocol fees to send to the protocol fee destination (in wei). Gas Report     | min             | avg   | median | max   | # calls | | 4726            | 6813  | 4726   | 11161 | 5       ||


### getSaleReturn

Function to get the amount of reserve tokens to return based on continuous tokens sold.


```solidity
function getSaleReturn(uint256 currentSupply, uint256 reserveBalance, uint256 amount)
    public
    view
    returns (uint256 saleReturn, uint256 fees);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentSupply`|`uint256`|supply of tokens.|
|`reserveBalance`|`uint256`|The balance of reserve tokens (in wei).|
|`amount`|`uint256`|The amount of tokens to sell.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`saleReturn`|`uint256`|The amount of ether to return to the seller.|
|`fees`|`uint256`|The amount of protocol fees to send to the protocol fee destination. Gas Report     | min             | avg   | median | max   | # calls | | 6695            | 7345  | 7345   | 7995  | 2       ||


### getMintCost

Function to calculate the amount of reserve tokens required to mint a token.


```solidity
function getMintCost(uint256 currentSupply, uint256 reserveBalance)
    external
    view
    returns (uint256 depositAmount, uint256 fees);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentSupply`|`uint256`|The current supply of continuous tokens (in 1e18 format).|
|`reserveBalance`|`uint256`|The balance of reserve tokens (in wei).|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositAmount`|`uint256`|The amount of reserve tokens required to mint a token (in wei).|
|`fees`|`uint256`||


### getTokenPrice

Function to calculate the price of the token based on the current supply and reserve balance.


```solidity
function getTokenPrice(uint256 currentSupply, uint256 reserveBalance)
    external
    view
    returns (uint256 tokenPrice, uint256 fees);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentSupply`|`uint256`|The current supply of continuous tokens (in 1e18 format).|
|`reserveBalance`|`uint256`|The balance of reserve tokens (in wei).|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenPrice`|`uint256`|The price of the token (in wei).|
|`fees`|`uint256`||


### setProtocolFeeDestination


```solidity
function setProtocolFeeDestination(address _feeDestination) public onlyOwner;
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
function setInitialReserve(uint256 _initialReserve) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_initialReserve`|`uint256`|The balance of reserve tokens to initialize the bonding curve token with.|


### setMaxGasLimit


```solidity
function setMaxGasLimit(uint256 _maxGasLimit) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_maxGasLimit`|`uint256`|The maximum gas limit for transactions.|


### getPrecision


```solidity
function getPrecision() public pure returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The `PRECISION` constant.|


### getBasisPointsPrecision


```solidity
function getBasisPointsPrecision() public pure returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The `BASIS_POINTS_PRECISION` constant.|


### getMaxBasisPoints


```solidity
function getMaxBasisPoints() public pure returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The `MAX_BASIS_POINTS` constant.|


### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newImplementation`|`address`|The address of the new implementation contract.|


