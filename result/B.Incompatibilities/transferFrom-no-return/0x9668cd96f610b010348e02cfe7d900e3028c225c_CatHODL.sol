pragma solidity ^0.4.18;
contract ERC721 {
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}
contract Owned {
    address public owner;

    function Owned () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    function changeOwner (address newOwner) public onlyOwner {
        owner = newOwner;
    }
}
contract Targeted is Owned {
    ERC721 public target;
    function changeTarget (address newTarget) public onlyOwner {
        target = ERC721(newTarget);
    }
}
contract CatHODL is Targeted {
    uint public releaseDate;
    mapping (uint => address) public catOwners;
    function CatHODL () public {
        releaseDate = now + 1 years;
    }
    function bringCat (uint catId) public {
        require(now < releaseDate ); // If you can get it anytime, its not forced HODL!
        catOwners[catId] = msg.sender; // Set the user as owner.
        target.transferFrom(msg.sender, this, catId); // Get the cat, throws if fails
    }
    function getCat (uint catId) public {
        require(catOwners[catId] == msg.sender);
        require(now >= releaseDate);
        catOwners[catId] = 0x0;
        target.transfer(msg.sender, catId);
    }
    function doSuicide () public onlyOwner {
        selfdestruct(owner);
    }
}