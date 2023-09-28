pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Return true if sender is owner or super-owner of the contract
    function isOwner() internal view returns(bool success) {
        if (msg.sender == owner) return true;
        return false;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}


contract CTESale is Ownable, StandardToken {


    uint8 public constant TOKEN_DECIMALS = 18;  // decimals
    uint8 public constant PRE_SALE_PERCENT = 20; // 20%

    // Public variables of the token
    string public name = "Career Trust Ecosystem";
    string public symbol = "CTE";
    uint8 public decimals = TOKEN_DECIMALS; // 18 decimals is the strongly suggested default, avoid changing it


    uint256 public totalSupply = 5000000000 * (10 ** uint256(TOKEN_DECIMALS)); // Five billion
    uint256 public preSaleSupply; // PRE_SALE_PERCENT / 20 * totalSupply
    uint256 public soldSupply = 0; // current supply tokens for sell
    uint256 public sellSupply = 0;
    uint256 public buySupply = 0;
    bool public stopSell = false;
    bool public stopBuy = false;

    /*
    	Sell/Buy prices in wei
    	1 ETH = 10^18 of wei
    */
    uint256 public buyExchangeRate = 8000;   // 8000 CTE tokens per 1 ETHs
    uint256 public sellExchangeRate = 40000;  // 1 ETH need 40000 CTE token
    address public ethFundDeposit;  // deposit address for ETH for CTE Team.


    bool public allowTransfers = true; // if true then allow coin transfers


    mapping (address => bool) public frozenAccount;

    bool public enableInternalLock = true; // if false then allow coin transfers by internal sell lock
    mapping (address => bool) public internalLockAccount;



    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    event IncreasePreSaleSupply(uint256 _value);
    event DecreasePreSaleSupply(uint256 _value);
    event IncreaseSoldSaleSupply(uint256 _value);
    event DecreaseSoldSaleSupply(uint256 _value);


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function CTESale() public {
        balances[msg.sender] = totalSupply;                 // Give the creator all initial tokens
        preSaleSupply = totalSupply * PRE_SALE_PERCENT / 100;      // preSaleSupply

        ethFundDeposit = msg.sender;                        // deposit eth
        allowTransfers = false;
    }

    function _isUserInternalLock() internal view returns (bool) {
        return (enableInternalLock && internalLockAccount[msg.sender]);
    }

    /// @dev increase the token's supply
    function increasePreSaleSupply (uint256 _value) onlyOwner public {
        require (_value + preSaleSupply < totalSupply);
        preSaleSupply += _value;
        IncreasePreSaleSupply(_value);
    }

    /// @dev decrease the token's supply
    function decreasePreSaleSupply (uint256 _value) onlyOwner public {
        require (preSaleSupply - _value > 0);
        preSaleSupply -= _value;
        DecreasePreSaleSupply(_value);
    }

    /// @dev increase the token's supply
    function increaseSoldSaleSupply (uint256 _value) onlyOwner public {
        require (_value + soldSupply < totalSupply);
        soldSupply += _value;
        IncreaseSoldSaleSupply(_value);
    }

    /// @dev decrease the token's supply
    function decreaseSoldSaleSupply (uint256 _value) onlyOwner public {
        require (soldSupply - _value > 0);
        soldSupply -= _value;
        DecreaseSoldSaleSupply(_value);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function destroyToken(address target, uint256 amount) onlyOwner public {
        balances[target] -= amount;
        totalSupply -= amount;
        Transfer(target, this, amount);
        Transfer(this, 0, amount);
    }


    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /// @dev set EthFundDeposit
    function setEthFundDeposit(address _ethFundDeposit) onlyOwner public {
        require(_ethFundDeposit != address(0));
        ethFundDeposit = _ethFundDeposit;
    }

    /// @dev sends ETH to CTE team
    function transferETH() onlyOwner public {
        require(ethFundDeposit != address(0));
        require(this.balance != 0);
        require(ethFundDeposit.send(this.balance));
    }

    /// @notice Allow users to buy tokens for `_buyExchangeRate` eth and sell tokens for `_sellExchangeRate` eth
    /// @param _sellExchangeRate the users can sell to the contract
    /// @param _buyExchangeRate users can buy from the contract
    function setExchangeRate(uint256 _sellExchangeRate, uint256 _buyExchangeRate) onlyOwner public {
        sellExchangeRate = _sellExchangeRate;
        buyExchangeRate = _buyExchangeRate;
    }

    function setExchangeStatus(bool _stopSell, bool _stopBuy) onlyOwner public {
        stopSell = _stopSell;
        stopBuy = _stopBuy;
    }

    function setAllowTransfers(bool _allowTransfers) onlyOwner public {
        allowTransfers = _allowTransfers;
    }

    // Admin function for transfer coins
    function transferFromAdmin(address _from, address _to, uint256 _value) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function setEnableInternalLock(bool _isEnable) onlyOwner public {
        enableInternalLock = _isEnable;
    }

    function lockInternalAccount(address target, bool lock) onlyOwner public {
        require(target != address(0));
        internalLockAccount[target] = lock;
    }

    // sell token, soldSupply, lockAccount
    function internalSellTokenFromAdmin(address _to, uint256 _value, bool _lock) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[owner]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[owner] = balances[owner].sub(_value);
        balances[_to] = balances[_to].add(_value);
        soldSupply += _value;
        sellSupply += _value;

        Transfer(owner, _to, _value);

        internalLockAccount[_to] = _lock;     // lock internalSell lock

        return true;
    }

    /***************************************************/
    /*                        BASE                     */
    /***************************************************/

    // @dev override
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (!isOwner()) {
            require (allowTransfers);
            require(!frozenAccount[_from]);                                          // Check if sender is frozen
            require(!frozenAccount[_to]);                                            // Check if recipient is frozen
            require(!_isUserInternalLock());                                         // Check if recipient is internalSellLock
        }
        return super.transferFrom(_from, _to, _value);
    }

    // @dev override
    function transfer(address _to, uint256 _value) public returns (bool) {
        if (!isOwner()) {
            require (allowTransfers);
            require(!frozenAccount[msg.sender]);                                        // Check if sender is frozen
            require(!frozenAccount[_to]);                                               // Check if recipient is frozen
            require(!_isUserInternalLock());                                            // Check if recipient is internalSellLock
        }
        return super.transfer(_to, _value);
    }


    /// @dev send ether to contract
    function pay() payable public {}


    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint256 amount = msg.value.mul(buyExchangeRate);

        require(!stopBuy);
        require(amount <= balances[owner]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[owner] = balances[owner].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);

        soldSupply += amount;
        buySupply += amount;

        Transfer(owner, msg.sender, amount);
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        uint256 ethAmount = amount.div(sellExchangeRate);
        require(!stopSell);
        require(this.balance >= ethAmount);      // checks if the contract has enough ether to buy
        require(ethAmount >= 1);      // checks if the contract has enough ether to buy

        require(balances[msg.sender] >= amount);                   // Check if the sender has enough
        require(balances[owner] + amount > balances[owner]);       // Check for overflows
        require(!frozenAccount[msg.sender]);                        // Check if sender is frozen
        require(!_isUserInternalLock());                                            // Check if recipient is internalSellLock

        // SafeMath.add will throw if there is not enough balance.
        balances[owner] = balances[owner].add(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);

        soldSupply -= amount;
        sellSupply += amount;

        Transfer(msg.sender, owner, amount);

        msg.sender.transfer(ethAmount);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
}