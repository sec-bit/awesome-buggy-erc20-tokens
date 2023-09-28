pragma solidity ^0.4.13;


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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



/*
 * This contract allows the deposit of funds during the presale of a tokens
 * It can supply a mapping of addresses of participants => amount contributed
 */

contract FornicoinPresale {
  using SafeMath for uint256;

  // Time of start and end to presale
  uint256 public startPresale;
  uint256 public endPresale;

  // Mapping of contributor addresses to the resective amounts contributed as FXX tokens
  mapping (address => uint256) contributors;

  // address where funds are collected
  address public wallet;

  // admin address to halt contract
  address public admin;
  bool public haltSale;

  // amount of wei raised in the presale
  uint256 public weiRaised;

  // FXX rate per ETH: 1300FXX/1ETH during presale
  uint256 public presaleRate = (1300 * (10 ** uint256(18)))/(1 ether);

  // Token pruchase event notification
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

  function FornicoinPresale(address _wallet, uint256 _startTime, address _admin) {
    require(_startTime >= now);
    require(_wallet != 0x0);

    admin = _admin;
    startPresale = _startTime;
    endPresale = startPresale + 7 days;
    wallet = _wallet;
  }

  // Halt the presale in case of emergency
  function setHaltSale( bool halt ) {
        require( msg.sender == admin );
        haltSale = halt;
    }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens();
  }

  // low level token purchase function
  function buyTokens() public payable {
    require(tx.gasprice <= 50000000000 wei);
    require(!haltSale);
    require(!hasEnded());
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(presaleRate);

    // add contributor and value to mapping
    contributors[msg.sender] = contributors[msg.sender].add(tokens);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    // Send out event on network
    TokenPurchase(msg.sender, weiAmount, tokens);

    // forward contribution funds to secure address
    forwardFunds();
  }

  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  // Purchases must be greater than 2 ETH
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startPresale && now <= endPresale;
    bool nonZeroPurchase = msg.value >= 2 ether;
    return withinPeriod && nonZeroPurchase;
  }

// ETH balance is always expected to be 0.
// but in case something went wrong, we use this function to extract the eth.
function emergencyDrain(ERC20 anyToken) returns(bool){
    require(msg.sender == admin);
    require(hasEnded());

    if(this.balance > 0) {
        wallet.transfer(this.balance);
    }

    if(anyToken != address(0x0)) {
        assert(anyToken.transfer(wallet, anyToken.balanceOf(this)));
    }

    return true;
}

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endPresale;
  }
}