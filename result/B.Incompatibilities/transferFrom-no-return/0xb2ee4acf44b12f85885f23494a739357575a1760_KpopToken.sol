pragma solidity ^0.4.18;

// KpopToken is a ERC-721 token (https://github.com/ethereum/eips/issues/721)
// Kpop celebrity cards as digital collectibles
// Kpop.io is the official website

contract ERC721 {
  function approve(address _to, uint _tokenId) public;
  function balanceOf(address _owner) public view returns (uint balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint _tokenId) public view returns (address addr);
  function takeOwnership(uint _tokenId) public;
  function totalSupply() public view returns (uint total);
  function transferFrom(address _from, address _to, uint _tokenId) public;
  function transfer(address _to, uint _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint tokenId);
  event Approval(address indexed owner, address indexed approved, uint tokenId);
}

contract KpopToken is ERC721 {
  address public author;
  address public coauthor;

  string public constant NAME = "Kpopio";
  string public constant SYMBOL = "KpopToken";

  uint public GROWTH_BUMP = 0.1 ether;
  uint public MIN_STARTING_PRICE = 0.002 ether;
  uint public PRICE_INCREASE_SCALE = 120; // 120% of previous price

  struct Celeb {
    string name;
  }

  Celeb[] public celebs;

  mapping(uint => address) public tokenIdToOwner;
  mapping(uint => uint) public tokenIdToPrice; // in wei
  mapping(address => uint) public userToNumCelebs;
  mapping(uint => address) public tokenIdToApprovedRecipient;

  event Transfer(address indexed from, address indexed to, uint tokenId);
  event Approval(address indexed owner, address indexed approved, uint tokenId);
  event CelebSold(uint tokenId, uint oldPrice, uint newPrice, string celebName, address prevOwner, address newOwner);

  function KpopToken() public {
    author = msg.sender;
    coauthor = msg.sender;
  }

  function _transfer(address _from, address _to, uint _tokenId) private {
    require(ownerOf(_tokenId) == _from);
    require(!isNullAddress(_to));
    require(balanceOf(_from) > 0);

    uint prevBalances = balanceOf(_from) + balanceOf(_to);
    tokenIdToOwner[_tokenId] = _to;
    userToNumCelebs[_from]--;
    userToNumCelebs[_to]++;

    // Clear outstanding approvals
    delete tokenIdToApprovedRecipient[_tokenId];

    Transfer(_from, _to, _tokenId);
    
    assert(balanceOf(_from) + balanceOf(_to) == prevBalances);
  }

  function buy(uint _tokenId) payable public {
    address prevOwner = ownerOf(_tokenId);
    uint currentPrice = tokenIdToPrice[_tokenId];

    require(prevOwner != msg.sender);
    require(!isNullAddress(msg.sender));
    require(msg.value >= currentPrice);

    // Take a cut off the payment
    uint payment = uint(SafeMath.div(SafeMath.mul(currentPrice, 92), 100));
    uint leftover = SafeMath.sub(msg.value, currentPrice);
    uint newPrice;

    _transfer(prevOwner, msg.sender, _tokenId);

    if (currentPrice < GROWTH_BUMP) {
      newPrice = SafeMath.mul(currentPrice, 2);
    } else {
      newPrice = SafeMath.div(SafeMath.mul(currentPrice, PRICE_INCREASE_SCALE), 100);
    }

    tokenIdToPrice[_tokenId] = newPrice;

    if (prevOwner != address(this)) {
      prevOwner.transfer(payment);
    }

    CelebSold(_tokenId, currentPrice, newPrice,
      celebs[_tokenId].name, prevOwner, msg.sender);

    msg.sender.transfer(leftover);
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return userToNumCelebs[_owner];
  }

  function ownerOf(uint _tokenId) public view returns (address addr) {
    return tokenIdToOwner[_tokenId];
  }

  function totalSupply() public view returns (uint total) {
    return celebs.length;
  }

  function transfer(address _to, uint _tokenId) public {
    _transfer(msg.sender, _to, _tokenId);
  }

  /** START FUNCTIONS FOR AUTHORS **/

  function createCeleb(string _name, uint _price) public onlyAuthors {
    require(_price >= MIN_STARTING_PRICE);

    uint tokenId = celebs.push(Celeb(_name)) - 1;
    tokenIdToOwner[tokenId] = author;
    tokenIdToPrice[tokenId] = _price;
    userToNumCelebs[author]++;
  }

  function withdraw(uint _amount, address _to) public onlyAuthors {
    require(!isNullAddress(_to));
    require(_amount <= this.balance);

    _to.transfer(_amount);
  }

  function withdrawAll() public onlyAuthors {
    require(author != 0x0);
    require(coauthor != 0x0);

    uint halfBalance = uint(SafeMath.div(this.balance, 2));

    author.transfer(halfBalance);
    coauthor.transfer(halfBalance);
  }

  function setCoAuthor(address _coauthor) public onlyAuthor {
    require(!isNullAddress(_coauthor));

    coauthor = _coauthor;
  }

  /** END FUNCTIONS FOR AUTHORS **/

  function getCeleb(uint _tokenId) public view returns (
    string name,
    uint price,
    address owner
  ) {
    name = celebs[_tokenId].name;
    price = tokenIdToPrice[_tokenId];
    owner = tokenIdToOwner[_tokenId];
  }

  /** START FUNCTIONS RELATED TO EXTERNAL CONTRACT INTERACTIONS **/

  function approve(address _to, uint _tokenId) public {
    require(msg.sender == ownerOf(_tokenId));

    tokenIdToApprovedRecipient[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint _tokenId) public {
    require(ownerOf(_tokenId) == _from);
    require(isApproved(_to, _tokenId));
    require(!isNullAddress(_to));

    _transfer(_from, _to, _tokenId);
  }

  function takeOwnership(uint _tokenId) public {
    require(!isNullAddress(msg.sender));
    require(isApproved(msg.sender, _tokenId));

    address currentOwner = tokenIdToOwner[_tokenId];

    _transfer(currentOwner, msg.sender, _tokenId);
  }

  /** END FUNCTIONS RELATED TO EXTERNAL CONTRACT INTERACTIONS **/

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /** MODIFIERS **/

  modifier onlyAuthor() {
    require(msg.sender == author);
    _;
  }

  modifier onlyAuthors() {
    require(msg.sender == author || msg.sender == coauthor);
    _;
  }

  /** FUNCTIONS THAT WONT BE USED FREQUENTLY **/

  function setMinStartingPrice(uint _price) public onlyAuthors {
    MIN_STARTING_PRICE = _price;
  }

  function setGrowthBump(uint _bump) public onlyAuthors {
    GROWTH_BUMP = _bump;
  }

  function setPriceIncreaseScale(uint _scale) public onlyAuthors {
    PRICE_INCREASE_SCALE = _scale;
  }

  /** PRIVATE FUNCTIONS **/

  function isApproved(address _to, uint _tokenId) private view returns (bool) {
    return tokenIdToApprovedRecipient[_tokenId] == _to;
  }

  function isNullAddress(address _addr) private pure returns (bool) {
    return _addr == 0x0;
  }
}

// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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