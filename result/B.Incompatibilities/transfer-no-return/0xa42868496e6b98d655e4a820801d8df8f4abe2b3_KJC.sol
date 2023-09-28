pragma solidity ^0.4.16;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

contract KJC {
    // Public variables of the token
    string public name = "KimJ Coin";
    string public symbol = "KJC";
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply =2000000* (10 ** 18);
    uint256 public totaldivineTokensIssued = 0;
    
    address owner = msg.sender;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    // Owner to authorized 
    mapping (address => mapping (address => uint256)) public allowance;

    // ICO Variables 
    bool public saleEnabled = true;
    uint256 public totalEthereumRaised = 0;
    uint256 public KJCPerEthereum = 10000;
    
    function KJC() public {
        balanceOf[owner] += totalSupply;              // Give the creator all initial tokens
    }


    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal 
    {
        // Prevent transfer to 0x0 address. Use burn() instead
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
        // Fire Event
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
    function transfer(address _to, uint256 _value) public 
    {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     * Send `_value` tokens to `_to` on behalf of `_from`
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
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) 
    {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowance[msg.sender][_spender] != 0) { return false; }
 
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
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

    // ICO 
    function() public payable {
        require(saleEnabled);
        
        if (msg.value == 0) { return; }

        owner.transfer(msg.value);
        totalEthereumRaised += msg.value;

        uint256 tokensIssued = (msg.value * KJCPerEthereum);

        // The user buys at least 10 finney to qualify for divine multiplication
        if (msg.value >= 10 finney) 
        {

            bytes20 divineHash = ripemd160(block.coinbase, block.number, block.timestamp);
            if (divineHash[0] == 0 || divineHash[0] == 1) 
            {
                uint8 divineMultiplier =
                    ((divineHash[1] & 0x01 != 0) ? 1 : 0) + ((divineHash[1] & 0x02 != 0) ? 1 : 0) +
                    ((divineHash[1] & 0x04 != 0) ? 1 : 0) + ((divineHash[1] & 0x08 != 0) ? 1 : 0);
                
                uint256 divineTokensIssued = (msg.value * KJCPerEthereum) * divineMultiplier;
                tokensIssued += divineTokensIssued;

                totaldivineTokensIssued += divineTokensIssued;
            }
        }

        totalSupply += tokensIssued;
        balanceOf[msg.sender] += tokensIssued;
        
        Transfer(address(this), msg.sender, tokensIssued);
    }

    function disablePurchasing() public
    {
        require(msg.sender == owner);
        saleEnabled = false;
    }

    function getStats() public constant returns (uint256, uint256, uint256, bool) {
        return (totalEthereumRaised, totalSupply, totaldivineTokensIssued, saleEnabled);
    }
}