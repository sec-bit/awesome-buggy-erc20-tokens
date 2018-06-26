# A Collection of Risks and Vulnerabilities in ERC20 Token Contracts

[![Join the chat at https://gitter.im/sec-bit/Lobby](https://badges.gitter.im/sec-bit/Lobby.svg)](https://gitter.im/sec-bit/Lobby)



Of all contracts deployed on Ethereum, a huge part are intended for tokens and never could we overestimate their value. However, smart contracts are far from perfection owing to the restriction by several factors, as security incidents are emerging from time to time.

In order to help developers be fully aware of risks along with vulnerabilities in smart contracts and avoid unnecessary losses in these pitfalls, we created this article with all known issues. Please conform your code to security guides when developing, e.g. ['*Smart Contract Best Practices*'](https://github.com/ConsenSys/smart-contract-best-practices).

## Recent Updates
* 2018-06-26， add new issue types： allowAnyone，no-allowance-verify，re-approve，no-Approval
* 2018-06-23， add 'how to contribute' and license
* 2018-06-23， add navigation
* 2018-06-22， add new issue types: no-decimals，no-name，no-symbol
* 2018-06-22， add new issue type: constructor-case-insensitive


## Classification

This article includes 22 types of issue, and we can generally divide them into 3 classes:

| Class | Description                                                  |
| ----- | ------------------------------------------------------------ |
| A     | Bugs in implementation - code & logic, e.g. overflow.        |
| B     | Incompatibilities caused by Different Compiler Versions and External Calls, e.g. no return in ERC20 interfaces. |
| C     | Excessive authorities, e.g. anyone can change owner.         |

#### Navigation

- [A. List of Bugs in Implementation](#a-list-of-bugs-in-implementation)
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
- [B.List of Incompatibilities](#b-list-of-incompatibilities)
  - [B1. transfer-no-return](#b1-transfer-no-return)
  - [B2. approve-no-return](#b2-approve-no-return)
  - [B3. transferFrom-no-return](#b3-transferfrom-no-return)
  - [B4. no-decimals](#b4-no-decimals)
  - [B5. no-name](#b5-no-name)
  - [B6. no-symbol](#b6-no-symbol)
- [C. List of Excessive Authorities](#c-list-of-excessive-authorities)
  - [C1. setowner-anyone](#c1-setowner-anyone)
  - [C2. centralAccount-transfer-anyone](#c2-centralaccount-transfer-anyone)

    

## How to Contribute

We would maintain and update this article continuously. Also, participation is welcomed to build a better Ethereum ecosystem.

If you find issues not listed in the article, please update in the following process:

- Classify and index the issue(type name + number, e.g. A1, B2)

- Add a detailed description with the format below in the correspondent issue list

  ```makedown
  ### Index. Name
  * Description
  * Problematic Implementation
  * Recommended Implementation
  * List of Buggy Contracts
  * Link
  ```

- Put the issue into [Navigation](#navigation)

- Append a reference to the issue

- Complete relevant contents in `raw`, `issues.json` and run the script: [Instruction](https://github.com/sec-bit/awesome-buggy-erc20-tokens#how-to-contribute)

- Check updated files and send us a pull request

If you have any questions or ideas, please join our discussion on [Gitter](https://gitter.im/sec-bit/Lobby).


## A. List of Bugs in Implementation

### A1. batchTransfer-overflow

* Description

    `batchTransfer()` makes multiple transactions simultaneously. After passing several transferring addresses and amounts by the caller, the function would conduct some checks then transfer tokens by modifying balances, while overflow might occur in `uint256 amount = uint256(cnt) * _value` if `_value` is a huge number. It results in passing the sender's balance check in `require( _value > 0 && balances[msg.sender] >= amount)` due to making `amount` become a small value rather than `cnt` times of `_value`, then transfers out tokens exceeding `balances[msg.sender]`. ([CVE-2018-10299](https://nvd.nist.gov/vuln/detail/CVE-2018-10299))

* Problematic Implementation

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

* Recommended Implementation

    Compute by secure mathematical operations such as `SafeMath`.

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

* List of Buggy Contracts

    * BeautyChain (BEC)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/batchTransfer-overflow.o.csv)

* Link

    * [A disastrous vulnerability found in smart contracts of BeautyChain (BEC)](https://medium.com/secbit-media/a-disastrous-vulnerability-found-in-smart-contracts-of-beautychain-bec-dbf24ddbc30e)

### A2. totalsupply-overflow

* Description

    `totalSupply` usually represents the sum of all tokens in the contract. The contract would add or decrease `totalSupply` without any check or using ``SafeMath`` when the sum of tokens changes, making overflow possible in `totalSupply`.

* Problematic Implementation 

    ```js
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    ```

* Recommended Implementation

    Compute by secure mathematical operations such as `SafeMath`.

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

* List of Buggy Contracts

    * FuturXE (FXE)

    * Amber Token (AMB)

    * Insights Network (INSTAR)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/totalsupply-overflow.o.csv) 

### A3. verify-invalid-by-overflow

* Description

    The contract checks the balance when doing operations like transferring and the hacker could bypass this check making use of overflow by passing a great value.

* Problematic Implementation

    ```js
    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeMesh,
                            uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){
    
        if(balances[_from] < _feeMesh + _value) revert();
    
        ...
        return true;
    }
    ```

* Recommended Implementation

    Compute by secure mathematical operations such as `SafeMath`.

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

* List of Buggy Contracts

    * SmartMesh Token (SMT)  

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/verify-invalid-by-overflow.o.csv)

### A4. owner-control-sell-price-for-overflow

* Description

    Some contracts let `owner` control the price of transferring between ethers and tokens by users, yet `owner` could maliciously set a huge `sellPrice` to make an overflow in computing equivalent ethers. The original number of ethers becomes a small value, causing the user receiving insufficient ethers. (CVE-2018-11811)

* Problematic Implementation

    ```js
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
    ```

* Recommended Implementation

    Compute by secure mathematical operations such as `SafeMath`.

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

* List of Buggy Contracts   

    * Internet Node Token (INT)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/owner-control-sell-price-for-overflow.o.csv)

* Link

    * [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A5. owner-overweight-token-by-overflow

* Description

    `owner` could bring about an underflow to increase its holding arbitrarily by transferring tokens more than its remaining tokens when transferring to other accounts. (CVE-2018-11687)

* Problematic Implementation

    ```js
    function distributeBTR(address[] addresses) onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            balances[owner] -= 2000 * 10**8;
            balances[addresses[i]] += 2000 * 10**8;
            Transfer(owner, addresses[i], 2000 * 10**8);
        }
    }
    ```

* Recommended Implementation

    Compute by secure mathematical operations such as `SafeMath`.

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

* List of Buggy Contracts

    * Bitcoin Red (BTCR)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/owner-overweight-token-by-overflow.o.csv)

* Link

    - [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A6. owner-decrease-balance-by-mint-by-overflow

* Description

    `owner` with minting authority could control an account's balance at will by sending numerous tokens to the account and leading its balance overflowing to a small figure. (CVE-2018-11812)

* Problematic Implementation

    ```js
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    ```

* Recommended Implementation

    Compute by secure mathematical operations such as `SafeMath`.

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

* List of Buggy Contracts

    * SwftCoin (SWFTC)

    * Pylon Token (PYLNT)

    * Internet Node Token (INT)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/owner-decrease-balance-by-mint-by-overflow.o.csv)

* Link

    - [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A7. excess-allocation-by-overflow

* Description

    `owner` could allocate more tokens to an address via bypassing the upper bound with overflow when allocate tokens to accounts. (CVE-2018-11810)

* Problematic Implementation

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

* Recommended Implementation

    Compute by secure mathematical operations such as `SafeMath`.

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

* List of Buggy Contracts
    * LGO Token (LGO)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/excess-allocation-by-overflow.o.csv)

* Link

    - [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A8. excess-mint-token-by-overflow

* Description

    `owner` can bring about an overflow and issue random amounts of tokens by passing a great value and pass the check of max minting value. (CVE-2018-11809)

* Problematic Implementation

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

* Recommended Implementation

    Compute by secure mathematical operations such as `SafeMath`.

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

* List of Buggy Contracts

    * Playkey Token (PKT)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/excess-mint-token-by-overflow.o.csv)

* Link

    * [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A9. excess-buy-token-by-overflow

* Description

    If the user possesses an enormous amount of ethers when transferring to tokens, he or she could buy so many tokens as an overflow would occur to pass `TOTAL_SOLD_TOKEN_SUPPLY_LIMIT`, thus gets more tokens. (CVE-2018-11809)

* Problematic Implementation
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

* Recommended Implementation

    Compute by secure mathematical operations such as `SafeMath`.

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

* List of Buggy Contracts

    * EthLend Token (LEND) 

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/excess-buy-token-by-overflow.o.csv)

* Link

    - [ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289)

### A10. verify-reverse-in-transferFrom

* Description

  The developer wrote the opposite comparing sign when checking `allowance` in `transferFrom()`, thus there would be an overflow or anyone could transfer out balances of any accounts. ([CVE-2018-10468](https://nvd.nist.gov/vuln/detail/CVE-2018-10468))

* Problematic Implementation

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

* Recommended Implementation

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

* List of Buggy Contracts

    * FuturXE (FXE)

    * Useless Ethereum Token (UET)

    * Soarcoin (Soar)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/verify-reverse-in-transferFrom.o.csv)

* Link

    * [ERC20 Token合约F_E惊现毁灭级漏洞，账户余额可以随意转出](https://mp.weixin.qq.com/s/hANqFGGS1ZwjdvFJFeHfoQ )
    * [围观！81个智能合约惊现同一漏洞，是巧合？还是另有玄机？](https://mp.weixin.qq.com/s/9FMt_TBSb9avL78KEAXHuA)

### A11. pauseTransfer-anyone

- Description

  `onlyFromWallet` mistakingly replaced == with !=, causing anyone except `walletAddress` could call `enableTokenTransfer()` and `disableTokenTransfer()`.

- Problematic Implementation

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

- Recommended Implementation

  ```js
  modifier onlyFromWallet {
      require(msg.sender == walletAddress);
      _;
  }
  ```

- List of Buggy Contracts

  - icon (ICX)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/pauseTransfer-anyone.o.csv)

- Link

  - [ICX Token交易控制Bug深度分析](https://mp.weixin.qq.com/s/HuJEQsst534vjK3yb7RcAQ)
  - [Bug in ERC20 contract, transfers can be disabled](https://github.com/icon-foundation/ico/issues/3)

### A12. transferProxy-keccak256

* Description

    Both `keccak256()` and `ecrecover()` are built-in functions. `keccak256()` computes the signature of public key and `ecrecover` recovers public key with signature. If the passed value is correct, we can verify the address by these two functions. ([CVE-2018-10376](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-10376))

    ```js
    bytes32 hash = keccak256(_from,_spender,_value,nonce,name);
    if(_from != ecrecover(hash,_v,_r,_s)) revert();
    ```

    When the parameter of `ecrecover()` is incorrect, it would return the address of `0x0`. Suppose `_from` passes `0x0` address as well, the check got bypassed, meaning that anyone could transfer out the balance of `0x0` address.

* Problematic Implementation

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

* Recommended Implementation

    Handle 0x0 address in advance.

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

* List of Buggy Contracts

    * SmartMesh Token (SMT)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/transferProxy-keccak256.o.csv)

* Link

    * [New proxyOverflow Bug in Multiple ERC20 Smart Contracts (CVE-2018-10376)](https://peckshield.com/2018/04/25/proxyOverflow/)

### A13. approveProxy-keccak256

* Description

    Both `keccak256()` and `ecrecover()` are built-in functions. `keccak256()` computes the signature of public key and `ecrecover` recovers public key with signature. If the passed value is correct, we can verify the address by these two functions. ([CVE-2018-10376](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-10376))

    ```js
    bytes32 hash = keccak256(_from,_spender,_value,nonce,name);
    if(_from != ecrecover(hash,_v,_r,_s)) revert();
    ```

    When the parameter of `ecrecover()` is incorrect, it would return the address of `0x0`. Suppose `_from` passes `0x0` address as well, the check got bypassed, meaning that anyone could get approved by `0x0` address.

* Problematic Implementation

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

* Recommended Implementation

    Handle 0x0 address in advance.

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

* List of Buggy Contracts

    * SmartMesh Token (SMT)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/approveProxy-keccak256.o.csv)

* Link

    * [New proxyOverflow Bug in Multiple ERC20 Smart Contracts (CVE-2018-10376)](https://peckshield.com/2018/04/25/proxyOverflow/)

### A14. constructor-case-insensitive

* Description

  The developer made a mistake spelling the constructor's name, making it inconsistent with the contract's name such that anyone could call this function.

* Problematic Implementation 

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

* Recommended Implementation

  Change the constructor's name to `constructor`.

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

* List of Buggy Contracts

  * MORPH (MORPH) 

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/constructor-case-insensitive.o.csv)

* Link

  * [一些智能合约存在笔误，一个字母可造成代币千万市值蒸发！](https://bcsec.org/index/detail?id=157&tag=1) 

### A15. custom-fallback-bypass-ds-auth

- Description

  Token contract calls ERC223's Recommended branch code and `ds-auth` library simultaneously, thus the hacker could make use of passing custom fallback functions in ERC223 contracts along with `ds-auth` approving check. When the fallback function in ERC223 contracts gets triggered, the hacker could call the contract itself to deactivate internal authorization control.

- Problematic Implementation

  ```
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

- Recommended Implementation

  - Try to avoid the ERC223 version with `_custom_fallback` parameter. Use `tokenFallback` instead:

    ```
        ERC223Receiver receiver = ERC223Receiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
    ```

  - Do not add the contract itself to the whitelist when `ds-auth` is determing the authority:

    ```
    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        }
        ...
    }
    ```

- List of Buggy Contracts

  - ATN (ATN) （Fixed officially by adding Guard contract)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/custom-fallback-bypass-ds-auth.o.csv)

- Link

    * [ATN抵御合约攻击的报告](https://atn.io/resource/aareport.pdf)
    * [以太坊智能合约call注入攻击](https://blog.csdn.net/u011721501/article/details/80757811)
    * [New evilReflex Bug Identified in Multiple ERC20 Smart Contracts](https://peckshield.com/2018/06/23/evilReflex/)
    * [ERC223及ERC827实现代码欠缺安全考虑 —— ATN Token中的CUSTOM_CALL漏洞深入分析](https://zhuanlan.zhihu.com/p/38465008)
    * [Discussion about ERC827 Proposal Implementation](https://github.com/ethereum/EIPs/issues/827#issuecomment-399776972)
    * [ERC-223 Token Standard Proposal Draft](https://github.com/ethereum/EIPs/issues/223)

### A16. custom-call-abuse

- Description

    It is a really bad practice to allow the abuse of `CUSTOM_CALL` in token standard.

    Attackers could call any contract **in the name of vulnerable contract** with CUSTOM_CALL.

    This vulnerability will make these attacking scenarios possible:

    - Attackers could steal almost each kind of tokens belong to the vulnerable contract

    - Attackers could steal almost each kind of tokens `approved` to the vulnerable contract

    - Attackers could bypass the auth check in vulnerable contract by proxy of contract itself in special situation

    - Attackers could pass fake values as parameter to cheat with receiver contract

- Problematic Implementation

    ```js
    <receiver>.call.value(msg.value)(_data)
    ```

    ```js
    receiver.call.value(0)(byte4(keccak256(_custom_fallback)), _from, amout, data);
    ```

    Current contract implementation of ERC223 and ERC827 are affected.

- Recommended Implementation

    Use **fixed function signature** for receiver notifying. Do not abuse **CUSTOM_CALL**.

    - https://github.com/svenstucki/ERC677
    - https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC721/ERC721BasicToken.sol#L349
    - https://github.com/ConsenSys/Token-Factory/blob/master/contracts/HumanStandardToken.sol
    - https://github.com/ethereum/ethereum-org/blob/b46095815f52cf328ecf7676b2b38284d48fba58/solidity/token-advanced.sol#L138

- List of Buggy Contracts

    * TE-FOOD (TFD)

        [more...](csv/custom-call-abuse.o.csv)  

- Link

  - [ATN抵御合约攻击的报告](https://atn.io/resource/aareport.pdf)
  - [以太坊智能合约call注入攻击](https://blog.csdn.net/u011721501/article/details/80757811)
  - [ERC-223 Token Standard Proposal Draft](https://github.com/ethereum/EIPs/issues/223)

### A17. setowner-anyone

- Description

  `setOwner()` could change `owner` and only the current `owner` may call it usually. However, the snippet below allows anyone calling `setOwner()` to set contract's `owner`. ([CVE-2018-10705](https://nvd.nist.gov/vuln/detail/CVE-2018-10705))

- Problematic Implementation

  ```js
  function setOwner(address _owner) returns (bool success) {
      owner = _owner;
      return true;
  }
  ```

- Recommended Implementation

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

- List of Buggy Contracts

  - Aurora DAO (AURA)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/setowner-anyone.o.csv)

- Link

  - [New ownerAnyone Bug Allows For Anyone to ''Own'' Certain ERC20-Based Smart Contracts (CVE-2018-10705)](https://peckshield.com/2018/05/03/ownerAnyone/)

### A18. allowAnyone

* Description
  `transferFrom()` missed a check on `allowed`, then anyone could transfer balances from any accounts. A hacker could make use of it to grab others' tokens. In the mean time, if the transferred sum surpasses `allowed`, `allowed[_from][msg.sender] -= _value;` would lead to an underflow.

* Problematic Implementation

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

* Recommended Implementation

  Add `allowed` checking or compute by secure mathematical operations such as `SafeMath`.

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

* List of Buggy Contracts

  * EDUCoin

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/allowAnyone.o.csv )

* Link

  [智能合约红色预警：四个Token惊爆逻辑漏洞，归零风险或源于代码复制](https://mp.weixin.qq.com/s/lf9vXcUxdB2fGY2YVTauRQ )

 ### A19. approve-with-balance-verify

* Description

  Several Token contracts add balance check in standard `approve()` requiring `_amount` not greater than the current balance.

  In one way, this check cannot assure that the approved account would transfer out tokens of this amount:

  * The token holder transfers out tokens after approval, making the balance smaller than `allowance`.
  * After approving multiple users, one of them calls `transferFrom()` and the balance could be smaller than the approved value.

  On the another way, this check might prevent external contracts(e.g. decentralized exchanges based on 0x protocol) from normal calling, before the Token developing team transferring a tremendous amount of tokens to the intermediate account.

* Problematic Implementation

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

* Recommended Implementation

  Delete balance checking.

  ```js
  function approve(address _spender, uint _amount) returns (bool success) {
      // update allowed amount
      allowed[msg.sender][_spender] = _amount;
      // log event
      Approval(msg.sender, _spender, _amount);
      return true;
  }
  ```

* List of Buggy Contracts

  * Saint Coins (SAINT) 

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/approve-with-balance-verify.o.csv )

* Link

  [ERC20智能合约的approve千万别这样写](https://mp.weixin.qq.com/s/hYE4nu7FCD_nJH5WMRrXMA)

### A20. re-approve

- Description

  `approve()` allows the spender account using a given number of tokens by updating the value of `allowance`.

  Suppose the spender account is able to control miners' confirming order of transferring, then spender could use up all `allowance` before approve comes into effect. After `approve()` is effective, spender has access to the new allowance, causing total tokens spent greater than expected and resulting in Re-approve attack.

  This attack is only possible when the spender has approval, the approved account changes the approved amount, the balance is sufficient and the spender could control confirming order of transferring.

  It would only cause the spender using more tokens than expected or the approved tokens less than expectation, not affecting the account balance and sum of tokens.
  
- Recommended Implementation

  This issue originates from vulnerabilities in ERC20 and could be found in most contracts(List of Buggy Contracts is omitted). Please use `increaseApprove()` and `decreaseApprove()` to avoid it.

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

- Link

  - [ERC20 API: An Attack Vector on Approve/TransferFrom Methods](https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/)

## B. List of Incompatibilities

### B1. transfer-no-return

* Description

  `transfer()` should return a `bool` value according to ERC20, while it is left out in many deployed Token contracts, not following EIP20.
  Suppose an external contract following EIP20 uses an ABI interface(with a return value) to call `transfer()` without a return value, the Solidity compiler would not throw an exception in versions before 0.4.22. However, `transfer()` calls would revert after the compiler is upgraded to 0.4.22 version.

* Problematic Implementation

    ```js
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }
    ```

* Recommended Implementation

    Follow the specifications strictly when developing.

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

* List of Buggy Contracts

    * IOT on Chain (ITC)

    * BNB (BNB)

    * loopring (LRC)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/transfer-no-return.o.csv)

* Link

    * [数千份以太坊 Token 合约不兼容问题浮出水面，恐严重影响DAPP生态](https://mp.weixin.qq.com/s/1MB-t_yZYsJDTPRazD1zAA)

### B2. approve-no-return

* Description 

    `approve()` should return a `bool` value according to ERC20, while it is left out in many deployed Token contracts, not following EIP20.
    Suppose an external contract following EIP20 uses an ABI interface(with a return value) to call `approve()` without a return value, the Solidity compiler would not throw an exception in versions before 0.4.22. However, `approve()` calls would revert after the compiler is upgraded to 0.4.22 version.

* Problematic Implementation

    ```js
    function approve(address _spender, uint _value) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }
    ```

* Recommended Implementation

    Follow the specifications strictly when developing.

    ```js
    function approve(address _spender, uint _value) returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    ```

* List of Buggy Contracts

    * loopring (LRC)

    * Paymon Token (PMNT)

    * Metal(MTL)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/approve-no-return.o.csv)

* Link

    - [数千份以太坊 Token 合约不兼容问题浮出水面，恐严重影响DAPP生态](https://mp.weixin.qq.com/s/1MB-t_yZYsJDTPRazD1zAA)

### B3. transferFrom-no-return

* Description 

    `transferFrom()` should return a `bool` value according to ERC20, while it is left out in many deployed Token contracts, not following EIP20.
    Suppose an external contract following EIP20 uses an ABI interface(with a return value) to call `transferFrom()` without a return value, the Solidity compiler would not throw an exception in versions before 0.4.22. However, `transferFrom()` calls would revert after the compiler is upgraded to 0.4.22 version.

* Problematic Implementation

    ```js
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }
    ```

* Recommended Implementation 

    Follow the specifications strictly when developing.

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

* List of Buggy Contracts

    * CUBE (AUTO)

    * loopring (LRC)

    * Paymon Token (PMNT)

        [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/transferfrom-no-return.o.csv)

* Link

    - [数千份以太坊 Token 合约不兼容问题浮出水面，恐严重影响DAPP生态](https://mp.weixin.qq.com/s/1MB-t_yZYsJDTPRazD1zAA)

### B4. no-decimals

- Description

  Usually a token contract employs `decimals` to represent digits after the token's decimal point, while some of them does not define this variable properly, e.g. a case-insensitive `decimals`, making them incompatible with external contract calls.

- Problematic Implementation

  ```js
  uint8 public DECIMALS;
  ```

- Recommended Implementation

  - Turn `DECIMALS` into lowercase.

    ```js
    uint8 public decimals;
    ```

  - Add a query interface.

    ```js
    uint8 public DECIMALS;
    
    function decimals() view returns (uint8 decimals){
        return DECIMALS;
    }
    ```

- List of Buggy Contracts 

  - Loopring (LRC)

  - ICON (ICX)

  - HPBCoin (HPB)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/no-decimals.o.csv)


### B5. no-name

- Description

  Usually a token contract employs `name` as a token name, while some of them does not define this variable properly, e.g. a case-insensitive `name`, making them incompatible with external contract calls.

- Problematic Implementation

  ```js
  string public NAME;
  ```

- Recommended Implementation

  - Turn `NAME` into lowercase.

    ```js
    string public name;
    ```

  - Add a query interface.

    ```js
    string public NAME;
    function name() view returns (string name){
        return NAME;
    }
    ```

- List of Buggy Contracts 

  - Loopring (LRC)

  - ICON (ICX)

  - HPBCoin (HPB)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/no-name.o.csv)

### B6. no-symbol 

- Description

  Usually a token contract employs `symbol` as a token alias, while some of them does not define this variable properly, e.g. a case-insensitive `symbol`, making them incompatible with external contract calls.

- Problematic Implementation

  ```js
  string public SYMBOL;
  ```

- Recommended Implementation

  - Turn `SYMBOL` into lowercase.

    ```js
    string public symbol;
    ```

  - Add a query interface.

    ```js
    string public SYMBOL;
    function symbol() view returns (string symbol){
        return SYMBOL;
    }
    ```

- List of Buggy Contracts 

  - Loopring (LRC)

  - ICON (ICX)

  - HPBCoin (HPB)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/no-symbol.o.csv)

    
## C. List of Excessive Authorities

### C1. centralAccount-transfer-anyone

- Description

  `onlycentralAccount` could transfer out other account's balances randomly. ([CVE-2018-1000203](https://nvd.nist.gov/vuln/detail/CVE-2018-1000203))

- Problematic Implementation 

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

- List of Buggy Contracts

  - Soarcoin (Soar)

    [more...](https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/csv/centralAccount-transfer-anyone.o.csv) 

- Link

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
* [16] https://github.com/ConsenSys/smart-contract-best-practices Smart Contract Best Practices
* [17] https://mp.weixin.qq.com/s/lf9vXcUxdB2fGY2YVTauRQ 智能合约红色预警：四个Token惊爆逻辑漏洞，归零风险或源于代码复制. May 24, 2018.
* [18] https://mp.weixin.qq.com/s/hYE4nu7FCD_nJH5WMRrXMA ERC20智能合约的approve千万别这样写. Jun 15,2018.
* [19] https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/ ERC20 API: An Attack Vector on Approve/TransferFrom Methods.


## License

[![CC0](http://mirrors.creativecommons.org/presskit/buttons/88x31/svg/cc-zero.svg)](https://creativecommons.org/publicdomain/zero/1.0/)
