pragma solidity ^0.4.13;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

interface AssetInterface {
    /*
     * Implements ERC 20 standard.
     * https://github.com/ethereum/EIPs/blob/f90864a3d2b2b45c4decf95efd26b3f0c276051a/EIPS/eip-20-token-standard.md
     * https://github.com/ethereum/EIPs/issues/20
     *
     *  Added support for the ERC 223 "tokenFallback" method in a "transfer" function with a payload.
     *  https://github.com/ethereum/EIPs/issues/223
     */

    // Events
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    // There is no ERC223 compatible Transfer event, with `_data` included.

    //ERC 223
    // PUBLIC METHODS
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);

    // ERC 20
    // PUBLIC METHODS
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    // PUBLIC VIEW METHODS
    function balanceOf(address _owner) view public returns (uint balance);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
}

interface ERC223Interface {
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value) returns (bool);
    function transfer(address to, uint value, bytes data) returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

contract Asset is DSMath, AssetInterface, ERC223Interface {

    // DATA STRUCTURES

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;

    // PUBLIC METHODS

    /**
     * @notice Send `_value` tokens to `_to` from `msg.sender`
     * @dev Transfers sender's tokens to a given address
     * @dev Similar to transfer(address, uint, bytes), but without _data parameter
     * @param _to Address of token receiver
     * @param _value Number of tokens to transfer
     * @return Returns success of function call
     */
    function transfer(address _to, uint _value)
        public
        returns (bool success)
    {
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly.
            codeLength := extcodesize(_to)
        }
 
        require(balances[msg.sender] >= _value); // sanity checks
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
        // if (codeLength > 0) {
        //     ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        //     receiver.tokenFallback(msg.sender, _value, empty);
        // }
        Transfer(msg.sender, _to, _value, empty);
        return true;
    }

    /**
     * @notice Send `_value` tokens to `_to` from `msg.sender` and trigger tokenFallback if sender is a contract
     * @dev Function that is called when a user or contract wants to transfer funds
     * @param _to Address of token receiver
     * @param _value Number of tokens to transfer
     * @param _data Data to be sent to tokenFallback
     * @return Returns success of function call
     */
    function transfer(address _to, uint _value, bytes _data)
        public
        returns (bool success)
    {
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly.
            codeLength := extcodesize(_to)
        }

        require(balances[msg.sender] >= _value); // sanity checks
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
        // if (codeLength > 0) {
        //     ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        //     receiver.tokenFallback(msg.sender, _value, _data);
        // }
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Transfer `_value` tokens from `_from` to `_to` if `msg.sender` is allowed.
    /// @notice Restriction: An account can only use this function to send to itself
    /// @dev Allows for an approved third party to transfer tokens from one
    /// address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        // require(_to == msg.sender); // can only use transferFrom to send to self

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Allows `_spender` to transfer `_value` tokens from `msg.sender` to any address.
    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    /// @return Returns success of function call.
    function approve(address _spender, uint _value) public returns (bool) {
        require(_spender != 0x0);

        // To change the approve amount you first have to reduce the addresses`
        // allowance to zero by calling `approve(_spender, 0)` if it is not
        // already 0 to mitigate the race condition described here:
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        // require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // PUBLIC VIEW METHODS

    /// @dev Returns number of allowed tokens that a spender can transfer on
    /// behalf of a token owner.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    /// @return Returns remaining allowance for spender.
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint)
    {
        return allowed[_owner][_spender];
    }

    /// @dev Returns number of tokens owned by the given address.
    /// @param _owner Address of token owner.
    /// @return Returns balance of owner.
    function balanceOf(address _owner) constant public returns (uint) {
        return balances[_owner];
    }

}

interface ERC223ReceivingContract {

