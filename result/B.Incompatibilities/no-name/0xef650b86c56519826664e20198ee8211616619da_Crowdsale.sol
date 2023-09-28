pragma solidity ^0.4.18;

contract FullERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  uint256 public totalSupply;
  uint8 public decimals;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
}

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

contract Crowdsale is Ownable {
    using SafeMath for uint256;


    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;
    FullERC20 public token;

    // token amount per 1 ETH
    // eg. 40000000000 = 2500000 tokens.
    uint256 public rate; 

    // amount of raised money in wei
    uint256 public weiRaised;
    uint256 public tokensPurchased;

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchased(address indexed purchaser, uint256 value, uint256 amount);

    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _token) public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        token = FullERC20(_token);
    }

    // fallback function can be used to buy tokens
    function () public payable {
        purchase();
    }

    function purchase() public payable {
        require(msg.sender != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.div(rate);
        require(tokens > 0);
        require(token.balanceOf(this) > tokens);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        tokensPurchased = tokensPurchased.add(tokens);

        TokenPurchased(msg.sender, weiAmount, tokens);
        assert(token.transfer(msg.sender, tokens));
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    // @dev updates the rate
    function updateRate(uint256 newRate) public onlyOwner {
        rate = newRate;
    }

    function updateTimes(uint256 _startTime, uint256 _endTime) public onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
    }

    // @dev returns the number of tokens available in the sale.
    function tokensAvailable() public view returns (bool) {
        return token.balanceOf(this) > 0;
    }

    // @dev Ends the token sale and transfers balance of tokens
    // and eth to owner. 
    function endSale() public onlyOwner {
        wallet.transfer(this.balance);
        assert(token.transfer(wallet, token.balanceOf(this)));
        endTime = now;
    }
}