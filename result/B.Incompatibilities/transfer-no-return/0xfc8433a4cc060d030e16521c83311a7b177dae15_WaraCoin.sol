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
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20() public {
        totalSupply = 100000000 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = "WaraCoin";                                   // Set the name for display purposes
        symbol = "WAC";                               // Set the symbol for display purposes
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}

contract  WaraCoin is owned, TokenERC20 {
    
    
    uint256 public waracoin_per_ether;
    
    address waracoin_corp;
    uint256 presale_deadline_count;
    uint256 crowdsale_deadline_count;
    
    /* Save product's genuine information */
    struct Product_genuine
    {
        address m_made_from_who;  // who made this product 
        
        string m_Product_GUID;    // product's unique code
        string m_Product_Description; // product's description
        address m_who_have;       // who have this product now
        address m_send_to_who;    // when product move to agency - if it is different with seller, it means that seller have no genuine  
        string m_hash;  // need to check hash of description
        
        uint256 m_moved_count;  // how many times moved this product
    }
    
    mapping (address => mapping (uint256 => Product_genuine)) public MyProducts;
    
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function WaraCoin() TokenERC20()  public 
    {
        presale_deadline_count = 25000000 * 10 ** uint256(decimals);  // after sale this counts will close presale 
        crowdsale_deadline_count = 50000000 * 10 ** uint256(decimals);    // after sale this counts will close crowdsale
        waracoin_corp = msg.sender;
        waracoin_per_ether = 10000;
    }

    /**
     * Set Waracoin sale price
     *
     * @param coincount One counts per one ether
     */
    function setWaracoinPerEther(uint256 coincount) onlyOwner public 
    {
        waracoin_per_ether = coincount;
    }

    /* Set Waracoin sale price */
    function () payable 
    {
        if ( msg.sender != owner )  // If owner send Ether, it will use for dApp operation
        {
            uint amount = 0;
            uint nowprice = 0;
            
            if ( presale_deadline_count > 0  )
                nowprice = 10000;   // presale price
            else
                if ( crowdsale_deadline_count > 0)
                    nowprice = 5000;    // crowdsale price
                else
                    nowprice = 1000;    // normalsale price
                    
            amount = msg.value * nowprice; 
            
            if ( presale_deadline_count != 0 )
            {
                if ( presale_deadline_count > amount )
                    presale_deadline_count -= amount;
                else
                    presale_deadline_count = 0;
            }
            else
                if ( crowdsale_deadline_count != 0 )
                {
                    if ( crowdsale_deadline_count > amount )
                        crowdsale_deadline_count -= amount;
                    else
                        crowdsale_deadline_count = 0;
                }
                else
                    totalSupply += amount;
    
            balanceOf[msg.sender] += amount;                  // adds the amount to buyer's balance
            require(waracoin_corp.send(msg.value));
            Transfer(this, msg.sender, amount);               // execute an event reflecting the change
        }
    }

    /**
     * Seller will send WaraCoin to buyer
     *
     * @param _to The address of backers who have WaraCoin
     * @param coin_amount How many WaraCoin will send
     */
    function waraCoinTransfer(address _to, uint256 coin_amount) public
    {
        uint256 amount = coin_amount * 10 ** uint256(decimals);

        require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
        balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller's balance
        balanceOf[_to] += amount;                  // subtracts the amount from seller's balance
        Transfer(msg.sender, _to, amount);               // executes an event reflecting on the change
    }

    /**
     * Owner will buy back WaraCoin from backers
     *
     * @param _from The address of backers who have WaraCoin
     * @param coin_amount How many WaraCoin will buy back from him
     */
    function buyFrom(address _from, uint256 coin_amount) onlyOwner public 
    {
        uint256 amount = coin_amount * 10 ** uint256(decimals);
        uint need_to_pay = amount / waracoin_per_ether;
        
        require(this.balance >= need_to_pay);
        require(balanceOf[_from] >= amount);         // checks if the sender has enough to sell
        balanceOf[_from] -= amount;                  // subtracts the amount from seller's balance
        _from.transfer(need_to_pay);                // sends ether to the seller: it's important to do this last to prevent recursion attacks
        Transfer(_from, this, amount);               // executes an event reflecting on the change
    }    
    
    /**
     * Here is WaraCoin's Genuine dApp functions
    */
    
    /* When creator made product, must need to use this fuction for register his product first */
    function registerNewProduct(uint256 product_idx,string new_guid,string product_descriptions,string hash) public returns(bool success)
    {
        uint256 amount = 1 * 10 ** uint256(decimals);        
        
        require(balanceOf[msg.sender]>=amount);   // Need to use one WaraCoin for make product code
        
        Product_genuine storage mine = MyProducts[msg.sender][product_idx];
        
        require(mine.m_made_from_who!=msg.sender);
        
        mine.m_made_from_who = msg.sender;
        mine.m_who_have = msg.sender;
        mine.m_Product_GUID = new_guid;
        mine.m_Product_Description = product_descriptions;
        mine.m_hash = hash;

        balanceOf[msg.sender] -= amount;
        return true;        
    }
    
    /* If product's owner want to move, he need to use this fuction for setting receiver : must use by sender */  
    function setMoveProductToWhom(address who_made_this,uint256 product_idx,address moveto) public returns (bool success)
    {
        Product_genuine storage mine = MyProducts[who_made_this][product_idx];
        
        require(mine.m_who_have==msg.sender);
        
        mine.m_send_to_who = moveto;

        return true;
    }
    
    /* Product's buyer need to use this function for save his genuine */
    function moveProduct(address who_made_this,address who_have_this,uint256 product_idx) public returns (bool success)
    {
        uint256 amount = 1 * 10 ** uint256(decimals);        

        require(balanceOf[msg.sender]>=amount);   // Need to use one WaraCoin for move product
        
        Product_genuine storage mine = MyProducts[who_made_this][product_idx];
        
        require(mine.m_who_have==who_have_this);    // if sender have no product, break
        require(mine.m_send_to_who==msg.sender);    // if receiver is not me, break

        mine.m_who_have = msg.sender;
        mine.m_moved_count += 1;
        
        balanceOf[msg.sender] -= amount;
        
        return true;
    }

    /* Check Genuine of owner */
    function checkProductGenuine(address who_made_this,address who_have_this,uint256 product_idx) public returns (bool success)
    {
        Product_genuine storage mine = MyProducts[who_made_this][product_idx];
        require(mine.m_who_have==who_have_this);    // if checker have no product, break
        
        return true;
    }
    
}