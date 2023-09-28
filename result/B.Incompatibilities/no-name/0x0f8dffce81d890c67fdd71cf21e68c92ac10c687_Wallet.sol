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
The standard Wallet contract, retrievable at
https://github.com/ethereum/dapp-bin/blob/master/wallet/wallet.sol has been
modified to include additional functionality, in particular:
* An additional parent of wallet contract called tokenswap, implementing almost
all the changes:
    - Functions for starting and stopping the tokenswap
    - A set-only-once function for the token contract
    - buyTokens(), which calls mintTokens() in the token contract
    - Modifiers for enforcing tokenswap time limits and max ether cap
* the wallet fallback function calls the buyTokens function
* the wallet contract cannot selfdestruct during the tokenswap
*/

contract multiowned {

	// TYPES

    // struct for the status of a pending operation.
    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
        uint index;
    }

	// EVENTS

    // this contract only has six types of events: it can accept a confirmation, in which case
    // we record owner and operation (hash) alongside it.
    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    // some others are in the case of an owner changing.
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);
    // the last one is emitted if the required signatures change
    event RequirementChanged(uint newRequirement);

	// MODIFIERS

    // simple single-sig function modifier.
    modifier onlyowner {
        if (isOwner(msg.sender))
            _;
    }
    // multi-sig function modifier: the operation must have an intrinsic hash in order
    // that later attempts can be realised as the same underlying operation and
    // thus count as confirmations.
    modifier onlymanyowners(bytes32 _operation) {
        if (confirmAndCheck(_operation))
            _;
    }

	// METHODS

    // constructor is given number of sigs required to do protected "onlymanyowners" transactions
    // as well as the selection of addresses capable of confirming them.
    function multiowned(address[] _owners, uint _required) {
        m_numOwners = _owners.length + 1;
        m_owners[1] = uint(msg.sender);
        m_ownerIndex[uint(msg.sender)] = 1;
        for (uint i = 0; i < _owners.length; ++i)
        {
            m_owners[2 + i] = uint(_owners[i]);
            m_ownerIndex[uint(_owners[i])] = 2 + i;
        }
        m_required = _required;
    }

    // Revokes a prior confirmation of the given operation
    function revoke(bytes32 _operation) external {
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
        // make sure they're an owner
        if (ownerIndex == 0) return;
        uint ownerIndexBit = 2**ownerIndex;
        var pending = m_pending[_operation];
        if (pending.ownersDone & ownerIndexBit > 0) {
            pending.yetNeeded++;
            pending.ownersDone -= ownerIndexBit;
            Revoke(msg.sender, _operation);
        }
    }

    // Replaces an owner `_from` with another `_to`.
    function changeOwner(address _from, address _to) onlymanyowners(sha3(msg.data)) external {
        if (isOwner(_to)) return;
        uint ownerIndex = m_ownerIndex[uint(_from)];
        if (ownerIndex == 0) return;

        clearPending();
        m_owners[ownerIndex] = uint(_to);
        m_ownerIndex[uint(_from)] = 0;
        m_ownerIndex[uint(_to)] = ownerIndex;
        OwnerChanged(_from, _to);
    }

    function addOwner(address _owner) onlymanyowners(sha3(msg.data)) external {
        if (isOwner(_owner)) return;

        clearPending();
        if (m_numOwners >= c_maxOwners)
            reorganizeOwners();
        if (m_numOwners >= c_maxOwners)
            return;
        m_numOwners++;
        m_owners[m_numOwners] = uint(_owner);
        m_ownerIndex[uint(_owner)] = m_numOwners;
        OwnerAdded(_owner);
    }

    function removeOwner(address _owner) onlymanyowners(sha3(msg.data)) external {
        uint ownerIndex = m_ownerIndex[uint(_owner)];
        if (ownerIndex == 0) return;
        if (m_required > m_numOwners - 1) return;

        m_owners[ownerIndex] = 0;
        m_ownerIndex[uint(_owner)] = 0;
        clearPending();
        reorganizeOwners(); //make sure m_numOwner is equal to the number of owners and always points to the optimal free slot
        OwnerRemoved(_owner);
    }

    function changeRequirement(uint _newRequired) onlymanyowners(sha3(msg.data)) external {
        if (_newRequired > m_numOwners) return;
        m_required = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
    }

    // Gets an owner by 0-indexed position (using numOwners as the count)
    function getOwner(uint ownerIndex) external constant returns (address) {
        return address(m_owners[ownerIndex + 1]);
    }

    function isOwner(address _addr) returns (bool) {
        return m_ownerIndex[uint(_addr)] > 0;
    }

    function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
        var pending = m_pending[_operation];
        uint ownerIndex = m_ownerIndex[uint(_owner)];

        // make sure they're an owner
        if (ownerIndex == 0) return false;

        // determine the bit to set for this owner.
        uint ownerIndexBit = 2**ownerIndex;
        return !(pending.ownersDone & ownerIndexBit == 0);
    }

    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation) internal returns (bool) {
        // determine what index the present sender is:
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
        // make sure they're an owner
        if (ownerIndex == 0) return;

        var pending = m_pending[_operation];
        // if we're not yet working on this operation, switch over and reset the confirmation status.
        if (pending.yetNeeded == 0) {
            // reset count of confirmations needed.
            pending.yetNeeded = m_required;
            // reset which owners have confirmed (none) - set our bitmap to 0.
            pending.ownersDone = 0;
            pending.index = m_pendingIndex.length++;
            m_pendingIndex[pending.index] = _operation;
        }
        // determine the bit to set for this owner.
        uint ownerIndexBit = 2**ownerIndex;
        // make sure we (the message sender) haven't confirmed this operation previously.
        if (pending.ownersDone & ownerIndexBit == 0) {
            Confirmation(msg.sender, _operation);
            // ok - check if count is enough to go ahead.
            if (pending.yetNeeded <= 1) {
                // enough confirmations: reset and run interior.
                delete m_pendingIndex[m_pending[_operation].index];
                delete m_pending[_operation];
                return true;
            }
            else
            {
                // not enough: record that this owner in particular confirmed.
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
            }
        }
    }

    function reorganizeOwners() private {
        uint free = 1;
        while (free < m_numOwners)
        {
            while (free < m_numOwners && m_owners[free] != 0) free++;
            while (m_numOwners > 1 && m_owners[m_numOwners] == 0) m_numOwners--;
            if (free < m_numOwners && m_owners[m_numOwners] != 0 && m_owners[free] == 0)
            {
                m_owners[free] = m_owners[m_numOwners];
                m_ownerIndex[m_owners[free]] = free;
                m_owners[m_numOwners] = 0;
            }
        }
    }

    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i < length; ++i)
            if (m_pendingIndex[i] != 0)
                delete m_pending[m_pendingIndex[i]];
        delete m_pendingIndex;
    }

   	// FIELDS

    // the number of owners that must confirm the same operation before it is run.
    uint public m_required;
    // pointer used to find a free slot in m_owners
    uint public m_numOwners;

    // list of owners
    uint[256] m_owners;
    uint constant c_maxOwners = 250;
    // index on the list of owners to allow reverse lookup
    mapping(uint => uint) m_ownerIndex;
    // the ongoing operations.
    mapping(bytes32 => PendingState) m_pending;
    bytes32[] m_pendingIndex;
}

