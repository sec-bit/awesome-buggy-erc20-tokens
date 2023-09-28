/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
pragma solidity 0.4.15;


/// @title Abstract token contract - Functions to be implemented by token contracts.
contract Token {
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);

    // This is not an abstract function, because solc won't recognize generated getter functions for public variables as functions.
    //function totalSupply() constant returns (uint256 supply) {};
    function balanceOf(address owner) constant returns (uint256 balance);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DutchAuction {

    /*
     *  Events
     */
    event BidSubmission(address indexed sender, uint256 amount);

    /*
     *  Constants
     */
    uint constant public MAX_TOKENS_SOLD = 5000000 * 10**18; // 5M
    uint constant public WAITING_PERIOD = 7 days;

    /*
     *  Storage
     */
    Token public virtuePlayerPoints;
    address public wallet;
    address public owner;
    uint public ceiling;
    uint public priceFactor;
    uint public startBlock;
    uint public endTime;
    uint public totalReceived;
    uint public finalPrice;
    mapping (address => uint) public bids;
    Stages public stage;
    
    // Bidder whitelist. Entries in the array are whitelisted addresses
    // Entries in the address-keyed map represent the (array_index+1) of
    // the key. 
    
    address[] public bidderWhitelist; // allows iteration over whitelisted addresses
    mapping (address => uint ) public whitelistIndexMap;  // allows fast address lookup

    /*
     *  Enums
     */
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TradingStarted
    }

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        require (stage == _stage);
            // Contract must be in expected state
        _;
    }

    modifier isOwner() {
        require (msg.sender == owner);
            // Only owner is allowed to proceed
        _;
    }

    modifier isWallet() {
        require (msg.sender == wallet);
            // Only wallet is allowed to proceed
        _;
    }

    modifier isValidPayload() {
        require (msg.data.length == 4 || msg.data.length == 36);
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stages.AuctionEnded && now > endTime + WAITING_PERIOD)
            stage = Stages.TradingStarted;
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Contract constructor function sets owner.
    /// @param _wallet Multisig wallet for auction proceeds.
    /// @param _ceiling Auction ceiling.
    /// @param _priceFactor Auction price factor.
    function DutchAuction(address _wallet, uint _ceiling, uint _priceFactor)
        public
    {
        require (_wallet != 0);
        require (_ceiling != 0);
        require (_priceFactor != 0);
            // Arguments cannot be null.
        owner = msg.sender;
        wallet = _wallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        stage = Stages.AuctionDeployed;
    }

    /// @dev Setup function sets external contracts' addresses.
    /// @param _virtuePlayerPoints token contract address.
    function setup(address _virtuePlayerPoints)
        public
        isOwner
        atStage(Stages.AuctionDeployed)
    {
        require (_virtuePlayerPoints != 0);
            // Argument cannot be null.
        virtuePlayerPoints = Token(_virtuePlayerPoints);
        // Validate token balance
        require (virtuePlayerPoints.balanceOf(this) == MAX_TOKENS_SOLD);

        stage = Stages.AuctionSetUp;
    }


    /// @dev Add bidder address to whitelist
    /// @param _bidderAddr Bidder Eth address
    function addToWhitelist(address _bidderAddr)
        public
        isOwner
        atStage(Stages.AuctionSetUp)
    {
        require(_bidderAddr != 0);
        if (whitelistIndexMap[_bidderAddr] == 0)
        {
            uint idxPlusOne = bidderWhitelist.push(_bidderAddr);
            whitelistIndexMap[_bidderAddr] = idxPlusOne; 
        }
    }

    /// @dev Add multiple bidder addresses to whitelist
    /// @param _bidderAddrs Array of Bidder Eth addresses
    function addArrayToWhitelist(address[] _bidderAddrs)
        public
        isOwner
        atStage(Stages.AuctionSetUp)
    {
        require(_bidderAddrs.length != 0);
        for(uint idx = 0; idx<_bidderAddrs.length; idx++) {
            addToWhitelist(_bidderAddrs[idx]);
        }
    }

    /// @dev Remove bidder address from whitelist
    /// @param _bidderAddr Bidder Eth address
    function removeFromWhitelist(address _bidderAddr)
        public
        isOwner
        atStage(Stages.AuctionSetUp)       
    {
        require(_bidderAddr != 0);
        require( whitelistIndexMap[_bidderAddr] != 0); // throw if not in map             
        uint idx = whitelistIndexMap[_bidderAddr] - 1;
        bidderWhitelist[idx] = 0;
        whitelistIndexMap[_bidderAddr] = 0;
    }
    
    /// @dev Is this addres in the whitelist?
    /// @param _addr Bidder Eth address    
    function isInWhitelist(address _addr)
        public
        constant
        returns(bool)
    {
        return (whitelistIndexMap[_addr] != 0);
    }
    
    /// @dev Number of non-zero entries in whitelist
    /// @return number of non-zero entries
    function whitelistCount()
        public
        constant
        returns (uint)        
    {
        uint count = 0;
        for (uint i = 0; i< bidderWhitelist.length; i++) {
            if (bidderWhitelist[i] != 0)
                count++;
        }
        return count;
    }
    
    /// @dev Fetch entries in whitelist
    /// @param _startIdx starting index
    /// @param _count number to fetch. zero for all.
    /// @return array of non-zero entries
    /// Note: because there can be null entries in the bidderWhitelist array,
    /// indices used in this call are not the same as those in bidderwhiteList
    function whitelistEntries(uint _startIdx, uint _count)
        public
        constant
        returns (address[])        
    {
        uint addrCount = whitelistCount();
        if (_count == 0)
            _count = addrCount; 
        if (_startIdx >= addrCount) {
            _startIdx = 0;
            _count = 0;
        } else if (_startIdx + _count > addrCount) {
            _count = addrCount - _startIdx;        
        }

        address[] memory results = new address[](_count);
        // skip to startIdx
        uint dynArrayIdx = 0; 
        while (_startIdx > 0) {
            if (bidderWhitelist[dynArrayIdx++] != 0)
                _startIdx--;  
        }   
        // copy into results
        uint resultsIdx = 0; 
        while (resultsIdx < _count) {
            address addr = bidderWhitelist[dynArrayIdx++];
            if (addr != 0)
                results[resultsIdx++] = addr;      
        }
        return results;    
    }    
    
    /// @dev Starts auction and sets startBlock.
    function startAuction()
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        stage = Stages.AuctionStarted;
        startBlock = block.number;
    }

    /// @dev Changes auction ceiling and start price factor before auction is started.
    /// @param _ceiling Updated auction ceiling.
    /// @param _priceFactor Updated start price factor.
    function changeSettings(uint _ceiling, uint _priceFactor)
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        ceiling = _ceiling;
        priceFactor = _priceFactor;
    }

    /// @dev Calculates current token price.
    /// @return Returns token price.
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint)
    {
        if (stage == Stages.AuctionEnded || stage == Stages.TradingStarted)
            return finalPrice;
        return calcTokenPrice();
    }

    /// @dev Returns correct stage, even if a function with timedTransitions modifier has not yet been called yet.
    /// @return Returns current auction stage.
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }

    /// @dev Allows to send a bid to the auction.
    /// @param receiver Bid will be assigned to this address if set.
    function bid(address receiver)
        public
        payable
        isValidPayload
        timedTransitions
        atStage(Stages.AuctionStarted)
        returns (uint amount)
    {
        // If a bid is done on behalf of a user via ShapeShift, the receiver address is set.
        if (receiver == 0)
            receiver = msg.sender;

        require(isInWhitelist(receiver));         
            
        amount = msg.value;
        // Prevent that more than 90% of tokens are sold. Only relevant if cap not reached.
        uint maxWei = (MAX_TOKENS_SOLD / 10**18) * calcTokenPrice() - totalReceived;
        uint maxWeiBasedOnTotalReceived = ceiling - totalReceived;
        if (maxWeiBasedOnTotalReceived < maxWei)
            maxWei = maxWeiBasedOnTotalReceived;
        // Only invest maximum possible amount.
        if (amount > maxWei) {
            amount = maxWei;
            // Send change back to receiver address. In case of a ShapeShift bid the user receives the change back directly.
            receiver.transfer(msg.value - amount); // throws on failure
        }
        // Forward funding to ether wallet
        require (amount != 0);
        wallet.transfer(amount); // throws on failure
        bids[receiver] += amount;
        totalReceived += amount;
        if (maxWei == amount)
            // When maxWei is equal to the big amount the auction is ended and finalizeAuction is triggered.
            finalizeAuction();
        BidSubmission(receiver, amount);
    }

    /// @dev Claims tokens for bidder after auction.
    /// @param receiver Tokens will be assigned to this address if set.
    function claimTokens(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stages.TradingStarted)
    {
        if (receiver == 0)
            receiver = msg.sender;
        uint tokenCount = bids[receiver] * 10**18 / finalPrice;
        bids[receiver] = 0;
        virtuePlayerPoints.transfer(receiver, tokenCount);
    }

    /// @dev Calculates stop price.
    /// @return Returns stop price.
    function calcStopPrice()
        constant
        public
        returns (uint)
    {
        return totalReceived * 10**18 / MAX_TOKENS_SOLD + 1;
    }

    /// @dev Calculates token price.
    /// @return Returns token price.
    function calcTokenPrice()
        constant
        public
        returns (uint)
    {
        return priceFactor * 10**18 / (block.number - startBlock + 8000) + 1;
    }

    /*
     *  Private functions
     */
    function finalizeAuction()
        private
    {
        stage = Stages.AuctionEnded;
        if (totalReceived == ceiling)
            finalPrice = calcTokenPrice();
        else
            finalPrice = calcStopPrice();
        uint soldTokens = totalReceived * 10**18 / finalPrice;
        // Auction contract transfers all unsold tokens to multisig wallet
        virtuePlayerPoints.transfer(wallet, MAX_TOKENS_SOLD - soldTokens);
        endTime = now;
    }
}