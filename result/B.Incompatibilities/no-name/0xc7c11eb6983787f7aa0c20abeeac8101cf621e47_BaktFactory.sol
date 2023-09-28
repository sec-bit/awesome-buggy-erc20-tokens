/******************************************************************************\

file:   RegBase.sol
ver:    0.2.1
updated:9-May-2017
author: Darryl Morris (o0ragman0o)
email:  o0ragman0o AT gmail.com

This file is part of the SandalStraps framework

`RegBase` provides an inheriting contract the minimal API to be compliant with 
`Registrar`.  It includes a set-once, `bytes32 public regName` which is refered
to by `Registrar` lookups.

An owner updatable `address public owner` state variable is also provided and is
required by `Factory.createNew()`.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See MIT Licence for further details.
<https://opensource.org/licenses/MIT>.

\******************************************************************************/

pragma solidity ^0.4.10;

contract RegBase
{
//
// Constants
//

    bytes32 constant public VERSION = "RegBase v0.2.1";

//
// State Variables
//
    
    /// @dev A static identifier, set in the constructor and used for registrar
    /// lookup
    /// @return Registrar name SandalStraps registrars
    bytes32 public regName;

    /// @dev An general purpose resource such as short text or a key to a
    /// string in a StringsMap
    /// @return resource
    bytes32 public resource;
    
    /// @dev An address permissioned to enact owner restricted functions
    /// @return owner
    address public owner;

//
// Events
//

    // Triggered on change of owner address
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);

    // Triggered on change of resource
    event ChangedResource(bytes32 indexed resource);

//
// Modifiers
//

    // Permits only the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

//
// Functions
//

    /// @param _creator The calling address passed through by a factory,
    /// typically msg.sender
    /// @param _regName A static name referenced by a Registrar
    /// @param _owner optional owner address if creator is not the intended
    /// owner
    /// @dev On 0x0 value for owner, ownership precedence is:
    /// `_owner` else `_creator` else msg.sender
    function RegBase(address _creator, bytes32 _regName, address _owner)
    {
        regName = _regName;
        owner = _owner != 0x0 ? _owner : 
                _creator != 0x0 ? _creator : msg.sender;
    }
    
    /// @notice Will selfdestruct the contract
    function destroy()
        public
        onlyOwner
    {
        selfdestruct(msg.sender);
    }
    
    /// @notice Change the owner to `_owner`
    /// @param _owner The address to which ownership is transfered
    function changeOwner(address _owner)
        public
        onlyOwner
        returns (bool)
    {
        ChangedOwner(owner, _owner);
        owner = _owner;
        return true;
    }

    /// @notice Change the resource to `_resource`
    /// @param _resource A key or short text to be stored as the resource.
    function changeResource(bytes32 _resource)
        public
        onlyOwner
        returns (bool)
    {
        resource = _resource;
        ChangedResource(_resource);
        return true;
    }
}

/******************************************************************************\

file:   Factory.sol
ver:    0.2.1
updated:9-May-2017
author: Darryl Morris (o0ragman0o)
email:  o0ragman0o AT gmail.com

This file is part of the SandalStraps framework

Factories are a core but independant concept of the SandalStraps framework and 
can be used to create SandalStraps compliant 'product' contracts from embed
bytecode.

The abstract Factory contract is to be used as a SandalStraps compliant base for
product specific factories which must impliment the createNew() function.

is itself compliant with `Registrar` by inhereting `RegBase` and
compiant with `Factory` through the `createNew(bytes32 _name, address _owner)`
API.

An optional creation fee can be set and manually collected by the owner.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See MIT Licence for further details.
<https://opensource.org/licenses/MIT>.

\******************************************************************************/

pragma solidity ^0.4.10;

// import "https://github.com/o0ragman0o/SandalStraps/contracts/RegBase.sol";

