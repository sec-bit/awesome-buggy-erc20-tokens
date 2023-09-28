pragma solidity ^0.4.4;

contract InsightsNetwork1 {
  address public owner;
  address public successor;
  mapping (address => uint) public balances;
  mapping (address => uint) public unlockTimes;
  bool public active;
  uint256 _totalSupply;

  string public constant name = "INS";
  string public constant symbol = "INS";
  uint8 public constant decimals = 0;

  function InsightsNetwork1() {
    owner = msg.sender;
    active = true;
  }

  function register(address newTokenHolder, uint issueAmount) {
    require(active);
    require(msg.sender == owner);
    require(balances[newTokenHolder] == 0); // Accounts can only be registered once.

    _totalSupply += issueAmount;
    Mint(newTokenHolder, issueAmount);

    require(balances[newTokenHolder] < (balances[newTokenHolder] + issueAmount));
    balances[newTokenHolder] += issueAmount;
    Transfer(address(0), newTokenHolder, issueAmount);

    uint currentTime = block.timestamp; // seconds since the Unix epoch
    uint unlockTime = currentTime + 365*24*60*60; // one year out from the current time
    assert(unlockTime > currentTime); // check for overflow
    unlockTimes[newTokenHolder] = unlockTime;
  }

  function totalSupply() constant returns (uint256) {
    return _totalSupply;
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
    return false;
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    return false;
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    return false;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return 0;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function getUnlockTime(address _accountHolder) constant returns (uint256) {
    return unlockTimes[_accountHolder];
  }

  event Mint(address indexed _to, uint256 _amount);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function makeSuccessor(address successorAddr) {
    require(active);
    require(msg.sender == owner);
    //require(successorAddr == address(0));
    successor = successorAddr;
  }

  function deactivate() {
    require(active);
    require(msg.sender == owner || (successor != address(0) && msg.sender == successor));
    active = false;
  }
}