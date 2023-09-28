pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract AnovaBace is owned{
   
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    uint256 public totalSupply;
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint minBalanceForAccounts;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    
    function AnovaBace(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address centralMinter
    ) public {
        if(centralMinter != 0) owner = centralMinter;
        totalSupply = initialSupply * 10 ** uint256(decimals); 
        balanceOf[msg.sender] = totalSupply;                
        name = tokenName;                                 
        symbol = tokenSymbol;                              
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

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
        if(_to.balance<minBalanceForAccounts)
            _to.transfer(sell((minBalanceForAccounts - _to.balance) / sellPrice));
    }

    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
        
        
    }

    
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

      
   
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        Burn(msg.sender, _value);
        return true;
    }

    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balanceOf[_from] -= _value;                      
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                             
        Burn(_from, _value);
        return true;
    }
    
        function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }
    
        function buy() payable returns (uint amount){
        amount = msg.value / buyPrice;                    
        require(balanceOf[this] >= amount);               
        balanceOf[msg.sender] += amount;                  
        balanceOf[this] -= amount;                        
        Transfer(this, msg.sender, amount);               
        return amount;                                    
    }

    function sell(uint amount) returns (uint revenue){
        require(balanceOf[msg.sender] >= amount);         
        balanceOf[this] += amount;                        
        balanceOf[msg.sender] -= amount;                  
        revenue = amount * sellPrice;
        require(msg.sender.send(revenue)); 
        Transfer(msg.sender, this, amount);                            
        return revenue;                                   
    }
    
    function setMinBalance(uint minimumBalanceInFinney) onlyOwner {
         minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }
}