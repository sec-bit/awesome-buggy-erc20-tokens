pragma solidity ^0.4.18;

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
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
contract ListingsERC20 is Ownable {
      using SafeMath for uint256;

    struct Listing {
        address seller;
        address tokenContractAddress;
        uint256 price;
        uint256 allowance;
        uint256 dateStarts;
        uint256 dateEnds;
    }
    event ListingCreated(bytes32 indexed listingId, address tokenContractAddress, uint256 price, uint256 allowance, uint256 dateStarts, uint256 dateEnds, address indexed seller);
    event ListingCancelled(bytes32 indexed listingId, uint256 dateCancelled);
    event ListingBought(bytes32 indexed listingId, address tokenContractAddress, uint256 price, uint256 amount, uint256 dateBought, address buyer);

    string constant public VERSION = "1.0.0";
    uint16 constant public GAS_LIMIT = 4999;
    uint256 public ownerPercentage;
    mapping (bytes32 => Listing) public listings;
    mapping (bytes32 => uint256) public sold;
    function ListingsERC20(uint256 percentage) public {
        ownerPercentage = percentage;
    }

    function updateOwnerPercentage(uint256 percentage) external onlyOwner {
        ownerPercentage = percentage;
    }

    function withdrawBalance() onlyOwner external {
        assert(owner.send(this.balance));
    }
    function approveToken(address token, uint256 amount) onlyOwner external {
        assert(ERC20(token).approve(owner, amount));
    }

    function() external payable { }

    function getHash(address tokenContractAddress, uint256 price, uint256 allowance, uint256 dateEnds, uint256 salt) external view returns (bytes32) {
        return getHashInternal(tokenContractAddress, price, allowance, dateEnds, salt);
    }

    function getHashInternal(address tokenContractAddress, uint256 price, uint256 allowance, uint256 dateEnds, uint256 salt) internal view returns (bytes32) {
        return keccak256(msg.sender, tokenContractAddress, price, allowance, dateEnds, salt);
    }
    function getBalance(address tokenContract, address seller) internal constant returns (uint256) {
        return ERC20(tokenContract).balanceOf.gas(GAS_LIMIT)(seller);
    }
    function getAllowance(address tokenContract, address seller, address listingContract) internal constant returns (uint256) {
        return ERC20(tokenContract).allowance.gas(GAS_LIMIT)(seller, listingContract);
    }

    function createListing(address tokenContractAddress, uint256 price, uint256 allowance, uint256 dateEnds, uint256 salt) external {
        require(price > 0);
        require(allowance > 0);
        require(dateEnds > 0);
        require(getBalance(tokenContractAddress, msg.sender) > allowance);
        require(getAllowance(tokenContractAddress, msg.sender, this) <= allowance);
        bytes32 listingId = getHashInternal(tokenContractAddress, price, allowance, dateEnds, salt);
        Listing memory listing = Listing(msg.sender, tokenContractAddress, price, allowance, now, dateEnds);
        listings[listingId] = listing;
        ListingCreated(listingId, tokenContractAddress, price, allowance, now, dateEnds, msg.sender);

    }

    function cancelListing(bytes32 listingId) external {
        Listing storage listing = listings[listingId];
        require(msg.sender == listing.seller);
        delete listings[listingId];
        ListingCancelled(listingId, now);
    }
    function buyListing(bytes32 listingId, uint256 amount) external payable {
        Listing storage listing = listings[listingId];
        address seller = listing.seller;
        address contractAddress = listing.tokenContractAddress;
        uint256 price = listing.price;
        uint256 sale = price.mul(amount);
        uint256 allowance = listing.allowance;
        require(now <= listing.dateEnds);
        require(allowance - sold[listingId] > amount);
        require(allowance - amount > 0);
        require(getBalance(contractAddress, seller) > allowance);
        require(getAllowance(contractAddress, seller, this) <= allowance);
        require(msg.value == sale);
        ERC20 tokenContract = ERC20(contractAddress);
        require(tokenContract.transferFrom(seller, msg.sender, amount));
        seller.transfer(sale - (sale.mul(ownerPercentage).div(10000)));
        sold[listingId] = allowance.sub(amount);
        ListingBought(listingId, contractAddress, price, amount, now, msg.sender);
    }

}