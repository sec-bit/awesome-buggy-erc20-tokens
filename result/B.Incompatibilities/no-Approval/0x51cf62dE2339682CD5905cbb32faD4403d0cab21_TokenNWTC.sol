pragma solidity ^0.4.11;

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

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint8 decimalPalces
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimalPalces);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalPalces;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);        
        require(balanceOf[_from] >= _value);        
        require(balanceOf[_to] + _value > balanceOf[_to]);        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];        
        balanceOf[_from] -= _value;        
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     * Send `_value` tokens to `_to` from your account     
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     * Send `_value` tokens to `_to` in behalf of `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     * Remove `_value` tokens from the system irreversibly
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*     UTILITY FUNCTIONS STARTS HERE      */
/******************************************/

contract utility
{
    event check1(uint256 val1);
    function calculateEthers(uint numberOfTokens, uint price, uint _decimalValue) constant internal returns(uint ethers)
    {
        ethers = numberOfTokens*price;
        ethers = ethers / 10**_decimalValue;
        check1(ethers);
        return (ethers);
    }
    
    function calculateTokens(uint _amount, uint _rate, uint _decimalValue) constant internal returns(uint tokens, uint excessEthers) 
    {
        tokens = _amount*10**_decimalValue;
        tokens = tokens/_rate;
        excessEthers = _amount-((tokens*_rate)/10**_decimalValue);
        return (tokens, excessEthers);
    } 
    
   
    function decimalAdjustment(uint _amount, uint _decimalPlaces) constant internal returns(uint adjustedValue)
    {
        uint diff = 18-_decimalPlaces;
        uint adjust = 1*10**diff;
       
        adjustedValue = _amount/adjust;
       
        return adjustedValue;       
    }
   
    // function ceil(uint a, uint m) constant returns (uint ) {
    //     return ((a + m - 1) / m) * m;
    // }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract TokenNWTC is owned, TokenERC20, utility {
    
    event check(uint256 val1);
    
    uint256 public sellPrice;
    uint256 public buyPrice;
    address[] frzAcc;
    address[] users;
    address[] frzAcc1;
    address[] users1;
    uint256 sellTokenAmount;

    bool emergencyFreeze;       // If this variable is true then all account will be frozen and can not transfer/recieve tokens.

    mapping (address => bool) public frozenAccount;
    mapping (uint => address) public tokenUsers;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function TokenNWTC(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint8 decimalPalces
    ) TokenERC20(initialSupply, tokenName, tokenSymbol, decimalPalces) public {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        require(!emergencyFreeze);                          // Check if emergencyFreeze enable  // by JD.
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        Transfer(_from, _to, _value);
        sellTokenAmount += _value;
        
        if (users.length>0){
                uint count=0;
            for (uint a=0;a<users.length;a++)
            {
            if (users[a]==_to){
            count=count+1;
            }
            }
            if (count==0){
                users.push(_to);
            }
                 
        }
        else{
            users.push(_to);
        }
    }
    

    // @notice Create `mintedAmount` tokens and send it to `target`
    // @param target Address to receive the tokens
    // @param mintedAmount the amount of tokens it will receive
    // amount should be in form of decimal specified in this contract.
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        //require(target!=0x0);
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
        sellTokenAmount += mintedAmount;
        
         if (users.length>0){
                uint count1=0;
            for (uint a=0;a<users.length;a++)
            {
            if (users[a]==target){
            count1=count1+1;
            }
            }
            if (count1==0){
                users.push(target);
            }
                 
        }
        else{
            users.push(target);
        }
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        //require(target!=0x0);
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
        if (frzAcc.length>0){
                uint count=0;
            for (uint a=0;a<frzAcc.length;a++)
            {
            if (frzAcc[a]==target){
            count=count+1;
            }
            }
            if (count==0){
                frzAcc.push(target);
            }
        }
        else{
            frzAcc.push(target);
        }
    }

    function freezeAllAccountInEmergency(bool freezeAll) onlyOwner public
    {
        emergencyFreeze = freezeAll;    
    }

    /// notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        require(newSellPrice!=0 || sellPrice!=0);
        require(newBuyPrice!=0 || buyPrice!=0); 
        if(newSellPrice!=0)
        {
            sellPrice = newSellPrice;
        }
        if(newBuyPrice!=0)
        {
            buyPrice = newBuyPrice;
        }
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        require(msg.value!=0);
        require(buyPrice!=0);
        uint exceededEthers;
        uint amount = msg.value;                                // msg.value will be in wei.   
        (amount, exceededEthers) = calculateTokens(amount, buyPrice, decimals);
        require(amount!=0);
        _transfer(this, msg.sender, amount);              // makes the transfers.
        msg.sender.transfer(exceededEthers);// sends exceeded ether to the seller.
        
       // addUsers(msg.sender);
        
        if (users.length>0){
                uint count=0;
            for (uint a=0;a<users.length;a++)
            {
            if (users[a]==msg.sender){
            count=count+1;
            }
            }
            if (count==0){
                users.push(msg.sender);
            }
                 
        }
        else{
            users.push(msg.sender);
        }
        
        
    }

    // @notice Sell `amount` tokens to contract
    // @param amount amount of tokens to be sold
    // amount should be in form of decimal specified in this contract. 
    function sell(uint256 amount) public {
        require(amount!=0);
        require(sellPrice!=0);
        uint etherAmount;
        etherAmount = calculateEthers(amount, sellPrice, decimals);
        require(this.balance >= etherAmount);           // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);     // makes the transfers
        check(etherAmount);
        msg.sender.transfer(etherAmount);               // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }


    function readAllUsers()constant returns(address[]){
	      
	      
	          for (uint k=0;k<users.length;k++){
	              if (balanceOf[users[k]]>0){
	                  users1.push(users[k]);
	              }
	          }
	      
       return users1;
   }
   
   function readAllFrzAcc()constant returns(address[]){
       for (uint k=0;k<frzAcc.length;k++){
	              if (frozenAccount[frzAcc[k]] == true){
	                  frzAcc1.push(frzAcc[k]);
	              }
	          }
       return frzAcc1;
   }
   
   function readSellTokenAmount()constant returns(uint256){
       return sellTokenAmount;
   }
   
   
//   function addUsers(address add) internal{
//       uint totalUsers = totalUsers+1;
//       tokenUsers[totalUsers] = add;
//   }
   
//     function transfer1(address _to, uint256 _value){

// 		// if(frozenAccount[msg.sender]) throw;
// 		                     // Check if sender is frozen
//         require(!frozenAccount[_to]);                       // Check if recipient is frozen
//         require(!emergencyFreeze); 
// 		require(!frozenAccount[msg.sender]);
// 		// if(balanceOf[msg.sender] < _value) throw;
// 		require(balanceOf[msg.sender] >= _value);
// 		// if(balanceOf[_to] + _value < balanceOf[_to]) throw;
// 		require(balanceOf[_to] + _value >= balanceOf[_to]);
// 		//if(admin)

// 		balanceOf[msg.sender] -= _value;
// 		balanceOf[_to] += _value;
// 		Transfer(msg.sender, _to, _value);
// 	}

// 	function transferFrom1(address _from, address _to, uint256 _value) returns (bool success){
// 		// if(frozenAccount[_from]) throw;
// 		require(!frozenAccount[_from]);
// 		// if(balanceOf[_from] < _value) throw;
// 		require(balanceOf[_from] >= _value);
// 		// if(balanceOf[_to] + _value < balanceOf[_to]) throw;
// 		require(balanceOf[_to] + _value >= balanceOf[_to]);
// 		// if(_value > allowance[_from][msg.sender]) throw;
// 		require(_value <= allowance[_from][msg.sender]);
// 		balanceOf[_from] -= _value;
// 		balanceOf[_to] += _value;
// 		allowance[_from][msg.sender] -= _value;
// 		Transfer(_from, _to, _value);
// 		return true;

// 	}

    /**
     * Set allowance for other address
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     * Remove `_value` tokens from the system irreversibly
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
    
    //======================================================
    function getTokenName() constant public returns (string)
    {
        return name;
    }
    
    //========================================================
    function getTokenSymbol() constant public returns (string)
    {
        return symbol;
    }

    //===========================================================
    function getSpecifiedDecimal() constant public returns (uint)
    {
        return decimals;
    }

    //======================================================
    function getTotalSupply() constant public returns (uint)
    {
        return totalSupply;
    }
    
}