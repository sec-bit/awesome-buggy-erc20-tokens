pragma solidity ^0.4.10;

/* taking ideas from FirstBlood token */
contract SafeMath {

    /* function assert(bool assertion) internal { */
    /*   if (!assertion) { */
    /*     throw; */
    /*   } */
    /* }      // assert no longer needed once solidity is on 0.4.10 */

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract CryptiblesVendingContract is StandardToken, SafeMath {

    // metadata
    bool public isOpen;
    uint256 ethDivisor = 1000000000000000000;
    string version = "1.0";

    // Owner of this contract
    address public owner;
    uint256 public totalSupply;

    // contracts
    address public ethFundDeposit;      // Address to deposit ETH to. LS Address

    // crowdsale parameters
    uint256 public tokenExchangeRate = 1000000000000000000;
    StandardToken cryptiToken;

    address public currentTokenOffered = 0x16b262b66E300C7410f0771eAC29246A75fb8c48;

    // events
    event TransferCryptibles(address indexed _to, uint256 _value);
    
    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // constructor
    function CryptiblesVendingContract()
    {
      isOpen = true;
      totalSupply = 0;
      owner = msg.sender;
      cryptiToken =  StandardToken(currentTokenOffered);
    }
    
    /// @dev Accepts ether and creates new Cryptible tokens.
    function () payable {
      require(isOpen);
      require(msg.value != 0);
      
      require(cryptiToken.balanceOf(this) >= tokens);
      
      uint256 amountSent = msg.value;
      uint256 tokens = safeMult(amountSent, tokenExchangeRate) / ethDivisor; // check that we're not over totals
      totalSupply = safeAdd(totalSupply, tokens);
      cryptiToken.transfer(msg.sender, tokens);
      
      TransferCryptibles(msg.sender, tokens);  // logs token transfer
    }

    /// @dev sends the ETH home
    function finalize() onlyOwner{
      isOpen = false;
      ethFundDeposit.transfer(this.balance);  // send the eth to LS
    }

    /// @dev Allow to change the tokenExchangeRate
    function changeTokenExchangeRate(uint256 _tokenExchangeRate) onlyOwner{
        tokenExchangeRate = _tokenExchangeRate;
    }

    function setETHAddress(address _ethAddr) onlyOwner{
      ethFundDeposit = _ethAddr;
    }
    
    function getRemainingTokens(address _sendTokensTo) onlyOwner{
        require(_sendTokensTo != address(this));
        var tokensLeft = cryptiToken.balanceOf(this);
        cryptiToken.transfer(_sendTokensTo, tokensLeft);
    }

    function changeIsOpenFlag(bool _value) onlyOwner{
      isOpen = _value;
    }

    function changeCrytiblesAddress(address _newAddr) onlyOwner{
      currentTokenOffered = _newAddr;
      cryptiToken =  StandardToken(currentTokenOffered);
    }
}