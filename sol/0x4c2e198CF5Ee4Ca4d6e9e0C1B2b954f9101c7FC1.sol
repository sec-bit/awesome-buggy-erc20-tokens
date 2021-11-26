pragma solidity ^0.4.13;

contract owned {
    /* Owner definition. */
    address public owner; // Owner address.
    function owned() internal {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner); _;
    }
    function transferOwnership(address newOwner) onlyOwner public{
        owner = newOwner;
    }
}

contract token { 
    /* Base token definition. */
    string public name; // Name for the token.
    string public symbol; // Symbol for the token.
    uint8 public decimals; // Number of decimals of the token.
    uint256 public totalSupply; // Total of tokens created.

    // Array containing the balance foreach address.
    mapping (address => uint256) public balanceOf;
    // Array containing foreach address, an array containing each approved address and the amount of tokens it can spend.
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify about a transfer done. */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes the contract */
    function token(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) internal {
        balanceOf[msg.sender] = initialSupply; // Gives the creator all initial tokens.
        totalSupply = initialSupply; // Update total supply.
        name = tokenName; // Set the name for display purposes.
        symbol = tokenSymbol; // Set the symbol for display purposes.
        decimals = decimalUnits; // Amount of decimals for display purposes.
    }

    /* Internal transfer, only can be called by this contract. */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0); // Prevent transfer to 0x0 address.
        require(balanceOf[_from] > _value); // Check if the sender has enough.
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows.
        balanceOf[_from] -= _value; // Subtract from the sender.
        balanceOf[_to]   += _value; // Add the same to the recipient.
        Transfer(_from, _to, _value); // Notifies the blockchain about the transfer.
    }

    /// @notice Send `_value` tokens to `_to` from your account.
    /// @param _to The address of the recipient.
    /// @param _value The amount to send.
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /// @notice Send `_value` tokens to `_to` in behalf of `_from`.
    /// @param _from The address of the sender.
    /// @param _to The address of the recipient.
    /// @param _value The amount to send.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // Check allowance.
        allowance[_from][msg.sender] -= _value; // Update the allowance array, substracting the amount sent.
        _transfer(_from, _to, _value); // Makes the transfer.
        return true;
    }

    /// @notice Allows `_spender` to spend a maximum of `_value` tokens in your behalf.
    /// @param _spender The address authorized to spend.
    /// @param _value The max amount they can spend.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value; // Adds a new register to allowance, permiting _spender to use _value of your tokens.
        return true;
    }
}

