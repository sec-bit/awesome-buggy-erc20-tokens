pragma solidity ^0.4.18;

contract ERC721 {
    // ERC20 compatible functions
    // use variable getter
    // function name() constant returns (string name);
    // function symbol() constant returns (string symbol);
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint balance);
    function ownerOf(uint256 _tokenId) public constant returns (address owner);
    function approve(address _to, uint256 _tokenId) public ;
    function allowance(address _owner, address _spender) public constant returns (uint256 tokenId);
    function transfer(address _to, uint256 _tokenId) external ;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    
    // Optional
    // function takeOwnership(uint256 _tokenId) public ;
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external constant returns (uint tokenId);
    // function tokenMetadata(uint256 _tokenId) public constant returns (string infoUrl);
    
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}

contract ERC20 {
    // Get the total token supply
    function totalSupply() public constant returns (uint256 _totalSupply);
 
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    // transfer _value amount of token approved by address _from
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    // approve an address with _value amount of tokens
    function approve(address _spender, uint256 _value) public returns (bool success);

    // get remaining token approved by _owner to _spender
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract VirtualGift is ERC721 {
    
    // load GTO to Virtual Gift contract, to interact with GTO
    ERC20 GTO = ERC20(0x00C5bBaE50781Be1669306b9e001EFF57a2957b09d);
    
    // Gift data
    struct Gift {
        // gift price
        uint256 price;
        // gift description
        string description;
    }
    
    address public owner;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _GiftId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _GiftId);
    event Creation(address indexed _owner, uint256 indexed GiftId);
    
    string public constant name = "VirtualGift";
    string public constant symbol = "VTG";
    
    // Gift object storage in array
    Gift[] giftStorage;
    
    // total Gift of an address
    mapping(address => uint256) private balances;
    
    // index of Gift array to Owner
    mapping(uint256 => address) private GiftIndexToOwners;
    
    // Gift exist or not
    mapping(uint256 => bool) private GiftExists;
    
    // mapping from owner and approved address to GiftId
    mapping(address => mapping (address => uint256)) private allowed;
    
    // mapping from owner and index Gift of owner to GiftId
    mapping(address => mapping(uint256 => uint256)) private ownerIndexToGifts;
    
    // Gift metadata
    mapping(uint256 => string) GiftLinks;

    modifier onlyOwner(){
         require(msg.sender == owner);
         _;
    }

    modifier onlyGiftOwner(uint256 GiftId){
        require(msg.sender == GiftIndexToOwners[GiftId]);
        _;
    }
    
    modifier validGift(uint256 GiftId){
        require(GiftExists[GiftId]);
        _;
    }

    /// @dev constructor
    function VirtualGift()
    public{
        owner = msg.sender;
        // save temporaryly new Gift
        Gift memory newGift = Gift({
            price: 0,
            description: "MYTHICAL"
        });
        // push to array and return the length is the id of new Gift
        uint256 mythicalGift = giftStorage.push(newGift) - 1; // id = 0
        // mythical Gift is not exist
        GiftExists[mythicalGift] = false;
        // assign url for Gift
        GiftLinks[mythicalGift] = "mythicalGift";
        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, msg.sender, mythicalGift);
        // event create new Gift for msg.sender
        Creation(msg.sender, mythicalGift);
    }
    
    /// @dev this function change GTO address, this mean you can use many token to buy gift
    /// by change GTO address to BNB address
    /// @param newAddress is new address of GTO or another Gift like BNB
    function changeGTOAddress(address newAddress)
    public
    onlyOwner{
        GTO = ERC20(newAddress);
    }
    
    /// @dev return current GTO address
    function getGTOAddress()
    public
    constant
    returns (address) {
        return address(GTO);
    }
    
    /// @dev return total supply of Gift
    /// @return length of Gift storage array, except Gift Zero
    function totalSupply()
    public 
    constant
    returns (uint256){
        // exclusive Gift Zero
        return giftStorage.length - 1;
    }
    
    /// @dev allow people to buy Gift
    /// @param GiftId : id of gift user want to buy
    function buy(uint256 GiftId) 
    validGift(GiftId)
    public {
        // get old owner of Gift
        address oldowner = ownerOf(GiftId);
        // tell gifto transfer GTO from new owner to oldowner
        // NOTE: new owner MUST approve for Virtual Gift contract to take his balance
        require(GTO.transferFrom(msg.sender, oldowner, giftStorage[GiftId].price) == true);
        // assign new owner for GiftId
        // TODO: old owner should have something to confirm that he want to sell this Gift
        _transfer(oldowner, msg.sender, GiftId);
    }
    
    /// @dev owner send gift to recipient when VG was approved
    /// @param recipient : received gift
    /// @param GiftId : id of gift which recipient want to buy
    function sendGift(address recipient, uint256 GiftId)
    onlyGiftOwner(GiftId)
    validGift(GiftId)
    public {
        // transfer GTO to owner
        // require(GTO.transfer(msg.sender, giftStorage[GiftId].price) == true);
        // transfer gift to recipient
        _transfer(msg.sender, recipient, GiftId);
    }
    
    /// @dev get total Gift of an address
    /// @param _owner to get balance
    /// @return balance of an address
    function balanceOf(address _owner) 
    public 
    constant 
    returns (uint256 balance){
        return balances[_owner];
    }
    
    function isExist(uint256 GiftId)
    public
    constant
    returns(bool){
        return GiftExists[GiftId];
    }
    
    /// @dev get owner of an Gift id
    /// @param _GiftId : id of Gift to get owner
    /// @return owner : owner of an Gift id
    function ownerOf(uint256 _GiftId)
    public
    constant 
    returns (address _owner) {
        require(GiftExists[_GiftId]);
        return GiftIndexToOwners[_GiftId];
    }
    
    /// @dev approve Gift id from msg.sender to an address
    /// @param _to : address is approved
    /// @param _GiftId : id of Gift in array
    function approve(address _to, uint256 _GiftId)
    validGift(_GiftId)
    public {
        require(msg.sender == ownerOf(_GiftId));
        require(msg.sender != _to);
        
        allowed[msg.sender][_to] = _GiftId;
        Approval(msg.sender, _to, _GiftId);
    }
    
    /// @dev get id of Gift was approved from owner to spender
    /// @param _owner : address owner of Gift
    /// @param _spender : spender was approved
    /// @return GiftId
    function allowance(address _owner, address _spender) 
    public 
    constant 
    returns (uint256 GiftId) {
        return allowed[_owner][_spender];
    }
    
    /// @dev a spender take owner ship of Gift id, when he was approved
    /// @param _GiftId : id of Gift has being takeOwnership
    function takeOwnership(uint256 _GiftId)
    validGift(_GiftId)
    public {
        // get oldowner of Giftid
        address oldOwner = ownerOf(_GiftId);
        // new owner is msg sender
        address newOwner = msg.sender;
        
        require(newOwner != oldOwner);
        // newOwner must be approved by oldOwner
        require(allowed[oldOwner][newOwner] == _GiftId);

        // transfer Gift for new owner
        _transfer(oldOwner, newOwner, _GiftId);

        // delete approve when being done take owner ship
        delete allowed[oldOwner][newOwner];

        Transfer(oldOwner, newOwner, _GiftId);
    }
    
    /// @dev transfer ownership of a specific Gift to an address.
    /// @param _from : address owner of Giftid
    /// @param _to : address's received
    /// @param _GiftId : Gift id
    function _transfer(address _from, address _to, uint256 _GiftId) 
    internal {
        // Since the number of Gift is capped to 2^32 we can't overflow this
        balances[_to]++;
        // transfer ownership
        GiftIndexToOwners[_GiftId] = _to;
        // When creating new Gift _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            balances[_from]--;
        }
        // Emit the transfer event.
        Transfer(_from, _to, _GiftId);
    }
    
    /// @dev transfer ownership of Giftid from msg sender to an address
    /// @param _to : address's received
    /// @param _GiftId : Gift id
    function transfer(address _to, uint256 _GiftId)
    validGift(_GiftId)
    external {
        // not transfer to zero
        require(_to != 0x0);
        // address received different from sender
        require(msg.sender != _to);
        // sender must be owner of Giftid
        require(msg.sender == ownerOf(_GiftId));
        // do not send to Gift contract
        require(_to != address(this));
        
        _transfer(msg.sender, _to, _GiftId);
    }
    
    /// @dev transfer Giftid was approved by _from to _to
    /// @param _from : address owner of Giftid
    /// @param _to : address is received
    /// @param _GiftId : Gift id
    function transferFrom(address _from, address _to, uint256 _GiftId)
    validGift(_GiftId)
    external {
        require(_from == ownerOf(_GiftId));
        // Check for approval and valid ownership
        require(allowance(_from, msg.sender) == _GiftId);
        // address received different from _owner
        require(_from != _to);
        
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any Gift
        require(_to != address(this));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _GiftId);
    }
    
    /// @dev Returns a list of all Gift IDs assigned to an address.
    /// @param _owner The owner whose Gift we are interested in.
    /// @notice This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire Gift array looking for Gift belonging to owner),
    /// @return ownerGifts : list Gift of owner
    function GiftsOfOwner(address _owner) 
    public 
    view 
    returns(uint256[] ownerGifts) {
        
        uint256 GiftCount = balanceOf(_owner);
        if (GiftCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](GiftCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all Gift have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint256 GiftId;
            
            // scan array and filter Gift of owner
            for (GiftId = 0; GiftId <= total; GiftId++) {
                if (GiftIndexToOwners[GiftId] == _owner) {
                    result[resultIndex] = GiftId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
    
    /// @dev Returns a Gift IDs assigned to an address.
    /// @param _owner The owner whose Gift we are interested in.
    /// @param _index to owner Gift list
    /// @notice This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire Gift array looking for Gift belonging to owner),
    ///  it is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function giftOwnerByIndex(address _owner, uint256 _index)
    external
    constant 
    returns (uint256 GiftId) {
        uint256[] memory ownerGifts = GiftsOfOwner(_owner);
        return ownerGifts[_index];
    }
    
    /// @dev get Gift metadata (url) from GiftLinks
    /// @param _GiftId : Gift id
    /// @return infoUrl : url of Gift
    function GiftMetadata(uint256 _GiftId)
    public
    constant
    returns (string infoUrl) {
        return GiftLinks[_GiftId];
    }
    
    /// @dev function create new Gift
    /// @param _price : Gift property
    /// @param _description : Gift property
    /// @return GiftId
    function createGift(uint256 _price, string _description, string _url)
    public
    onlyOwner
    returns (uint256) {
        // save temporarily new Gift
        Gift memory newGift = Gift({
            price: _price,
            description: _description
        });
        // push to array and return the length is the id of new Gift
        uint256 newGiftId = giftStorage.push(newGift) - 1;
        // turn on existen
        GiftExists[newGiftId] = true;
        // assin gift url
        GiftLinks[newGiftId] = _url;
        // event create new Gift for msg.sender
        Creation(msg.sender, newGiftId);
        
        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, msg.sender, newGiftId);
        
        return newGiftId;
    }
    
    /// @dev get Gift property
    /// @param GiftId : id of Gift
    /// @return properties of Gift
    function getGift(uint256 GiftId)
    public
    constant 
    returns (uint256, string){
        if(GiftId > giftStorage.length){
            return (0, "");
        }
        Gift memory newGift = giftStorage[GiftId];
        return (newGift.price, newGift.description);
    }
    
    /// @dev change gift properties
    /// @param GiftId : to change
    /// @param _price : new price of gift
    /// @param _description : new description
    /// @param _giftUrl : new url 
    function updateGift(uint256 GiftId, uint256 _price, string _description, string _giftUrl)
    public
    onlyOwner {
        // check Gift exist First
        require(GiftExists[GiftId]);
        // setting new properties
        giftStorage[GiftId].price = _price;
        giftStorage[GiftId].description = _description;
        GiftLinks[GiftId] = _giftUrl;
    }
    
    /// @dev remove gift 
    /// @param GiftId : gift id to remove
    function removeGift(uint256 GiftId)
    public
    onlyOwner {
        // just setting GiftExists equal to false
        GiftExists[GiftId] = false;
    }
    
    /// @dev withdraw GTO in this contract
    function withdrawGTO()
    onlyOwner
    public {
        GTO.transfer(owner, GTO.balanceOf(address(this)));
    }
    
}