pragma solidity ^0.4.13;
contract owned {
    address public owner;
    mapping (address =>  bool) public admins;

    function owned() {
        owner = msg.sender;
        admins[msg.sender]=true;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin   {
        require(admins[msg.sender] == true);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
    function makeAdmin(address newAdmin, bool isAdmin) onlyOwner {
        admins[newAdmin] = isAdmin;
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract GRX is owned {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 minBalanceForAccounts;
    bool public usersCanTrade;
    bool public usersCanUnfreeze;

    bool public ico = true; //turn ico on and of
    mapping (address => bool) public admin;


    modifier notICO {
        require(admin[msg.sender] || !ico);
        _;
    }


    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;


    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address =>  bool) public frozen;

    mapping (address =>  bool) public canTrade; //user allowed to buy or sell

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    //This generates a public even on the blockhcain when an address is reward
    event Reward(address from, address to, uint256 value, string data, uint256 time);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Frozen(address indexed addr, bool frozen);

    // This generates a public event on the blockchain that will notify clients
    event Unlock(address indexed addr, address from, uint256 val);

    // This generates a public event on the blockchain that will notify clients


    // This generates a public event on the blockchain that will notify clients
    // event Unfreeze(address indexed addr);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function GRX() {
        uint256 initialSupply = 20000000000000000000000000;
        balanceOf[msg.sender] = initialSupply ;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = "Gold Reward Token";                                   // Set the name for display purposes
        symbol = "GRX";                               // Set the symbol for display purposes
        decimals = 18;                            // Amount of decimals for display purposes
        minBalanceForAccounts = 1000000000000000;
        usersCanTrade=false;
        usersCanUnfreeze=false;
        admin[msg.sender]=true;
        canTrade[msg.sender]=true;

    }

    /**
     * Increace Total Supply
     *
     * Increases the total coin supply
     */
    function increaseTotalSupply (address target,  uint256 increaseBy )  onlyOwner {
        balanceOf[target] += increaseBy;
        totalSupply += increaseBy;
        Transfer(0, owner, increaseBy);
        Transfer(owner, target, increaseBy);
    }

    function  usersCanUnFreeze(bool can) {
        usersCanUnfreeze=can;
    }

    function setMinBalance(uint minimumBalanceInWei) onlyOwner {
        minBalanceForAccounts = minimumBalanceInWei;
    }

    /**
     * transferAndFreeze
     *
     * Function to transfer to and freeze and account at the same time
     */
    function transferAndFreeze (address target,  uint256 amount )  onlyAdmin {
        _transfer(msg.sender, target, amount);
        freeze(target, true);
    }

    /**
     * _freeze internal
     *
     * function to freeze an account
     */
    function _freeze (address target, bool froze )  internal  {

        frozen[target]=froze;
        Frozen(target, froze);
    }



    /**
     * freeze
     *
     * function to freeze an account
     */
    function freeze (address target, bool froze )   {
        if(froze || (!froze && !usersCanUnfreeze)) {
            require(admin[msg.sender]);
        }

        _freeze(target, froze);
    }



    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                   // Prevent transfer to 0x0 address. Use burn() instead

        require(!frozen[_from]);                       //prevent transfer from frozen address
        require(balanceOf[_from] >= _value);                // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) notICO {
        require(!frozen[msg.sender]);                       //prevent transfer from frozen address
        if (msg.sender.balance  < minBalanceForAccounts) {
            sell((minBalanceForAccounts - msg.sender.balance) * sellPrice);
        }
        _transfer(msg.sender, _to, _value);
    }



    mapping (address => uint256) public totalLockedRewardsOf;
    mapping (address => mapping (address => uint256)) public lockedRewardsOf; //balance of a locked reward
    mapping (address => mapping (uint32  => address)) public userRewarders; //indexed list of rewardees rewarder
    mapping (address => mapping (address => uint32)) public userRewardCount; //a list of number of times a customer has received reward from a given merchant
    mapping (address => uint32) public userRewarderCount; //number of rewarders per customer

    //merchant
    mapping (address =>  uint256  ) public totalRewardIssuedOut;

    /**
     * Reward tokens - tokens go to
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function reward(address _to, uint256 _value, bool locked, string data) {
        require(_to != 0x0);
        require(!frozen[msg.sender]);                       //prevent transfer from frozen address
        if (msg.sender.balance  < minBalanceForAccounts) {
            sell((minBalanceForAccounts - msg.sender.balance) * sellPrice);
        }
        if(!locked) {
            _transfer(msg.sender, _to, _value);
        }else{
            //prevent transfer from frozen address
            require(balanceOf[msg.sender] >= _value);                // Check if the sender has enough
            require(totalLockedRewardsOf[_to] + _value > totalLockedRewardsOf[_to]); // Check for overflows
            balanceOf[msg.sender] -= _value;                         // Subtract from the sender
            totalLockedRewardsOf[_to] += _value;                           // Add the same to the recipient
            lockedRewardsOf[_to][msg.sender] += _value;
            if(userRewardCount[_to][msg.sender]==0) {
                userRewarderCount[_to] += 1;
                userRewarders[_to][userRewarderCount[_to]]=msg.sender;
            }
            userRewardCount[_to][msg.sender]+=1;
            totalRewardIssuedOut[msg.sender]+= _value;
            Transfer(msg.sender, _to, _value);
        }

        Reward(msg.sender, _to, _value, data, now);
    }

    /**
     * Transfer locked rewards
     *
     * Send `_value` tokens to `_to` merchant
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferReward(address _to, uint256 _value) {
        require(!frozen[msg.sender]);                       //prevent transfer from frozen address
        require(lockedRewardsOf[msg.sender][_to] >= _value );
        require(totalLockedRewardsOf[msg.sender] >= _value);

        if (msg.sender.balance  < minBalanceForAccounts) {
            sell((minBalanceForAccounts - msg.sender.balance) * sellPrice);
        }
        totalLockedRewardsOf[msg.sender] -= _value;                           // Add the same to the recipient
        lockedRewardsOf[msg.sender][_to] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }

    /**
     * Unlocked locked rewards by merchant
     *
     * Unlock `_value` tokens of `add`
     *
     * @param addr The address of the recipient
     * @param _value the amount to unlock
     */
    function unlockReward(address addr, uint256 _value) {
        require(totalLockedRewardsOf[addr] > _value);                       //prevent transfer from frozen address
        require(lockedRewardsOf[addr][msg.sender] >= _value );
        if(_value==0) _value=lockedRewardsOf[addr][msg.sender];
        if (msg.sender.balance  < minBalanceForAccounts) {
            sell((minBalanceForAccounts - msg.sender.balance) * sellPrice);
        }
        totalLockedRewardsOf[addr] -= _value;                           // Add the same to the recipient
        lockedRewardsOf[addr][msg.sender] -= _value;
        balanceOf[addr] += _value;
        Unlock(addr, msg.sender, _value);
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
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(!frozen[_from]);                       //prevent transfer from frozen address
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
    function approve(address _spender, uint256 _value)
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) onlyOwner
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
    function burn(uint256 _value) onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other ccount
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value)  returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }

    /*
     function increaseSupply(address _from, uint256 _value) onlyOwner  returns (bool success)  {
     balanceOf[_from] += _value;                         // Subtract from the targeted balance
     totalSupply += _value;                              // Update totalSupply
     // Burn(_from, _value);
     return true;
     }
     */




    uint256 public sellPrice = 608;
    uint256 public buyPrice = 760;

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function setUsersCanTrade(bool trade) onlyOwner {
        usersCanTrade=trade;
    }
    function setCanTrade(address addr, bool trade) onlyOwner {
        canTrade[addr]=trade;
    }

    //user is buying grx
    function buy() payable returns (uint256 amount){
        if(!usersCanTrade && !canTrade[msg.sender]) revert();
        amount = msg.value * buyPrice;                    // calculates the amount

        require(balanceOf[this] >= amount);               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer's balance
        balanceOf[this] -= amount;                        // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                    // ends function and returns
    }

    //user is selling us grx, we are selling eth to the user
    function sell(uint256 amount) returns (uint revenue){
        require(!frozen[msg.sender]);
        if(!usersCanTrade && !canTrade[msg.sender]) {
            require(minBalanceForAccounts > amount/sellPrice);
        }
        require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
        balanceOf[this] += amount;                        // adds the amount to owner's balance
        balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller's balance
        revenue = amount / sellPrice;
        require(msg.sender.send(revenue));                // sends ether to the seller: it's important to do this last to prevent recursion attacks
        Transfer(msg.sender, this, amount);               // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }

    function() payable {
    }
    event Withdrawn(address indexed to, uint256 value);
    function withdraw(address target, uint256 amount) onlyOwner {
        target.transfer(amount);
        Withdrawn(target, amount);
    }

    function setAdmin(address addr, bool enabled) onlyOwner {
        admin[addr]=enabled;
    }

    function setICO(bool enabled) onlyOwner {
        ico=enabled;
    }
}