contract Factory is RegBase
{
//
// Constants
//

    // Deriving factories should have `bytes32 constant public regName` being
    // the product's contract name, e.g for products "Foo":
    // bytes32 constant public regName = "Foo";

    // Deriving factories should have `bytes32 constant public VERSION` being
    // the product's contract name appended with 'Factory` and the version
    // of the product, e.g for products "Foo":
    // bytes32 constant public VERSION "FooFactory 0.0.1";

//
// State Variables
//

    /// @return The payment in wei required to create the product contract.
    uint public value;

//
// Events
//

    // Is triggered when a product is created
    event Created(address _creator, bytes32 _regName, address _address);

//
// Modifiers
//

    // To check that the correct fee has bene paid
    modifier feePaid() {
    	require(msg.value == value || msg.sender == owner);
    	_;
    }

//
// Functions
//

    /// @param _creator The calling address passed through by a factory,
    /// typically msg.sender
    /// @param _regName A static name referenced by a Registrar
    /// @param _owner optional owner address if creator is not the intended
    /// owner
    /// @dev On 0x0 value for _owner or _creator, ownership precedence is:
    /// `_owner` else `_creator` else msg.sender
    function Factory(address _creator, bytes32 _regName, address _owner)
        RegBase(_creator, _regName, _owner)
    {
        // nothing left to construct
    }
    
    /// @notice Set the product creation fee
    /// @param _fee The desired fee in wei
    function set(uint _fee) 
        onlyOwner
        returns (bool)
    {
        value = _fee;
        return true;
    }

    /// @notice Send contract balance to `owner`
    function withdraw()
        public
        returns (bool)
    {
        owner.transfer(this.balance);
        return true;
    }
    
    /// @notice Create a new product contract
    /// @param _regName A unique name if the the product is to be registered in
    /// a SandalStraps registrar
    /// @param _owner An address of a third party owner.  Will default to
    /// msg.sender if 0x0
    /// @return kAddr_ The address of the new product contract
    function createNew(bytes32 _regName, address _owner) 
        payable returns(address kAddr_);
}

/* Example implimentation of `createNew()` for a deriving factory

    function createNew(bytes32 _regName, address _owner)
        payable
        feePaid
        returns (address kAddr_)
    {
        require(_regName != 0x0);
        address kAddr_ = address(new Foo(msg.sender, _regName, _owner));
        Created(msg.sender, _regName, kAddr);
    }

Example product contract with `Factory` compiant constructor and `Registrar`
compliant `regName`.

The owner will be the caller by default if the `_owner` value is `0x0`.

If the contract requires initialization that would normally be done in a
constructor, then a `init()` function can be used instead post deployment.

    contract Foo is RegBase
    {
        bytes32 constant public VERSION = "Foo v0.0.1";
        uint val;
        uint8 public __initFuse = 1;
        
        function Foo(address _creator, bytes32 _regName, address _owner)
            RegBase(_creator, _regName, _owner)
        {
            // put non-parametric constructor code here.
        }
        
        function _init(uint _val)
        {
            require(__initFuse == 1);

            // put parametric constructor code here and call _init() post 
            // deployment
            val = _val;
            delete __initFuse;
        }
    }

*/

/*
file:   Bakt.sol
ver:    0.3.4-beta
updated:16-May-2017
author: Darryl Morris
email:  o0ragman0o AT gmail.com

Copyright is retained by the author.  Copying or running this software is only
by express permission.

This software is provided WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. The author
cannot be held liable for damage or loss.

Design Notes:

This contract DOES NOT offer trust to its holders. Holders instead elect a
Trustee from among the holders and the Trustee is responsible for funds.

The Trustee has unilateral powers to:
    - remove funds
    - use the contract to execute code on another contract
    - pay dividends
    - add holders
    - issue a token offer to a holder
    - selfdestruct the contract, on condition of 0 supply and 0 ether balance
    - veto a transaction

Holders have the power to:
    - vote for a preferred Trustee
    - veto a transaction if owned or owns > 10% of tokens
    - purchase tokens offer with ether.
    - redeem tokens for ether at the token price or a price proportional to
      the fund.
    - withdraw their balance of ether.
    - Cause a panic state in the contract if holds > 10% of tokens

This contract uses integer tokens so ERC20 `decimalPlaces` is 0.

Maximum number of holders is limited to 254 to prevent potential OOG loops
during elections.
Perpetual election of the `Trustee` runs in O(254) time to discover a winner.

Release Notes v0.3.4-beta:
-fixed magnitude bug introduced when using scientific notation (10**18 != 10e18)
-using 10**18 notation rather than 1e18 as already using 2**256 notation
-Intend to deploy factory to Ropsten, Rinkeby and Live 

Ropsten: 0.3.4-beta-test1 @ 0xc446575f7ed13f7b4b849f70ffa9f209a64db742

*/

