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
/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;
  uint256 public cap;
  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }
  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase(uint256 weiAmount) internal view returns (bool) {
    return super.validPurchase(weiAmount) && !capReached();
  }
  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return super.hasEnded() || capReached();
  }
  // @return true if cap has been reached
  function capReached() internal view returns (bool) {
   return weiRaised >= cap;
  }
  // overriding Crowdsale#buyTokens to add partial refund logic
  function buyTokens(address beneficiary) public payable {
     uint256 weiToCap = cap.sub(weiRaised);
     uint256 weiAmount = weiToCap < msg.value ? weiToCap : msg.value;
     buyTokens(beneficiary, weiAmount);
     uint256 refund = msg.value.sub(weiAmount);
     if (refund > 0) {
       msg.sender.transfer(refund);
     }
   }
}
/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
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
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable, HasNoTokens {
  using SafeMath for uint256;
  enum State { Active, Refunding, Closed }
  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;
  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);
  function RefundVault(address _wallet) {
    require(_wallet != 0x0);
    wallet = _wallet;
    state = State.Active;
  }
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }
  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }
  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}
/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale's vault.
 */
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;
  // minimum amount of funds to be raised in weis
  uint256 public goal;
  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;
  function RefundableCrowdsale(uint256 _goal) {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }
  // We're overriding the fund forwarding from Crowdsale.
  // If the goal is reached forward the fund to the wallet, 
  // otherwise in addition to sending the funds, we want to
  // call the RefundVault deposit function
  function forwardFunds(uint256 weiAmount) internal {
    if (goalReached())
      wallet.transfer(weiAmount);
    else
      vault.deposit.value(weiAmount)(msg.sender);
  }
  // if crowdsale is unsuccessful, investors can claim refunds here
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());
    vault.refund(msg.sender);
  }
  // vault finalization task, called when owner calls finalize()
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }
    super.finalization();
  }
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
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
 * @title EthealPreSale
 * @author thesved
 * @notice Etheal Token Sale round one presale contract, with mincap (goal), softcap and hardcap (cap)
 * @dev This contract has to be finalized before refund or token claims are enabled
 */
