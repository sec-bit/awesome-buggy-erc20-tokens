pragma solidity ^0.4.19;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 constant public decimals = 18;
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
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
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
     * Send `_value` tokens to `_to` on behalf of `_from`
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
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
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

contract OwnableToken is TokenERC20 {
    address public owner;

    function OwnableToken(uint256 initialSupply, string tokenName, string tokenSymbol) public TokenERC20(initialSupply, tokenName, tokenSymbol) {
        owner = msg.sender;
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract StoppableToken is OwnableToken {
    bool public stopped;
    function StoppableToken(uint256 initialSupply, string tokenName, string tokenSymbol) public OwnableToken(initialSupply, tokenName, tokenSymbol) {
        stopped = false;
    }

    function stop() public onlyOwner {
        require(stopped == false);
        stopped = true;
    }

    function resume() public onlyOwner {
        require(stopped == true);
        stopped = false;
    }
    
    function transfer(address to, uint256 value) public {
        require(stopped == false);
        super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(stopped == false);
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        require(stopped == false);
        return super.approve(spender, value);
    }

    function burn(uint256 value) public onlyOwner returns (bool success) {
        return super.burn(value);
    }

    function burnFrom(address from, uint256 value) public onlyOwner returns (bool success) {
        return super.burnFrom(from, value);
    }
}

contract CTToken is StoppableToken {
    // Token constants
    uint256 constant CTTOKEN_TOTAL_SUPLY = 20000000000; // total 20 billion
    string constant CTTOKEN_NAME = "CrypTube";
    string constant CTTOKEN_SYMBOL = "CTUBE";
    // Lock constants
    uint256 constant OWNER_LOCKED_BALANCE_RELEASE_PERIOD_LEN_IN_SEC = 180 days;
    uint16 constant OWNER_LOCKED_BALANCE_TOTAL_RELEASE_TIMES = 4;
    uint256 constant OWNER_LOCKED_BALANCE_RELEASE_NUM_PER_TIMES = 750000000;

    uint256 public ownerLockedBalance;
    uint256 public tokenCreateUtcTimeInSec;

    function CTToken() public StoppableToken(CTTOKEN_TOTAL_SUPLY, CTTOKEN_NAME, CTTOKEN_SYMBOL) {
        tokenCreateUtcTimeInSec = block.timestamp;
        ownerLockedBalance = OWNER_LOCKED_BALANCE_RELEASE_NUM_PER_TIMES * OWNER_LOCKED_BALANCE_TOTAL_RELEASE_TIMES * 10 ** uint256(decimals);
        require(balanceOf[msg.sender] >= ownerLockedBalance);
        balanceOf[msg.sender] -= ownerLockedBalance;
    }

    // refuse any payment
    function () public {
        revert();
    }

    function time() public view returns (uint) {
        return block.timestamp;
    }

    function unlockToken() public onlyOwner {
        require(ownerLockedBalance > 0);
        require(block.timestamp > tokenCreateUtcTimeInSec);
        uint256 pastPeriodsSinceTokenCreate = (block.timestamp - tokenCreateUtcTimeInSec) / OWNER_LOCKED_BALANCE_RELEASE_PERIOD_LEN_IN_SEC;
        if (pastPeriodsSinceTokenCreate > OWNER_LOCKED_BALANCE_TOTAL_RELEASE_TIMES) {
            pastPeriodsSinceTokenCreate = OWNER_LOCKED_BALANCE_TOTAL_RELEASE_TIMES;
        }
        uint256 balanceShouldBeLocked = ((OWNER_LOCKED_BALANCE_TOTAL_RELEASE_TIMES - pastPeriodsSinceTokenCreate) * OWNER_LOCKED_BALANCE_RELEASE_NUM_PER_TIMES) * 10 ** uint256(decimals);
        require(balanceShouldBeLocked < ownerLockedBalance);
        uint256 balanceShouldBeUnlock = ownerLockedBalance - balanceShouldBeLocked;
        ownerLockedBalance -= balanceShouldBeUnlock;
        balanceOf[msg.sender] += balanceShouldBeUnlock;
    }
}