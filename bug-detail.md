# BUG detail

## 1.transfer-no-retrun

* 问题描述

根据ERC20 合约规范，其中 transfer()函数应返回一个bool值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现，transfer()函数没有返回值。
但若外部合约按照EIP20规范的ABI解析去调用 transfer()函数，在solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后，transfer()函数调用将发生revert。

* 示例代码
```js
function transfer(address _to, uint256 _value) {
    if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
    if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for 
    
    balanceOf[msg.sender] -= _value;                     // Subtract from the sender
    balanceOf[_to] += _value;                            // Add the same to the recipient
    Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
}
```

## 2.approve-no-return

* 问题描述

    根据ERC20 合约规范，其中 approve()函数应返回一个bool值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现，approve()函数没有返回值。
    但若外部合约按照EIP20规范的ABI解析去调用 approve()函数，在solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后，approve()函数调用将发生revert。

* 示例代码
    ```js
    function approve(address _spender, uint _value) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }
    ```

## 3.transferFrom-no-return

* 问题描述

    根据ERC20 合约规范，其中 transfer()函数应返回一个bool值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现，transfer()函数没有返回值。
    但若外部合约按照EIP20规范的ABI解析去调用 transfer()函数，在solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后，transfer()函数调用将发生revert。

* 示例代码

    ```js
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }
    ```

## 4.approveProxy-keccak256

* 问题描述
    keccak256() 和 ecrecover() 都是内嵌的函数，keccak256 可以用于计算公钥的签名，ecrecover 可以用来恢复签名公钥。传值正确的情况下，可以利用这两者函数来验证地址。
    ```js
        bytes32 hash = keccak256(_from,_spender,_value,nonce,name);
        if(_from != ecrecover(hash,_v,_r,_s)) revert();
    ```
    当ecrecover()的参数错误时候，返回0x0地址，如果 `_from` 也传入0x0地址，怎能通过校验。也就是说，任何人都可以获得 0x0地址的授权。

* 示例代码
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

## 5.batchTransfer-overflow

* 问题描述

    （**CVE-2018-10299**）
    batchTransfer()函数的功能为批量转账。调用者可以传入若干个地址和转账金额，经过一些强制检查交易，再依次对balances进行增减操作，以实现 Token 的转移。当传入值_value过大时，uint256 amount = uint256(cnt) * _value会发生溢出（overflow），导致amount变量无法正确等于cnt倍的_value，变得异常变小，从而使得后面的require对转账发起者的余额校验可正常通过。这就导致可以转出超过余额的Token。

* 示例代码

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

## 6.setowner-anyone

* 问题描述

    setOwner()函数的作用是修改owner，通常情况下该函数只有当前 owner 可以调用。 但问题代码中，这个函数任何人都可以调用，这就导致了任何人都可以修改合约的owner。


* 示例代码

    ```js
    function setOwner(address _owner) returns (bool success) {
        owner = _owner;
        return true;
    }
    ```

## 7.totalsupply-overflow

* 问题描述
    totalsupply 为合约中代币的总量。 在问题合约代码中，当token总量发生变化时，对totalSupply做加减运算，并没有校验也没有使用safeMath，从而造成了totalSupply溢出的漏洞。

* 示例代码

    ```js
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    ```

## 8.transferProxy-keccak256

* 问题描述
    keccak256() 和 ecrecover() 都是内嵌的函数，keccak256 可以用于计算公钥的签名，ecrecover 可以用来恢复签名公钥。传值正确的情况下，可以利用这两者函数来验证地址。
    ```js
        bytes32 hash = keccak256(_from,_spender,_value,nonce,name);
        if(_from != ecrecover(hash,_v,_r,_s)) revert();
    ```
    当ecrecover()的参数错误时候，返回0x0地址，如果 `_from` 也传入0x0地址，怎能通过校验。也就是说，任何人都可以将 0x0 地址的余额转出。

* 示例代码
    ```js
    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeMesh,
            uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){

            ...
            
            bytes32 h = keccak256(_from,_to,_value,_feeMesh,nonce,name);
            if(_from != ecrecover(h,_v,_r,_s)) revert();
            
            ...
            return true;
        }
    ```

## 9.verify-reverse-in-transferFrom

