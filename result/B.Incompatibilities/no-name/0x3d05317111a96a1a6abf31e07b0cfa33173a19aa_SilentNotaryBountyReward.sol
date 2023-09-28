pragma solidity ^0.4.14;

 /// @title Ownable contract - base contract with an owner
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
}


pragma solidity ^0.4.14;

 /// @title ERC20 interface see https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);
  function mint(address receiver, uint amount);
  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  function decimals() constant returns (uint decimals) { return 0; }
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


pragma solidity ^0.4.18;




 /// @title SilentNotary bounty reward  contract
contract SilentNotaryBountyReward is Ownable {

  ERC20 public token;

  /// Team wallet to withdraw remaining tokens
  address public teamWallet;

  /// Remaining bounty rewards
  mapping (address => uint) public bountyRewards;

  /// Total count of addresses which have collected their rewards
  uint public collectedAddressesCount;

  /// Array of addresses which have collected their rewards
  address[] public collectedAddresses;

  /// Starting time of the bounty collection
  uint public startTime;

  /// Duration of the bounty collection
  uint public constant DURATION = 2 weeks;

  event Claimed(address receiver, uint amount);

  /// @dev Constructor
  /// @param _token Address of Silent Notary Token
  /// @param _teamWallet Team wallet to withdraw remaining tokens
  /// @param _startTime Starting time of the bounty collection
  function SilentNotaryBountyReward(address _token, address _teamWallet, uint _startTime) {
    require(_token != 0);
    require(_teamWallet != 0);
    require(_startTime > 0);

    token = ERC20(_token);
    teamWallet = _teamWallet;
    startTime = _startTime;
  }

  /// @dev Disable ETH accepting
  function() payable  {
    revert();
  }

  /// @dev Claim bounty reward
  function claimReward() public {
    require(now >= startTime && now <= startTime + DURATION);

    var receiver = msg.sender;
    var reward = bountyRewards[receiver];
    assert(reward > 0);
    assert(token.balanceOf(address(this)) >= reward);

    delete bountyRewards[receiver];
    collectedAddressesCount++;
    collectedAddresses.push(receiver);

    token.transfer(receiver, reward);
    Claimed(receiver, reward);
  }

  /// @dev Import bounty reward (for owner)
  /// @param receiver Address of reward receiver
  /// @param tokenAmount Amount of tokens to reward
  function importReward(address receiver, uint tokenAmount) public onlyOwner {
    require(receiver != 0);
    require(tokenAmount > 0);

    bountyRewards[receiver] = tokenAmount;
  }

  /// @dev Clear invalid bounty reward (for owner)
  /// @param receiver Address of reward receiver
  function clearReward(address receiver) public onlyOwner {
    require(receiver != 0);

    delete bountyRewards[receiver];
  }

  /// @dev Withdraw remaining tokens after reward claim period is over (for owner)
  function withdrawRemainder() public onlyOwner {
    require(now > startTime + DURATION);
    var remainingBalance = token.balanceOf(address(this));
    require(remainingBalance > 0);

    token.transfer(teamWallet, remainingBalance);
  }
}