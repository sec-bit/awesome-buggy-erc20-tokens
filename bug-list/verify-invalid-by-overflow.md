# verify-invalid-by-overflow

## 问题描述
合约中在进行转账等操作时候，会对余额做校验。黑客可以通过转出一个极大的值来制造溢出，从而绕开校验。


## 示例代码
```js
    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeMesh,
        uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){

        if(balances[_from] < _feeMesh + _value) revert();

        ...
        return true;
    }
```