    /// @dev Function that is called when a user or another contract wants to transfer funds.
    /// @param _from Transaction initiator, analogue of msg.sender
    /// @param _value Number of tokens to transfer.
    /// @param _data Data containing a function signature and/or parameters
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

contract SimpleAdapter {

    // CONSTANT FIELDS

    bool public constant approveOnly = false; // If the exchange implementation requires asset approve instead of transfer on make orders

    // EVENTS

    event OrderUpdated(uint id);

    // VIEW METHODS

    function isApproveOnly()
        constant
        returns (bool)
    {
        return approveOnly;
    }

    function getLastOrderId(address onExchange)
        constant
        returns (uint)
    {
        return SimpleMarket(onExchange).last_offer_id();
    }

    function isActive(address onExchange, uint id)
        constant
        returns (bool)
    {
        return SimpleMarket(onExchange).isActive(id);
    }

    function getOwner(address onExchange, uint id)
        constant
        returns (address)
    {
        return SimpleMarket(onExchange).getOwner(id);
    }

    function getOrder(address onExchange, uint id)
        constant
        returns (address, address, uint, uint)
    {
        var (
            sellQuantity,
            sellAsset,
            buyQuantity,
            buyAsset
        ) = SimpleMarket(onExchange).getOffer(id);
        return (
            address(sellAsset),
            address(buyAsset),
            sellQuantity,
            buyQuantity
        );
    }

    function getTimestamp(address onExchange, uint id)
        constant
        returns (uint)
    {
        var (, , , , , , timestamp) = SimpleMarket(onExchange).offers(id);
        return timestamp;
    }

    // NON-CONSTANT METHODS

    /// @notice Makes an order on the given exchange
    /// @dev Only use this in context of a delegatecall, as spending of sellAsset need to be approved first
    /// @param onExchange Address of the exchange
    /// @param sellAsset Asset (as registered in Asset registrar) to be sold
    /// @param buyAsset Asset (as registered in Asset registrar) to be bought
    /// @param sellQuantity Quantity of sellAsset to be sold
    /// @param buyQuantity Quantity of buyAsset to be bought
    /// @return id Order ID
    function makeOrder(
        address onExchange,
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    )
        returns (uint id)
    {
        id = SimpleMarket(onExchange).offer(
            sellQuantity,
            Asset(sellAsset),
            buyQuantity,
            Asset(buyAsset)
        );
        OrderUpdated(id);
    }

    /// @notice Takes an order on the given exchange
    /// @dev For this subset of adapter no immediate settlement can be expected
    /// @param onExchange Address of the exchange
    /// @param id Order id
    /// @param quantity Quantity of order to be executed (For partial taking)
    /// @return success Whether the takeOrder is successfully executed
    function takeOrder(
        address onExchange,
        uint id,
        uint quantity
    )
        returns (bool success)
    {
        success = SimpleMarket(onExchange).buy(id, quantity);
        OrderUpdated(id);
    }

    /// @notice Cancels an order on the given exchange
    /// @dev Only use this in context of a delegatecall, as spending of sellAsset need to be approved first
    /// @param onExchange Address of the exchange
    /// @param id Order id
    /// @return success Whether the order is successfully cancelled
    function cancelOrder(
        address onExchange,
        uint id
    )
        returns (bool success)
    {
        success = SimpleMarket(onExchange).cancel(id);
        OrderUpdated(id);
    }
}

contract EventfulMarket {
    event LogItemUpdate(uint id);
    event LogTrade(uint pay_amt, address indexed pay_gem,
                   uint buy_amt, address indexed buy_gem);

    event LogMake(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        Asset             pay_gem,
        Asset             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );

    event LogBump(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        Asset             pay_gem,
        Asset             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );

    event LogTake(
        bytes32           id,
        bytes32  indexed  pair,
        address  indexed  maker,
        Asset             pay_gem,
        Asset             buy_gem,
        address  indexed  taker,
        uint128           take_amt,
        uint128           give_amt,
        uint64            timestamp
    );

    event LogKill(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        Asset             pay_gem,
        Asset             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );
}

contract SimpleMarket is EventfulMarket, DSMath {

    uint public last_offer_id;

    mapping (uint => OfferInfo) public offers;

    bool locked;

    struct OfferInfo {
        uint     pay_amt;
        Asset    pay_gem;
        uint     buy_amt;
        Asset    buy_gem;
        address  owner;
        bool     active;
        uint64   timestamp;
    }

    modifier can_buy(uint id) {
        require(isActive(id));
        _;
    }

    modifier can_cancel(uint id) {
        require(isActive(id));
        require(getOwner(id) == msg.sender);
        _;
    }

    modifier can_offer {
        _;
    }

    modifier synchronized {
        assert(!locked);
        locked = true;
        _;
        locked = false;
    }

    function isActive(uint id) constant returns (bool active) {
        return offers[id].active;
    }

    function getOwner(uint id) constant returns (address owner) {
        return offers[id].owner;
    }

    function getOffer(uint id) constant returns (uint, Asset, uint, Asset) {
      var offer = offers[id];
      return (offer.pay_amt, offer.pay_gem,
              offer.buy_amt, offer.buy_gem);
    }

    // ---- Public entrypoints ---- //

    function bump(bytes32 id_)
        can_buy(uint256(id_))
    {
        var id = uint256(id_);
        LogBump(
            id_,
            keccak256(offers[id].pay_gem, offers[id].buy_gem),
            offers[id].owner,
            offers[id].pay_gem,
            offers[id].buy_gem,
            uint128(offers[id].pay_amt),
            uint128(offers[id].buy_amt),
            offers[id].timestamp
        );
    }

    // Accept given `quantity` of an offer. Transfers funds from caller to
    // offer maker, and from market to caller.
    function buy(uint id, uint quantity)
        can_buy(id)
        synchronized
        returns (bool)
    {
        OfferInfo memory offer = offers[id];
        uint spend = mul(quantity, offer.buy_amt) / offer.pay_amt;

        require(uint128(spend) == spend);
        require(uint128(quantity) == quantity);

        // For backwards semantic compatibility.
        if (quantity == 0 || spend == 0 ||
            quantity > offer.pay_amt || spend > offer.buy_amt)
        {
            return false;
        }

        offers[id].pay_amt = sub(offer.pay_amt, quantity);
        offers[id].buy_amt = sub(offer.buy_amt, spend);
        assert( offer.buy_gem.transferFrom(msg.sender, this, spend) );
        assert( offer.buy_gem.transfer(offer.owner, spend) );
        assert( offer.pay_gem.transfer(msg.sender, quantity) );

        LogItemUpdate(id);
        LogTake(
            bytes32(id),
            keccak256(offer.pay_gem, offer.buy_gem),
            offer.owner,
            offer.pay_gem,
            offer.buy_gem,
            msg.sender,
            uint128(quantity),
            uint128(spend),
            uint64(now)
        );
        LogTrade(quantity, offer.pay_gem, spend, offer.buy_gem);

        if (offers[id].pay_amt == 0) {
            delete offers[id];
        }

        return true;
    }

    // Cancel an offer. Refunds offer maker.
    function cancel(uint id)
        can_cancel(id)
        synchronized
        returns (bool success)
    {
        // read-only offer. Modify an offer by directly accessing offers[id]
        OfferInfo memory offer = offers[id];
        delete offers[id];

        assert( offer.pay_gem.transfer(offer.owner, offer.pay_amt) );

        LogItemUpdate(id);
        LogKill(
            bytes32(id),
            keccak256(offer.pay_gem, offer.buy_gem),
            offer.owner,
            offer.pay_gem,
            offer.buy_gem,
            uint128(offer.pay_amt),
            uint128(offer.buy_amt),
            uint64(now)
        );

        success = true;
    }

    function kill(bytes32 id) {
        assert(cancel(uint256(id)));
    }

    function make(
        Asset    pay_gem,
        Asset    buy_gem,
        uint128  pay_amt,
        uint128  buy_amt
    ) returns (bytes32 id) {
        return bytes32(offer(pay_amt, pay_gem, buy_amt, buy_gem));
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function offer(uint pay_amt, Asset pay_gem, uint buy_amt, Asset buy_gem)
        can_offer
        synchronized
        returns (uint id)
    {
        require(uint128(pay_amt) == pay_amt);
        require(uint128(buy_amt) == buy_amt);
        require(pay_amt > 0);
        require(pay_gem != Asset(0x0));
        require(buy_amt > 0);
        require(buy_gem != Asset(0x0));
        require(pay_gem != buy_gem);

        OfferInfo memory info;
        info.pay_amt = pay_amt;
        info.pay_gem = pay_gem;
        info.buy_amt = buy_amt;
        info.buy_gem = buy_gem;
        info.owner = msg.sender;
        info.active = true;
        info.timestamp = uint64(now);
        id = _next_id();
        offers[id] = info;

        assert( pay_gem.transferFrom(msg.sender, this, pay_amt) );

        LogItemUpdate(id);
        LogMake(
            bytes32(id),
            keccak256(pay_gem, buy_gem),
            msg.sender,
            pay_gem,
            buy_gem,
            uint128(pay_amt),
            uint128(buy_amt),
            uint64(now)
        );
    }

    function take(bytes32 id, uint128 maxTakeAmount) {
        assert(buy(uint256(id), maxTakeAmount));
    }

    function _next_id() internal returns (uint) {
        last_offer_id++; return last_offer_id;
    }

    function tokenFallback(address ofSender, uint tokenAmount, bytes metadata) {
        return;
    }
}