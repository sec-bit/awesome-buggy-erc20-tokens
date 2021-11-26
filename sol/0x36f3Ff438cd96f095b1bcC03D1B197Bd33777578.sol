pragma solidity ^0.4.15;

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20.sol

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

// File: contracts/LockableToken.sol

contract LockableToken is ERC20 {
    function addToTimeLockedList(address addr) external returns (bool);
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: contracts/PricingStrategy.sol

contract PricingStrategy {

    using SafeMath for uint;

    uint[] public rates;
    uint[] public limits;

    function PricingStrategy(
        uint[] _rates,
        uint[] _limits
    ) public
    {
        require(_rates.length == _limits.length);
        rates = _rates;
        limits = _limits;
    }

    /** Interface declaration. */
    function isPricingStrategy() public view returns (bool) {
        return true;
    }

    /** Calculate the current price for buy in amount. */
    function calculateTokenAmount(uint weiAmount, uint weiRaised) public view returns (uint tokenAmount) {
        if (weiAmount == 0) {
            return 0;
        }

        var (rate, index) = currentRate(weiRaised);
        tokenAmount = weiAmount.mul(rate);

        // if we crossed slot border, recalculate remaining tokens according to next slot price
        if (weiRaised.add(weiAmount) > limits[index]) {
            uint currentSlotWei = limits[index].sub(weiRaised);
            uint currentSlotTokens = currentSlotWei.mul(rate);
            uint remainingWei = weiAmount.sub(currentSlotWei);
            tokenAmount = currentSlotTokens.add(calculateTokenAmount(remainingWei, limits[index]));
        }
    }

    function currentRate(uint weiRaised) public view returns (uint rate, uint8 index) {
        rate = rates[0];
        index = 0;

        while (weiRaised >= limits[index]) {
            rate = rates[++index];
        }
    }

}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: zeppelin-solidity/contracts/ownership/Contactable.sol

/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable{

    string public contactInformation;

    /**
     * @dev Allows the owner to set a string with their contact information.
     * @param info The contact information to attach to the contract.
     */
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
     }
}

// File: contracts/Sale.sol

