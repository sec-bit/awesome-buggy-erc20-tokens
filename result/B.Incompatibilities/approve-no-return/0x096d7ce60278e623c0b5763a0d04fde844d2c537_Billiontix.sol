pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
 
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
   
  function transferOwnership(address newOwner) onlyOwner public{
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}




/**
 * Interface for required functionality in the ERC721 standard
 * for non-fungible tokens.
 * Borrowed from Token Standard discussion board
 *
 * 
 */
 
contract ERC721 {
    // Function
    function totalSupply() public view returns (uint256 _totalSupply);
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint _tokenId) public view returns (address _owner);
    function transfer(address _to, uint _tokenId) internal;
    function implementsERC721() public view returns (bool _implementsERC721);

  
    function approve(address _to, uint _tokenId) internal;
    function transferFrom(address _from, address _to, uint _tokenId) internal;

   
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

/**
 * Interface for optional functionality in the ERC721 standard
 * for non-fungible tokens.
 *
 *  
 * Borrowed in part from Token Standard discussion board
 */
 
contract DetailedERC721 is ERC721 {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
   // function tokenMetadata(uint _tokenId) public view returns (string _infoUrl);
    function tokenOfOwnerByIndex(address _owner, uint _index) public view returns (uint _tokenId);
}

/**
 * @title NonFungibleToken
 *
 * Generic implementation for both required and optional functionality in
 * the ERC721 standard for non-fungible tokens.
 *
 * Borrowed in part from Token Standard discussion board
 */
 
contract NonFungibleToken is DetailedERC721 {
    string public name;
    string public symbol;

    uint public numTokensTotal;
    uint public currentTokenIdNumber;

    mapping(uint => address) internal tokenIdToOwner;
    mapping(uint => address) internal tokenIdNumber;
    mapping(uint => address) internal tokenIdToApprovedAddress;
   // mapping(uint => string) internal tokenIdToMetadata;
    mapping(address => uint[]) internal ownerToTokensOwned;
    mapping(uint => uint) internal tokenIdToOwnerArrayIndex;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
    );

    modifier onlyExtantToken(uint _tokenId) {
        require(ownerOf(_tokenId) != address(0));
        _;
    }

    function name()
        public
        view
        returns (string _name)
    {
        return name;
    }

    function symbol()
        public
        view
        returns (string _symbol)
    {
        return symbol;
    }

    function totalSupply()
        public
        view
        returns (uint256 _totalSupply)
    {
        return numTokensTotal;
    }
    
    function currentIDnumber()
        public
        view
        returns (uint256 _tokenId)
    {
        return currentTokenIdNumber;
    }

    function balanceOf(address _owner)
        public
        view
        returns (uint _balance)
    {
        return ownerToTokensOwned[_owner].length;
    }

    function ownerOf(uint _tokenId)
        public
        view
        returns (address _owner)
    {
        return _ownerOf(_tokenId);
    }
    
   /*  NOT USED
    function tokenMetadata(uint _tokenId)
        public
        view
        returns (string _infoUrl)
    {
        return tokenIdToMetadata[_tokenId];
    }
 */
    function approve(address _to, uint _tokenId)
        internal
        onlyExtantToken(_tokenId)
    {
        require(msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);

        if (_getApproved(_tokenId) != address(0) ||
                _to != address(0)) {
            _approve(_to, _tokenId);
            Approval(msg.sender, _to, _tokenId);
        }
    }

  
    function transferFrom(address _from, address _to, uint _tokenId)
        internal
        onlyExtantToken(_tokenId)
    {
        require(getApproved(_tokenId) == msg.sender);
        require(ownerOf(_tokenId) == _from);
        require(_to != address(0));

        _clearApprovalAndTransfer(_from, _to, _tokenId);

        Approval(_from, 0, _tokenId);
        Transfer(_from, _to, _tokenId);
    }

    function auctiontransfer(address _currentowner, address _to, uint _tokenId)
        internal
        onlyExtantToken(_tokenId)
    {
        require(ownerOf(_tokenId) == _currentowner);
        require(_to != address(0));

        _clearApprovalAndTransfer(_currentowner, _to, _tokenId);

        Approval(_currentowner, 0, _tokenId);
        Transfer(_currentowner, _to, _tokenId);
    }
   

    function transfer(address _to, uint _tokenId)
        internal 
        onlyExtantToken(_tokenId)
    {
        require(ownerOf(_tokenId) == msg.sender);
        require(_to != address(0));

        _clearApprovalAndTransfer(msg.sender, _to, _tokenId);

        Approval(msg.sender, 0, _tokenId);
        Transfer(msg.sender, _to, _tokenId);
    }

    function tokenOfOwnerByIndex(address _owner, uint _index)
        public
        view
        returns (uint _tokenId)
    {
        return _getOwnerTokenByIndex(_owner, _index);
    }

    function getOwnerTokens(address _owner)
        public
        view
        returns (uint[] _tokenIds)
    {
        return _getOwnerTokens(_owner);
    }

    function implementsERC721()
        public
        view
        returns (bool _implementsERC721)
    {
        return true;
    }

    function getApproved(uint _tokenId)
        public
        view
        returns (address _approved)
    {
        return _getApproved(_tokenId);
    }

    function _clearApprovalAndTransfer(address _from, address _to, uint _tokenId)
        internal
    {
        _clearTokenApproval(_tokenId);
        _removeTokenFromOwnersList(_from, _tokenId);
        _setTokenOwner(_tokenId, _to);
        _addTokenToOwnersList(_to, _tokenId);
    }

    function _ownerOf(uint _tokenId)
        internal
        view
        returns (address _owner)
    {
        return tokenIdToOwner[_tokenId];
    }

   
    function _approve(address _to, uint _tokenId)
        internal
    {
        tokenIdToApprovedAddress[_tokenId] = _to;
    }

    function _getApproved(uint _tokenId)
        internal
        view
        returns (address _approved)
    {
        return tokenIdToApprovedAddress[_tokenId];
    }

    function _getOwnerTokens(address _owner)
        internal
        view
        returns (uint[] _tokens)
    {
        return ownerToTokensOwned[_owner];
    }

    function _getOwnerTokenByIndex(address _owner, uint _index)
        internal
        view
        returns (uint _tokens)
    {
        return ownerToTokensOwned[_owner][_index];
    }


    function _clearTokenApproval(uint _tokenId)
        internal
    {
        tokenIdToApprovedAddress[_tokenId] = address(0);
    }


    function _setTokenOwner(uint _tokenId, address _owner)
        internal
    {
        tokenIdToOwner[_tokenId] = _owner;
    }

    function _addTokenToOwnersList(address _owner, uint _tokenId)
        internal
    {
        ownerToTokensOwned[_owner].push(_tokenId);
        tokenIdToOwnerArrayIndex[_tokenId] =
            ownerToTokensOwned[_owner].length - 1;
    }

    function _removeTokenFromOwnersList(address _owner, uint _tokenId)
        internal
    {
        uint length = ownerToTokensOwned[_owner].length;
        uint index = tokenIdToOwnerArrayIndex[_tokenId];
        uint swapToken = ownerToTokensOwned[_owner][length - 1];

        ownerToTokensOwned[_owner][index] = swapToken;
        tokenIdToOwnerArrayIndex[swapToken] = index;

        delete ownerToTokensOwned[_owner][length - 1];
        ownerToTokensOwned[_owner].length--;
    }