contract GFCToken is owned, token {
    /* Specific token definition for -GFC Token- company. */
    uint256 public sellPrice = 1; // Price applied when selling a token.
    uint256 public buyPrice = 1; // Price applied when buying a token.
    bool public closeBuy = false; // If true, nobody will be able to buy.
    bool public closeSell = false; // If true, nobody will be able to sell.
    address public commissionGetter = 0xCd8bf69ad65c5158F0cfAA599bBF90d7f4b52Bb0; // The address that gets the commissions paid.
    mapping (address => bool) public frozenAccount; // Array containing foreach address if it's frozen or not.

    /* This generates a public event on the blockchain that will notify about an address being freezed. */
    event FrozenFunds(address target, bool frozen);
    /* This generates a public event on the blockchain that will notify about an addition of Ether to the contract. */
    event LogDeposit(address sender, uint amount);
    /* This generates a public event on the blockchain that will notify about a Withdrawal of Ether from the contract. */
    event LogWithdrawal(address receiver, uint amount);

    /* Initializes the contract */
    function GFCToken(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) public token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

    /* Overrides Internal transfer due to frozen accounts check */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0); // Prevent transfer to 0x0 address.
        require(balanceOf[_from] >= _value); // Check if the sender has enough.
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows.
        require(!frozenAccount[_from]); // Check if sender is frozen.
        require(!frozenAccount[_to]); // Check if recipient is frozen.
		balanceOf[_from] -= _value; // Subtracts _value tokens from the sender.
        balanceOf[_to] += _value; // Adds the same amount to the recipient.
        Transfer(_from, _to, _value); // Notifies the blockchain about the transfer.
    }

    /* Sends GFC from the owner to the smart-contract */
    function refillTokens(uint256 _value) public onlyOwner{
        _transfer(msg.sender, this, _value);
    }

    /* Overrides basic transfer function due to commission value */
    function transfer(address _to, uint256 _value) public {
        uint market_value = _value * sellPrice; //Market value for this amount
        uint commission = market_value * 1 / 100; //Calculates the commission for this transaction
        require(this.balance >= commission); // The smart-contract pays commission, else the transfer is not possible.
        commissionGetter.transfer(commission); // Transfers commission to the commissionGetter.
        _transfer(msg.sender, _to, _value); // Makes the transfer of tokens.
    }

    /* Overrides basic transferFrom function due to commission value */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // Check allowance.
        uint market_value = _value * sellPrice; //Market value for this amount
        uint commission = market_value * 1 / 100; //Calculates the commission for this transaction
        require(this.balance >= commission); // The smart-contract pays commission, else the transfer is not possible.
        commissionGetter.transfer(commission); // Transfers commission to the commissionGetter.
        allowance[_from][msg.sender] -= _value; // Update the allowance array, substracting the amount sent.
        _transfer(_from, _to, _value); // Makes the transfer of tokens.
        return true;
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens.
    /// @param target Address to be frozen.
    /// @param freeze Either to freeze target or not.
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze; // Sets the target status. True if it's frozen, False if it's not.
        FrozenFunds(target, freeze); // Notifies the blockchain about the change of state.
    }

    /// @notice Allow addresses to pay `newBuyPrice`ETH when buying and receive `newSellPrice`ETH when selling, foreach token bought/sold.
    /// @param newSellPrice Price applied when an address sells its tokens, amount in WEI (1ETH = 10¹⁸WEI).
    /// @param newBuyPrice Price applied when an address buys tokens, amount in WEI (1ETH = 10¹⁸WEI).
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice; // Update the buying price.
        buyPrice = newBuyPrice; // Update the selling price.
    }

    /// @notice Sets the state of buy and sell operations
    /// @param isClosedBuy True if buy operations are closed, False if opened.
    /// @param isClosedSell True if sell operations are closed, False if opened.
    function setStatus(bool isClosedBuy, bool isClosedSell) onlyOwner public {
        closeBuy = isClosedBuy; // Update the state of buy operations.
        closeSell = isClosedSell; // Update the state of sell operations.
    }

    /// @notice Deposits Ether to the contract
    function deposit() payable public returns(bool success) {
        require((this.balance + msg.value) > this.balance); // Checks for overflows.
        LogDeposit(msg.sender, msg.value); // Notifies the blockchain about the Ether received.
        return true;
    }

    /// @notice The owner withdraws Ether from the contract.
    /// @param amountInWeis Amount of ETH in WEI which will be withdrawed.
    function withdraw(uint amountInWeis) onlyOwner public {
        LogWithdrawal(msg.sender, amountInWeis); // Notifies the blockchain about the withdrawal.
        owner.transfer(amountInWeis); // Sends the Ether to owner address.
    }

    /// @notice Buy tokens from contract by sending Ether.
    function buy() public payable {
        require(!closeBuy); //Buy operations must be opened
        uint amount = msg.value / buyPrice; //Calculates the amount of tokens to be sent
        uint market_value = amount * buyPrice; //Market value for this amount
        uint commission = market_value * 1 / 100; //Calculates the commission for this transaction
        require(this.balance >= commission); //The token smart-contract pays commission, else the operation is not possible.
        commissionGetter.transfer(commission); //Transfers commission to the commissionGetter.
        _transfer(this, msg.sender, amount); //Makes the transfer of tokens.
    }

    /// @notice Sell `amount` tokens to the contract.
    /// @param amount amount of tokens to be sold.
    function sell(uint256 amount) public {
        require(!closeSell); //Sell operations must be opened
        uint market_value = amount * sellPrice; //Market value for this amount
        uint commission = market_value * 1 / 100; //Calculates the commission for this transaction
        uint amount_weis = market_value + commission; //Total in weis that must be paid
        require(this.balance >= amount_weis); //Contract must have enough weis
        commissionGetter.transfer(commission); //Transfers commission to the commissionGetter
        _transfer(msg.sender, this, amount); //Makes the transfer of tokens, the contract receives the tokens.
        msg.sender.transfer(market_value); //Sends Ether to the seller.
    }

    /// Default function, sender buys tokens by sending ether to the contract
    function () public payable { buy(); }
}