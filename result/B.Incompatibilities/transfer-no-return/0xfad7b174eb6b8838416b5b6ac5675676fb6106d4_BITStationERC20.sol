pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract BITStationERC20  {
    // Public variables of the token
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals = 7;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
	bool public isLocked;
	//uint private lockTime;
	//uint public lockDays;
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
	mapping (address => bool) public whiteList;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

	
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function  BITStationERC20() public {
        totalSupply = 120000000000000000;  // Update total supply with the decimal amount
        balanceOf[msg.sender] = 120000000000000000;                // Give the creator all initial tokens
		owner = msg.sender;
        name = "BIT Station";                                   // Set the name for display purposes
        symbol = "BSTN";                               // Set the symbol for display purposes
        isLocked=true;
		//lockTime=now;
		//lockDays=lockdays;
		whiteList[owner]=true;
    }
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
  
	function transferOwnership(address newOwner) onlyOwner public{
    if (newOwner != address(0)) {
      owner = newOwner;
	  whiteList[owner]=true;
    }
  }
	/*
	modifier disableLock() 
	{ 
		if (now >= lockTime+ lockDays *1 days )
		{
			if(isLocked)
				isLocked=!isLocked;
		}	
		_; 
	}
	*/
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(!isLocked||whiteList[msg.sender]);
		require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
		
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public 
	returns (bool success) {
		require(!isLocked||whiteList[msg.sender]);
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public 
        returns (bool success) {
		require(!isLocked);
        allowance[msg.sender][_spender] = _value;
        return true;
        }
	function addWhiteList(address _value) public onlyOwner
	    {
		    whiteList[_value]=true;
	    }
	function delFromWhiteList(address _value) public onlyOwner
	    {
	    	whiteList[_value]=false;	
	    }
	
    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public 
        returns (bool success) {
		require(!isLocked);
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
	function changeAssetsState(bool _value) public
	returns (bool success){
    	require(msg.sender==owner);
	    isLocked =_value;
	    return true;
	}
}