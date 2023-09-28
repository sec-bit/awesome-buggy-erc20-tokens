pragma solidity ^0.4.16;

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

/**
 * Simple ERC20 compatible contract that allows basic operations
 * on a currency like token.
 */
contract TokenHEL20 {
    // the public variables of the token, includes things like
    // name symbol and number of decimal places
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // this creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // this generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // this notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract.
     * The token should be compatible with ERC20 https://github.com/ethereum/EIPs/issues/20.
     */
    function TokenHEL20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    /**
     * Internal transfer, only can be called by this contract.
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // prevents transfer to 0x0 address, should use burn() instead
        require(_to != 0x0);

        // checks if there's enought from the sender and
        // then checks for overflows in the target buffer
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        // saves this for an assertion in the future
        // this is basically the sum of both balances
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        // subtracts from the sender and adds the same ammount
        // to the receiver
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        // triggers the transfer event to the blockchain with
        // the description of the tranfer operation
        Transfer(_from, _to, _value);

        // asserts are used to use static analysis to find bugs in your code,
        // they should never fail under normal conditions
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account.
     *
     * @param _to The address of the recipient.
     * @param _value The amount to send.
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`.
     *
     * @param _from The address of the sender.
     * @param _to The address of the recipient.
     * @param _value The amount to send.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // checks for proper allowance and if there's enought
        // proceeds with the transfer operation
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address.
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf.
     *
     * @param _spender The address authorized to spend.
     * @param _value the max amount they can spend.
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify.
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf,
     * and then ping the contract about it.
     *
     * @param _spender The address authorized to spend.
     * @param _value The max amount they can spend.
     * @param _extraData Some extra information to send to the approved contract.
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
     * Remove `_value` tokens from the system irreversibly.
     *
     * @param _value The amount of money to burn.
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account.
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from The address of the sender.
     * @param _value The amount of money to burn.
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}