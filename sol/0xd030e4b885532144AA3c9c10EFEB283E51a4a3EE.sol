pragma solidity ^0.4.18; // solhint-disable-line



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

/// Modified from the CryptoCelebrities contract
contract EmojiToken is ERC721 {

  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new emoji comes into existence.
  event Birth(uint256 tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721. 
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "EmojiBlockchain"; // solhint-disable-line
  string public constant SYMBOL = "EmojiToken"; // solhint-disable-line

  uint256 private startingPrice = 0.001 ether;
  // The limit was 77, and the redeployment was for 65 emoji
  // That's why the limit here is 142
  uint256 private constant PROMO_CREATION_LIMIT = 142;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.55 ether;

  /*** STORAGE ***/

  /// @dev A mapping from emoji IDs to the address that owns them. All emojis have
  ///  some valid owner address.
  mapping (uint256 => address) public emojiIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from EmojiIDs to an address that has been approved to call
  ///  transferFrom(). Each Emoji can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public emojiIndexToApproved;

  // @dev A mapping from EmojiIDs to the price of the token.
  mapping (uint256 => uint256) private emojiIndexToPrice;
  
  /// @dev A mapping from EmojiIDs to the previpus price of the token. Used
  /// to calculate price delta for payouts
  mapping (uint256 => uint256) private emojiIndexToPreviousPrice;

  // MY THING
  // @dev A mapping from emojiId to the custom message the owner set.
  mapping (uint256 => string) private emojiIndexToCustomMessage;

  // @dev A mapping from emojiId to the 7 last owners.
  mapping (uint256 => address[7]) private emojiIndexToPreviousOwners;


  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

  /*** DATATYPES ***/
  struct Emoji {
    string name;
  }

  Emoji[] private emojis;

  /*** ACCESS MODIFIERS ***/
  /// @dev Access modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  /// @dev Access modifier for COO-only functionality
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  /// Access modifier for contract owner only functionality
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

  /*** CONSTRUCTOR ***/
  function EmojiToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

  /*** PUBLIC FUNCTIONS ***/
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

    emojiIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /// @dev Creates a new promo Emoji with the given name, with given _price and assignes it to an address.
  function createPromoEmoji(address _owner, string _name, uint256 _price) public onlyCOO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address emojiOwner = _owner;
    if (emojiOwner == address(0)) {
      emojiOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createEmoji(_name, emojiOwner, _price);
  }

  /// @dev Creates a new Emoji with the given name.
  function createContractEmoji(string _name) public onlyCOO {
    _createEmoji(_name, address(this), startingPrice);
  }

  /// @notice Returns all the relevant information about a specific emoji.
  /// @param _tokenId The tokenId of the emoji of interest.
  function getEmoji(uint256 _tokenId) public view returns (
    string emojiName,
    uint256 sellingPrice,
    address owner,
    string message,
    uint256 previousPrice,
    address[7] previousOwners
  ) {
    Emoji storage emoji = emojis[_tokenId];
    emojiName = emoji.name;
    sellingPrice = emojiIndexToPrice[_tokenId];
    owner = emojiIndexToOwner[_tokenId];
    message = emojiIndexToCustomMessage[_tokenId];
    previousPrice = emojiIndexToPreviousPrice[_tokenId];
    previousOwners = emojiIndexToPreviousOwners[_tokenId];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /// @dev Required for ERC-721 compliance.
  function name() public pure returns (string) {
    return NAME;
  }

  /// For querying owner of token
  /// @param _tokenId The tokenID for owner inquiry
  /// @dev Required for ERC-721 compliance.
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = emojiIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

  // Allows owner to add short message to token
  // Limit is based on Twitter's tweet characterlimit
  function addMessage(uint256 _tokenId, string _message) public {
    require(_owns(msg.sender, _tokenId));
    require(bytes(_message).length<281);
    emojiIndexToCustomMessage[_tokenId] = _message;
  }

  // This function was added in order to give the ability
  // to manually set ownership history since this had to be
  // redeployed
  function setOwnershipHistory(uint256 _tokenId, address[7] _previousOwners) public onlyCOO {
    emojiIndexToPreviousOwners[_tokenId] = _previousOwners;
  }

  // This function was added in order to give the ability
  // to manually set the previous price since this had to 
  // be redeployed
  function setPreviousPrice(uint256 _tokenId, uint256 _previousPrice) public onlyCOO {
    emojiIndexToPreviousPrice[_tokenId] = _previousPrice;
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = emojiIndexToOwner[_tokenId];
    address newOwner = msg.sender;
    
    address[7] storage previousOwners = emojiIndexToPreviousOwners[_tokenId];

    uint256 sellingPrice = emojiIndexToPrice[_tokenId];
    uint256 previousPrice = emojiIndexToPreviousPrice[_tokenId];

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    uint256 priceDelta = SafeMath.sub(sellingPrice, previousPrice);
    uint256 payoutTotal = uint256(SafeMath.div(SafeMath.mul(priceDelta, 90), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
    // Update previous price
    emojiIndexToPreviousPrice[_tokenId] = sellingPrice; 
    // Update prices
    if (sellingPrice < firstStepLimit) {
      // first stage
      emojiIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 90);
    } else if (sellingPrice < secondStepLimit) {
      // second stage
      emojiIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 90);
    } else {
      // third stage
      emojiIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 90);
    }

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    // and if previous price is not 0
    if (oldOwner != address(this) && previousPrice > 0) {
      // old owner gets entire initial payment back
      oldOwner.transfer(previousPrice);
    }
    
    // Next distribute payoutTotal among previous Owners
    // Do not distribute if previous owner is contract.
    // Split is: 75, 12, 6, 3, 2, 1.5, 0.5
    if (previousOwners[0] != address(this) && payoutTotal > 0) {
      previousOwners[0].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 75), 100)));
    }
    if (previousOwners[1] != address(this) && payoutTotal > 0) {
      previousOwners[1].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 12), 100)));
    }
    if (previousOwners[2] != address(this) && payoutTotal > 0) {
      previousOwners[2].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 6), 100)));
    }
    if (previousOwners[3] != address(this) && payoutTotal > 0) {
      previousOwners[3].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 3), 100)));
    }
    if (previousOwners[4] != address(this) && payoutTotal > 0) {
      previousOwners[4].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 2), 100)));
    }
    if (previousOwners[5] != address(this) && payoutTotal > 0) {
      // divide by 1000 since percentage is 1.5
      previousOwners[5].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 15), 1000)));
    }
    if (previousOwners[6] != address(this) && payoutTotal > 0) {
      // divide by 1000 since percentage is 0.5
      previousOwners[6].transfer(uint256(SafeMath.div(SafeMath.mul(payoutTotal, 5), 1000)));
    }
    
    TokenSold(_tokenId, sellingPrice, emojiIndexToPrice[_tokenId], oldOwner, newOwner, emojis[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return emojiIndexToPrice[_tokenId];
  }

  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

  /// @dev Assigns a new address to act as the COO. Only available to the current COO.
  /// @param _newCOO The address of the new COO
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }

  /// @dev Required for ERC-721 compliance.
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

  /// @notice Allow pre-approved user to take ownership of a token
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = emojiIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose emoji tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
  ///  expensive (it walks the entire Emojis array looking for emojis belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalEmojis = totalSupply();
      uint256 resultIndex = 0;
      uint256 emojiId;
      for (emojiId = 0; emojiId <= totalEmojis; emojiId++) {
        if (emojiIndexToOwner[emojiId] == _owner) {
          result[resultIndex] = emojiId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return emojis.length;
  }

  /// Owner initates the transfer of the token to another account
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));
    _transfer(msg.sender, _to, _tokenId);
  }

  /// Third-party initiates transfer of token from address _from to address _to
  /// @param _from The address for the token to be transferred from.
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));
    _transfer(_from, _to, _tokenId);
  }

  /*** PRIVATE FUNCTIONS ***/
  /// Safety check on _to address to prevent against an unexpected 0x0 default.
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  /// For checking approval of transfer for address _to
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return emojiIndexToApproved[_tokenId] == _to;
  }

  /// For creating Emoji
  function _createEmoji(string _name, address _owner, uint256 _price) private {
    Emoji memory _emoji = Emoji({
      name: _name
    });
    uint256 newEmojiId = emojis.push(_emoji) - 1;

    // It's probably never going to happen, 4 billion tokens are A LOT, but
    // let's just be 100% sure we never let this happen.
    require(newEmojiId == uint256(uint32(newEmojiId)));

    Birth(newEmojiId, _name, _owner);

    emojiIndexToPrice[newEmojiId] = _price;
    emojiIndexToPreviousPrice[newEmojiId] = 0;
    emojiIndexToCustomMessage[newEmojiId] = 'hi';
    emojiIndexToPreviousOwners[newEmojiId] =
        [address(this), address(this), address(this), address(this), address(this), address(this), address(this)];

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newEmojiId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == emojiIndexToOwner[_tokenId];
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  /// @dev Assigns ownership of a specific Emoji to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of emojis is capped to 2^32 we can't overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    emojiIndexToOwner[_tokenId] = _to;
    // When creating new emojis _from is 0x0, but we can't account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete emojiIndexToApproved[_tokenId];
    }
    // Update the emojiIndexToPreviousOwners
    emojiIndexToPreviousOwners[_tokenId][6]=emojiIndexToPreviousOwners[_tokenId][5];
    emojiIndexToPreviousOwners[_tokenId][5]=emojiIndexToPreviousOwners[_tokenId][4];
    emojiIndexToPreviousOwners[_tokenId][4]=emojiIndexToPreviousOwners[_tokenId][3];
    emojiIndexToPreviousOwners[_tokenId][3]=emojiIndexToPreviousOwners[_tokenId][2];
    emojiIndexToPreviousOwners[_tokenId][2]=emojiIndexToPreviousOwners[_tokenId][1];
    emojiIndexToPreviousOwners[_tokenId][1]=emojiIndexToPreviousOwners[_tokenId][0];
    // the _from address for creation is 0, so instead set it to the contract address
    if (_from != address(0)) {
        emojiIndexToPreviousOwners[_tokenId][0]=_from;
    } else {
        emojiIndexToPreviousOwners[_tokenId][0]=address(this);
    }
    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
}
library SafeMath {

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