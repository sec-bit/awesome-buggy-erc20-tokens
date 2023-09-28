pragma solidity ^0.4.19; //

// EtherVillains.co


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

contract EtherVillains is ERC721 {

  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new villain comes into existence.
  event Birth(uint256 tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721.
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "EtherVillains"; //
  string public constant SYMBOL = "EVIL"; //

  uint256 public precision = 1000000000000; //0.000001 Eth

  uint256 private zapPrice =  0.001 ether;
  uint256 private pinchPrice =  0.002 ether;
  uint256 private guardPrice =  0.002 ether;

  uint256 private pinchPercentageReturn = 20; // how much a flip is worth when a villain is flipped.

  uint256 private defaultStartingPrice = 0.001 ether;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.5 ether;

  /*** STORAGE ***/

  /// @dev A mapping from villain IDs to the address that owns them. All villians have
  ///  some valid owner address.
  mapping (uint256 => address) public villainIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from Villains to an address that has been approved to call
  ///  transferFrom(). Each Villain can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public villainIndexToApproved;

  // @dev A mapping from Villains to the price of the token.
  mapping (uint256 => uint256) private villainIndexToPrice;

  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;


  /*** DATATYPES ***/
  struct Villain {
    uint256 id; // needed for gnarly front end
    string name;
    uint256 class; // 0 = Zapper , 1 = Pincher , 2 = Guard
    uint256 level; // 0 for Zapper, 1 - 5 for Pincher, Guard - representing the max active pinches or guards
    uint256 numSkillActive; // the current number of active skill implementations (pinches or guards)
    uint256 state; // 0 = normal , 1 = zapped , 2 = pinched , 3 = guarded
    uint256 zappedExipryTime; // if this villain was disarmed, when does it expire
    uint256 affectedByToken; // token that has affected this token (zapped, pinched, guarded)
    uint256 buyPrice; // the price at which this villain was purchased
  }

  Villain[] private villains;

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
  function EtherVillains() public {
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

    villainIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /// @dev Creates a new Villain with the given name.
  function createVillain(string _name, uint256 _startPrice, uint256 _class, uint256 _level) public onlyCLevel {
    _createVillain(_name, address(this), _startPrice,_class,_level);
  }

  /// @notice Returns all the relevant information about a specific villain.
  /// @param _tokenId The tokenId of the villain of interest.
  function getVillain(uint256 _tokenId) public view returns (
    uint256 id,
    string villainName,
    uint256 sellingPrice,
    address owner,
    uint256 class,
    uint256 level,
    uint256 numSkillActive,
    uint256 state,
    uint256 zappedExipryTime,
    uint256 buyPrice,
    uint256 nextPrice,
    uint256 affectedByToken
  ) {
    id = _tokenId;
    Villain storage villain = villains[_tokenId];
    villainName = villain.name;
    sellingPrice =villainIndexToPrice[_tokenId];
    owner = villainIndexToOwner[_tokenId];
    class = villain.class;
    level = villain.level;
    numSkillActive = villain.numSkillActive;
    state = villain.state;
    if (villain.state==1 && now>villain.zappedExipryTime){
        state=0; // time expired so say they are armed
    }
    zappedExipryTime=villain.zappedExipryTime;
    buyPrice=villain.buyPrice;
    nextPrice=calculateNewPrice(_tokenId);
    affectedByToken=villain.affectedByToken;
  }

  /// zap a villain in preparation for a pinch
  function zapVillain(uint256 _victim  , uint256 _zapper) public payable returns (bool){
    address villanOwner = villainIndexToOwner[_victim];
    require(msg.sender != villanOwner); // it doesn't make sense, but hey
    require(villains[_zapper].class==0); // they must be a zapper class
    require(msg.sender==villainIndexToOwner[_zapper]); // they must be a zapper owner

    uint256 operationPrice = zapPrice;
    // if the target sale price <0.01 then operation is free
    if (villainIndexToPrice[_victim]<0.01 ether){
      operationPrice=0;
    }

    // can be used to extend a zapped period
    if (msg.value>=operationPrice && villains[_victim].state<2){
        // zap villain
        villains[_victim].state=1;
        villains[_victim].zappedExipryTime = now + (villains[_zapper].level * 1 minutes);
    }

  }

    /// pinch a villain
  function pinchVillain(uint256 _victim, uint256 _pincher) public payable returns (bool){
    address victimOwner = villainIndexToOwner[_victim];
    require(msg.sender != victimOwner); // it doesn't make sense, but hey
    require(msg.sender==villainIndexToOwner[_pincher]);
    require(villains[_pincher].class==1); // they must be a pincher
    require(villains[_pincher].numSkillActive<villains[_pincher].level);

    uint256 operationPrice = pinchPrice;
    // if the target sale price <0.01 then operation is free
    if (villainIndexToPrice[_victim]<0.01 ether){
      operationPrice=0;
    }

    // 0 = normal , 1 = zapped , 2 = pinched
    // must be inside the zapped window
    if (msg.value>=operationPrice && villains[_victim].state==1 && now< villains[_victim].zappedExipryTime){
        // squeeze
        villains[_victim].state=2; // squeezed
        villains[_victim].affectedByToken=_pincher;
        villains[_pincher].numSkillActive++;
    }
  }

  /// guard a villain
  function guardVillain(uint256 _target, uint256 _guard) public payable returns (bool){
    require(msg.sender==villainIndexToOwner[_guard]); // sender must own this token
    require(villains[_guard].numSkillActive<villains[_guard].level);

    uint256 operationPrice = guardPrice;
    // if the target sale price <0.01 then operation is free
    if (villainIndexToPrice[_target]<0.01 ether){
      operationPrice=0;
    }

    // 0 = normal , 1 = zapped , 2 = pinched, 3 = guarded
    if (msg.value>=operationPrice && villains[_target].state<2){
        // guard this villain
        villains[_target].state=3;
        villains[_target].affectedByToken=_guard;
        villains[_guard].numSkillActive++;
    }
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
    owner = villainIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }




  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = villainIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = villainIndexToPrice[_tokenId];

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    uint256 payment = roundIt(uint256(SafeMath.div(SafeMath.mul(sellingPrice, 93), 100))); // taking 7% for the house before any pinches?
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);


    // HERE'S THE FLIPPING STRATEGY

    villainIndexToPrice[_tokenId]  = calculateNewPrice(_tokenId);


     // we check to see if there is a pinch on this villain
     // if there is, then transfer the pinch percentage to the owner of the pinch token
     if (villains[_tokenId].state==2 && villains[_tokenId].affectedByToken!=0){
         uint256 profit = sellingPrice - villains[_tokenId].buyPrice;
         uint256 pinchPayment = roundIt(SafeMath.mul(SafeMath.div(profit,100),pinchPercentageReturn));

         // release on of this villans pinch capabilitiesl
         address pincherTokenOwner = villainIndexToOwner[villains[_tokenId].affectedByToken];
         pincherTokenOwner.transfer(pinchPayment);
         payment = SafeMath.sub(payment,pinchPayment); // subtract the pinch fees
     }

     // free the villan of any pinches or guards as part of this purpose
     if (villains[villains[_tokenId].affectedByToken].numSkillActive>0){
        villains[villains[_tokenId].affectedByToken].numSkillActive--; // reset the pincher or guard affected count
     }

     villains[_tokenId].state=0;
     villains[_tokenId].affectedByToken=0;
     villains[_tokenId].buyPrice=sellingPrice;

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //(1-0.08)
    }

    TokenSold(_tokenId, sellingPrice, villainIndexToPrice[_tokenId], oldOwner, newOwner, villains[_tokenId].name);

    msg.sender.transfer(purchaseExcess); // return any additional amount
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return villainIndexToPrice[_tokenId];
  }

  function nextPrice(uint256 _tokenId) public view returns (uint256 nPrice) {
    return calculateNewPrice(_tokenId);
  }