// inheritable "property" contract that enables methods to be protected by placing a linear limit (specifiable)
// on a particular resource per calendar day. is multiowned to allow the limit to be altered. resource that method
// uses is specified in the modifier.
contract daylimit is multiowned {

	// MODIFIERS

    // simple modifier for daily limit.
    modifier limitedDaily(uint _value) {
        if (underLimit(_value))
            _;
    }

	// METHODS

    // constructor - stores initial daily limit and records the present day's index.
    function daylimit(uint _limit) {
        m_dailyLimit = _limit;
        m_lastDay = today();
    }
    // (re)sets the daily limit. needs many of the owners to confirm. doesn't alter the amount already spent today.
    function setDailyLimit(uint _newLimit) onlymanyowners(sha3(msg.data)) external {
        m_dailyLimit = _newLimit;
    }
    // resets the amount already spent today. needs many of the owners to confirm.
    function resetSpentToday() onlymanyowners(sha3(msg.data)) external {
        m_spentToday = 0;
    }

    // INTERNAL METHODS

    // checks to see if there is at least `_value` left from the daily limit today. if there is, subtracts it and
    // returns true. otherwise just returns false.
    function underLimit(uint _value) internal onlyowner returns (bool) {
        // reset the spend limit if we're on a different day to last time.
        if (today() > m_lastDay) {
            m_spentToday = 0;
            m_lastDay = today();
        }
        // check to see if there's enough left - if so, subtract and return true.
        // overflow protection                    // dailyLimit check
        if (m_spentToday + _value >= m_spentToday && m_spentToday + _value <= m_dailyLimit) {
            m_spentToday += _value;
            return true;
        }
        return false;
    }
    // determines today's index.
    function today() private constant returns (uint) { return now / 1 days; }

	// FIELDS

    uint public m_dailyLimit;
    uint public m_spentToday;
    uint public m_lastDay;
}

// interface contract for multisig proxy contracts; see below for docs.
contract multisig {

	// EVENTS

    // logged events:
    // Funds has arrived into the wallet (record how much).
    event Deposit(address _from, uint value);
    // Single transaction going out of the wallet (record who signed for it, how much, and to whom it's going).
    event SingleTransact(address owner, uint value, address to, bytes data);
    // Multi-sig transaction going out of the wallet (record who signed for it last, the operation hash, how much, and to whom it's going).
    event MultiTransact(address owner, bytes32 operation, uint value, address to, bytes data);
    // Confirmation still needed for a transaction.
    event ConfirmationNeeded(bytes32 operation, address initiator, uint value, address to, bytes data);

    // FUNCTIONS

    // TODO: document
    function changeOwner(address _from, address _to) external;
    function execute(address _to, uint _value, bytes _data) external returns (bytes32);
    function confirm(bytes32 _h) returns (bool);
}

