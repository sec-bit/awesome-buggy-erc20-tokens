# verify-reverse-in-transfer

## 问题描述

合约在对storage中的值做校验的时候，将校验逻辑写反，从而使得合约代码的逻辑判断错误。

有可能造成溢出或者任何人都能转出任何账户的余额

## 示例代码

示例代码1
```js
//Function for transer the coin from one address to another
function transferFrom(address from, address to, uint value) returns (bool success) {

    ...

    //checking for allowance
    if( allowed[from][msg.sender] >= value ) return false;

    ...

    return true;
}
```

示例代码2
```js
 function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        ...
        
        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            ...
            return true;
        } else { return false; }
    }
```