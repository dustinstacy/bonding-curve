# AlphaMarketToken
[Git Source](https://github.com/dustinstacy/bonding-curve/blob/7a2c4a7e41ef04642ab28f4be4017b9996da4af2/src/dao/AlphaMarketToken.sol)

**Inherits:**
[ERC20](/src/references/tokens/ERC20.sol/abstract.ERC20.md), ERC20Burnable, [Ownable](/src/references/FriendTechCurve.sol/abstract.Ownable.md), ERC20Permit, ERC20Votes


## Functions
### constructor


```solidity
constructor(address initialOwner)
    ERC20("AlphaMarketToken", "ALF")
    Ownable(initialOwner)
    ERC20Permit("AlphaMarketToken");
```

### mint


```solidity
function mint(address to, uint256 amount) public onlyOwner;
```

### _update


```solidity
function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes);
```

### nonces


```solidity
function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256);
```

