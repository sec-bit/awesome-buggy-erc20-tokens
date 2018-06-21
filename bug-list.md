# 常见安全漏洞描述

## A. 漏洞问题列表

### A1. batchTransfer-overflow

* 问题描述

    batchTransfer()函数的功能为批量转账。调用者可以传入若干个转账地址和转账金额，经过一些强制检查交易，再依次对balances进行增减操作，以实现 Token 的转移。当传入值_value过大时，uint256 amount = uint256(cnt) * _value会发生溢出（overflow），导致amount变量不等于cnt倍的_value，而是变成一个很小的值，从而使得后面的require对转账发起者的余额校验能够正常通过，继而可以转出超过余额的Token。([CVE-2018-10299](https://nvd.nist.gov/vuln/detail/CVE-2018-10299))

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
* 问题合约列表

    * BeautyChain (BEC)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/batchTransfer-overflow_o.csv)

### A2. totalsupply-overflow

* 问题描述

    totalsupply 通常为合约中代币的总量。 在问题合约代码中，当 token 总量发生变化时，对 totalSupply 做加减运算，并没有校验也没有使用 safeMath，从而导致了totalSupply 发生溢出。

* 示例代码

    ```js
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    ```

* 问题合约列表

    * FuturXE (FXE)
    * Amber Token (AMB)
    * Insights Network (INSTAR)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/totalsupply-overflow_o.csv) 

### A3. verify-invalid-by-overflow

* 问题描述

    合约中在进行转账等操作时候，会对余额做校验。黑客可以通过转出一个极大的值来制造溢出，继而绕开校验。

* 示例代码

    ```js
    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeMesh,
                            uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){

        if(balances[_from] < _feeMesh + _value) revert();

        ...
        return true;
    }
    ```

* 问题合约列表

    * SmartMesh Token (SMT)     
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/verify-invalid-by-overflow_o.csv)

### A4. owner-control-sell-price-for-overflow

