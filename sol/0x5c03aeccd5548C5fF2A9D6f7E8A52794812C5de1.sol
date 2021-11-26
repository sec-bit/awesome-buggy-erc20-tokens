pragma solidity 0.4.19;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    //   require(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    //   require(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

contract ControllerInterface {

  function totalSupply() constant returns (uint256);
  function balanceOf(address _owner) constant returns (uint256);
  function allowance(address _owner, address _spender) constant returns (uint256);

  function approve(address owner, address spender, uint256 value) public returns (bool);
  function transfer(address owner, address to, uint value, bytes data) public returns (bool);
  function transferFrom(address owner, address from, address to, uint256 amount, bytes data) public returns (bool);
  function mint(address _to, uint256 _amount)  public returns (bool);
}

/**
 * @title CrowdsaleBase
 * @dev CrowdsaleBase is a base contract for managing a token crowdsale.
 * All crowdsale contracts must inherit this contract.
 */

contract CrowdsaleBase {
  using SafeMath for uint256;

  address public controller;
  uint256 public startTime;
  address public wallet;
  uint256 public weiRaised;
  uint256 public endTime;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }

  function CrowdsaleBase(uint256 _startTime, address _wallet, address _controller) public {
    require(_wallet != address(0));

    controller = _controller;
    startTime = _startTime;
    wallet = _wallet;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

  // send ether to the fund collection wallet
  function forwardFunds() internal {
    require(wallet.call.gas(2000).value(msg.value)());
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // internal token purchase function
  function _buyTokens(address beneficiary, uint256 rate) internal returns (uint256 tokens) {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    ControllerInterface(controller).mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

}

/**
 * @title Crowdsale
 * @dev Crowdsale is a  contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is CrowdsaleBase {

  uint256 public rate;

  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _controller) public
    CrowdsaleBase(_startTime, _wallet, _controller)
  {
    require(_endTime >= _startTime);
    require(_rate > 0);

    endTime = _endTime;
    rate = _rate;
  }

}

/**
 * @title TokenCappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of tokens to be bought
 */
contract TokenCappedCrowdsale is Crowdsale {

  uint256 public tokenCap;
  uint256 public totalSupply;

  function TokenCappedCrowdsale(uint256 _tokenCap) public {
      require(_tokenCap > 0);
      tokenCap = _tokenCap;
  }

  function setSupply(uint256 newSupply) internal constant returns (bool) {
    totalSupply = newSupply;
    return tokenCap >= totalSupply;
  }

}

contract SGPayPresale is TokenCappedCrowdsale {


  function SGPayPresale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address controller, uint256 _cap)
    Crowdsale(_startTime, _endTime, _rate, _wallet, controller)
    TokenCappedCrowdsale(_cap)
  {

  }

  function buyTokens(address beneficiary) public payable {
    uint256 tokens = _buyTokens(beneficiary, rate);
    if(!setSupply(totalSupply.add(tokens))) revert();
  }

  function changeRate(uint256 _newValue) public onlyController {
    rate = _newValue;
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }
}