pragma solidity ^0.4.16;

contract Owned {
    address public owner;

    function Owned() public {
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

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public constant TOKEN_UNIT = 10 ** 18;

    uint256 internal _totalSupply;
    mapping (address => uint256) internal _balanceOf;
    mapping (address => mapping (address => uint256)) internal _allowance;


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
    ) public 
    {
        _totalSupply = initialSupply * TOKEN_UNIT;  // Update total supply with the decimal amount
        _balanceOf[msg.sender] = _totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }


    function totalSupply() constant public returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address src) constant public returns (uint256) {
        return _balanceOf[src];
    }
    function allowance(address src, address guy) constant public returns (uint256) {
        return _allowance[src][guy];
    }


    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(_balanceOf[_from] >= _value);
        // Check for overflows
        require(_balanceOf[_to] + _value > _balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = _balanceOf[_from] + _balanceOf[_to];
        // Subtract from the sender
        _balanceOf[_from] -= _value;
        // Add the same to the recipient
        _balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(_balanceOf[_from] + _balanceOf[_to] == previousBalances);
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
        require(_value <= _allowance[_from][msg.sender]);     // Check allowance
        _allowance[_from][msg.sender] -= _value;
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
        _allowance[msg.sender][_spender] = _value;
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
        returns (bool success) 
    {
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
        require(_balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        _balanceOf[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                      // Updates totalSupply
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
        require(_balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= _allowance[_from][msg.sender]);    // Check allowance
        _balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        _allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        _totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


contract PeralToken is Owned, TokenERC20 {
    using SafeMath for uint256;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    
    mapping (address => bool) public frozenAccount;
    mapping (address => bool) private allowMint;
    bool _closeSale = false;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function PeralToken(uint remainAmount,string tokenName,string tokenSymbol) TokenERC20(remainAmount, tokenName, tokenSymbol) public {
        
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (_balanceOf[_from] >= _value);               // Check if the sender has enough
        require (_balanceOf[_to].add(_value) > _balanceOf[_to]); // Check for overflows
        require(_closeSale);
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        _balanceOf[_from] = _balanceOf[_from].sub(_value);                         // Subtract from the sender
        _balanceOf[_to] = _balanceOf[_to].add(_value);                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) public {
        require(allowMint[msg.sender]);
        _balanceOf[target] = _balanceOf[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintTokenWithUnit(address target, uint256 mintedAmount) public {
        require(allowMint[msg.sender]);
        uint256 amount = mintedAmount.mul(TOKEN_UNIT);
        _balanceOf[target] = _balanceOf[target].add(amount);
        _totalSupply = _totalSupply.add(amount);
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }



    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     function setMintContactAddress(address _contactAddress) onlyOwner public {
        allowMint[_contactAddress] = true;
    }

    function disableContactMint(address _contactAddress) onlyOwner public {
        allowMint[_contactAddress] = false;
    }

    function closeSale(bool close) onlyOwner public {
        _closeSale = close;
    }

}