/* Not Used
    function _insertTokenMetadata(uint _tokenId, string _metadata)
        internal
    {
        tokenIdToMetadata[_tokenId] = _metadata;
    }
   
 */  
}

/**
 * @title MintableNonFungibleToken
 *
 * Superset of the ERC721 standard that allows for the minting
 * of non-fungible tokens.
 * Borrowed from Token Standard discussion board
 */
 
contract MintableNonFungibleToken is NonFungibleToken {
    using SafeMath for uint;

    event Mint(address indexed _to, uint256 indexed _tokenId);

    modifier onlyNonexistentToken(uint _tokenId) {
        require(tokenIdToOwner[_tokenId] == address(0));
        _;
    }

    function mint(address _owner, uint256 _tokenId)
        internal
        onlyNonexistentToken(_tokenId)
    {
        _setTokenOwner(_tokenId, _owner);
        _addTokenToOwnersList(_owner, _tokenId);
        //_insertTokenMetadata(_tokenId, _metadata);

        numTokensTotal = numTokensTotal.add(1);

        Mint(_owner, _tokenId);
    }
   
    
}

/**
 * @title Auction
 *
 * BillionTix proprietary Auction 
 * of BillionTix
 * Developed Exclusively for and by BillionTix Jan 31 2018
 */
 
