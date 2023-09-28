pragma solidity ^0.4.17;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

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

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

contract EcoVault is Ownable, Pausable, HasNoEther, CanReclaimToken
{

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public constant MAX_CONTRIBUTION = 100000 * 10**18; // Max amount of WILD per address
    uint256 public constant MAX_TOTAL_CONTRIBUTIONS = 5000000 * 10**18; // Max amount for all WILD contributed
    uint256 public constant CONTRIBUTION_START = 1508544000; // 21 Oct, 2018 00:00:00 UTC
    uint256 public constant CONTRIBUTION_END = 1509494400; // 1 Nov, 2018 00:00:00 UTC
    uint256 public constant TIME_LOCK_END = 1525132800; // 1 May, 2018 00:00:00 UTC

    mapping (address => uint256) public contributions;
    uint256 public totalContributions = 0;

    ERC20 public token;

    event Contribution(address indexed _addr, uint256 _amount);
    event Withdrawal(address indexed _addr, uint256 _amount);

    modifier whenAbleToContribute(uint256 _amount)
    {
        require(
            now > CONTRIBUTION_START &&
            now < CONTRIBUTION_END &&
            _amount > 0 &&
            contributions[msg.sender].add(_amount) <= MAX_CONTRIBUTION &&
            totalContributions.add(_amount) <= MAX_TOTAL_CONTRIBUTIONS &&
            token.allowance(msg.sender, this) >= _amount
        );
        _;
    }

    modifier whenAbleToWithdraw()
    {
        require(
            now >= TIME_LOCK_END &&
            contributions[msg.sender] > 0
        );
        _;
    }

    function EcoVault(address _tokenAddress) public
    {
        token = ERC20(_tokenAddress);
    }

    function contribute(uint256 _amount) whenAbleToContribute(_amount) whenNotPaused public
    {
        contributions[msg.sender] = contributions[msg.sender].add(_amount);
        totalContributions = totalContributions.add(_amount);
        token.safeTransferFrom(msg.sender, this, _amount);
        Contribution(msg.sender, _amount);
    }

    function contributionsOf(address _addr) public constant returns (uint256)
    {
        return contributions[_addr];
    }

    function withdraw() whenAbleToWithdraw whenNotPaused public
    {
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        totalContributions = totalContributions.sub(amount);
        token.safeTransfer(msg.sender, amount);
        Withdrawal(msg.sender, amount);
    }
}