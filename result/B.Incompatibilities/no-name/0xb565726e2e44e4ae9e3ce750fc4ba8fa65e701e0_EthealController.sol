pragma solidity ^0.4.17;
/**
 * @title ERC20
 * @dev ERC20 interface
 */
contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { require(msg.sender == controller); _; }
    address public controller;
    function Controlled() public { controller = msg.sender;}
    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}
/**
 * @title MiniMe interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20MiniMe is ERC20, Controlled {
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool);
    function totalSupply() public view returns (uint);
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint);
    function totalSupplyAt(uint _blockNumber) public view returns(uint);
    function createCloneToken(string _cloneTokenName, uint8 _cloneDecimalUnits, string _cloneTokenSymbol, uint _snapshotBlock, bool _transfersEnabled) public returns(address);
    function generateTokens(address _owner, uint _amount) public returns (bool);
    function destroyTokens(address _owner, uint _amount)  public returns (bool);
    function enableTransfers(bool _transfersEnabled) public;
    function isContract(address _addr) internal view returns(bool);
    function claimTokens(address _token) public;
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
}
/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
  using SafeMath for uint256;
  // The token being sold
  ERC20MiniMe public token;
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
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }
  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }
  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    buyTokens(beneficiary, msg.value);
  }
  // implementation of low level token purchase function
  function buyTokens(address beneficiary, uint256 weiAmount) internal {
    require(beneficiary != 0x0);
    require(validPurchase(weiAmount));
    // update state
    weiRaised = weiRaised.add(weiAmount);
    transferToken(beneficiary, weiAmount);
    forwardFunds(weiAmount);
  }
  // low level transfer token
  // override to create custom token transfer mechanism, eg. pull pattern
  function transferToken(address beneficiary, uint256 weiAmount) internal {
    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);
    token.generateTokens(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }
  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds(uint256 weiAmount) internal {
    wallet.transfer(weiAmount);
  }
  // @return true if the transaction can buy tokens
  function validPurchase(uint256 weiAmount) internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = weiAmount != 0;
    return withinPeriod && nonZeroPurchase;
  }
  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }
  // @return true if crowdsale has started
  function hasStarted() public view returns (bool) {
    return now >= startTime;
  }
}
/// @dev The token controller contract must implement these functions
contract TokenController {
    ERC20MiniMe public ethealToken;
    address public SALE; // address where sale tokens are located
    /// @notice needed for hodler handling
    function addHodlerStake(address _beneficiary, uint _stake) public;
    function setHodlerStake(address _beneficiary, uint256 _stake) public;
    function setHodlerTime(uint256 _time) public;
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) public payable returns(bool);
    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);
    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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
/**
 * @title Hodler
 * @dev Handles hodler reward, TokenController should create and own it.
 */
