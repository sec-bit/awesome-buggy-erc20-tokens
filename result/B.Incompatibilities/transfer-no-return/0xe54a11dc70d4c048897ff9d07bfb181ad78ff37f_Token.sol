pragma solidity ^0.4.18;


contract Owned {
    address public owner;
    function Owned() public {
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


interface tokenRecipient { function receiveApproval(address _from, uint _value, address _token, bytes _extraData) public; }


contract TokenBase is Owned {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public totalSupply;
    uint public tokenUnit = 10 ** uint(decimals);
    uint public wanUnit = 10000 * tokenUnit;
    uint public foundingTime;

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);

    function TokenBase() public {
        foundingTime = now;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}



contract Token is TokenBase {
    uint public initialSupply = 0 * wanUnit;
    uint public reserveSupply = 10000 * wanUnit;
    uint public sellSupply = 0 * wanUnit;

    function Token() public {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        name = "LXB";
        symbol = "LXB";
    }

    function releaseReserve(uint value) onlyOwner public {
        require(reserveSupply >= value);
        balanceOf[owner] += value;
        totalSupply += value;
        reserveSupply -= value;
        Transfer(0, this, value);
        Transfer(this, owner, value);
    }

    function releaseSell(uint value) onlyOwner public {
        require(sellSupply >= value);
        balanceOf[owner] += value;
        totalSupply += value;
        sellSupply -= value;
        Transfer(0, this, value);
        Transfer(this, owner, value);
    }
}