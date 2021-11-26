pragma solidity ^0.4.19;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract ERC20Interface {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ERC827 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}


contract TEFoodsToken is Ownable, ERC20Interface {

  using SafeMath for uint;

  string public constant name = "TEFOOD FARM TO FORK FOOD TRACEABILITY SYSTEM LICENSE TOKEN";
  string public constant symbol = "TFOOD";
  uint8 public constant decimals = 18;
  uint constant _totalSupply = 1000000000 * 1 ether;
  uint public transferrableTime = 1521712800;
  uint _vestedSupply;
  uint _circulatingSupply;
  mapping (address => uint) balances;
  mapping (address => mapping(address => uint)) allowed;

  struct vestedBalance {
    address addr;
    uint balance;
  }
  mapping (uint => vestedBalance[]) vestingMap;



  function TEFoodsToken () public {
    owner = msg.sender;
    balances[0x00] = _totalSupply;
  }

  event VestedTokensReleased(address to, uint amount);

  function allocateTokens (address addr, uint amount) public onlyOwner returns (bool) {
    require (addr != 0x00);
    require (amount > 0);
    balances[0x00] = balances[0x00].sub(amount);
    balances[addr] = balances[addr].add(amount);
    _circulatingSupply = _circulatingSupply.add(amount);
    assert (_vestedSupply.add(_circulatingSupply).add(balances[0x00]) == _totalSupply);
    return true;
  }

  function allocateVestedTokens (address addr, uint amount, uint vestingPeriod) public onlyOwner returns (bool) {
    require (addr != 0x00);
    require (amount > 0);
    require (vestingPeriod > 0);
    balances[0x00] = balances[0x00].sub(amount);
    vestingMap[vestingPeriod].push( vestedBalance (addr,amount) );
    _vestedSupply = _vestedSupply.add(amount);
    assert (_vestedSupply.add(_circulatingSupply).add(balances[0x00]) == _totalSupply);
    return true;
  }

  function releaseVestedTokens (uint vestingPeriod) public {
    require (now >= transferrableTime.add(vestingPeriod));
    require (vestingMap[vestingPeriod].length > 0);
    require (vestingMap[vestingPeriod][0].balance > 0);
    var v = vestingMap[vestingPeriod];
    for (uint8 i = 0; i < v.length; i++) {
      balances[v[i].addr] = balances[v[i].addr].add(v[i].balance);
      _circulatingSupply = _circulatingSupply.add(v[i].balance);
      _vestedSupply = _vestedSupply.sub(v[i].balance);
      v[i].balance = 0;
      VestedTokensReleased(v[i].addr, v[i].balance);
    }
  }

  function enableTransfers () public onlyOwner returns (bool) {
    if (now.add(86400) < transferrableTime) {
      transferrableTime = now.add(86400);
    }
    owner = 0x00;
    return true;
  }

  function () public payable {
    revert();
  }

  function totalSupply() public constant returns (uint) {
    return _circulatingSupply;
  }

  function balanceOf(address tokenOwner) public constant returns (uint balance) {
    return balances[tokenOwner];
  }

  function vestedBalanceOf(address tokenOwner, uint vestingPeriod) public constant returns (uint balance) {
    var v = vestingMap[vestingPeriod];
    for (uint8 i = 0; i < v.length; i++) {
      if (v[i].addr == tokenOwner) return v[i].balance;
    }
    return 0;
  }

  function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }

  function transfer(address to, uint tokens) public returns (bool success) {
    require (now >= transferrableTime);
    require (to != address(this));
    require (balances[msg.sender] >= tokens);
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint tokens) public returns (bool success) {
    require (spender != address(this));
    allowed[msg.sender][spender] = tokens;
    Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    require (now >= transferrableTime);
    require (to != address(this));
    require (allowed[from][msg.sender] >= tokens);
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    Transfer(from, to, tokens);
    return true;
  }

}

contract TEFoods827Token is TEFoodsToken, ERC827 {

  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    super.approve(_spender, _value);
    require(_spender.call(_data));
    return true;
  }

  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    super.transfer(_to, _value);
    require(_to.call(_data));
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    super.transferFrom(_from, _to, _value);
    require(_to.call(_data));
    return true;
  }

}