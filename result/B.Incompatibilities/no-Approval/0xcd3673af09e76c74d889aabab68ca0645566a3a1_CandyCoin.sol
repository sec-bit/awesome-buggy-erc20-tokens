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

contract CandyCoin is owned {
    // Public variables of the token
    string public name = "Unicorn Candy Coin";
    string public symbol = "Candy";
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply = 12000000000000000000000000;
    address public crowdsaleContract;

    uint sendingBanPeriod = 1519776000;           // 28.02.2018

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    modifier canSend() {
        require ( msg.sender == owner ||  now > sendingBanPeriod || msg.sender == crowdsaleContract);
        _;
    }
    
    /**
     * Constrctor function
     */
    function CandyCoin(
    ) public {
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
    }
    
    function setCrowdsaleContract(address contractAddress) onlyOwner {
        crowdsaleContract = contractAddress;
    }
     
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
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
    function transfer(address _to, uint256 _value) public canSend {
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
    function transferFrom(address _from, address _to, uint256 _value) public canSend returns (bool success) {
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
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
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
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}


contract CandySale is owned {
    
    address public teamWallet = address(0x7Bd19c5Fa45c5631Aa7EFE2Bf8Aa6c220272694F);

    uint public fundingGoal;
    uint public amountRaised;
    // sale periods
    uint public beginTime = now;
    uint public stage2BeginTime = 1517529600;   // 2.02.2018 
    uint public stage3BeginTime = 1518393600;   // 12.02.2018
    uint public stage4BeginTime = 1519257600;   // 22.02.2018 
    uint public endTime = 1519776000;           // 28.02.2018

    CandyCoin public tokenReward;

    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function CandySale(
        CandyCoin addressOfTokenUsedAsReward
    ) {
        tokenReward = addressOfTokenUsedAsReward;
    }
    
    // withdraw tokens from contract
    function withdrawTokens() onlyOwner {
        tokenReward.transfer(msg.sender, tokenReward.balanceOf(this));
        FundTransfer(msg.sender, tokenReward.balanceOf(this), false);
    }

    function currentPrice() constant returns (uint) {
        if ( now <= stage2BeginTime ) return 100 szabo;
        if ( now > stage2BeginTime && now <= stage3BeginTime) return 500 szabo;
        if ( now > stage3BeginTime && now <= stage4BeginTime) return 1000 szabo;
        if ( now > stage4BeginTime ) return 1500 szabo;
    }
    
    // low level token purchase function
    function buyTokens(address beneficiary) payable {
        require(msg.value > 0);
        uint amount = msg.value;
        amountRaised += amount;
        tokenReward.transfer(beneficiary, amount*1000000000000000000/currentPrice());
        FundTransfer(beneficiary, amount, true);
        teamWallet.transfer(msg.value);

    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable onlyCrowdsalePeriod {
        buyTokens(msg.sender);
    }

    modifier onlyCrowdsalePeriod() { 
        require ( now >= beginTime && now <= endTime ) ;
        _; 
    }

    

}