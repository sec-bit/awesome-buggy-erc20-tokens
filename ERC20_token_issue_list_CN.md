# ERC20 Token 合约安全风险问题汇总

[![Join the chat at https://gitter.im/sec-bit/Lobby](https://badges.gitter.im/sec-bit/Lobby.svg)](https://gitter.im/sec-bit/Lobby)



在以太坊平台已部署的数以万计份合约中，Token合约占据了半壁江山，这些Token合约承载的价值更是不可估量。然而由于诸多因素的限制，智能合约的开发还存在很多的不足之处，接二连三爆出的安全事件就是最好的印证。

本文收录了token合约中目前已披露的安全风险问题，旨在帮助大家快速了解这些安全风险，提高安全意识，避免重复踩坑，杜绝不必要的损失。同时也建议大家在合约开发过程中参考安全标准的开发指导说明和规范源码，如「[以太坊智能合约 —— 最佳安全开发指南](https://github.com/ConsenSys/smart-contract-best-practices)」。

## 最近更新
* 2018-07-14，新增问题分类：constructor-mistyping
* 2018-07-12，新增问题分类：check-effect-inconsistency
* 2018-06-26，新增问题分类：allowAnyone，no-allowance-verify，re-approve，no-Approval
* 2018-06-23，添加如何参与贡献和版权声明
* 2018-06-23，添加快速导航
* 2018-06-22，新增问题分类：no-decimals，no-name，no-symbol
* 2018-06-22，新增问题分类：constructor-case-insensitive


## 问题分类

本文共收录了29种问题，大致分为下表所述三大类：

| 分类 | 描述                                                         |
| ---- | ------------------------------------------------------------ |
| A    | 代码实现漏洞，涵盖了合约代码功能实现和逻辑实现上的漏洞，如整数溢出 |
| B    | 不规范问题，涵盖了因代码实现不规范导致版本不兼容或者外部合约调用时的无法不兼容问题，如 ERC20 接口无返回值 |
| C    | 权限管理问题，涵盖了所有因管理权限设置不当而引发的问题，如owner可以操作任何人账户上的余额 |

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
  - [A14. constructor-case-insensitive](#a14-constructor-case-insensitive)
  - [A15. custom-fallback-bypass-ds-auth](#a15-custom-fallback-bypass-ds-auth)
  - [A16. custom-call-abuse](#a16-custom-call-abuse)
  - [A17. setowner-anyone](#a17-setowner-anyone)
  - [A18. allowAnyone](#a18-allowanyone)
  - [A19. approve-with-balance-verify](#a19-approve-with-balance-verify)
  - [A20. re-approve](#a20-re-approve)
  - [A21. check-effect-inconsistency](#a21-check-effect-inconsistency)
  - [A22. constructor-mistyping](#a22-constructor-mistyping)
  - [A23. fake-burn](#a23-fake-burn)

- [B.不规范问题列表](#b不规范问题列表)

  - [B1. transfer-no-return](#b1-transfer-no-return)
  - [B2. approve-no-return](#b2-approve-no-return)
  - [B3. transferFrom-no-return](#b3-transferfrom-no-return)
  - [B4. no-decimals](#b4-no-decimals)
  - [B5. no-name](#b5-no-name)
  - [B6. no-symbol](#b6-no-symbol)
  - [B7. no-Approval](#b7-no-approval)

- [C. 权限管理问题列表](#c-权限管理问题列表)

  - [C1. centralAccount-transfer-anyone](#c1-centralaccount-transfer-anyone)

  

## 如何参与贡献

我们会长期维护本文，并对其进行持续地更新。也欢迎大家共同参与进来，共同推进以太坊生态健康发展。

如果您发现了本文未收录的问题，欢迎按照以下流程贡献更新：

- 对问题进行分类，编号(分类名+数字，如A1，B2)

- 在对应问题列表中按照如下模板，添加问题的详细描述

  ```makedown
  ### 编号. 问题名称
  * 问题描述
  * 错误的代码实现
  * 推荐的代码实现
  * 问题合约列表
  * 相关链接
  ```

- 补充 [快速导航](#快速导航)

- 添加引用问题的出处

- 补充`raw`，`issues.json`文件中该问题相应的内容，运行脚本[具体步骤](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/README_CN.md#%E5%A6%82%E4%BD%95%E5%8F%82%E4%B8%8E%E8%B4%A1%E7%8C%AE)

- 检查更改的文件，提交更新

如果你有其他任何问题或者想法，欢迎加入我们的 [Gitter](https://gitter.im/sec-bit/Lobby) 参与讨论。




## A. 代码实现漏洞问题列表

### A1. batchTransfer-overflow

* 问题描述

    `batchTransfer()` 函数的功能是批量转账。调用者可以传入若干个转账地址和转账金额，函数首先执行了一系列的检查，再依次对 `balances` 进行增减操作，以实现 Token 的转移。但是当传入值 `_value` 过大时，`uint256 amount = uint256(cnt) * _value` 会发生溢出（overflow），导致 `amount` 变量不等于`cnt`倍的 `_value`，而是变成一个很小的值，从而通过`require( _value > 0 && balances[msg.sender] >= amount)` 中对转账发起者的余额校验，继而实际转出超过 `balances[msg.sender]` 的Token。([CVE-2018-10299](https://nvd.nist.gov/vuln/detail/CVE-2018-10299))

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

    使用诸如 `SafeMath` 的安全运算方式来运算。

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

      [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/batchTransfer-overflow.o.csv)

* 相关链接

    * [SECBIT: 美链(BEC)合约安全事件分析全景](https://blog.csdn.net/Secbit/article/details/80045167)

### A2. totalsupply-overflow

* 问题描述

    `totalsupply` 通常为合约中代币的总量。 在问题合约代码中，当 token 总量发生变化时，对 `totalSupply` 做加减运算，并没有校验也没有使用 `SafeMath`，从而使得 `totalSupply` 有可能发生溢出。

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

    使用诸如 `SafeMath` 的安全运算方式来运算。

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

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/totalsupply-overflow.o.csv ) 

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

    使用诸如 `SafeMath` 的安全运算方式来运算。

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

      [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/verify-invalid-by-overflow.o.csv)

### A4. owner-control-sell-price-for-overflow

* 问题描述

    部分合约中，用户在以太和token之间进行兑换，兑换的价格由 `owner` 完全控制，若`owner` 想要作恶，可以通过构造一个很大的兑换值，使得计算要兑换出的以太时发生溢出，将原本较大的一个eth数额变为较小的值，因而使得用户只能拿到很少量的以太。(CVE-2018-11811)

* 错误的代码实现

    ```js
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
    ```

* 推荐的代码实现

    使用诸如 `SafeMath` 的安全运算方式来运算。

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

      [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/owner-control-sell-price-for-overflow.o.csv)

* 相关链接

    * [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A5. owner-overweight-token-by-overflow

* 问题描述

    `owner` 账户在向其它账户转账时候，通过转出多于账户余额的Token数量，来给 `balances[owner]` 制造下溢，实现对自身账户余额的任意增加。(CVE-2018-11687)

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

    使用诸如 `SafeMath` 的安全运算方式来运算。

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

       [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/owner-overweight-token-by-overflow.o.csv)

* 相关链接

    - [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A6. owner-decrease-balance-by-mint-by-overflow

* 问题描述

    有铸币权限的 `owner` 可以通过给某一账户增发数量极大的token，使得这个账户的余额溢出为一个很小的数字，从而任意控制这个账户的余额。(CVE-2018-11812)

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

    使用诸如 `SafeMath` 的安全运算方式来运算。

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

      [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/owner-decrease-balance-by-mint-by-overflow.o.csv)

* 相关链接

    - [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A7. excess-allocation-by-overflow

* 问题描述

    `owner` 在给账户分配token时候，可以通过溢出绕开上限，从而给指定的地址分配更多的token。(CVE-2018-11810)

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

    使用诸如 `SafeMath` 的安全运算方式来运算。

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

      [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/excess-allocation-by-overflow.o.csv)

* 相关链接

    - [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A8. excess-mint-token-by-overflow

* 问题描述

    `owner` 可以通过传入一个极大的值来制造溢出，进而绕开合约中铸币最大值的设置，来发行任意多的币。(CVE-2018-11809)

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

    使用诸如 `SafeMath` 的安全运算方式来运算。

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

      [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/excess-mint-token-by-overflow.o.csv )

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

    使用诸如 `SafeMath` 的安全运算方式来运算。

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

      [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/excess-buy-token-by-overflow.o.csv ) 

* 相关链接

    - [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A10. verify-reverse-in-transferFrom

* 问题描述

  在 `transferFrom()` 函数中，当对 `allowance`值做校验的时，误将校验逻辑写反，从而使得合约代码的逻辑判断错误。有可能造成溢出或者任何人都能转出任何账户的余额。([CVE-2018-10468](https://nvd.nist.gov/vuln/detail/CVE-2018-10468))

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

    ​        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/verify-reverse-in-transferFrom.o.csv )

* 相关链接

    * [ERC20 Token合约F_E惊现毁灭级漏洞，账户余额可以随意转出](https://mp.weixin.qq.com/s/hANqFGGS1ZwjdvFJFeHfoQ )
    * [围观！81个智能合约惊现同一漏洞，是巧合？还是另有玄机？](https://mp.weixin.qq.com/s/9FMt_TBSb9avL78KEAXHuA)

### A11. pauseTransfer-anyone

- 问题描述

  `onlyFromWallet` 中的判断条件将 `==`  写反了，写成了`!=`，使得除了 `walletAddress` 以外，所有账户都可以调用 `enableTokenTransfer()` 和 `disableTokenTransfer()` 函数。

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

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/pauseTransfer-anyone.o.csv)

- 相关链接

  - [ICX Token交易控制Bug深度分析](https://mp.weixin.qq.com/s/HuJEQsst534vjK3yb7RcAQ)
  - [Bug in ERC20 contract, transfers can be disabled](https://github.com/icon-foundation/ico/issues/3)

### A12. transferProxy-keccak256

* 问题描述

    `keccak256()` 和 `ecrecover()` 都是内嵌的函数， `keccak256()` 可以用于计算公钥的签名， `ecrecover()` 可以用来恢复签名公钥。传值正确的情况下，可以利用这两者函数来验证地址。([CVE-2018-10376](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-10376))

    ```js
    bytes32 hash = keccak256(_from,_spender,_value,nonce,name);
    if(_from != ecrecover(hash,_v,_r,_s)) revert();
    ```

    当 `ecrecover()` 的参数错误时候，返回 `0x0` 地址，如果 `_from` 也传入 `0x0` 地址，就能通过校验。也就是说，任何人都可以将 `0x0` 地址的余额转出。

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

    对 `0x0` 地址做特殊处理。

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

      [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/transferProxy-keccak256.o.csv)

* 相关链接

    * [New proxyOverflow Bug in Multiple ERC20 Smart Contracts (CVE-2018-10376)](https://peckshield.com/2018/04/25/proxyOverflow/)

### A13. approveProxy-keccak256

* 问题描述

    `keccak256()` 和 `ecrecover()` 都是内嵌的函数， `keccak256()` 可以用于计算公钥的签名， `ecrecover()` 可以用来恢复签名公钥。传值正确的情况下，可以利用这两者函数来验证地址。([CVE-2018-10376](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-10376))

    ```js
    bytes32 hash = keccak256(_from,_spender,_value,nonce,name);
    if(_from != ecrecover(hash,_v,_r,_s)) revert();
    ```

    当 `ecrecover()` 的参数错误时候，返回 `0x0` 地址，如果 `_from` 也传入 `0x0` 地址，就能通过校验。也就是说，任何人都可以获得 `0x0` 地址的授权。

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

    对 `0x0` 地址做特殊处理。

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

      [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/approveProxy-keccak256.o.csv)

* 相关链接

    * [New proxyOverflow Bug in Multiple ERC20 Smart Contracts (CVE-2018-10376)](https://peckshield.com/2018/04/25/proxyOverflow/)

### A14. constructor-case-insensitive

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

  把构造函数名写为 `constructor`。

  ```js
  contract Owned {
      address public owner;
      constructor() public {
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

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/constructor-case-insensitive.o.csv)

* 相关链接

  * [一些智能合约存在笔误，一个字母可造成代币千万市值蒸发！](https://bcsec.org/index/detail?id=157&tag=1) 

### A15. custom-fallback-bypass-ds-auth

* 问题描述

    Token 合约同时使用了 ERC223 的 Recommended 分支代码和 `ds-auth` 合约库，黑客可利用 ERC223 合约可传入自定义回调函数与 `ds-auth` 库授权校验的特征，在 ERC223 合约回调函数发起时，调用合约自身从而造成内部权限控制失效。

* 错误的代码实现 

    ```js
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _amount, 
        bytes _data, 
        string _custom_fallback
        ) 
        public returns (bool success)
    {
        ...
        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiving.call.value(0)(byte4(keccak256(_custom_fallback)), _from, amout, data);
        ...
    }
    
    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        }
        ...
    }
    ```

* 推荐的代码实现

  - 尽量不要使用 ERC223 带 `_custom_fallback` 参数的版本，使用 `tokenFallback` 完成类似功能：
    
    ```js
        ERC223Receiver receiver = ERC223Receiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
    ```

  - `ds-auth` 合约在判断权限的时候，不要把合约自身加入白名单

    ```js
    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        }
        ...
    }
    ```

* 问题合约列表

  * ATN (ATN) （官方已通过增加 Guard 合约的方式修复）

    [more...](csv/custom-fallback-bypass-ds-auth.o.csv)

* 相关链接

  * [ATN抵御合约攻击的报告](https://atn.io/resource/aareport.pdf)
  * [以太坊智能合约call注入攻击](https://blog.csdn.net/u011721501/article/details/80757811)
  * [ERC-223 Token Standard Proposal Draft](https://github.com/ethereum/EIPs/issues/223)

### A16. custom-call-abuse

* 问题描述

    与[a15-custom-fallback-bypass-ds-auth](#a15-custom-fallback-bypass-ds-auth) 类似，Token 合约设计或实现上允许用户自定义 call() 任意地址上任意函数来实现“接收通知调用”功能，攻击者可以很容易地借用当前合约的身份来进行任何操作。

    这通常会导致以下危险的后果：

    - 后果一：允许攻击者以缺陷合约身份来盗走其它 Token 合约中的 Token
    - 后果二：与 ds-auth 之类的鉴权机制结合，绕过合约自身的权限检查
    - 后果三：允许攻击者以缺陷合约身份来盗走其它 Token 账户所授权（Approve）的 Token
    - 后果四：攻击者可传入虚假数据欺骗 Receiver 合约

* 错误的代码实现

    ```js
    <receiver>.call.value(msg.value)(_data)
    ```

    ```js
    receiver.call.value(0)(byte4(keccak256(_custom_fallback)), _from, amout, data);
    ```

    ERC223, ERC827 的部分实现代码均引入了任意函数调用缺陷，可能会对使用这部分代码的合约带来安全漏洞。

* 推荐的代码实现

    正确的代码实现中，对于“接收通知调用”的处理应该将被通知函数的签名（signature）写死为固定值，避免由攻击者来任意指定的任何可能性。

    - https://github.com/svenstucki/ERC677
    - https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC721/ERC721BasicToken.sol#L349
    - https://github.com/ConsenSys/Token-Factory/blob/master/contracts/HumanStandardToken.sol
    - https://github.com/ethereum/ethereum-org/blob/b46095815f52cf328ecf7676b2b38284d48fba58/solidity/token-advanced.sol#L138

* 问题合约列表

    * TE-FOOD (TFD)

      [more...](csv/custom-call-abuse.o.csv) 

* 相关链接

    * [ATN抵御合约攻击的报告](https://atn.io/resource/aareport.pdf)
    * [以太坊智能合约call注入攻击](https://blog.csdn.net/u011721501/article/details/80757811)
    * [New evilReflex Bug Identified in Multiple ERC20 Smart Contracts](https://peckshield.com/2018/06/23/evilReflex/)
    * [ERC223及ERC827实现代码欠缺安全考虑 —— ATN Token中的CUSTOM_CALL漏洞深入分析](https://zhuanlan.zhihu.com/p/38465008)
    * [Discussion about ERC827 Proposal Implementation](https://github.com/ethereum/EIPs/issues/827#issuecomment-399776972)
    * [ERC-223 Token Standard Proposal Draft](https://github.com/ethereum/EIPs/issues/223)

### A17. setowner-anyone

- 问题描述

  `setOwner()` 函数的作用是修改 `owner`，通常情况下该函数只有当前 `owner` 可以调用。 但问题代码中，任何人都可以调用 `setOwner()` 函数，这就导致了任何人都可以修改合约的 `owner`。([CVE-2018-10705](https://nvd.nist.gov/vuln/detail/CVE-2018-10705))

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

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/setowner-anyone.o.csv )

- 相关链接

  - [New ownerAnyone Bug Allows For Anyone to ''Own'' Certain ERC20-Based Smart Contracts (CVE-2018-10705)](https://peckshield.com/2018/05/03/ownerAnyone/)

### A18. allowAnyone

* 问题描述

  在`transferFrom`函数中，由于缺少了对`allowed`的校验， 任何账户都可以对某一账户上的余额随意进行转账，黑客就可以利用这个漏洞将他人账户上的余额转入自己的账户中，从而获益。同时若转账金额超出了`allowed` 的限制，`allowed[_from][msg.sender] -= _value;`这段代码将导致的溢出。

* 错误的代码实现

  ```js
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      /// same as above
      require(_to != 0x0);
      require(balances[_from] >= _value);
      require(balances[_to] + _value > balances[_to]);
  
      uint previousBalances = balances[_from] + balances[_to];
      balances[_from] -= _value;
      balances[_to] += _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      assert(balances[_from] + balances[_to] == previousBalances);
  
      return true;
  }
  ```

* 推荐的代码实现

  增加allowed的校验或者使用safeMath进行运算。

  ```js
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      /// same as above
      require(_to != 0x0);
      require(balances[_from] >= _value);
      require(balances[_to] + _value > balances[_to]);
  	require(allowed[_from][msg.sender] >= _value);
      
      uint previousBalances = balances[_from] + balances[_to];
      balances[_from] -= _value;
      balances[_to] += _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      assert(balances[_from] + balances[_to] == previousBalances);
  
      return true;
  }
  ```

* 问题合约列表

  * EDUCoin

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/allowAnyone.o.csv )

* 相关链接

  [智能合约红色预警：四个Token惊爆逻辑漏洞，归零风险或源于代码复制](https://mp.weixin.qq.com/s/lf9vXcUxdB2fGY2YVTauRQ )

 ### A19. approve-with-balance-verify

* 问题描述

  部分合约在函数approve()中，增加对被授权账户余额的校验，要求授权的_amount小于或等于当前余额。

  一方面对余额的校验并不能保证被授权账户一定可以转出这个数量的金额:

  * 在approve之后，token的所有者自己通过transfer函数，把token转走，导致余额小于allowance。
  * approve给多个人，其中一个人进行transferFrom操作后，可能导致余额小于之前给其他人approve过的值。

  另一方面这个校验可能导致外部合约（如以0x协议为基础的去中心化交易所）无法正常调用，必须由 Token 项目方提前转入一笔数额巨大的 Token 至中间账户才能继续执行。

* 错误的代码实现

  ```js
  function approve(address _spender, uint _amount) returns (bool success) {
      // approval amount cannot exceed the balance
      require ( balances[msg.sender] >= _amount );
      // update allowed amount
      allowed[msg.sender][_spender] = _amount;
      // log event
      Approval(msg.sender, _spender, _amount);
      return true;
  }
  ```

* 推荐的代码实现

  去掉balance的校验

  ```js
  function approve(address _spender, uint _amount) returns (bool success) {
      // update allowed amount
      allowed[msg.sender][_spender] = _amount;
      // log event
      Approval(msg.sender, _spender, _amount);
      return true;
  }
  ```

* 问题合约列表

  * Saint Coins (SAINT) 

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/approve-with-balance-verify.o.csv )

* 相关链接

  [ERC20智能合约的approve千万别这样写](https://mp.weixin.qq.com/s/hYE4nu7FCD_nJH5WMRrXMA)

### A20. re-approve

- 问题描述

  approve函数执行时，通过直接修改allowance为新的值，授权spender账户花费新的指定金额。

  如果spender在有能力操纵交易被矿工确认的顺序，那么spender可以在approve函数调用生效前，花费现有的所有的allowance，等到approve生效，spender便可以花费新的allowance，使得总花费大于预想的数量，从而导致Re-approve攻击。

  当spender账户已获得approve权限，被授权账户修改approve金额，并且账户余额充足时，若spender有能力操作交易的打包顺序时情况下才能够发动改类攻击。

  此类攻击仅会造成spender账户可以使用比被授权账户预期更多的代币，或者可以使用的代币不足预期，并不会对账户余额和代币总量造成实质性的影响。

- 推荐的代码实现 

  该问题是由于ERC20规范的漏洞引发的问题，目前大部分合约都存在该问题（问题合约不再专门列出）。建议使用increaseApprove()和decreaseApprove()进行授权来规避。

  ```js
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
      allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }
  
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
      uint oldValue = allowed[msg.sender][_spender];
      if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
      } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }
  ```

- 相关链接

  - [ERC20 API: An Attack Vector on Approve/TransferFrom Methods](https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/)

### A21. check-effect-inconsistency

* 问题描述

    条件验证与变量修改逻辑不一致，使得验证失效，可进一步导致整数下溢等其他漏洞。
    比如合约检查的是A的余额，却更新了B的余额。

* 错误的代码实现

    ```js
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        ...
        require(_value <= allowed[_from][msg.sender]);    // Check the allowance of msg.sender
        ...
        allowed[_from][_to] -= _value;    // But update the allowance of _to
        ...
        return true;
    }
    ```

* 推荐的代码实现

    ```js
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        ...
        require(_value <= allowed[_from][msg.sender]);
        ...
        allowed[_from][msg.sender] -= _value;
        ...
        return true;
    }
    ```

* 问题合约列表

    * LightCoin Token (LIGHT)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/check-effect-inconsistency.o.csv)

### A22. constructor-mistyping

- 问题描述

  开发者在声明构造函数时应该写为 `constructor()`，但有些合约误写为 `function constructor()`，因此 Solidity 编译器将其视为任何人都可以调用的普通函数，而非仅合约部署时调用一次的构造函数。

- 错误的代码实现

  ```js
  contract A{
      function constructor() public{
  
      }
  }
  ```

- 推荐的代码实现

  ```js
  contract A{
      constructor() public{
  
      }
  }
  ```

- 问题合约列表

    - Maolulu Polkadot (MDOT)

      [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/constructor-mistyping.o.csv)

- 相关链接

  - [注意！3份合约又存在Owner权限被盗问题——低级错误不容忽视](<https://mp.weixin.qq.com/s?__biz=MzU2NzUxMTM0Nw==&mid=2247484096&idx=1&sn=d7f228bf24af9e66a6db6129b9e49aeb&chksm=fc9d529ccbeadb8a635bf46f46a23467fdee54eac862de982c7c9053ce0e2418a36ff8b003c4&scene=0&pass_ticket=Ku28saTpR8rmi3fOxGcGnUDOlhbL1U7mvP8xbjKvcVfVDW%2F3J%2BwTJV7vegBCqRyR#rd>)

### A23. fake-burn

- 问题描述

    Token 合约中存在整数溢出漏洞（CVE-2018-13151 fake-burn）。合约烧币功能存在**乘方运算**可导致整数溢出，通过精心构造指数，使得烧币的实际值为零。

    黑客可通过构造参数，在自身余额并不减少的情况下，触发烧币 `Burn()` 事件。

- 错误的代码实现

```js
    function burnWithDecimals(uint256 _value, uint256 _dec) public returns (bool success) {
        _value = _value * 10 ** _dec;
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
```

问题合约代码 `burnWithDecimals()` 函数中 `10 ** _dec` 这一乘方操作存在整数溢出漏洞，可使计算结果为 `0`。若 `_dec` 传入值大于 `255`，则最终 `_value` 值会被更新为 `0`。

- 问题合约列表

  *  OnPlace (OPL)

    [more...](csv/fake-burn.o.csv)


- 相关链接

    - [震惊！利好变利空，烧币也能作假！](https://mp.weixin.qq.com/s/-4d3OD0M_a0xGGADNzi7Xw)

## B.不规范问题列表

### B1. transfer-no-return

* 问题描述

  根据ERC20 合约规范，其中 `transfer()` 函数应返回一个bool值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现， `transfer()` 函数没有返回值。
  但若外部合约按照EIP20规范的ABI接口（即包含返回值）去调用无返回值 `transfer()` 函数，在Solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后， `transfer()` 函数调用将直接 `revert`。

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

    * UNetworkToken (UUU)

      ​    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/transfer-no-return.o.csv)

* 相关链接

    * [数千份以太坊 Token 合约不兼容问题浮出水面，恐严重影响DAPP生态](https://mp.weixin.qq.com/s/1MB-t_yZYsJDTPRazD1zAA)

### B2. approve-no-return

* 问题描述 

    根据ERC20 合约规范，其中 `approve()` 函数应返回一个 `bool` 值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现， `approve()` 函数没有返回值。
    但若外部合约按照EIP20规范的ABI接口（即包含返回值）去调用无返回值 `approve()` 函数，在Solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后， `approve()` 函数调用将直接 `revert`。

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

    * Metal(MTL)

       [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/approve-no-return.o.csv )

* 相关链接

    - [数千份以太坊 Token 合约不兼容问题浮出水面，恐严重影响DAPP生态](https://mp.weixin.qq.com/s/1MB-t_yZYsJDTPRazD1zAA)

### B3. transferFrom-no-return

* 问题描述 

    根据ERC20 合约规范，其中 `transferFrom()` 函数应返回一个 `bool` 值。但是大量实际部署的Token合约，并没有严格按照 EIP20 规范来实现， `transferFrom()` 函数没有返回值。
    但若外部合约按照EIP20规范的ABI接口（即包含返回值）去调用无返回值 `transferFrom()` 函数，在Solidity编译器升级至0.4.22版本以前，合约调用也不会出现异常。但当合约升级至0.4.22后， `transferFrom()` 函数调用将直接 `revert`。

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

      [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/transferfrom-no-return.o.csv)

* 相关链接

    - [数千份以太坊 Token 合约不兼容问题浮出水面，恐严重影响DAPP生态](https://mp.weixin.qq.com/s/1MB-t_yZYsJDTPRazD1zAA)

### B4. no-decimals

- 问题描述

  在token合约中通常使用 `decimals` 变量来表示token的小数点后的位数，但在部分合约中，未定义该变量或者该变量没有严格按照规范命名，使用诸如大小写不敏感的 `decimals` 来命名，致使外部合约调用时无法兼容。

- 错误的代码实现

  ```js
  uint8 public DECIMALS;
  ```

- 推荐的代码实现

  - 将 `DECIMALS` 改为小写

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

    - ICON (ICX) 

      [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/no-decimals.o.csv )
### B5. no-name

- 问题描述

  在token合约中通常使用 `name` 变量来表示token的名称，但在部分合约中，未定义该变量或者该变量没有严格按照规范命名，使用诸如大小写不敏感的 `name`，致使外部合约调用时无法兼容。

- 错误的代码实现

  ```js
  string public NAME;
  ```

- 推荐的代码实现

  - 将 `NAME` 改为小写

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

  - ICON (ICX) 

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/no-name.o.csv )

### B6. no-symbol 

- 问题描述

  在token合约中通常使用 `symbol` 变量来表示token的别名，但在部分合约中，未定义该变量或者该变量没有严格按照规范命名，使用诸如大小写不敏感的 `symbol` 来命名，致使外部合约调用时无法兼容。

- 错误的代码实现

  ```js
  string public SYMBOL;
  ```

- 推荐的代码实现

  - 将 `SYMBOL` 改为小写

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

  - ICON (ICX)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/no-symbol.o.csv)

### B7. no-Approval

* 问题描述

  ERC20 标准中还规定了 `Transfer` 和 `Approval` 事件必须在特定场景下触发。很多 Token 的实现参考了以太坊官网的不标准代码(已修复)，漏掉触发 `Approval` 事件的操作。

* 错误代码实现

  ```js
  function approve(address _spender, uint _amount) returns (bool success) {
      allowed[msg.sender][_spender] = _amount;
      return true;
  }
  ```

* 推荐的代码实现

  ```js
  function approve(address _spender, uint _amount) returns (bool success) {
      allowed[msg.sender][_spender] = _amount;
      Approval(msg.sender, _spender, _amount);
      return true;
  }
  ```

* 问题合约列表

  * JEX Token (JEX)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/no-Approval.o.csv )


## C. 权限管理问题列表

### C1. centralAccount-transfer-anyone

- 问题描述

  `onlycentralAccount`账户可以任意转出他人账户上的余额。([CVE-2018-1000203](https://nvd.nist.gov/vuln/detail/CVE-2018-1000203))

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

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/centralAccount-transfer-anyone.o.csv ) 

- 相关链接

  - [ERC20代币Soarcoin (SOAR) 存在后门，合约所有者可任意转移他人代币](https://mp.weixin.qq.com/s/LvLMJHUg-O5G37TQ9y4Gxg)

## Reference 

* [1] https://nvd.nist.gov/vuln/detail/CVE-2018-10299 CVE-2018-10299.
* [2] https://nvd.nist.gov/vuln/detail/CVE-2018-10468  CVE-2018-10468.
* [3] https://nvd.nist.gov/vuln/detail/CVE-2018-1000203 CVE-2018-1000203.
* [4] https://blog.csdn.net/Secbit/article/details/80045167 SECBIT: 美链(BEC)合约安全事件分析全景, Apr 23, 2018.
* [5] https://www.secrss.com/articles/3289 ERC20智能合约整数溢出系列漏洞披露, Jun 12, 2018.
* [6] https://peckshield.com/2018/04/25/proxyOverflow/ New proxyOverflow Bug in Multiple ERC20 Smart Contracts (CVE-2018-10376), Apr 25, 2018.
* [7] https://medium.com/coinmonks/uselessethereumtoken-uet-erc20-token-allows-attackers-to-steal-all-victims-balances-543d42ac808e UselessEthereumToken(UET), ERC20 token, allows attackers to steal all victim’s balances (CVE-2018–10468), May 3, 2018.
* [8] https://mp.weixin.qq.com/s/hANqFGGS1ZwjdvFJFeHfoQ ERC20 Token合约F_E惊现毁灭级漏洞，账户余额可以随意转出,  Jun 6, 2018.
* [9] https://mp.weixin.qq.com/s/9FMt_TBSb9avL78KEAXHuA 围观！81个智能合约惊现同一漏洞，是巧合？还是另有玄机？Jun 3, 2018.
* [10] https://mp.weixin.qq.com/s/HuJEQsst534vjK3yb7RcAQ ICX Token交易控制Bug深度分析, Jun 16, 2018.
* [11] https://peckshield.com/2018/05/03/ownerAnyone/ New ownerAnyone Bug Allows For Anyone to ''Own'' Certain ERC20-Based Smart Contracts (CVE-2018-10705), May 3, 2018.
* [12] https://mp.weixin.qq.com/s/1MB-t_yZYsJDTPRazD1zAA 数千份以太坊 Token 合约不兼容问题浮出水面，恐严重影响DAPP生态, Jun 8,2018.
* [13] https://mp.weixin.qq.com/s/LvLMJHUg-O5G37TQ9y4Gxg ERC20代币Soarcoin (SOAR) 存在后门，合约所有者可任意转移他人代币, Jun 9,2018.
* [14] https://github.com/icon-foundation/ico/issues/3 Bug in ERC20 contract, transfers can be disabled, Jun 16,2018.
* [15] https://bcsec.org/index/detail?id=157&tag=1 一些智能合约存在笔误，一个字母可造成代币千万市值蒸发！Jun 22,2018.
* [16] https://github.com/ConsenSys/smart-contract-best-practices 以太坊智能合约 —— 最佳安全开发指南.
* [17] https://mp.weixin.qq.com/s/lf9vXcUxdB2fGY2YVTauRQ 智能合约红色预警：四个Token惊爆逻辑漏洞，归零风险或源于代码复制. May 24, 2018.
* [18] https://mp.weixin.qq.com/s/hYE4nu7FCD_nJH5WMRrXMA ERC20智能合约的approve千万别这样写. Jun 15,2018.
* [19] https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/ ERC20 API: An Attack Vector on Approve/TransferFrom Methods.

 

## 版权声明

[![CC0](http://mirrors.creativecommons.org/presskit/buttons/88x31/svg/cc-zero.svg)](https://creativecommons.org/publicdomain/zero/1.0/)
