pragma solidity ^0.4.16;

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

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 15;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowanceEliminate;
    mapping (address => mapping (address => uint256)) public allowanceTransfer;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount Eliminatet
    event Eliminate(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use Eliminate() instead
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
        require(_value <= allowanceTransfer[_from][msg.sender]);     // Check allowance
        allowanceTransfer[_from][msg.sender] -= _value;
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
    function approveTransfer(address _spender, uint256 _value) public
        returns (bool success) {
        allowanceTransfer[msg.sender][_spender] = _value;
        return true;
    }
    
    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can Eliminate
     */
    function approveEliminate(address _spender, uint256 _value) public
        returns (bool success) {
        allowanceEliminate[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to Eliminate
     */
    function eliminate(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Eliminate(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to Eliminate
     */
    function eliminateFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                    // Check if the targeted balance is enough
        require(_value <= allowanceEliminate[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                             // Subtract from the targeted balance
        allowanceEliminate[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                                  // Update totalSupply
        Eliminate(_from, _value);
        return true;
    }
}

contract RESToken is owned, TokenERC20 {

    uint256 initialSellPrice = 1000; 
    uint256 initialBuyPrice = 1000;
    uint256 initialSupply = 8551000000; // the projected number of people in 2030
    string tokenName = "Resource";
    string tokenSymbol = "RES";

    uint256 public sellPrice; 
    uint256 public buyPrice;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function RESToken() TokenERC20(initialSupply, tokenName, tokenSymbol) public {
        sellPrice = initialSellPrice;
        buyPrice = initialBuyPrice;
        allowanceEliminate[this][msg.sender] = initialSupply / 2 * (10 ** uint256(decimals)); 
    }

    /// @notice update the price based on the remaining count of resources
    function updatePrice() public {
        sellPrice = initialSellPrice * initialSupply * (10 ** uint256(decimals)) / totalSupply;
        buyPrice = initialBuyPrice * initialSupply * (10 ** uint256(decimals)) / totalSupply;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint amount = msg.value * 1000 / buyPrice;        // calculates the amount (1 eth == 1000 finney)
        _transfer(this, msg.sender, amount);              // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice / 1000); // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);                // makes the transfers
        msg.sender.transfer(amount * sellPrice / 1000);     // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
}