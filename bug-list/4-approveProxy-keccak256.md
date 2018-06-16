# approveProxy-keccak256

## 问题描述
keccak256() 和 ecrecover() 都是内嵌的函数，keccak256 可以用于计算公钥的签名，ecrecover 可以用来恢复签名公钥。传值正确的情况下，可以利用这两者函数来验证地址。
```js
    bytes32 hash = keccak256(_from,_spender,_value,nonce,name);
    if(_from != ecrecover(hash,_v,_r,_s)) revert();
```
当ecrecover()的参数错误时候，返回0x0地址，如果 `_from` 也传入0x0地址，怎能通过校验。也就是说，任何人都可以获得 0x0地址的授权。

## 示例代码
```js
function approveProxy(address _from, address _spender, uint256 _value,
                       uint8 _v,bytes32 _r, bytes32 _s) public returns (bool success) {

    uint256 nonce = nonces[_from];
    bytes32 hash = keccak256(_from,_spender,_value,nonce,name);
    if(_from != ecrecover(hash,_v,_r,_s)) revert();
    allowed[_from][_spender] = _value;
    Approval(_from, _spender, _value);
    nonces[_from] = nonce + 1;
    return true;
}
```