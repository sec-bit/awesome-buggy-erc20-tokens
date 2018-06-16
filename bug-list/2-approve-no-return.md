# approve-no-return

## 问题描述
根据ERC20 合约规范，其中 approve()函数应返回一个bool值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现，approve()函数没有返回值。
但若外部合约按照EIP20规范的ABI解析去调用 approve()函数，在solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后，approve()函数调用将发生revert。

## 示例代码
```js
    function approve(address _spender, uint _value) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }
```