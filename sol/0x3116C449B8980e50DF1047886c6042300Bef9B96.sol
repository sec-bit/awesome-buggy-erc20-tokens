pragma solidity ^0.4.18;

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)

contract ERC721 {
  // Required methods
  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;

  //Events
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

contract CryptoColors is ERC721 {

  /*** EVENTS ***/

  /// @dev The Released event is fired whenever a new color is released.
  event Released(uint256 tokenId, string name, address owner);

  /// @dev The ColorSold event is fired whenever a color is sold.
  event ColorSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721.
  /// ownership is assigned, including initial color listings.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/
  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CryptoColors";
  string public constant SYMBOL = "COLOR";

  uint256 private constant PROMO_CREATION_LIMIT = 1000000;
  uint256 private startingPrice = 0.001 ether;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.5 ether;


  /*** STORAGE ***/
  /// @dev A mapping from color IDs to the address that owns them. All colors have
  ///  some valid owner address.
  mapping (uint256 => address) public colorIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from colorIDs to an address that has been approved to call
  ///  transferFrom(). Each color can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public colorIndexToApproved;

  // @dev A mapping from colorIDs to the price of the token.
  mapping (uint256 => uint256) private colorIndexToPrice;

  // The address of the CEO
  address public ceoAddress;

  // Keeps track of the total promo colors released
  uint256 public promoCreatedCount;

  /*** DATATYPES ***/
  struct Color{
    uint8 R;
    uint8 G;
    uint8 B;
    string name;
  }

  // Storage array of all colors. Indexed by colorId.
  Color[] private colors;


  /*** ACCESS MODIFIERS ***/
  /// @dev Access modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  /*** CONSTRUCTOR ***/
  function CryptoColors() public {
    ceoAddress = msg.sender;
  }

  /*** PUBLIC FUNCTIONS ***/

  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

  /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
  /// @param _to The address to be granted transfer approval. Pass address(0) to clear all approvals.
  /// @param _tokenId The ID of the color that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function approve(address _to, uint256 _tokenId) public {
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));

    colorIndexToApproved[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /// @dev Creates a new color with the given name, with given _price and assignes it to an address.
  function createPromoColor(uint256 _R, uint256 _G, uint256 _B, string _name, address _owner, uint256 _price) public onlyCEO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address colorOwner = _owner;
    if (colorOwner == address(0)) {
      colorOwner = ceoAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createColor(_R, _G, _B, _name, colorOwner, _price);
  }

  /// @dev Creates a new color with the given name and assigns it to the contract.
  function createContractColor(uint256 _R, uint256 _G, uint256 _B, string _name) public onlyCEO {
    _createColor(_R, _G, _B, _name, address(this), startingPrice);
  }

  /// @notice Returns all the relevant information about a specific color.
  /// @param _tokenId The Id of the color of interest.
  function getColor(uint256 _tokenId) public view returns (uint256 R, uint256 G, uint256 B, string colorName, uint256 sellingPrice, address owner) {
    Color storage col = colors[_tokenId];

    R = col.R;
    G = col.G;
    B = col.B;
    colorName = col.name;
    sellingPrice = colorIndexToPrice[_tokenId];
    owner = colorIndexToOwner[_tokenId];
  }

  /// For querying owner of token
  /// @param _tokenId The colorId for owner inquiry
  /// @dev Required for ERC-721 compliance.
  function ownerOf(uint256 _tokenId) public view returns (address owner) {
    owner = colorIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCEO {
    _payout(_to);
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = colorIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = colorIndexToPrice[_tokenId];

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 93), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    // Update prices
    if (sellingPrice < firstStepLimit) {
      // first stage
      colorIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 93);
    } else if (sellingPrice < secondStepLimit) {
      // second stage
      colorIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 93);
    } else {
      // third stage
      colorIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 93);
    }

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
    }

    ColorSold(_tokenId, sellingPrice, colorIndexToPrice[_tokenId], oldOwner, newOwner, colors[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return colorIndexToPrice[_tokenId];
  }


  /// @notice Allow pre-approved user to take ownership of a color
  /// @param _tokenId The ID of the color that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = colorIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose color tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
  ///  expensive (it walks the entire colors array looking for colors belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalcolors = totalSupply();
      uint256 resultIndex = 0;

      uint256 colorId;
      for (colorId = 0; colorId <= totalcolors; colorId++) {
        if (colorIndexToOwner[colorId] == _owner) {
          result[resultIndex] = colorId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return colors.length;
  }

  /// Owner initates the transfer of the token to another account
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the color that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(address _to, uint256 _tokenId) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

  /// Third-party initiates transfer of token from address _from to address _to
  /// @param _from The address for the token to be transferred from.
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the color that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transferFrom(address _from, address _to, uint256 _tokenId) public {
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
    return colorIndexToApproved[_tokenId] == _to;
  }

  /// For creating color
  function _createColor(uint256 _R, uint256 _G, uint256 _B, string _name, address _owner, uint256 _price) private {
    require(_R == uint256(uint8(_R)));
    require(_G == uint256(uint8(_G)));
    require(_B == uint256(uint8(_B)));

    Color memory _color = Color({
        R: uint8(_R),
        G: uint8(_G),
        B: uint8(_B),
        name: _name
    });

    uint256 newColorId = colors.push(_color) - 1;

    require(newColorId == uint256(uint32(newColorId)));

    Released(newColorId, _name, _owner);

    colorIndexToPrice[newColorId] = _price;

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newColorId);
  }

  /// Check for color ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == colorIndexToOwner[_tokenId];
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  /// @dev Assigns ownership of a specific Color to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of colors is capped to 2^32 we can't overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    colorIndexToOwner[_tokenId] = _to;

    // When creating new colors _from is 0x0, but we can't account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete colorIndexToApproved[_tokenId];
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
}