//(note: hard coded value appreciation is 2X from a contract price of 0 ETH to 0.05 ETH, 1.2X from 0.05 to 0.5 and 1.15X from 0.5 ETH and up).


 function calculateNewPrice(uint256 _tokenId) internal view returns (uint256 price){
   uint256 sellingPrice = villainIndexToPrice[_tokenId];
   uint256 newPrice;
   // Update prices
   if (sellingPrice < firstStepLimit) {
     // first stage
    newPrice = roundIt(SafeMath.mul(sellingPrice, 2));
   } else if (sellingPrice < secondStepLimit) {
     // second stage
     newPrice = roundIt(SafeMath.div(SafeMath.mul(sellingPrice, 120), 100));
   } else {
     // third stage
     newPrice= roundIt(SafeMath.div(SafeMath.mul(sellingPrice, 115), 100));
   }
   return newPrice;

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
    address oldOwner = villainIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose tokens we are interested in.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalVillains = totalSupply();
      uint256 resultIndex = 0;

      uint256 villainId;
      for (villainId = 0; villainId <= totalVillains; villainId++) {
        if (villainIndexToOwner[villainId] == _owner) {
          result[resultIndex] = villainId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return villains.length;
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
    return villainIndexToApproved[_tokenId] == _to;
  }



  /// For creating Villains
  function _createVillain(string _name, address _owner, uint256 _price, uint256 _class, uint256 _level) private {

    Villain memory _villain = Villain({
      name: _name,
      class: _class,
      level: _level,
      numSkillActive: 0,
      state: 0,
      zappedExipryTime: 0,
      affectedByToken: 0,
      buyPrice: 0,
      id: villains.length-1
    });
    uint256 newVillainId = villains.push(_villain) - 1;
    villains[newVillainId].id=newVillainId;

    // It's probably never going to happen, 4 billion tokens are A LOT, but
    // let's just be 100% sure we never let this happen.
    require(newVillainId == uint256(uint32(newVillainId)));

    Birth(newVillainId, _name, _owner);

    villainIndexToPrice[newVillainId] = _price;

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newVillainId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == villainIndexToOwner[_tokenId];
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  /// @dev Assigns ownership of a specific Villain to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of villains is capped to 2^32 we can't overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    villainIndexToOwner[_tokenId] = _to;

    // When creating new villains _from is 0x0, but we can't account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete villainIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }

    // utility to round to the game precision
    function roundIt(uint256 amount) internal constant returns (uint256)
    {
        // round down to correct preicision
        uint256 result = (amount/precision)*precision;
        return result;
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