pragma solidity ^0.4.18;

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title OwnableToken
 * @dev The OwnableToken contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract OwnableToken
{
    address owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The OwnableToken constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function OwnableToken() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


interface tokenRecipient
{
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

/**
 * @title ERC20
 * @dev eip20 token implementation
 */
contract ERC20 is OwnableToken
{
    using SafeMath for uint;

    uint256 constant MAX_UINT256 = 2**256 - 1;

    // Public variables of the token
    string public name;
    string public symbol;
    uint256 public decimals = 8;
    uint256 DEC = 10 ** uint256(decimals);
    uint256 public totalSupply;
    uint256 public price = 0 wei;

    // This creates an array with all balances
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function ERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public
    {
        totalSupply = initialSupply.mul(DEC);  // Update total supply with the decimal amount
        balances[msg.sender] = totalSupply;         // Give the creator all initial tokens
        name = tokenName;                      // Set the name for display purposes
        symbol = tokenSymbol;                  // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     *
     * @param _from - address of the contract
     * @param _to - address of the investor
     * @param _value - tokens for the investor
     */
    function _transfer(address _from, address _to, uint256 _value) internal
    {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to].add(_value) > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from].add(balances[_to]);
        // Subtract from the sender
        balances[_from] = balances[_from].sub(_value);
        // Add the same to the recipient
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from].add(balances[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public
    {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Balance show
     *
     * @param _holder current holder balance
     */
    function balanceOf(address _holder) view public
        returns (uint256 balance)
    {
        return balances[_holder];
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
        returns (bool success)
    {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance

        if (allowance[_from][msg.sender] < MAX_UINT256) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
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
    function approve(address _spender, uint256 _value) public
        returns (bool success)
    {
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public onlyOwner
        returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);

            return true;
        }
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue) public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);

        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
        returns (bool success)
    {
        uint oldValue = allowance[msg.sender][_spender];

        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public onlyOwner
        returns (bool success)
    {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough

        balances[msg.sender] = balances[msg.sender].sub(_value);  // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply

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
    function burnFrom(address _from, uint256 _value) public onlyOwner
        returns (bool success)
    {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance

        balances[_from] = balances[_from].sub(_value);    // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);    // Subtract from the sender's allowance
        totalSupply = totalSupply.sub(_value);              // Update totalSupply

        Burn(_from, _value);

        return true;
    }
}

contract PausebleToken is ERC20
{
    event EPause(address indexed owner, string indexed text);
    event EUnpause(address indexed owner, string indexed text);

    bool public paused = true;

    modifier isPaused()
    {
        require(paused);
        _;
    }

    function pause() public onlyOwner
    {
        paused = true;
        EPause(owner, 'sale is paused');
    }

    function pauseInternal() internal
    {
        paused = true;
        EPause(owner, 'sale is paused');
    }

    function unpause() public onlyOwner
    {
        paused = false;
        EUnpause(owner, 'sale is unpaused');
    }

    function unpauseInternal() internal
    {
        paused = false;
        EUnpause(owner, 'sale is unpaused');
    }
}

contract ERC20Extending is ERC20
{
    using SafeMath for uint;

    /**
    * Function for transfer ethereum from contract to any address
    *
    * @param _to - address of the recipient
    * @param amount - ethereum
    */
    function transferEthFromContract(address _to, uint256 amount) public onlyOwner
    {
        _to.transfer(amount);
    }

    /**
    * Function for transfer tokens from contract to any address
    *
    */
    function transferTokensFromContract(address _to, uint256 _value) public onlyOwner
    {
        _transfer(this, _to, _value);
    }
}

contract CrowdsaleContract is PausebleToken
{
    using SafeMath for uint;

    uint256 public receivedEther;  // how many weis was raised on crowdsale

    event CrowdSaleFinished(address indexed owner, string indexed text);

    struct sale {
        uint256 tokens;   // Tokens in crowdsale
        uint startDate;   // Date when crowsale will be starting, after its starting that property will be the 0
        uint endDate;     // Date when crowdsale will be stop
    }

    sale public Sales;

    uint8 public discount;  // Discount

    /*
    * Function confirm autofund
    *
    */
    function confirmSell(uint256 _amount) internal view
        returns(bool)
    {
        if (Sales.tokens < _amount) {
            return false;
        }

        return true;
    }

    /*
    *  Make discount
    */
    function countDiscount(uint256 amount) internal view
        returns(uint256)
    {
        uint256 _amount = (amount.mul(DEC)).div(price);
        _amount = _amount.add(withDiscount(_amount, discount));

        return _amount;
    }

    /** +
    * Function for change discount if need
    *
    */
    function changeDiscount(uint8 _discount) public onlyOwner
        returns (bool)
    {
        discount = _discount;
        return true;
    }

    /**
    * Function for adding discount
    *
    */
    function withDiscount(uint256 _amount, uint _percent) internal pure
        returns (uint256)
    {
        return (_amount.mul(_percent)).div(100);
    }

    /**
    * Expanding of the functionality
    *
    * @param _price in weis
    */
    function changePrice(uint256 _price) public onlyOwner
        returns (bool success)
    {
        require(_price != 0);
        price = _price;
        return true;
    }

    /*
    * Seles manager
    *
    */
    function paymentManager(uint256 value) internal
    {
        uint256 _value = (value * 10 ** uint256(decimals)) / 10 ** uint256(18);
        uint256 discountValue = countDiscount(_value);
        bool conf = confirmSell(discountValue);

        // transfer all ether to the contract

        if (conf) {

            Sales.tokens = Sales.tokens.sub(_value);
            receivedEther = receivedEther.add(value);

            if (now >= Sales.endDate) {
                pauseInternal();
                CrowdSaleFinished(owner, 'crowdsale is finished');
            }

        } else {

            Sales.tokens = Sales.tokens.sub(Sales.tokens);
            receivedEther = receivedEther.add(value);

            pauseInternal();
            CrowdSaleFinished(owner, 'crowdsale is finished');
        }
    }

    function transfertWDiscount(address _spender, uint256 amount) public onlyOwner
        returns(bool)
    {
        uint256 _amount = (amount.mul(DEC)).div(price);
        _amount = _amount.add(withDiscount(_amount, discount));
        transfer(_spender, _amount);

        return true;
    }

    /*
    * Function for start crowdsale (any)
    *
    * @param _tokens - How much tokens will have the crowdsale - amount humanlike value (10000)
    * @param _startDate - When crowdsale will be start - unix timestamp (1512231703 )
    * @param _endDate - When crowdsale will be end - humanlike value (7) same as 7 days
    */
    function startCrowd(uint256 _tokens, uint _startDate, uint _endDate) public onlyOwner
    {
        Sales = sale (_tokens * DEC, _startDate, _startDate + _endDate * 1 days);
        unpauseInternal();
    }

}

contract TokenContract is ERC20Extending, CrowdsaleContract
{
    /* Constructor */
    function TokenContract() public
        ERC20(10000000000, "Debit Coin", "DEBC") {}

    /**
    * Function payments handler
    *
    */
    function () public payable
    {
        assert(msg.value >= 1 ether / 100);
        require(now >= Sales.startDate);

        if (paused == false) {
            paymentManager(msg.value);
        } else {
            revert();
        }
    }
}