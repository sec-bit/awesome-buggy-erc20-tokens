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

contract RewardDistributable {
    event TokensRewarded(address indexed player, address rewardToken, uint rewards, address requester, uint gameId, uint block);
    event ReferralRewarded(address indexed referrer, address indexed player, address rewardToken, uint rewards, uint gameId, uint block);
    event ReferralRegistered(address indexed player, address indexed referrer);

    /// @dev Calculates and transfers the rewards to the player.
    function transferRewards(address player, uint entryAmount, uint gameId) public;

    /// @dev Returns the total number of tokens, across all approvals.
    function getTotalTokens(address tokenAddress) public constant returns(uint);

    /// @dev Returns the total number of supported reward token contracts.
    function getRewardTokenCount() public constant returns(uint);

    /// @dev Gets the total number of approvers.
    function getTotalApprovers() public constant returns(uint);

    /// @dev Gets the reward rate inclusive of referral bonus.
    function getRewardRate(address player, address tokenAddress) public constant returns(uint);

    /// @dev Adds a requester to the whitelist.
    /// @param requester The address of a contract which will request reward transfers
    function addRequester(address requester) public;

    /// @dev Removes a requester from the whitelist.
    /// @param requester The address of a contract which will request reward transfers
    function removeRequester(address requester) public;

    /// @dev Adds a approver address.  Approval happens with the token contract.
    /// @param approver The approver address to add to the pool.
    function addApprover(address approver) public;

    /// @dev Removes an approver address. 
    /// @param approver The approver address to remove from the pool.
    function removeApprover(address approver) public;

    /// @dev Updates the reward rate
    function updateRewardRate(address tokenAddress, uint newRewardRate) public;

    /// @dev Updates the token address of the payment type.
    function addRewardToken(address tokenAddress, uint newRewardRate) public;

    /// @dev Updates the token address of the payment type.
    function removeRewardToken(address tokenAddress) public;

    /// @dev Updates the referral bonus rate
    function updateReferralBonusRate(uint newReferralBonusRate) public;

    /// @dev Registers the player with the given referral code
    /// @param player The address of the player
    /// @param referrer The address of the referrer
    function registerReferral(address player, address referrer) public;

    /// @dev Transfers any tokens to the owner
    function destroyRewards() public;
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

contract RewardDistributor is RewardDistributable, Ownable {
    using SafeMath for uint256;

    struct RewardSource {
        address rewardTokenAddress;
        uint96 rewardRate; // 1 token for every reward rate (in wei)
    }

    RewardSource[] public rewardSources;
    mapping(address => bool) public approvedRewardSources;
    
    mapping(address => bool) public requesters; // distribution requesters
    address[] public approvers; // distribution approvers

    mapping(address => address) public referrers; // player -> referrer
    
    uint public referralBonusRate;

    modifier onlyRequesters() {
        require(requesters[msg.sender] || (msg.sender == owner));
        _;
    }

    modifier validRewardSource(address tokenAddress) {
        require(approvedRewardSources[tokenAddress]);
        _;        
    }

    function RewardDistributor(uint256 rewardRate, address tokenAddress) public {
        referralBonusRate = 10;
        addRewardToken(tokenAddress, rewardRate);
    }

    /// @dev Calculates and transfers the rewards to the player.
    function transferRewards(address player, uint entryAmount, uint gameId) public onlyRequesters {
        // loop through all reward tokens, since we never really expect more than 2, this should be ok wrt gas
        for (uint i = 0; i < rewardSources.length; i++) {
            transferRewardsInternal(player, entryAmount, gameId, rewardSources[i]);
        }
    }

    /// @dev Returns the total number of tokens, across all approvals.
    function getTotalTokens(address tokenAddress) public constant validRewardSource(tokenAddress) returns(uint) {
        for (uint j = 0; j < rewardSources.length; j++) {
            if (rewardSources[j].rewardTokenAddress == tokenAddress) {
                FullERC20 rewardToken = FullERC20(rewardSources[j].rewardTokenAddress);
                uint total = rewardToken.balanceOf(this);
            
                for (uint i = 0; i < approvers.length; i++) {
                    address approver = approvers[i];
                    uint allowance = rewardToken.allowance(approver, this);
                    total = total.add(allowance);
                }

                return total;
            }
        }

        return 0;
    }

    /// @dev Get reward token count
    function getRewardTokenCount() public constant returns(uint) {
        return rewardSources.length;
    }


    /// @dev Gets the total number of approvers.
    function getTotalApprovers() public constant returns(uint) {
        return approvers.length;
    }

    /// @dev Gets the reward rate inclusive of bonus.
    /// This is meant to be used by dividing the total purchase amount in wei by this amount.
    function getRewardRate(address player, address tokenAddress) public constant validRewardSource(tokenAddress) returns(uint) {
        for (uint j = 0; j < rewardSources.length; j++) {
            if (rewardSources[j].rewardTokenAddress == tokenAddress) {
                RewardSource storage rewardSource = rewardSources[j];
                uint256 rewardRate = rewardSource.rewardRate;
                uint bonusRate = referrers[player] == address(0) ? 0 : referralBonusRate;
                return rewardRate.mul(100).div(100 + bonusRate);
            }
        }

        return 0;
    }

    /// @dev Adds a requester to the whitelist.
    /// @param requester The address of a contract which will request reward transfers
    function addRequester(address requester) public onlyOwner {
        require(!requesters[requester]);    
        requesters[requester] = true;
    }

    /// @dev Removes a requester from the whitelist.
    /// @param requester The address of a contract which will request reward transfers
    function removeRequester(address requester) public onlyOwner {
        require(requesters[requester]);
        requesters[requester] = false;
    }

    /// @dev Adds a approver address.  Approval happens with the token contract.
    /// @param approver The approver address to add to the pool.
    function addApprover(address approver) public onlyOwner {
        approvers.push(approver);
    }

    /// @dev Removes an approver address. 
    /// @param approver The approver address to remove from the pool.
    function removeApprover(address approver) public onlyOwner {
        uint good = 0;
        for (uint i = 0; i < approvers.length; i = i.add(1)) {
            bool isValid = approvers[i] != approver;
            if (isValid) {
                if (good != i) {
                    approvers[good] = approvers[i];            
                }
              
                good = good.add(1);
            } 
        }

        // TODO Delete the previous entries.
        approvers.length = good;
    }

    /// @dev Updates the reward rate
    function updateRewardRate(address tokenAddress, uint newRewardRate) public onlyOwner {
        require(newRewardRate > 0);
        require(tokenAddress != address(0));

        for (uint i = 0; i < rewardSources.length; i++) {
            if (rewardSources[i].rewardTokenAddress == tokenAddress) {
                rewardSources[i].rewardRate = uint96(newRewardRate);
                return;
            }
        }
    }

    /// @dev Adds the token address of the payment type.
    function addRewardToken(address tokenAddress, uint newRewardRate) public onlyOwner {
        require(tokenAddress != address(0));
        require(!approvedRewardSources[tokenAddress]);
        
        rewardSources.push(RewardSource(tokenAddress, uint96(newRewardRate)));
        approvedRewardSources[tokenAddress] = true;
    }

    /// @dev Removes the given token address from the approved sources.
    /// @param tokenAddress the address of the token
    function removeRewardToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0));
        require(approvedRewardSources[tokenAddress]);

        approvedRewardSources[tokenAddress] = false;

        // Shifting costs significant gas with every write.
        // UI should update the reward sources after this function call.
        for (uint i = 0; i < rewardSources.length; i++) {
            if (rewardSources[i].rewardTokenAddress == tokenAddress) {
                rewardSources[i] = rewardSources[rewardSources.length - 1];
                delete rewardSources[rewardSources.length - 1];
                rewardSources.length--;
                return;
            }
        }
    }

    /// @dev Transfers any tokens to the owner
    function destroyRewards() public onlyOwner {
        for (uint i = 0; i < rewardSources.length; i++) {
            FullERC20 rewardToken = FullERC20(rewardSources[i].rewardTokenAddress);
            uint tokenBalance = rewardToken.balanceOf(this);
            assert(rewardToken.transfer(owner, tokenBalance));
            approvedRewardSources[rewardSources[i].rewardTokenAddress] = false;
        }

        rewardSources.length = 0;
    }

    /// @dev Updates the referral bonus percentage
    function updateReferralBonusRate(uint newReferralBonusRate) public onlyOwner {
        require(newReferralBonusRate < 100);
        referralBonusRate = newReferralBonusRate;
    }

    /// @dev Registers the player with the given referral code
    /// @param player The address of the player
    /// @param referrer The address of the referrer
    function registerReferral(address player, address referrer) public onlyRequesters {
        if (referrer != address(0) && player != referrer) {
            referrers[player] = referrer;
            ReferralRegistered(player, referrer);
        }
    }

    /// @dev Transfers the rewards to the player for the provided reward source
    function transferRewardsInternal(address player, uint entryAmount, uint gameId, RewardSource storage rewardSource) internal {
        if (rewardSource.rewardTokenAddress == address(0)) {
            return;
        }
        
        FullERC20 rewardToken = FullERC20(rewardSource.rewardTokenAddress);
        uint rewards = entryAmount.div(rewardSource.rewardRate).mul(10**uint256(rewardToken.decimals()));
        if (rewards == 0) {
            return;
        }

        address referrer = referrers[player];
        uint referralBonus = referrer == address(0) ? 0 : rewards.mul(referralBonusRate).div(100);
        uint totalRewards = referralBonus.mul(2).add(rewards);
        uint playerRewards = rewards.add(referralBonus);

        // First check if the contract itself has enough tokens to reward.
        if (rewardToken.balanceOf(this) >= totalRewards) {
            assert(rewardToken.transfer(player, playerRewards));
            TokensRewarded(player, rewardToken, playerRewards, msg.sender, gameId, block.number);

            if (referralBonus > 0) {
                assert(rewardToken.transfer(referrer, referralBonus));
                ReferralRewarded(referrer, rewardToken, player, referralBonus, gameId, block.number);
            }
            
            return;
        }

        // Iterate through the approvers to find first with enough rewards and successful transfer
        for (uint i = 0; i < approvers.length; i++) {
            address approver = approvers[i];
            uint allowance = rewardToken.allowance(approver, this);
            if (allowance >= totalRewards) {
                assert(rewardToken.transferFrom(approver, player, playerRewards));
                TokensRewarded(player, rewardToken, playerRewards, msg.sender, gameId, block.number);
                if (referralBonus > 0) {
                    assert(rewardToken.transfer(referrer, referralBonus));
                    ReferralRewarded(referrer, rewardToken, player, referralBonus, gameId, block.number);
                }
                return;
            }
        }
    }
}