/**
 * @title Sale
 * @dev Sale is a contract for managing a token crowdsale.
 * Sales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Sale is Pausable, Contactable {
    using SafeMath for uint;
  
    // The token being sold
    LockableToken public token;
  
    // start and end timestamps where investments are allowed (both inclusive)
    uint public startTime;
    uint public endTime;
  
    // address where funds are collected
    address public wallet;
  
    // the contract, which determine how many token units a buyer gets per wei
    PricingStrategy public pricingStrategy;
  
    // amount of raised money in wei
    uint public weiRaised;

    // amount of tokens that was sold on the crowdsale
    uint public tokensSold;

    // maximum amount of wei in total, that can be invested
    uint public weiMaximumGoal;

    // if weiMinimumGoal will not be reached till endTime, investors will be able to refund ETH
    uint public weiMinimumGoal;

    // minimal amount of ether, that investor can invest
    uint public minAmount;

    // How many distinct addresses have invested
    uint public investorCount;

    // how much wei we have returned back to the contract after a failed crowdfund
    uint public loadedRefund;

    // how much wei we have given back to investors
    uint public weiRefunded;

    //How much ETH each address has invested to this crowdsale
    mapping (address => uint) public investedAmountOf;

    // Addresses that are allowed to invest before ICO offical opens
    mapping (address => bool) public earlyParticipantWhitelist;

    // whether a buyer bought tokens through other currencies
    mapping (address => bool) public isExternalBuyer;

    address public admin;

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == admin); 
        _;
    }
  
    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param tokenAmount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint value,
        uint tokenAmount
    );

    // a refund was processed for an investor
    event Refund(address investor, uint weiAmount);

    function Sale(
        uint _startTime,
        uint _endTime,
        PricingStrategy _pricingStrategy,
        LockableToken _token,
        address _wallet,
        uint _weiMaximumGoal,
        uint _weiMinimumGoal,
        uint _minAmount
    ) {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_pricingStrategy.isPricingStrategy());
        require(address(_token) != 0x0);
        require(_wallet != 0x0);
        require(_weiMaximumGoal > 0);
        require(_weiMinimumGoal > 0);

        startTime = _startTime;
        endTime = _endTime;
        pricingStrategy = _pricingStrategy;
        token = _token;
        wallet = _wallet;
        weiMaximumGoal = _weiMaximumGoal;
        weiMinimumGoal = _weiMinimumGoal;
        minAmount = _minAmount;
}

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public whenNotPaused payable returns (bool) {
        uint weiAmount = msg.value;
        
        require(beneficiary != 0x0);
        require(validPurchase(weiAmount));
    
        transferTokenToBuyer(beneficiary, weiAmount);

        wallet.transfer(weiAmount);

        return true;
    }

    function transferTokenToBuyer(address beneficiary, uint weiAmount) internal {
        if (investedAmountOf[beneficiary] == 0) {
            // A new investor
            investorCount++;
        }

        // calculate token amount to be created
        uint tokenAmount = pricingStrategy.calculateTokenAmount(weiAmount, weiRaised);

        investedAmountOf[beneficiary] = investedAmountOf[beneficiary].add(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);
    
        token.transferFrom(owner, beneficiary, tokenAmount);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
    }

   // return true if the transaction can buy tokens
    function validPurchase(uint weiAmount) internal view returns (bool) {
        bool withinPeriod = (now >= startTime || earlyParticipantWhitelist[msg.sender]) && now <= endTime;
        bool withinCap = weiRaised.add(weiAmount) <= weiMaximumGoal;
        bool moreThenMinimal = weiAmount >= minAmount;

        return withinPeriod && withinCap && moreThenMinimal;
    }

    // return true if crowdsale event has ended
    function hasEnded() external view returns (bool) {
        bool capReached = weiRaised >= weiMaximumGoal;
        bool afterEndTime = now > endTime;
        
        return capReached || afterEndTime;
    }

    // get the amount of unsold tokens allocated to this contract;
    function getWeiLeft() external view returns (uint) {
        return weiMaximumGoal - weiRaised;
    }

    // return true if the crowdsale has raised enough money to be a successful.
    function isMinimumGoalReached() public view returns (bool) {
        return weiRaised >= weiMinimumGoal;
    }
    
    /**
     * allows to add and exclude addresses from earlyParticipantWhitelist for owner
     * @param isWhitelisted is true for adding address into whitelist, false - to exclude
     */
    function editEarlyParicipantWhitelist(address addr, bool isWhitelisted) external onlyOwnerOrAdmin returns (bool) {
        earlyParticipantWhitelist[addr] = isWhitelisted;
        return true;
    }

    // allows to update tokens rate for owner
    function setPricingStrategy(PricingStrategy _pricingStrategy) external onlyOwner returns (bool) {
        pricingStrategy = _pricingStrategy;
        return true;
    }

    /**
    * Allow load refunds back on the contract for the refunding.
    *
    * The team can transfer the funds back on the smart contract in the case the minimum goal was not reached..
    */
    function loadRefund() external payable {
        require(msg.value > 0);
        require(!isMinimumGoalReached());
        
        loadedRefund = loadedRefund.add(msg.value);
    }

    /**
    * Investors can claim refund.
    *
    * Note that any refunds from proxy buyers should be handled separately,
    * and not through this contract.
    */
    function refund() external {
        uint256 weiValue = investedAmountOf[msg.sender];
        
        require(!isMinimumGoalReached() && loadedRefund > 0);
        require(!isExternalBuyer[msg.sender]);
        require(weiValue > 0);
        
        investedAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded.add(weiValue);
        Refund(msg.sender, weiValue);
        msg.sender.transfer(weiValue);
    }

    function registerPayment(address beneficiary, uint weiAmount) external onlyOwnerOrAdmin {
        require(validPurchase(weiAmount));
        isExternalBuyer[beneficiary] = true;
        transferTokenToBuyer(beneficiary, weiAmount);
    }

    function setAdmin(address adminAddress) external onlyOwner {
        admin = adminAddress;
    }
}