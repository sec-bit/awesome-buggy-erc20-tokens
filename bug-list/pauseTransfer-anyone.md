# pauseTransfer-anyone

## 问题描述
合约中存在一个变量isTokenTransfer，当该变量为true时，合约中所有的账户(被锁定的账户除外)才可以进行转账、授权他人转账和烧币等操作，但其在onlyFromWallet中的判断条件却写反了，也就是说，除了walletAddress以外，所有账户都可以调用enableTokenTransfer和disableTokenTransfer函数，开关Token的交易相关功能。

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