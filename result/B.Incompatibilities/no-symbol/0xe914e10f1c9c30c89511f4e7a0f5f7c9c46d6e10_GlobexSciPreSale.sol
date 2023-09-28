pragma solidity ^0.4.14;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}


interface GlobexSci {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}


/**
 * @title  
 * @dev DatCrowdSale is a contract for managing a token crowdsale.
 * GlobexSciCrowdSale have a start and end date, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a refundable valut 
 * as they arrive.
 */
contract GlobexSciPreSale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  GlobexSci public token = GlobexSci(0x88dBd3f9E6809FC24d27B9403371Af1cC089ba9e);

  // start and end date where investments are allowed (both inclusive)
  uint256 public startDate = 1517961600; //Wed, 07 Feb 2018 00:00:00 +0000
  uint256 public endDate = 1520380800; //Web, 07 Mar 2018 00:00:00 +0000

  // Minimum amount to participate
  uint256 public minimumParticipationAmount = 100000000000000000 wei; //0.1 ether

  // address where funds are collected
  address wallet;

  // how many token units a buyer gets per ether
  uint256 rate = 650;

  // amount of raised money in wei
  uint256 public weiRaised;

  //flag for final of crowdsale
  bool public isFinalized = false;

  //cap for the sale
  uint256 public cap = 3076920000000000000000 wei; //3076 ether
 


  event Finalized();

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */ 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  /**
  * @notice Log an event for each funding contributed during the public phase
  * @notice Events are not logged when the constructor is being executed during
  *         deployment, so the preallocations will not be logged
  */
  event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);


  
  function GlobexSciPreSale() {
    wallet = msg.sender;
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    //get ammount in wei
    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    //purchase tokens and transfer to beneficiary
    token.transfer(beneficiary, tokens);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    //Token purchase event
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    //forward funds to wallet
    forwardFunds();
  }


  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // should be called after crowdsale ends or to emergency stop the sale
  function finalize() onlyOwner {
    require(!isFinalized);
    uint256 unsoldTokens = token.balanceOf(this);
    token.transfer(wallet, unsoldTokens);
    isFinalized = true;
    Finalized();
  }


  // @return true if the transaction can buy tokens
  // check for valid time period, min amount and within cap
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = startDate <= now && endDate >= now;
    bool nonZeroPurchase = msg.value != 0;
    bool minAmount = msg.value >= minimumParticipationAmount;
    bool withinCap = weiRaised.add(msg.value) <= cap;

    return withinPeriod && nonZeroPurchase && minAmount && !isFinalized && withinCap;
  }

    // @return true if the goal is reached
  function capReached() public constant returns (bool) {
    return weiRaised >= cap;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return isFinalized;
  }

}