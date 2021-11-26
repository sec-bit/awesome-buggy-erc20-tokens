pragma solidity ^0.4.19;

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

contract Ownable {

  address public contractOwner;

  event ContractOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    contractOwner = msg.sender;
  }

  modifier onlyContractOwner() {
    require(msg.sender == contractOwner);
    _;
  }

  function transferContractOwnership(address _newOwner) public onlyContractOwner {
    require(_newOwner != address(0));
    ContractOwnershipTransferred(contractOwner, _newOwner);
    contractOwner = _newOwner;
  }
  
  function payoutFromContract() public onlyContractOwner {
      contractOwner.transfer(this.balance);
  }  

}

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
  // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

contract KittyEthPics is ERC721, Ownable {

  event KittyCreated(uint256 tokenId, string name, address owner);
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);
  event Transfer(address from, address to, uint256 tokenId);

  string public constant NAME = "KittyEthPics";
  string public constant SYMBOL = "KittyPicsToken";

  uint256 private startingPrice = 0.01 ether;

  mapping (uint256 => address) public kittyIdToOwner;

  mapping (uint256 => address) public kittyIdToDivs;

  mapping (address => uint256) private ownershipTokenCount;

  mapping (uint256 => address) public kittyIdToApproved;

  mapping (uint256 => uint256) private kittyIdToPrice;

  /*** DATATYPES ***/
  struct Kitty {
    string name;
  }

  Kitty[] private kitties;

  function approve(address _to, uint256 _tokenId) public { //ERC721
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));
    kittyIdToApproved[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

  function balanceOf(address _owner) public view returns (uint256 balance) { //ERC721
    return ownershipTokenCount[_owner];
  }

  function createKittyToken(string _name, uint256 _price) private {
    _createKitty(_name, msg.sender, _price);
  }

  function create21KittiesTokens() public onlyContractOwner {
     uint256 totalKitties = totalSupply();
	 
	 require (totalKitties<1); // only 21 tokens for start
	 
	 for (uint8 i=1; i<=21; i++)
		_createKitty("EthKitty", address(this), startingPrice);
	
  }
  
  function getKitty(uint256 _tokenId) public view returns (string kittyName, uint256 sellingPrice, address owner) {
    Kitty storage kitty = kitties[_tokenId];
    kittyName = kitty.name;
    sellingPrice = kittyIdToPrice[_tokenId];
    owner = kittyIdToOwner[_tokenId];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  function name() public pure returns (string) { //ERC721
    return NAME;
  }

  function ownerOf(uint256 _tokenId) public view returns (address owner) { //ERC721
    owner = kittyIdToOwner[_tokenId];
    require(owner != address(0));
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = kittyIdToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = kittyIdToPrice[_tokenId];

    require(oldOwner != newOwner);
    require(_addressNotNull(newOwner));
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 8), 10)); //80% to previous owner
    uint256 divs_payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 1), 10)); //10% divs
    
	address divs_address = kittyIdToDivs[_tokenId];
	
    // Next price will rise on 300%
    kittyIdToPrice[_tokenId] = uint256(SafeMath.mul(sellingPrice, 3));

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //
    }

    // Pay winner tokenOwner if owner is not contract
    if (divs_address != address(this)) {
      divs_address.transfer(divs_payment); //
    }

    TokenSold(_tokenId, sellingPrice, kittyIdToPrice[_tokenId], oldOwner, newOwner, kitties[_tokenId].name);
	
    if (msg.value > sellingPrice) { //if excess pay
	    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
		msg.sender.transfer(purchaseExcess);
	}
  }
  
  function changeKitty(uint256 _tokenId) public payable { //

    require(kittyIdToOwner[_tokenId] == msg.sender && msg.value == 20 finney); //tax 0.02eth for change
	
	uint256 newPrice =  SafeMath.div(kittyIdToPrice[_tokenId], 2);
    
    //get two kitties within one
	createKittyToken("EthKitty", newPrice);
	createKittyToken("EthKitty", newPrice);
	
	kittyIdToOwner[_tokenId] = address(this); //return changed kitty to kittypics
	kittyIdToPrice[_tokenId] = 10 finney;
	 
  }


  function symbol() public pure returns (string) { //ERC721
    return SYMBOL;
  }


  function takeOwnership(uint256 _tokenId) public { //ERC721
    address newOwner = msg.sender;
    address oldOwner = kittyIdToOwner[_tokenId];

    require(_addressNotNull(newOwner));
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) { //for web site view
    return kittyIdToPrice[_tokenId];
  }

  function ALLownersANDprices(uint256 _startKittyId) public view returns (address[] owners, address[] divs, uint256[] prices) { //for web site view
	
	uint256 totalKitties = totalSupply();
	
    if (totalKitties == 0 || _startKittyId >= totalKitties) {
        // Return an empty array
      return (new address[](0),new address[](0),new uint256[](0));
    }
	
	uint256 indexTo;
	if (totalKitties > _startKittyId+1000)
		indexTo = _startKittyId + 1000;
	else 	
		indexTo = totalKitties;
		
    uint256 totalResultKitties = indexTo - _startKittyId;		
		
	address[] memory owners_res = new address[](totalResultKitties);
	address[] memory divs_res = new address[](totalResultKitties);
	uint256[] memory prices_res = new uint256[](totalResultKitties);
	
	for (uint256 kittyId = _startKittyId; kittyId < indexTo; kittyId++) {
	  owners_res[kittyId - _startKittyId] = kittyIdToOwner[kittyId];
	  divs_res[kittyId - _startKittyId] = kittyIdToDivs[kittyId];
	  prices_res[kittyId - _startKittyId] = kittyIdToPrice[kittyId];
	}
	
	return (owners_res, divs_res, prices_res);
  }
  
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerToken) { //ERC721 for web site view
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalKitties = totalSupply();
      uint256 resultIndex = 0;

      uint256 kittyId;
      for (kittyId = 0; kittyId <= totalKitties; kittyId++) {
        if (kittyIdToOwner[kittyId] == _owner) {
          result[resultIndex] = kittyId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  function totalSupply() public view returns (uint256 total) { //ERC721
    return kitties.length;
  }

  function transfer(address _to, uint256 _tokenId) public { //ERC721
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

	_transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public { //ERC721
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }


  /* PRIVATE FUNCTIONS */
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return kittyIdToApproved[_tokenId] == _to;
  }

  function _createKitty(string _name, address _owner, uint256 _price) private {
    Kitty memory _kitty = Kitty({
      name: _name
    });
    uint256 newKittyId = kitties.push(_kitty) - 1;

    require(newKittyId == uint256(uint32(newKittyId))); //check maximum limit of tokens

    KittyCreated(newKittyId, _name, _owner);

    kittyIdToPrice[newKittyId] = _price;
	kittyIdToDivs[newKittyId] = _owner; //dividents address;

    _transfer(address(0), _owner, newKittyId);
  }

  function _owns(address _checkedAddr, uint256 _tokenId) private view returns (bool) {
    return _checkedAddr == kittyIdToOwner[_tokenId];
  }

function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownershipTokenCount[_to]++;
    kittyIdToOwner[_tokenId] = _to;

    // When creating new kitties _from is 0x0, but we can't account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete kittyIdToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
}