pragma solidity ^0.4.0;
/*
This vSlice token contract is based on the ERC20 token contract. Additional
functionality has been integrated:
* the contract Lockable, which is used as a parent of the Token contract
* the function mintTokens(), which makes use of the currentSwapRate() and safeToAdd() helpers
* the function disableTokenSwapLock()
*/

contract Lockable {
    uint public numOfCurrentEpoch;
    uint public creationTime;
    uint public constant UNLOCKED_TIME = 25 days;
    uint public constant LOCKED_TIME = 5 days;
    uint public constant EPOCH_LENGTH = 30 days;
    bool public lock;
    bool public tokenSwapLock;

    event Locked();
    event Unlocked();

    // This modifier should prevent tokens transfers while the tokenswap
    // is still ongoing
    modifier isTokenSwapOn {
        if (tokenSwapLock) throw;
        _;
    }

    // This modifier checks and, if needed, updates the value of current
    // token contract epoch, before executing a token transfer of any
    // kind
    modifier isNewEpoch {
        if (numOfCurrentEpoch * EPOCH_LENGTH + creationTime < now ) {
            numOfCurrentEpoch = (now - creationTime) / EPOCH_LENGTH + 1;
        }
        _;
    }

    // This modifier check whether the contract should be in a locked
    // or unlocked state, then acts and updates accordingly if
    // necessary
    modifier checkLock {
        if ((creationTime + numOfCurrentEpoch * UNLOCKED_TIME) +
        (numOfCurrentEpoch - 1) * LOCKED_TIME < now) {
            // avoids needless lock state change and event spamming
            if (lock) throw;

            lock = true;
            Locked();
            return;
        }
        else {
            // only set to false if in a locked state, to avoid
            // needless state change and event spam
            if (lock) {
                lock = false;
                Unlocked();
            }
        }
        _;
    }

    function Lockable() {
        creationTime = now;
        numOfCurrentEpoch = 1;
        tokenSwapLock = true;
    }
}


contract ERC20 {
    function totalSupply() constant returns (uint);
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);

    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Token is ERC20, Lockable {

  mapping( address => uint ) _balances;
  mapping( address => mapping( address => uint ) ) _approvals;
  uint _supply;
  address public walletAddress;

  event TokenMint(address newTokenHolder, uint amountOfTokens);
  event TokenSwapOver();

  modifier onlyFromWallet {
      if (msg.sender != walletAddress) throw;
      _;
  }

  function Token( uint initial_balance, address wallet) {
    _balances[msg.sender] = initial_balance;
    _supply = initial_balance;
    walletAddress = wallet;
  }

  function totalSupply() constant returns (uint supply) {
    return _supply;
  }

  function balanceOf( address who ) constant returns (uint value) {
    return _balances[who];
  }

  function allowance(address owner, address spender) constant returns (uint _allowance) {
    return _approvals[owner][spender];
  }

  // A helper to notify if overflow occurs
  function safeToAdd(uint a, uint b) internal returns (bool) {
    return (a + b >= a && a + b >= b);
  }

  function transfer( address to, uint value)
    isTokenSwapOn
    isNewEpoch
    checkLock
    returns (bool ok) {

    if( _balances[msg.sender] < value ) {
        throw;
    }
    if( !safeToAdd(_balances[to], value) ) {
        throw;
    }

    _balances[msg.sender] -= value;
    _balances[to] += value;
    Transfer( msg.sender, to, value );
    return true;
  }

  function transferFrom( address from, address to, uint value)
    isTokenSwapOn
    isNewEpoch
    checkLock
    returns (bool ok) {
    // if you don't have enough balance, throw
    if( _balances[from] < value ) {
        throw;
    }
    // if you don't have approval, throw
    if( _approvals[from][msg.sender] < value ) {
        throw;
    }
    if( !safeToAdd(_balances[to], value) ) {
        throw;
    }
    // transfer and return true
    _approvals[from][msg.sender] -= value;
    _balances[from] -= value;
    _balances[to] += value;
    Transfer( from, to, value );
    return true;
  }

  function approve(address spender, uint value)
    isTokenSwapOn
    isNewEpoch
    checkLock
    returns (bool ok) {
    _approvals[msg.sender][spender] = value;
    Approval( msg.sender, spender, value );
    return true;
  }

  // The function currentSwapRate() returns the current exchange rate
  // between vSlice tokens and Ether during the token swap period
  function currentSwapRate() constant returns(uint) {
      if (creationTime + 1 weeks > now) {
          return 130;
      }
      else if (creationTime + 2 weeks > now) {
          return 120;
      }
      else if (creationTime + 4 weeks > now) {
          return 100;
      }
      else {
          return 0;
      }
  }

  // The function mintTokens is only usable by the chosen wallet
  // contract to mint a number of tokens proportional to the
  // amount of ether sent to the wallet contract. The function
  // can only be called during the tokenswap period
  function mintTokens(address newTokenHolder, uint etherAmount)
    external
    onlyFromWallet {

        uint tokensAmount = currentSwapRate() * etherAmount;
        if(!safeToAdd(_balances[newTokenHolder],tokensAmount )) throw;
        if(!safeToAdd(_supply,tokensAmount)) throw;

        _balances[newTokenHolder] += tokensAmount;
        _supply += tokensAmount;

        TokenMint(newTokenHolder, tokensAmount);
  }

  // The function disableTokenSwapLock() is called by the wallet
  // contract once the token swap has reached its end conditions
  function disableTokenSwapLock()
    external
    onlyFromWallet {
        tokenSwapLock = false;
        TokenSwapOver();
  }
}


