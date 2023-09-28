//sol MyAdvancedToken8
pragma solidity ^0.4.18;
// Peter's "tik", "TIK", "TiTok" - Token Contract IL MARE FILM, MyAdvancedToken8, 25th July 2017

contract MyAdvancedToken8  {
    address public owner;
    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Deposit(address from, uint256 value);


    /* Public variables of the token */
    string public standard = 'ERC-Token 1.0';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    

    function transferOwnership(address newOwner) public {
        if (msg.sender != owner) revert();
        owner = newOwner;
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public 
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyAdvancedToken8(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) public
    {
        owner = msg.sender;
        
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }
    
    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows
        if (frozenAccount[msg.sender]) revert();                // Check if frozen
        balanceOf[msg.sender] -= _value;                        // Subtract from the sender
        balanceOf[_to] += _value;                               // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                      // Notify anyone listening that this transfer took place
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (frozenAccount[_from]) revert();                        // Check if frozen            
        if (balanceOf[_from] < _value) revert();                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert();   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) public {
        if (msg.sender != owner) revert();
        
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) public {
        if (msg.sender != owner) revert();
        
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public {
        if (msg.sender != owner) revert();
        
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable public {
        uint amount = msg.value / buyPrice;                // calculates the amount
        if (balanceOf[this] < amount) revert();             // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                   // adds the amount to buyer's balance
        balanceOf[this] -= amount;                         // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);                // execute an event reflecting the change
    }

    function sell(uint256 amount) public {
        bool sendSUCCESS = false;
        if (balanceOf[msg.sender] < amount ) revert();        // checks if the sender has enough to sell
        balanceOf[this] += amount;                         // adds the amount to owner's balance
        balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller's balance
        
        
        sendSUCCESS = msg.sender.send(amount * sellPrice);
        if (!sendSUCCESS) {                                     // sends ether to the seller. It's important
            revert();                                           // to do this last to avoid recursion attacks
        } else {
            Transfer(msg.sender, this, amount);                 // executes an event reflecting on the change
        }               
    }
    
    // gets called when no other function matches
	function() payable public {
		// just being sent some cash?
		if (msg.value > 0)
			Deposit(msg.sender, msg.value);
	}
    
    
}