contract Auction is NonFungibleToken, Ownable {
            using SafeMath for uint256;

    
    struct ActiveAuctionsStruct {
    address auctionOwner;
    uint isBeingAuctioned; 
    //1=Being Auctioned 0=Not Being Auctioned
    uint startingPrice;
    uint buynowPrice;
    uint highestBid;
    uint numberofBids;
    uint auctionEnd;
    uint lastSellingPrice;
    address winningBidder;
    
  }
  
  struct ActiveAuctionsByAddressStruct {
      
      uint tixNumberforSale;
      
  }
  
 
    mapping(uint => ActiveAuctionsStruct) private activeAuctionsStructs;
    mapping(address => uint[]) private activeAuctionsByAddressStructs;

    event LiveAuctionEvent (address auctionowner, uint indexed tixNumberforSale, uint indexed startingPrice, uint indexed buynowPrice, uint auctionLength);
    event RunningAuctionsEvent (address auctionowner, uint indexed tixNumberforSale, uint indexed isBeingAuctioned, uint auctionLength);
    event SuccessAuctionEvent (address auctionowner, address auctionwinner, uint indexed tixNumberforSale, uint indexed winningPrice);
    event CanceledAuctionEvent (address auctionowner, address highestbidder, uint indexed tixNumberforSale, uint indexed highestbid);
    event BuyNowEvent (address auctionowner, address ticketbuyer, uint indexed tixNumberforSale, uint indexed purchaseprice);
    event LogBid (address auctionowner, address highestbidder, uint indexed tixNumberforSale, uint indexed highestbid, uint indexed bidnumber);
    event LogRefund (address losingbidder, uint indexed tixNumberforSale, uint indexed refundedamount);
    event CreationFailedEvent (address auctionrequestedby, uint indexed tixNumberforSale, string approvalstatus);
    event BidFailedEvent (address bidder, uint tixNumberforSale, string bidfailure);

    
    address ticketownwer;
    address public auctionleader;

    string public approval = "Auction Approved";
    string public notapproved = "You Do Not Own This Ticket or Ticket is Already For Sale";
    string public bidfailure ="Bid Failure";
   
    uint public tixNumberforSale;
    uint public leadingBid;
    uint public startingPrice;
    uint public winningPrice;
    uint public buynowPrice;
    uint public auctionLength;
    uint256 public ownerCut;
    uint256 public cancelCost;
    
    uint[] public runningauctions;
 
    function Auction() public {
        //Only called once when contract created.  Put initialization constructs here if needed
    }
    

    function createAuction (uint _startprice, uint _buynowprice, uint _tixforsale, uint _auctiontime) public  {
        
        require (_startprice >= 0);
        require (_buynowprice >= 0);
        require (_tixforsale > 0);
        require (_auctiontime > 0);
        
        address auctionowner = msg.sender;
        tixNumberforSale = _tixforsale;
        ticketownwer = ownerOf(tixNumberforSale);
        auctionLength = _auctiontime;
         
        var auctionDetails = activeAuctionsStructs[tixNumberforSale];

        uint auctionstatus = auctionDetails.isBeingAuctioned;


        if (auctionowner == ticketownwer && auctionstatus != 1) {
         
         startingPrice = _startprice;
         buynowPrice = _buynowprice;
         auctionDetails.auctionOwner = auctionowner;
         auctionDetails.startingPrice = startingPrice;
         auctionDetails.buynowPrice = buynowPrice;
         auctionDetails.highestBid = startingPrice;
         auctionDetails.isBeingAuctioned = 1;
         auctionDetails.numberofBids = 0;
         auctionDetails.auctionEnd = now + auctionLength;
         runningauctions.push(tixNumberforSale);

     
         activeAuctionsByAddressStructs[auctionowner].push(tixNumberforSale);
         LiveAuctionEvent(auctionowner, tixNumberforSale, startingPrice, buynowPrice, auctionDetails.auctionEnd);

       
        } else {
            
        CreationFailedEvent(msg.sender, tixNumberforSale, notapproved);
        revert();

        }
    
    }
   
    function placeBid(uint _tixforsale) payable public{
       

      var auctionDetails = activeAuctionsStructs[_tixforsale];
      uint auctionavailable = auctionDetails.isBeingAuctioned;
      uint leadbid = auctionDetails.highestBid;
      uint bidtotal = auctionDetails.numberofBids;
      address auctionowner = auctionDetails.auctionOwner;
      address leadingbidder = auctionDetails.winningBidder;
      uint endofauction = auctionDetails.auctionEnd;
      
      require (now <= endofauction);
      require (auctionavailable == 1);
      require (msg.value > leadbid);
      
        if (msg.value > leadbid) {
           
            auctionDetails.winningBidder = msg.sender;
            auctionDetails.highestBid = msg.value;
            auctionDetails.numberofBids++;
            uint bidnumber = auctionDetails.numberofBids;
            
             if (bidtotal > 0) {
            returnPrevBid(leadingbidder, leadbid, _tixforsale);
           }
            LogBid(auctionowner, auctionDetails.winningBidder, _tixforsale, auctionDetails.highestBid, bidnumber);
        }
        else {
            
            BidFailedEvent(msg.sender, _tixforsale, bidfailure);
            revert();
            
        }
    
    
        
    }
   
    function returnPrevBid(address _highestbidder, uint _leadbid, uint _tixnumberforsale) internal {
      
        if (_highestbidder != 0 && _leadbid > 0) {
           
            _highestbidder.transfer(_leadbid);
            
            LogRefund(_highestbidder, _tixnumberforsale, _leadbid);
        
        }
    }
    
    function setOwnerCut(uint256 _ownercut) onlyOwner public {
       
       ownerCut = _ownercut;
       
       
   }
   
   function setCostToCancel(uint256 _cancelcost) onlyOwner public {
       
       cancelCost = _cancelcost;
       
       
   }
   
    function getCostToCancel() view public returns (uint256) {
       
       return cancelCost;
       
       
   }
    

    //END AUCTION FUNCTION CAN BE CALLED AFTER AUCTION TIME IS UP BY EITHER SELLER OR WINNING PARTY
    
    function endAuction(uint _tixnumberforsale) public {
        

      var auctionDetails = activeAuctionsStructs[_tixnumberforsale];
      uint auctionEnd = auctionDetails.auctionEnd;
      address auctionowner = auctionDetails.auctionOwner;
      address auctionwinner = auctionDetails.winningBidder;
      uint256 winningBid = auctionDetails.highestBid;
      uint numberofBids = auctionDetails.numberofBids;

        require (now > auctionEnd);

       if ((msg.sender == auctionowner || msg.sender == auctionwinner) && numberofBids > 0 && winningBid > 0) {
          

           uint256 ownersCut = winningBid * ownerCut / 10000;
        
           owner.transfer(ownersCut);
           auctionowner.transfer(auctionDetails.highestBid - ownersCut);
           auctiontransfer(auctionowner, auctionwinner, _tixnumberforsale);
           auctionDetails.isBeingAuctioned = 0;
           auctionDetails.auctionEnd = 0;
           auctionDetails.numberofBids = 0;
           auctionDetails.highestBid = 0;
           auctionDetails.buynowPrice = 0;
           auctionDetails.startingPrice = 0;
           removeByValue(_tixnumberforsale);
           SuccessAuctionEvent(auctionowner, auctionwinner, _tixnumberforsale, winningBid);
           
       }
       
       if (msg.sender == auctionowner && numberofBids == 0) {
          

           auctionDetails.isBeingAuctioned = 0;
           auctionDetails.auctionEnd = 0;
           auctionDetails.numberofBids = 0;
           auctionDetails.highestBid = 0;
           auctionDetails.buynowPrice = 0;
           auctionDetails.startingPrice = 0;

           removeByValue(_tixnumberforsale);

           SuccessAuctionEvent(auctionowner, auctionwinner, _tixnumberforsale, winningBid);
           
       }
       
       
       
       
   }
   
   
  

   //CANCEL AUCTION CAN ONLY BE CALLED BY AUCTION OWNER - ALL MONEY RETURNED TO HIGHEST BIDDER. COSTS ETHER
   
   function cancelAuction(uint _tixnumberforsale) payable public {
       
            
        var auctionDetails = activeAuctionsStructs[_tixnumberforsale];
        uint auctionEnd = auctionDetails.auctionEnd;
        uint numberofBids = auctionDetails.numberofBids;

        require (now < auctionEnd);
        
        
        
         uint256 highestBid = auctionDetails.highestBid;
         address auctionwinner = auctionDetails.winningBidder;
         address auctionowner = auctionDetails.auctionOwner;
         
                if (msg.sender == auctionowner && msg.value >= cancelCost && numberofBids > 0) {

        
                        auctionwinner.transfer(highestBid);
                        LogRefund(auctionwinner, _tixnumberforsale, highestBid);

                        owner.transfer(cancelCost);
                        
                        auctionDetails.isBeingAuctioned = 0;
                        auctionDetails.auctionEnd = 0;
                        auctionDetails.numberofBids = 0;
                        auctionDetails.highestBid = 0;
                        auctionDetails.buynowPrice = 0;
                        auctionDetails.startingPrice = 0;

                        removeByValue(_tixnumberforsale);


              CanceledAuctionEvent(auctionowner, auctionwinner, _tixnumberforsale, highestBid);

                } 
                
                if (msg.sender == auctionowner && msg.value >= cancelCost && numberofBids == 0) {

                        owner.transfer(cancelCost);
                        
                        auctionDetails.isBeingAuctioned = 0;
                        auctionDetails.auctionEnd = 0;
                        auctionDetails.numberofBids = 0;
                        auctionDetails.highestBid = 0;
                        auctionDetails.buynowPrice = 0;
                        auctionDetails.startingPrice = 0;

                        removeByValue(_tixnumberforsale);


              CanceledAuctionEvent(auctionowner, auctionwinner, _tixnumberforsale, highestBid);

                }

       
   }
   

   //Buy Now Cancels Auction with no Penalty and returns all placed bids.  Contract takes cut of buy now price

   function buyNow(uint _tixnumberforsale) payable public {
       

     var auctionDetails = activeAuctionsStructs[_tixnumberforsale];
      uint auctionEnd = auctionDetails.auctionEnd;
      address auctionowner = auctionDetails.auctionOwner;
      address auctionlead = auctionDetails.winningBidder;
      uint256 highestBid = auctionDetails.highestBid;
      uint256 buynowprice = auctionDetails.buynowPrice;
      
      uint256 buynowcut = ownerCut;
    
      uint256 buynowownersCut = buynowPrice * buynowcut / 10000;


      require(buynowprice > 0);
      require(now < auctionEnd);
        
      if (msg.value == buynowPrice) {
          

          auctionowner.transfer(buynowPrice - buynowownersCut);
          owner.transfer(buynowownersCut);
         
         
          auctiontransfer(auctionowner, msg.sender, _tixnumberforsale);
          auctionDetails.isBeingAuctioned = 0;
          auctionDetails.auctionEnd = 0;
          auctionDetails.numberofBids = 0;
          auctionDetails.highestBid = 0;
          auctionDetails.buynowPrice = 0;
          auctionDetails.startingPrice = 0;

          removeByValue(_tixnumberforsale);


          BuyNowEvent(auctionowner, msg.sender, _tixnumberforsale, msg.value);
          
           if (auctionDetails.numberofBids > 0) {
         
          returnPrevBid(auctionlead, highestBid, _tixnumberforsale);

         }
          
          
      } else {
          
          revert();
      }
       
   }
   
    function withdraw(address forwardAddress, uint amount) public onlyOwner {

        forwardAddress.transfer(amount);

}
   
 
    function getAuctionDetails(uint tixnumberforsale)
        public
        view
        returns (uint _startingprice, uint _buynowprice, uint _numberofBids, uint _highestBid, uint _auctionEnd, address winningBidder, address _auctionOwner)
    {
        return (
         activeAuctionsStructs[tixnumberforsale].startingPrice,
         activeAuctionsStructs[tixnumberforsale].buynowPrice,
         activeAuctionsStructs[tixnumberforsale].numberofBids,
         activeAuctionsStructs[tixnumberforsale].highestBid,
         activeAuctionsStructs[tixnumberforsale].auctionEnd,
         activeAuctionsStructs[tixnumberforsale].winningBidder,
         activeAuctionsStructs[tixnumberforsale].auctionOwner);
         

    }
    
    //Had to split due to stack limitations of Solidity - Pull back together in UI
    
    function getMoreAuctionDetails(uint tixnumberforsale) public view returns (uint _auctionstatus, uint _auctionEnd, address _auctionOwner) {
        
     return (
                    
                    activeAuctionsStructs[tixnumberforsale].isBeingAuctioned,
                    activeAuctionsStructs[tixnumberforsale].auctionEnd,
                    activeAuctionsStructs[tixnumberforsale].auctionOwner);
        
    }
   
    
     function getOwnerAuctions(address _auctionowner)
        public
        view
        returns (uint[] _auctions)
    {
       
        return activeAuctionsByAddressStructs[_auctionowner];
    }
  
    
  //FUNCTIONS USED TO KEEP ACCURATE ARRAY OF LIVE AUCTIONS
  
  function find(uint value) view public returns(uint) {
        uint i = 0;
        while (runningauctions[i] != value) {
            i++;
        }
        return i;
    }

    function removeByValue(uint value) internal {
        uint i = find(value);
        removeByIndex(i);
    }

    function removeByIndex(uint i) internal {
        while (i<runningauctions.length-1) {
            runningauctions[i] = runningauctions[i+1];
            i++;
        }
        runningauctions.length--;
    }

    function getRunningAuctions() constant public returns(uint[]) {
        return runningauctions;
    }


     function() payable public {}

   
}


