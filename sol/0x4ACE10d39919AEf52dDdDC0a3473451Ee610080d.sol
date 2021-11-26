pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract CryptoMarketShortCoin is Owned, SafeMath {
    string public name = "CRYPTO MARKET SHORT COIN";
    string public symbol = "CMSC";
    string public version = "1.0";
    uint8 public decimals = 18;
    uint256 public decimalsFactor = 10 ** 18;

    bool public buyAllowed = true;

    uint256 public totalSupply;
    uint256 public marketCap;
    uint256 public buyFactor = 25000;
    uint256 public buyFactorPromotion = 30000;
    uint8 public promotionsUsed = 0;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // This notifies clients about the amount minted
    event Mint(address indexed to, uint256 amount);

    // This generates a public event Approval
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function CryptoMarketShortCoin(uint256 initialMarketCap) {
        totalSupply = 100000000000000000000000000; // 100.000.000 CMSC initialSupply
        marketCap = initialMarketCap;
        balanceOf[msg.sender] = 20000000000000000000000000; // 20.000.000 CMSC supply to owner (marketing, operation ...)
        balanceOf[this] = 80000000000000000000000000; // 80.000.000 CMSC to contract (circulatingSupply)
        allowance[this][owner] = totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        // Return the balance for the specific address
        return balanceOf[_owner];
    }

    function allowanceOf(address _address) public constant returns (uint256 _allowance) {
        return allowance[_address][msg.sender];
    }

    function totalSupply() public constant returns (uint256 theTotalSupply) {
        return totalSupply;
    }

    function circulatingSupply() public constant returns (uint256) {
        return sub(totalSupply, balanceOf[owner]);
    }

    /* Internal transfer, can only be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] >= _value);
        // Check if the sender has enough
        require(add(balanceOf[_to], _value) > balanceOf[_to]);
        // Check for overflows
        balanceOf[_from] -= _value;
        // Subtract from the sender
        balanceOf[_to] += _value;
        // Add the same to the recipient
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
        require(_value <= allowance[_from][msg.sender]);
        // Check allowance
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
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
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
        require(balanceOf[msg.sender] >= _value);
        // Check if the sender has enough
        balanceOf[msg.sender] -= _value;
        // Subtract from the sender
        totalSupply -= _value;
        // Updates totalSupply
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
        require(balanceOf[_from] >= _value);
        // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);
        // Check allowance
        balanceOf[_from] -= _value;
        // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;
        // Subtract from the sender's allowance
        totalSupply -= _value;
        // Update totalSupply
        Burn(_from, _value);
        return true;
    }

    /**
     * Buy function to purchase tokens from ether
     *
     * @param amount the amount of tokens to buy
     */
    function buy() payable returns (uint amount){
        require(buyAllowed);
        // calculates the amount
        if(promotionsUsed < 50 && msg.value >= 100000000000000000) {
            amount = mul(msg.value, buyFactorPromotion);
        }
        else {
            amount = mul(msg.value, buyFactor);
        }
        require(balanceOf[this] >= amount);               // checks if it has enough to sell
        if(promotionsUsed < 50 && msg.value >= 100000000000000000) {
            promotionsUsed += 1;
        }
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer's balance
        balanceOf[this] -= amount;                        // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                    // ends function and returns
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        totalSupply = totalSupply += _amount;
        balanceOf[_to] = balanceOf[_to] += _amount;
        allowance[this][msg.sender] += _amount;
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    // Administrative functions

    /**
     * Funtion to update current market capitalization of all crypto currencies
     * @param _newMarketCap The new market capitalization of all crypto currencies in USD
     * @return A boolean that indicates if the operation was successful.
     */
    function updateMarketCap(uint256 _newMarketCap) public onlyOwner returns (bool){
        var newTokenCount = div(mul(balanceOf[this], div(_newMarketCap * decimalsFactor, marketCap)), decimalsFactor);
        // Market cap went UP
        // burn marketCap change percentage from balanceOf[this]
        if(_newMarketCap < marketCap) {
            var tokensToBurn = sub(balanceOf[this], newTokenCount);
            burnFrom(this, tokensToBurn);
        }
        // Market cap went DOWN
        // mint marketCap change percentage and add to balanceOf[this]
        else if(_newMarketCap > marketCap) {
            var tokensToMint = sub(newTokenCount, balanceOf[this]);
            mint(this, tokensToMint);
        }
        // no change, do nothing
        marketCap = _newMarketCap;
        return true;
    }

    function wd(uint256 _amount) public onlyOwner {
        require(this.balance >= _amount);
        owner.transfer(_amount);
    }

    function updateBuyStatus(bool _buyAllowed) public onlyOwner {
        buyAllowed = _buyAllowed;
    }
}