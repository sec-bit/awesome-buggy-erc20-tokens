pragma solidity ^0.4.18;

contract Owner {
    address public owner;
    modifier onlyOwner { require(msg.sender == owner); _;}
    function Owner() public { owner = msg.sender; }
}

contract ERC20Basic{
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event onTransfer(address indexed from, address indexed to, uint256 value);
}

/* contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
} */

contract LajoinCoin is ERC20Basic, Owner {

  string public name;
  string public symbol;
  uint8 public decimals;
  mapping(address => uint256) balances;

  struct FrozenToken {
    bool isFrozenAll;
    uint256 amount;
    uint256 unfrozenDate;
  }
  mapping(address => FrozenToken) frozenTokens;

  event onFrozenAccount(address target,bool freeze);
  event onFrozenToken(address target,uint256 amount,uint256 unforzenDate);

  function LajoinCoin(uint256 initialSupply,string tokenName,string tokenSymbol,uint8 decimalUnits) public {
    balances[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    name = tokenName;
    decimals = decimalUnits;
    symbol = tokenSymbol;
  }

  function changeOwner(address newOwner) onlyOwner public {
    balances[newOwner] += balances[msg.sender];
    balances[msg.sender] = 0;
    owner = newOwner;
  }

  function freezeAccount(address target,bool freeze) onlyOwner public {
      frozenTokens[target].isFrozenAll = freeze;
      onFrozenAccount(target, freeze);
  }

  function freezeToken(address target,uint256 amount,uint256 date)  onlyOwner public {
      require(amount > 0);
      require(date > now);
      frozenTokens[target].amount = amount;
      frozenTokens[target].unfrozenDate = date;

      onFrozenToken(target,amount,date);
  }

  function transfer(address to,uint256 value) public returns (bool) {
    require(msg.sender != to);
    require(value > 0);
    require(balances[msg.sender] >= value);
    require(frozenTokens[msg.sender].isFrozenAll != true);

    if(frozenTokens[msg.sender].unfrozenDate > now){
        require(balances[msg.sender] - value >= frozenTokens[msg.sender].amount);
    }

    balances[msg.sender] -= value;
    balances[to] += value;
    onTransfer(msg.sender,to,value);

    return true;
  }

  function balanceOf(address addr) public constant returns (uint256) {
    return balances[addr];
  }

  function kill() public {
    if(owner == msg.sender){
        selfdestruct(owner);
    }
  }
}