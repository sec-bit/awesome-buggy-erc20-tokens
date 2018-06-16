# batchTransfer-overflow

## 问题描述

batchTransfer()函数的功能为批量转账。调用者可以传入若干个地址和转账金额，经过一些强制检查交易，再依次对balances进行增减操作，以实现 Token 的转移。当传入值_value过大时，uint256 amount = uint256(cnt) * _value会发生溢出（overflow），导致amount变量无法正确等于cnt倍的_value，变得异常变小，从而使得后面的require对转账发起者的余额校验可正常通过。
这就导致可以转出超过余额的Token。

## 示例代码

```js
function batchTransfer(address[] _receivers, uint256 _value) public whenNotPaused returns (bool) {
    uint cnt = _receivers.length;
    uint256 amount = uint256(cnt) * _value;
    require(cnt > 0 && cnt <= 20);
    require(_value > 0 && balances[msg.sender] >= amount);

    balances[msg.sender] = balances[msg.sender].sub(amount);
    for (uint i = 0; i < cnt; i++) {
        balances[_receivers[i]] = balances[_receivers[i]].add(_value);
        Transfer(msg.sender, _receivers[i], _value);
    }
    return true;
 }
```