contract EthealPreSale is Pausable, CappedCrowdsale, RefundableCrowdsale {
    // the token is here
    TokenController public ethealController;
    // after reaching {weiRaised} >= {softCap}, there is {softCapTime} seconds until the sale closes
    // {softCapClose} contains the closing time
    uint256 public rate = 1250;
    uint256 public goal = 333 ether;
    uint256 public softCap = 3600 ether;
    uint256 public softCapTime = 120 hours;
    uint256 public softCapClose;
    uint256 public cap = 7200 ether;
    // how many token is sold and not claimed, used for refunding to token controller
    uint256 public tokenBalance;
    // total token sold
    uint256 public tokenSold;
    // contributing above {maxGasPrice} results in 
    // calculating stakes on {maxGasPricePenalty} / 100
    // eg. 80 {maxGasPricePenalty} means 80%, sending 5 ETH with more than 100gwei gas price will be calculated as 4 ETH
    uint256 public maxGasPrice = 100 * 10**9;
    uint256 public maxGasPricePenalty = 80;
    // minimum contribution, 0.1ETH
    uint256 public minContribution = 0.1 ether;
    // first {whitelistDayCount} days of token sale is exclusive for whitelisted addresses
    // {whitelistDayMaxStake} contains the max stake limits per address for each whitelist sales day
    // {whitelist} contains who can contribute during whitelist period
    uint8 public whitelistDayCount;
    mapping (address => bool) public whitelist;
    mapping (uint8 => uint256) public whitelistDayMaxStake;
    
    // stakes contains contribution stake in wei
    // contributed ETH is calculated on 80% when sending funds with gasprice above maxGasPrice
    mapping (address => uint256) public stakes;
    // addresses of contributors to handle finalization after token sale end (refunds or token claims)
    address[] public contributorsKeys; 
    // events for token purchase during sale and claiming tokens after sale
    event TokenClaimed(address indexed _claimer, address indexed _beneficiary, uint256 _stake, uint256 _amount);
    event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _stake, uint256 _amount, uint256 _participants, uint256 _weiRaised);
    event TokenGoalReached();
    event TokenSoftCapReached(uint256 _closeTime);
    // whitelist events for adding days with maximum stakes and addresses
    event WhitelistAddressAdded(address indexed _whitelister, address indexed _beneficiary);
    event WhitelistAddressRemoved(address indexed _whitelister, address indexed _beneficiary);
    event WhitelistSetDay(address indexed _whitelister, uint8 _day, uint256 _maxStake);
    ////////////////
    // Constructor and inherited function overrides
    ////////////////
    /// @notice Constructor to create PreSale contract
    /// @param _ethealController Address of ethealController
    /// @param _startTime The start time of token sale in seconds.
    /// @param _endTime The end time of token sale in seconds.
    /// @param _minContribution The minimum contribution per transaction in wei (0.1 ETH)
    /// @param _rate Number of HEAL tokens per 1 ETH
    /// @param _goal Minimum funding in wei, below that EVERYONE gets back ALL their
    ///  contributions regardless of maxGasPrice penalty. 
    ///  Eg. someone contributes with 5 ETH, but gets only 4 ETH stakes because
    ///  sending funds with gasprice over 100Gwei, he will still get back >>5 ETH<<
    ///  in case of unsuccessful token sale
    /// @param _softCap Softcap in wei, reaching it ends the sale in _softCapTime seconds
    /// @param _softCapTime Seconds until the sale remains open after reaching _softCap
    /// @param _cap Maximum cap in wei, we can't raise more funds
    /// @param _gasPrice Maximum gas price
    /// @param _gasPenalty Penalty in percentage points for calculating stakes, eg. 80 means calculating 
    ///  stakes on 80% if gasprice was higher than _gasPrice
    /// @param _wallet Address of multisig wallet, which will get all the funds after successful sale
    function EthealPreSale(
        address _ethealController,
        uint256 _startTime, 
        uint256 _endTime, 
        uint256 _minContribution, 
        uint256 _rate, 
        uint256 _goal, 
        uint256 _softCap, 
        uint256 _softCapTime, 
        uint256 _cap, 
        uint256 _gasPrice, 
        uint256 _gasPenalty, 
        address _wallet
    )
        CappedCrowdsale(_cap)
        FinalizableCrowdsale()
        RefundableCrowdsale(_goal)
        Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        // ethealController must be valid
        require(_ethealController != address(0));
        ethealController = TokenController(_ethealController);
        // caps have to be consistent with each other
        require(_goal <= _softCap && _softCap <= _cap);
        softCap = _softCap;
        softCapTime = _softCapTime;
        // this is needed since super constructor wont overwite overriden variables
        cap = _cap;
        goal = _goal;
        rate = _rate;
        maxGasPrice = _gasPrice;
        maxGasPricePenalty = _gasPenalty;
        minContribution = _minContribution;
    }
    /// @dev Overriding Crowdsale#buyTokens to add partial refund and softcap logic 
    /// @param _beneficiary Beneficiary of the token purchase
    function buyTokens(address _beneficiary) public payable whenNotPaused {
        require(_beneficiary != address(0));
        uint256 weiToCap = howMuchCanXContributeNow(_beneficiary);
        uint256 weiAmount = uint256Min(weiToCap, msg.value);
        // goal is reached
        if (weiRaised < goal && weiRaised.add(weiAmount) >= goal) {
            TokenGoalReached();
        }
        // call the Crowdsale#buyTokens internal function
        buyTokens(_beneficiary, weiAmount);
        // close sale in softCapTime seconds after reaching softCap
        if (weiRaised >= softCap && softCapClose == 0) {
            softCapClose = now.add(softCapTime);
            TokenSoftCapReached(uint256Min(softCapClose, endTime));
        }
        // handle refund
        uint256 refund = msg.value.sub(weiAmount);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }
    /// @dev Overriding Crowdsale#transferToken, which keeps track of contributions DURING token sale
    /// @param _beneficiary Address of the recepient of the tokens
    /// @param _weiAmount Contribution in wei
    function transferToken(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        uint256 weiAmount = _weiAmount;
        // check maxGasPricePenalty
        if (maxGasPrice > 0 && tx.gasprice > maxGasPrice) {
            weiAmount = weiAmount.mul(maxGasPricePenalty).div(100);
        }
        // calculate tokens, so we can refund excess tokens to EthealController after token sale
        uint256 tokens = weiAmount.mul(rate);
        tokenBalance = tokenBalance.add(tokens);
        if (stakes[_beneficiary] == 0) {
            contributorsKeys.push(_beneficiary);
        }
        stakes[_beneficiary] = stakes[_beneficiary].add(weiAmount);
        TokenPurchase(msg.sender, _beneficiary, _weiAmount, weiAmount, tokens, contributorsKeys.length, weiRaised);
    }
    /// @dev Overriding Crowdsale#validPurchase to add min contribution logic
    /// @param _weiAmount Contribution amount in wei
    /// @return true if contribution is okay
    function validPurchase(uint256 _weiAmount) internal view returns (bool) {
        return super.validPurchase(_weiAmount) && _weiAmount >= minContribution;
    }
    /// @dev Overriding Crowdsale#hasEnded to add soft cap logic
    /// @return true if crowdsale event has ended or a softCapClose time is set and passed
    function hasEnded() public view returns (bool) {
        return super.hasEnded() || softCapClose > 0 && now > softCapClose;
    }
    /// @dev Overriding RefundableCrowdsale#claimRefund to enable anyone to call for any address
    ///  which enables us to refund anyone and also anyone can refund themselves
    function claimRefund() public {
        claimRefundFor(msg.sender);
    }
    /// @dev Extending RefundableCrowdsale#finalization sending back excess tokens to ethealController
    function finalization() internal {
        uint256 _balance = getHealBalance();
        // if token sale was successful send back excess funds
        if (goalReached()) {
            // saving token balance for future reference
            tokenSold = tokenBalance; 
            // send back the excess token to ethealController
            if (_balance > tokenBalance) {
                ethealController.ethealToken().transfer(ethealController.SALE(), _balance.sub(tokenBalance));
            }
        } else if (!goalReached() && _balance > 0) {
            // if token sale is failed, then send back all tokens to ethealController's sale address
            tokenBalance = 0;
            ethealController.ethealToken().transfer(ethealController.SALE(), _balance);
        }
        super.finalization();
    }
    ////////////////
    // BEFORE token sale
    ////////////////
    /// @notice Modifier for before sale cases
    modifier beforeSale() {
        require(!hasStarted());
        _;
    }
    /// @notice Sets whitelist
    /// @dev The length of _whitelistLimits says that the first X days of token sale is 
    ///  closed, meaning only for whitelisted addresses.
    /// @param _add Array of addresses to add to whitelisted ethereum accounts
    /// @param _remove Array of addresses to remove to whitelisted ethereum accounts
    /// @param _whitelistLimits Array of limits in wei, where _whitelistLimits[0] = 10 ETH means
    ///  whitelisted addresses can contribute maximum 10 ETH stakes on the first day
    ///  After _whitelistLimits.length days, there will be no limits per address (besides hard cap)
    function setWhitelist(address[] _add, address[] _remove, uint256[] _whitelistLimits) public onlyOwner beforeSale {
        uint256 i = 0;
        uint8 j = 0; // access max daily stakes
        // we override whiteListLimits only if it was supplied as an argument
        if (_whitelistLimits.length > 0) {
            // saving whitelist max stake limits for each day -> uint256 maxStakeLimit
            whitelistDayCount = uint8(_whitelistLimits.length);
            for (i = 0; i < _whitelistLimits.length; i++) {
                j = uint8(i.add(1));
                if (whitelistDayMaxStake[j] != _whitelistLimits[i]) {
                    whitelistDayMaxStake[j] = _whitelistLimits[i];
                    WhitelistSetDay(msg.sender, j, _whitelistLimits[i]);
                }
            }
        }
        // adding whitelist addresses
        for (i = 0; i < _add.length; i++) {
            require(_add[i] != address(0));
            
            if (!whitelist[_add[i]]) {
                whitelist[_add[i]] = true;
                WhitelistAddressAdded(msg.sender, _add[i]);
            }
        }
        // removing whitelist addresses
        for (i = 0; i < _remove.length; i++) {
            require(_remove[i] != address(0));
            
            if (whitelist[_remove[i]]) {
                whitelist[_remove[i]] = false;
                WhitelistAddressRemoved(msg.sender, _remove[i]);
            }
        }
    }
    /// @notice Sets max gas price and penalty before sale
    function setMaxGas(uint256 _maxGas, uint256 _penalty) public onlyOwner beforeSale {
        maxGasPrice = _maxGas;
        maxGasPricePenalty = _penalty;
    }
    /// @notice Sets min contribution before sale
    function setMinContribution(uint256 _minContribution) public onlyOwner beforeSale {
        minContribution = _minContribution;
    }
    /// @notice Sets minimum goal, soft cap and max cap
    function setCaps(uint256 _goal, uint256 _softCap, uint256 _softCapTime, uint256 _cap) public onlyOwner beforeSale {
        require(0 < _goal && _goal <= _softCap && _softCap <= _cap);
        goal = _goal;
        softCap = _softCap;
        softCapTime = _softCapTime;
        cap = _cap;
    }
    /// @notice Sets crowdsale start and end time
    function setTimes(uint256 _startTime, uint256 _endTime) public onlyOwner beforeSale {
        require(_startTime > now && _startTime < _endTime);
        startTime = _startTime;
        endTime = _endTime;
    }
    /// @notice Set rate
    function setRate(uint256 _rate) public onlyOwner beforeSale {
        require(_rate > 0);
        rate = _rate;
    }
    ////////////////
    // AFTER token sale
    ////////////////
    /// @notice Modifier for cases where sale is failed
    /// @dev It checks whether we haven't reach the minimum goal AND whether the contract is finalized
    modifier afterSaleFail() {
        require(!goalReached() && isFinalized);
        _;
    }
    /// @notice Modifier for cases where sale is closed and was successful.
    /// @dev It checks whether
    ///  the sale has ended 
    ///  and we have reached our goal
    ///  AND whether the contract is finalized
    modifier afterSaleSuccess() {
        require(goalReached() && isFinalized);
        _;
    }
    /// @notice Modifier for after sale finalization
    modifier afterSale() {
        require(isFinalized);
        _;
    }
    
    /// @notice Refund an ethereum address
    /// @param _beneficiary Address we want to refund
    function claimRefundFor(address _beneficiary) public afterSaleFail whenNotPaused {
        require(_beneficiary != address(0));
        vault.refund(_beneficiary);
    }
    /// @notice Refund several addresses with one call
    /// @param _beneficiaries Array of addresses we want to refund
    function claimRefundsFor(address[] _beneficiaries) external afterSaleFail {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            claimRefundFor(_beneficiaries[i]);
        }
    }
    /// @notice Claim token for msg.sender after token sale based on stake.
    function claimToken() public afterSaleSuccess {
        claimTokenFor(msg.sender);
    }
    /// @notice Claim token after token sale based on stake.
    /// @dev Anyone can call this function and distribute tokens after successful token sale
    /// @param _beneficiary Address of the beneficiary who gets the token
    function claimTokenFor(address _beneficiary) public afterSaleSuccess whenNotPaused {
        uint256 stake = stakes[_beneficiary];
        require(stake > 0);
        // set the stake 0 for beneficiary
        stakes[_beneficiary] = 0;
        // calculate token count
        uint256 tokens = stake.mul(rate);
        // decrease tokenBalance, to make it possible to withdraw excess HEAL funds
        tokenBalance = tokenBalance.sub(tokens);
        // distribute hodlr stake
        ethealController.addHodlerStake(_beneficiary, tokens.mul(2));
        // distribute token
        require(ethealController.ethealToken().transfer(_beneficiary, tokens));
        TokenClaimed(msg.sender, _beneficiary, stake, tokens);
    }
    /// @notice claimToken() for multiple addresses
    /// @dev Anyone can call this function and distribute tokens after successful token sale
    /// @param _beneficiaries Array of addresses for which we want to claim tokens
    function claimTokensFor(address[] _beneficiaries) external afterSaleSuccess {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            claimTokenFor(_beneficiaries[i]);
        }
    }
    /// @notice Get back accidentally sent token from the vault
    function extractVaultTokens(address _token, address _claimer) public onlyOwner afterSale {
        // it has to have a valid claimer, and either the goal has to be reached or the token can be 0 which means we can't extract ether if the goal is not reached
        require(_claimer != address(0));
        require(goalReached() || _token != address(0));
        vault.extractTokens(_token, _claimer);
    }
    ////////////////
    // Constant, helper functions
    ////////////////
    /// @notice How many wei can the msg.sender contribute now.
    function howMuchCanIContributeNow() view public returns (uint256) {
        return howMuchCanXContributeNow(msg.sender);
    }
    /// @notice How many wei can an ethereum address contribute now.
    /// @dev This function can return 0 when the crowdsale is stopped
    ///  or the address has maxed the current day's whitelist cap,
    ///  it is possible, that next day he can contribute
    /// @param _beneficiary Ethereum address
    /// @return Number of wei the _beneficiary can contribute now.
    function howMuchCanXContributeNow(address _beneficiary) view public returns (uint256) {
        require(_beneficiary != address(0));
        if (!hasStarted() || hasEnded()) {
            return 0;
        }
        // wei to hard cap
        uint256 weiToCap = cap.sub(weiRaised);
        // if this is a whitelist limited period
        uint8 _saleDay = getSaleDayNow();
        if (_saleDay <= whitelistDayCount) {
            // address can't contribute if
            //  it is not whitelisted
            if (!whitelist[_beneficiary]) {
                return 0;
            }
            // personal cap is the daily whitelist limit minus the stakes the address already has
            uint256 weiToPersonalCap = whitelistDayMaxStake[_saleDay].sub(stakes[_beneficiary]);
            // calculate for maxGasPrice penalty
            if (msg.value > 0 && maxGasPrice > 0 && tx.gasprice > maxGasPrice) {
                weiToPersonalCap = weiToPersonalCap.mul(100).div(maxGasPricePenalty);
            }
            weiToCap = uint256Min(weiToCap, weiToPersonalCap);
        }
        return weiToCap;
    }
    /// @notice For a give date how many 24 hour blocks have ellapsed since token sale start
    /// @dev _time has to be bigger than the startTime of token sale, otherwise SafeMath's div will throw.
    ///  Within 24 hours of token sale it will return 1, 
    ///  between 24 and 48 hours it will return 2, etc.
    /// @param _time Date in seconds for which we want to know which sale day it is
    /// @return Number of 24 hour blocks ellapsing since token sale start starting from 1
    function getSaleDay(uint256 _time) view public returns (uint8) {
        return uint8(_time.sub(startTime).div(60*60*24).add(1));
    }
    /// @notice How many 24 hour blocks have ellapsed since token sale start
    /// @return Number of 24 hour blocks ellapsing since token sale start starting from 1
    function getSaleDayNow() view public returns (uint8) {
        return getSaleDay(now);
    }
    /// @notice Minimum between two uint8 numbers
    function uint8Min(uint8 a, uint8 b) pure internal returns (uint8) {
        return a > b ? b : a;
    }
    /// @notice Minimum between two uint256 numbers
    function uint256Min(uint256 a, uint256 b) pure internal returns (uint256) {
        return a > b ? b : a;
    }
    ////////////////
    // Test and contribution web app, NO audit is needed
    ////////////////
    /// @notice Was this token sale successful?
    /// @return true if the sale is over and we have reached the minimum goal
    function wasSuccess() view public returns (bool) {
        return hasEnded() && goalReached();
    }
    /// @notice How many contributors we have.
    /// @return Number of different contributor ethereum addresses
    function getContributorsCount() view public returns (uint256) {
        return contributorsKeys.length;
    }
    /// @notice Get contributor addresses to manage refunds or token claims.
    /// @dev If the sale is not yet successful, then it searches in the RefundVault.
    ///  If the sale is successful, it searches in contributors.
    /// @param _pending If true, then returns addresses which didn't get refunded or their tokens distributed to them
    /// @param _claimed If true, then returns already refunded or token distributed addresses
    /// @return Array of addresses of contributors
    function getContributors(bool _pending, bool _claimed) view public returns (address[] contributors) {
        uint256 i = 0;
        uint256 results = 0;
        address[] memory _contributors = new address[](contributorsKeys.length);
        // if we have reached our goal, then search in contributors, since this is what we want to monitor
        if (goalReached()) {
            for (i = 0; i < contributorsKeys.length; i++) {
                if (_pending && stakes[contributorsKeys[i]] > 0 || _claimed && stakes[contributorsKeys[i]] == 0) {
                    _contributors[results] = contributorsKeys[i];
                    results++;
                }
            }
        } else {
            // otherwise search in the refund vault
            for (i = 0; i < contributorsKeys.length; i++) {
                if (_pending && vault.deposited(contributorsKeys[i]) > 0 || _claimed && vault.deposited(contributorsKeys[i]) == 0) {
                    _contributors[results] = contributorsKeys[i];
                    results++;
                }
            }
        }
        contributors = new address[](results);
        for (i = 0; i < results; i++) {
            contributors[i] = _contributors[i];
        }
        return contributors;
    }
    /// @notice How many HEAL tokens do this contract have
    function getHealBalance() view public returns (uint256) {
        return ethealController.ethealToken().balanceOf(address(this));
    }
    
    
    /// @notice Get current date for web3
    function getNow() view public returns (uint256) {
        return now;
    }
}