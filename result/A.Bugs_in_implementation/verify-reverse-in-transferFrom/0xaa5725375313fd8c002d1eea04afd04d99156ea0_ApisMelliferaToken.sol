pragma solidity ^0.4.10;

contract ERC20Interface {
    uint public totalSupply;
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Administrable {
    address admin;
    bool public inMaintenance;
    
    function Administrable() {
        admin = msg.sender;
        inMaintenance = true;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    modifier checkMaintenance() {
        require(!inMaintenance);
        _;
    }
    
    function setMaintenance(bool inMaintenance_) onlyAdmin {
        inMaintenance = inMaintenance_;
    }
    
    function kill() onlyAdmin {
        selfdestruct(admin);
    }
}

contract ApisMelliferaToken is ERC20Interface, Administrable {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;


    string public constant name = "Apis Mellifera Token";
    string public constant symbol = "APIS";
    uint8 public constant decimals = 18;
    
    function balanceOf(address _owner) constant returns (uint256) { 
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (2 * 32) + 4) { 
            throw;
        }

        if (_value == 0) { 
            return false;
        }

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        
        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false; 
            
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (3 * 32) + 4) { 
            throw;
        }

        if (_value == 0) {
            return false;
        }
        
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
        } else { 
            return false;
        }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) {
            return false;
        }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function withdraw(uint amount) onlyAdmin {
        admin.transfer(amount);
    }

    function mint(uint amount) onlyAdmin {
        totalSupply += amount;
        balances[msg.sender] += amount;
        Transfer(address(this), msg.sender, amount);
    }

    function() payable checkMaintenance {
        if (msg.value == 0) {
            return;
        }
        uint tokens = msg.value * 1000;
        totalSupply += tokens;
        balances[msg.sender] += tokens;
        Transfer(address(this), msg.sender, tokens);
    }
}