pragma solidity ^0.4.0;
/*
The ProfitContainer contract receives profits from the vDice games and allows a
a fair distribution between token holders.
*/

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address _newOwner)
      external
      onlyOwner {
      if (_newOwner == address(0x0)) throw;
      owner = _newOwner;
  }

}

contract ProfitContainer is Ownable {
    uint public currentEpoch;
    //This is to mitigate supersend and the possibility of
    //different payouts for same token ownership during payout phase
    uint public initEpochBalance;
    mapping (address => uint) lastPaidOutEpoch;
    Token public tokenCtr;

    event WithdrawalEnabled();
    event ProfitWithdrawn(address tokenHolder, uint amountPaidOut);
    event TokenContractChanged(address newTokenContractAddr);

    // The modifier onlyNotPaidOut prevents token holders who have
    // already withdrawn their share of profits in the epoch, to cash
    // out additional shares.
    modifier onlyNotPaidOut {
        if (lastPaidOutEpoch[msg.sender] == currentEpoch) throw;
        _;
    }

    // The modifier onlyLocked prevents token holders from collecting
    // their profits when the token contract is in an unlocked state
    modifier onlyLocked {
        if (!tokenCtr.lock()) throw;
        _;
    }

    // The modifier resetPaidOut updates the currenct epoch, and
    // enables the smart contract to track when a token holder
    // has already received their fair share of profits or not
    // and sets the balance for the epoch using current balance
    modifier resetPaidOut {
        if(currentEpoch < tokenCtr.numOfCurrentEpoch()) {
            currentEpoch = tokenCtr.numOfCurrentEpoch();
            initEpochBalance = this.balance;
            WithdrawalEnabled();
        }
        _;
    }

    function ProfitContainer(address _token) {
        tokenCtr = Token(_token);
    }

    function ()
        payable {

    }

    // The function withdrawalProfit() enables token holders
    // to collect a fair share of profits from the ProfitContainer,
    // proportional to the amount of tokens they own. Token holders
    // will be able to collect their profits only once
    function withdrawalProfit()
        external
        resetPaidOut
        onlyLocked
        onlyNotPaidOut {
        uint currentEpoch = tokenCtr.numOfCurrentEpoch();
        uint tokenBalance = tokenCtr.balanceOf(msg.sender);
        uint totalSupply = tokenCtr.totalSupply();

        if (tokenBalance == 0) throw;

        lastPaidOutEpoch[msg.sender] = currentEpoch;

        // Overflow risk only exists if balance is greater than
        // 1e+33 ether, assuming max of 96M tokens minted.
        // Functions throws, as such a state should never be reached
        // Unless significantly more tokens are minted
        if (!safeToMultiply(tokenBalance, initEpochBalance)) throw;
        uint senderPortion = (tokenBalance * initEpochBalance);

        uint amountToPayOut = senderPortion / totalSupply;

        if(!msg.sender.send(amountToPayOut)) {
            throw;
        }

        ProfitWithdrawn(msg.sender, amountToPayOut);
    }

    function changeTokenContract(address _newToken)
        external
        onlyOwner {

        if (_newToken == address(0x0)) throw;

        tokenCtr = Token(_newToken);
        TokenContractChanged(_newToken);
    }

    // returns expected payout for tokenholder during lock phase
    function expectedPayout(address _tokenHolder)
        external
        constant returns (uint) {

        if (!tokenCtr.lock())
            return 0;

        return (tokenCtr.balanceOf(_tokenHolder) * initEpochBalance) / tokenCtr.totalSupply();
    }

    function safeToMultiply(uint _a, uint _b)
        private
        constant returns (bool) {

        return (_b == 0 || ((_a * _b) / _b) == _a);
    }
}