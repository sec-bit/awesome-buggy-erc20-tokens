pragma solidity ^0.4.18; // solhint-disable-line




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
  event Dissolved(address  owner, uint256 tokenId);
  event TransferDissolved(address indexed from, address indexed to, uint256 tokenId);
  
}


contract CryptoStamps is ERC721 {

  
  /*** EVENTS ***/

  
  /// @dev The Birth event is fired whenever a new stamp is created.
  event stampBirth(uint256 tokenId,  address owner);

  /// @dev The TokenSold event is fired whenever a stamp is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner);

  /// @dev Transfer event as defined in current draft of ERC721. 
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);



  
  /*** CONSTANTS ***/


  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CryptoStamps"; // 
  string public constant SYMBOL = "CS"; // 
  
  // @dev firstStepLimit for the change in rate of price increase
  uint256 private firstStepLimit =  1.28 ether;
  


  
  
  /*** STORAGE ***/



  /// @dev A mapping from stamp IDs to the address that owns them. All stamps have
  ///  some valid owner address.
  mapping (uint256 => address) public stampIndexToOwner;
  

  // @dev A mapping from owner address to count of stamps that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from stamp IDs to an address that has been approved to call
  ///  transferFrom(). Each stamp can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public stampIndexToApproved;

  // @dev A mapping from stamp IDs to the price of the token.
  mapping (uint256 => uint256) private stampIndexToPrice;
  
  
  
  //@dev A mapping from stamp IDs to the number of transactions that the stamp has gone through. 
  mapping(uint256 => uint256) public stampIndextotransactions;
  
  //@dev To calculate the total ethers transacted in the game.
  uint256 public totaletherstransacted;

  //@dev To calculate the total transactions in the game.
  uint256 public totaltransactions;
  
  //@dev To calculate the total stamps created.
  uint256 public stampCreatedCount;
  
  
  

 /*** STORAGE FOR DISSOLVED ***/
 
 
 //@dev A mapping from stamp IDs to their dissolved status.
  //Initially all values are set to false by default
  mapping (uint256 => bool) public stampIndextodissolved;
 
 
 //@dev A mapping from dissolved stamp IDs to their approval status.
  //Initially all values are set to false by default
 mapping (uint256 => address) public dissolvedIndexToApproved;
 
  
  
  
  /*** DATATYPES ***/
  
  struct Stamp {
    uint256 birthtime;
  }
  
  

  Stamp[] private stamps;

 
 
 
 
  
  
  
  /*** ACCESS MODIFIERS ***/
  
  /// @dev Access modifier for CEO-only functionality
  
  
  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;
  bool private paused;
  
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
  
  
  
  /*** CONSTRUCTOR ***/
  function CryptoStamps() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    paused = false;
  }

  
  
  
  
  /*** PUBLIC FUNCTIONS ***/
  /// @notice Grant another address the right to transfer stamp via takeOwnership() and transferFrom().
  
  ///  clear all approvals.
  
  /// @dev Required for ERC-721 compliance.
  
  
  //@dev to pause and unpause the contract in emergency situations
  function pausecontract() public onlyCLevel
  {
      paused = true;
  }
  
  
  
  function unpausecontract() public onlyCEO
  {
      paused = false;
      
  }
  
  
  
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
    // Caller must own token.
    require(paused == false);
    require(_owns(msg.sender, _tokenId));

    stampIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  
  
  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  
  
  
  
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  
  
  //@dev To create a stamp.
  function createStamp(address _owner,  uint256 _price) public onlyCOO {
    
    require(paused == false);
    address stampOwner = _owner;
    if (stampOwner == address(0)) {
      stampOwner = cooAddress;
    }

    require(_price >= 0);

    stampCreatedCount++;
    _createStamp( stampOwner, _price);
  }

  
 
  //@dev To get stamp information
  
  function getStamp(uint256 _tokenId) public view returns (
    uint256 birthtimestamp,
    uint256 sellingPrice,
    address owner
  ) {
    Stamp storage stamp = stamps[_tokenId];
    birthtimestamp = stamp.birthtime;
    sellingPrice = stampIndexToPrice[_tokenId];
    owner = stampIndexToOwner[_tokenId];
  }

  
  
  
  function implementsERC721() public pure returns (bool) {
    return true;
  }

  
  
  /// @dev Required for ERC-721 compliance.
  
  
  
  
  function name() public pure returns (string) {
    return NAME;
  }

  
  
  /// For querying owner of stamp
  /// @param _tokenId The tokenID for owner inquiry
  /// @dev Required for ERC-721 compliance.
  
  
  
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = stampIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  
  
  //@dev To payout to an address
  
  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }
  
  
  
  
  
  
  //@ To set the cut received by smart contract
  uint256 private cut;
  
  
  
  
  function setcut(uint256 cutowner) onlyCEO public returns(uint256)
  { 
      cut = cutowner;
      return(cut);
      
  }

  
  
  
  
  // Allows someone to send ether and obtain the token
  
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = stampIndexToOwner[_tokenId];
    address newOwner = msg.sender;
    require(stampIndextodissolved[_tokenId] == false);
    require(paused == false);
    uint256 sellingPrice = stampIndexToPrice[_tokenId];
    totaletherstransacted = totaletherstransacted + sellingPrice;

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, cut), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    // Update prices
    if (sellingPrice < firstStepLimit) {
      // first stage
      stampIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), cut);
    } 
    else {
      
      stampIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 125), cut);
    }

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //(1-0.06)
    }

    TokenSold(_tokenId, sellingPrice, stampIndexToPrice[_tokenId], oldOwner, newOwner);

    msg.sender.transfer(purchaseExcess);
  }

  
  
  
  //@dev To get price of a stamp
  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return stampIndexToPrice[_tokenId];
  }

  
  
  //@dev To get the next price of a stamp
  function nextpriceOf(uint256 _tokenId) public view returns (uint256 price) {
    uint256 currentsellingPrice = stampIndexToPrice[_tokenId];
    
    if (currentsellingPrice < firstStepLimit) {
      // first stage
      return SafeMath.div(SafeMath.mul(currentsellingPrice, 200), cut);
    } 
    else {
      
      return SafeMath.div(SafeMath.mul(currentsellingPrice, 125), cut);
    }
    
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
    address oldOwner = stampIndexToOwner[_tokenId];
    require(paused == false);
    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  
  
  
  /// @param _owner The owner of the stamp
  /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
  ///  expensive (it walks the entire Stamps array looking for stamps belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  
  
  
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalStamps = totalSupply();
      uint256 resultIndex = 0;

      uint256 stampId;
      for (stampId = 0; stampId <= totalStamps; stampId++) {
        if (stampIndexToOwner[stampId] == _owner) {
          result[resultIndex] = stampId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  
  
  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  
  
  
  function totalSupply() public view returns (uint256 total) {
    return stamps.length;
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
    require(paused == false);

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
  
  
  //@dev To set the number in which the stamp gets dissolved into.
  uint256 private num;
  
  
  
  function setnumber(uint256 number) onlyCEO public returns(uint256)
  {
      num = number;
      return num;
  }
  
  
  //@dev To set the price at which dissolution starts.
   uint256 private priceatdissolution;
  
  
  
  function setdissolveprice(uint256 number) onlyCEO public returns(uint256)
  {
      priceatdissolution = number;
      return priceatdissolution;
  }
  
  
  //@ To set the address to which dissolved stamp is sent.
  address private addressatdissolution;
  
  
  
  function setdissolveaddress(address dissolveaddress) onlyCEO public returns(address)
  {
      addressatdissolution = dissolveaddress;
      return addressatdissolution;
  }
  
  
  //@dev for emergency purposes
  function controlstampdissolution(bool control,uint256 _tokenId) onlyCEO public
  {
      stampIndextodissolved[_tokenId] = control;
      
  }
  
  
  //@dev Dissolve function which mines new stamps.
  function dissolve(uint256 _tokenId) public
  {   require(paused == false);
      require(stampIndexToOwner[_tokenId] == msg.sender);
      require(priceOf(_tokenId)>= priceatdissolution );
      require(stampIndextodissolved[_tokenId] == false);
      address reciever = stampIndexToOwner[_tokenId];
      
      uint256 price = priceOf(_tokenId);
      uint256 newprice = SafeMath.div(price,num);
      
      approve(addressatdissolution, _tokenId);
      transfer(addressatdissolution,_tokenId);
      stampIndextodissolved[_tokenId] = true;
      
      uint256 i;
      for(i = 0; i<num; i++)
      {
      _createStamp( reciever, newprice);
          
      }
      Dissolved(msg.sender,_tokenId);
    
  }
  
 //@dev The contract which is used to interact with dissolved stamps.
 address private dissolvedcontract; 
 
 
 
 
 /*** PUBLIC FUNCTIONS FOR DISSOLVED STAMPS ***/
 
 
 function setdissolvedcontract(address dissolvedaddress) onlyCEO public returns(address)
 {
     
     dissolvedcontract = dissolvedaddress;
     return dissolvedcontract;
 }
 
 //@dev To transfer dissolved stamp. Requires the contract assigned for dissolution management to send message.
 function transferdissolvedFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(_from, _tokenId));
    require(_addressNotNull(_to));
    require(msg.sender == dissolvedcontract);

    _transferdissolved(_from, _to, _tokenId);
  }
  
  


  
  
  
  
  
  /*** PRIVATE FUNCTIONS ***/
  /// Safety check on _to address to prevent against an unexpected 0x0 default.
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  
  
  /// For checking approval of transfer for address _to
  
  
  
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return stampIndexToApproved[_tokenId] == _to;
  }

  
  /// For creating Stamp
  
  
  function _createStamp(address _owner, uint256 _price) private {
    Stamp memory _stamp = Stamp({
      birthtime: now
    });
    uint256 newStampId = stamps.push(_stamp) - 1;

    // It's probably never going to happen, 4 billion tokens are A LOT, but
    // let's just be 100% sure we never let this happen.
    require(newStampId == uint256(uint32(newStampId)));

    stampBirth(newStampId, _owner);

    stampIndexToPrice[newStampId] = _price;

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newStampId);
  }

  
  
  /// Check for token ownership
  
  
  
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == stampIndexToOwner[_tokenId];
  }

  
  
  /// For paying out balance on contract
  
  
  
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  
  
  
  /// @dev Assigns ownership of a specific Stamp to an address.
  
  
  
  function _transfer(address _from, address _to, uint256 _tokenId) private {
   
    require(paused == false);
    ownershipTokenCount[_to]++;
    stampIndextotransactions[_tokenId] = stampIndextotransactions[_tokenId] + 1;
    totaltransactions++;
    //transfer ownership
    stampIndexToOwner[_tokenId] = _to;
    

    // When creating new stamps _from is 0x0, but we can't account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete stampIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
  
  
  
/*** PRIVATE FUNCTIONS FOR DISSOLVED STAMPS***/  
  
  
  
  //@ To transfer a dissolved stamp.
  function _transferdissolved(address _from, address _to, uint256 _tokenId) private {
    
    require(stampIndextodissolved[_tokenId] == true);
    require(paused == false);
    ownershipTokenCount[_to]++;
    stampIndextotransactions[_tokenId] = stampIndextotransactions[_tokenId] + 1;
    //transfer ownership
    stampIndexToOwner[_tokenId] = _to;
    totaltransactions++;
    

    // When creating new stamp _from is 0x0, but we can't account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      
    }

    // Emit the transfer event.
    TransferDissolved(_from, _to, _tokenId);
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