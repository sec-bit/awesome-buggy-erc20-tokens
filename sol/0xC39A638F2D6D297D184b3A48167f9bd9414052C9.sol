pragma solidity ^0.4.18;

///>[ Crypto Brands ]>>>>

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
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

contract EtherBrand is ERC721 {

  /*** EVENTS ***/
  event Birth(uint256 tokenId, bytes32 name, address owner);
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, bytes32 name);
  event Transfer(address from, address to, uint256 tokenId);

  /*** STRUCTS ***/
  struct Brand {
    bytes32 name;
    address owner;
    uint256 price;
    uint256 last_price;
    address approve_transfer_to;
  }
  
  struct TopOwner {
    address addr;
    uint256 price;
  }

  /*** CONSTANTS ***/
  string public constant NAME = "EtherBrands";
  string public constant SYMBOL = "EtherBrand";
  
  bool public gameOpen = false;

  /*** STORAGE ***/
  mapping (address => uint256) private ownerCount;
  mapping (uint256 => TopOwner) private topOwner;
  mapping (uint256 => address) private lastBuyer;

  address public ceoAddress;
  address public cooAddress;
  address public cfoAddress;
  mapping (uint256 => address) public extra;
  
  uint256 brand_count;
  uint256 lowest_top_brand;
 
  mapping (uint256 => Brand) private brands;
  //Brand[] public brands;

  /*** ACCESS MODIFIERS ***/
  modifier onlyCEO() { require(msg.sender == ceoAddress); _; }
  modifier onlyCOO() { require(msg.sender == cooAddress); _; }
  modifier onlyCXX() { require(msg.sender == ceoAddress || msg.sender == cooAddress); _; }

  /*** ACCESS MODIFIES ***/
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }
  function setCFO(address _newCFO) public onlyCEO {
    require(_newCFO != address(0));
    cfoAddress = _newCFO;
  }
  function setExtra(uint256 _id, address _newExtra) public onlyCXX {
    require(_newExtra != address(0));
    // failsave :3 require(_id <= 2); // 3 = 1 ETH, 4 = 2.5 ETH, 5 = 5 ETH
    extra[_id] = _newExtra;
  }

  /*** DEFAULT METHODS ***/
  function symbol() public pure returns (string) { return SYMBOL; }
  function name() public pure returns (string) { return NAME; }
  function implementsERC721() public pure returns (bool) { return true; }

  /*** CONSTRUCTOR ***/
  function EtherBrand() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    cfoAddress = msg.sender;
    topOwner[1] = TopOwner(msg.sender, 500000000000000000); // 0.5
    topOwner[2] = TopOwner(msg.sender, 100000000000000000); // 0.1
    topOwner[3] = TopOwner(msg.sender, 50000000000000000); // 0.05
    topOwner[4] = TopOwner(msg.sender, 0);
    topOwner[5] = TopOwner(msg.sender, 0);
    lastBuyer[1] = msg.sender;
    lastBuyer[2] = msg.sender;
    lastBuyer[3] = msg.sender;
    extra[1] = msg.sender;
    extra[2] = msg.sender;
    extra[3] = msg.sender;
    extra[4] = msg.sender;
    extra[5] = msg.sender;
  }

  /*** INTERFACE METHODS ***/

  function createBrand(bytes32 _name, uint256 _price) public onlyCXX {
    require(msg.sender != address(0));
    _create_brand(_name, address(this), _price);
  }

  function createPromoBrand(bytes32 _name, address _owner, uint256 _price) public onlyCXX {
    require(msg.sender != address(0));
    require(_owner != address(0));
    _create_brand(_name, _owner, _price);
  }

  function openGame() public onlyCXX {
    require(msg.sender != address(0));
    gameOpen = true;
  }

  function totalSupply() public view returns (uint256 total) {
    return brand_count;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownerCount[_owner];
  }
  function priceOf(uint256 _brand_id) public view returns (uint256 price) {
    return brands[_brand_id].price;
  }

  function getBrand(uint256 _brand_id) public view returns (
    uint256 id,
    bytes32 brand_name,
    address owner,
    uint256 price,
    uint256 last_price
  ) {
    id = _brand_id;
    brand_name = brands[_brand_id].name;
    owner = brands[_brand_id].owner;
    price = brands[_brand_id].price;
    last_price = brands[_brand_id].last_price;
  }
  
  function getBrands() public view returns (uint256[], bytes32[], address[], uint256[]) {
    uint256[] memory ids = new uint256[](brand_count);
    bytes32[] memory names = new bytes32[](brand_count);
    address[] memory owners = new address[](brand_count);
    uint256[] memory prices = new uint256[](brand_count);
    for(uint256 _id = 0; _id < brand_count; _id++){
      ids[_id] = _id;
      names[_id] = brands[_id].name;
      owners[_id] = brands[_id].owner;
      prices[_id] = brands[_id].price;
    }
    return (ids, names, owners, prices);
  }
  
  function purchase(uint256 _brand_id) public payable {
    require(gameOpen == true);
    Brand storage brand = brands[_brand_id];

    require(brand.owner != msg.sender);
    require(msg.sender != address(0));
    require(msg.value >= brand.price);

    uint256 excess = SafeMath.sub(msg.value, brand.price);
    uint256 half_diff = SafeMath.div(SafeMath.sub(brand.price, brand.last_price), 2);
    uint256 reward = SafeMath.add(half_diff, brand.last_price);

    topOwner[1].addr.transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 15)));  // 15%
    topOwner[2].addr.transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 12)));  // 12%
    topOwner[3].addr.transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 9)));   // 9%
    topOwner[4].addr.transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 5)));   // 5%
    topOwner[5].addr.transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 2)));   // 2% == 43%
  
    lastBuyer[1].transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 20))); // 20%
    lastBuyer[2].transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 15))); // 15%
    lastBuyer[3].transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 10))); // 10% == 45%
  
    extra[1].transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 1)));      // 1%
    extra[2].transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 1)));      // 1%
    extra[3].transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 1)));      // 1%
    extra[4].transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 1)));      // 1%
    extra[5].transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 1)));      // 1%
    
    cfoAddress.transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 6)));    // 6%
    cooAddress.transfer(uint256(SafeMath.mul(SafeMath.div(half_diff, 100), 1)));    // 1%

    if(brand.owner == address(this)){
      cfoAddress.transfer(reward);
    } else {
      brand.owner.transfer(reward);
    }
    
    if(brand.price > topOwner[5].price){
        for(uint8 i = 1; i <= 5; i++){
            if(brand.price > topOwner[(i+1)].price){
                if(i <= 1){ topOwner[2] = topOwner[1]; }
                if(i <= 2){ topOwner[3] = topOwner[2]; }
                if(i <= 3){ topOwner[4] = topOwner[3]; }
                if(i <= 4){ topOwner[5] = topOwner[4]; }
                topOwner[i] = TopOwner(msg.sender, brand.price);
                break;
            }
        }
    }
    
    if(extra[3] == ceoAddress && brand.price >= 1000000000000000000){ extra[3] == msg.sender; } // 1 ETH
    if(extra[4] == ceoAddress && brand.price >= 2500000000000000000){ extra[4] == msg.sender; } // 2.5 ETH
    if(extra[5] == ceoAddress && brand.price >= 5000000000000000000){ extra[5] == msg.sender; } // 5 ETH
    
    brand.last_price = brand.price;
    address _old_owner = brand.owner;
    
    if(brand.price < 50000000000000000){ // 0.05
        brand.price = SafeMath.mul(SafeMath.div(brand.price, 100), 150);
    } else {
        brand.price = SafeMath.mul(SafeMath.div(brand.price, 100), 125);
    }
    brand.owner = msg.sender;

    lastBuyer[3] = lastBuyer[2];
    lastBuyer[2] = lastBuyer[1];
    lastBuyer[1] = msg.sender;

    Transfer(_old_owner, brand.owner, _brand_id);
    TokenSold(_brand_id, brand.last_price, brand.price, _old_owner, brand.owner, brand.name);

    msg.sender.transfer(excess);
  }

  function payout() public onlyCEO {
    cfoAddress.transfer(this.balance);
  }

  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 resultIndex = 0;
      for (uint256 brandId = 0; brandId <= totalSupply(); brandId++) {
        if (brands[brandId].owner == _owner) {
          result[resultIndex] = brandId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /*** ERC-721 compliance. ***/

  function approve(address _to, uint256 _brand_id) public {
    require(msg.sender == brands[_brand_id].owner);
    brands[_brand_id].approve_transfer_to = _to;
    Approval(msg.sender, _to, _brand_id);
  }
  function ownerOf(uint256 _brand_id) public view returns (address owner){
    owner = brands[_brand_id].owner;
    require(owner != address(0));
  }
  function takeOwnership(uint256 _brand_id) public {
    address oldOwner = brands[_brand_id].owner;
    require(msg.sender != address(0));
    require(brands[_brand_id].approve_transfer_to == msg.sender);
    _transfer(oldOwner, msg.sender, _brand_id);
  }
  function transfer(address _to, uint256 _brand_id) public {
    require(msg.sender != address(0));
    require(msg.sender == brands[_brand_id].owner);
    _transfer(msg.sender, _to, _brand_id);
  }
  function transferFrom(address _from, address _to, uint256 _brand_id) public {
    require(_from == brands[_brand_id].owner);
    require(brands[_brand_id].approve_transfer_to == _to);
    require(_to != address(0));
    _transfer(_from, _to, _brand_id);
  }

  /*** PRIVATE METHODS ***/

  function _create_brand(bytes32 _name, address _owner, uint256 _price) private {
    // Params: name, owner, price, is_for_sale, is_public, share_price, increase, fee, share_count,
    brands[brand_count] = Brand({
      name: _name,
      owner: _owner,
      price: _price,
      last_price: 0,
      approve_transfer_to: address(0)
    });
    Birth(brand_count, _name, _owner);
    Transfer(address(this), _owner, brand_count);
    brand_count++;
  }

  function _transfer(address _from, address _to, uint256 _brand_id) private {
    brands[_brand_id].owner = _to;
    brands[_brand_id].approve_transfer_to = address(0);
    ownerCount[_from] -= 1;
    ownerCount[_to] += 1;
    Transfer(_from, _to, _brand_id);
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}