/**
 * @title BillionTix
 *
 * Main BillionTix Contract. Controls creation of BillionTix and  
 * selecting and Paying Giveaway Winners
 * Developed Exclusively for and by BillionTix Jan 31 2018
 */
 
contract Billiontix is MintableNonFungibleToken, Auction {
   address owner;

    string public name = 'BillionTix';
    string public symbol = 'BTIX';
   
    string internal TenTimesEther = "0.005 Ether";
    string internal OneHundredTimesEther = "0.05 Ether";
    string internal OneThousandTimesEther = "0.5 Ether";
    string internal TenThousandTimesEther = "5 Ether";
    string internal OneHundredThousandTimesEther = "50 Ether";
    string internal OneMillionTimesEther = "500 Ether";
    string internal TenMillionTimesEther = "5,000 Ether";
    string internal OneHundredMillionTimesEther = "50,000 Ether";
    string internal OneBillionTimesEther = "500,000 Ether";
   
   
    //SET THESE PRICES IN WEI
    
    uint256 public buyPrice =      500000000000000;
    uint256 public buy5Price =    2500000000000000;
    uint256 public buy10Price =   5000000000000000;
    uint256 public buy20Price =  10000000000000000;
    uint256 public buy50Price =  25000000000000000;
    uint256 public buy100Price = 50000000000000000;

    address public winner;
  
   //These are the supertix numbers. They will NOT CHANGE
   
    uint[] supertixarray = [10000,100000,500000,1000000,5000000,10000000,50000000,100000000,500000000,750000000];

 
    mapping(address => uint256) public balanceOf; 
    
    event PayoutEvent (uint indexed WinningNumber, address indexed _to, uint indexed value);
    event WinningNumbersEvent (uint256 indexed WinningNumber, string AmountWon); 
    event WinnerPaidEvent (address indexed Winner, string AmountWon);
    


  function buy () payable public 
   onlyNonexistentToken(_tokenId)
    {
       
       if ((msg.value) == buyPrice) {
           
           
        uint256 _tokenId = numTokensTotal +1;
        _setTokenOwner(_tokenId, msg.sender);
        _addTokenToOwnersList(msg.sender, _tokenId);
       // _insertTokenMetadata(_tokenId, _metadata);

       numTokensTotal = numTokensTotal.add(1);

        Mint(msg.sender, _tokenId);          

       if (numTokensTotal > 1 && numTokensTotal < 10000000002) {
       playDraw();
       playDraw2();
       supertixdraw();
       } else { }


       }
       else {
          
       }
       
   }
   
   
     function buy5 () payable public 
   onlyNonexistentToken(_tokenId)
    {
       for (uint i = 0; i < 5; i++) {
       if ((msg.value) == buy5Price) {
           
        uint256 _tokenId = numTokensTotal +1;
        _setTokenOwner(_tokenId, msg.sender);
        _addTokenToOwnersList(msg.sender, _tokenId);
       // _insertTokenMetadata(_tokenId, _metadata);

       numTokensTotal = numTokensTotal.add(1);

        Mint(msg.sender, _tokenId);          

       if (numTokensTotal > 1 && numTokensTotal < 10000000002) {
       playDraw();
       playDraw2();
       supertixdraw();

       } else { 
       }
       
       }
       else {
       }
       }
   }


  function buy10 () payable public 
   onlyNonexistentToken(_tokenId)
    {
       for (uint i = 0; i < 10; i++) {
       if ((msg.value) == buy10Price) {
           
        uint256 _tokenId = numTokensTotal +1;
        _setTokenOwner(_tokenId, msg.sender);
        _addTokenToOwnersList(msg.sender, _tokenId);
       // _insertTokenMetadata(_tokenId, _metadata);

       numTokensTotal = numTokensTotal.add(1);

        Mint(msg.sender, _tokenId);          

       if (numTokensTotal > 1 && numTokensTotal < 10000000002) {
       playDraw();
       playDraw2();
       supertixdraw();

       } else { }
       }
       else {
          
       }
       }
   }
      
    function buy20 () payable public 
   onlyNonexistentToken(_tokenId)
    {
       for (uint i = 0; i < 20; i++) {
       if ((msg.value) == buy20Price) {
           
        uint256 _tokenId = numTokensTotal +1;
        _setTokenOwner(_tokenId, msg.sender);
        _addTokenToOwnersList(msg.sender, _tokenId);
       // _insertTokenMetadata(_tokenId, _metadata);

       numTokensTotal = numTokensTotal.add(1);

        Mint(msg.sender, _tokenId);          

       if (numTokensTotal > 1 && numTokensTotal < 10000000002) {
       playDraw();
       playDraw2();
        supertixdraw();
        
      } else { }
       }
       else {
          
       }
       }
   }
   
    function buy50 () payable public 
   onlyNonexistentToken(_tokenId)
    {
       for (uint i = 0; i < 50; i++) {
       if ((msg.value) == buy50Price) {
           
         uint256 _tokenId = numTokensTotal +1;
        _setTokenOwner(_tokenId, msg.sender);
        _addTokenToOwnersList(msg.sender, _tokenId);
       // _insertTokenMetadata(_tokenId, _metadata);

       numTokensTotal = numTokensTotal.add(1);

        Mint(msg.sender, _tokenId);          

       if (numTokensTotal > 1 && numTokensTotal < 10000000002) {
       playDraw();
       playDraw2();
        supertixdraw();
   
       } else { }
       }
       else {
          
       }
       }
   }
   
    function buy100 () payable public 
   onlyNonexistentToken(_tokenId)
    {
       for (uint i = 0; i < 100; i++) {
       if ((msg.value) == buy100Price) {
           
        uint256 _tokenId = numTokensTotal +1;
        _setTokenOwner(_tokenId, msg.sender);
        _addTokenToOwnersList(msg.sender, _tokenId);
       // _insertTokenMetadata(_tokenId, _metadata);

       numTokensTotal = numTokensTotal.add(1);

        Mint(msg.sender, _tokenId);          

       if (numTokensTotal > 1 && numTokensTotal < 10000000002) {
       playDraw();
       playDraw2();
       supertixdraw();

       } else { }
       }
       else {
          
       }
       }
   }

   
 function playDraw() internal returns (uint winningrandomNumber1, 
 uint winningrandomNumber2, 
 uint winningrandomNumber3, 
 uint winningrandomNumber4, 
 uint winningrandomNumber5)  {
     

     uint A = ((numTokensTotal / 1) % 10);
     uint B = ((numTokensTotal / 10) % 10);
     uint C = ((numTokensTotal / 100) % 10);
     uint D = ((numTokensTotal / 1000) % 10);
     uint E = ((numTokensTotal / 10000) % 10);
     uint F = ((numTokensTotal / 100000) % 10);
     uint G = ((numTokensTotal / 1000000) % 10);
     uint H = ((numTokensTotal / 10000000) % 10);
     uint I = ((numTokensTotal / 100000000) % 10);
     uint J = ((numTokensTotal / 1000000000) % 10);

  
     
       if (A == 1 && B == 0) {
         
         winningrandomNumber1 = (uint(keccak256(block.blockhash(block.number-1), numTokensTotal + 1))%100 + (1000000000 * J) + (100000000 * I) + (10000000 * H) + (1000000 * G) + (100000 * F) + (10000 * E) + (1000 * D) + (100 * (C - 1)));
        
         WinningNumbersEvent(winningrandomNumber1, TenTimesEther);
         

        // PAY OUT THE WINNER HERE AFTER LOGGING WINNING NUMBER IN EVENT Pays 10x Ether - 0.005

         winner = ownerOf(winningrandomNumber1);
         payWinner(winner, 5000000000000000); 
         
         WinnerPaidEvent(winner, TenTimesEther);

        
     } else {
         //Do stuff here with non winning ticket if needed
     }

 if (A == 1 && B == 0 && C == 0) {
         
         winningrandomNumber2 = (uint(keccak256(block.blockhash(block.number-1), numTokensTotal + 2))%1000 + (1000000000 * J) + (100000000 * I) + (10000000 * H) + (1000000 * G) + (100000 * F) + (10000 * E) + (1000 * (D - 1)));
             
         WinningNumbersEvent(winningrandomNumber2, OneHundredTimesEther);


        // PAY OUT THE WINNER HERE AFTER LOGGING WINNING NUMBER IN EVENT
        // PAYS 100x Ether

         winner = ownerOf(winningrandomNumber2);
         payWinner(winner, 50000000000000000); 
         payBilliontixOwner();

         WinnerPaidEvent(winner, OneHundredTimesEther);
  
     
     } else {
         //Do stuff here with non winning ticket if needed
     }
 
 if (A == 1 && B == 0 && C == 0 && D == 0) {
         
          winningrandomNumber3 = (uint(keccak256(block.blockhash(block.number-1), numTokensTotal + 3))%10000 + (1000000000 * J) + (100000000 * I) + (10000000 * H) + (1000000 * G) + (100000 * F) + (10000 * (E - 1)));
          WinningNumbersEvent(winningrandomNumber3, OneThousandTimesEther);


      // PAY OUT THE WINNER HERE AFTER LOGGING WINNING NUMBER IN EVENT
      // PAYS 1,000x Ether   
      
        winner = ownerOf(winningrandomNumber3);
        payWinner(winner, 500000000000000000); 
        WinnerPaidEvent(winner, OneThousandTimesEther);


     } else {
         //Do stuff here with non winning ticket if needed
     }

     if (A == 1 && B == 0 && C == 0 && D == 0 && E == 0) {
         
          winningrandomNumber4 = (uint(keccak256(block.blockhash(block.number-1), numTokensTotal + 4))%100000 + (1000000000 * J) + (100000000 * I) + (10000000 * H) + (1000000 * G) + (100000 * (F - 1)));
          WinningNumbersEvent(winningrandomNumber4, TenThousandTimesEther);


      // PAY OUT THE WINNER HERE AFTER LOGGING WINNING NUMBER IN EVENT
      // PAYS 10,000x Ether
         
         winner = ownerOf(winningrandomNumber4);
         payWinner(winner, 5000000000000000000); 
         
         WinnerPaidEvent(winner, TenThousandTimesEther);

         
     } else {
         //Do stuff here with non winning ticket if needed
     }
     
  if (A == 1 && B == 0 && C == 0 && D == 0 && E == 0 && F == 0) {
         
          winningrandomNumber5 = (uint(keccak256(block.blockhash(block.number-1), numTokensTotal + 5))%1000000 + (1000000000 * J) + (100000000 * I) + (10000000 * H) + (1000000 * (G - 1)));
          WinningNumbersEvent(winningrandomNumber5, OneHundredThousandTimesEther);

        // PAY OUT THE WINNER HERE AFTER LOGGING WINNING NUMBER IN EVENT
        // PAYS 100,000x Ether

         winner = ownerOf(winningrandomNumber5);
         payWinner(winner, 50000000000000000000); 
         
        WinnerPaidEvent(winner, OneHundredThousandTimesEther);

         
     } else {
         //Do stuff here with non winning ticket if needed
     }
  
     
 }
 
 function playDraw2() internal returns (
 uint winningrandomNumber6,
 uint winningrandomNumber7,
 uint winningrandomNumber8,
 uint billiondollarwinningNumber) {
     

     uint A = ((numTokensTotal / 1) % 10);
     uint B = ((numTokensTotal / 10) % 10);
     uint C = ((numTokensTotal / 100) % 10);
     uint D = ((numTokensTotal / 1000) % 10);
     uint E = ((numTokensTotal / 10000) % 10);
     uint F = ((numTokensTotal / 100000) % 10);
     uint G = ((numTokensTotal / 1000000) % 10);
     uint H = ((numTokensTotal / 10000000) % 10);
     uint I = ((numTokensTotal / 100000000) % 10);
     uint J = ((numTokensTotal / 1000000000) % 10);
     uint K = ((numTokensTotal / 10000000000) % 10);

   
  
  if (A == 1 && B == 0 && C == 0 && D == 0 && E == 0 && F == 0 && G == 0) {
         
          winningrandomNumber6 = (uint(keccak256(block.blockhash(block.number-1), numTokensTotal + 6))%10000000 + (1000000000 * J) + (100000000 * I) + (10000000 * (H - 1)));
          WinningNumbersEvent(winningrandomNumber6, OneMillionTimesEther);


        // PAY OUT THE WINNER HERE AFTER LOGGING WINNING NUMBER IN EVENT
        // PAYS 1,000,000x Ether

         winner = ownerOf(winningrandomNumber6);
         payWinner(winner, 500000000000000000000); 
         
         WinnerPaidEvent(winner, OneMillionTimesEther);


     } else {
         //Do stuff here with non winning ticket if needed
     }
     
      if (A == 1 && B == 0 && C == 0 && D == 0 && E == 0 && F == 0 && G == 0 && H == 0) {
         
         winningrandomNumber7 = (uint(keccak256(block.blockhash(block.number-1), numTokensTotal + 7))%100000000 + (1000000000 * J) + (100000000 * (I - 1)));
         WinningNumbersEvent(winningrandomNumber7, TenMillionTimesEther);


       // PAY OUT THE WINNER HERE AFTER LOGGING WINNING NUMBER IN EVENT
       // PAYS 10,000,000x Ether
        
         winner = ownerOf(winningrandomNumber7);
         payWinner(winner, 5000000000000000000000);
         
         WinnerPaidEvent(winner, TenMillionTimesEther);


     
     } else {
         //Do stuff here with non winning ticket if needed
     }
 
     if (A == 1 && B == 0 && C == 0 && D == 0 && E == 0 && F == 0 && G == 0 && H == 0 && I == 0) {
         
          winningrandomNumber8 = (uint(keccak256(block.blockhash(block.number-1), numTokensTotal + 8))%1000000000 + (1000000000 * (J - 1)));
          WinningNumbersEvent(winningrandomNumber8, OneHundredMillionTimesEther);

        // PAY OUT THE WINNER HERE AFTER LOGGING WINNING NUMBER IN ARRAY
        // PAYS 100,000,000x Ether
        
         winner = ownerOf(winningrandomNumber8);
         payWinner(winner, 50000000000000000000000);
         
         WinnerPaidEvent(winner, OneHundredMillionTimesEther);

        
     } else {
         //Do stuff here with non winning ticket if needed
     }
     
     if (A == 1 && B == 0 && C == 0 && D == 0 && E == 0 && F == 0 && G == 0 && H == 0 && I == 0 && J == 0 && K == 1) {
         
         billiondollarwinningNumber = (uint(keccak256(block.blockhash(block.number-1), numTokensTotal + 9))%10000000000);
         WinningNumbersEvent(billiondollarwinningNumber, OneBillionTimesEther);


        //PAY OUT THE WINNER HERE AFTER LOGGING WINNING NUMBER IN EVENT
        // PAYS 1,000,000,000x Ether
    
         winner = ownerOf(billiondollarwinningNumber);
         payWinner(winner, 500000000000000000000000);
         
         WinnerPaidEvent(winner, OneBillionTimesEther);


     } else {
         //Do stuff here with non winning ticket if needed
     }

   
     
 }
 
 function supertixdraw()  internal returns (uint winningsupertixnumber) {

     uint A = ((numTokensTotal / 1) % 10);
     uint B = ((numTokensTotal / 10) % 10);
     uint C = ((numTokensTotal / 100) % 10);
     uint D = ((numTokensTotal / 1000) % 10);
     uint E = ((numTokensTotal / 10000) % 10);
     uint F = ((numTokensTotal / 100000) % 10);
     uint G = ((numTokensTotal / 1000000) % 10);
     uint H = ((numTokensTotal / 10000000) % 10);
     uint I = ((numTokensTotal / 100000000) % 10);
     uint J = ((numTokensTotal / 1000000000) % 10);
     
   
     
      if (A == 1 && B == 0 && C == 0 && D == 0 && E == 0 && F == 0 && G == 0 && H == 0 && I == 0 && J==1) {
          
          //AT TICKET 1Billion and 1 Sold - Give Away 10Million times Ether to SuperTix holder
          
           uint randomsupertixnumber = (uint(keccak256(block.blockhash(block.number-1), numTokensTotal + 2))%10);

           winningsupertixnumber = supertixarray[randomsupertixnumber];
       
           WinningNumbersEvent(winningsupertixnumber, TenMillionTimesEther);

         winner = ownerOf(winningsupertixnumber);
         payWinner(winner, 5000000000000000000000);
         
         WinnerPaidEvent(winner, TenMillionTimesEther);

        
     } else {
         //Do stuff here with non winning ticket if needed
     }
     
     
 }

 function Billiontix() public {
      owner = msg.sender;
   }
  
 function transferEther(address forwardAddress, uint amount) public onlyOwner {

        forwardAddress.transfer(amount);

}
 

  function payWinner(address winnerAddress, uint amount) internal {
      
        winnerAddress.transfer(amount);

}
 
 function payBilliontixOwner () internal {
     
     //This is Called at Every 1000 Level Giveaway to Give BillionTix Their Cut in Wei
     
      owner.transfer(50000000000000000);
     
 }
 

   function kill() public onlyOwner {
      if(msg.sender == owner)
         selfdestruct(owner);
   }
   
      function() payable public {}
      
}