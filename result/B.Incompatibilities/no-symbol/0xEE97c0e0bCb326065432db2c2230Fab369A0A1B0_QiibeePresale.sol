pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
    require(msg.sender == owner);
    _;
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

contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract QiibeeTokenInterface {
  function mintVestedTokens(address _to,
    uint256 _value,
    uint64 _start,
    uint64 _cliff,
    uint64 _vesting,
    bool _revokable,
    bool _burnsOnRevoke,
    address _wallet
  ) returns (bool);
  function mint(address _to, uint256 _amount) returns (bool);
  function transferOwnership(address _wallet);
  function pause();
  function unpause();
  function finishMinting() returns (bool);
}

contract QiibeePresale is CappedCrowdsale, FinalizableCrowdsale, Pausable {

    using SafeMath for uint256;

    struct AccreditedInvestor {
      uint64 cliff;
      uint64 vesting;
      bool revokable;
      bool burnsOnRevoke;
      uint256 minInvest; // minimum invest in wei for a given investor
      uint256 maxCumulativeInvest; // maximum cumulative invest in wei for a given investor
    }

    QiibeeTokenInterface public token; // token being sold

    uint256 public distributionCap; // cap in tokens that can be distributed to the pools
    uint256 public tokensDistributed; // tokens distributed to pools
    uint256 public tokensSold; // qbx minted (and sold)

    uint64 public vestFromTime = 1530316800; // start time for vested tokens (equiv. to 30/06/2018 12:00:00 AM GMT)

    mapping (address => uint256) public balances; // balance of wei invested per investor
    mapping (address => AccreditedInvestor) public accredited; // whitelist of investors

    // spam prevention
    mapping (address => uint256) public lastCallTime; // last call times by address
    uint256 public maxGasPrice; // max gas price per transaction
    uint256 public minBuyingRequestInterval; // min request interval for purchases from a single source (in seconds)

    bool public isFinalized = false;

    event NewAccreditedInvestor(address indexed from, address indexed buyer);
    event TokenDistributed(address indexed beneficiary, uint256 tokens);

    /*
     * @dev Constructor.
     * @param _startTime see `startTimestamp`
     * @param _endTime see `endTimestamp`
     * @param _rate see `see rate`
     * @param _cap see `see cap`
     * @param _distributionCap see `see distributionCap`
     * @param _maxGasPrice see `see maxGasPrice`
     * @param _minBuyingRequestInterval see `see minBuyingRequestInterval`
     * @param _wallet see `wallet`
     */
    function QiibeePresale(
        uint256 _startTime,
        uint256 _endTime,
        address _token,
        uint256 _rate,
        uint256 _cap,
        uint256 _distributionCap,
        uint256 _maxGasPrice,
        uint256 _minBuyingRequestInterval,
        address _wallet
    )
      Crowdsale(_startTime, _endTime, _rate, _wallet)
      CappedCrowdsale(_cap)
    {
      require(_distributionCap > 0);
      require(_maxGasPrice > 0);
      require(_minBuyingRequestInterval > 0);
      require(_token != address(0));

      distributionCap = _distributionCap;
      maxGasPrice = _maxGasPrice;
      minBuyingRequestInterval = _minBuyingRequestInterval;
      token = QiibeeTokenInterface(_token);
    }

    /*
     * @param beneficiary address where tokens are sent to
     */
    function buyTokens(address beneficiary) public payable whenNotPaused {
      require(beneficiary != address(0));
      require(validPurchase());

      AccreditedInvestor storage data = accredited[msg.sender];

      // investor's data
      uint256 minInvest = data.minInvest;
      uint256 maxCumulativeInvest = data.maxCumulativeInvest;
      uint64 from = vestFromTime;
      uint64 cliff = from + data.cliff;
      uint64 vesting = cliff + data.vesting;
      bool revokable = data.revokable;
      bool burnsOnRevoke = data.burnsOnRevoke;

      uint256 tokens = msg.value.mul(rate);

      // check investor's limits
      uint256 newBalance = balances[msg.sender].add(msg.value);
      require(newBalance <= maxCumulativeInvest && msg.value >= minInvest);

      if (data.cliff > 0 && data.vesting > 0) {
        require(QiibeeTokenInterface(token).mintVestedTokens(beneficiary, tokens, from, cliff, vesting, revokable, burnsOnRevoke, wallet));
      } else {
        require(QiibeeTokenInterface(token).mint(beneficiary, tokens));
      }

      // update state
      balances[msg.sender] = newBalance;
      weiRaised = weiRaised.add(msg.value);
      tokensSold = tokensSold.add(tokens);

      TokenPurchase(msg.sender, beneficiary, msg.value, tokens);

      forwardFunds();
    }

    /*
     * @dev This functions is used to manually distribute tokens. It works after the fundraising, can
     * only be called by the owner and when the presale is not paused. It has a cap on the amount
     * of tokens that can be manually distributed.
     *
     * @param _beneficiary address where tokens are sent to
     * @param _tokens amount of tokens (in atto) to distribute
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest.
     * @param _vesting duration in seconds of the vesting in which tokens will vest.
     */
    function distributeTokens(address _beneficiary, uint256 _tokens, uint64 _cliff, uint64 _vesting, bool _revokable, bool _burnsOnRevoke) public onlyOwner whenNotPaused {
      require(_beneficiary != address(0));
      require(_tokens > 0);
      require(_vesting >= _cliff);
      require(!isFinalized);
      require(hasEnded());

      // check distribution cap limit
      uint256 totalDistributed = tokensDistributed.add(_tokens);
      assert(totalDistributed <= distributionCap);

      if (_cliff > 0 && _vesting > 0) {
        uint64 from = vestFromTime;
        uint64 cliff = from + _cliff;
        uint64 vesting = cliff + _vesting;
        assert(QiibeeTokenInterface(token).mintVestedTokens(_beneficiary, _tokens, from, cliff, vesting, _revokable, _burnsOnRevoke, wallet));
      } else {
        assert(QiibeeTokenInterface(token).mint(_beneficiary, _tokens));
      }

      // update state
      tokensDistributed = tokensDistributed.add(_tokens);

      TokenDistributed(_beneficiary, _tokens);
    }

    /*
     * @dev Add an address to the accredited list.
     */
    function addAccreditedInvestor(address investor, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke, uint256 minInvest, uint256 maxCumulativeInvest) public onlyOwner {
        require(investor != address(0));
        require(vesting >= cliff);
        require(minInvest > 0);
        require(maxCumulativeInvest > 0);
        require(minInvest <= maxCumulativeInvest);

        accredited[investor] = AccreditedInvestor(cliff, vesting, revokable, burnsOnRevoke, minInvest, maxCumulativeInvest);

        NewAccreditedInvestor(msg.sender, investor);
    }

    /*
     * @dev checks if an address is accredited
     * @return true if investor is accredited
     */
    function isAccredited(address investor) public constant returns (bool) {
        AccreditedInvestor storage data = accredited[investor];
        return data.minInvest > 0;
    }

    /*
     * @dev Remove an address from the accredited list.
     */
    function removeAccreditedInvestor(address investor) public onlyOwner {
        require(investor != address(0));
        delete accredited[investor];
    }


    /*
     * @return true if investors can buy at the moment
     */
    function validPurchase() internal constant returns (bool) {
      require(isAccredited(msg.sender));
      bool withinFrequency = now.sub(lastCallTime[msg.sender]) >= minBuyingRequestInterval;
      bool withinGasPrice = tx.gasprice <= maxGasPrice;
      return super.validPurchase() && withinFrequency && withinGasPrice;
    }

    /*
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function. Only owner can call it.
     */
    function finalize() public onlyOwner {
      require(!isFinalized);
      require(hasEnded());

      finalization();
      Finalized();

      isFinalized = true;

      // transfer the ownership of the token to the foundation
      QiibeeTokenInterface(token).transferOwnership(wallet);
    }

    /*
     * @dev sets the token that the presale will use. Can only be called by the owner and
     * before the presale starts.
     */
    function setToken(address tokenAddress) onlyOwner {
      require(now < startTime);
      token = QiibeeTokenInterface(tokenAddress);
    }

}