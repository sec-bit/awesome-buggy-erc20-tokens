pragma solidity ^0.4.0;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract MyFirstEthereumToken {
    // The keyword "public" makes those variables
    // readable from outside.
    address public owner;
	// Public variables of the token
    string public name = "MyFirstEthereumToken";
    string public symbol = "MFET";
    uint8 public decimals = 18;	// 18 decimals is the strongly suggested default, avoid changing it
 
    uint256 public totalSupply; 
	uint256 public totalExtraTokens = 0;
	uint256 public totalContributed = 0;
	
	bool public onSale = false;

	/* This creates an array with all balances */
    mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowance;

    // Events allow light clients to react on
    // changes efficiently.
    event Sent(address from, address to, uint amount);
	// This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);	
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

	function name() public constant returns (string) { return name; }
    function symbol() public constant returns (string) { return symbol; }
    function decimals() public constant returns (uint8) { return decimals; }
	function totalSupply() public constant returns (uint256) { return totalSupply; }
	function balanceOf(address _owner) public constant returns (uint256) { return balances[_owner]; }
	
    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function MyFirstEthereumToken(uint256 initialSupply) public payable
	{
		owner = msg.sender;
		
		// Update total supply with the decimal amount
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
		//totalSupply = initialSupply;  
		// Give the creator all initial tokens
        balances[msg.sender] = totalSupply; 
		// Give the creator all initial tokens		
        //balanceOf[msg.sender] = initialSupply;  
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success)
	{
        return _transfer(msg.sender, _to, _value);
    }
	
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal returns (bool success)
	{
		// mitigates the ERC20 short address attack
		//require(msg.data.length >= (2 * 32) + 4);
		// checks for minimum transfer amount
		require(_value > 0);
		// Prevent transfer to 0x0 address. Use burn() instead  
        require(_to != 0x0);	      
		// Check if the sender has enough
        require(balances[_from] >= _value);	
		// Check for overflows
        require(balances[_to] + _value > balances[_to]);	// Check for overflows
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
		// Call for Event
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
		
		return true;
    }

    /**
     * Send tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function send(address _to, uint256 _value) public 
	{
        _send(_to, _value);
    }
	
    /**
     * Internal send, only can be called by this contract
     */
    function _send(address _to, uint256 _value) internal 
	{	
		address _from = msg.sender;
		
		// mitigates the ERC20 short address attack
		//require(msg.data.length >= (2 * 32) + 4);
		// checks for minimum transfer amount
		require(_value > 0);
		// Prevent transfer to 0x0 address. Use burn() instead  
        require(_to != 0x0);	      
		// Check if the sender has enough
        require(balances[_from] >= _value);	
		// Check for overflows
        require(balances[_to] + _value > balances[_to]);	// Check for overflows
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
		// Call for Event
        Sent(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }

   /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) 
	{
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) 
	{
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
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
     * Create tokens
     *
     * Create `_amount` tokens to `owner` account
     *
     * @param _amount the amount to create
     */	
    function createTokens(uint256 _amount) public
	{
	    require(msg.sender == owner);
        //if (msg.sender != owner) return;
        
        balances[owner] += _amount; 
        totalSupply += _amount;
		
        Transfer(0, owner, _amount);
    }

	/**
     * Withdraw funds
     *
     * Transfers the total amount of funds to ownwer account minus gas fee
     *
     */	
    function safeWithdrawAll() public returns (bool)
	{
	    require(msg.sender == owner);
		
		uint256 _gasPrice = 30000000000;
		
		require(this.balance > _gasPrice);
		
		uint256 _totalAmount = this.balance - _gasPrice;
		
		owner.transfer(_totalAmount);
		
		return true;
    }
	
	/**
     * Withdraw funds
     *
     * Create `_amount` tokens to `owner` account
     *
     * @param _amount the amount to create
     */	
    function safeWithdraw(uint256 _amount) public returns (bool)
	{
	    require(msg.sender == owner);
		
		uint256 _gasPrice = 30000000000;
		
		require(_amount > 0);
		
		uint256 totalAmount = _amount + _gasPrice; 
		
		require(this.balance >= totalAmount);
		
		owner.transfer(totalAmount);
		
		return true;
    }
    
	function getBalanceContract() public constant returns(uint)
	{
		require(msg.sender == owner);
		
        return this.balance;
    }
	
	/**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
	
	// A function to buy tokens accesible by any address
	// The payable keyword allows the contract to accept ethers
	// from the transactor. The ethers to be deposited is entered as msg.value
	// (which will get clearer when we will call the functions in browser-solidity)
	// and the corresponding tokens are stored in balance[msg.sender] mapping.
	// underflows and overflows are security consideration which are
	// not checked in the process. But lets not worry about them for now.

	function buyTokens () public payable 
	{
		// checks for minimum transfer amount
		require(msg.value > 0);
		
		require(onSale == true);
		
		owner.transfer(msg.value);
			
		totalContributed += msg.value;
		
		uint256 tokensAmount = msg.value * 1000;
		
		if(totalContributed >= 1 ether)
		{
			
			uint256 multiplier = (totalContributed / 1 ether);
			
			uint256 extraTokens = (tokensAmount * multiplier) / 10;
			
			totalExtraTokens += extraTokens;
			
			tokensAmount += extraTokens;
		}
			
		balances[msg.sender] += tokensAmount;
		
		totalSupply += tokensAmount;
        
        Transfer(address(this), msg.sender, tokensAmount);
	}
	
	/**
     * EnableSale Function
     *
     */	
	function enableSale() public
	{
		require(msg.sender == owner);

        onSale = true;
    }
	
	/**
     * DisableSale Function
     *
     */	
	function disableSale() public 
	{
		require(msg.sender == owner);

        onSale = false;
    }
	
    /**
     * Kill Function
     *
     */	
    function kill() public
	{
	    require(msg.sender == owner);
	
		onSale = false;
	
        selfdestruct(owner);
    }
	
    /**
     * Fallback Function
     *
     */	
	function() public payable 
	{
		buyTokens();
		//totalContributed += msg.value;
	}
}