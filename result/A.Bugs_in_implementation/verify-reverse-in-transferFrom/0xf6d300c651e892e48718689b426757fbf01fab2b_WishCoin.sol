pragma solidity ^0.4.10;

contract WishCoin 
{
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    uint256 public supply;
    
    uint256 public cryptaurus;
    uint256 public wishes;
    bool public ICO;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function WishCoin() 
    {
        owner = msg.sender;
        supply = 0; 
        name = "WishCoin";     
        symbol = "WISH";
        decimals = 8;
        cryptaurus = 0;
        wishes = 0;
        ICO = true;
    }
    
    function balanceOf(address _owner) constant returns (uint256) 
    { 
        return balances[_owner]; 
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) 
    {
        if(msg.data.length < (2 * 32) + 4) 
        { 
            throw; 
        }

        if (_value == 0) 
        { 
            return false; 
        }

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        
        if (sufficientFunds && !overflowed) 
        {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true;
        } 
        else 
        { 
            return false; 
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) 
    {
        if(msg.data.length < (3 * 32) + 4) 
        { 
            throw; 
        }

        if (_value == 0) 
        { 
            return false; 
        }
        
        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) 
        {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            allowed[_from][msg.sender] -= _value;
            
            Transfer(_from, _to, _value);
            return true;
        } 
        else 
        { 
            return false;
        }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) 
    {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) 
        { 
            return false; 
        }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256) 
    {
        return allowed[_owner][_spender];
    }

    

    /*Some magic you won't understand*/
    function UseWish(string _words) returns (bool success) 
    {
        uint256 length = bytes(_words).length;
        bool sufficientFunds = balances[msg.sender] >= 100000000;
        if(sufficientFunds)
        {
            uint256 ExecutableMagicNumber = length * 77 + 8;    //Providing magic to the words
            ExecutableMagicNumber -= 13;                        //Clearing evilness of the words
            ExecutableMagicNumber -= length - 5;                //Protecting WishCoin from influence of the words
            cryptaurus = ExecutableMagicNumber;                 //Executing magic words
            balances[msg.sender] -= 100000000;
            supply -= 100000000;
            wishes += 1;
            return true;
        }
        else
        {
            return false;
        }
    }

    function StopICO()
    {
        if (msg.sender != owner) 
        { 
            throw; 
        }
        ICO = false;
    }
    
    function Buy() payable
    {
        if(msg.value < 2000000000000000) 
        { 
            throw; 
        }
        owner.transfer(msg.value);
        if(ICO)
        {
            uint256 amount = (msg.value / 20000000) + ((1000000 * wishes) * ((msg.value / 20000000) / 100000000));
            supply += amount;
            balances[msg.sender] += amount;
            Transfer(this, msg.sender, amount);
        }
    }
}