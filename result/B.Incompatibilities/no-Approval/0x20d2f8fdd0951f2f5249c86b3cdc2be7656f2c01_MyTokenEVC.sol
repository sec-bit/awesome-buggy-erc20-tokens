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

contract MyTokenEVC is owned {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public _totalSupply;
    // This creates an array with all balances
    mapping (address => uint256) public _balanceOf;
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
    function MyTokenEVC() public {
        _totalSupply = 0 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        _balanceOf[msg.sender] = _totalSupply;                // Give the creator all initial tokens
        name = "MyTokenEVC 2";                                   // Set the name for display purposes
        symbol = "MEVC2";                               // Set the symbol for display purposes
    }
    
    function name() public constant returns (string) {
        return name;
    }
    
    function symbol() public constant returns (string) {
        return symbol;
    }
    
    function decimals() public constant returns (uint8) {
        return decimals;
    }
    
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenHolder) public constant returns (uint256) {
        return _balanceOf[tokenHolder];
    }
    
    mapping (address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);

    function freezeAccount (address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    
    
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(_balanceOf[_from] >= _value);
        // Check for overflows
        require(_balanceOf[_to] + _value > _balanceOf[_to]);
        //Check if FrozenFunds
        require(!frozenAccount[msg.sender]);
        // Save this for an assertion in the future
        uint previousBalances = _balanceOf[_from] + _balanceOf[_to];
        // Subtract from the sender
        _balanceOf[_from] -= _value;
        // Add the same to the recipient
        _balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(_balanceOf[_from] + _balanceOf[_to] == previousBalances);
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(_balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        _balanceOf[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                      // Updates totalSupply
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
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(_balanceOf[_from] >= _value);                // Check if the targeted balance is enough
    ///    require(_value <= allowance[_from][msg.sender]);    // Check allowance
        _balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        _totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
    /// @notice Create `mintedAmount` tokens and send it to `owner`
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(uint256 mintedAmount) onlyOwner public {
        _balanceOf[owner] += mintedAmount;
        _totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
    }
}