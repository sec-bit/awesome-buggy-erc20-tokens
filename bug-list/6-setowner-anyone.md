# setowner-anyone

## 问题描述

setOwner()函数的作用是修改owner，通常情况下该函数只有当前 owner 可以调用。 但问题代码中，这个函数任何人都可以调用，这就导致了任何人都可以修改合约的owner。


## 示例代码

```js
function setOwner(address _owner) returns (bool success) {
    owner = _owner;
    return true;
}
```