contract Hodler is Ownable {
    using SafeMath for uint;
    // HODLER reward tracker
    // stake amount per address
    struct HODL {
        uint256 stake;
        // moving ANY funds invalidates hodling of the address
        bool invalid;
        bool claimed3M;
        bool claimed6M;
        bool claimed9M;
    }
    mapping (address => HODL) public hodlerStakes;
    // total current staking value and hodler addresses
    uint256 public hodlerTotalValue;
    uint256 public hodlerTotalCount;
    // store dates and total stake values for 3 - 6 - 9 months after normal sale
    uint256 public hodlerTotalValue3M;
    uint256 public hodlerTotalValue6M;
    uint256 public hodlerTotalValue9M;
    uint256 public hodlerTimeStart;
    uint256 public hodlerTime3M;
    uint256 public hodlerTime6M;
    uint256 public hodlerTime9M;
    // reward HEAL token amount
    uint256 public TOKEN_HODL_3M;
    uint256 public TOKEN_HODL_6M;
    uint256 public TOKEN_HODL_9M;
    // total amount of tokens claimed so far
    uint256 public claimedTokens;
    
    event LogHodlSetStake(address indexed _setter, address indexed _beneficiary, uint256 _value);
    event LogHodlClaimed(address indexed _setter, address indexed _beneficiary, uint256 _value);
    event LogHodlStartSet(address indexed _setter, uint256 _time);
    /// @dev Only before hodl is started
    modifier beforeHodlStart() {
        if (hodlerTimeStart == 0 || now <= hodlerTimeStart)
            _;
    }
    /// @dev Contructor, it should be created by a TokenController
    function Hodler(uint256 _stake3m, uint256 _stake6m, uint256 _stake9m) {
        TOKEN_HODL_3M = _stake3m;
        TOKEN_HODL_6M = _stake6m;
        TOKEN_HODL_9M = _stake9m;
    }
    /// @notice Adding hodler stake to an account
    /// @dev Only owner contract can call it and before hodling period starts
    /// @param _beneficiary Recepient address of hodler stake
    /// @param _stake Amount of additional hodler stake
    function addHodlerStake(address _beneficiary, uint256 _stake) public onlyOwner beforeHodlStart {
        // real change and valid _beneficiary is needed
        if (_stake == 0 || _beneficiary == address(0))
            return;
        
        // add stake and maintain count
        if (hodlerStakes[_beneficiary].stake == 0)
            hodlerTotalCount = hodlerTotalCount.add(1);
        hodlerStakes[_beneficiary].stake = hodlerStakes[_beneficiary].stake.add(_stake);
        hodlerTotalValue = hodlerTotalValue.add(_stake);
        LogHodlSetStake(msg.sender, _beneficiary, hodlerStakes[_beneficiary].stake);
    }
    /// @notice Setting hodler stake of an account
    /// @dev Only owner contract can call it and before hodling period starts
    /// @param _beneficiary Recepient address of hodler stake
    /// @param _stake Amount to set the hodler stake
    function setHodlerStake(address _beneficiary, uint256 _stake) public onlyOwner beforeHodlStart {
        // real change and valid _beneficiary is needed
        if (hodlerStakes[_beneficiary].stake == _stake || _beneficiary == address(0))
            return;
        
        // add stake and maintain count
        if (hodlerStakes[_beneficiary].stake == 0 && _stake > 0) {
            hodlerTotalCount = hodlerTotalCount.add(1);
        } else if (hodlerStakes[_beneficiary].stake > 0 && _stake == 0) {
            hodlerTotalCount = hodlerTotalCount.sub(1);
        }
        uint256 _diff = _stake > hodlerStakes[_beneficiary].stake ? _stake.sub(hodlerStakes[_beneficiary].stake) : hodlerStakes[_beneficiary].stake.sub(_stake);
        if (_stake > hodlerStakes[_beneficiary].stake) {
            hodlerTotalValue = hodlerTotalValue.add(_diff);
        } else {
            hodlerTotalValue = hodlerTotalValue.sub(_diff);
        }
        hodlerStakes[_beneficiary].stake = _stake;
        LogHodlSetStake(msg.sender, _beneficiary, _stake);
    }
    /// @notice Setting hodler start period.
    /// @param _time The time when hodler reward starts counting
    function setHodlerTime(uint256 _time) public onlyOwner beforeHodlStart {
        require(_time >= now);
        hodlerTimeStart = _time;
        hodlerTime3M = _time.add(90 days);
        hodlerTime6M = _time.add(180 days);
        hodlerTime9M = _time.add(270 days);
        LogHodlStartSet(msg.sender, _time);
    }
    /// @notice Invalidates hodler account 
    /// @dev Gets called by EthealController#onTransfer before every transaction
    function invalidate(address _account) public onlyOwner {
        if (hodlerStakes[_account].stake > 0 && !hodlerStakes[_account].invalid) {
            hodlerStakes[_account].invalid = true;
            hodlerTotalValue = hodlerTotalValue.sub(hodlerStakes[_account].stake);
            hodlerTotalCount = hodlerTotalCount.sub(1);
        }
        // update hodl total values "automatically" - whenever someone sends funds thus
        updateAndGetHodlTotalValue();
    }
    /// @notice Claiming HODL reward for msg.sender
    function claimHodlReward() public {
        claimHodlRewardFor(msg.sender);
    }
    /// @notice Claiming HODL reward for an address
    function claimHodlRewardFor(address _beneficiary) public {
        // only when the address has a valid stake
        require(hodlerStakes[_beneficiary].stake > 0 && !hodlerStakes[_beneficiary].invalid);
        uint256 _stake = 0;
        
        // update hodl total values
        updateAndGetHodlTotalValue();
        // claim hodl if not claimed
        if (!hodlerStakes[_beneficiary].claimed3M && now >= hodlerTime3M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue3M));
            hodlerStakes[_beneficiary].claimed3M = true;
        }
        if (!hodlerStakes[_beneficiary].claimed6M && now >= hodlerTime6M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_6M).div(hodlerTotalValue6M));
            hodlerStakes[_beneficiary].claimed6M = true;
        }
        if (!hodlerStakes[_beneficiary].claimed9M && now >= hodlerTime9M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_9M).div(hodlerTotalValue9M));
            hodlerStakes[_beneficiary].claimed9M = true;
        }
        if (_stake > 0) {
            // increasing claimed tokens
            claimedTokens = claimedTokens.add(_stake);
            // transferring tokens
            require(TokenController(owner).ethealToken().transfer(_beneficiary, _stake));
            // log
            LogHodlClaimed(msg.sender, _beneficiary, _stake);
        }
    }
    /// @notice claimHodlRewardFor() for multiple addresses
    /// @dev Anyone can call this function and distribute hodl rewards
    /// @param _beneficiaries Array of addresses for which we want to claim hodl rewards
    function claimHodlRewardsFor(address[] _beneficiaries) external {
        for (uint256 i = 0; i < _beneficiaries.length; i++)
            claimHodlRewardFor(_beneficiaries[i]);
    }
    /// @notice Setting 3 - 6 - 9 months total staking hodl value if time is come
    function updateAndGetHodlTotalValue() public returns (uint) {
        if (now >= hodlerTime3M && hodlerTotalValue3M == 0) {
            hodlerTotalValue3M = hodlerTotalValue;
        }
        if (now >= hodlerTime6M && hodlerTotalValue6M == 0) {
            hodlerTotalValue6M = hodlerTotalValue;
        }
        if (now >= hodlerTime9M && hodlerTotalValue9M == 0) {
            hodlerTotalValue9M = hodlerTotalValue;
            // since we can transfer more tokens to this contract, make it possible to retain more than the predefined limit
            TOKEN_HODL_9M = TokenController(owner).ethealToken().balanceOf(this).sub(TOKEN_HODL_3M).sub(TOKEN_HODL_6M).add(claimedTokens);
        }
        return hodlerTotalValue;
    }
}
/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  event Released(uint256 amount);
  event Revoked();
  // beneficiary of tokens after they are released
  address public beneficiary;
  uint256 public cliff;
  uint256 public start;
  uint256 public duration;
  bool public revocable;
  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;
  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);
    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }
  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20MiniMe token) public {
    uint256 unreleased = releasableAmount(token);
    require(unreleased > 0);
    released[token] = released[token].add(unreleased);
    require(token.transfer(beneficiary, unreleased));
    Released(unreleased);
  }
  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20MiniMe token which is being vested
   */
  function revoke(ERC20MiniMe token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);
    uint256 balance = token.balanceOf(this);
    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);
    revoked[token] = true;
    require(token.transfer(owner, refund));
    Revoked();
  }
  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param token ERC20MiniMe token which is being vested
   */
  function releasableAmount(ERC20MiniMe token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }
  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20MiniMe token which is being vested
   */
  function vestedAmount(ERC20MiniMe token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);
    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}
