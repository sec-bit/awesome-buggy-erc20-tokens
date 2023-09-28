pragma solidity ^0.4.18;

// File: contracts/InsightsNetwork1.sol

contract InsightsNetwork1 {
  address public owner; // Creator
  address public successor; // May deactivate contract
  mapping (address => uint) public balances;    // Who has what
  mapping (address => uint) public unlockTimes; // When balances unlock
  bool public active;
  uint256 _totalSupply; // Sum of minted tokens

  string public constant name = "INS";
  string public constant symbol = "INS";
  uint8 public constant decimals = 0;

  function InsightsNetwork1() {
    owner = msg.sender;
    active = true;
  }

  function register(address newTokenHolder, uint issueAmount) { // Mint tokens and assign to new owner
    require(active);
    require(msg.sender == owner);   // Only creator can register
    require(balances[newTokenHolder] == 0); // Accounts can only be registered once

    _totalSupply += issueAmount;
    Mint(newTokenHolder, issueAmount);  // Trigger event

    require(balances[newTokenHolder] < (balances[newTokenHolder] + issueAmount));   // Overflow check
    balances[newTokenHolder] += issueAmount;
    Transfer(address(0), newTokenHolder, issueAmount);  // Trigger event

    uint currentTime = block.timestamp; // seconds since the Unix epoch
    uint unlockTime = currentTime + 365*24*60*60; // one year out from the current time
    assert(unlockTime > currentTime); // check for overflow
    unlockTimes[newTokenHolder] = unlockTime;
  }

  function totalSupply() constant returns (uint256) {   // ERC20 compliance
    return _totalSupply;
  }

  function transfer(address _to, uint256 _value) returns (bool success) {   // ERC20 compliance
    return false;
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {    // ERC20 compliance
    return false;
  }

  function approve(address _spender, uint256 _value) returns (bool success) {   // ERC20 compliance
    return false;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {   // ERC20 compliance
    return 0;   // No transfer allowance
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {   // ERC20 compliance
    return balances[_owner];
  }

  function getUnlockTime(address _accountHolder) constant returns (uint256) {
    return unlockTimes[_accountHolder];
  }

  event Mint(address indexed _to, uint256 _amount);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function makeSuccessor(address successorAddr) {
    require(active);
    require(msg.sender == owner);
    //require(successorAddr == address(0));
    successor = successorAddr;
  }

  function deactivate() {
    require(active);
    require(msg.sender == owner || (successor != address(0) && msg.sender == successor));   // Called by creator or successor
    active = false;
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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
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
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/CappedToken.sol

/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
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

// File: zeppelin-solidity/contracts/token/ERC20/PausableToken.sol

/**
 * @title Pausable token
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

// File: contracts/InsightsNetwork2Base.sol

contract InsightsNetwork2Base is DetailedERC20("Insights Network", "INSTAR", 18), PausableToken, CappedToken{

    uint256 constant ATTOTOKEN_FACTOR = 10**18;

    address public predecessor;
    address public successor;

    uint constant MAX_LENGTH = 1024;
    uint constant MAX_PURCHASES = 64;

    mapping (address => uint256[]) public lockedBalances;
    mapping (address => uint256[]) public unlockTimes;
    mapping (address => bool) public imported;

    event Import(address indexed account, uint256 amount, uint256 unlockTime);

    function InsightsNetwork2Base() public CappedToken(300*1000000*ATTOTOKEN_FACTOR) {
        paused = true;
        mintingFinished = true;
    }

    function activate(address _predecessor) public onlyOwner {
        require(predecessor == 0);
        require(_predecessor != 0);
        require(predecessorDeactivated(_predecessor));
        predecessor = _predecessor;
        unpause();
        mintingFinished = false;
    }

    function lockedBalanceOf(address account) public view returns (uint256 balance) {
        uint256 amount;
        for (uint256 index = 0; index < lockedBalances[account].length; index++)
            if (unlockTimes[account][index] > now)
                amount += lockedBalances[account][index];
        return amount;
    }

    function mintBatch(address[] accounts, uint256[] amounts) public onlyOwner canMint returns (bool) {
        require(accounts.length == amounts.length);
        require(accounts.length <= MAX_LENGTH);
        for (uint index = 0; index < accounts.length; index++)
            require(mint(accounts[index], amounts[index]));
        return true;
    }

    function mintUnlockTime(address account, uint256 amount, uint256 unlockTime) public onlyOwner canMint returns (bool) {
        require(unlockTime > now);
        require(lockedBalances[account].length < MAX_PURCHASES);
        lockedBalances[account].push(amount);
        unlockTimes[account].push(unlockTime);
        return super.mint(account, amount);
    }

    function mintUnlockTimeBatch(address[] accounts, uint256[] amounts, uint256 unlockTime) public onlyOwner canMint returns (bool) {
        require(accounts.length == amounts.length);
        require(accounts.length <= MAX_LENGTH);
        for (uint index = 0; index < accounts.length; index++)
            require(mintUnlockTime(accounts[index], amounts[index], unlockTime));
        return true;
    }

    function mintLockPeriod(address account, uint256 amount, uint256 lockPeriod) public onlyOwner canMint returns (bool) {
        return mintUnlockTime(account, amount, now + lockPeriod);
    }

    function mintLockPeriodBatch(address[] accounts, uint256[] amounts, uint256 lockPeriod) public onlyOwner canMint returns (bool) {
        return mintUnlockTimeBatch(accounts, amounts, now + lockPeriod);
    }

    function importBalance(address account) public onlyOwner canMint returns (bool);

    function importBalanceBatch(address[] accounts) public onlyOwner canMint returns (bool) {
        require(accounts.length <= MAX_LENGTH);
        for (uint index = 0; index < accounts.length; index++)
            require(importBalance(accounts[index]));
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender] - lockedBalanceOf(msg.sender));
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from] - lockedBalanceOf(from));
        return super.transferFrom(from, to, value);
    }

    function selfDestruct(address _successor) public onlyOwner whenPaused {
        require(mintingFinished);
        successor = _successor;
        selfdestruct(owner);
    }

    function predecessorDeactivated(address _predecessor) internal view onlyOwner returns (bool);

}

// File: contracts/InsightsNetwork3.sol

contract InsightsNetwork3 is InsightsNetwork2Base {

    function importBalance(address account) public onlyOwner canMint returns (bool) {
        require(!imported[account]);
        InsightsNetwork2Base source = InsightsNetwork2Base(predecessor);
        uint256 amount = source.balanceOf(account);
        require(amount > 0);
        imported[account] = true;
        uint256 mintAmount = amount - source.lockedBalanceOf(account);
        Import(account, mintAmount, now);
        assert(mint(account, mintAmount));
        amount -= mintAmount;
        for (uint index = 0; amount > 0; index++) {
            uint256 unlockTime = source.unlockTimes(account, index);
            if ( unlockTime > now ) {
                mintAmount = source.lockedBalances(account, index);
                Import(account, mintAmount, unlockTime);
                assert(mintUnlockTime(account, mintAmount, unlockTime));
                amount -= mintAmount;
            }
        }
        return true;
    }

    function predecessorDeactivated(address _predecessor) internal view onlyOwner returns (bool) {
        return InsightsNetwork2Base(_predecessor).paused() && InsightsNetwork2Base(_predecessor).mintingFinished();
    }

}