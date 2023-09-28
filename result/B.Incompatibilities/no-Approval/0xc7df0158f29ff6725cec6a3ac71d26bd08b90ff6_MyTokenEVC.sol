pragma solidity ^0.4.18;
contract owned {
    
    address _owner;
    
    function owner() public  constant returns (address) {
        return _owner;
    }
    
    function owned() public {
        _owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
    
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        _owner = _newOwner;
    }
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract MyTokenEVC is owned {
    
    // Internal variables of the token
    string  _name;
    string _symbol;
    uint8  _decimals = 18;
    uint256 _totalSupply;
    
    // This creates an array with all balances
    mapping (address => uint256)  _balanceOf;
    mapping (address => mapping (address => uint256)) _allowance;
    mapping (address => bool) _frozenAccount;
    
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    // This notifies clients frozen accounts
    event FrozenFunds(address target, bool frozen);
       
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function MyTokenEVC() public {
        
        // Update total supply with the decimal amount
        _totalSupply = 0 * 10 ** uint256(_decimals);
        
        // Give the creator all initial tokens
        _balanceOf[msg.sender] = _totalSupply;
        
        // Set the name for display purposes
        _name = "MyTokenEVC 4";   
        
        // Set the symbol for display purposes
        _symbol = "MEVC4";                    
        
    }
    
    /**
     * Returns token's name
     *
     */
    
    function name() public  constant returns (string) {
        return _name;
    }
    
    /**
     * Returns token's symbol
     *
     */
    function symbol() public constant returns (string) {
        return _symbol;
    }
    
    /**
     * Returns token's total supply
     *
     */
    function decimals() public constant returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * Returns balance of the give address
     * @param _tokenHolder Tokens holder address
     */
    function balanceOf(address _tokenHolder) public constant returns (uint256) {
        return _balanceOf[_tokenHolder];
    }
    
    /**
     * Returns allowance for the given owner and spender
     * @param _tokenOwner Tokens owner address
     * @param _spender Spender address
     */
    function allowance(address _tokenOwner, address _spender) public constant returns (uint256) {
        return _allowance[_tokenOwner][_spender];
    }
    
    /**
     * Check if the address is frozen
     * @param _account Address to be checked
     */
    function frozenAccount(address _account) public constant returns (bool) {
        return _frozenAccount[_account];
    }
    
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        
        //Check if FrozenFunds
        require(!_frozenAccount[msg.sender]);
        
        // Check if the sender has enough
        require(_balanceOf[_from] >= _value);
        
        // Check for overflows
        require(_balanceOf[_to] + _value > _balanceOf[_to]);
        
        // Save this for an assertion in the future
        uint256 previousBalances = _balanceOf[_from] + _balanceOf[_to];
        
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
        
        // Check allowance if transfer not from own
        if (msg.sender != _from) {
            require(_allowance[_from][msg.sender] >= _value);     
            _allowance[_from][msg.sender] -= _value;
        }
        
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
        
        //Check the balance
        require(_balanceOf[msg.sender] >= _value);
        
        _allowance[msg.sender][_spender] = _value;
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
    
    
    
    /**
     * @notice Destroy tokens from owener account, can be run only by owner
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        
        // Check if the targeted balance is enough
        require(_balanceOf[_owner] >= _value);
        
        // Check total Supply
        require(_totalSupply >= _value);
        // Subtract from the targeted balance and total supply
        _balanceOf[_owner] -= _value;
        _totalSupply -= _value;
        
        Burn(_owner, _value);
        return true;
        
    }
    
    /**
     * @notice Destroy tokens from other account, can be run only by owner
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        
        // Save frozen state
        bool bAccountFrozen = frozenAccount(_from);
        
        //Unfreeze account if was frozen
        if (bAccountFrozen) {
            //Allow transfers
            freezeAccount(_from,false);
        }
        
        // Transfer to owners account
        _transfer(_from, _owner, _value);
        
        //Freeze again if was frozen before
        if (bAccountFrozen) {
            freezeAccount(_from,bAccountFrozen);
        }
        
        // Burn from owners account
        burn(_value);
        
        return true;
    }
    
    /**
    * @notice Create `mintedAmount` tokens and send it to `owner`, can be run only by owner
    * @param mintedAmount the amount of tokens it will receive
    */
    function mintToken(uint256 mintedAmount) onlyOwner public {
        
        // Check for overflows
        require(_balanceOf[_owner] + mintedAmount >= _balanceOf[_owner]);
        
        // Check for overflows
        require(_totalSupply + mintedAmount >= _totalSupply);
        
        _balanceOf[_owner] += mintedAmount;
        _totalSupply += mintedAmount;
        
        Transfer(0, _owner, mintedAmount);
        
    }
    
    /**
    * @notice Freeze or unfreeze account, can be run only by owner
    * @param target Account
    * @param freeze True to freeze, False to unfreeze
    */
    function freezeAccount (address target, bool freeze) onlyOwner public {
        
        _frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
        
    }
    
}