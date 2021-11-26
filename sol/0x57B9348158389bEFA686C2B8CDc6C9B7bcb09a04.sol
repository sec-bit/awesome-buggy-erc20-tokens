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

contract DoggyEthPics is ERC721, Ownable {

  event DoggyCreated(uint256 tokenId, string name, address owner);
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);
  event Transfer(address from, address to, uint256 tokenId);

  string public constant NAME = "DoggyEthPics";
  string public constant SYMBOL = "DoggyPicsToken";

  uint256 private startingPrice = 0.01 ether;

  mapping (uint256 => address) public doggyIdToOwner;

  mapping (uint256 => address) public doggyIdToDivs;

  mapping (address => uint256) private ownershipTokenCount;

  mapping (uint256 => address) public doggyIdToApproved;

  mapping (uint256 => uint256) private doggyIdToPrice;

  /*** DATATYPES ***/
  struct Doggy {
    string name;
  }

  Doggy[] private doggies;

  function approve(address _to, uint256 _tokenId) public { //ERC721
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));
    doggyIdToApproved[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

  function balanceOf(address _owner) public view returns (uint256 balance) { //ERC721
    return ownershipTokenCount[_owner];
  }

  function createDoggyToken(string _name, uint256 _price) private {
    _createDoggy(_name, msg.sender, _price);
  }

  function create3DoggiesTokens() public onlyContractOwner { //migration
	  _createDoggy("EthDoggy", 0xe6c58f8e459fe570afff5b4622990ea1744f0e28, 384433593750000000);
	  _createDoggy("EthDoggy", 0x5632ca98e5788eddb2397757aa82d1ed6171e5ad, 384433593750000000);
	  _createDoggy("EthDoggy", 0x7cd84443027d2e19473c3657f167ada34417654f, 576650390625000000);
	
  }
  
  function getDoggy(uint256 _tokenId) public view returns (string doggyName, uint256 sellingPrice, address owner) {
    Doggy storage doggy = doggies[_tokenId];
    doggyName = doggy.name;
    sellingPrice = doggyIdToPrice[_tokenId];
    owner = doggyIdToOwner[_tokenId];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  function name() public pure returns (string) { //ERC721
    return NAME;
  }

  function ownerOf(uint256 _tokenId) public view returns (address owner) { //ERC721
    owner = doggyIdToOwner[_tokenId];
    require(owner != address(0));
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = doggyIdToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = doggyIdToPrice[_tokenId];

    require(oldOwner != newOwner);
    require(_addressNotNull(newOwner));
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 9), 10)); //90% to previous owner
    uint256 divs_payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 1), 20)); //5% divs
    
	address divs_address = doggyIdToDivs[_tokenId];
	
    // Next price will rise on 50%
    doggyIdToPrice[_tokenId] = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 3), 2)); 

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //
    }

    // Pay winner tokenOwner if owner is not contract
    if (divs_address != address(this)) {
      divs_address.transfer(divs_payment); //
    }

    TokenSold(_tokenId, sellingPrice, doggyIdToPrice[_tokenId], oldOwner, newOwner, doggies[_tokenId].name);
	
    if (msg.value > sellingPrice) { //if excess pay
	    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
		msg.sender.transfer(purchaseExcess);
	}
  }
  
  function changeDoggy(uint256 _tokenId) public payable { //
    require(doggyIdToPrice[_tokenId] >= 500 finney);
	
    require(doggyIdToOwner[_tokenId] == msg.sender && msg.value == 20 finney); //tax 0.02eth for change
	
	uint256 newPrice1 =  uint256(SafeMath.div(SafeMath.mul(doggyIdToPrice[_tokenId], 3), 10)); //30%
	uint256 newPrice2 =  uint256(SafeMath.div(SafeMath.mul(doggyIdToPrice[_tokenId], 7), 10)); //70%
    
    //get two doggies within one
	createDoggyToken("EthDoggy", newPrice1);
	createDoggyToken("EthDoggy", newPrice2);
	
	doggyIdToOwner[_tokenId] = address(this); //return changed doggy to doggypics
	doggyIdToPrice[_tokenId] = 10 finney;
	 
  }


  function symbol() public pure returns (string) { //ERC721
    return SYMBOL;
  }


  function takeOwnership(uint256 _tokenId) public { //ERC721
    address newOwner = msg.sender;
    address oldOwner = doggyIdToOwner[_tokenId];

    require(_addressNotNull(newOwner));
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) { //for web site view
    return doggyIdToPrice[_tokenId];
  }

  function ALLownersANDprices(uint256 _startDoggyId) public view returns (address[] owners, address[] divs, uint256[] prices) { //for web site view
	
	uint256 totalDoggies = totalSupply();
	
    if (totalDoggies == 0 || _startDoggyId >= totalDoggies) {
        // Return an empty array
      return (new address[](0),new address[](0),new uint256[](0));
    }
	
	uint256 indexTo;
	if (totalDoggies > _startDoggyId+1000)
		indexTo = _startDoggyId + 1000;
	else 	
		indexTo = totalDoggies;
		
    uint256 totalResultDoggies = indexTo - _startDoggyId;		
		
	address[] memory owners_res = new address[](totalResultDoggies);
	address[] memory divs_res = new address[](totalResultDoggies);
	uint256[] memory prices_res = new uint256[](totalResultDoggies);
	
	for (uint256 doggyId = _startDoggyId; doggyId < indexTo; doggyId++) {
	  owners_res[doggyId - _startDoggyId] = doggyIdToOwner[doggyId];
	  divs_res[doggyId - _startDoggyId] = doggyIdToDivs[doggyId];
	  prices_res[doggyId - _startDoggyId] = doggyIdToPrice[doggyId];
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
      uint256 totalDoggies = totalSupply();
      uint256 resultIndex = 0;

      uint256 doggyId;
      for (doggyId = 0; doggyId <= totalDoggies; doggyId++) {
        if (doggyIdToOwner[doggyId] == _owner) {
          result[resultIndex] = doggyId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  function totalSupply() public view returns (uint256 total) { //ERC721
    return doggies.length;
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
    return doggyIdToApproved[_tokenId] == _to;
  }

  function _createDoggy(string _name, address _owner, uint256 _price) private {
    Doggy memory _doggy = Doggy({
      name: _name
    });
    uint256 newDoggyId = doggies.push(_doggy) - 1;

    require(newDoggyId == uint256(uint32(newDoggyId))); //check maximum limit of tokens

    DoggyCreated(newDoggyId, _name, _owner);

    doggyIdToPrice[newDoggyId] = _price;
	
	if (newDoggyId<3) //migration
		doggyIdToDivs[newDoggyId] = 0xa828476505d3b4db07aca0b69726eca39e5dea50; //dividents address;
	else 
		doggyIdToDivs[newDoggyId] = _owner; //dividents address;

    _transfer(address(0), _owner, newDoggyId);
  }

  function _owns(address _checkedAddr, uint256 _tokenId) private view returns (bool) {
    return _checkedAddr == doggyIdToOwner[_tokenId];
  }

function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownershipTokenCount[_to]++;
    doggyIdToOwner[_tokenId] = _to;

    // When creating new doggies _from is 0x0, but we can't account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete doggyIdToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
}