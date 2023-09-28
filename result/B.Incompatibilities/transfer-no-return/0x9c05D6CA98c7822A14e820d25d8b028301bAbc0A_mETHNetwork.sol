pragma solidity ^0.4.19;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract mETHNetwork {
    // Public variables of METH
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public funds;
    address public director;
    bool public saleClosed;
    bool public directorLock;
    uint256 public claimAmount;
    uint256 public payAmount;
    uint256 public feeAmount;

    // Array definitions
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public buried;
    mapping (address => uint256) public claimed;

    // ERC20 event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    // ERC20 event
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed _from, uint256 _value);
    
    // This notifies clients about a claim being made on a buried address
    event Claim(address indexed _target, address indexed _payout, address indexed _fee);

    /**
     * Constructor function
     *
     * Initializes contract
     */
    function mETHNetwork() public {
        director = msg.sender;
        name = "mETH";
        symbol = "METH";
        decimals = 10;
        saleClosed = true;
        directorLock = false;
        funds = 0;
        totalSupply = 0;
        
        }
    
    /**
     * ERC20 balance function
     */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    modifier onlyDirector {
        // Director can lock themselves out to complete decentralization of mETH network
        // An alternative is that another smart contract could become the decentralized director
        require(!directorLock);
        
        // Only the director is permitted
        require(msg.sender == director);
        _;
    }
    
    modifier onlyDirectorForce {
        // Only the director is permitted
        require(msg.sender == director);
        _;
    }
    
    /**
     * Transfers the director to a new address
     */
    function transferDirector(address newDirector) public onlyDirectorForce {
        director = newDirector;
    }
    
    /**
     * Withdraw funds from the contract
     */
    function withdrawFunds() public onlyDirectorForce {
        director.transfer(this.balance);
    }
    
    /**
     * Director can close the contribution
     */
    function closeSale() public onlyDirector returns (bool success) {
        // The sale must be currently open
        require(!saleClosed);
        
        // Lock the crowdsale
        saleClosed = true;
        return true;
    }

    /**
     * Director can open the contribution
     */
    function openSale() public onlyDirector returns (bool success) {
        // The sale must be currently closed
        require(saleClosed);
        
        // Unlock the contribution
        saleClosed = false;
        return true;
    }
 
    /**
     * contribution function
     */
    function () public payable {
        // Check if contribution is still active
        require(!saleClosed);
        
        // Price is 1 ETH = 100000000 mETH
        uint256 amount = msg.value * 100000000;
        
        // totalSupply limit is 9 billion mETH
        require(totalSupply + amount <= (9000000000 * 10 ** uint256(decimals)));
        
        // Increases the total supply
        totalSupply += amount;
        
        // Adds the amount to the balance
        balances[msg.sender] += amount;
        
        // Track ETH amount raised
        funds += msg.value;
        
        // Execute an event reflecting the change
        Transfer(this, msg.sender, amount);
    }

    /**
     * Internal transfer, can be called by this contract only
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Sending addresses cannot be buried
        require(!buried[_from]);
        

        
        // Prevent transfer to 0x0 address, use burn() instead
        require(_to != 0x0);
        
        // Check if the sender has enough
        require(balances[_from] >= _value);
        
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        
        // Save this for an assertion in the future
        uint256 previousBalances = balances[_from] + balances[_to];
        
        // Subtract from the sender
        balances[_from] -= _value;
        
        // Add the same to the recipient
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        
        // Failsafe logic that should never be false
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to the address of the recipient
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
     * @param _from the address of the sender
     * @param _to the address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Check allowance
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender the address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // Buried addresses cannot be approved
        require(!buried[msg.sender]);
        
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender the address authorized to spend
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
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        // Buried addresses cannot be burnt
        require(!buried[msg.sender]);
        
        // Check if the sender has enough
        require(balances[msg.sender] >= _value);
        
        // Subtract from the sender
        balances[msg.sender] -= _value;
        
        // Updates totalSupply
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        // Buried addresses cannot be burnt
        require(!buried[_from]);
        
        // Check if the targeted balance is enough
        require(balances[_from] >= _value);
        
        // Check allowance
        require(_value <= allowance[_from][msg.sender]);
        
        // Subtract from the targeted balance
        balances[_from] -= _value;
        
        // Subtract from the sender's allowance
        allowance[_from][msg.sender] -= _value;
        
        // Update totalSupply
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}