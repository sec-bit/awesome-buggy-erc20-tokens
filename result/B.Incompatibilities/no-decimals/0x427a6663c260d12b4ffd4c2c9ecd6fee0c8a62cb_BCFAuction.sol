pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;

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
        owner = newOwner;
  }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
    * @dev modifier to allow actions only when the contract IS paused
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev modifier to allow actions only when the contract IS NOT paused
    */
    modifier whenPaused {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        Pause();
        return true;
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}

contract ERC721 {

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Required
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint _tokenId) public view returns (address approved);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function implementsERC721() public pure returns (bool);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

contract BCFAuction is Pausable {

    struct CardAuction {
        address seller;
        uint128 startPrice; // in wei
        uint128 endPrice;
        uint64 duration;
        uint64 startedAt;
    }

    // To lookup owners 
    ERC721 public dataStore;
    uint256 public auctioneerCut;

    mapping (uint256 => CardAuction) playerCardIdToAuction;

    event AuctionCreated(uint256 cardId, uint256 startPrice, uint256 endPrice, uint256 duration);
    event AuctionSuccessful(uint256 cardId, uint256 finalPrice, address winner);
    event AuctionCancelled(uint256 cardId);

    function BCFAuction(address dataStoreAddress, uint cutValue) public {
        require(cutValue <= 10000); // 100% == 10,000
        auctioneerCut = cutValue;

        ERC721 candidateDataStoreContract = ERC721(dataStoreAddress);
        require(candidateDataStoreContract.implementsERC721());
        dataStore = candidateDataStoreContract;
    }

    function withdrawBalance() external {
        address storageAddress = address(dataStore);
        require(msg.sender == owner || msg.sender == storageAddress);
        storageAddress.transfer(this.balance);
    }

    function createAuction(
        uint256 cardId, 
        uint256 startPrice, 
        uint256 endPrice, 
        uint256 duration, 
        address seller
    )
        external
        whenNotPaused
    {
        require(startPrice == uint256(uint128(startPrice)));
        require(endPrice == uint256(uint128(endPrice)));
        require(duration == uint256(uint64(duration)));
        require(seller != address(0));
        require(address(dataStore) != address(0));
        require(msg.sender == address(dataStore));

        _escrow(seller, cardId);
        CardAuction memory auction = CardAuction(
            seller,
            uint128(startPrice),
            uint128(endPrice),
            uint64(duration),
            uint64(now)
        );
        _addAuction(cardId, auction);
    }

    function bid(uint256 cardId) external payable whenNotPaused {
        _bid(cardId, msg.value); // This function handles validation and throws
        _transfer(msg.sender, cardId);
    }

    function cancelAuction(uint256 cardId) external {
        CardAuction storage auction = playerCardIdToAuction[cardId];
        require(isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(cardId, seller);
    }

    function getAuction(uint256 cardId) external view returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        CardAuction storage auction = playerCardIdToAuction[cardId];
        require(isOnAuction(auction));
        return (auction.seller, auction.startPrice, auction.endPrice, auction.duration, auction.startedAt);
    }

    function getCurrentPrice(uint256 cardId) external view returns (uint256) {
        CardAuction storage auction = playerCardIdToAuction[cardId];
        require(isOnAuction(auction));
        return currentPrice(auction);
    }

    // Internal utility functions
    function ownsPlayerCard(address cardOwner, uint256 cardId) internal view returns (bool) {
        return (dataStore.ownerOf(cardId) == cardOwner);
    }

    function _escrow(address owner, uint256 cardId) internal {
        dataStore.transferFrom(owner, this, cardId);
    }

    function _transfer(address receiver, uint256 cardId) internal {
        dataStore.transfer(receiver, cardId);
    }

    function _addAuction(uint256 cardId, CardAuction auction) internal {
        require(auction.duration >= 1 minutes && auction.duration <= 14 days);
        playerCardIdToAuction[cardId] = auction;
        AuctionCreated(cardId, auction.startPrice, auction.endPrice, auction.duration);
    }

    function _removeAuction(uint256 cardId) internal {
        delete playerCardIdToAuction[cardId];
    }

    function _cancelAuction(uint256 cardId, address seller) internal {
        _removeAuction(cardId);
        _transfer(seller, cardId);
        AuctionCancelled(cardId);
    }

    function isOnAuction(CardAuction storage auction) internal view returns (bool) {
        return (auction.startedAt > 0);
    }

    function _bid(uint256 cardId, uint256 bidAmount) internal returns (uint256) {
        CardAuction storage auction = playerCardIdToAuction[cardId];
        require(isOnAuction(auction));

        uint256 price = currentPrice(auction);
        require(bidAmount >= price);

        address seller = auction.seller;
        _removeAuction(cardId);

        if (price > 0) {
            uint256 handlerCut = calculateAuctioneerCut(price);
            uint256 sellerProceeds = price - handlerCut;
            seller.transfer(sellerProceeds);
        } 

        uint256 bidExcess = bidAmount - price;
        msg.sender.transfer(bidExcess);

        AuctionSuccessful(cardId, price, msg.sender); // Emit event/log

        return price;
    }

    function currentPrice(CardAuction storage auction) internal view returns (uint256) {
        uint256 secondsPassed = 0;
        if (now > auction.startedAt) {
            secondsPassed = now - auction.startedAt;
        }

        return calculateCurrentPrice(auction.startPrice, auction.endPrice, auction.duration, secondsPassed);
    }

    function calculateCurrentPrice(uint256 startPrice, uint256 endPrice, uint256 duration, uint256 secondsElapsed)
        internal
        pure
        returns (uint256)
    {
        if (secondsElapsed >= duration) {
            return endPrice;
        } 

        int256 totalPriceChange = int256(endPrice) - int256(startPrice);
        int256 currentPriceChange = totalPriceChange * int256(secondsElapsed) / int256(duration);
        int256 _currentPrice = int256(startPrice) + currentPriceChange;

        return uint256(_currentPrice);
    }

    function calculateAuctioneerCut(uint256 sellPrice) internal view returns (uint256) {
        // 10,000 = 100%, ownerCut required'd <= 10,000 in the constructor so no requirement to validate here
        uint finalCut = sellPrice * auctioneerCut / 10000;
        return finalCut;
    }    
}