/**
 * @title claim accidentally sent tokens
 */
contract HasNoTokens is Ownable {
    event ExtractedTokens(address indexed _token, address indexed _claimer, uint _amount);
    /// @notice This method can be used to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    /// @param _claimer Address that tokens will be send to
    function extractTokens(address _token, address _claimer) onlyOwner public {
        if (_token == 0x0) {
            _claimer.transfer(this.balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        token.transfer(_claimer, balance);
        ExtractedTokens(_token, _claimer, balance);
    }
}
/**
 * @title EthealController
 * @author thesved
 * @notice Controller of the Etheal Token
 * @dev Crowdsale can be only replaced when no active crowdsale is running.
 *  The contract is paused by default. It has to be unpaused to enable token transfer.
 */
contract EthealController is Pausable, HasNoTokens, TokenController {
    using SafeMath for uint;
    // when migrating this contains the address of the new controller
    TokenController public newController;
    // token contract
    ERC20MiniMe public ethealToken;
    // distribution of tokens
    uint256 public constant ETHEAL_UNIT = 10**18;
    uint256 public constant THOUSAND = 10**3;
    uint256 public constant MILLION = 10**6;
    uint256 public constant TOKEN_SALE1_PRE = 9 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_SALE1_NORMAL = 20 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_SALE2 = 9 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_SALE3 = 5 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_HODL_3M = 1 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_HODL_6M = 2 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_HODL_9M = 7 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_REFERRAL = 2 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_BOUNTY = 1500 * THOUSAND * ETHEAL_UNIT;
    uint256 public constant TOKEN_COMMUNITY = 20 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_TEAM = 14 * MILLION * ETHEAL_UNIT;
    uint256 public constant TOKEN_FOUNDERS = 6500 * THOUSAND * ETHEAL_UNIT;
    uint256 public constant TOKEN_INVESTORS = 3 * MILLION * ETHEAL_UNIT;
    // addresses only SALE will remain, the others will be real eth addresses
    address public SALE = 0X1;
    address public FOUNDER1 = 0x296dD2A2879fEBe2dF65f413999B28C053397fC5;
    address public FOUNDER2 = 0x0E2feF8e4125ed0f49eD43C94b2B001C373F74Bf;
    address public INVESTOR1 = 0xAAd27eD6c93d91aa60Dc827bE647e672d15e761A;
    address public INVESTOR2 = 0xb906665f4ef609189A31CE55e01C267EC6293Aa5;
    // addresses for multisig and crowdsale
    address public ethealMultisigWallet;
    Crowdsale public crowdsale;
    // hodler reward contract
    Hodler public hodlerReward;
    // token grants
    TokenVesting[] public tokenGrants;
    uint256 public constant VESTING_TEAM_CLIFF = 365 days;
    uint256 public constant VESTING_TEAM_DURATION = 4 * 365 days;
    uint256 public constant VESTING_ADVISOR_CLIFF = 3 * 30 days;
    uint256 public constant VESTING_ADVISOR_DURATION = 6 * 30 days;
    /// @dev only the crowdsale can call it
    modifier onlyCrowdsale() {
        require(msg.sender == address(crowdsale));
        _;
    }
    /// @dev only the crowdsale can call it
    modifier onlyEthealMultisig() {
        require(msg.sender == address(ethealMultisigWallet));
        _;
    }
    ////////////////
    // Constructor, overrides
    ////////////////
    /// @notice Constructor for Etheal Controller
    function EthealController(address _wallet) {
        require(_wallet != address(0));
        paused = true;
        ethealMultisigWallet = _wallet;
    }
    /// @dev overrides HasNoTokens#extractTokens to make it possible to extract any tokens after migration or before that any tokens except etheal
    function extractTokens(address _token, address _claimer) onlyOwner public {
        require(newController != address(0) || _token != address(ethealToken));
        super.extractTokens(_token, _claimer);
    }
    ////////////////
    // Manage crowdsale
    ////////////////
    /// @notice Set crowdsale address and transfer HEAL tokens from ethealController's SALE address
    /// @dev Crowdsale can be only set when the current crowdsale is not active and ethealToken is set
    function setCrowdsaleTransfer(address _sale, uint256 _amount) public onlyOwner {
        require (_sale != address(0) && !isCrowdsaleOpen() && address(ethealToken) != address(0));
        crowdsale = Crowdsale(_sale);
        // transfer HEAL tokens to crowdsale account from the account of controller
        require(ethealToken.transferFrom(SALE, _sale, _amount));
    }
    /// @notice Is there a not ended crowdsale?
    /// @return true if there is no crowdsale or the current crowdsale is not yet ended but started
    function isCrowdsaleOpen() public view returns (bool) {
        return address(crowdsale) != address(0) && !crowdsale.hasEnded() && crowdsale.hasStarted();
    }
    ////////////////
    // Manage grants
    ////////////////
    /// @notice Grant vesting token to an address
    function createGrant(address _beneficiary, uint256 _start, uint256 _amount, bool _revocable, bool _advisor) public onlyOwner {
        require(_beneficiary != address(0) && _amount > 0 && _start >= now);
        // create token grant
        if (_advisor) {
            tokenGrants.push(new TokenVesting(_beneficiary, _start, VESTING_ADVISOR_CLIFF, VESTING_ADVISOR_DURATION, _revocable));
        } else {
            tokenGrants.push(new TokenVesting(_beneficiary, _start, VESTING_TEAM_CLIFF, VESTING_TEAM_DURATION, _revocable));
        }
        // transfer funds to the grant
        transferToGrant(tokenGrants.length.sub(1), _amount);
    }
    /// @notice Transfer tokens to a grant until it is starting
    function transferToGrant(uint256 _id, uint256 _amount) public onlyOwner {
        require(_id < tokenGrants.length && _amount > 0 && now <= tokenGrants[_id].start());
        // transfer funds to the grant
        require(ethealToken.transfer(address(tokenGrants[_id]), _amount));
    }
    /// @dev Revoking grant
    function revokeGrant(uint256 _id) public onlyOwner {
        require(_id < tokenGrants.length);
        tokenGrants[_id].revoke(ethealToken);
    }
    /// @notice Returns the token grant count
    function getGrantCount() view public returns (uint) {
        return tokenGrants.length;
    }
    ////////////////
    // BURN, handle ownership - only multsig can call these functions!
    ////////////////
    /// @notice contract can burn its own or its sale tokens
    function burn(address _where, uint256 _amount) public onlyEthealMultisig {
        require(_where == address(this) || _where == SALE);
        require(ethealToken.destroyTokens(_where, _amount));
    }
    /// @notice replaces controller when it was not yet replaced, only multisig can do it
    function setNewController(address _controller) public onlyEthealMultisig {
        require(_controller != address(0) && newController == address(0));
        newController = TokenController(_controller);
        ethealToken.changeController(_controller);
        hodlerReward.transferOwnership(_controller);
        // send eth
        uint256 _stake = this.balance;
        if (_stake > 0) {
            _controller.transfer(_stake);
        }
        // send tokens
        _stake = ethealToken.balanceOf(this);
        if (_stake > 0) {
            ethealToken.transfer(_controller, _stake);
        }
    }
    /// @notice Set new multisig wallet, to make it upgradable.
    function setNewMultisig(address _wallet) public onlyEthealMultisig {
        require(_wallet != address(0));
        ethealMultisigWallet = _wallet;
    }
    ////////////////
    // When PAUSED
    ////////////////
    /// @notice set the token, if no hodler provided then creates a hodler reward contract
    function setEthealToken(address _token, address _hodler) public onlyOwner whenPaused {
        require(_token != address(0));
        ethealToken = ERC20MiniMe(_token);
        
        if (_hodler != address(0)) {
            // set hodler reward contract if provided
            hodlerReward = Hodler(_hodler);
        } else if (hodlerReward == address(0)) {
            // create hodler reward contract if not yet created
            hodlerReward = new Hodler(TOKEN_HODL_3M, TOKEN_HODL_6M, TOKEN_HODL_9M);
        }
        // MINT tokens if not minted yet
        if (ethealToken.totalSupply() == 0) {
            // sale
            ethealToken.generateTokens(SALE, TOKEN_SALE1_PRE.add(TOKEN_SALE1_NORMAL).add(TOKEN_SALE2).add(TOKEN_SALE3));
            // hodler reward
            ethealToken.generateTokens(address(hodlerReward), TOKEN_HODL_3M.add(TOKEN_HODL_6M).add(TOKEN_HODL_9M));
            // bounty + referral
            ethealToken.generateTokens(owner, TOKEN_BOUNTY.add(TOKEN_REFERRAL));
            // community fund
            ethealToken.generateTokens(address(ethealMultisigWallet), TOKEN_COMMUNITY);
            // team -> grantable
            ethealToken.generateTokens(address(this), TOKEN_FOUNDERS.add(TOKEN_TEAM));
            // investors
            ethealToken.generateTokens(INVESTOR1, TOKEN_INVESTORS.div(3).mul(2));
            ethealToken.generateTokens(INVESTOR2, TOKEN_INVESTORS.div(3));
        }
    }
    ////////////////
    // Proxy for Hodler contract
    ////////////////
    
    /// @notice Proxy call for setting hodler start time
    function setHodlerTime(uint256 _time) public onlyCrowdsale {
        hodlerReward.setHodlerTime(_time);
    }
    /// @notice Proxy call for adding hodler stake
    function addHodlerStake(address _beneficiary, uint256 _stake) public onlyCrowdsale {
        hodlerReward.addHodlerStake(_beneficiary, _stake);
    }
    /// @notice Proxy call for setting hodler stake
    function setHodlerStake(address _beneficiary, uint256 _stake) public onlyCrowdsale {
        hodlerReward.setHodlerStake(_beneficiary, _stake);
    }
    ////////////////
    // MiniMe Controller functions
    ////////////////
    /// @notice No eth payment to the token contract
    function proxyPayment(address _owner) payable public returns (bool) {
        revert();
    }
    /// @notice Before transfers are enabled for everyone, only this and the crowdsale contract is allowed to distribute HEAL
    function onTransfer(address _from, address _to, uint256 _amount) public returns (bool) {
        // moving any funds makes hodl participation invalid
        hodlerReward.invalidate(_from);
        return !paused || _from == address(this) || _to == address(this) || _from == address(crowdsale) || _to == address(crowdsale);
    }
    function onApprove(address _owner, address _spender, uint256 _amount) public returns (bool) {
        return !paused;
    }
    /// @notice Retrieve mistakenly sent tokens (other than the etheal token) from the token contract 
    function claimTokenTokens(address _token) public onlyOwner {
        require(_token != address(ethealToken));
        ethealToken.claimTokens(_token);
    }
}