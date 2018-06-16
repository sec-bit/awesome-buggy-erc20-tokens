# pauseTransfer-anyone

## 问题描述
onlyFromWallet中的判断条件却写反了，使得除了walletAddress以外，所有账户都可以调用enableTokenTransfer和disableTokenTransfer函数。

## 示例代码
```js
// if Token transfer
modifier isTokenTransfer {
    // if token transfer is not allow
    if(!tokenTransfer) {
        require(unlockaddress[msg.sender]);
    }
    _;
}

modifier onlyFromWallet {
    require(msg.sender != walletAddress);
    _;
}

function enableTokenTransfer()
external
onlyFromWallet {
    tokenTransfer = true;
    TokenTransfer();
}

function disableTokenTransfer()
external
onlyFromWallet {
    tokenTransfer = false;
    TokenTransfer();
}
```