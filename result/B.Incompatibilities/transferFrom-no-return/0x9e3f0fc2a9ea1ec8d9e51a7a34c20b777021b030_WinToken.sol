pragma solidity ^0.4.8;

contract OwnedByWinsome {

  address public owner;
  mapping (address => bool) allowedWorker;

  function initOwnership(address _owner, address _worker) internal{
    owner = _owner;
    allowedWorker[_owner] = true;
    allowedWorker[_worker] = true;
  }

  function allowWorker(address _new_worker) onlyOwner{
    allowedWorker[_new_worker] = true;
  }
  function removeWorker(address _old_worker) onlyOwner{
    allowedWorker[_old_worker] = false;
  }
  function changeOwner(address _new_owner) onlyOwner{
    owner = _new_owner;
  }
						    
  modifier onlyAllowedWorker{
    if (!allowedWorker[msg.sender]){
      throw;
    }
    _;
  }

  modifier onlyOwner{
    if (msg.sender != owner){
      throw;
    }
    _;
  }

  
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


/*
 * Basic token
 * Basic version of StandardToken, with no allowances
 */
contract BasicToken {
  using SafeMath for uint;
  event Transfer(address indexed from, address indexed to, uint value);
  mapping(address => uint) balances;
  uint public     totalSupply =    0;    			 // Total supply of 500 million Tokens
  
  /*
   * Fix for the ERC20 short address attack  
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
}


contract StandardToken is BasicToken{
  
  event Approval(address indexed owner, address indexed spender, uint value);

  
  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


contract WinToken is StandardToken, OwnedByWinsome{

  string public   name =           "Winsome.io Token";
  string public   symbol =         "WIN";
  uint public     decimals =       18;
  
  mapping (address => bool) allowedMinter;

  function WinToken(address _owner){
    allowedMinter[_owner] = true;
    initOwnership(_owner, _owner);
  }

  function allowMinter(address _new_minter) onlyOwner{
    allowedMinter[_new_minter] = true;
  }
  function removeMinter(address _old_minter) onlyOwner{
    allowedMinter[_old_minter] = false;
  }

  modifier onlyAllowedMinter{
    if (!allowedMinter[msg.sender]){
      throw;
    }
    _;
  }
  function mintTokens(address _for, uint _value_wei) onlyAllowedMinter {
    balances[_for] = balances[_for].add(_value_wei);
    totalSupply = totalSupply.add(_value_wei) ;
    Transfer(address(0), _for, _value_wei);
  }
  function destroyTokens(address _for, uint _value_wei) onlyAllowedMinter {
    balances[_for] = balances[_for].sub(_value_wei);
    totalSupply = totalSupply.sub(_value_wei);
    Transfer(_for, address(0), _value_wei);    
  }
  
}