* 问题描述
    （**CVE-2018-10468**）
    转账时候对allownce值做校验的时候，将校验逻辑写反，从而使得合约代码的逻辑判断错误。
    有可能造成溢出或者任何人都能转出任何账户的余额

* 示例代码

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

## 10.pauseTransfer-anyone

* 问题描述
    onlyFromWallet中的判断条件却写反了，使得除了walletAddress以外，所有账户都可以调用enableTokenTransfer和disableTokenTransfer函数。

* 示例代码

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

## 11.verify-invalid-by-overflow

* 问题描述
    合约中在进行转账等操作时候，会对余额做校验。黑客可以通过转出一个极大的值来制造溢出，从而绕开校验。


* 示例代码
    ```js
        function transferProxy(address _from, address _to, uint256 _value, uint256 _feeMesh,
            uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){

            if(balances[_from] < _feeMesh + _value) revert();

            ...
            return true;
        }
    ```

## 12.owner-control-sell-price

* 问题描述
    (**CVE-2018-11811**)
    部分合约中，用户在以太和token之间进行兑换，兑换的价格由owner完全控制，owner可以通过构造一个很大的兑换值，使得计算兑换出的以太时候发生溢出，将原本较大的一个eth数额转换为较小的值，从而使得用户只能拿到很少量的以太。

* 示例代码
    ```js
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
    ```

## 13.owner-overweight-token

* 问题描述
    (**CVE-2018-11687**)
    owner账户在向其它账户转账时候，通过制造下溢，实现对自身账户余额的任意增加。

* 示例代码

    ```js
    function distributeBTR(address[] addresses) onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            balances[owner] -= 2000 * 10**8;
            balances[addresses[i]] += 2000 * 10**8;
            Transfer(owner, addresses[i], 2000 * 10**8);
        }
    }
    ```

## 14.owner-decrease-balance-by-mint

* 问题描述
    （**CVE-2018-11812**）
    有铸币权限的owner可以通过给某一账户增发数量极大的token，使得这个账户的余额溢出成为一个很小的数字，从而任意控制这个账户的余额。

* 示例代码

    ```js
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    ```

## 15.excess-allocation-by-overflow

* 问题描述
    （**CVE-2018-11810**）
    owner在给账户分配token时候，可以通过溢出绕开上限，从而给指定的地址分配更多的token

* 示例代码
    ```js
    function allocate(address _address, uint256 _amount, uint8 _type) public onlyOwner returns (bool success) {

        require(allocations[_address] == 0);

        if (_type == 0) { // advisor
            ...
        } else if (_type == 1) { // founder
            ...
        } else {
            require(holdersAllocatedAmount + _amount <= HOLDERS_AMOUNT + RESERVE_AMOUNT);
            holdersAllocatedAmount += _amount;
        }
        allocations[_address] = _amount;
        initialAllocations[_address] = _amount;

        balances[_address] += _amount;

        ...

        return true;
    }
    ```

## 16-excess-mint-token

* 问题描述
    （**CVE-2018-11809**）
    owner可以通过溢出来绕开合约中铸币最大值的设置，来发行任意多的币。

* 示例代码

    ```js
    function mint(address _holder, uint256 _value) external icoOnly {
    require(_holder != address(0));
    require(_value != 0);
    require(totalSupply + _value <= tokenLimit);

    balances[_holder] += _value;
    totalSupply += _value;
    Transfer(0x0, _holder, _value);
    }
    ```

## 17.excess-buy-token

* 问题描述
    （**CVE-2018-11809**）
    在用eth兑换token的时候，用户若拥有足够的eth，可以通过购买足够大量的token来制造溢出，从而绕过发币上限，以此来获得更多的token。

* 示例代码
    ```js
    function buyTokensICO() public payable onlyInState(State.ICORunning)
    {
        // min - 0.01 ETH
        require(msg.value >= ((1 ether / 1 wei) / 100));
        uint newTokens = msg.value * getPrice();

        require(totalSoldTokens + newTokens <= TOTAL_SOLD_TOKEN_SUPPLY_LIMIT);

        balances[msg.sender] += newTokens;
        supply+= newTokens;
        icoSoldTokens+= newTokens;
        totalSoldTokens+= newTokens;

        LogBuy(msg.sender, newTokens);
    }
    ```

