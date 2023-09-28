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

contract TokenERC20 {
    // Public variables of the token
    string  public name;
    string  public symbol;
    uint8   public decimals = 18;     // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // Constructor function.  Initializes contract with initial supply tokens to the creator of the contract
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply             = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender]   = totalSupply;                              // Give the creator all initial tokens
        name                    = tokenName;                                // Set the name for display purposes
        symbol                  = tokenSymbol;                              // Set the symbol for display purposes
    }

    // Internal transfer, only can be called by this contract
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                                // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] >= _value);                                // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);                  // Check for overflows
        uint previousBalances = balanceOf[_from] + balanceOf[_to];          // Save this for an assertion in the future
        balanceOf[_from] -= _value;                                         // Subtract from the sender
        balanceOf[_to] += _value;                                           // Add the same to the recipient
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);      // Asserts are used to use static analysis to find bugs in your code. They should never fail
    }


    /// @notice Send `_value` (in wei, with 18 zeros) tokens to `_to` from msg.sender's account
    /// @param _to The address of the recipient
    /// @param _value the amount to send 
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


    /// @notice Transfer tokens from another address. Send `_value` (in wei, with 18 zeros) tokens to `_to` in behalf of `_from`.  `_from` must have already approved `msg.sender`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);                    // Check allowance (array[approver][approvee])
        allowance[_from][msg.sender] -= _value;                             // deduct _value from allowance
        _transfer(_from, _to, _value);                                      // transfer
        return true;
    }

    /// @notice Set allowance for other address.  Allow `_spender` to spend no more than `_value` (in wei, with 18 zeros) tokens on `msg.sender` behalf
    /// @param _spender The address authorized to spend
    /// @param _value the max amount they can spend
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;                           // Create allowance (array[approver][approvee])
        return true;
    }

    /// @notice Set allowance for other address,then notify  Allow `_spender` to spend no more than `_value` (in wei, with 18 zeros) tokens on `msg.sender` behalf, then ping the contract about it
    /// @param _spender The address authorized to spend
    /// @param _value the max amount they can spend
    /// @param _extraData some extra information to send to the approved contract
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /// @notice Destroy tokens.  Remove `_value` (in wei, with 18 zeros) tokens from the system irreversibly
    /// @param _value the amount of money to burn
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);                           // Check if the sender has enough
        balanceOf[msg.sender] -= _value;                                    // Subtract from the sender
        totalSupply -= _value;                                              // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }


    /// @notice Destroy tokens in another account.  Remove `_value` (in wei, with 18 zeros) tokens from the system irreversibly, on behalf of `_from`. `_from` must have already approved `msg.sender`
    /// @param _from the address of the sender
    /// @param _value the amount of money to burn
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);                    // Check allowance.  `_from` must have already approved `msg.sender`
        balanceOf[_from] -= _value;                                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;                             // Subtract from the sender's allowance
        totalSupply -= _value;                                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       TRADESMAN TOKEN STARTS HERE      */
/******************************************/

contract Tradesman is owned, TokenERC20 {

    uint256 public sellPrice;
    uint256 public sellMultiplier;  // allows token to be valued at < 1 ETH
    uint256 public buyPrice;
    uint256 public buyMultiplier;   // allows token to be valued at < 1 ETH

    mapping (address => bool) public frozenAccount;

    // This generates a public event on the blockchain that will notify clients
    event FrozenFunds(address target, bool frozen);

    // Initializes contract with initial supply tokens to the creator of the contract
    function Tradesman(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    // Internal transfer, only can be called by this contract
    // value in wei, with 18 zeros
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                               // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]);                 // Check for overflows
        require (!frozenAccount[_from]);                                    // Check if sender is frozen
        require (!frozenAccount[_to]);                                      // Check if recipient is frozen
        balanceOf[_from] -= _value;                                         // Subtract from the sender
        balanceOf[_to] += _value;                                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

    /* we disable minting.  Fixed supply.
    
    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens (in wei, with 18 zeros) it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    */

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens, if ordered by law
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth. Multipliers allow for token value < 1 ETH
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    /// @param newSellMultiplier Allows token value < 1 ETH. num_eth = num_tokens * (sellPrice / sellMultiplier)
    /// @param newBuyMultiplier Allows token value < 1 ETH.  num_tokens = num_eth * (buyMultiplier / buyPrice)
    function setPrices(uint256 newSellPrice, uint256 newSellMultiplier, uint256 newBuyPrice, uint256 newBuyMultiplier) onlyOwner public {
        sellPrice       = newSellPrice;                                     // sellPrice should be less than buyPrice
        sellMultiplier  = newSellMultiplier;                                // so buyPrice cannot be 1 if also selling
        buyPrice        = newBuyPrice;                                      // Suggest buyPrice = 10, buyMultiplier = 100000, for 10000:1 TRD:ETH
        buyMultiplier   = newBuyMultiplier;                                 // then    sellPrice = 5, sellMultiplier = 100000
    }

    //  Set `buyMultiplier` = 0 after all tokens sold.  We can still accept donations.
    /// @notice Automatically buy tokens from contract by sending ether (no `data` required).
    function () payable public {
        uint amount = msg.value * buyMultiplier / buyPrice;                 // calculates the amount.  Multiplier allows token value < 1 ETH
        _transfer(this, msg.sender, amount);                                // makes the transfers
    }
    
    //  Set `buyMultiplier` = 0 after all tokens sold.
    /// @notice Buy tokens from contract by sending ether, with `data` = `0xa6f2ae3a`. 
    function buy() payable public {
        require (buyMultiplier > 0);                                        // if no more tokens, make Tx fail.
        uint amount = msg.value * buyMultiplier / buyPrice;                 // calculates the amount.  Multiplier allows token value < 1 ETH
        _transfer(this, msg.sender, amount);                                // makes the transfers
    }
    
    //  Set `sellMultiplier` = 0 after all tokens sold.
    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        require (sellMultiplier > 0);                                       // if not buying back tokens, make Tx fail.
        require(this.balance >= amount * sellPrice / sellMultiplier);       // checks if the contract has enough ether to buy.    Multiplier allows token value < 1 ETH
        _transfer(msg.sender, this, amount);                                // makes the transfers
        msg.sender.transfer(amount * sellPrice / sellMultiplier);           // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
    
    /// @notice Allow contract to transfer ether directly
    /// @param _to address of destination
    /// @param _value amount of ETH to transfer
    function etherTransfer(address _to, uint _value) onlyOwner public {
        _to.transfer(_value);
    }
    
    /// @notice generic transfer function can interact with contracts by supplying data / function calls
    /// @param _to address of destination
    /// @param _value amount of ETH to transfer
    /// @param _data data bytes
    function genericTransfer(address _to, uint _value, bytes _data) onlyOwner public {
         require(_to.call.value(_value)(_data));
    }

    //  transfer out tokens (can be done with the generic transfer function by supplying the function signature and parameters)
    /// @notice Allow contract to transfer tokens directly
    /// @param _to address of destination
    /// @param _value amount of ETH to transfer
    function tokenTransfer(address _to, uint _value) onlyOwner public {
         _transfer(this, _to, _value);                               // makes the transfers
    }
        
}