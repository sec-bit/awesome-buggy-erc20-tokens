pragma solidity ^0.4.18;

contract ForeignToken {
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract EIP20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract AMLOveCoin is EIP20Interface, Owned{
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalContribution = 0;
    uint februaryLastTime = 1519862399;
    uint marchLastTime = 1522540799;
    uint aprilLastTime = 1525132799;
    uint juneLastTime = 1530403199;
    modifier onlyExecuteBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }
    string public symbol;
    string public name;
    uint8 public decimals;

    function balanceOf(address _owner) public constant returns (uint256) {
      return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(msg.data.length >= (2 * 32) + 4);
        if (_value == 0) { return false; }
        uint256 fromBalance = balances[msg.sender];
        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(msg.data.length >= (2 * 32) + 4);
        if (_value == 0) { return false; }
        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];
        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];
        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    function withdrawForeignTokens(address _tokenContract) public onlyExecuteBy(owner) returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function withdraw() public onlyExecuteBy(owner) {
        owner.transfer(this.balance);
    }

    function getStats() public constant returns (uint256, uint256, bool) {
        bool purchasingAllowed = (getTime() < juneLastTime);
        return (totalContribution, totalSupply, purchasingAllowed);
    }

    function AMLOveCoin() public {
        owner = msg.sender;
        symbol = "AML";
        name = "AMLOve";
        decimals = 18;
        uint256 tokensIssued = 1300000 ether;
        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;
        Transfer(address(this), msg.sender, tokensIssued);
    }

    function() payable public {
        require(msg.value >= 1 finney);
        uint rightNow = getTime();
        require(rightNow < juneLastTime);
        owner.transfer(msg.value);
        totalContribution += msg.value;
        uint rate = 10000;
        if(rightNow < februaryLastTime){
           rate = 15000;
        } else {
           if(rightNow < marchLastTime){
              rate = 13000;
           } else {
              if(rightNow < aprilLastTime){
                 rate = 11000;
              }
           }
        }
        uint256 tokensIssued = (msg.value * rate);
        uint256 futureTokenSupply = (totalSupply + tokensIssued);
        uint256 maxSupply = 13000000 ether;
        require(futureTokenSupply < maxSupply);
        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;
        Transfer(address(this), msg.sender, tokensIssued);
    }

    function getTime() internal constant returns (uint) {
      return now;
    }
}