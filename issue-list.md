# Token 合约已揭露安全风险问题汇总

[![Join the chat at https://gitter.im/sec-bit/Lobby](https://badges.gitter.im/sec-bit/Lobby.svg)](https://gitter.im/sec-bit/Lobby)



在以太坊平台已部署的数以万计份合约中，Token合约占据了半壁江山，这些Token合约承载的价值更是不可估量。然而由于诸多因素的限制，智能合约的开发还存在很多的不足之处，接二连三爆出的安全事件就是最好的印证。

本文收录了token合约中目前已披露的安全风险问题，旨在帮助大家快速了解这些安全风险，提高安全意识，避免重复踩坑，杜绝不必要的损失。同时也建议大家在合约开发过程中参考安全标准的开发指导说明和规范源码，如「[以太坊智能合约 —— 最佳安全开发指南](https://github.com/ConsenSys/smart-contract-best-practices)」。

### 最近更新

* 2018-06-23，添加快速导航
* 2018-06-22，新增问题分类：no-decimals，no-name，no-symbol
* 2018-06-22，新增问题分类：constructor-case-insentive


## 问题分类

本文共收录了22种问题，大致分为三大类：

* A类问题：代码实现漏洞，涵盖了合约代码功能实现和逻辑实现上的漏洞，如overflow。
* B类问题：不兼容问题 ，涵盖了因版本不兼容或者外部合约调用时的不兼容导致问题，如ERC20接口无返回值。
* C类问题：权限管理问题，涵盖了所有因管理权限设置不当而引发的问题，如任何人都可以修改owner。 

#### 快速导航

- [A. 代码实现漏洞问题列表](#a-代码实现漏洞问题列表)
  - [A1. batchTransfer-overflow](#a1-batchtransfer-overflow)
  - [A2. totalsupply-overflow](#a2-totalsupply-overflow)
  - [A3. verify-invalid-by-overflow](#a3-verify-invalid-by-overflow)
  - [A4. owner-control-sell-price-for-overflow](#a4-owner-control-sell-price-for-overflow)
  - [A5. owner-overweight-token-by-overflow](#a5-owner-overweight-token-by-overflow)
  - [A6. owner-decrease-balance-by-mint-by-overflow](#a6-owner-decrease-balance-by-mint-by-overflow)
  - [A7. excess-allocation-by-overflow](#a7-excess-allocation-by-overflow)
  - [A8. excess-mint-token-by-overflow](#a8-excess-mint-token-by-overflow)
  - [A9. excess-buy-token-by-overflow](#a9-excess-buy-token-by-overflow)
  - [A10. verify-reverse-in-transferFrom](#a10-verify-reverse-in-transferfrom)
  - [A11. pauseTransfer-anyone](#a11-pausetransfer-anyone)
  - [A12. transferProxy-keccak256](#a12-transferproxy-keccak256)
  - [A13. approveProxy-keccak256](#a13-approveproxy-keccak256)
  - [A14. constructor-case-insentive](#a14-constructor-case-insentive)
- [B.不兼容问题列表](#b不兼容问题列表)
  - [B1. transfer-no-return](#b1-transfer-no-return)
  - [B2. approve-no-return](#b2-approve-no-return)
  - [B3. transferFrom-no-return](#b3-transferfrom-no-return)
  - [B4. no-decimals](#b4-no-decimals)
  - [B5. no-name](#b5-no-name)
  - [B6. no-symbol](#b6-no-symbol)
- [C. 权限管理问题列表](#c-权限管理问题列表)
  - [C1. setowner-anyone](#c1-setowner-anyone)
  - [C2. centralAccount-transfer-anyone](#c2-centralaccount-transfer-anyone)

如有遗漏和误报，欢迎指正。
对于后续披露的Token合约安全问题，本文也将持续更新...


## A. 代码实现漏洞问题列表

### A1. batchTransfer-overflow

* 问题描述

    batchTransfer()函数的功能是批量转账。调用者可以传入若干个转账地址和转账金额，函数首先执行了一系列的检查，再依次对balances进行增减操作，以实现 Token 的转移。但是当传入值_value过大时，`uint256 amount = uint256(cnt) * _value` 会发生溢出（overflow），导致amount变量不等于cnt倍的 _value，而是变成一个很小的值，从而通过`require( _value > 0 && balances[msg.sender] >= amount)` 中对转账发起者的余额校验，继而实际转出超过 `balances[msg.sender]` 的Token。([CVE-2018-10299](https://nvd.nist.gov/vuln/detail/CVE-2018-10299))

* 错误的代码实现

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

* 推荐的代码实现

    使用诸如safeMath的安全运算方式来运算。

    ```js
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function batchTransfer(address[] _receivers, uint256 _value) public whenNotPaused returns (bool) {
        uint cnt = _receivers.length;
        uint256 amount = mul(uint256(cnt), _value);
       	
        ...
        return true;
    }
    ```

* 问题合约列表

    * BeautyChain (BEC)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/batchTransfer-overflow_o.csv)

* 相关链接

    * [SECBIT: 美链(BEC)合约安全事件分析全景](https://blog.csdn.net/Secbit/article/details/80045167)

### A2. totalsupply-overflow

* 问题描述

    totalsupply 通常为合约中代币的总量。 在问题合约代码中，当 token 总量发生变化时，对 totalSupply 做加减运算，并没有校验也没有使用 safeMath，从而是的totalSupply 有可能发生溢出。

* 错误的代码实现 

    ```js
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    ```

* 推荐的代码实现

    使用诸如safeMath的安全运算方式来运算。

    ```js
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] =add(balanceOf[target], mintedAmount);
        totalSupply = add(totalSupply, mintedAmount);
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

* 错误的代码实现

    ```js
    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeMesh,
                            uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){
    
        if(balances[_from] < _feeMesh + _value) revert();
    
        ...
        return true;
    }
    ```

* 推荐的代码实现

    使用诸如safeMath的安全运算方式来运算。

    ```js
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeMesh,
                            uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){
    
        if(balances[_from] < add(_feeMesh, _value)) revert();
    
        ...
        return true;
    }
    ```

* 问题合约列表

    * SmartMesh Token (SMT)  

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/verify-invalid-by-overflow_o.csv)

### A4. owner-control-sell-price-for-overflow

* 问题描述

    部分合约中，用户在以太和token之间进行兑换，兑换的价格由owner完全控制，若owner想要作恶，可以通过构造一个很大的兑换值，使得计算要兑换出的以太时发生溢出，将原本较大的一个eth数额变为较小的值，因而使得用户只能拿到很少量的以太。(CVE-2018-11811)

* 错误的代码实现

    ```js
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
    ```

* 推荐的代码实现

    使用诸如safeMath的安全运算方式来运算。

    ```js
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function sell(uint256 amount) public {
        require(this.balance >= mul(amount, sellPrice));      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
    ```

* 问题合约列表   

    * Internet Node Token (INT)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/owner-control-sell-price-for-overflow_o.csv)

* 相关链接

    * [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A5. owner-overweight-token-by-overflow

* 问题描述

    owner账户在向其它账户转账时候，通过转出多于账户余额的Token数量，来给 `balances[owner]` 制造下溢，实现对自身账户余额的任意增加。(CVE-2018-11687)

* 错误的代码实现

    ```js
    function distributeBTR(address[] addresses) onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            balances[owner] -= 2000 * 10**8;
            balances[addresses[i]] += 2000 * 10**8;
            Transfer(owner, addresses[i], 2000 * 10**8);
        }
    }
    ```

* 推荐的代码实现

    使用诸如safeMath的安全运算方式来运算。

    ```js
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function distributeBTR(address[] addresses) onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            balances[owner] = sub(balances[owner],2000 * 10**8);
            balances[addresses[i]] = add(balances[addresses[i]],2000 * 10**8);
            Transfer(owner, addresses[i], 2000 * 10**8);
        }
    }
    ```

* 问题合约列表

    * Bitcoin Red (BTCR)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/owner-overweight-token-by-overflow_o.csv)

* 相关链接

    - [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A6. owner-decrease-balance-by-mint-by-overflow

* 问题描述

    有铸币权限的owner可以通过给某一账户增发数量极大的token，使得这个账户的余额溢出为一个很小的数字，从而任意控制这个账户的余额。(CVE-2018-11812)

* 错误的代码实现

    ```js
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    ```

* 推荐的代码实现

    使用诸如safeMath的安全运算方式来运算。

    ```js
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] = add(balanceOf[target],mintedAmount);
        totalSupply = add(totalSupply,mintedAmount);
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    ```

* 问题合约列表

    * SwftCoin (SWFTC)

    * Pylon Token (PYLNT)

    * Internet Node Token (INT)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/owner-decrease-balance-by-mint-by-overflow_o.csv)

* 相关链接

    - [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A7. excess-allocation-by-overflow

* 问题描述

    owner在给账户分配token时候，可以通过溢出绕开上限，从而给指定的地址分配更多的token。(CVE-2018-11810)

* 错误的代码实现

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

* 推荐的代码实现

    使用诸如safeMath的安全运算方式来运算。

    ```js
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function allocate(address _address, uint256 _amount, uint8 _type) public onlyOwner returns (bool success) {
    
        require(allocations[_address] == 0);
        if (_type == 0) { // advisor
            ...
        } else if (_type == 1) { // founder
            ...
        } else {
            require(holdersAllocatedAmount + _amount <= HOLDERS_AMOUNT + RESERVE_AMOUNT);
            holdersAllocatedAmount = add(holdersAllocatedAmount,_amount);
        }
        allocations[_address] = _amount;
        initialAllocations[_address] = _amount;
    
        balances[_address] = add(balances[_address],_amount);
    
        ...
    
        return true;
    }
    ```

* 问题合约列表
    * LGO Token (LGO)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/excess-allocation-by-overflow_o.csv)

* 相关链接

    - [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A8. excess-mint-token-by-overflow

* 问题描述

    owner可以通过传入一个极大的值来制造溢出来，进而绕开合约中铸币最大值的设置，来发行任意多的币。(CVE-2018-11809)

* 错误的代码实现

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

* 推荐的代码实现

    使用诸如safeMath的安全运算方式来运算。

    ```js
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function mint(address _holder, uint256 _value) external icoOnly {
        require(_holder != address(0));
        require(_value != 0);
        require(add(totalSupply,_value) <= tokenLimit);
    
        balances[_holder] = add(balances[_holder],_value);
        totalSupply =add(totalSupply, _value);
        Transfer(0x0, _holder, _value);
    }
    ```

* 问题合约列表

    * Playkey Token (PKT)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/excess-mint-token-by-overflow_o.csv)

* 相关链接

    * [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A9. excess-buy-token-by-overflow

* 问题描述

    在用eth兑换token的时候，用户若拥有足够的eth，可以通过购买足够大量的token来制造溢出，从而绕过发币上限，以此来获得更多的token。(CVE-2018-11809)

* 错误的代码实现
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

* 推荐的代码实现

    使用诸如safeMath的安全运算方式来运算。

    ```js
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function buyTokensICO() public payable onlyInState(State.ICORunning)
    {
        // min - 0.01 ETH
        require(msg.value >= ((1 ether / 1 wei) / 100));
        uint newTokens = msg.value * getPrice();
    
        require(add(totalSoldTokens, newTokens) <= TOTAL_SOLD_TOKEN_SUPPLY_LIMIT);
    
        balances[msg.sender] =add(balances[msg.sender],newTokens);
        supply=add(supply,newTokens);
        icoSoldTokens = add(icoSoldTokens,newTokens);
        totalSoldTokens = add(totalSoldTokens,newTokens);
    
        LogBuy(msg.sender, newTokens);
    }
    ```

* 问题合约列表

    * EthLend Token (LEND) 

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/excess-buy-token-by-overflow_o.csv)

* 相关链接

    - [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A10. verify-reverse-in-transferFrom

* 问题描述

  在transferFrom()函数中，当对allownce值做校验的时，误将校验逻辑写反，从而使得合约代码的逻辑判断错误。有可能造成溢出或者任何人都能转出任何账户的余额。([CVE-2018-10468](https://nvd.nist.gov/vuln/detail/CVE-2018-10468))

* 错误的代码实现

  bad code 1

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

  bad code 2

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

* 推荐代码实现

    good code 1

    ```js
    //Function for transer the coin from one address to another
    function transferFrom(address from, address to, uint value) returns (bool success) {
        ...
    
        //checking for allowance
        require( allowed[from][msg.sender] >= value );
        
        ...
        return true;
    }
    ```

    good code 2

    ```js
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        ...
    
        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];
    
        bool sufficientFunds = fromBalance >= _value;
        bool sufficientAllowance = allowance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
    
        require(sufficientFunds);
        require(sufficientAllowance);
        require(!overflowed);
        ...
    }
    ```

* 问题合约列表

    * FuturXE (FXE)

    * Useless Ethereum Token (UET)

    * Soarcoin (Soar)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/verify-reverse-in-transferFrom_o.csv)

* 相关链接

    * [ERC20 Token合约F_E惊现毁灭级漏洞，账户余额可以随意转出](https://mp.weixin.qq.com/s/hANqFGGS1ZwjdvFJFeHfoQ )
    * [围观！81个智能合约惊现同一漏洞，是巧合？还是另有玄机？](https://mp.weixin.qq.com/s/9FMt_TBSb9avL78KEAXHuA)

### A11. pauseTransfer-anyone

- 问题描述

  onlyFromWallet中的判断条件将 `==`  写反了，写成了`!=`，使得除了walletAddress以外，所有账户都可以调用enableTokenTransfer 和 disableTokenTransfer 函数。

- 错误的代码实现

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

- 推荐的代码实现

  ```js
  modifier onlyFromWallet {
      require(msg.sender == walletAddress);
      _;
  }
  ```

- 问题合约列表

  - icon (ICX)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/pauseTransfer-anyone_o.csv)

- 相关链接

  - [ICX Token交易控制Bug深度分析](https://mp.weixin.qq.com/s/HuJEQsst534vjK3yb7RcAQ)
  - [Bug in ERC20 contract, transfers can be disabled](https://github.com/icon-foundation/ico/issues/3)

### A12. transferProxy-keccak256

* 问题描述

    keccak256() 和 ecrecover() 都是内嵌的函数，keccak256 可以用于计算公钥的签名，ecrecover 可以用来恢复签名公钥。传值正确的情况下，可以利用这两者函数来验证地址。([CVE-2018-10376](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-10376))

    ```js
    bytes32 hash = keccak256(_from,_spender,_value,nonce,name);
    if(_from != ecrecover(hash,_v,_r,_s)) revert();
    ```

    当ecrecover()的参数错误时候，返回0x0地址，如果 `_from` 也传入0x0地址，就能通过校验。也就是说，任何人都可以将 0x0 地址的余额转出。

* 错误的代码实现

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

* 推荐的代码实现

    对0x0地址做特殊处理。

    ```js
    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeMesh,
        uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){
    
        ...
        require(_from != 0x0);
        bytes32 h = keccak256(_from,_to,_value,_feeMesh,nonce,name);
        if(_from != ecrecover(h,_v,_r,_s)) revert();
        
        ...
        return true;
    }
    ```

* 问题合约列表

    * SmartMesh Token (SMT)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/transferProxy-keccak256_o.csv)

* 相关链接

    * [New proxyOverflow Bug in Multiple ERC20 Smart Contracts (CVE-2018-10376)](https://peckshield.com/2018/04/25/proxyOverflow/)

### A13. approveProxy-keccak256

* 问题描述

    keccak256() 和 ecrecover() 都是内嵌的函数，keccak256 可以用于计算公钥的签名，ecrecover 可以用来恢复签名公钥。传值正确的情况下，可以利用这两者函数来验证地址。([CVE-2018-10376](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-10376))

    ```js
    bytes32 hash = keccak256(_from,_spender,_value,nonce,name);
    if(_from != ecrecover(hash,_v,_r,_s)) revert();
    ```

    当ecrecover()的参数错误时候，返回0x0地址，如果 `_from` 也传入0x0地址，就能通过校验。也就是说，任何人都可以获得 0x0地址的授权。

* 错误的代码实现

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

* 推荐的代码实现

    对0x0地址做特殊处理。

    ```js
    function approveProxy(address _from, address _spender, uint256 _value,
                        uint8 _v,bytes32 _r, bytes32 _s) public returns (bool success) {
    	require(_from != 0x0);
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

* 相关链接

    * [New proxyOverflow Bug in Multiple ERC20 Smart Contracts (CVE-2018-10376)](https://peckshield.com/2018/04/25/proxyOverflow/)

### A14. constructor-case-insentive

* 问题描述

  合约开发过程中，误将构造函数的大小写写错，使得函数名称与合约名称不一致，因而任何人都可以调用这个函数。

* 错误的代码实现 

  ```js
  contract Owned {
      address public owner;
      function owned() public {
          owner = msg.sender;
      }
      modifier onlyOwner {
          require(msg.sender == owner);
          _;
      }
      function transferOwnership(address newOwner) onlyOwner public {
          owner = newOwner;
      }
  }
  ```

* 推荐的代码实现

  把构造函数名写为constructor。

  ```js
  contract Owned {
      address public owner;
      function constructor() public {
          owner = msg.sender;
      }
      modifier onlyOwner {
          require(msg.sender == owner);
          _;
      }
      function transferOwnership(address newOwner) onlyOwner public {
          owner = newOwner;
      }
  }
  ```

* 问题合约列表

  * MORPH (MORPH) 

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/constructor-case-insentive_o.csv)

* 相关链接

  * [一些智能合约存在笔误，一个字母可造成代币千万市值蒸发！](https://bcsec.org/index/detail?id=157&tag=1) 



## B.不兼容问题列表

### B1. transfer-no-return

* 问题描述

  根据ERC20 合约规范，其中 transfer()函数应返回一个bool值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现，transfer()函数没有返回值。
  但若外部合约按照EIP20规范的ABI接口（即包含返回值）去调用无返回值 transfer()函数，在solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后，transfer()函数调用将直接revert。

* 错误的代码实现

    ```js
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }
    ```

* 推荐的代码实现

    合约开发严格按照规范标准来实现

    ```js
    function transfer(address _to, uint256 _value) returns (bool success){
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }
    ```

* 问题合约列表

    * IOT on Chain (ITC)

    * BNB (BNB)

    * loopring (LRC)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/transfer-no-return_o.csv)

* 相关链接

    * [数千份以太坊 Token 合约不兼容问题浮出水面，恐严重影响DAPP生态](https://mp.weixin.qq.com/s/1MB-t_yZYsJDTPRazD1zAA)

### B2. approve-no-return

* 问题描述 

    根据ERC20 合约规范，其中 approve()函数应返回一个bool值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现，approve()函数没有返回值。
    但若外部合约按照EIP20规范的ABI接口（即包含返回值）去调用无返回值 approve()函数，在solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后，approve()函数调用将直接revert。

* 错误的代码实现

    ```js
    function approve(address _spender, uint _value) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }
    ```

* 推荐的代码实现

    合约开发严格按照规范标准来实现。

    ```js
    function approve(address _spender, uint _value) returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    ```

* 问题合约列表

    * loopring (LRC)

    * Paymon Token (PMNT)

    * Metal(MTL)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/approve-no-return_o.csv)

* 相关链接

    - [数千份以太坊 Token 合约不兼容问题浮出水面，恐严重影响DAPP生态](https://mp.weixin.qq.com/s/1MB-t_yZYsJDTPRazD1zAA)

### B3. transferFrom-no-return

* 问题描述 

    根据ERC20 合约规范，其中 transferFrom()函数应返回一个bool值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现，transferFrom()函数没有返回值。
    但若外部合约按照EIP20规范的ABI接口（即包含返回值）去调用无返回值 transferFrom()函数，在solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后，transferFrom()函数调用将直接revert。

* 错误的代码实现

    ```js
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }
    ```

* 推荐的代码实现 

    合约开发严格按照规范标准来实现。

    ```js
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success){
        var _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    ```

* 问题合约列表

    * CUBE (AUTO)

    * loopring (LRC)

    * Paymon Token (PMNT)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/transferfrom-no-return_o.csv)

* 相关链接

    - [数千份以太坊 Token 合约不兼容问题浮出水面，恐严重影响DAPP生态](https://mp.weixin.qq.com/s/1MB-t_yZYsJDTPRazD1zAA)

### B4. no-decimals

- 问题描述

  在token合约中通常使用decimals变量来表示token的小数点后的位数，但在部分合约中，未定义该变量或者该变量没有严格按照规范命名，使用诸如大小写不敏感的decimals来命名，致使外部合约调用时无法兼容。

- 错误的代码实现

  ```js
  uint8 public DECIMALS;
  ```

- 推荐的代码实现

  - 将DECIMALS改为小写

    ```js
    uint8 public decimals;
    ```

  - 增加查询接口

    ```js
    uint8 public DECIMALS;
    
    function decimals() view returns (uint8 decimals){
        return DECIMALS;
    }
    ```

- 问题合约列表 

  - Loopring (LRC)

  - ICON (ICX)

  - HPBCoin (HPB)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/no-decimals_o.csv)


### B5. no-name

- 问题描述

  在token合约中通常使用name变量来表示token的名称，但在部分合约中，未定义该变量或者该变量没有严格按照规范命名，使用诸如大小写不敏感的name，致使外部合约调用时无法兼容。

- 错误的代码实现

  ```js
  string public NAME;
  ```

- 推荐的代码实现

  - 将NAME改为小写

    ```js
    string public name;
    ```

  - 增加查询接口

    ```js
    string public NAME;
    function name() view returns (string name){
        return NAME;
    }
    ```

- 问题合约列表 

  - Loopring (LRC)

  - ICON (ICX)

  - HPBCoin (HPB)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/no-name_o.csv)

### B6. no-symbol 

- 问题描述

  在token合约中通常使用symbol变量来表示token的别名，但在部分合约中，未定义该变量或者该变量没有严格按照规范命名，使用诸如大小写不敏感的symbol来命名，致使外部合约调用时无法兼容。

- 错误的代码实现

  ```js
  string public SYMBOL;
  ```

- 推荐的代码实现

  - 将SYMBOL改为小写

    ```js
    string public symbol;
    ```

  - 增加查询接口

    ```js
    string public SYMBOL;
    function symbol() view returns (string symbol){
        return SYMBOL;
    }
    ```

- 问题合约列表 

  - Loopring (LRC)

  - ICON (ICX)

  - HPBCoin (HPB)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/no-symbol_o.csv)

    

## C. 权限管理问题列表

### C1. setowner-anyone

- 问题描述

  setOwner()函数的作用是修改owner，通常情况下该函数只有当前 owner 可以调用。 但问题代码中，任何人都可以调用setOwner()函数，这就导致了任何人都可以修改合约的owner。([CVE-2018-10705](https://nvd.nist.gov/vuln/detail/CVE-2018-10705))

- 错误的代码实现

  ```js
  function setOwner(address _owner) returns (bool success) {
      owner = _owner;
      return true;
  }
  ```

- 推荐的代码实现

  ```js
  modifier onlyOwner() {
      require(msg.sender == owner);
      _;
  }
  function setOwner(address _owner) onlyOwner returns (bool success) {
      owner = _owner;
      return true;
  }
  ```

- 问题合约列表

  - Aurora DAO (AURA)

  - idex-membership

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/setowner-anyone_o.csv)

- 相关链接

  - [New ownerAnyone Bug Allows For Anyone to ''Own'' Certain ERC20-Based Smart Contracts (CVE-2018-10705)](https://peckshield.com/2018/05/03/ownerAnyone/)

### C2. centralAccount-transfer-anyone

- 问题描述

  onlycentralAccount账户可以任意转出他人账户上的余额。([CVE-2018-1000203](https://nvd.nist.gov/vuln/detail/CVE-2018-1000203))

- 错误的代码实现 

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

- 问题合约列表

  - Soarcoin (Soar)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/centralAccount-transfer-anyone_o.csv) 

- 相关链接

  - [ERC20代币Soarcoin (SOAR) 存在后门，合约所有者可任意转移他人代币](https://mp.weixin.qq.com/s/LvLMJHUg-O5G37TQ9y4Gxg)

    

## reference

* [1] https://nvd.nist.gov/vuln/detail/CVE-2018-10299 CVE-2018-10299
* [2] https://nvd.nist.gov/vuln/detail/CVE-2018-10468  CVE-2018-10468
* [3] https://nvd.nist.gov/vuln/detail/CVE-2018-1000203 CVE-2018-1000203
* [4] https://blog.csdn.net/Secbit/article/details/80045167 SECBIT: 美链(BEC)合约安全事件分析全景, Apr 23, 2018.
* [5] https://www.secrss.com/articles/3289 ERC20智能合约整数溢出系列漏洞披露, Jun 12, 2018.
* [6] https://peckshield.com/2018/04/25/proxyOverflow/ New proxyOverflow Bug in Multiple ERC20 Smart Contracts (CVE-2018-10376), Apr 25, 2018.
* [7] https://medium.com/coinmonks/uselessethereumtoken-uet-erc20-token-allows-attackers-to-steal-all-victims-balances-543d42ac808e UselessEthereumToken(UET), ERC20 token, allows attackers to steal all victim’s balances (CVE-2018–10468), May 3, 2018.
* [8] https://mp.weixin.qq.com/s/hANqFGGS1ZwjdvFJFeHfoQ ERC20 Token合约F_E惊现毁灭级漏洞，账户余额可以随意转出,  Jun 6, 2018.
* [9] https://mp.weixin.qq.com/s/9FMt_TBSb9avL78KEAXHuA 围观！81个智能合约惊现同一漏洞，是巧合？还是另有玄机？Jun 3, 2018.
* [10] https://mp.weixin.qq.com/s/HuJEQsst534vjK3yb7RcAQ ICX Token交易控制Bug深度分析, Jun 16, 2018.
* [11] https://peckshield.com/2018/05/03/ownerAnyone/ New ownerAnyone Bug Allows For Anyone to ''Own'' Certain ERC20-Based Smart Contracts (CVE-2018-10705), May 3, 2018.
* [11] https://mp.weixin.qq.com/s/1MB-t_yZYsJDTPRazD1zAA 数千份以太坊 Token 合约不兼容问题浮出水面，恐严重影响DAPP生态, Jun 8,2018.
* [12] https://mp.weixin.qq.com/s/LvLMJHUg-O5G37TQ9y4Gxg ERC20代币Soarcoin (SOAR) 存在后门，合约所有者可任意转移他人代币, Jun 9,2018.
* [13] https://github.com/icon-foundation/ico/issues/3 Bug in ERC20 contract, transfers can be disabled, Jun 16,2018.
* [14] https://bcsec.org/index/detail?id=157&tag=1 一些智能合约存在笔误，一个字母可造成代币千万市值蒸发！Jun 22,2018.
* [15] https://github.com/ConsenSys/smart-contract-best-practices 以太坊智能合约 —— 最佳安全开发指南