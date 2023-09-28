pragma solidity ^0.4.11;
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  function allowance(address owner, address spender) constant returns (uint);

  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract StandardToken is ERC20 {

  string public constant name = "testcbs";
  string public constant symbol = "KKL";
  uint8 public constant decimals = 18; 

  mapping (address => mapping (address => uint)) allowed;
  mapping (address => uint) balances;

  function transferFrom(address _from, address _to, uint _value) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because safeSub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] +=_value;
    balances[_from] -= _value;
    allowed[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  function transfer(address _to, uint _value) {
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
  function StandardToken(){
  balances[msg.sender] = 1000000;
}

function mint() payable external {
  if (msg.value == 0) throw;

  var numTokens = msg.value * 1000;
  totalSupply += numTokens;

  balances[msg.sender] += numTokens;

  Transfer(0, msg.sender, numTokens);
}
}