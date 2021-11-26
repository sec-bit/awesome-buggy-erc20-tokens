pragma solidity ^0.4.18;

// File: contracts/ERC721.sol

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
}

// File: contracts/TulipsSaleInterface.sol

/*
* @title Crypto Tulips Initial Sale Interface
* @dev This interface sets the standard for initial sale
* contract. All future sale contracts should follow this.
*/
interface TulipsSaleInterface {
    function putOnInitialSale(uint256 tulipId) external;

    function createAuction(
        uint256 _tulipId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _transferFrom
    )external;
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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

// File: contracts/TulipsRoles.sol

/*
* @title Crypto Tulips SaleAuction
* @dev .
*/
contract TulipsRoles is Pausable {

    modifier onlyFinancial() {
        require(msg.sender == address(financialAccount));
        _;
    }

    modifier onlyOperations() {
        require(msg.sender == address(operationsAccount));
        _;
    }

    function TulipsRoles() Ownable() public {
        financialAccount = msg.sender;
        operationsAccount = msg.sender;
    }

    address public financialAccount;
    address public operationsAccount;

    function transferFinancial(address newFinancial) public onlyOwner {
        require(newFinancial != address(0));
        financialAccount = newFinancial;
    }

    function transferOperations(address newOperations) public onlyOwner {
        require(newOperations != address(0));
        operationsAccount = newOperations;
    }

}

// File: contracts/TulipsSaleAuction.sol

/*
* @title Crypto Tulips SaleAuction
* @dev .
*/
contract TulipsSaleAuction is TulipsRoles, TulipsSaleInterface {

    modifier onlyCoreContract() {
        require(msg.sender == address(coreContract));
        _;
    }

    struct Auction {
        address seller;
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        uint64 startedAt;
    }

    // @dev core contract cannot change due to security reasons
    ERC721 public coreContract;

    // Commission cut
    uint256 public ownerCut;

    uint256 public initialStartPrice;
    uint256 public initialEndPrice;
    uint256 public initialSaleDuration = 1 days;

    // Map from token ID to their corresponding auction.
    mapping (uint256 => Auction) public tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    /*
    * @dev Constructor initialized with the reference to core Tulips contract
    * @param _tulipsCoreContract - core contract adress should be fixed
    * @param _cut - core contract adress should be fixed
    */
    function TulipsSaleAuction(address _tulipsCoreContract, uint256 _cut) TulipsRoles() public {
        require(_cut <= 10000); // cut as percentage between 0.00-100.00%
        ownerCut = _cut;

        coreContract = ERC721(_tulipsCoreContract);
    }
     /*
    * @dev These are auction prices for initial tulip sales.
    */
    function setDefaultAuctionPrices(uint256 _startPrice, uint256 _endPrice) external onlyFinancial {
        initialStartPrice = _startPrice;
        initialEndPrice = _endPrice;
    }

    function recievePayout(uint payoutAmount, address payoutAddress) external onlyFinancial {
        require(payoutAddress != 0);
        payoutAddress.transfer(payoutAmount);
    }

    /*
    * @dev This function is called from core Contract to put tulip on initial sale.
    * This is a privilaged version that, recieves request from corecontract.
    * Core contract ensures that this contract already is the ownerof this tulip
    */
    function putOnInitialSale(uint256 _tulipId) external onlyCoreContract {
        // !! Core contract must ensure the ownership
        _createAuction(_tulipId, initialStartPrice, initialEndPrice, initialSaleDuration, this);
    }

    function createAuction(
        uint256 _tulipId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _transferFrom
    )external
    {
        // Avoid input overflowing struct memory sizes
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        // Make sure we have at least a minute for this auction
        require(_duration >= 1 minutes);

        require(coreContract.ownerOf(_tulipId) == _transferFrom);

        // Transfer from checks whether the owner approved this transfer so
        // we can't transfer tulips without permission
        coreContract.transferFrom(_transferFrom, this, _tulipId);

        _createAuction(_tulipId, _startingPrice, _endingPrice, _duration, _transferFrom);
    }



    /// @param _tulipId - Id of the tulip to auction.
    /// @param _startingPrice - Starting price in wei.
    /// @param _endingPrice - Ending price in wei.
    /// @param _duration - Duration in seconds.
    /// @param _seller - Seller address
    function _createAuction(
        uint256 _tulipId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        internal
    {

        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );

        tokenIdToAuction[_tulipId] = auction;

        AuctionCreated(
            uint256(_tulipId),
            uint256(auction.startingPrice),
            uint256(auction.endingPrice),
            uint256(auction.duration)
        );
    }


    /*
    * @dev Cancel auction and return tulip to original owner.
    * @param _tulipId - ID of the tulip on auction
    */
    function cancelAuction(uint256 _tulipId)
        external
    {
        Auction storage auction = tokenIdToAuction[_tulipId];
        require(auction.startedAt > 0);

        // Only seller can call this function
        address seller = auction.seller;
        require(msg.sender == seller);

        // Return the tulip to the owner
        coreContract.transfer(seller, _tulipId);

        // Remove auction from storage
        delete tokenIdToAuction[_tulipId];

        AuctionCancelled(_tulipId);
    }

    function buy(uint256 _tulipId)
        external
        payable
        whenNotPaused
    {
        Auction storage auction = tokenIdToAuction[_tulipId];

        require(auction.startedAt > 0);

        uint256 price = _currentPrice(auction);
        require(msg.value >= price);

        address seller = auction.seller;

        delete tokenIdToAuction[_tulipId];

        // We don't calculate auctioneers if the seller is us.
        if (price > 0 && seller != address(this)) {
            // Calculate the auctioneer's cut.
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerGains = price - auctioneerCut;

            seller.transfer(sellerGains);
        }

        uint256 bidExcess = msg.value - price;

        msg.sender.transfer(bidExcess);

        coreContract.transfer(msg.sender, _tulipId);

        AuctionSuccessful(_tulipId, price, msg.sender);
    }

    function secondsPassed(uint256 _tulipId )external view
       returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tulipId];

        uint256 secondsPassed = 0;

        if (now > auction.startedAt) {
            secondsPassed = now - auction.startedAt;
        }

        return secondsPassed;
    }

    function currentPrice(uint256 _tulipId) external view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tulipId];

        require(auction.startedAt > 0);

        return _currentPrice(auction);
    }

    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }

}