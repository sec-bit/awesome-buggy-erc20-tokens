/*
file:   Base.sol
ver:    0.2.1
updated:18-Nov-2016
author: Darryl Morris (o0ragman0o)
email:  o0ragman0o AT gmail.com

An basic contract furnishing inheriting contracts with ownership, reentry
protection and safe sending functions.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.
<http://www.gnu.org/licenses/>.
*/

pragma solidity ^0.4.0;

contract Base
{
/* Constants */

    string constant VERSION = "Base 0.1.1 \n";

/* State Variables */

    bool mutex;
    address public owner;

/* Events */

    event Log(string message);
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);

/* Modifiers */

    // To throw call not made by owner
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

    // This modifier can be used on functions with external calls to
    // prevent reentry attacks.
    // Constraints:
    //   Protected functions must have only one point of exit.
    //   Protected functions cannot use the `return` keyword
    //   Protected functions return values must be through return parameters.
    modifier preventReentry() {
        if (mutex) throw;
        else mutex = true;
        _;
        delete mutex;
        return;
    }

    // This modifier can be applied to pulic access state mutation functions
    // to protect against reentry if a `mutextProtect` function is already
    // on the call stack.
    modifier noReentry() {
        if (mutex) throw;
        _;
    }

    // Same as noReentry() but intended to be overloaded
    modifier canEnter() {
        if (mutex) throw;
        _;
    }
    
/* Functions */

    function Base() { owner = msg.sender; }

    function version() public constant returns (string) {
        return VERSION;
    }

    function contractBalance() public constant returns(uint) {
        return this.balance;
    }

    // Change the owner of a contract
    function changeOwner(address _newOwner)
        public onlyOwner returns (bool)
    {
        owner = _newOwner;
        ChangedOwner(msg.sender, owner);
        return true;
    }
    
    function safeSend(address _recipient, uint _ether)
        internal
        preventReentry()
        returns (bool success_)
    {
        if(!_recipient.call.value(_ether)()) throw;
        success_ = true;
    }
}

/* End of Base */

/*
file:   Math.sol
ver:    0.2.0
updated:18-Nov-2016
author: Darryl Morris
email:  o0ragman0o AT gmail.com

An inheritable contract containing math functions and comparitors.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.
<http://www.gnu.org/licenses/>.
*/

pragma solidity ^0.4.0;