// import "https://github.com/o0ragman0o/SandalStraps/contracts/Factory.sol";

pragma solidity ^0.4.10;


contract BaktInterface
{

/* Structs */

    struct Holder {
        uint8 id;
        address votingFor;
        uint40 offerExpiry;
        uint lastClaimed;
        uint tokenBalance;
        uint etherBalance;
        uint votes;
        uint offerAmount;
        mapping (address => uint) allowances;
    }

    struct TX {
        bool blocked;
        uint40 timeLock;
        address from;
        address to;
        uint value;
        bytes data;
    }


/* Constants */

    // Constant max tokens and max ether to prevent potential multiplication
    // overflows in 10e17 fixed point     
    uint constant MAXTOKENS = 2**128 - 10**18;
    uint constant MAXETHER = 2**128;
    uint constant BLOCKPCNT = 10; // 10% holding required to block TX's
    uint constant TOKENPRICE = 1000000000000000;
    uint8 public constant decimalPlaces = 15;

/* State Valiables */

    // A mutex used for reentry protection
    bool __reMutex;

    // Initialisation fuse. Blows on initialisation and used for entry check;
    bool __initFuse = true;

    // Allows the contract to accept or deny payments
    bool public acceptingPayments;

    // The period for which a panic will prevent functionality to the contract
    uint40 public PANICPERIOD;

    // The period for which a pending transaction must wait before being sent 
    uint40 public TXDELAY;

    /// @return The Panic flag state. false == calm, true == panicked
    bool public panicked;

    /// @return The pending transaction queue head pointer
    uint8 public ptxHead;

    /// @return The pending transaction queue tail pointer
    uint8 public ptxTail;

    /// @return The `PANIC` timelock expiry date/time
    uint40 public timeToCalm;

    /// @return The Address of the current elected trustee
    address public trustee;

    /// @return Total count of tokens
    uint public totalSupply;

    /// @return The combined balance of ether committed to holder accounts, 
    /// unclaimed dividends and values in pending transactions.
    uint public committedEther;

    /// @dev The running tally of dividends points accured by 
    /// dividend/totalSupply at each dividend payment
    uint dividendPoints;

    /// @return The historic tally of paid dividends
    uint public totalDividends;

    /// @return A static identifier, set in the constructor and used by
    /// registrars
    bytes32 public regName;

    /// @return An informational resource. Can be a sha3 of a string to lookup
    /// in a StringsMap
    bytes32 public resource;

    /// @param address The address of a holder.
    /// @return Holder data cast from struct Holder to an array
    mapping (address => Holder) public holders;

    /// @param uint8 The index of a holder
    /// @return An address of a holder
    address[256] public holderIndex;

    /// @param uint8 The index of a pending transaction
    /// @return Transaction details cast from struct TX to array
    TX[256] public pendingTxs;

/* Events */

    // Triggered when the contract recieves a payment
    event Deposit(uint value);

    // Triggered when ether is sent from the contract
    event Withdrawal(address indexed sender, address indexed recipient,
        uint value);

    // Triggered when a transaction is ordered
    event TransactionPending(uint indexed pTX, address indexed sender, 
        address indexed recipient, uint value, uint timeLock);

    // Triggered when a pending transaction is blocked
    event TransactionBlocked(address indexed by, uint indexed pTX);

    // Triggered when a transaction fails either by being blocked or failure of 
    // reciept
    event TransactionFailed(address indexed sender, address indexed recipient,
        uint value);

    // Triggered when the trustee pays dividends
    event DividendPaid(uint value);

    // ERC20 transfer notification
    event Transfer(address indexed from, address indexed to, uint value);

    // ERC20 approval notification
    event Approval(address indexed owner, address indexed spender, uint value);

    // Triggered on change of trustee
    event Trustee(address indexed trustee);

    // Trigger when a new holder is added
    event NewHolder(address indexed holder);

    // Triggered when a holder vacates
    event HolderVacated(address indexed holder);

    // Triggered when a offer of tokens is created
    event IssueOffer(address indexed holder);

    // Triggered on token creation when an offer is accepted
    event TokensCreated(address indexed holder, uint amount);

    // Triggered when tokens are destroyed during a redeeming round
    event TokensDestroyed(address indexed holder, uint amount);

    // Triggered when a hold causes a panic
    event Panicked(address indexed by);

    // Triggered when a holder calms a panic
    event Calm();

//
// Bakt Functions
//

    /// @dev Accept payment to the default function
    function() payable;

    /// @notice This will set the panic and pending periods.
    /// This action is a one off and is irrevocable! 
    /// @param _panicDelayInSeconds The panic delay period in seconds
    /// @param _pendingDelayInSeconds The pending period in seconds
    function _init(uint40 _panicDelayInSeconds, uint40 _pendingDelayInSeconds)
        returns (bool);

    /// @return The balance of uncommitted ether funds.
    function fundBalance() constant returns (uint);
    
    /// @return The constant TOKENPRICE.
    function tokenPrice() constant returns (uint);

//
// ERC20 API functions
//

    /// @param _addr The address of a holder
    /// @return The ERC20 token balance of the holder
    function balanceOf(address _addr) constant returns (uint);

    /// @notice Transfer `_amount` of tokens to `_to`
    /// @param _to the recipient holder's address
    /// @param _amount the number of tokens to transfer
    /// @return success state
    /// @dev `_to` must be an existing holder
    function transfer(address _to, uint _amount) returns (bool);

    /// @notice Transfer `_amount` of tokens from `_from` to `_to`
    /// @param _from The holder address from which to take tokens
    /// @param _to the recipient holder's address
    /// @param _amount the number of tokens to transfer
    /// @return success state
    /// @dev `_from` and `_to` must be existing holders
    function transferFrom(address _from, address _to, uint256 _amount)
        returns (bool);

    /// @notice Approve `_spender` to transfer `_amount` of tokens
    /// @param _spender the approved spender address. Does not have to be an
    /// existing holder.
    /// @param _amount the number of tokens to transfer
    function approve(address _spender, uint256 _amount) returns (bool);

    /// @param _owner The adddress of the holder owning tokens
    /// @param _spender The address of the account allowed to transfer tokens
    /// @return Amount of remaining token that the _spender can transfer
    function allowance(address _owner, address _spender)
        constant returns (uint256);

//
// Security Functions
//

    /// @notice Cause the contract to Panic. This will block most state changing
    /// functions for a set delay.
    /// Exceptions are `vote()`, `blockPendingTx(uint _txIdx)` and `PANIC()`.
    function PANIC() returns (bool);

    /// @notice Release the contract from a Panic after the panic period has
    /// expired.
    function calm() returns (bool);

    /// @notice Execute the first TX in the pendingTxs queue. Values will
    /// revert if the transaction is blocked or fails.
    function sendPending() returns (bool);

    /// @notice Block a pending transaction with id `_txIdx`. Pending
    /// transactions can be blocked by any holder at any time but must
    /// still be cleared from the pending transactions queue once the timelock
    /// is cleared.
    /// @param _txIdx Index of the transaction in the pending transactions
    /// table
    function blockPendingTx(uint _txIdx) returns (bool);

//
// Trustee functions
//

    /// @notice Send a transaction to `_to` containing `_value` with RLP encoded
    ///     arguments of `_data`
    /// @param _to The recipient address
    /// @param _value value of ether to send
    /// @param _data RLP encoded data to send with the transaction
    /// @dev Allows the trustee to initiate a transaction as the Bakt. It must
    /// be followed by sendPending() after the timeLock expires.
    function execute(address _to, uint _value, bytes _data) returns (uint8);

    /// @notice Pay dividends of `_value`
    /// @param _value a value of ether upto the fund balance
    /// @dev Allows the trustee to commit a portion of `fundBalance` to dividends.
    function payDividends(uint _value) returns (bool);

//
// Holder Functions
//

    /// @return Returns the array of holder addresses.
    function getHolders() constant returns(address[256]);

    /// @param _addr The address of a holder
    /// @return Returns the holder's withdrawable balance of ether
    function etherBalanceOf(address _addr) constant returns (uint);

    /// @notice Initiate a withdrawal of the holder's `etherBalance`
    /// Follow up with sendPending() once the timelock has expired
    function withdraw() returns(uint8);

    /// @notice Vacate holder `_addr`
    /// @param _addr The address of a holder with empty balances.
    function vacate(address _addr) returns (bool);

//
// Token Creation/Destruction Functions
//

    /// @notice Create tokens to the value of `msg.value` +
    /// `holder.etherBalance`
    /// @return success state
    /// @dev The amount of tokens created is:
    ///     tokens = floor((`etherBalance` + `msg.value`)/`tokenPrice`)
    ///     Any remainder of ether is credited to the holder's `etherBalance`
    function purchase() payable returns (bool);

    /// @notice Redeem `_amount` tokens back to the contract
    /// @param _amount The amount of tokens to redeem
    /// @dev ether = `_amount` * `fundBalance()` / `totalSupply`
    /// @return success state
    function redeem(uint _amount) returns (bool);

//
// Ballot functions
//

    /// @notice Vote for `_candidate` as preferred Trustee.
    /// @param _candidate The address of the preferred holder
    /// @return success state
    function vote(address _candidate) returns (bool);
}

