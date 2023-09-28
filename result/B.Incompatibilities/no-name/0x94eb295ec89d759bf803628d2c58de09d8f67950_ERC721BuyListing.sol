pragma solidity ^0.4.18;

contract Token {

    function totalSupply() constant returns (uint supply) {}
    function balanceOf(address _owner) constant returns (uint balance) {}
    function transfer(address _to, uint _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {}
    function approve(address _spender, uint _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
contract ERC721 {
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract ERC721BuyListing is Ownable {
    struct Listing {
        address seller;
        uint256 price;
        uint256 dateStarts;
        uint256 dateEnds;
    }
    ERC721 public sourceContract;
    uint256 public ownerPercentage;
    mapping (uint256 => Listing) tokenIdToListing;

    string constant public version = "1.0.0";
    event ListingCreated(uint256 indexed tokenId, uint256 price, uint256 dateStarts, uint256 dateEnds, address indexed seller);
    event ListingCancelled(uint256 indexed tokenId, uint256 dateCancelled);
    event ListingBought(uint256 indexed tokenId, uint256 price, uint256 dateBought, address buyer);

    function ERC721BuyListing(address targetContract, uint256 percentage) public {
        ownerPercentage = percentage;
        ERC721 contractPassed = ERC721(targetContract);
        sourceContract = contractPassed;
    }
    function owns(address claimant, uint256 tokenId) internal view returns (bool) {
        return (sourceContract.ownerOf(tokenId) == claimant);
    }

    function updateOwnerPercentage(uint256 percentage) external onlyOwner {
        ownerPercentage = percentage;
    }

    function withdrawBalance() onlyOwner external {
        assert(owner.send(this.balance));
    }
    function approveToken(address token, uint256 amount) onlyOwner external {
        assert(Token(token).approve(owner, amount));
    }

    function() external payable { }

    function createListing(uint256 tokenId, uint256 price, uint256 dateEnds) external {
        require(owns(msg.sender, tokenId));
        require(price > 0);
        Listing memory listing = Listing(msg.sender, price, now, dateEnds);
        tokenIdToListing[tokenId] = listing;
        ListingCreated(tokenId, listing.price, now, dateEnds, listing.seller);
    }

    function buyListing(uint256 tokenId) external payable {
        Listing storage listing = tokenIdToListing[tokenId];
        require(msg.value == listing.price);
        require(now <= listing.dateEnds);
        address seller = listing.seller;
        uint256 currentPrice = listing.price;
        delete tokenIdToListing[tokenId];
        sourceContract.transferFrom(seller, msg.sender, tokenId);
        seller.transfer(currentPrice - (currentPrice * ownerPercentage / 10000));
        ListingBought(tokenId, listing.price, now, msg.sender);

    }

    function cancelListing(uint256 tokenId) external {
        Listing storage listing = tokenIdToListing[tokenId];
        require(msg.sender == listing.seller || msg.sender == owner);
        delete tokenIdToListing[tokenId];
        ListingCancelled(tokenId, now);
    }
}