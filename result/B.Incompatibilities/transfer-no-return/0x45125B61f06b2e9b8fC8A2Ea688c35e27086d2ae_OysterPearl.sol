pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract OysterPearl {
    // Public variables of PRL
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
    uint256 public epoch;
    uint256 public retentionMax;

    // This creates an array with all balances
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public buried;
    mapping (address => uint256) public claimed;

    // ERC20 event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    // ERC20 event
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    // This notifies clients about the an address getting buried
    event Bury(address indexed target, uint256 value);
    
    // This notifies clients about a claim being made on a buried address
    event Claim(address indexed target, address indexed payout, address indexed fee);

    /**
     * Constructor function
     *
     * Initializes contract
     */
    function OysterPearl() public {
        director = msg.sender;
        name = "Oyster Pearl";
        symbol = "TSPRL";
        decimals = 18;
        funds = 0;
        totalSupply = 0;
        saleClosed = true;
        directorLock = false;
        
        // Marketing share (5%)
        totalSupply += 25000000 * 10 ** uint256(decimals);
        
        // Devfund share (15%)
        totalSupply += 75000000 * 10 ** uint256(decimals);
        
        // Allocation to match PREPRL supply
        totalSupply += 1000000 * 10 ** uint256(decimals);
        
        // Assign reserved PRL supply to contract owner
        balances[director] = totalSupply;
        
        //define default values for Oyster functions
        claimAmount = 5 * 10 ** (uint256(decimals) - 1);
        payAmount = 4 * 10 ** (uint256(decimals) - 1);
        feeAmount = 1 * 10 ** (uint256(decimals) - 1);
        
        //seconds in a year
        epoch = 31536001;
        
        //Maximum time for a sector to remain stored
        retentionMax = 40 * 10 ** uint256(decimals);
    }
    
    /**
     * ERC20 function
     */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    modifier onlyDirector {
        // Owner can lock themselves out to complete decentralization of Oyster network
        require(!directorLock);
        
        // Lockout will occur eventually, guaranteeing Oyster decentralization
        require(block.number < 8000000);
        
        // Only the contract owner is permitted
        require(msg.sender == director);
        _;
    }
    
    modifier onlyDirectorForce {
        // Only the contract owner is permitted
        require(msg.sender == director);
        _;
    }
    
    /**
     * Transfers the contract owner to a new address
     */
    function transferDirector(address newDirector) public onlyDirectorForce {
        director = newDirector;
    }
    
    /**
     * Withdraw funds from the crowdsale
     */
    function withdrawFunds() public onlyDirectorForce {
        director.transfer(this.balance);
    }
    
    /**
     * Permanently lock out the contract owner to decentralize Oyster
     */
    function selfLock() public onlyDirector {
        // The sale must be closed before the owner gets locked out
        require(saleClosed);
        
        // Permanently lock out the contract owner
        directorLock = true;
    }
    
    /**
     * Contract owner can alter the storage-peg and broker fees
     */
    function amendClaim(uint8 claimAmountSet, uint8 payAmountSet, uint8 feeAmountSet) public onlyDirector {
        require(claimAmountSet == (payAmountSet + feeAmountSet));
        
        claimAmount = claimAmountSet * 10 ** (uint256(decimals) - 1);
        payAmount = payAmountSet * 10 ** (uint256(decimals) - 1);
        feeAmount = feeAmountSet * 10 ** (uint256(decimals) - 1);
    }
    
    /**
     * Contract owner can alter the epoch time
     */
    function amendEpoch(uint256 epochSet) public onlyDirector {
        // Set the epoch
        epoch = epochSet;
    }
    
    /**
     * Contract owner can alter the maximum storage retention
     */
    function amendRetention(uint8 retentionSet) public onlyDirector {
        // Set RetentionMax
        retentionMax = retentionSet * 10 ** uint256(decimals);
    }
    
    /**
     * Director can close the crowdsale
     */
    function closeSale() public onlyDirector {
        // The sale must be currently open
        require(!saleClosed);
        
        // Lock the crowdsale
        saleClosed = true;
    }

    /**
     * Director can open the crowdsale
     */
    function openSale() public onlyDirector {
        // The sale must be currently closed
        require(saleClosed);
        
        // Unlock the crowdsale
        saleClosed = false;
    }
    
    /**
     * Oyster Protocol Function
     * More information at https://oyster.ws/OysterWhitepaper.pdf
     * 
     * Bury an address
     *
     * When an address is buried; only claimAmount can be withdrawn once per epoch
     *
     */
    function bury() public {
        // The address must be previously unburied
        require(!buried[msg.sender]);
        
        // An address must have atleast claimAmount to be buried
        require(balances[msg.sender] > claimAmount);
        
        // Prevent addresses with large balances from getting buried
        require(balances[msg.sender] <= retentionMax);
        
        // Set buried state to true
        buried[msg.sender] = true;
        
        // Set the initial claim clock to 1
        claimed[msg.sender] = 1;
        
        // Execute an event reflecting the change
        Bury(msg.sender, balances[msg.sender]);
    }
    
    /**
     * Oyster Protocol Function
     * More information at https://oyster.ws/OysterWhitepaper.pdf
     * 
     * Claim PRL from a buried address
     *
     * If a prior claim wasn't made during the current epoch
     *
     * @param _payout The address of the recipient
     * @param _fee the amount to send
     */
    function claim(address _payout, address _fee) public {
        // The claimed address must have already been buried
        require(buried[msg.sender]);
        
        // The payout and fee addresses must be different
        require(_payout != _fee);
        
        // The claimed address cannot pay itself
        require(msg.sender != _payout);
        
        // The claimed address cannot pay itself
        require(msg.sender != _fee);
        
        // It must be either the first time this address is being claimed or atleast epoch in time has passed
        require(claimed[msg.sender] == 1 || (block.timestamp - claimed[msg.sender]) >= epoch);
        
        // Check if the buried address has enough
        require(balances[msg.sender] >= claimAmount);
        
        // Reset the claim clock to the current time
        claimed[msg.sender] = block.timestamp;
        
        // Save this for an assertion in the future
        uint256 previousBalances = balances[msg.sender] + balances[_payout] + balances[_fee];
        
        // Remove claimAmount from the buried address
        balances[msg.sender] -= claimAmount;
        
        // Pay the website owner that invoked the webnode that found the PRL seed key
        balances[_payout] += payAmount;
        
        // Pay the broker node that unlocked the PRL
        balances[_fee] += feeAmount;
        
        // Execute events to reflect the changes
        Transfer(msg.sender, _payout, payAmount);
        Transfer(msg.sender, _fee, feeAmount);
        Claim(msg.sender, _payout, _fee);
        
        // Asserts are used to use static analysis to find bugs in your code, they should never fail
        assert(balances[msg.sender] + balances[_payout] + balances[_fee] == previousBalances);
    }
    
    /**
     * Crowdsale function
     */
    function () payable public {
        // Check if crowdsale is still active
        require(!saleClosed);
        
        // Minimum amount is 1 finney
        require(msg.value >= 1 finney);
        
        // Price is 1 ETH = 5000 PRL
        uint256 amount = msg.value * 5000;
        
        // totalSupply limit is 500 million PRL
        require(totalSupply + amount <= (500000000 * 10 ** uint256(decimals)));
        
        // Increases the total supply
        totalSupply += amount;
        
        // Adds the amount to buyer's balance
        balances[msg.sender] += amount;
        
        // Track ETH amount raised
        funds += msg.value;
        
        // Execute an event reflecting the change
        Transfer(this, msg.sender, amount);
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Sending addresses cannot be buried
        require(!buried[_from]);
        
        // If the receiving addresse is buried, it cannot exceed retentionMax
        if (buried[_to]) {
            require(balances[_to] + _value <= retentionMax);
        }
        
        // Prevent transfer to 0x0 address. Use burn() instead
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
        
        // Asserts are used to use static analysis to find bugs in your code, they should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
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
        // Check allowance
        require(_value <= allowance[_from][msg.sender]);
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
        // Buried addresses cannot be approved
        require(!buried[_spender]);
        
        allowance[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
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
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
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