pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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



contract ERC20Basic {
  uint256 public totalSupply;
  uint8 public decimals;
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

    string constant public VERSION = "1.0.1";
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
    function getDecimals(address tokenContract) internal constant returns (uint256) {
        return ERC20(tokenContract).decimals.gas(GAS_LIMIT)();
    }

    function createListing(address tokenContractAddress, uint256 price, uint256 allowance, uint256 dateEnds, uint256 salt) external {
        require(price > 0);
        require(allowance > 0);
        require(dateEnds > 0);
        require(getBalance(tokenContractAddress, msg.sender) >= allowance);
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
        uint256 decimals = getDecimals(listing.tokenContractAddress);
        uint256 factor = 10 ** decimals;
        uint256 sale;
        if (decimals > 0) {
            sale = price.mul(amount).div(factor);
        } else {
            sale = price.mul(amount);
        } 
        uint256 allowance = listing.allowance;
        //make sure listing is still available
        require(now <= listing.dateEnds);
        //make sure there are still enough to sell from this listing
        require(allowance - sold[listingId] >= amount);
        //make sure that the seller still has that amount to sell
        require(getBalance(contractAddress, seller) >= amount);
        //make sure that the seller still will allow that amount to be sold
        require(getAllowance(contractAddress, seller, this) >= amount);
        require(msg.value == sale);
        ERC20 tokenContract = ERC20(contractAddress);
        require(tokenContract.transferFrom(seller, msg.sender, amount));
        if (ownerPercentage > 0) {
            seller.transfer(sale - (sale.mul(ownerPercentage).div(10000)));
        } else {
            seller.transfer(sale);
        }
        sold[listingId] = sold[listingId].add(amount);
        ListingBought(listingId, contractAddress, price, amount, now, msg.sender);
    }

}