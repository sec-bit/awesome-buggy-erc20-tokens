pragma solidity ^0.4.13;

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

contract BbillerBallot is Ownable {
    BbillerToken public token;
    mapping(uint => Issue) public issues;

    uint issueDoesNotExistFlag = 0;
    uint issueVotingFlag = 1;
    uint issueAcceptedFlag = 2;
    uint issueRejectedFlag = 3;

    struct Issue {
        uint votingStartDate;
        uint votingEndDate;
        mapping(address => bool) isVoted;
        uint forCounter;
        uint againstCounter;
        uint flag;
    }

    event CreateIssue(uint _issueId, uint _votingStartDate, uint _votingEndDate, address indexed creator);
    event Vote(uint issueId, bool forVote, address indexed voter);
    event IssueAccepted(uint issueId);
    event IssueRejected(uint issueId);

    function BbillerBallot(BbillerToken _token) public {
        token = _token;
    }

    function createIssue(uint issueId, uint _votingStartDate, uint _votingEndDate) public onlyOwner {
        require(issues[issueId].flag == issueDoesNotExistFlag);

        Issue memory issue = Issue(
            {votingEndDate : _votingEndDate,
            votingStartDate : _votingStartDate,
            forCounter : 0,
            againstCounter : 0,
            flag : issueVotingFlag});
        issues[issueId] = issue;

        CreateIssue(issueId, _votingStartDate, _votingEndDate, msg.sender);
    }

    function vote(uint issueId, bool forVote) public {
        require(token.isTokenUser(msg.sender));

        Issue storage issue = issues[issueId];
        require(!issue.isVoted[msg.sender]);
        require(issue.flag == issueVotingFlag);
        require(issue.votingEndDate > now);
        require(issue.votingStartDate < now);

        issue.isVoted[msg.sender] = true;
        if (forVote) {
            issue.forCounter++;
        }
        else {
            issue.againstCounter++;
        }
        Vote(issueId, forVote, msg.sender);

        uint tokenUserCounterHalf = getTokenUserCounterHalf();
        if (issue.forCounter >= tokenUserCounterHalf) {
            issue.flag = issueAcceptedFlag;
            IssueAccepted(issueId);
        }
        if (issue.againstCounter >= tokenUserCounterHalf) {
            issue.flag = issueRejectedFlag;
            IssueRejected(issueId);
        }
    }

    function getVoteResult(uint issueId) public view returns (string) {
        Issue storage issue = issues[issueId];
        if (issue.flag == issueVotingFlag) {
            return 'Voting';
        }
        if (issue.flag == issueAcceptedFlag) {
            return 'Accepted';
        }
        if (issue.flag == issueRejectedFlag) {
            return 'Rejected';
        }
        if (issue.flag == issueDoesNotExistFlag) {
            return 'DoesNotExist';
        }
    }

    function getTokenUserCounterHalf() internal returns (uint) {
        // for division must be of uint type
        uint half = 2;
        uint tokenUserCounter = token.getTokenUserCounter();
        uint tokenUserCounterHalf = tokenUserCounter / half;
        if (tokenUserCounterHalf * half != tokenUserCounter) {
            // odd case
            tokenUserCounterHalf++;
        }
        return tokenUserCounterHalf;
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

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

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed _to, uint256 _amount);
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
    totalSupply = totalSupply.add(_amount);
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

contract BbillerToken is MintableToken {
    string public symbol = 'BBILLER';
    uint public decimals = 18;
    uint public tokenUserCounter;  // number of users that owns this token

    mapping(address => bool) public isTokenUser;

    event CountTokenUser(address _tokenUser, uint _tokenUserCounter, bool increment);

    function getTokenUserCounter() public view returns (uint) {
        return tokenUserCounter;
    }

    function countTokenUser(address tokenUser) internal {
        if (!isTokenUser[tokenUser]) {
            isTokenUser[tokenUser] = true;
            tokenUserCounter++;
        }
        CountTokenUser(tokenUser, tokenUserCounter, true);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        bool res = super.transfer(to, value);
        countTokenUser(to);
        return res;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        bool res = super.transferFrom(from, to, value);
        countTokenUser(to);
        if (balanceOf(from) <= 0) {
            isTokenUser[from] = false;
            tokenUserCounter--;
            CountTokenUser(from, tokenUserCounter, false);
        }
        return res;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        bool res = super.mint(_to, _amount);
        countTokenUser(_to);
        return res;
    }
}