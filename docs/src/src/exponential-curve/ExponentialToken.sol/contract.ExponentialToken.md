# ExponentialToken
[Git Source](https://github.com/dustinstacy/bonding-curve/blob/7a2c4a7e41ef04642ab28f4be4017b9996da4af2/src/exponential-curve/ExponentialToken.sol)

**Inherits:**
ERC20Burnable

**Author:**
Dustin Stacy

This contract implements a simple ERC20 token that can be bought and sold using an exponential bonding curve.


## State Variables
### i_bondingCurve
Instance of a Bonding Curve contract used to determine the price of tokens.


```solidity
ExponentialBondingCurve private immutable i_bondingCurve;
```


### reserveBalance
The total amount of Ether held in the contract.


```solidity
uint256 public reserveBalance;
```


### collectedFees
The total amount of fees collected by the contract.


```solidity
uint256 public collectedFees;
```


## Functions
### validGasPrice

*Modifier to check if the transaction gas price is below the maximum gas limit.*


```solidity
modifier validGasPrice();
```

### constructor


```solidity
constructor(string memory _name, string memory _symbol, address _bcAddress, address _host)
    payable
    ERC20(_name, _symbol);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_name`|`string`|The name of the token.|
|`_symbol`|`string`|The symbol of the token.|
|`_bcAddress`|`address`|The address of the ExponentialBondingCurve contract.|
|`_host`|`address`|The address of the host account.|


### mintTokens

Allows a user to mint tokens by sending Ether to the contract.


```solidity
function mintTokens() external payable validGasPrice;
```

### burnTokens

Allows a user to burn tokens and receive ether from the contract.


```solidity
function burnTokens(uint256 amount, address sender) external validGasPrice;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of tokens to burn.|
|`sender`|`address`|The address of the sender.|


### getBondingCurveProxyAddress

Do we want to enforce this to prevent bricking the contract?

Returns the address of the ExponentialBondingCurve proxy contract.


```solidity
function getBondingCurveProxyAddress() external view returns (address);
```

## Events
### TokensPurchased
Event to log token purchases.


```solidity
event TokensPurchased(address indexed buyer, uint256 amountSpent, uint256 fees, uint256 tokensMinted);
```

### TokensSold
Event to log token sales.


```solidity
event TokensSold(address indexed seller, uint256 amountReceived, uint256 fees, uint256 tokensBurnt);
```

## Errors
### ExponentialToken__IncorrectAmountOfEtherSent
*Emitted when the buyer does not send the correct amount of Ether to mint the initial token.*


```solidity
error ExponentialToken__IncorrectAmountOfEtherSent();
```

### ExponentialToken__AmountMustBeMoreThanZero
*Emitted when attempting to perform an action with an amount that must be more than zero.*


```solidity
error ExponentialToken__AmountMustBeMoreThanZero();
```

### ExponentialToken__InsufficientFundingForTransaction
*Emitted if the buyer does not send enough Ether to purchase the tokens.*


```solidity
error ExponentialToken__InsufficientFundingForTransaction();
```

### ExponentialToken__BurnAmountExceedsBalance
*Emitted when attempting to burn an amount that exceeds the sender's balance.*


```solidity
error ExponentialToken__BurnAmountExceedsBalance();
```

### ExponentialToken__SupplyCannotBeReducedBelowOne
*Emitted when attempting to reduce the total supply below one.*


```solidity
error ExponentialToken__SupplyCannotBeReducedBelowOne();
```

