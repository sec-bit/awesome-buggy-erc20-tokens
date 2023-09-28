contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        if (balancesVersions[version].balances[msg.sender] >= _value && balancesVersions[version].balances[_to] + _value > balancesVersions[version].balances[_to]) {
        //if (balancesVersions[version].balances[msg.sender] >= _value && _value > 0) {
            balancesVersions[version].balances[msg.sender] -= _value;
            balancesVersions[version].balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balancesVersions[version].balances[_from] >= _value && allowedVersions[version].allowed[_from][msg.sender] >= _value && balancesVersions[version].balances[_to] + _value > balancesVersions[version].balances[_to]) {
        //if (balancesVersions[version].balances[_from] >= _value && allowedVersions[version].allowed[_from][msg.sender] >= _value && _value > 0) {
            balancesVersions[version].balances[_to] += _value;
            balancesVersions[version].balances[_from] -= _value;
            allowedVersions[version].allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balancesVersions[version].balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowedVersions[version].allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowedVersions[version].allowed[_owner][_spender];
    }

    //this is so we can reset the balances while keeping track of old versions
    uint public version = 0;

    struct BalanceStruct {
      mapping(address => uint256) balances;
    }
    mapping(uint => BalanceStruct) balancesVersions;

    struct AllowedStruct {
      mapping (address => mapping (address => uint256)) allowed;
    }
    mapping(uint => AllowedStruct) allowedVersions;

    uint256 public totalSupply;

}

contract ReserveToken is StandardToken {
    address public minter;
    function setMinter() {
        if (minter==0x0000000000000000000000000000000000000000) {
            minter = msg.sender;
        }
    }
    modifier onlyMinter { if (msg.sender == minter) _ }
    function create(address account, uint amount) onlyMinter {
        balancesVersions[version].balances[account] += amount;
        totalSupply += amount;
    }
    function destroy(address account, uint amount) onlyMinter {
        if (balancesVersions[version].balances[account] < amount) throw;
        balancesVersions[version].balances[account] -= amount;
        totalSupply -= amount;
    }
    function reset() onlyMinter {
        version++;
        totalSupply = 0;
    }
}

contract EtherDelta {

  mapping (address => mapping (address => uint)) tokens; //mapping of token addresses to mapping of account balances
  //ether balances are held in the token=0 account
  mapping (bytes32 => uint) orderFills;
  address public feeAccount;
  uint public feeMake; //percentage times (1 ether)
  uint public feeTake; //percentage times (1 ether)

  event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);

  function EtherDelta(address feeAccount_, uint feeMake_, uint feeTake_) {
    feeAccount = feeAccount_;
    feeMake = feeMake_;
    feeTake = feeTake_;
  }

  function() {
    throw;
  }

  function deposit() {
    tokens[0][msg.sender] += msg.value;
    Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

  function withdraw(uint amount) {
    if (msg.value>0) throw;
    if (tokens[0][msg.sender] < amount) throw;
    tokens[0][msg.sender] -= amount;
    if (!msg.sender.call.value(amount)()) throw;
    Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
  }

  function depositToken(address token, uint amount) {
    //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
    if (msg.value>0 || token==0) throw;
    if (!Token(token).transferFrom(msg.sender, this, amount)) throw;
    tokens[token][msg.sender] += amount;
    Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function withdrawToken(address token, uint amount) {
    if (msg.value>0 || token==0) throw;
    if (tokens[token][msg.sender] < amount) throw;
    tokens[token][msg.sender] -= amount;
    if (!Token(token).transfer(msg.sender, amount)) throw;
    Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function balanceOf(address token, address user) constant returns (uint) {
    return tokens[token][user];
  }

  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) {
    if (msg.value>0) throw;
    Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
  }

  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) {
    //amount is in amountGet terms
    if (msg.value>0) throw;
    bytes32 hash = sha256(tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(
      ecrecover(hash,v,r,s) == user &&
      block.number <= expires &&
      orderFills[hash] + amount <= amountGet &&
      tokens[tokenGet][msg.sender] >= amount &&
      tokens[tokenGive][user] >= amountGive * amount / amountGet
    )) throw;
    tokens[tokenGet][msg.sender] -= amount;
    tokens[tokenGet][user] += amount * ((1 ether) - feeMake) / (1 ether);
    tokens[tokenGet][feeAccount] += amount * feeMake / (1 ether);
    tokens[tokenGive][user] -= amountGive * amount / amountGet;
    tokens[tokenGive][msg.sender] += ((1 ether) - feeTake) * amountGive * amount / amountGet / (1 ether);
    tokens[tokenGive][feeAccount] += feeTake * amountGive * amount / amountGet / (1 ether);
    orderFills[hash] += amount;
    Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender);
  }

  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) constant returns(bool) {
    if (!(
      tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
    )) return false;
    return true;
  }

  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint) {
    bytes32 hash = sha256(tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    if (!(
      ecrecover(hash,v,r,s) == user &&
      block.number <= expires
    )) return 0;
    uint available1 = amountGet - orderFills[hash];
    uint available2 = tokens[tokenGive][user] * amountGet / amountGive;
    if (available1<available2) return available1;
    return available2;
  }
}