contract Bakt is BaktInterface
{
    bytes32 constant public VERSION = "Bakt 0.3.4-beta";

//
// Bakt Functions
//

    // SandalStraps compliant constructor
    function Bakt(address _creator, bytes32 _regName, address _trustee)
    {
        regName = _regName;
        trustee = _trustee != 0x0 ? _trustee : 
                _creator != 0x0 ? _creator : msg.sender;
        join(trustee);
    }

    // Accept payment to the default function on the condition that
    // `acceptingPayments` is true
    function()
        payable
    {
        require(msg.value > 0 &&
            msg.value + this.balance < MAXETHER &&
            acceptingPayments);
        Deposit(msg.value);
    }

    // Destructor
    // Selfdestructs on the condition that `totalSupply` and `committedEther`
    // are 0
    function destroy()
        public
        canEnter
        onlyTrustee
    {
        require(totalSupply == 0 && committedEther == 0);
        
        delete holders[trustee];
        selfdestruct(msg.sender);
    }

    // One Time Programable shot to set the panic and pending periods.
    // 86400 == 1 day
    function _init(uint40 _panicPeriodInSeconds, uint40 _pendingPeriodInSeconds)
        onlyTrustee
        returns (bool)
    {
        require(__initFuse);
        PANICPERIOD = _panicPeriodInSeconds;
        TXDELAY = _pendingPeriodInSeconds;
        acceptingPayments = true;
        delete __initFuse;
        return true;
    }

    // Returns calculated fund balance
    function fundBalance()
        public
        constant
        returns (uint)
    {
        return this.balance - committedEther;
    }

    // Returns token price constant
    function tokenPrice()
        public
        constant
        returns (uint)
    {
        return TOKENPRICE;
    }

    // `RegBase` compliant `changeResource()` to restrict caller to
    // `trustee` rather than `owner`
    function changeResource(bytes32 _resource)
        public
        canEnter
        onlyTrustee
        returns (bool)
    {
        resource = _resource;
        return true;
    }

//
// ERC20 API functions
//

    // Returns holder token balance
    function balanceOf(address _addr) 
        public
        constant
        returns (uint)
    {
        return holders[_addr].tokenBalance;
    }

    // To transfer tokens
    function transfer(address _to, uint _amount)
        public
        canEnter
        isHolder(_to)
        returns (bool)
    {
        Holder from = holders[msg.sender];
        Holder to = holders[_to];

        Transfer(msg.sender, _to, _amount);
        return xfer(from, to, _amount);
    }

    // To transfer tokens by proxy
    function transferFrom(address _from, address _to, uint256 _amount)
        public
        canEnter
        isHolder(_to)
        returns (bool)
    {
        require(_amount <= holders[_from].allowances[msg.sender]);
        
        Holder from = holders[_from];
        Holder to = holders[_to];

        from.allowances[msg.sender] -= _amount;
        Transfer(_from, _to, _amount);
        return xfer(from, to, _amount);
    }

    // To approve a proxy for token transfers
    function approve(address _spender, uint256 _amount)
        public
        canEnter
        returns (bool)
    {
        holders[msg.sender].allowances[_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    // Return the alloance of a proxy
    function allowance(address _owner, address _spender)
        constant
        returns (uint256)
    {
        return holders[_owner].allowances[_spender];
    }

    // Processes token transfers and subsequent change in voting power
    function xfer(Holder storage _from, Holder storage _to, uint _amount)
        internal
        returns (bool)
    {
        // Ensure dividends are up to date at current balances
        updateDividendsFor(_from);
        updateDividendsFor(_to);

        // Remove existing votes
        revoke(_from);
        revoke(_to);

        // Transfer tokens
        _from.tokenBalance -= _amount;
        _to.tokenBalance += _amount;

        // Revote accoring to changed token balances
        revote(_from);
        revote(_to);

        // Force election
        election();
        return true;
    }

//
// Security Functions
//

    // Cause the contract to Panic. This will block most state changing
    // functions for a set delay.
    function PANIC()
        public
        isHolder(msg.sender)
        returns (bool)
    {
        // A blocking holder requires at least 10% of tokens
        require(holders[msg.sender].tokenBalance >= totalSupply / 10);
        
        panicked = true;
        timeToCalm = uint40(now + PANICPERIOD);
        Panicked(msg.sender);
        return true;
    }

    // Release the contract from a Panic after the panic period has expired.
    function calm()
        public
        isHolder(msg.sender)
        returns (bool)
    {
        require(uint40(now) > timeToCalm && panicked);
        
        panicked = false;
        Calm();
        return true;
    }

    // Queues a pending transaction 
    function timeLockSend(address _from, address _to, uint _value, bytes _data)
        internal
        returns (uint8)
    {
        // Check that queue is not full
        require(ptxHead + 1 != ptxTail);

        TX memory tx = TX({
            from: _from,
            to: _to,
            value: _value,
            data: _data,
            blocked: false,
            timeLock: uint40(now + TXDELAY)
        });
        TransactionPending(ptxHead, _from, _to, _value, now + TXDELAY);
        pendingTxs[ptxHead++] = tx;
        return  ptxHead - 1;
    }

    // Execute the first TX in the pendingTxs queue. Values will
    // revert if the transaction is blocked or fails.
    function sendPending()
        public
        preventReentry
        isHolder(msg.sender)
        returns (bool)
    {
        if (ptxTail == ptxHead) return false; // TX queue is empty
        
        TX memory tx = pendingTxs[ptxTail];
        if(now < tx.timeLock) return false;
        
        // Have memory cached the TX so deleting store now to prevent any chance
        // of double spends.
        delete pendingTxs[ptxTail++];
        
        if(!tx.blocked) {
            if(tx.to.call.value(tx.value)(tx.data)) {
                // TX sent successfully
                committedEther -= tx.value;
                
                Withdrawal(tx.from, tx.to, tx.value);
                return true;
            }
        }
        
        // TX is blocked or failed so manually revert balances to pre-pending
        // state
        if (tx.from == address(this)) {
            // Was sent from fund balance
            committedEther -= tx.value;
        } else {
            // Was sent from holder ether balance
            holders[tx.from].etherBalance += tx.value;
        }
        
        TransactionFailed(tx.from, tx.to, tx.value);
        return false;
    }

    // To block a pending transaction
    function blockPendingTx(uint _txIdx)
        public
        returns (bool)
    {
        // Only prevent reentry not entry during panic
        require(!__reMutex);
        
        // A blocking holder requires at least 10% of tokens or is trustee or
        // is from own account
        require(holders[msg.sender].tokenBalance >= totalSupply / BLOCKPCNT ||
            msg.sender == pendingTxs[ptxTail].from ||
            msg.sender == trustee);
        
        pendingTxs[_txIdx].blocked = true;
        TransactionBlocked(msg.sender, _txIdx);
        return true;
    }

//
// Trustee functions
//

    // For the trustee to send a transaction as the contract. Returns pending
    // TX queue index
    function execute(address _to, uint _value, bytes _data)
        public
        canEnter
        onlyTrustee
        returns (uint8)
    {
        require(_value <= fundBalance());

        committedEther += _value;
        return timeLockSend(address(this), _to, _value, _data);
    }

    // For the trustee to commit an amount from the fund balance as a dividend
    function payDividends(uint _value)
        public
        canEnter
        onlyTrustee
        returns (bool)
    {
        require(_value <= fundBalance());
        // Calculates dividend as percent of current `totalSupply` in 10e17
        // fixed point math
        dividendPoints += 10**18 * _value / totalSupply;
        totalDividends += _value;
        committedEther += _value;
        return true;
    }
    
    // For the trustee to add an address as a holder
    function addHolder(address _addr)
        public
        canEnter
        onlyTrustee
        returns (bool)
    {
        return join(_addr);
    }

    // Creates holder accounts.  Called by addHolder() and issue()
    function join(address _addr)
        internal
        returns (bool)
    {
        if(0 != holders[_addr].id) return true;
        
        require(_addr != address(this));
        
        uint8 id;
        // Search for the first available slot.
        while (holderIndex[++id] != 0) {}
        
        // if `id` is 0 then there has been a array full overflow.
        if(id == 0) revert();
        
        Holder holder = holders[_addr];
        holder.id = id;
        holder.lastClaimed = dividendPoints;
        holder.votingFor = trustee;
        holderIndex[id] = _addr;
        NewHolder(_addr);
        return true;
    }

    // For the trustee to allow or disallow payments made to the Bakt
    function acceptPayments(bool _accepting)
        public
        canEnter
        onlyTrustee
        returns (bool)
    {
        acceptingPayments = _accepting;
        return true;
    }

    // For the trustee to issue an offer of new tokens to a holder
    function issue(address _addr, uint _amount)
        public
        canEnter
        onlyTrustee
        returns (bool)
    {
        // prevent overflows in total supply
        assert(totalSupply + _amount < MAXTOKENS);
        
        join(_addr);
        Holder holder = holders[_addr];
        holder.offerAmount = _amount;
        holder.offerExpiry = uint40(now + 7 days);
        IssueOffer(_addr);
        return true;
    }

    // For the trustee to revoke an earlier Issue Offer
    function revokeOffer(address _addr)
        public
        canEnter
        onlyTrustee
        returns (bool)
    {
        Holder holder = holders[_addr];
        delete holder.offerAmount;
        delete holder.offerExpiry;
        return true;
    }

//
// Holder Functions
//

    // Returns the array of holder addresses.
    function getHolders()
        public
        constant
        returns(address[256])
    {
        return holderIndex;
    }

    // Returns the holder's withdrawable balance of ether
    function etherBalanceOf(address _addr)
        public
        constant
        returns (uint)
    {
        Holder holder = holders[_addr];
        return holder.etherBalance + dividendsOwing(holder);
    }

    // For a holder to initiate a withdrawal of their ether balance
    function withdraw()
        public
        canEnter
        returns(uint8 pTxId_)
    {
        Holder holder = holders[msg.sender];
        updateDividendsFor(holder);
        
        pTxId_ = timeLockSend(msg.sender, msg.sender, holder.etherBalance, "");
        holder.etherBalance = 0;
    }

    // To close a holder account
    function vacate(address _addr)
        public
        canEnter
        isHolder(msg.sender)
        isHolder(_addr)
        returns (bool)
    {
        Holder holder = holders[_addr];
        // Ensure holder account is empty, is not the trustee and there are no
        // pending transactions or dividends
        require(_addr != trustee);
        require(holder.tokenBalance == 0);
        require(holder.etherBalance == 0);
        require(holder.lastClaimed == dividendPoints);
        require(ptxHead == ptxTail);
        
        delete holderIndex[holder.id];
        delete holders[_addr];
        // NB can't garbage collect holder.allowances mapping
        return (true);
    }

//
// Token Creation/Destruction Functions
//

    // For a holder to buy an offer of tokens
    function purchase()
        payable
        canEnter
        returns (bool)
    {
        Holder holder = holders[msg.sender];
        // offer must exist
        require(holder.offerAmount > 0);
        // offer not expired
        require(holder.offerExpiry > now);
        // correct payment has been sent
        require(msg.value == holder.offerAmount * TOKENPRICE);
        
        updateDividendsFor(holder);
                
        revoke(holder);
                
        totalSupply += holder.offerAmount;
        holder.tokenBalance += holder.offerAmount;
        TokensCreated(msg.sender, holder.offerAmount);
        
        delete holder.offerAmount;
        delete holder.offerExpiry;
        
        revote(holder);
        election();
        return true;
    }

    // For holders to destroy tokens in return for ether during a redeeming
    // round
    function redeem(uint _amount)
        public
        canEnter
        isHolder(msg.sender)
        returns (bool)
    {
        uint redeemPrice;
        uint eth;
        
        Holder holder = holders[msg.sender];
        require(_amount <= holder.tokenBalance);
        
        updateDividendsFor(holder);
        
        revoke(holder);
        
        redeemPrice = fundBalance() / totalSupply;
        // prevent redeeming above token price which would allow an arbitrage
        // attack on the fund balance
        redeemPrice = redeemPrice < TOKENPRICE ? redeemPrice : TOKENPRICE;
        
        eth = _amount * redeemPrice;
        
        // will throw if either `amount` or `redeemPRice` are 0
        require(eth > 0);
        
        totalSupply -= _amount;
        holder.tokenBalance -= _amount;
        holder.etherBalance += eth;
        committedEther += eth;
        
        TokensDestroyed(msg.sender, _amount);
        revote(holder);
        election();
        return true;
    }

//
// Dividend Functions
//

    function dividendsOwing(Holder storage _holder)
        internal
        constant
        returns (uint _value)
    {
        // Calculates owed dividends in 10e17 fixed point math
        return (dividendPoints - _holder.lastClaimed) * _holder.tokenBalance/
            10**18;
    }
    
    function updateDividendsFor(Holder storage _holder)
        internal
    {
        _holder.etherBalance += dividendsOwing(_holder);
        _holder.lastClaimed = dividendPoints;
    }

//
// Ballot functions
//

    // To vote for a preferred Trustee.
    function vote(address _candidate)
        public
        isHolder(msg.sender)
        isHolder(_candidate)
        returns (bool)
    {
        // Only prevent reentry not entry during panic
        require(!__reMutex);
        
        Holder holder = holders[msg.sender];
        revoke(holder);
        holder.votingFor = _candidate;
        revote(holder);
        election();
        return true;
    }

    // Loops through holders to find the holder with most votes and declares
    // them to be the Executive;
    function election()
        internal
    {
        uint max;
        uint winner;
        uint votes;
        uint8 i;
        address addr;
        
        if (0 == totalSupply) return;
        
        while(++i != 0)
        {
            addr = holderIndex[i];
            if (addr != 0x0) {
                votes = holders[addr].votes;
                if (votes > max) {
                    max = votes;
                    winner = i;
                }
            }
        }
        trustee = holderIndex[winner];
        Trustee(trustee);
    }

    // Pulls votes from the preferred candidate
    // required before any adjustments to `tokenBalance` or vote preference.
    function revoke(Holder _holder)
        internal
    {
        holders[_holder.votingFor].votes -= _holder.tokenBalance;
    }

    // Places votes with preferred candidate
    // required after any adjustments to `tokenBalance` or vote preference.
    function revote(Holder _holder)
        internal
    {
        holders[_holder.votingFor].votes += _holder.tokenBalance;
    }

//
// Modifiers
//

    // Blocks if reentry mutex or panicked is true or sets rentry mutex to true
    modifier preventReentry() {
        require(!(__reMutex || panicked || __initFuse));
        __reMutex = true;
        _;
        __reMutex = false;
        return;
    }

    // Blocks if reentry mutex or panicked is true
    modifier canEnter() {
        require(!(__reMutex || panicked || __initFuse));
        _;
    }

    // Blocks if '_addr' is not a holder
    modifier isHolder(address _addr) {
        require(0 != holders[_addr].id);
        _;
    }

    // Block non-trustee holders
    modifier onlyTrustee() {
        require(msg.sender == trustee);
        _;
    }
}


// SandalStraps compliant factory for Bakt
contract BaktFactory is Factory
{
    // Live: 0xc7c11eb6983787f7aa0c20abeeac8101cf621e47
    // https://etherscan.io/address/0xc7c11eb6983787f7aa0c20abeeac8101cf621e47
    // Ropsten: 0xda33129464688b7bd752ce64e9ed6bca65f44902 (could not verify),
    //          0x19124dbab3fcba78b8d240ed2f2eb87654e252d4
    // Rinkeby: 

/* Constants */

    bytes32 constant public regName = "Bakt";
    bytes32 constant public VERSION = "Bakt Factory v0.3.4-beta";

/* Constructor Destructor*/

    function BaktFactory(address _creator, bytes32 _regName, address _owner)
        Factory(_creator, _regName, _owner)
    {
        // nothing to construct
    }

/* Public Functions */

    function createNew(bytes32 _regName, address _owner)
        payable
        feePaid
        returns (address kAddr_)
    {
        require(_regName != 0x0);
        kAddr_ = new Bakt(owner, _regName, msg.sender);
        Created(msg.sender, _regName, kAddr_);
    }
}