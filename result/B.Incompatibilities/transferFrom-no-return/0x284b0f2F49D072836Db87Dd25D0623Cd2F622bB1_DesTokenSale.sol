pragma solidity ^0.4.13;

/**
 * Math operations with safety checks
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

  function unown() onlyOwner {
    owner = address(0);
  }

}

contract Transferable is Ownable {

  bool public transfersAllowed = false;
  mapping(address => bool) allowedTransfersTo;

  function Transferable() {
    allowedTransfersTo[msg.sender] = true;
  }

  modifier onlyIfTransfersAllowed() {
    require(transfersAllowed == true || allowedTransfersTo[msg.sender] == true);
    _;
  }

  function allowTransfers() onlyOwner {
    transfersAllowed = true;
  }

  function disallowTransfers() onlyOwner {
    transfersAllowed = false;
  }

  function allowTransfersTo(address _owner) onlyOwner {
    allowedTransfersTo[_owner] = true;
  }

  function disallowTransfersTo(address _owner) onlyOwner {
    allowedTransfersTo[_owner] = false;
  }

  function transfersAllowedTo(address _owner) constant returns (bool) {
    return (transfersAllowed == true || allowedTransfersTo[_owner] == true);
  }

}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic, Transferable {
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
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) onlyIfTransfersAllowed {
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
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) onlyIfTransfersAllowed {
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

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator. 
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract DesToken is StandardToken {

  string public name = "DES Token";
  string public symbol = "DES";
  uint256 public decimals = 18;
  uint256 public INITIAL_SUPPLY = 35000000 * 1 ether;

  /**
   * @dev Contructor that gives msg.sender all of existing tokens. 
   */
  function DesToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

}

/*
 * Haltable
 *
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by causing a throw when in halt mode.
 *
 *
 * Originally envisioned in FirstBlood ICO contract.
 */
contract Haltable is Ownable {
  bool public halted = false;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

contract DesTokenSale is Haltable {
    using SafeMath for uint;

    string public name = "3DES Token Sale Contract";

    DesToken public token;
    address public beneficiary;

    uint public tokensSoldTotal = 0; // in wei
    uint public weiRaisedTotal = 0; // in wei
    uint public investorCount = 0;
    uint public tokensSelling = 0; // tokens selling in the current phase
    uint public tokenPrice = 0; // in wei
    uint public purchaseLimit = 0; // in tokens wei amount

    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);

    function DesTokenSale(
      address _token,
      address _beneficiary
      ) {
        token = DesToken(_token);
        beneficiary = _beneficiary;
    }

    function changeBeneficiary(address _beneficiary) onlyOwner stopInEmergency {
        beneficiary = _beneficiary;
    }

    function startPhase(
      uint256 _tokens,
      uint256 _price,
      uint256 _limit
      ) onlyOwner {
        require(tokensSelling == 0);
        require(_tokens <= token.balanceOf(this));
        tokensSelling = _tokens * 1 ether;
        tokenPrice = _price;
        purchaseLimit = _limit * 1 ether;
    }

    // If DES tokens will not be sold in a phase it will be ours.
    // We belive in success of our project.
    function finishPhase() onlyOwner {
        require(tokensSelling != 0);
        token.transfer(beneficiary, tokensSelling);
        tokensSelling = 0;
    }

    function () payable {
        doPurchase(msg.sender);
    }

    function doPurchaseFor(address _sender) payable {
        doPurchase(_sender);
    }

    function doPurchase(address _sender) private stopInEmergency {
        // phase is started
        require(tokensSelling != 0);

        // require min limit of contribution
        require(msg.value >= 0.01 * 1 ether);
        
        // calculate token amount
        uint tokens = msg.value * 1 ether / tokenPrice;
        
        // throw if you trying to buy over the limit
        require(token.balanceOf(_sender).add(tokens) <= purchaseLimit);
        
        // recalculate selling tokens
        // will throw if it is not enough tokens
        tokensSelling = tokensSelling.sub(tokens);
        
        // recalculate counters
        tokensSoldTotal = tokensSoldTotal.add(tokens);
        if (token.balanceOf(_sender) == 0) investorCount++;
        weiRaisedTotal = weiRaisedTotal.add(msg.value);
        
        // transfer bought tokens to the contributor 
        token.transfer(_sender, tokens);

        // transfer funds to the beneficiary
        beneficiary.transfer(msg.value);

        NewContribution(_sender, tokens, msg.value);
    }
    
}