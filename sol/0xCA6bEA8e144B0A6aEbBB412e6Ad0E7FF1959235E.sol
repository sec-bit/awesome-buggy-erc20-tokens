pragma solidity ^0.4.18;

/// Item23s :3

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

}

contract EtherConsole is ERC721 {

  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new item23 comes into existence.
  event Birth(uint256 tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721.
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/
  //uint256 private startingPrice = 0.001 ether;

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CrypoConsoles"; // solhint-disable-line
  string public constant SYMBOL = "CryptoConsole"; // solhint-disable-line

  /*** STORAGE ***/

  /// @dev A mapping from item23 IDs to the address that owns them. All item23s have
  ///  some valid owner address.
  mapping (uint256 => address) public item23IndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from Item23IDs to an address that has been approved to call
  ///  transferFrom(). Each Item23 can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public item23IndexToApproved;

  // @dev A mapping from Item23IDs to the price of the token.
  mapping (uint256 => uint256) private item23IndexToPrice;

  /// @dev A mapping from Item23IDs to the previpus price of the token. Used
  /// to calculate price delta for payouts
  mapping (uint256 => uint256) private item23IndexToPreviousPrice;

  // @dev A mapping from item23Id to the 7 last owners.
  mapping (uint256 => address[5]) private item23IndexToPreviousOwners;


  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;

  /*** DATATYPES ***/
  struct Item23 {
    string name;
  }

  Item23[] private item23s;

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
  function EtherConsole() public {
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

    item23IndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /// @dev Creates a new Item23 with the given name.
  function createContractItem23(string _name , string _startingP ) public onlyCOO {
    _createItem23(_name, address(this), stringToUint( _startingP));
  }



function stringToUint(string _amount) internal constant returns (uint result) {
    bytes memory b = bytes(_amount);
    uint i;
    uint counterBeforeDot;
    uint counterAfterDot;
    result = 0;
    uint totNum = b.length;
    totNum--;
    bool hasDot = false;

    for (i = 0; i < b.length; i++) {
        uint c = uint(b[i]);

        if (c >= 48 && c <= 57) {
            result = result * 10 + (c - 48);
            counterBeforeDot ++;
            totNum--;
        }

        if(c == 46){
            hasDot = true;
            break;
        }
    }

    if(hasDot) {
        for (uint j = counterBeforeDot + 1; j < 18; j++) {
            uint m = uint(b[j]);

            if (m >= 48 && m <= 57) {
                result = result * 10 + (m - 48);
                counterAfterDot ++;
                totNum--;
            }

            if(totNum == 0){
                break;
            }
        }
    }
     if(counterAfterDot < 18){
         uint addNum = 18 - counterAfterDot;
         uint multuply = 10 ** addNum;
         return result = result * multuply;
     }

     return result;
}


  /// @notice Returns all the relevant information about a specific item23.
  /// @param _tokenId The tokenId of the item23 of interest.
  function getItem23(uint256 _tokenId) public view returns (
    string item23Name,
    uint256 sellingPrice,
    address owner,
    uint256 previousPrice,
    address[5] previousOwners
  ) {
    Item23 storage item23 = item23s[_tokenId];
    item23Name = item23.name;
    sellingPrice = item23IndexToPrice[_tokenId];
    owner = item23IndexToOwner[_tokenId];
    previousPrice = item23IndexToPreviousPrice[_tokenId];
    previousOwners = item23IndexToPreviousOwners[_tokenId];
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
    owner = item23IndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = item23IndexToOwner[_tokenId];
    address newOwner = msg.sender;

    address[5] storage previousOwners = item23IndexToPreviousOwners[_tokenId];

    uint256 sellingPrice = item23IndexToPrice[_tokenId];
    uint256 previousPrice = item23IndexToPreviousPrice[_tokenId];
    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    uint256 priceDelta = SafeMath.sub(sellingPrice, previousPrice);
    uint256 ownerPayout = SafeMath.add(previousPrice, SafeMath.mul(SafeMath.div(priceDelta, 100), 40));


    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    item23IndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
    item23IndexToPreviousPrice[_tokenId] = sellingPrice;

    uint256 strangePrice = uint256(SafeMath.mul(SafeMath.div(priceDelta, 100), 10));
    uint256 strangePrice2 = uint256(0);


    // Pay previous tokenOwner if owner is not contract
    // and if previous price is not 0
    if (oldOwner != address(this)) {
      // old owner gets entire initial payment back
      oldOwner.transfer(ownerPayout);
    } else {
      strangePrice = SafeMath.add(ownerPayout, strangePrice);
    }

    // Next distribute payout Total among previous Owners
    for (uint i = 0; i < 5; i++) {
        if (previousOwners[i] != address(this)) {
            strangePrice2+=uint256(SafeMath.mul(SafeMath.div(priceDelta, 100), 10));
        } else {
            strangePrice = SafeMath.add(strangePrice, uint256(SafeMath.mul(SafeMath.div(priceDelta, 100), 10)));
        }
    }

    ceoAddress.transfer(strangePrice+strangePrice2);
    //ceoAddress.transfer(strangePrice2);
    _transfer(oldOwner, newOwner, _tokenId);

    //TokenSold(_tokenId, sellingPrice, item23IndexToPrice[_tokenId], oldOwner, newOwner, item23s[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }


  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return item23IndexToPrice[_tokenId];
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
    address oldOwner = item23IndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose item23 tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
  ///  expensive (it walks the entire Item23s array looking for item23s belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalItem23s = totalSupply();
      uint256 resultIndex = 0;
      uint256 item23Id;
      for (item23Id = 0; item23Id <= totalItem23s; item23Id++) {
        if (item23IndexToOwner[item23Id] == _owner) {
          result[resultIndex] = item23Id;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return item23s.length;
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
    return item23IndexToApproved[_tokenId] == _to;
  }

  /// For creating Item23
  function _createItem23(string _name, address _owner, uint256 _price) private {
    Item23 memory _item23 = Item23({
      name: _name
    });
    uint256 newItem23Id = item23s.push(_item23) - 1;

    // It's probably never going to happen, 4 billion tokens are A LOT, but
    // let's just be 100% sure we never let this happen.
    require(newItem23Id == uint256(uint32(newItem23Id)));

    Birth(newItem23Id, _name, _owner);

    item23IndexToPrice[newItem23Id] = _price;
    item23IndexToPreviousPrice[newItem23Id] = 0;
    item23IndexToPreviousOwners[newItem23Id] =
        [address(this), address(this), address(this), address(this)];

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newItem23Id);
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == item23IndexToOwner[_tokenId];
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  /// @dev Assigns ownership of a specific Item23 to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of item23s is capped to 2^32 we can't overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    item23IndexToOwner[_tokenId] = _to;
    // When creating new item23s _from is 0x0, but we can't account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete item23IndexToApproved[_tokenId];
    }
    // Update the item23IndexToPreviousOwners
    item23IndexToPreviousOwners[_tokenId][4]=item23IndexToPreviousOwners[_tokenId][3];
    item23IndexToPreviousOwners[_tokenId][3]=item23IndexToPreviousOwners[_tokenId][2];
    item23IndexToPreviousOwners[_tokenId][2]=item23IndexToPreviousOwners[_tokenId][1];
    item23IndexToPreviousOwners[_tokenId][1]=item23IndexToPreviousOwners[_tokenId][0];
    // the _from address for creation is 0, so instead set it to the contract address
    if (_from != address(0)) {
        item23IndexToPreviousOwners[_tokenId][0]=_from;
    } else {
        item23IndexToPreviousOwners[_tokenId][0]=address(this);
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