* 问题描述

    部分合约中，用户在以太和token之间进行兑换，兑换的价格由owner完全控制，owner可以通过构造一个很大的兑换值，使得计算兑换出的以太时候发生溢出，将原本较大的一个eth数额转换为较小的值，从而使得用户只能拿到很少量的以太。([CVE-2018-11811](https://nvd.nist.gov/vuln/detail/CVE-2018-11811))

* 示例代码

    ```js
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
    ```

* 问题合约列表   
    
    * Internet Node Token (INT)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/owner-control-sell-price-for-overflow_o.csv)

### A5. owner-overweight-token-by-overflow

* 问题描述

    owner账户在向其它账户转账时候，通过制造下溢，实现对自身账户余额的任意增加。([CVE-2018-11687](https://nvd.nist.gov/vuln/detail/CVE-2018-11687))

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

* 问题合约列表
    * Bitcoin Red (BTCR)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/owner-overweight-token-by-overflow_o.csv)

### A6. owner-decrease-balance-by-mint-by-overflow

* 问题描述

    有铸币权限的owner可以通过给某一账户增发数量极大的token，使得这个账户的余额溢出为一个很小的数字，从而任意控制这个账户的余额。([CVE-2018-11812](https://nvd.nist.gov/vuln/detail/CVE-2018-11812))

* 示例代码

    ```js
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    ```

* 问题合约列表
    * SwftCoin (SWFTC)
    * Pylon Token (PYLNT)
    * Internet Node Token (INT)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/owner-decrease-balance-by-mint-by-overflow_o.csv)

### A7. excess-allocation-by-overflow

* 问题描述

    owner在给账户分配token时候，可以通过溢出绕开上限，从而给指定的地址分配更多的token。([CVE-2018-11810](https://nvd.nist.gov/vuln/detail/CVE-2018-11810))

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

* 问题合约列表
    * LGO Token (LGO)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/excess-allocation-by-overflow_o.csv)

### A8. excess-mint-token-by-overflow

* 问题描述

    owner可以通过传入一个极大的值来制造溢出来，进而绕开合约中铸币最大值的设置，来发行任意多的币。([CVE-2018-11809](https://nvd.nist.gov/vuln/detail/CVE-2018-11809))

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

* 问题合约列表
    * Playkey Token (PKT)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/excess-mint-token-by-overflow_o.csv)

### A9. excess-buy-token-by-overflow

* 问题描述

    在用eth兑换token的时候，用户若拥有足够的eth，可以通过购买足够大量的token来制造溢出，从而绕过发币上限，以此来获得更多的token。([CVE-2018-11809](https://nvd.nist.gov/vuln/detail/CVE-2018-11809))

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

* 问题合约列表
    * EthLend Token (LEND) 
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/excess-buy-token-by-overflow_o.csv)

### A10. verify-reverse-in-transferFrom

- 问题描述

  在transferFrom()函数中，当对allownce值做校验的时，误将校验逻辑写反，从而使得合约代码的逻辑判断错误。有可能造成溢出或者任何人都能转出任何账户的余额。([CVE-2018-10468](https://nvd.nist.gov/vuln/detail/CVE-2018-10468))

- 示例代码

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

* 问题合约列表
    * FuturXE (FXE)
    * Useless Ethereum Token (UET)
    * Soarcoin (Soar)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/verify-reverse-in-transferFrom_o.csv)

### A11. pauseTransfer-anyone

- 问题描述

  onlyFromWallet中的判断条件却写反了，使得除了walletAddress以外，所有账户都可以调用enableTokenTransfer 和 disableTokenTransfer 函数。

- 示例代码

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

* 问题合约列表
    * icon (ICX)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/pauseTransfer-anyone_o.csv)

### A12. setowner-anyone

- 问题描述

  setOwner()函数的作用是修改owner，通常情况下该函数只有当前 owner 可以调用。 但问题代码中，任何人都可以调用setOwner()函数，这就导致了任何人都可以修改合约的owner。

- 示例代码

  ```js
  function setOwner(address _owner) returns (bool success) {
      owner = _owner;
      return true;
  }
  ```

* 问题合约列表
    * Aurora DAO (AURA)
    * idex-membership
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/setowner-anyone_o.csv)

### A13. centralAccount-transfer-anyone

* 问题描述

    onlycentralAccount账户可以任意转出他人账户上的余额。([CVE-2018-1000203](https://nvd.nist.gov/vuln/detail/CVE-2018-1000203))

* 示例代码

    ```js
    function zero_fee_transaction(
    address _from,
    address _to,
    uint256 _amount
    ) onlycentralAccount returns(bool success) {
        if (balances[_from] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    ```

* 问题合约列表
    * Soarcoin (Soar)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/centralAccount-transfer-anyone_o.csv)

### A14. transferProxy-keccak256

- 问题描述

  keccak256() 和 ecrecover() 都是内嵌的函数，keccak256 可以用于计算公钥的签名，ecrecover 可以用来恢复签名公钥。传值正确的情况下，可以利用这两者函数来验证地址。

  ```js
  bytes32 hash = keccak256(_from,_spender,_value,nonce,name);
  if(_from != ecrecover(hash,_v,_r,_s)) revert();
  ```

  当ecrecover()的参数错误时候，返回0x0地址，如果 `_from` 也传入0x0地址，就能通过校验。也就是说，任何人都可以将 0x0 地址的余额转出。

- 示例代码

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
* 问题合约列表
    * SmartMesh Token (SMT)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/transferProxy-keccak256_o.csv)

### A15. approveProxy-keccak256

- 问题描述

  keccak256() 和 ecrecover() 都是内嵌的函数，keccak256 可以用于计算公钥的签名，ecrecover 可以用来恢复签名公钥。传值正确的情况下，可以利用这两者函数来验证地址。

  ```js
  bytes32 hash = keccak256(_from,_spender,_value,nonce,name);
  if(_from != ecrecover(hash,_v,_r,_s)) revert();
  ```

  当ecrecover()的参数错误时候，返回0x0地址，如果 `_from` 也传入0x0地址，就能通过校验。也就是说，任何人都可以获得 0x0地址的授权。

- 示例代码

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
    
* 问题合约列表
    * SmartMesh Token (SMT)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/approveProxy-keccak256_o.csv)


## B.不兼容问题列表

### B1. transfer-no-return

- 问题描述

  根据ERC20 合约规范，其中 transfer()函数应返回一个bool值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现，transfer()函数没有返回值。
  但若外部合约按照EIP20规范的ABI解析去调用 transfer()函数，在solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后，transfer()函数调用将发生revert。

- 示例代码

  ```js
  function transfer(address _to, uint256 _value) {
      if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
      if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
      balanceOf[msg.sender] -= _value;                     // Subtract from the sender
      balanceOf[_to] += _value;                            // Add the same to the recipient
      Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
  }
  ```

* 问题合约列表
    * IOT on Chain (ITC)
    * BNB (BNB)
    * loopring (LRC)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/transfer-no-return_o.csv)

### B2. approve-no-return

- 问题描述

  根据ERC20 合约规范，其中 approve()函数应返回一个bool值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现，approve()函数没有返回值。
  但若外部合约按照EIP20规范的ABI解析去调用 approve()函数，在solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后，approve()函数调用将发生revert。

- 示例代码

  ```js
  function approve(address _spender, uint _value) {
      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
  }
  ```
  [问题合约列表](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/approve-no-return_o.csv)

### B3. transferFrom-no-return

- 问题描述

  根据ERC20 合约规范，其中 transferFrom() 函数应返回一个bool值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现，transferFrom() 函数没有返回值。
  但若外部合约按照EIP20规范的ABI解析去调用 transferFrom() 函数，在solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后，transferFrom() 函数调用将发生revert。

- 示例代码

  ```js
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
      var _allowance = allowed[_from][msg.sender];
      balances[_to] = balances[_to].add(_value);
      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = _allowance.sub(_value);
      Transfer(_from, _to, _value);
  }
  ```

* 问题合约列表
    * CUBE (AUTO)
    * loopring (LRC)
    * Paymon Token (PMNT)
    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/transferfrom-no-return_o.csv)

## reference

[1] https://nvd.nist.gov/vuln/detail/CVE-2018-10299 CVE-2018-10299

[2] https://nvd.nist.gov/vuln/detail/CVE-2018-10468  CVE-2018-10468

[3] https://nvd.nist.gov/vuln/detail/CVE-2018-1000203 CVE-2018-1000203

[4] https://blog.csdn.net/Secbit/article/details/80045167
SECBIT: 美链(BEC)合约安全事件分析全景,Apr 23, 2018.

[5] https://www.secrss.com/articles/3289 ERC20智能合约整数溢出系列漏洞披露,June 12, 2018.

[6] https://peckshield.com/2018/04/25/proxyOverflow/ New proxyOverflow Bug in Multiple ERC20 Smart Contracts (CVE-2018-10376),Apr 25, 2018.

[7] https://medium.com/coinmonks/uselessethereumtoken-uet-erc20-token-allows-attackers-to-steal-all-victims-balances-543d42ac808e UselessEthereumToken(UET), ERC20 token, allows attackers to steal all victim’s balances (CVE-2018–10468),May 3, 2018.

[8] https://mp.weixin.qq.com/s/hANqFGGS1ZwjdvFJFeHfoQ ERC20 Token合约F_E惊现毁灭级漏洞，账户余额可以随意转出 ,June 6, 2018.

[9] https://mp.weixin.qq.com/s/HuJEQsst534vjK3yb7RcAQ ICX Token交易控制Bug深度分析, June 16, 2018.

[10] https://peckshield.com/2018/05/03/ownerAnyone/ New ownerAnyone Bug Allows For Anyone to ''Own'' Certain ERC20-Based Smart Contracts (CVE-2018-10705),May 3, 2018.

[11] https://mp.weixin.qq.com/s/1MB-t_yZYsJDTPRazD1zAA 数千份以太坊 Token 合约不兼容问题浮出水面，恐严重影响DAPP生态,June 8,2018.