contract tokenswap is multisig, multiowned {
    Token public tokenCtr;
    bool public tokenSwap;
    uint public constant SWAP_LENGTH = 4  weeks;
    uint public constant MAX_ETH = 700000 ether;
    uint public amountRaised;

    modifier isZeroValue {
        if (msg.value == 0) throw;
        _;
    }

    modifier isOverCap {
	if (amountRaised + msg.value > MAX_ETH) throw;
        _;
    }

    modifier isSwapStopped {
        if (!tokenSwap) throw;
        _;
    }

    modifier areConditionsSatisfied {
	// End token swap if sale period ended
	if (tokenCtr.creationTime() + SWAP_LENGTH < now) {
            tokenCtr.disableTokenSwapLock();
            tokenSwap = false;
        }
        else {
            _;
	        // Check if cap has been reached in this tx
            if (amountRaised == MAX_ETH) {
                tokenCtr.disableTokenSwapLock();
                tokenSwap = false;
            }
        }
    }

    function safeToAdd(uint a, uint b) internal returns (bool) {
      return (a + b >= a && a + b >= b);
    }

    function startTokenSwap() onlyowner {
        tokenSwap = true;
    }

    function stopTokenSwap() onlyowner {
        tokenSwap = false;
    }

    function setTokenContract(address newTokenContractAddr) onlyowner {
        if (newTokenContractAddr == address(0x0)) throw;
        // Allow setting only once
        if (tokenCtr != address(0x0)) throw;

        tokenCtr = Token(newTokenContractAddr);
    }

    function buyTokens(address _beneficiary)
    payable
    isZeroValue
    isOverCap
    isSwapStopped
    areConditionsSatisfied {
        Deposit(msg.sender, msg.value);
        tokenCtr.mintTokens(_beneficiary, msg.value);
        if (!safeToAdd(amountRaised, msg.value)) throw;
        amountRaised += msg.value;
    }
}

// usage:
// bytes32 h = Wallet(w).from(oneOwner).transact(to, value, data);
// Wallet(w).from(anotherOwner).confirm(h);
contract Wallet is multisig, multiowned, daylimit, tokenswap {

	// TYPES

    // Transaction structure to remember details of transaction lest it need be saved for a later call.
    struct Transaction {
        address to;
        uint value;
        bytes data;
    }

    // METHODS

    // constructor - just pass on the owner array to the multiowned and
    // the limit to daylimit
    function Wallet(address[] _owners, uint _required, uint _daylimit)
            multiowned(_owners, _required) daylimit(_daylimit) {
    }

    // kills the contract sending everything to `_to`.
    function kill(address _to) onlymanyowners(sha3(msg.data)) external {
        //ensure owners can't prematurely stop token sale
        //and then render tokens untradable, as without this
        //check, the tokenSwapLock would never get disiabled
        //if this fires
        if (tokenCtr.tokenSwapLock()) throw;

        suicide(_to);
    }

    // gets called when no other function matches
    function()
    payable {
        buyTokens(msg.sender);
    }

    // Outside-visible transact entry point. Executes transaction immediately if below daily spend limit.
    // If not, goes into multisig process. We provide a hash on return to allow the sender to provide
    // shortcuts for the other confirmations (allowing them to avoid replicating the _to, _value
    // and _data arguments). They still get the option of using them if they want, anyways.
    function execute(address _to, uint _value, bytes _data) external onlyowner returns (bytes32 _r) {
        // Disallow the wallet contract from calling token contract once it's set
        // so tokens can't be minted arbitrarily once the sale starts.
        // Tokens can be minted for premine before the sale opens and tokenCtr is set.
        if (_to == address(tokenCtr)) throw;

        // first, take the opportunity to check that we're under the daily limit.
        if (underLimit(_value)) {
            SingleTransact(msg.sender, _value, _to, _data);
            // yes - just execute the call.
            if(!_to.call.value(_value)(_data))
            return 0;
        }
        // determine our operation hash.
        _r = sha3(msg.data, block.number);
        if (!confirm(_r) && m_txs[_r].to == 0) {
            m_txs[_r].to = _to;
            m_txs[_r].value = _value;
            m_txs[_r].data = _data;
            ConfirmationNeeded(_r, msg.sender, _value, _to, _data);
        }
    }

    // confirm a transaction through just the hash. we use the previous transactions map, m_txs, in order
    // to determine the body of the transaction from the hash provided.
    function confirm(bytes32 _h) onlymanyowners(_h) returns (bool) {
        if (m_txs[_h].to != 0) {
            if(!m_txs[_h].to.call.value(m_txs[_h].value)(m_txs[_h].data))
            MultiTransact(msg.sender, _h, m_txs[_h].value, m_txs[_h].to, m_txs[_h].data);
            delete m_txs[_h];
            return true;
        }
    }

    // INTERNAL METHODS

    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i < length; ++i)
            delete m_txs[m_pendingIndex[i]];
        super.clearPending();
    }

	// FIELDS

    // pending transactions we have at present.
    mapping (bytes32 => Transaction) m_txs;
}