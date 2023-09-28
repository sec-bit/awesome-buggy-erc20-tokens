pragma solidity ^0.4.13;

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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract ReturnVestingRegistry is Ownable {

  mapping (address => address) public returnAddress;

  function record(address from, address to) onlyOwner public {
    require(from != 0);

    returnAddress[from] = to;
  }
}

contract TerraformReserve is Ownable {

  /* Storing a balance for each user */
  mapping (address => uint256) public lockedBalance;

  /* Store the total sum locked */
  uint public totalLocked;

  /* Reference to the token */
  ERC20 public manaToken;

  /* Contract that will assign the LAND and burn/return tokens */
  address public landClaim;

  /* Prevent the token from accepting deposits */
  bool public acceptingDeposits;

  event LockedBalance(address user, uint mana);
  event LandClaimContractSet(address target);
  event LandClaimExecuted(address user, uint value, bytes data);
  event AcceptingDepositsChanged(bool _acceptingDeposits);

  function TerraformReserve(address _token) {
    require(_token != 0);
    manaToken = ERC20(_token);
    acceptingDeposits = true;
  }

  /**
   * Lock MANA into the contract.
   * This contract does not have another way to take the tokens out other than
   * through the target contract.
   */
  function lockMana(address _from, uint256 mana) public {
    require(acceptingDeposits);
    require(mana >= 1000 * 1e18);
    require(manaToken.transferFrom(_from, this, mana));

    lockedBalance[_from] += mana;
    totalLocked += mana;
    LockedBalance(_from, mana);
  }

  /**
   * Allows the owner of the contract to pause acceptingDeposits
   */
  function changeContractState(bool _acceptingDeposits) public onlyOwner {
    acceptingDeposits = _acceptingDeposits;
    AcceptingDepositsChanged(acceptingDeposits);
  }

  /**
   * Set the contract that can move the staked MANA.
   * Calls the `approve` function of the ERC20 token with the total amount.
   */
  function setTargetContract(address target) public onlyOwner {
    landClaim = target;
    manaToken.approve(landClaim, totalLocked);
    LandClaimContractSet(target);
  }

  /**
   * Prevent payments to the contract
   */
  function () public payable {
    revert();
  }
}

contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;
  bool public revoked;

  uint256 public released;

  ERC20 public token;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   * @param _token address of the ERC20 token contract
   */
  function TokenVesting(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool    _revocable,
    address _token
  ) {
    require(_beneficiary != 0x0);
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    start       = _start;
    cliff       = _start.add(_cliff);
    duration    = _duration;
    revocable   = _revocable;
    token       = ERC20(_token);
  }

  /**
   * @notice Only allow calls from the beneficiary of the vesting contract
   */
  modifier onlyBeneficiary() {
    require(msg.sender == beneficiary);
    _;
  }

  /**
   * @notice Allow the beneficiary to change its address
   * @param target the address to transfer the right to
   */
  function changeBeneficiary(address target) onlyBeneficiary public {
    require(target != 0);
    beneficiary = target;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function release() onlyBeneficiary public {
    require(now >= cliff);
    _releaseTo(beneficiary);
  }

  /**
   * @notice Transfers vested tokens to a target address.
   * @param target the address to send the tokens to
   */
  function releaseTo(address target) onlyBeneficiary public {
    require(now >= cliff);
    _releaseTo(target);
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function _releaseTo(address target) internal {
    uint256 unreleased = releasableAmount();

    released = released.add(unreleased);

    token.safeTransfer(target, unreleased);

    Released(released);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested are sent to the beneficiary.
   */
  function revoke() onlyOwner public {
    require(revocable);
    require(!revoked);

    // Release all vested tokens
    _releaseTo(beneficiary);

    // Send the remainder to the owner
    token.safeTransfer(owner, token.balanceOf(this));

    revoked = true;

    Revoked();
  }


  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   */
  function releasableAmount() public constant returns (uint256) {
    return vestedAmount().sub(released);
  }

  /**
   * @dev Calculates the amount that has already vested.
   */
  function vestedAmount() public constant returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }

  /**
   * @notice Allow withdrawing any token other than the relevant one
   */
  function releaseForeignToken(ERC20 _token, uint256 amount) onlyOwner {
    require(_token != token);
    _token.transfer(owner, amount);
  }
}

contract DecentralandVesting is TokenVesting {
  using SafeERC20 for ERC20;

  event LockedMANA(uint256 amount);

  ReturnVestingRegistry public returnVesting;
  TerraformReserve public terraformReserve;

  function DecentralandVesting(
    address               _beneficiary,
    uint256               _start,
    uint256               _cliff,
    uint256               _duration,
    bool                  _revocable,
    ERC20                 _token,
    ReturnVestingRegistry _returnVesting,
    TerraformReserve      _terraformReserve
  )
    TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable, _token)
  {
    returnVesting    = ReturnVestingRegistry(_returnVesting);
    terraformReserve = TerraformReserve(_terraformReserve);
  }

  function lockMana(uint256 amount) onlyBeneficiary public {
    // Require allowance to be enough
    require(token.allowance(beneficiary, terraformReserve) >= amount);

    // Check the balance of the vesting contract
    require(amount <= token.balanceOf(this));

    // Check the registry of the beneficiary is fixed to return to this contract
    require(returnVesting.returnAddress(beneficiary) == address(this));

    // Transfer and lock
    token.safeTransfer(beneficiary, amount);
    terraformReserve.lockMana(beneficiary, amount);

    LockedMANA(amount);
  }
}