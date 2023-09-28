pragma solidity ^0.4.11;

/**
 * Math operations with safety checks
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

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


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


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
     require(msg.data.length >= size + 4);
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
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

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) {
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
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

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

/// @title Migration Agent interface
contract MigrationAgent {
  function migrateFrom(address _from, uint256 _value);
}

/// @title Votes Platform Token
contract VotesPlatformToken is StandardToken, Ownable {

  string public name = "Votes Platform Token";
  string public symbol = "VOTES";
  uint256 public decimals = 2;
  uint256 public INITIAL_SUPPLY = 100000000 * 100;

  mapping(address => bool) refundAllowed;

  address public migrationAgent;
  uint256 public totalMigrated;

  /**
   * @dev Contructor that gives msg.sender all of existing tokens.
   */
  function VotesPlatformToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

  /**
   * Allow refund from given presale contract address.
   * Only token owner may do that.
   */
  function allowRefund(address _contractAddress) onlyOwner {
    refundAllowed[_contractAddress] = true;
  }

  /**
   * Refund _count presale tokens from _from to msg.sender.
   * msg.sender must be a trusted presale contract.
   */
  function refundPresale(address _from, uint _count) {
    require(refundAllowed[msg.sender]);
    balances[_from] = balances[_from].sub(_count);
    balances[msg.sender] = balances[msg.sender].add(_count);
  }

  function setMigrationAgent(address _agent) external onlyOwner {
    migrationAgent = _agent;
  }

  function migrate(uint256 _value) external {
    // Abort if not in Operational Migration state.
    require(migrationAgent != 0);

    // Validate input value.
    require(_value > 0);
    require(_value <= balances[msg.sender]);

    balances[msg.sender] -= _value;
    totalSupply -= _value;
    totalMigrated += _value;
    MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
  }
}

/**
 * Workflow:
 * 1) owner: create token contract
 * 2) owner: create presale contract
 * 3) owner: transfer required amount of tokens to presale contract
 * 4) owner: allow refund from presale contract by calling token.allowRefund
 * 5) <wait for start time>
 * 6) everyone sends ether to the presale contract and receives tokens in exchange
 * 7) <wait until end time or until hard cap is reached>
 * 8) if soft cap is reached:
 * 8.1) beneficiary calls withdraw() and receives
 * 8.2) beneficiary calls withdrawTokens() and receives the rest of non-sold tokens
 * 9) if soft cap is not reached:
 * 9.1) everyone calls refund() and receives their ether back in exchange for tokens
 * 9.2) owner calls withdrawTokens() and receives the refunded tokens
 */
contract VotesPlatformTokenPreSale is Ownable {
    using SafeMath for uint;

    string public name = "Votes Platform Token ICO";

    VotesPlatformToken public token;
    address public beneficiary;

    uint public hardCap;
    uint public softCap;
    uint public tokenPrice;
    uint public purchaseLimit;

    uint public tokensSold = 0;
    uint public weiRaised = 0;
    uint public investorCount = 0;
    uint public weiRefunded = 0;

    uint public startTime;
    uint public endTime;

    bool public softCapReached = false;
    bool public crowdsaleFinished = false;

    mapping(address => uint) sold;

    event GoalReached(uint amountRaised);
    event SoftCapReached(uint softCap1);
    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event Refunded(address indexed holder, uint256 amount);

    modifier onlyAfter(uint time) {
        require(now >= time);
        _;
    }

    modifier onlyBefore(uint time) {
        require(now <= time);
        _;
    }

    function VotesPlatformTokenPreSale(
        uint _hardCapUSD,       // maximum allowed fundraising in USD
        uint _softCapUSD,       // minimum amount in USD required for withdrawal by beneficiary
        address _token,         // token contract address
        address _beneficiary,   // beneficiary address
        uint _totalTokens,      // in token-wei. i.e. number of presale tokens * 10^18
        uint _priceETH,         // ether price in USD
        uint _purchaseLimitUSD, // purchase limit in USD
        uint _startTime,        // start time (unix time, in seconds since 1970-01-01)
        uint _duration          // presale duration in hours
    ) {
        hardCap = _hardCapUSD * 1 ether / _priceETH;
        softCap = _softCapUSD * 1 ether / _priceETH;
        tokenPrice = hardCap / _totalTokens;

        purchaseLimit = _purchaseLimitUSD * 1 ether / _priceETH / tokenPrice;
        token = VotesPlatformToken(_token);
        beneficiary = _beneficiary;

        startTime = _startTime;
        endTime = _startTime + _duration * 1 hours;
    }

    function () payable {
        require(msg.value / tokenPrice > 0);
        doPurchase(msg.sender);
    }

    function refund() external onlyAfter(endTime) {
        require(!softCapReached);
        uint balance = sold[msg.sender];
        require(balance > 0);
        uint refund = balance * tokenPrice;
        msg.sender.transfer(refund);
        delete sold[msg.sender];
        weiRefunded = weiRefunded.add(refund);
        token.refundPresale(msg.sender, balance);
        Refunded(msg.sender, refund);
    }

    function withdrawTokens() onlyOwner onlyAfter(endTime) {
        token.transfer(beneficiary, token.balanceOf(this));
    }

    function withdraw() onlyOwner {
        require(softCapReached);
        beneficiary.transfer(weiRaised);
        token.transfer(beneficiary, token.balanceOf(this));
        crowdsaleFinished = true;
    }

    function doPurchase(address _to) private onlyAfter(startTime) onlyBefore(endTime) {
        assert(crowdsaleFinished == false);

        require(weiRaised.add(msg.value) <= hardCap);

        if (!softCapReached && weiRaised < softCap && weiRaised.add(msg.value) >= softCap) {
            softCapReached = true;
            SoftCapReached(softCap);
        }

        uint tokens = msg.value / tokenPrice;
        require(token.balanceOf(_to) + tokens <= purchaseLimit);

        if (sold[_to] == 0)
            investorCount++;

        token.transfer(_to, tokens);
        sold[_to] += tokens;
        tokensSold = tokensSold.add(tokens);

        weiRaised = weiRaised.add(msg.value);

        NewContribution(_to, tokens, msg.value);

        if (weiRaised == hardCap) {
            GoalReached(hardCap);
        }
    }
}