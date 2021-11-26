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
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

contract KiddyToys is ERC721, Ownable {

  event ToyCreated(uint256 tokenId, string name, address owner);
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);
  event Transfer(address from, address to, uint256 tokenId);

  string public constant NAME = "KiddyToys";
  string public constant SYMBOL = "ToyToken";

  uint256 private startingPrice = 0.01 ether;

  mapping (uint256 => address) public toyIdToOwner;

  mapping (address => uint256) private ownershipTokenCount;

  mapping (uint256 => address) public toyIdToApproved;

  mapping (uint256 => uint256) private toyIdToPrice;

  /*** DATATYPES ***/
  struct Toy {
    string name;
  }

  Toy[] private toys;

  function approve(address _to, uint256 _tokenId) public { //ERC721
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));
    toyIdToApproved[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

  function balanceOf(address _owner) public view returns (uint256 balance) { //ERC721
    return ownershipTokenCount[_owner];
  }

  function createContractToy(string _name) public onlyContractOwner {
    _createToy(_name, address(this), startingPrice);
  }

  function create20ContractToy() public onlyContractOwner {
     uint256 totalToys = totalSupply();
	 
     require (totalToys < 1);
	 
 	 _createToy("Sandy train", address(this), startingPrice);
 	 _createToy("Red Teddy", address(this), startingPrice);
	 _createToy("Brown Teddy", address(this), startingPrice);
	 _createToy("White Horsy", address(this), startingPrice);
	 _createToy("Blue rocking Horsy", address(this), startingPrice);
	 _createToy("Arch pyramid", address(this), startingPrice);
	 _createToy("Sandy rocking Horsy", address(this), startingPrice);
	 _createToy("Letter cubes", address(this), startingPrice);
	 _createToy("Ride carousel", address(this), startingPrice);
	 _createToy("Town car", address(this), startingPrice);
	 _createToy("Nighty train", address(this), startingPrice);
	 _createToy("Big circles piramid", address(this), startingPrice);
	 _createToy("Small circles piramid", address(this), startingPrice);
	 _createToy("Red lamp", address(this), startingPrice);
	 _createToy("Ducky", address(this), startingPrice);
	 _createToy("Small ball", address(this), startingPrice);
	 _createToy("Big ball", address(this), startingPrice);
	 _createToy("Digital cubes", address(this), startingPrice);
	 _createToy("Small Dolly", address(this), startingPrice);
	 _createToy("Big Dolly", address(this), startingPrice);
  }
  
  function getToy(uint256 _tokenId) public view returns (string toyName, uint256 sellingPrice, address owner) {
    Toy storage toy = toys[_tokenId];
    toyName = toy.name;
    sellingPrice = toyIdToPrice[_tokenId];
    owner = toyIdToOwner[_tokenId];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  function name() public pure returns (string) { //ERC721
    return NAME;
  }

  function ownerOf(uint256 _tokenId) public view returns (address owner) { //ERC721
    owner = toyIdToOwner[_tokenId];
    require(owner != address(0));
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = toyIdToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = toyIdToPrice[_tokenId];

    require(oldOwner != newOwner);
    require(_addressNotNull(newOwner));
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 9), 10)); //90% to previous owner
    uint256 win_payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 9), 180)); //5% to random owner

    uint256 randomToyId = uint256(block.blockhash(block.number-1))%20;
	address winner = toyIdToOwner[randomToyId];
	
    // Next price will in 2 times more.
    toyIdToPrice[_tokenId] = SafeMath.mul(sellingPrice, 2);

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //
    }

    // Pay winner tokenOwner if owner is not contract
    if (winner != address(this)) {
      winner.transfer(win_payment); //
    }

    TokenSold(_tokenId, sellingPrice, toyIdToPrice[_tokenId], oldOwner, newOwner, toys[_tokenId].name);
	
    if (msg.value > sellingPrice) { //if excess pay
	    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
		msg.sender.transfer(purchaseExcess);
	}
  }


  function symbol() public pure returns (string) { //ERC721
    return SYMBOL;
  }


  function takeOwnership(uint256 _tokenId) public { //ERC721
    address newOwner = msg.sender;
    address oldOwner = toyIdToOwner[_tokenId];

    require(_addressNotNull(newOwner));
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) { //for web site view
    return toyIdToPrice[_tokenId];
  }
  
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) { //for web site view
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalToys = totalSupply();
      uint256 resultIndex = 0;

      uint256 toyId;
      for (toyId = 0; toyId <= totalToys; toyId++) {
        if (toyIdToOwner[toyId] == _owner) {
          result[resultIndex] = toyId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  function totalSupply() public view returns (uint256 total) { //ERC721
    return toys.length;
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
    return toyIdToApproved[_tokenId] == _to;
  }

  function _createToy(string _name, address _owner, uint256 _price) private {
    Toy memory _toy = Toy({
      name: _name
    });
    uint256 newToyId = toys.push(_toy) - 1;

    require(newToyId == uint256(uint32(newToyId))); //check maximum limit of tokens

    ToyCreated(newToyId, _name, _owner);

    toyIdToPrice[newToyId] = _price;

    _transfer(address(0), _owner, newToyId);
  }

  function _owns(address _checkedAddr, uint256 _tokenId) private view returns (bool) {
    return _checkedAddr == toyIdToOwner[_tokenId];
  }

function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownershipTokenCount[_to]++;
    toyIdToOwner[_tokenId] = _to;

    // When creating new toys _from is 0x0, but we can't account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete toyIdToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
}