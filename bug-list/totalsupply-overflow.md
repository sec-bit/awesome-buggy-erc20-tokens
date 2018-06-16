# totalsupply-overflow

## 问题描述
totalsupply 为合约中代币的总量。 在问题合约代码中，当token总量发生变化时，对totalSupply做加减运算，并没有校验也没有使用safeMath，从而造成了totalSupply溢出的漏洞。

## 示例代码

```js
function mintToken(address target, uint256 mintedAmount) onlyOwner public {
    balanceOf[target] += mintedAmount;
    totalSupply += mintedAmount;
    Transfer(0, this, mintedAmount);
    Transfer(this, target, mintedAmount);
}
```