pragma solidity ^0.4.18;

// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function owned() public {
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }
}


// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

}

contract tokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ERC20Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant public returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract limitedFactor {
    uint256 public startTime;
    uint256 public stopTime;
    address public walletAddress;
    address public teamAddress;
    address public contributorsAddress;
    bool public tokenFrozen = true;
    modifier teamAccountNeedFreezeOneYear(address _address) {
        if(_address == teamAddress) {
            require(now > startTime + 1 years);
        }
        _;
    }
    
    modifier TokenUnFreeze() {
        require(!tokenFrozen);
        _;
    } 
}
contract standardToken is ERC20Token, limitedFactor {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    /* Transfers tokens from your address to other */
    function transfer(address _to, uint256 _value) public TokenUnFreeze teamAccountNeedFreezeOneYear(msg.sender) returns (bool success) {
        require (balances[msg.sender] > _value);           // Throw if sender has insufficient balance
        require (balances[_to] + _value > balances[_to]);  // Throw if owerflow detected
        balances[msg.sender] -= _value;                     // Deduct senders balance
        balances[_to] += _value;                            // Add recivers blaance
        Transfer(msg.sender, _to, _value);                  // Raise Transfer event
        return true;
    }

    /* Approve other address to spend tokens on your account */
    function approve(address _spender, uint256 _value) public TokenUnFreeze returns (bool success) {
        allowances[msg.sender][_spender] = _value;          // Set allowance
        Approval(msg.sender, _spender, _value);             // Raise Approval event
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public TokenUnFreeze returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);              // Cast spender to tokenRecipient contract
        approve(_spender, _value);                                      // Set approval to contract for _value
        spender.receiveApproval(msg.sender, _value, this, _extraData);  // Raise method on _spender contract
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public TokenUnFreeze returns (bool success) {
        require (balances[_from] > _value);                // Throw if sender does not have enough balance
        require (balances[_to] + _value > balances[_to]);  // Throw if overflow detected
        require (_value > allowances[_from][msg.sender]);  // Throw if you do not have allowance
        balances[_from] -= _value;                          // Deduct senders balance
        balances[_to] += _value;                            // Add recipient blaance
        allowances[_from][msg.sender] -= _value;            // Deduct allowance for this address
        Transfer(_from, _to, _value);                       // Raise Transfer event
        return true;
    }

    /* Get the amount of allowed tokens to spend */
    function allowance(address _owner, address _spender) constant public TokenUnFreeze returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

}

contract FansChainToken is standardToken,Owned {
    using SafeMath for uint;

    string constant public name="FansChain";
    string constant public symbol="FSC";
    uint256 constant public decimals=18;
    
    uint256 public totalSupply = 0;
    uint256 constant public topTotalSupply = 24*10**7*10**decimals;
    uint256 public teamSupply = percent(25);
    uint256 public privateFundSupply = percent(25);
    uint256 public privateFundingSupply = 0;
    uint256 public ICOtotalSupply = percent(20);
    uint256 public ICOSupply = 0;
    uint256 public ContributorsSupply = percent(30);
    uint256 public exchangeRate;
    
    
    
    /// @dev Fallback to calling deposit when ether is sent directly to contract.
    function() public payable {
        depositToken(msg.value);
    }
    
    
    function FansChainToken() public {
        owner=msg.sender;
    }
    
    /// @dev Buys tokens with Ether.
    function depositToken(uint256 _value) internal {
        uint256 tokenAlloc = buyPriceAt(getTime()) * _value;
        ICOSupply = ICOSupply.add(tokenAlloc);
        require (ICOSupply < ICOtotalSupply);
        mintTokens (msg.sender, tokenAlloc);
        forwardFunds();
    }
    
    function forwardFunds() internal {
        require(walletAddress != address(0));
        walletAddress.transfer(msg.value);
    }
    
    /// @dev Issue new tokens
    function mintTokens(address _to, uint256 _amount) internal {
        require (balances[_to] + _amount > balances[_to]);      // Check for overflows
        balances[_to] = balances[_to].add(_amount);             // Set minted coins to target
        totalSupply = totalSupply.add(_amount);
        Transfer(0x0, _to, _amount);                            // Create Transfer event from 0x
    }
    
    /// @dev Calculate exchange
    function buyPriceAt(uint256 _time) internal constant returns(uint256) {
        if (_time >= startTime && _time <= stopTime) {
            return exchangeRate;
        } else {
            return 0;
        }
    }
    
    /// @dev Get time
    function getTime() internal constant returns(uint256) {
        return now;
    }
    
    /// @dev set initial message
    function setInitialVaribles(
        uint256 _icoStartTime, 
        uint256 _icoStopTime,
        uint256 _exchangeRate,
        address _walletAddress,
        address _teamAddress,
        address _contributorsAddress
        )
        public
        onlyOwner {
            startTime = _icoStartTime;
            stopTime = _icoStopTime;
            exchangeRate=_exchangeRate;
            walletAddress = _walletAddress;
            teamAddress = _teamAddress;
            contributorsAddress = _contributorsAddress;
        }
    
    /// @dev withDraw Ether to a Safe Wallet
    function withDraw() public payable onlyOwner {
        require (msg.sender != address(0));
        require (getTime() > stopTime);
        walletAddress.transfer(this.balance);
    }
    
    /// @dev unfreeze if ICO succeed
    function unfreezeTokenTransfer(bool _freeze) public onlyOwner {
        tokenFrozen = !_freeze;
    }
    
    /// @dev allocate Token
    function allocateTokens(address[] _owners, uint256[] _values) public onlyOwner {
        require (_owners.length == _values.length);
        for(uint256 i = 0; i < _owners.length ; i++){
            address owner = _owners[i];
            uint256 value = _values[i];
            ICOSupply = ICOSupply.add(value);
            require(totalSupply < ICOtotalSupply);
            mintTokens(owner, value);
        }
    }
    
    /// @dev calcute the tokens
    function percent(uint256 percentage) internal  pure returns (uint256) {
        return percentage.mul(topTotalSupply).div(100);
    }
     
     /// @dev allocate token for Team Address
    function allocateTeamToken() public onlyOwner {
        mintTokens(teamAddress, teamSupply);
    }
    
    /// @dev allocate token for Private Address
    function allocatePrivateToken(address[] _privateFundingAddress, uint256[] _amount) public onlyOwner {
        require (_privateFundingAddress.length == _amount.length);
        for(uint256 i = 0; i < _privateFundingAddress.length ; i++){
            address owner = _privateFundingAddress[i];
            uint256 value = _amount[i];
            privateFundingSupply = privateFundingSupply.add(value);
            require(privateFundingSupply <= privateFundSupply);
            mintTokens(owner, value);
        }
    }
    
    /// @dev allocate token for contributors Address
    function allocateContributorsToken() public onlyOwner {
        mintTokens(contributorsAddress, ContributorsSupply);
    }
}