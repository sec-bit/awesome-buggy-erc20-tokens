pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

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

contract TokenERC20 is owned {

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 8;
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
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);      // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                        // Give the creator all initial tokens
        name = tokenName;                                           // Set the name for display purposes
        symbol = tokenSymbol;                                       // Set the symbol for display purposes
    }

    /* Returns total supply of issued tokens */
    function totalSupply() constant public returns (uint256 supply) {
        return totalSupply;
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
    function transfer(address _to, uint256 _value) public {
        // Master Lock: Allow transfer by other users only after 1511308799
       if (msg.sender != owner) require(now > 1511308799);   
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

contract CDRTToken is TokenERC20 {

    uint256 public buyBackPrice;
    // Snapshot of PE balances by Ethereum Address and by year
    mapping (uint256 => mapping (address => uint256)) public snapShot;
    // This is time for next Profit Equivalent
    uint256 public nextPE = 1539205199;
    // List of Team and Founders account's frozen till 15 November 2018
    mapping (address => uint256) public frozenAccount;

    // List of all years when snapshots were made
    uint[] internal yearsPast = [17];  
    // Holds current year PE balance
    uint256 public peBalance;       
    // Holds full Buy Back balance
    uint256 public bbBalance;       
    // Holds unclaimed PE balance from last periods
    uint256 internal peLastPeriod;       
    // All ever used in transactions Ethereum Addresses' positions in list
    mapping (address => uint256) internal ownerPos;              
    // Total number of Ethereum Addresses used in transactions 
    uint256 internal pos;                                      
    // All ever used in transactions Ethereum Addresses list
    mapping (uint256 => address) internal addressList;   
    
    /* Handles incoming payments to contract's address */
    function() payable public {
    }

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function CDRTToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    /* Internal insertion in list of all Ethereum Addresses used in transactions, called by contract */
    function _insert(address _to) internal {
            if (ownerPos[_to] == 0) {
                pos++;
                addressList[pos] = _to;
                ownerPos[_to] = pos;
            }
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        require(frozenAccount[_from] < now);                 // Check if sender is frozen
         _insert(_to);
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

    /**
      * @notice Freezes from sending & receiving tokens. For users protection can't be used after 1542326399
      * and will not allow corrections.
      *     
      * Will set freeze to 1542326399
      *
      * @param _from  Founders and Team account we are freezing from sending
      *
      */
   function freezeAccount(address _from) onlyOwner public {
        require(now < 1542326400);
        require(frozenAccount[_from] == 0);
        frozenAccount[_from] = 1542326399;                  
    }

    /**
      * @notice Allow owner to set tokens price for Buy-Back Campaign. Can not be executed until 1539561600
      *
      * @param _newPrice market value of 1 CDRT Token
      *
      */
    function setPrice(uint256 _newPrice) onlyOwner public {
        require(now > 1539561600);                          
        buyBackPrice = _newPrice;
    }

    /**
      * @notice Contract owner can take snapshot of current balances and issue PE to each balance
      *
      * @param _year year of the snapshot to take, must be greater than existing value
      *
      * @param _nextPE set new Profit Equivalent date
      *
      */
   function takeSnapshot(uint256 _year, uint256 _nextPE) onlyOwner public {
        require(_year > yearsPast[yearsPast.length-1]);                             
        uint256 reward = peBalance / totalSupply;
        for (uint256 k=1; k <= pos; k++){
            snapShot[_year][addressList[k]] = balanceOf[addressList[k]] * reward;
        }
        yearsPast.push(_year);
        peLastPeriod += peBalance;     // Transfer new balance to unclaimed
        peBalance = 0;                 // Zero current balance;
        nextPE = _nextPE;
    }

    /**
      *  @notice Allow user to claim his PE on his Ethereum Address. Should be called manualy by user
      *
      */
    function claimProfitEquivalent() public{
        uint256 toPay;
        for (uint k=0; k <= yearsPast.length-1; k++){
            toPay += snapShot[yearsPast[k]][msg.sender];
            snapShot[yearsPast[k]][msg.sender] = 0;
        }
        msg.sender.transfer(toPay);
        peLastPeriod -= toPay;
   }
    /**
      * @notice Allow user to sell CDRT tokens and destroy them. Can not be executed until 1539561600
      *
      * @param _qty amount to sell and destroy
      */
    function execBuyBack(uint256 _qty) public{
        require(now > 1539561600);                          
        uint256 toPay = _qty*buyBackPrice;                                        
        require(balanceOf[msg.sender] >= _qty);                     // check if user has enough CDRT Tokens 
        require(buyBackPrice > 0);                                  // check if sale price set
        require(bbBalance >= toPay);                        
        require(frozenAccount[msg.sender] < now);                   // Check if sender is frozen
        msg.sender.transfer(toPay);
        bbBalance -= toPay;
        burn(_qty);
    }   
   /**
      * @notice Allow owner to set balances
      *
      *
      */
    function setBalances(uint256 _peBalance, uint256 _bbBalance) public{
      peBalance = _peBalance;
      bbBalance = _bbBalance;
    }
}