contract Math
{

/* Constants */

    string constant VERSION = "Math 0.0.1 \n";
    uint constant NULL = 0;
    bool constant LT = false;
    bool constant GT = true;
    // No type bool <-> int type converstion in solidity :~(
    uint constant iTRUE = 1;
    uint constant iFALSE = 0;
    uint constant iPOS = 1;
    uint constant iZERO = 0;
    uint constant iNEG = uint(-1);


/* Modifiers */

/* Functions */
    function version() public constant returns (string)
    {
        return VERSION;
    }

    function assert(bool assertion) internal constant
    {
      if (!assertion) throw;
    }
    
    // @dev Parametric comparitor for > or <
    // !_sym returns a < b
    // _sym  returns a > b
    function cmp (uint a, uint b, bool _sym) internal constant returns (bool)
    {
        return (a!=b) && ((a < b) != _sym);
    }

    /// @dev Parametric comparitor for >= or <=
    /// !_sym returns a <= b
    /// _sym  returns a >= b
    function cmpEq (uint a, uint b, bool _sym) internal constant returns (bool)
    {
        return (a==b) || ((a < b) != _sym);
    }
    
    /// Trichotomous comparitor
    /// a < b returns -1
    /// a == b returns 0
    /// a > b returns 1
/*    function triCmp(uint a, uint b) internal constant returns (bool)
    {
        uint c = a - b;
        return c & c & (0 - 1);
    }
    
    function nSign(uint a) internal returns (uint)
    {
        return a & 2^255;
    }
    
    function neg(uint a) internal returns (uint) {
        return 0 - a;
    }
*/    
    function safeMul(uint a, uint b) internal constant returns (uint)
    {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function safeSub(uint a, uint b) internal constant returns (uint)
    {
      assert(b <= a);
      return a - b;
    }

    function safeAdd(uint a, uint b) internal constant returns (uint)
    {
      uint c = a + b;
      assert(c>=a && c>=b);
      return c;
    }
}

/* End of Math */


/*
file:   ERC20.sol
ver:    0.2.3
updated:18-Nov-2016
author: Darryl Morris
email:  o0ragman0o AT gmail.com

An ERC20 compliant token.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.
<http://www.gnu.org/licenses/>.
*/

//pragma solidity ^0.4.0;

//import "Math.sol";
//import "Base.sol";

// ERC20 Standard Token Interface with safe maths and reentry protection
contract ERC20Interface
{
/* Structs */

/* Constants */
    string constant VERSION = "ERC20 0.2.3-o0ragman0o\nMath 0.0.1\nBase 0.1.1\n";

/* State Valiables */
    uint public totalSupply;
    uint8 public decimalPlaces;
    string public name;
    string public symbol;
    
    // Token ownership mapping
    // mapping (address => uint) public balanceOf;
    mapping (address => uint) balance;
    
    // Transfer allowances mapping
    mapping (address => mapping (address => uint)) public allowance;

/* Events */
    // Triggered when tokens are transferred.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value);

/* Modifiers */

/* Function Abstracts */

    /* State variable Accessor Functions (for reference - leave commented) */

    // Returns the allowable transfer of tokens by a proxy
    // function allowance (address tokenHolders, address proxy, uint allowance) public constant returns (uint);

    // Get the total token supply
    // function totalSupply() public constant returns (uint);

    // Returns token symbol
    // function symbol() public constant returns(string);

    // Returns token symbol
    // function name() public constant returns(string);

    // Returns decimal places designated for unit of token.
    // function decimalPlaces() public returns(uint);

    // Send _value amount of tokens to address _to
    // function transfer(address _to, uint256 _value) public returns (bool success);

    // Send _value amount of tokens from address _from to address _to
    // function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the
    // _value amount.
    // function approve(address _spender, uint256 _value) public returns (bool success);
}

contract ERC20Token is Base, Math, ERC20Interface
{

/* Events */

/* Structs */

/* Constants */

/* State Valiables */

/* Modifiers */

    modifier isAvailable(uint _amount) {
        if (_amount > balance[msg.sender]) throw;
        _;
    }

    modifier isAllowed(address _from, uint _amount) {
        if (_amount > allowance[_from][msg.sender] ||
           _amount > balance[_from]) throw;
        _;        
    }

/* Funtions Public */

    function ERC20Token(
        uint _supply,
        uint8 _decimalPlaces,
        string _symbol,
        string _name)
    {
        totalSupply = _supply;
        decimalPlaces = _decimalPlaces;
        symbol = _symbol;
        name = _name;
        balance[msg.sender] = totalSupply;
    }
    
    function version() public constant returns(string) {
        return VERSION;
    }
    
    function balanceOf(address _addr)
        public
        constant
        returns (uint)
    {
        return balance[_addr];
    }

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value)
        external
        canEnter
        isAvailable(_value)
        returns (bool)
    {
        balance[msg.sender] = safeSub(balance[msg.sender], _value);
        balance[_to] = safeAdd(balance[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value)
        external
        canEnter
        isAllowed(_from, _value)
        returns (bool)
    {
        balance[_from] = safeSub(balance[_from], _value);
        balance[_to] = safeAdd(balance[_to], _value);
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the
    // _value amount. If this function is called again it overwrites the current
    // allowance with _value.
    function approve(address _spender, uint256 _value)
        external
        canEnter
        returns (bool success)
    {
        if (balance[msg.sender] == 0) throw;
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

/* End of ERC20 */


/*
file:   LibCLL.sol
ver:    0.3.1
updated:21-Sep-2016
author: Darryl Morris
email:  o0ragman0o AT gmail.com

A Solidity library for implementing a data indexing regime using
a circular linked list.

This library provisions lookup, navigation and key/index storage
functionality which can be used in conjunction with an array or mapping.

NOTICE: This library uses internal functions only and so cannot be compiled
and deployed independently from its calling contract.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.
<http://www.gnu.org/licenses/>.
*/

//pragma solidity ^0.4.0;

// LibCLL using `uint` keys
library LibCLLu {

    string constant VERSION = "LibCLLu 0.3.1";
    uint constant NULL = 0;
    uint constant HEAD = NULL;
    bool constant PREV = false;
    bool constant NEXT = true;
    
    struct CLL{
        mapping (uint => mapping (bool => uint)) cll;
    }

    // n: node id  d: direction  r: return node id

    function version() internal constant returns (string) {
        return VERSION;
    }

    // Return existential state of a list.
    function exists(CLL storage self)
        internal
        constant returns (bool)
    {
        if (self.cll[HEAD][PREV] != HEAD || self.cll[HEAD][NEXT] != HEAD)
            return true;
    }
    
    // Returns the number of elements in the list
    function sizeOf(CLL storage self) internal constant returns (uint r) {
        uint i = step(self, HEAD, NEXT);
        while (i != HEAD) {
            i = step(self, i, NEXT);
            r++;
        }
        return;
    }

    // Returns the links of a node as and array
    function getNode(CLL storage self, uint n)
        internal  constant returns (uint[2])
    {
        return [self.cll[n][PREV], self.cll[n][NEXT]];
    }

    // Returns the link of a node `n` in direction `d`.
    function step(CLL storage self, uint n, bool d)
        internal  constant returns (uint)
    {
        return self.cll[n][d];
    }

    // Can be used before `insert` to build an ordered list
    // `a` an existing node to search from, e.g. HEAD.
    // `b` value to seek
    // `r` first node beyond `b` in direction `d`
    function seek(CLL storage self, uint a, uint b, bool d)
        internal  constant returns (uint r)
    {
        r = step(self, a, d);
        while  ((b!=r) && ((b < r) != d)) r = self.cll[r][d];
        return;
    }

    // Creates a bidirectional link between two nodes on direction `d`
    function stitch(CLL storage self, uint a, uint b, bool d) internal  {
        self.cll[b][!d] = a;
        self.cll[a][d] = b;
    }

    // Insert node `b` beside and existing node `a` in direction `d`.
    function insert (CLL storage self, uint a, uint b, bool d) internal  {
        uint c = self.cll[a][d];
        stitch (self, a, b, d);
        stitch (self, b, c, d);
    }
    
    function remove(CLL storage self, uint n) internal returns (uint) {
        if (n == NULL) return;
        stitch(self, self.cll[n][PREV], self.cll[n][NEXT], NEXT);
        delete self.cll[n][PREV];
        delete self.cll[n][NEXT];
        return n;
    }

    function push(CLL storage self, uint n, bool d) internal  {
        insert(self, HEAD, n, d);
    }
    
    function pop(CLL storage self, bool d) internal returns (uint) {
        return remove(self, step(self, HEAD, d));
    }
}

// LibCLL using `int` keys
library LibCLLi {

    string constant VERSION = "LibCLLi 0.3.1";
    int constant NULL = 0;
    int constant HEAD = NULL;
    bool constant PREV = false;
    bool constant NEXT = true;
    
    struct CLL{
        mapping (int => mapping (bool => int)) cll;
    }

    // n: node id  d: direction  r: return node id

    function version() internal constant returns (string) {
        return VERSION;
    }

    // Return existential state of a node. n == HEAD returns list existence.
    function exists(CLL storage self, int n) internal constant returns (bool) {
        if (self.cll[HEAD][PREV] != HEAD || self.cll[HEAD][NEXT] != HEAD)
            return true;
    }
    // Returns the number of elements in the list
    function sizeOf(CLL storage self) internal constant returns (uint r) {
        int i = step(self, HEAD, NEXT);
        while (i != HEAD) {
            i = step(self, i, NEXT);
            r++;
        }
        return;
    }

    // Returns the links of a node as and array
    function getNode(CLL storage self, int n)
        internal  constant returns (int[2])
    {
        return [self.cll[n][PREV], self.cll[n][NEXT]];
    }

    // Returns the link of a node `n` in direction `d`.
    function step(CLL storage self, int n, bool d)
        internal  constant returns (int)
    {
        return self.cll[n][d];
    }

    // Can be used before `insert` to build an ordered list
    // `a` an existing node to search from, e.g. HEAD.
    // `b` value to seek
    // `r` first node beyond `b` in direction `d`
    function seek(CLL storage self, int a, int b, bool d)
        internal  constant returns (int r)
    {
        r = step(self, a, d);
        while  ((b!=r) && ((b < r) != d)) r = self.cll[r][d];
        return;
    }

    // Creates a bidirectional link between two nodes on direction `d`
    function stitch(CLL storage self, int a, int b, bool d) internal  {
        self.cll[b][!d] = a;
        self.cll[a][d] = b;
    }

    // Insert node `b` beside existing node `a` in direction `d`.
    function insert (CLL storage self, int a, int b, bool d) internal  {
        int c = self.cll[a][d];
        stitch (self, a, b, d);
        stitch (self, b, c, d);
    }
    
    function remove(CLL storage self, int n) internal returns (int) {
        if (n == NULL) return;
        stitch(self, self.cll[n][PREV], self.cll[n][NEXT], NEXT);
        delete self.cll[n][PREV];
        delete self.cll[n][NEXT];
        return n;
    }

    function push(CLL storage self, int n, bool d) internal  {
        insert(self, HEAD, n, d);
    }
    
    function pop(CLL storage self, bool d) internal returns (int) {
        return remove(self, step(self, HEAD, d));
    }
}


/* End of LibCLLi */

/*
file:   ITT.sol
ver:    0.3.6
updated:18-Nov-2016
author: Darryl Morris (o0ragman0o)
email:  o0ragman0o AT gmail.com

An ERC20 compliant token with currency
exchange functionality here called an 'Intrinsically Tradable
Token' (ITT).

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.
<http://www.gnu.org/licenses/>.
*/

//pragma solidity ^0.4.0;

//import "Base.sol";
//import "Math.sol";
//import "ERC20.sol";
//import "LibCLL.sol";

contract ITTInterface
{

    using LibCLLu for LibCLLu.CLL;

/* Constants */

    string constant VERSION = "ITT 0.3.6\nERC20 0.2.3-o0ragman0o\nMath 0.0.1\nBase 0.1.1\n";
    uint constant HEAD = 0;
    uint constant MINNUM = uint(1);
    // use only 128 bits of uint to prevent mul overflows.
    uint constant MAXNUM = 2**128;
    uint constant MINPRICE = uint(1);
    uint constant NEG = uint(-1); //2**256 - 1
    bool constant PREV = false;
    bool constant NEXT = true;
    bool constant BID = false;
    bool constant ASK = true;

    // minimum gas required to prevent out of gas on 'take' loop
    uint constant MINGAS = 100000;

    // For staging and commiting trade details.  This saves unneccessary state
    // change gas usage during multi order takes but does increase logic
    // complexity when encountering 'trade with self' orders
    struct TradeMessage {
        bool make;
        bool side;
        uint price;
        uint tradeAmount;
        uint balance;
        uint etherBalance;
    }

/* State Valiables */

    // To allow for trade halting by owner.
    bool public trading;

    // Mapping for ether ownership of accumulated deposits, sales and refunds.
    mapping (address => uint) etherBalance;

    // Orders are stored in circular linked list FIFO's which are mappings with
    // price as key and value as trader address.  A trader can have only one
    // order open at each price. Reordering at that price will cancel the first
    // order and push the new one onto the back of the queue.
    mapping (uint => LibCLLu.CLL) orderFIFOs;
    
    // Order amounts are stored in a seperate lookup. The keys of this mapping
    // are `sha3` hashes of the price and trader address.
    // This mapping prevents more than one order at a particular price.
    mapping (bytes32 => uint) amounts;

    // The pricebook is a linked list holding keys to lookup the price FIFO's
    LibCLLu.CLL priceBook = orderFIFOs[0];


/* Events */

    // Triggered on a make sell order
    event Ask (uint indexed price, uint amount, address indexed trader);

    // Triggered on a make buy order
    event Bid (uint indexed price, uint amount, address indexed trader);

    // Triggered on a filled order
    event Sale (uint indexed price, uint amount, address indexed buyer, address indexed seller);

    // Triggered when trading is started or halted
    event Trading(bool trading);

/* Functions Public constant */

    /// @notice Returns best bid or ask price. 
    function spread(bool _side) public constant returns(uint);
    
    /// @notice Returns the order amount for trader `_trader` at '_price'
    /// @param _trader Address of trader
    /// @param _price Price of order
    function getAmount(uint _price, address _trader) 
        public constant returns(uint);

    /// @notice Returns the collective order volume at a `_price`.
    /// @param _price FIFO for price.
    function getPriceVolume(uint _price) public constant returns (uint);

    /// @notice Returns an array of all prices and their volumes.
    /// @dev [even] indecies are the price. [odd] are the volume. [0] is the
    /// index of the spread.
    function getBook() public constant returns (uint[]);

/* Functions Public non-constant*/

    /// @notice Will buy `_amount` tokens at or below `_price` each.
    /// @param _bidPrice Highest price to bid.
    /// @param _amount The requested amount of tokens to buy.
    /// @param _make Value of true will make order if not filled.
    function buy (uint _bidPrice, uint _amount, bool _make)
        payable returns (bool);

    /// @notice Will sell `_amount` tokens at or above `_price` each.
    /// @param _askPrice Lowest price to ask.
    /// @param _amount The requested amount of tokens to buy.
    /// @param _make A value of true will make an order if not market filled.
    function sell (uint _askPrice, uint _amount, bool _make)
        external returns (bool);

    /// @notice Will withdraw `_ether` to your account.
    /// @param _ether The amount to withdraw
    function withdraw(uint _ether)
        external returns (bool success_);

    /// @notice Cancel order at `_price`
    /// @param _price The price at which the order was placed.
    function cancel(uint _price) 
        external returns (bool);

    /// @notice Will set trading state to `_trading`
    /// @param _trading State to set trading to.
    function setTrading(bool _trading) 
        external returns (bool);
}


/* Intrinsically Tradable Token code */ 

contract ITT is ERC20Token, ITTInterface
{

/* Structs */

/* Modifiers */

    /// @dev Passes if token is currently trading
    modifier isTrading() {
        if (!trading) throw;
        _;
    }

    /// @dev Validate buy parameters
    modifier isValidBuy(uint _bidPrice, uint _amount) {
        if ((etherBalance[msg.sender] + msg.value) < (_amount * _bidPrice) ||
            _amount == 0 || _amount > totalSupply ||
            _bidPrice <= MINPRICE || _bidPrice >= MAXNUM) throw; // has insufficient ether.
        _;
    }

    /// @dev Validates sell parameters. Price must be larger than 1.
    modifier isValidSell(uint _askPrice, uint _amount) {
        if (_amount > balance[msg.sender] || _amount == 0 ||
            _askPrice < MINPRICE || _askPrice > MAXNUM) throw;
        _;
    }
    
    /// @dev Validates ether balance
    modifier hasEther(address _member, uint _ether) {
        if (etherBalance[_member] < _ether) throw;
        _;
    }

    /// @dev Validates token balance
    modifier hasBalance(address _member, uint _amount) {
        if (balance[_member] < _amount) throw;
        _;
    }

/* Functions */

    function ITT(
        uint _totalSupply,
        uint8 _decimalPlaces,
        string _symbol,
        string _name
        )
            ERC20Token(
                _totalSupply,
                _decimalPlaces,
                _symbol,
                _name
                )
    {
        // setup pricebook and maximum spread.
        priceBook.cll[HEAD][PREV] = MINPRICE;
        priceBook.cll[MINPRICE][PREV] = MAXNUM;
        priceBook.cll[HEAD][NEXT] = MAXNUM;
        priceBook.cll[MAXNUM][NEXT] = MINPRICE;
        trading = true;
        balance[owner] = totalSupply;
    }

/* Functions Getters */

    function version() public constant returns(string) {
        return VERSION;
    }

    function etherBalanceOf(address _addr) public constant returns (uint) {
        return etherBalance[_addr];
    }

    function spread(bool _side) public constant returns(uint) {
        return priceBook.step(HEAD, _side);
    }

    function getAmount(uint _price, address _trader) 
        public constant returns(uint) {
        return amounts[sha3(_price, _trader)];
    }

    function sizeOf(uint l) constant returns (uint s) {
        if(l == 0) return priceBook.sizeOf();
        return orderFIFOs[l].sizeOf();
    }
    
    function getPriceVolume(uint _price) public constant returns (uint v_)
    {
        uint n = orderFIFOs[_price].step(HEAD,NEXT);
        while (n != HEAD) { 
            v_ += amounts[sha3(_price, address(n))];
            n = orderFIFOs[_price].step(n, NEXT);
        }
        return;
    }

    function getBook() public constant returns (uint[])
    {
        uint i; 
        uint p = priceBook.step(MINNUM, NEXT);
        uint[] memory volumes = new uint[](priceBook.sizeOf() * 2 - 2);
        while (p < MAXNUM) {
            volumes[i++] = p;
            volumes[i++] = getPriceVolume(p);
            p = priceBook.step(p, NEXT);
        }
        return volumes; 
    }
    
    function numOrdersOf(address _addr) public constant returns (uint)
    {
        uint c;
        uint p = MINNUM;
        while (p < MAXNUM) {
            if (amounts[sha3(p, _addr)] > 0) c++;
            p = priceBook.step(p, NEXT);
        }
        return c;
    }
    
    function getOpenOrdersOf(address _addr) public constant returns (uint[])
    {
        uint i;
        uint c;
        uint p = MINNUM;
        uint[] memory open = new uint[](numOrdersOf(_addr)*2);
        p = MINNUM;
        while (p < MAXNUM) {
            if (amounts[sha3(p, _addr)] > 0) {
                open[i++] = p;
                open[i++] = amounts[sha3(p, _addr)];
            }
            p = priceBook.step(p, NEXT);
        }
        return open;
    }

    function getNode(uint _list, uint _node) public constant returns(uint[2])
    {
        return [orderFIFOs[_list].cll[_node][PREV], 
            orderFIFOs[_list].cll[_node][NEXT]];
    }
    
/* Functions Public */

// Here non-constant public functions act as a security layer. They are re-entry
// protected so cannot call each other. For this reason, they
// are being used for parameter and enterance validation, while internal
// functions manage the logic. This also allows for deriving contracts to
// overload the public function with customised validations and not have to
// worry about rewritting the logic.

    function buy (uint _bidPrice, uint _amount, bool _make)
        payable
        canEnter
        isTrading
        isValidBuy(_bidPrice, _amount)
        returns (bool)
    {
        trade(_bidPrice, _amount, BID, _make);
        return true;
    }

    function sell (uint _askPrice, uint _amount, bool _make)
        external
        canEnter
        isTrading
        isValidSell(_askPrice, _amount)
        returns (bool)
    {
        trade(_askPrice, _amount, ASK, _make);
        return true;
    }

    function withdraw(uint _ether)
        external
        canEnter
        hasEther(msg.sender, _ether)
        returns (bool success_)
    {
        etherBalance[msg.sender] -= _ether;
        safeSend(msg.sender, _ether);
        success_ = true;
    }

    function cancel(uint _price)
        external
        canEnter
        returns (bool)
    {
        TradeMessage memory tmsg;
        tmsg.price = _price;
        tmsg.balance = balance[msg.sender];
        tmsg.etherBalance = etherBalance[msg.sender];
        cancelIntl(tmsg);
        balance[msg.sender] = tmsg.balance;
        etherBalance[msg.sender] = tmsg.etherBalance;
        return true;
    }
    
    function setTrading(bool _trading)
        external
        onlyOwner
        canEnter
        returns (bool)
    {
        trading = _trading;
        Trading(true);
        return true;
    }

/* Functions Internal */

// Internal functions handle this contract's logic.

    function trade (uint _price, uint _amount, bool _side, bool _make) internal {
        TradeMessage memory tmsg;
        tmsg.price = _price;
        tmsg.tradeAmount = _amount;
        tmsg.side = _side;
        tmsg.make = _make;
        
        // Cache state balances to memory and commit to storage only once after trade.
        tmsg.balance  = balance[msg.sender];
        tmsg.etherBalance = etherBalance[msg.sender] + msg.value;

        take(tmsg);
        make(tmsg);
        
        balance[msg.sender] = tmsg.balance;
        etherBalance[msg.sender] = tmsg.etherBalance;
    }
    
    function take (TradeMessage tmsg)
        internal
    {
        address maker;
        bytes32 orderHash;
        uint takeAmount;
        uint takeEther;
        // use of signed math on unsigned ints is intentional
        uint sign = tmsg.side ? uint(1) : uint(-1);
        uint bestPrice = spread(!tmsg.side);

        // Loop with available gas to take orders
        while (
            tmsg.tradeAmount > 0 &&
            cmpEq(tmsg.price, bestPrice, !tmsg.side) && 
            msg.gas > MINGAS
        )
        {
            maker = address(orderFIFOs[bestPrice].step(HEAD, NEXT));
            orderHash = sha3(bestPrice, maker);
            if (tmsg.tradeAmount < amounts[orderHash]) {
                // Prepare to take partial order
                amounts[orderHash] = safeSub(amounts[orderHash], tmsg.tradeAmount);
                takeAmount = tmsg.tradeAmount;
                tmsg.tradeAmount = 0;
            } else {
                // Prepare to take full order
                takeAmount = amounts[orderHash];
                tmsg.tradeAmount = safeSub(tmsg.tradeAmount, takeAmount);
                closeOrder(bestPrice, maker);
            }
            takeEther = safeMul(bestPrice, takeAmount);
            // signed multiply on uints is intentional and so safeMaths will 
            // break here. Valid range for exit balances are 0..2**128 
            tmsg.etherBalance += takeEther * sign;
            tmsg.balance -= takeAmount * sign;
            if (tmsg.side) {
                // Sell to bidder
                if (msg.sender == maker) {
                    // bidder is self
                    tmsg.balance += takeAmount;
                } else {
                    balance[maker] += takeAmount;
                }
            } else {
                // Buy from asker;
                if (msg.sender == maker) {
                    // asker is self
                    tmsg.etherBalance += takeEther;
                } else {                
                    etherBalance[maker] += takeEther;
                }
            }
            // prep for next order
            bestPrice = spread(!tmsg.side);
            Sale (bestPrice, takeAmount, msg.sender, maker);
        }
    }

    function make(TradeMessage tmsg)
        internal
    {
        bytes32 orderHash;
        if (tmsg.tradeAmount == 0 || !tmsg.make || msg.gas < MINGAS) return;
        orderHash = sha3(tmsg.price, msg.sender);
        if (amounts[orderHash] != 0) {
            // Cancel any pre-existing owned order at this price
            cancelIntl(tmsg);
        }
        if (!orderFIFOs[tmsg.price].exists()) {
            // Register price in pricebook
            priceBook.insert(
                priceBook.seek(HEAD, tmsg.price, tmsg.side),
                tmsg.price, !tmsg.side);
        }

        amounts[orderHash] = tmsg.tradeAmount;
        orderFIFOs[tmsg.price].push(uint(msg.sender), PREV); 

        if (tmsg.side) {
            tmsg.balance -= tmsg.tradeAmount;
            Ask (tmsg.price, tmsg.tradeAmount, msg.sender);
        } else {
            tmsg.etherBalance -= tmsg.tradeAmount * tmsg.price;
            Bid (tmsg.price, tmsg.tradeAmount, msg.sender);
        }
    }

    function cancelIntl(TradeMessage tmsg) internal {
        uint amount = amounts[sha3(tmsg.price, msg.sender)];
        if (amount == 0) return;
        if (tmsg.price > spread(BID)) tmsg.balance += amount; // was ask
        else tmsg.etherBalance += tmsg.price * amount; // was bid
        closeOrder(tmsg.price, msg.sender);
    }

    function closeOrder(uint _price, address _trader) internal {
        orderFIFOs[_price].remove(uint(_trader));
        if (!orderFIFOs[_price].exists())  {
            priceBook.remove(_price);
        }
        delete amounts[sha3(_price, _trader)];
    }
}