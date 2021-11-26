pragma solidity ^0.4.19;


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
  // Required methods
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

  // Optional
  // function name() public view returns (string name);
  // function symbol() public view returns (string symbol);
  // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

contract Ownable {
    
	  // The addresses of the accounts (or contracts) that can execute actions within each roles.
	address public hostAddress;
	address public adminAddress;
    
    function Ownable() public {
		hostAddress = msg.sender;
		adminAddress = msg.sender;
    }

    modifier onlyHost() {
        require(msg.sender == hostAddress); 
        _;
    }
	
    modifier onlyAdmin() {
        require(msg.sender == adminAddress);
        _;
    }
	
	/// Access modifier for contract owner only functionality
	modifier onlyHostOrAdmin() {
		require(
		  msg.sender == hostAddress ||
		  msg.sender == adminAddress
		);
		_;
	}

	function setHost(address _newHost) public onlyHost {
		require(_newHost != address(0));

		hostAddress = _newHost;
	}
    
	function setAdmin(address _newAdmin) public onlyHost {
		require(_newAdmin != address(0));

		adminAddress = _newAdmin;
	}
}

contract TokensWarContract is ERC721, Ownable {
        
    /*** EVENTS ***/
        
    /// @dev The NewHero event is fired whenever a new card comes into existence.
    event NewToken(uint256 tokenId, string name, address owner);
        
    /// @dev The NewTokenOwner event is fired whenever a token is sold.
    event NewTokenOwner(uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name, uint256 tokenId);
    
    /// @dev The NewGoldenCard event is fired whenever a golden card is change.
    event NewGoldenToken(uint256 goldenPayment);
        
    /// @dev Transfer event as defined in current draft of ERC721. ownership is assigned, including births.
    event Transfer(address from, address to, uint256 tokenId);
        
    /*** CONSTANTS ***/
        
    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant NAME = "TokensWarContract"; // solhint-disable-line
    string public constant SYMBOL = "TWC"; // solhint-disable-line
      
    uint256 private startingPrice = 0.001 ether; 
    uint256 private firstStepLimit =  0.045 ether; //5 iteration
    uint256 private secondStepLimit =  0.45 ether; //8 iteration
    uint256 private thirdStepLimit = 1.00 ether; //10 iteration
        
    /*** STORAGE ***/
        
    /// @dev A mapping from card IDs to the address that owns them. All cards have
    ///  some valid owner address.
    mapping (uint256 => address) public cardTokenToOwner;
        
    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) private ownershipTokenCount;
        
    /// @dev A mapping from CardIDs to an address that has been approved to call
    ///  transferFrom(). Each card can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public cardTokenToApproved;
        
    // @dev A mapping from CardIDs to the price of the token.
    mapping (uint256 => uint256) private cardTokenToPrice;
        
    // @dev A mapping from CardIDs to the position of the item in array.
    mapping (uint256 => uint256) private cardTokenToPosition;
    
    // @dev tokenId of golden card.
    uint256 public goldenTokenId;
    
    /*** STORAGE ***/
    
	/*** ------------------------------- ***/
    
    /*** CARDS ***/
    
	/*** DATATYPES ***/
	struct Card {
		uint256 token;
		string name;
	}

	Card[] private cards;
    
	
	/// @notice Returns all the relevant information about a specific card.
	/// @param _tokenId The tokenId of the card of interest.
	function getCard(uint256 _tokenId) public view returns (
		string name,
		uint256 token
	) {
	    
	    address owner = cardTokenToOwner[_tokenId];
        require(owner != address(0));
	    
	    uint256 index = cardTokenToPosition[_tokenId];
	    Card storage card = cards[index];
		name = card.name;
		token = card.token;
	}
    
    /// @dev Creates a new token with the given name.
	function createToken(string _name, uint256 _id) public onlyAdmin {
		_createToken(_name, _id, address(this), startingPrice);
	}
	
    /// @dev set golden card token.
	function setGoldenCardToken(uint256 tokenId) public onlyAdmin {
		goldenTokenId = tokenId;
		NewGoldenToken(goldenTokenId);
	}
	
	function _createToken(string _name, uint256 _id, address _owner, uint256 _price) private {
	    
		Card memory _card = Card({
		  name: _name,
		  token: _id
		});
			
		uint256 index = cards.push(_card) - 1;
		cardTokenToPosition[_id] = index;
		// It's probably never going to happen, 4 billion tokens are A LOT, but
		// let's just be 100% sure we never let this happen.
		require(_id == uint256(uint32(_id)));

		NewToken(_id, _name, _owner);
		cardTokenToPrice[_id] = _price;
		// This will assign ownership, and also emit the Transfer event as
		// per ERC721 draft
		_transfer(address(0), _owner, _id);
	}
	/*** CARDS ***/
	
	/*** ------------------------------- ***/
	
	/*** ERC721 FUNCTIONS ***/
    /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
      ) public {
        // Caller must own token.
        require(_owns(msg.sender, _tokenId));
    
        cardTokenToApproved[_tokenId] = _to;
    
        Approval(msg.sender, _to, _tokenId);
    }
    
    /// For querying balance of a particular account
    /// @param _owner The address for balance query
    /// @dev Required for ERC-721 compliance.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }
    
    function implementsERC721() public pure returns (bool) {
        return true;
    }
    

    /// For querying owner of token
    /// @param _tokenId The tokenID for owner inquiry
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = cardTokenToOwner[_tokenId];
        require(owner != address(0));
    }
    
    /// @notice Allow pre-approved user to take ownership of a token
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = cardTokenToOwner[_tokenId];
    
        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));

        // Making sure transfer is approved
        require(_approved(newOwner, _tokenId));
    
        _transfer(oldOwner, newOwner, _tokenId);
    }
    
    /// For querying totalSupply of token
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint256 total) {
        return cards.length;
    }
    
    /// Third-party initiates transfer of token from address _from to address _to
    /// @param _from The address for the token to be transferred from.
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));
    
        _transfer(_from, _to, _tokenId);
    }

    /// Owner initates the transfer of the token to another account
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));
    
        _transfer(msg.sender, _to, _tokenId);
    }
    
    /// @dev Required for ERC-721 compliance.
    function name() public pure returns (string) {
        return NAME;
    }
    
    /// @dev Required for ERC-721 compliance.
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

	/*** ERC721 FUNCTIONS ***/
	
	/*** ------------------------------- ***/
	
	/*** ADMINISTRATOR FUNCTIONS ***/
	
	//send balance of contract on wallet
	function payout(address _to) public onlyHostOrAdmin {
		_payout(_to);
	}
	
	function _payout(address _to) private {
		if (_to == address(0)) {
			hostAddress.transfer(this.balance);
		} else {
			_to.transfer(this.balance);
		}
	}
	
	/*** ADMINISTRATOR FUNCTIONS ***/
	

    /*** PUBLIC FUNCTIONS ***/

    function contractBalance() public  view returns (uint256 balance) {
        return address(this).balance;
    }
    


  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = cardTokenToOwner[_tokenId];
    address newOwner = msg.sender;
    
    require(oldOwner != address(0));

    uint256 sellingPrice = cardTokenToPrice[_tokenId];

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(Helper.div(Helper.mul(sellingPrice, 93), 100));
    uint256 goldenPayment = uint256(Helper.div(Helper.mul(sellingPrice, 2), 100));
    
    uint256 purchaseExcess = Helper.sub(msg.value, sellingPrice);

    // Update prices
    if (sellingPrice < firstStepLimit) {
      // first stage
      cardTokenToPrice[_tokenId] = Helper.div(Helper.mul(sellingPrice, 300), 93);
    } else if (sellingPrice < secondStepLimit) {
      // second stage
      cardTokenToPrice[_tokenId] = Helper.div(Helper.mul(sellingPrice, 200), 93);
    } else if (sellingPrice < thirdStepLimit) {
      // second stage
      cardTokenToPrice[_tokenId] = Helper.div(Helper.mul(sellingPrice, 120), 93);
    } else {
      // third stage
      cardTokenToPrice[_tokenId] = Helper.div(Helper.mul(sellingPrice, 115), 93);
    }

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //-0.05
    }
    
    //Pay golden commission
    address goldenOwner = cardTokenToOwner[goldenTokenId];
    if (goldenOwner != address(0)) {
      goldenOwner.transfer(goldenPayment); //-0.02
    }

	//CONTRACT EVENT 
	uint256 index = cardTokenToPosition[_tokenId];
    NewTokenOwner(sellingPrice, cardTokenToPrice[_tokenId], oldOwner, newOwner, cards[index].name, _tokenId);

    msg.sender.transfer(purchaseExcess);
    
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return cardTokenToPrice[_tokenId];
  }



  /// @param _owner The owner whose celebrity tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
  ///  expensive (it walks the entire cards array looking for cards belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalCards = totalSupply();
      uint256 resultIndex = 0;

      uint256 index;
      for (index = 0; index <= totalCards-1; index++) {
        if (cardTokenToOwner[cards[index].token] == _owner) {
          result[resultIndex] = cards[index].token;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /*** PRIVATE FUNCTIONS ***/
  /// Safety check on _to address to prevent against an unexpected 0x0 default.
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  /// For checking approval of transfer for address _to
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return cardTokenToApproved[_tokenId] == _to;
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == cardTokenToOwner[_tokenId];
  }


  /// @dev Assigns ownership of a specific card to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of cards is capped to 2^32 we can't overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    cardTokenToOwner[_tokenId] = _to;

    // When creating new cards _from is 0x0, but we can't account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete cardTokenToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
  

    function TokensWarContract() public {
    }
    
}

library Helper {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}