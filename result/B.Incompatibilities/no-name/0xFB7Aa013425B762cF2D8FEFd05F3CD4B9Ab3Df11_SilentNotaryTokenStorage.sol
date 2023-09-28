pragma solidity ^0.4.18;

 /// @title Ownable contract - base contract with an owner
contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

 /// @title SafeMath contract - math operations with safety checks
contract SafeMath {
  function safeMul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 /// @title ERC20 interface see https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);  
  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  function decimals() public constant returns (uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract SilentNotaryTokenStorage is SafeMath, Ownable {

  /// Information about frozen portion of tokens
  struct FrozenPortion {
    /// Earliest time when this portion will become available
    uint unfreezeTime;

    /// Frozen balance portion, in percents
    uint portionPercent;

    /// Frozen token amount
    uint portionAmount;

    /// Is this portion unfrozen (withdrawn) after freeze period has finished
    bool isUnfrozen;
  }

  /// Specified amount of tokens was unfrozen
  event Unfrozen(uint tokenAmount);

  /// SilentNotary token contract
  ERC20 public token;

  /// All frozen portions of the contract token balance
  FrozenPortion[] public frozenPortions;

  /// Team wallet to withdraw unfrozen tokens
  address public teamWallet;

  /// Deployment time of this contract, which is also the start point to count freeze periods
  uint public deployedTime;

  /// Is current token amount fixed (must be to unfreeze)
  bool public amountFixed;

  /// @dev Constructor
  /// @param _token SilentNotary token contract address
  /// @param _teamWallet Wallet address to withdraw unfrozen tokens
  /// @param _freezePeriods Ordered array of freeze periods
  /// @param _freezePortions Ordered array of balance portions to freeze, in percents
  function SilentNotaryTokenStorage (address _token, address _teamWallet, uint[] _freezePeriods, uint[] _freezePortions) public {
    require(_token > 0);
    require(_teamWallet > 0);
    require(_freezePeriods.length > 0);
    require(_freezePeriods.length == _freezePortions.length);

    token = ERC20(_token);
    teamWallet = _teamWallet;
    deployedTime = now;

    var cumulativeTime = deployedTime;
    uint cumulativePercent = 0;
    for (uint i = 0; i < _freezePeriods.length; i++) {
      require(_freezePortions[i] > 0 && _freezePortions[i] <= 100);
      cumulativePercent = safeAdd(cumulativePercent, _freezePortions[i]);
      cumulativeTime = safeAdd(cumulativeTime, _freezePeriods[i]);
      frozenPortions.push(FrozenPortion({
        portionPercent: _freezePortions[i],
        unfreezeTime: cumulativeTime,
        portionAmount: 0,
        isUnfrozen: false}));
    }
    assert(cumulativePercent == 100);
  }

  /// @dev Unfreeze currently available amount of tokens
  function unfreeze() public onlyOwner {
    require(amountFixed);

    uint unfrozenTokens = 0;
    for (uint i = 0; i < frozenPortions.length; i++) {
      var portion = frozenPortions[i];
      if (portion.isUnfrozen)
        continue;
      if (portion.unfreezeTime < now) {
        unfrozenTokens = safeAdd(unfrozenTokens, portion.portionAmount);
        portion.isUnfrozen = true;
      }
      else
        break;
    }
    transferTokens(unfrozenTokens);
  }

  /// @dev Fix current token amount (calculate absolute values of every portion)
  function fixAmount() public onlyOwner {
    require(!amountFixed);
    amountFixed = true;

    uint currentBalance = token.balanceOf(this);
    for (uint i = 0; i < frozenPortions.length; i++) {
      var portion = frozenPortions[i];
      portion.portionAmount = safeDiv(safeMul(currentBalance, portion.portionPercent), 100);
    }
  }

  /// @dev Withdraw remaining tokens after all freeze periods are over (in case there were additional token transfers)
  function withdrawRemainder() public onlyOwner {
    for (uint i = 0; i < frozenPortions.length; i++) {
      if (!frozenPortions[i].isUnfrozen)
        revert();
    }
    transferTokens(token.balanceOf(this));
  }

  function transferTokens(uint tokenAmount) private {
    require(tokenAmount > 0);
    var transferSuccess = token.transfer(teamWallet, tokenAmount);
    assert(transferSuccess);
    Unfrozen(tokenAmount);
  }
}