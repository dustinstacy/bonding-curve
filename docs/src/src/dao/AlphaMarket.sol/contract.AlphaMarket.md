# AlphaMarket
[Git Source](https://github.com/dustinstacy/bonding-curve/blob/7a2c4a7e41ef04642ab28f4be4017b9996da4af2/src/dao/AlphaMarket.sol)

**Inherits:**
Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl


## Functions
### constructor


```solidity
constructor(IVotes _token, TimelockController _timelock)
    Governor("AlphaMarket")
    GovernorSettings(7200, 50400, 0)
    GovernorVotes(_token)
    GovernorVotesQuorumFraction(4)
    GovernorTimelockControl(_timelock);
```

### votingDelay


```solidity
function votingDelay() public view override(Governor, GovernorSettings) returns (uint256);
```

### votingPeriod


```solidity
function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256);
```

### quorum


```solidity
function quorum(uint256 blockNumber) public view override(Governor, GovernorVotesQuorumFraction) returns (uint256);
```

### state


```solidity
function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState);
```

### proposalNeedsQueuing


```solidity
function proposalNeedsQueuing(uint256 proposalId)
    public
    view
    override(Governor, GovernorTimelockControl)
    returns (bool);
```

### proposalThreshold


```solidity
function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256);
```

### _queueOperations


```solidity
function _queueOperations(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
) internal override(Governor, GovernorTimelockControl) returns (uint48);
```

### _executeOperations


```solidity
function _executeOperations(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
) internal override(Governor, GovernorTimelockControl);
```

### _cancel


```solidity
function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
    internal
    override(Governor, GovernorTimelockControl)
    returns (uint256);
```

### _executor


```solidity
function _executor() internal view override(Governor, GovernorTimelockControl) returns (address);
```

