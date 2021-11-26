pragma solidity ^0.4.18;

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
contract TokenERC20 is owned {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    
    uint256 public totalSupply;
    uint public amountRaised;

    uint256 public sellPrice;
    uint256 public buyPrice;
    bool public lockedSell;
    
    bytes32 public currentChallenge;
    uint public timeOfLastProof;
    uint public difficulty = 10**32;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address from, uint256 amount);
    event UnFreeze(address to, uint256 amount);
        
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol, uint256 newSellPrice, uint256 newBuyPrice) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        name = tokenName;                                   
        symbol = tokenSymbol;                               
        owner = msg.sender;
        timeOfLastProof = now;
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        lockedSell = true;
    }

    function emission(uint256 amount) onlyOwner public {
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
    } 
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    function buy() public payable returns (uint amount) {
        amount = (msg.value * 10 ** uint256(decimals)) / buyPrice;
        require(balanceOf[owner] >= amount);               
        balanceOf[msg.sender] += amount;                  
        balanceOf[owner] -= amount;                        
        amountRaised += msg.value;
        Transfer(owner, msg.sender, amount);               
        return amount;                                    
    }

    function sell(uint amount) public returns (uint revenue) {
        require(!lockedSell);
        require(balanceOf[msg.sender] >= amount);         
        balanceOf[owner] += amount;                        
        balanceOf[msg.sender] -= amount;  
        revenue = amount * sellPrice / 10 ** uint256(decimals);
        amountRaised -= revenue;
        require(msg.sender.send(revenue));                
        Transfer(msg.sender, owner, amount);               
        return revenue;                                   
    }

    function lockSell(bool value) onlyOwner public {
        lockedSell = value;
    }

    function proofOfWork(uint nonce) public {
        bytes8 n = bytes8(keccak256(nonce, currentChallenge));    
        require(n >= bytes8(difficulty));                   

        uint timeSinceLastProof = (now - timeOfLastProof);  
        require(timeSinceLastProof >= 5 seconds);         
        balanceOf[msg.sender] += timeSinceLastProof / 60 seconds;  

        difficulty = difficulty * 10 minutes / timeSinceLastProof + 1;  

        timeOfLastProof = now;                              
        currentChallenge = keccak256(nonce, currentChallenge, block.blockhash(block.number - 1));  
    }
    
    function _transfer(address from, address to, uint amount) internal {
        require(to != 0x0);
        require(balanceOf[from] >= amount);
        require(balanceOf[to] + amount > balanceOf[to]);
        uint previousBalances = balanceOf[from] + balanceOf[to];
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        Transfer(from, to, amount);
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
    }
    
    function transfer(address to, uint256 amount) public {
        _transfer(msg.sender, to, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
        require(amount <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    
    function burn(uint256 amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= amount);   
        balanceOf[msg.sender] -= amount;            
        totalSupply -= amount;                      
        Burn(msg.sender, amount);
        return true;
    }

    function burnFrom(address from, uint256 amount) public returns (bool success) {
        require(balanceOf[from] >= amount);
        require(amount <= allowance[from][msg.sender]);
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        totalSupply -= amount;
        Burn(from, amount);
        return true;
    }

    function withdrawRaised(uint amount) onlyOwner public {
        require(amountRaised >= amount);
        if (owner.send(amount))
            amountRaised -= amount;
    }

    function freeze(address from, uint256 amount) onlyOwner public returns (bool success){
        require(amount <= allowance[from][this]);
        allowance[from][this] -= amount;
        _transfer(from, this, amount);
        Freeze(from, amount);
        return true;
    }

    function unFreeze(address to, uint256 amount) onlyOwner public returns (bool success){
        _transfer(this, to, amount);
        UnFreeze(to, amount);
        return true;
    }
}