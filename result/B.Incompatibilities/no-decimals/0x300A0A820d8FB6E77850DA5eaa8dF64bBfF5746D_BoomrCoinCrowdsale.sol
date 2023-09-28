pragma solidity ^0.4.18;

//*****************************************************
// BOOMR Coin contract
// For LibLob, Zach Spoor, by Michael Hanna
// ****************************************************

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


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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

/**
 * @title Pausable token
 *
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
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

//*****************************************************
// *   BoomrCoinCrowdsale
// *   Info:
//     - Sale will be for 30% (150M of 500) of total tokens
//     - Funding during presale determines price
//     - Times are in UTC (seconds since Jan 1 1970)
//
//*****************************************************
contract BoomrCoinCrowdsale is Ownable{
  using SafeMath for uint256;

  //***************************************************
  //  Settings
  //***************************************************

  // minimum amount of funds to be raised in weis
  uint256 private minGoal = 0;

  // maximum amount of funds to be raised in weis
  uint256 private maxGoal = 0;

  // Tokens for presale
  uint256 private tokenLimitPresale    =  0;

  // Tokens for crowdsale
  uint256 private tokenLimitCrowdsale  = 0;

  // Presale discount for each phase
  uint256 private presaleDiscount    = 0;
  uint256 private crowdsaleDiscount1 = 0;
  uint256 private crowdsaleDiscount2 = 0;
  uint256 private crowdsaleDiscount3 = 0;
  uint256 private crowdsaleDiscount4 = 0;

  // durations for each phase
  uint256 private  presaleDuration    = 0;//604800; // One Week in seconds
  uint256 private  crowdsaleDuration1 = 0;//604800; // One Week in seconds
  uint256 private  crowdsaleDuration2 = 0;//604800; // One Week in seconds
  uint256 private  crowdsaleDuration3 = 0;//604800; // One Week in seconds
  uint256 private  crowdsaleDuration4 = 0;//604800; // One Week in seconds

  //***************************************************
  //  Info
  //***************************************************

  // Tokens Sold
  uint256 private tokenPresaleTotalSold  = 0;
  uint256 private tokenCrowdsaleTotalSold  = 0;

  // Backers
  uint256 private totalBackers  = 0;

  // amount of raised money in wei
  uint256 private weiRaised = 0;

  // prices for each phase
  uint256 private presaleTokenPrice    = 0;
  uint256 private baseTokenPrice = 0;
  uint256 private crowdsaleTokenPrice1 = 0;
  uint256 private crowdsaleTokenPrice2 = 0;
  uint256 private crowdsaleTokenPrice3 = 0;
  uint256 private crowdsaleTokenPrice4 = 0;

  // Count of token distributions by phase
  uint256 private presaleTokenSent     = 0;
  uint256 private crowdsaleTokenSold1  = 0;
  uint256 private crowdsaleTokenSold2  = 0;
  uint256 private crowdsaleTokenSold3  = 0;
  uint256 private crowdsaleTokenSold4  = 0;

  //***************************************************
  //  Vars
  //***************************************************

  // Finalization Flag
  bool private finalized = false;

  // Halted Flag
  bool private halted = false;

  uint256 public startTime;

  // The token being sold
  PausableToken public boomrToken;

  // Address where funds are collected
  address private wallet;

  // refund vault used to hold funds while crowdsale is running
  RefundVault private vault;

  // tracking for deposits
  mapping (address => uint256) public deposits;

  // tracking for purchasers
  mapping (address => uint256) public purchases;

  //***************************************************
  //  Events
  //***************************************************

  // Log event for crowdsale purchase
  event TokenPurchase(address indexed Purchaser, address indexed Beneficiary, uint256 ValueInWei, uint256 TokenAmount);

  // Log event for presale purchase
  event PresalePurchase(address indexed Purchaser, address indexed Beneficiary, uint256 ValueInWei);

  // Log event for distribution of tokens for presale purchasers
  event PresaleDistribution(address indexed Purchaser, address indexed Beneficiary, uint256 TokenAmount);

  // Finalization
  event Finalized();

  //***************************************************
  //  Constructor
  //***************************************************
  function BoomrCoinCrowdsale() public{

  }

  function StartCrowdsale(address _token, address _wallet, uint256 _startTime) public onlyOwner{
    require(_startTime >= now);
    require(_token != 0x0);
    require(_wallet != 0x0);

    // Set the start time
    startTime = _startTime;

    // Assign the token
    boomrToken = PausableToken(_token);

    // Wallet for funds
    wallet = _wallet;

    // Refund vault
    vault = new RefundVault(wallet);

    // minimum amount of funds to be raised in weis
    minGoal = 5000 * 10**18; // Approx 3.5M Dollars
    //minGoal = 1 * 10**18; // testing

    // maximum amount of funds to be raised in weis
    maxGoal = 28600 * 10**18; // Approx 20M Dollars
    //maxGoal = 16 * 10**18; // teesting

    // Tokens for presale
    tokenLimitPresale    =  30000000 * 10**18;
    //uint256 tokenLimitPresale    =  5 * 10**18;  // for testing

    // Tokens for crowdsale
    tokenLimitCrowdsale  = 120000000 * 10**18;
    //uint256 tokenLimitCrowdsale  = 5 * 10**18;

    // Presale discount for each phase
    presaleDiscount    = 25 * 10**16;  // 25%
    crowdsaleDiscount1 = 15 * 10**16;  // 15%
    crowdsaleDiscount2 = 10 * 10**16;  // 10%
    crowdsaleDiscount3 =  5 * 10**16;  //  5%
    crowdsaleDiscount4 =           0;  //  0%

    // durations for each phase
    presaleDuration    = 604800; // One Week in seconds
    crowdsaleDuration1 = 604800; // One Week in seconds
    crowdsaleDuration2 = 604800; // One Week in seconds
    crowdsaleDuration3 = 604800; // One Week in seconds
    crowdsaleDuration4 = 604800; // One Week in seconds

  }

  //***************************************************
  //  Runtime state checks
  //***************************************************

  function currentStateActive() public constant returns ( bool presaleWaitPhase,
                                                          bool presalePhase,
                                                          bool crowdsalePhase1,
                                                          bool crowdsalePhase2,
                                                          bool crowdsalePhase3,
                                                          bool crowdsalePhase4,
                                                          bool buyable,
                                                          bool distributable,
                                                          bool reachedMinimumEtherGoal,
                                                          bool reachedMaximumEtherGoal,
                                                          bool completed,
                                                          bool finalizedAndClosed,
                                                          bool stopped){

    return (  isPresaleWaitPhase(),
              isPresalePhase(),
              isCrowdsalePhase1(),
              isCrowdsalePhase2(),
              isCrowdsalePhase3(),
              isCrowdsalePhase4(),
              isBuyable(),
              isDistributable(),
              minGoalReached(),
              maxGoalReached(),
              isCompleted(),
              finalized,
              halted);
  }

  function currentStateSales() public constant returns (uint256 PresaleTokenPrice,
                                                        uint256 BaseTokenPrice,
                                                        uint256 CrowdsaleTokenPrice1,
                                                        uint256 CrowdsaleTokenPrice2,
                                                        uint256 CrowdsaleTokenPrice3,
                                                        uint256 CrowdsaleTokenPrice4,
                                                        uint256 TokenPresaleTotalSold,
                                                        uint256 TokenCrowdsaleTotalSold,
                                                        uint256 TotalBackers,
                                                        uint256 WeiRaised,
                                                        address Wallet,
                                                        uint256 GoalInWei,
                                                        uint256 RemainingTokens){

    return (  presaleTokenPrice,
              baseTokenPrice,
              crowdsaleTokenPrice1,
              crowdsaleTokenPrice2,
              crowdsaleTokenPrice3,
              crowdsaleTokenPrice4,
              tokenPresaleTotalSold,
              tokenCrowdsaleTotalSold,
              totalBackers,
              weiRaised,
              wallet,
              minGoal,
              getContractTokenBalance());

  }

  function currentTokenDistribution() public constant returns (uint256 PresalePhaseTokens,
                                                               uint256 CrowdsalePhase1Tokens,
                                                               uint256 CrowdsalePhase2Tokens,
                                                               uint256 CrowdsalePhase3Tokens,
                                                               uint256 CrowdsalePhase4Tokens){

    return (  presaleTokenSent,
              crowdsaleTokenSold1,
              crowdsaleTokenSold2,
              crowdsaleTokenSold3,
              crowdsaleTokenSold4);

  }

  function isPresaleWaitPhase() internal constant returns (bool){
    return startTime >= now;
  }

  function isPresalePhase() internal constant returns (bool){
    return startTime < now && (startTime + presaleDuration) >= now && !maxGoalReached();
  }

  function isCrowdsalePhase1() internal constant returns (bool){
    return (startTime + presaleDuration) < now && (startTime + presaleDuration + crowdsaleDuration1) >= now && !maxGoalReached();
  }

  function isCrowdsalePhase2() internal constant returns (bool){
    return (startTime + presaleDuration + crowdsaleDuration1) < now && (startTime + presaleDuration + crowdsaleDuration1 + crowdsaleDuration2) >= now && !maxGoalReached();
  }

  function isCrowdsalePhase3() internal constant returns (bool){
    return (startTime + presaleDuration + crowdsaleDuration1 + crowdsaleDuration2) < now && (startTime + presaleDuration + crowdsaleDuration1 + crowdsaleDuration2 + crowdsaleDuration3) >= now && !maxGoalReached();
  }

  function isCrowdsalePhase4() internal constant returns (bool){
    return (startTime + presaleDuration + crowdsaleDuration1 + crowdsaleDuration2 + crowdsaleDuration3) < now && (startTime + presaleDuration + crowdsaleDuration1 + crowdsaleDuration2 + crowdsaleDuration3 + crowdsaleDuration4) >= now && !maxGoalReached();
  }

  function isCompleted() internal constant returns (bool){
    return (startTime + presaleDuration + crowdsaleDuration1 + crowdsaleDuration2 + crowdsaleDuration3 + crowdsaleDuration4) < now || maxGoalReached();
  }

  function isDistributable() internal constant returns (bool){
    return (startTime + presaleDuration) < now;
  }

  function isBuyable() internal constant returns (bool){
    return isDistributable() && !isCompleted();
  }

  // Test if we reached the goals
  function minGoalReached() internal constant returns (bool) {
    return weiRaised >= minGoal;
  }

  function maxGoalReached() internal constant returns (bool) {
    return weiRaised >= maxGoal;
  }

  //***************************************************
  //  Contract's token balance
  //***************************************************
  function getContractTokenBalance() internal constant returns (uint256) {
    return boomrToken.balanceOf(this);
  }

  //***************************************************
  //  Emergency functions
  //***************************************************
  function halt() public onlyOwner{
    halted = true;
  }

  function unHalt() public onlyOwner{
    halted = false;
  }

  //***************************************************
  //  Update all the prices
  //***************************************************
  function updatePrices() internal {

    presaleTokenPrice = weiRaised.mul(1 ether).div(tokenLimitPresale);
    baseTokenPrice = (presaleTokenPrice * (1 ether)) / ((1 ether) - presaleDiscount);
    crowdsaleTokenPrice1 = baseTokenPrice - ((baseTokenPrice * crowdsaleDiscount1)/(1 ether));
    crowdsaleTokenPrice2 = baseTokenPrice - ((baseTokenPrice * crowdsaleDiscount2)/(1 ether));
    crowdsaleTokenPrice3 = baseTokenPrice - ((baseTokenPrice * crowdsaleDiscount3)/(1 ether));
    crowdsaleTokenPrice4 = baseTokenPrice - ((baseTokenPrice * crowdsaleDiscount4)/(1 ether));
  }

  //***************************************************
  //  Default presale and token purchase
  //***************************************************
  function () public payable{
    if(msg.value == 0 && isDistributable())
    {
      distributePresale(msg.sender);
    }else{
      require(!isPresaleWaitPhase() && !isCompleted());

      // Select purchase action
      if (isPresalePhase()){

        // Presale deposit
        depositPresale(msg.sender);

      }else{
        // Buy the tokens
        buyTokens(msg.sender);
      }
    }
  }

  //***************************************************
  //  Low level deposit
  //***************************************************
  function depositPresale(address beneficiary) public payable{
    internalDepositPresale(beneficiary, msg.value);
  }

  function internalDepositPresale(address beneficiary, uint256 deposit) internal{
    require(!halted);
    require(beneficiary != 0x0);
    require(deposit != 0);
    require(isPresalePhase());
    require(!maxGoalReached());

    // Amount invested
    uint256 weiAmount = deposit;

    // If real deposit from person then forward funds
    // otherwise it was from the manual routine for external
    // deposits that were made in fiat instead of ether
    if (msg.value > 0)
    {
      // Send funds to main wallet
      forwardFunds();
    }

    // Total innvested so far
    weiRaised = weiRaised.add(weiAmount);

    // Mark the deposits, add if they deposit more than once
    deposits[beneficiary] += weiAmount;
    totalBackers++;

    // Determine the current price
    updatePrices();

    // emit event for logging
    PresalePurchase(msg.sender, beneficiary, weiAmount);
  }

  //***************************************************
  //  Token distribution for presale purchasers
  //***************************************************
  function distributePresale(address beneficiary) public{
    require(!halted);
    require(isDistributable());
    require(deposits[beneficiary] > 0);
    require(beneficiary != 0x0);

    // Amount investesd
    uint256 weiDeposit = deposits[beneficiary];

    // prevent re-entrancy
    deposits[beneficiary] = 0;

    // tokens out
    uint256 tokensOut = weiDeposit.mul(1 ether).div(presaleTokenPrice);

    //trackTokens(tokensOut, index);
    tokenPresaleTotalSold += tokensOut;
    //presaleTokenSent += tokensOut;

    // transfer tokens
    boomrToken.transfer(beneficiary, tokensOut);

    // emit event for logging
    PresaleDistribution(msg.sender, beneficiary, tokensOut);
  }

  //***************************************************
  //  Low level purchase
  //***************************************************
  function buyTokens(address beneficiary) public payable{
    internalBuyTokens(beneficiary, msg.value);
  }

  function internalBuyTokens(address beneficiary, uint256 deposit) internal{
    require(!halted);
    require(beneficiary != 0x0);
    require(deposit != 0);
    require(isCrowdsalePhase1() || isCrowdsalePhase2() || isCrowdsalePhase3() || isCrowdsalePhase4());
    require(!maxGoalReached());

    uint256 price = 0;

    if (isCrowdsalePhase1()){
      price = crowdsaleTokenPrice1;
    }else if (isCrowdsalePhase2()){
      price = crowdsaleTokenPrice2;
    }else if (isCrowdsalePhase3()){
      price = crowdsaleTokenPrice3;
    }else if (isCrowdsalePhase4()){
      price = crowdsaleTokenPrice4;
    }else{
      price = baseTokenPrice;
    }

    // Amount of ether sent
    uint256 weiAmount = deposit;

    // calculate reward
    uint256 tokensOut = weiAmount.mul(1 ether).div(price);

    // make sure we are not over sold
    require(tokensOut + tokenCrowdsaleTotalSold < tokenLimitCrowdsale);

    // If real deposit from person then forward funds
    // otherwise it was from the manual routine for external
    // deposits that were made in fiat instead of ether
    if (msg.value > 0)
    {
      // Send funds to main wallet
      forwardFunds();
    }

    // Update raised
    weiRaised = weiRaised.add(weiAmount);

    // Track purchases
    purchases[beneficiary] += weiRaised;

    // track issued
    tokenCrowdsaleTotalSold += tokensOut;

    if (isCrowdsalePhase1()){
      crowdsaleTokenSold1 += tokensOut;
    }else if (isCrowdsalePhase2()){
      crowdsaleTokenSold2 += tokensOut;
    }else if (isCrowdsalePhase3()){
      crowdsaleTokenSold3 += tokensOut;
    }else if (isCrowdsalePhase4()){
      crowdsaleTokenSold4 += tokensOut;
    }

    // Send to buyers
    boomrToken.transfer(beneficiary, tokensOut);

    // Emit event for logging
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokensOut);

    // Track the backers
    totalBackers++;
  }

  // For deposits that do not come thru the contract
  function externalDeposit(address beneficiary, uint256 amount) public onlyOwner{
      require(!isPresaleWaitPhase() && !isCompleted());

      // Select purchase action
      if (isPresalePhase()){

        // Presale deposit
        internalDepositPresale(beneficiary, amount);

      }else{
        // Buy the tokens
        internalBuyTokens(beneficiary, amount);
      }
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    //wallet.transfer(msg.value);
    vault.deposit.value(msg.value)(msg.sender);
  }

    // if crowdsale is unsuccessful, investors can claim refunds here
  function claimRefund() public{
    require(!halted);
    require(finalized);
    require(!minGoalReached());

    vault.refund(msg.sender);
  }

  // Should be called after crowdsale ends, to do
  // some extra finalization work
  function finalize() public onlyOwner{
    require(!finalized);
    require(isCompleted());

    if (minGoalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    finalized = true;
    Finalized();
  }
}