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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract BalToken is owned {
    string public name;                 // Name of the Token
    string public symbol;               // Symbol of the Token
    uint8 public decimals = 18;         // Decimal Places for the token
    uint256 public totalSupply;         // Total Supply of the token

    struct frozenInfo {
        bool frozen;                    // Frozen state of the account
        uint till;                      // The timestamp account will be frozen till
    }
    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;

    // This creates an array with all allowances
    mapping (address => mapping (address => uint256)) public allowance;

    // This creates and array with all Frozen accounts with time limit
    mapping (address => frozenInfo) public frozenAccount;
    
    // This generates a public event on the blockchain that will notify clients
    event FrozenFunds(address target, bool frozen, uint till);

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function BalToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public 
    {
        totalSupply = initialSupply * 10 ** uint256(decimals);      // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                        // Give the creator all initial tokens
        name = tokenName;                                           // Set the name for display purposes
        symbol = tokenSymbol;                                       // Set the symbol for display purposes
    }

    /**
     * Function for other contracts to call to get balances of individual accounts
     */
    function getBalanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOf[_owner];
    }    

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                           // Prevent transfer to 0x0 address.
        require (_to != address(this));                                 // Prevent transfer back to this contract
        require (balanceOf[_from] >= _value);                           // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]);             // Check for overflows
        require(!(frozenAccount[_from].frozen));                        // Check if sender is frozen
        require(!(frozenAccount[_to].frozen));                          // Check if recipient is frozen
        uint previousBalances = balanceOf[_from] + balanceOf[_to];      // Save this value for assertion

        balanceOf[_from] -= _value;                                     // Subtract from the sender
        balanceOf[_to] += _value;                                       // Add the same to the recipient
        Transfer(_from, _to, _value);                                   // Transfer the token from _from to _to for the amount of _value
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);  // Asserts that the previous value matches the current value 
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
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value; // Subtract from the 
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /// @notice `freeze? Prevent` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param till Timestamp frozen till
    function freezeAccount(address target, uint till) onlyOwner public {
        require(!frozenAccount[target].frozen); 

        frozenInfo memory fi = frozenInfo(true, till);
        frozenAccount[target] = fi;
        FrozenFunds(target, true, till);

    }

    /// @notice `unfreeze? Allows` `target` from sending & receiving tokens
    /// @param target Address to be unfrozen
    function unfreezeAccount(address target) onlyOwner public {
        require(frozenAccount[target].frozen);
        require(frozenAccount[target].till < now);
        
        frozenInfo memory fi = frozenInfo(false, 0);
        frozenAccount[target] = fi;
        FrozenFunds(target, false, 0);
    }
}