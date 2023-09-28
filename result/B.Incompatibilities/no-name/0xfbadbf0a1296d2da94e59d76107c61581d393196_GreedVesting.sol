pragma solidity ^0.4.11;

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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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
 * @title Math
 * @dev Assorted math operations
 */

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

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
 * @title GreedVesting
 * @dev A vesting contract for greed tokens that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner. In this contract, you add vesting to a particular wallet, release and revoke the vesting.
 */
 
contract GreedVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(address beneficiary, uint256 amount);
  event Revoked(address beneficiary);

  uint256 public totalVesting;
  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;
  mapping (address => bool) public revocables;
  mapping (address => uint256) public durations;
  mapping (address => uint256) public starts;
  mapping (address => uint256) public cliffs; 
  mapping (address => uint256) public amounts; 
  mapping (address => uint256) public refunded; 
       
  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param greed address of greed token contract
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _amount amount to be vested
   * @param _revocable whether the vesting is revocable or not
   */
  function addVesting(ERC20Basic greed, address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, uint256 _amount, bool _revocable) public onlyOwner {
    require(_beneficiary != 0x0);
    require(_amount > 0);
    // Make sure that a single address can be granted tokens only once.
    require(starts[_beneficiary] == 0);
    // Check for date inconsistencies that may cause unexpected behavior.
    require(_cliff <= _duration);
    // Check that this grant doesn't exceed the total amount of tokens currently available for vesting.
    require(totalVesting.add(_amount) <= greed.balanceOf(address(this)));

	revocables[_beneficiary] = _revocable;
    durations[_beneficiary] = _duration;
    cliffs[_beneficiary] = _start.add(_cliff);
    starts[_beneficiary] = _start;
    amounts[_beneficiary] = _amount;
    totalVesting = totalVesting.add(_amount);
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param greed address of greed token contract
   */
  function release(address beneficiary, ERC20Basic greed) public {
      
    require(msg.sender == beneficiary || msg.sender == owner);

    uint256 unreleased = releasableAmount(beneficiary);
    
    require(unreleased > 0);

    released[beneficiary] = released[beneficiary].add(unreleased);

    greed.safeTransfer(beneficiary, unreleased);

    Released(beneficiary, unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param greed address of greed token contract
    */
  function revoke(address beneficiary, ERC20Basic greed) public onlyOwner {
    require(revocables[beneficiary]);
    require(!revoked[beneficiary]);

    uint256 balance = amounts[beneficiary].sub(released[beneficiary]);

    uint256 unreleased = releasableAmount(beneficiary);
    uint256 refund = balance.sub(unreleased);

    revoked[beneficiary] = true;
    if (refund != 0) { 
		greed.safeTransfer(owner, refund);
		refunded[beneficiary] = refunded[beneficiary].add(refund);
	}
    Revoked(beneficiary);
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param beneficiary address of the beneficiary to whom vested tokens are transferred
   * 
   */
  function releasableAmount(address beneficiary) public constant returns (uint256) {
    return vestedAmount(beneficiary).sub(released[beneficiary]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param beneficiary address of the beneficiary to whom vested tokens are transferred
   */
  function vestedAmount(address beneficiary) public constant returns (uint256) {
    uint256 totalBalance = amounts[beneficiary].sub(refunded[beneficiary]);

    if (now < cliffs[beneficiary]) {
      return 0;
    } else if (now >= starts[beneficiary] + durations[beneficiary] || revoked[beneficiary]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now - starts[beneficiary]).div(durations[beneficiary]);
    }
  }
}