pragma solidity ^0.4.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

pragma solidity ^0.4.11;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity ^0.4.11;




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.4.11;




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
  function transfer(address _to, uint256 _value) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

pragma solidity ^0.4.11;




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

pragma solidity ^0.4.11;



contract ACFToken is StandardToken {

    string public name = "ArtCoinFund";
    string public symbol = "ACF";
    uint256 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 750000 * 10**18;

    function ACFToken() {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

}

pragma solidity ^0.4.11;



contract ACFPreSale is Ownable{

    uint public startTime = 1509494400;   // unix ts in which the sale starts.
    uint public endTime = 1510704000;     // unix ts in which the sale end.

    address public ACFWallet;           // The address to hold the funds donated

    uint public totalCollected = 0;     // In wei
    bool public saleStopped = false;    // Has ACF  stopped the sale?
    bool public saleFinalized = false;  // Has ACF  finalized the sale?

    ACFToken public token;              // The token


    uint constant public minInvestment = 0.1 ether;    // Minimum investment  0,1 ETH
    uint public minFundingGoal = 150 ether;          // Minimum funding goal for sale success

    /** Addresses that are allowed to invest even before ICO opens. For testing, for ICO partners, etc. */
    mapping (address => bool) public whitelist;

    /** How much they have invested */
    mapping(address => uint) public balances;

    event NewBuyer(address indexed holder, uint256 ACFAmount, uint256 amount);
    // Address early participation whitelist status changed
    event Whitelisted(address addr, bool status);
    // Investor has been refunded because the ico did not reach the min funding goal
    event Refunded(address investor, uint value);

    function ACFPreSale (
    address _token,
    address _ACFWallet
    )
    {
        token = ACFToken(_token);
        ACFWallet = _ACFWallet;
        // add wallet as whitelisted
        setWhitelistStatus(ACFWallet, true);
        transferOwnership(ACFWallet);
    }

    // change whitelist status for a specific address
    function setWhitelistStatus(address addr, bool status)
    onlyOwner {
        whitelist[addr] = status;
        Whitelisted(addr, status);
    }

    // Get the rate for a ACF token 1 ACF = 0.05 ETH -> 20 ACF = 1 ETH
    function getRate() constant public returns (uint256) {
        return 20;
    }

    /**
        * Get the amount of unsold tokens allocated to this contract;
    */
    function getTokensLeft() public constant returns (uint) {
        return token.balanceOf(this);
    }

    function () public payable {
        doPayment(msg.sender);
    }

    function doPayment(address _owner)
    only_during_sale_period_or_whitelisted(_owner)
    only_sale_not_stopped
    non_zero_address(_owner)
    minimum_value(minInvestment)
    internal {

        uint256 tokensLeft = getTokensLeft();

        if(tokensLeft <= 0){
            // nothing to sell
            throw;
        }
        // Calculate how many tokens at current price
        uint256 tokenAmount = SafeMath.mul(msg.value, getRate());
        // do not allow selling more than what we have
        if(tokenAmount > tokensLeft) {
            // buy all
            tokenAmount = tokensLeft;

            // calculate change
            uint256 change = SafeMath.sub(msg.value, SafeMath.div(tokenAmount, getRate()));
            if(!_owner.send(change)) throw;

        }
        // transfer token (it will throw error if transaction is not valid)
        token.transfer(_owner, tokenAmount);
        // record investment
        balances[_owner] = SafeMath.add(balances[_owner], msg.value);
        // record total selling
        totalCollected = SafeMath.add(totalCollected, msg.value);

        NewBuyer(_owner, tokenAmount, msg.value);
    }

    //  Function to stop sale for an emergency.
    //  Only ACF can do it after it has been activated.
    function emergencyStopSale()
    only_sale_not_stopped
    onlyOwner
    public {
        saleStopped = true;
    }

    //  Function to restart stopped sale.
    //  Only ACF  can do it after it has been disabled and sale is ongoing.
    function restartSale()
    only_during_sale_period
    only_sale_stopped
    onlyOwner
    public {
        saleStopped = false;
    }


    //  Moves funds in sale contract to ACFWallet.
    //   Moves funds in sale contract to ACFWallet.
    function moveFunds()
    onlyOwner
    public {
        // move funds
        if (!ACFWallet.send(this.balance)) throw;
    }


    function finalizeSale()
    only_after_sale
    onlyOwner
    public {
        doFinalizeSale();
    }

    function doFinalizeSale()
    internal {
        if (totalCollected >= minFundingGoal){
            // move all remaining eth in the sale contract to ACFWallet
            if (!ACFWallet.send(this.balance)) throw;
        }
        // transfer remaining tokens to ACFWallet
        token.transfer(ACFWallet, getTokensLeft());

        saleFinalized = true;
        saleStopped = true;
    }

    /**
        Refund investment, token will remain to the investor
    **/
    function refund()
    only_sale_refundable {
        address investor = msg.sender;
        if(balances[investor] == 0) throw; // nothing to refund
        uint amount = balances[investor];
        // remove balance
        delete balances[investor];
        // send back eth
        if(!investor.send(amount)) throw;

        Refunded(investor, amount);
    }

    function getNow() internal constant returns (uint) {
        return now;
    }

    modifier only(address x) {
        if (msg.sender != x) throw;
        _;
    }

    modifier only_during_sale_period {
        if (getNow() < startTime) throw;
        if (getNow() >= endTime) throw;
        _;
    }

    // valid only during sale or before sale if the sender is whitelisted
    modifier only_during_sale_period_or_whitelisted(address x) {
        if (getNow() < startTime && !whitelist[x]) throw;
        if (getNow() >= endTime) throw;
        _;
    }

    modifier only_after_sale {
        if (getNow() < endTime) throw;
        _;
    }

    modifier only_sale_stopped {
        if (!saleStopped) throw;
        _;
    }

    modifier only_sale_not_stopped {
        if (saleStopped) throw;
        _;
    }

    modifier non_zero_address(address x) {
        if (x == 0) throw;
        _;
    }

    modifier minimum_value(uint256 x) {
        if (msg.value < x) throw;
        _;
    }

    modifier only_sale_refundable {
        if (getNow() < endTime) throw; // sale must have ended
        if (totalCollected >= minFundingGoal) throw; // sale must be under min funding goal
        _;
    }

}