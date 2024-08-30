# TimeLock
[Git Source](https://github.com/dustinstacy/bonding-curve/blob/7a2c4a7e41ef04642ab28f4be4017b9996da4af2/src/dao/TimeLock.sol)

**Inherits:**
TimelockController


## Functions
### constructor


```solidity
constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin)
    TimelockController(minDelay, proposers, executors, admin);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`minDelay`|`uint256`|Minimum delay for timelock|
|`proposers`|`address[]`|List of addresses that can propose a transaction|
|`executors`|`address[]`|List of addresses that can execute a transaction|
|`admin`|`address`|Address that can change the proposers, executors, and delay|


