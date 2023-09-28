// TheCoin token
// ERC20 Compatible
// https://github.com/ethereum/EIPs/issues/20


pragma solidity ^0.4.2;
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;  
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalTokens;
    mapping (address => uint256) public balance;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);

    function token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balance[msg.sender] = initialSupply;        
        totalTokens = initialSupply;                     
        name = tokenName;                              
        symbol = tokenSymbol;                             
        decimals = decimalUnits;                           
    }

    function transfer(address _to, uint256 _value) returns (bool success){
        if (balance[msg.sender] < _value) throw;     
        if (balance[_to] + _value < balance[_to]) throw; 
        balance[msg.sender] -= _value;                     
        balance[_to] += _value;                      
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        tokenRecipient spender = tokenRecipient(_spender);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balance[_from] < _value) throw;         
        if (balance[_to] + _value < balance[_to]) throw;  
        if (_value > allowance[_from][msg.sender]) throw; 
        balance[_from] -= _value;                  
        balance[_to] += _value;                       
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
}

contract TheCoin is owned, token {
    uint256 public buyPrice; 
    uint256 public totalTokens;
    uint256 public komission; 
    bool public crowdsale;
    mapping (address => bool) public frozenAccountProfit; 
    mapping (address => uint) public frozenProfitDate; 
    event FrozenProfit(address target, bool frozen);

    function TheCoin(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        address centralMinter
    ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {
        if(centralMinter != 0 ) owner = centralMinter;   
        balance[this] = initialSupply;               
	komission = 10;
	crowdsale = true;
	buyPrice = 50000000;
    }

    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        tokenRecipient spender = tokenRecipient(_spender);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balance[_from] < _value) throw;         
        if (balance[_to] + _value < balance[_to]) throw;  
        if (_value > allowance[_from][msg.sender]) throw; 
        balance[_from] -= _value;                  
        balance[_to] += _value;                       
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
    uint256 kom;
	kom = (_value * komission) / 1000;			
	if (kom < 1) kom = 1;				
        if (balance[msg.sender] > (_value + kom) && (_value + kom) > 0) {         
        balance[msg.sender] -= (_value + kom);                  
        balance[_to] += _value;                                               
        balance[this] += kom;                           
        Transfer(msg.sender, _to, (_value));
        return true;
        } else { 
         return false;
      }
    }

    function saleover() onlyOwner{
	crowdsale = false;
        }

    function getreward() returns (bool success) {
        uint256 reward;
        reward = (balance[this] * balance[msg.sender]) / totalTokens; 
    if (frozenAccountProfit[msg.sender] == true && frozenProfitDate[msg.sender] + 3 days > now) {
	return false;
        } else {
    if (reward < 1) reward = 1; 
    if (balance[this] < reward) throw;  
    balance[msg.sender] += reward; 
    balance[this] -= reward; 
    frozenAccountProfit[msg.sender] = true;  
    frozenProfitDate[msg.sender] = now;    
    Transfer(this, msg.sender, (reward));     
    return true;
	 }
    }

    function buy() payable returns (bool success) {
	if (!crowdsale) {return false;} 
	else {  
	uint amount = msg.value / buyPrice;                
        totalTokens += amount;                          
        balance[msg.sender] += amount;                   
        Transfer(this, msg.sender, amount); 
	return true; }            
    }

    function fund (uint256 amount) onlyOwner {
        if (!msg.sender.send(amount)) {                      		
          throw;                                         
        } else {
            Transfer(this, msg.sender, amount);            
        }               
    }

    function totalSupply() external constant returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) external constant returns (uint256) {
        return balance[_owner];
    }

    function () payable {
	if (!crowdsale) {throw;} 
	else {  
	uint amount = msg.value / buyPrice;                
        totalTokens += amount;                          
        balance[msg.sender] += amount;                   
        Transfer(this, msg.sender, amount); 
	 }               
    }
}