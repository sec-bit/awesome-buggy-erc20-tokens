pragma solidity ^0.4.18;

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ArtyCoin {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    uint256 public tokensPerOneETH;
    uint256 public totalEthInWei;
    uint256 public totalETHRaised;
    uint256 public totalDeposit;
    uint256 public sellPrice;
    uint256 public buyPrice;
    address public owner; 
    
    bool public isCanSell;
    bool public isCanBuy;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function ArtyCoin(uint256 initialSupply, string tokenName, string tokenSymbol, address ownerAddress) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[ownerAddress] = totalSupply;
        owner = ownerAddress;
        name = tokenName;
        symbol = tokenSymbol;
    }
    
    function setIsTokenCanBeBuy(bool condition) onlyOwner public returns (bool success) {
        isCanBuy = condition;
        return true;
    }
    
    function setIsTokenCanBeSell(bool condition) onlyOwner public returns (bool success) {
        isCanSell = condition;
        return true;
    }
    
    function setSellPrice(uint256 newSellPrice) onlyOwner public returns (bool success) {
        require(newSellPrice > 0);
        sellPrice = newSellPrice;
        return true;
    }
    
    function setBuyPrice(uint256 newBuyPrice) onlyOwner public returns (bool success) {
        require(newBuyPrice > 0);
        buyPrice = newBuyPrice;
        return true;
    }
    
    function sellTokens(uint amount) public returns (uint revenue){
        require(isCanSell);
        require(sellPrice > 0);
        require(balanceOf[msg.sender] >= amount);
        
        uint256 divideValue = 1 * 10 ** uint256(decimals);
        
        revenue = (amount / divideValue) * sellPrice;
        require(this.balance >= revenue);
        
        balanceOf[owner] += amount;
        balanceOf[msg.sender] -= amount;
        
        msg.sender.transfer(revenue);
        
        Transfer(msg.sender, owner, amount);
        return revenue;
    }
    
    function buyTokens() payable public {
        require(msg.value > 0);
        totalEthInWei += msg.value;
        uint256 amount = msg.value * tokensPerOneETH;
        require(balanceOf[owner] >= amount);
        
        balanceOf[owner] -= amount;
        balanceOf[msg.sender] += amount;
        Transfer(owner, msg.sender, amount);

        owner.transfer(msg.value);
    }
    
    function createTokensToOwner(uint256 amount) onlyOwner public {
        require(amount > 0);
        uint256 newAmount = amount * 10 ** uint256(decimals);
        totalSupply += newAmount;
        balanceOf[owner] += newAmount;
        Transfer(0, owner, newAmount);
    }
    
    function createTokensTo(address target, uint256 mintedAmount) onlyOwner public {
        require(mintedAmount > 0);
        uint256 newAmount = mintedAmount * 10 ** uint256(decimals);
        balanceOf[target] += newAmount;
        totalSupply += newAmount;
        Transfer(0, target, newAmount);
    }
    
    function setTokensPerOneETH(uint256 value) onlyOwner public returns (bool success) {
        require(value > 0);
        tokensPerOneETH = value;
        return true;
    }
    
    function depositFunds() payable public {
        totalDeposit += msg.value;
    }
    
    function() payable public {
        require(msg.value > 0);
        totalEthInWei += msg.value;
        totalETHRaised += msg.value;
        uint256 amount = msg.value * tokensPerOneETH;
        require(balanceOf[owner] >= amount);
        
        balanceOf[owner] -= amount;
        balanceOf[msg.sender] += amount;
        Transfer(owner, msg.sender, amount);

        owner.transfer(msg.value);
    }
    
    function getMyBalance() view public returns (uint256) {
        return this.balance;
    }
    
    function withdrawEthToOwner(uint256 amount) onlyOwner public {
        require(amount > 0);
        require(this.balance >= amount);
        owner.transfer(amount);
    }
    
    function withdrawAllEthToOwner() onlyOwner public {
        require(this.balance > 0);
        owner.transfer(this.balance);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        address oldOwner = owner;
        uint256 amount = balanceOf[oldOwner];
        balanceOf[newOwner] += amount;
        balanceOf[oldOwner] -= amount;
        Transfer(oldOwner, newOwner, amount);
        owner = newOwner;
    }
    
    function sendMultipleAddress(address[] dests, uint256[] values) public returns (uint256) {
        uint256 i = 0;
        while (i < dests.length) {
            transfer(dests[i], values[i]);
            i += 1;
        }
        return i;
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
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
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
}