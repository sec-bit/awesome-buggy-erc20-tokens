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
    function transfer(address _to, uint256 _tokenId) external returns (bool success);
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
    string public name = "VirtualGift";             
    uint8 public decimals = 0;                
    string public symbol = "VTG";                 
    string public version = "1.0";  

    address private defaultGiftOwner;
    
    mapping(address => bool) allowPermission;

    ERC20 private Gifto = ERC20(0x00C5bBaE50781Be1669306b9e001EFF57a2957b09d);
    
    event Creation(address indexed _owner, uint256 indexed tokenId);
    //Gift token storage.
    GiftToken[] giftStorageArry;
    //Gift template storage.
    GiftTemplateToken[] giftTemplateStorageArry;
    //mapping address to it's gift sum
    mapping(address => uint256) private balances;
    //mapping gift id to owner
    mapping(uint256 => address) private giftIndexToOwners;
    //tells the gift is existed by gift id
    mapping(uint256 => bool) private giftExists;
    //mapping current owner to approved owners to gift
    mapping(address => mapping (address => uint256)) private ownerToApprovedAddsToGifIds;
    //mapping gift template id to gift ids
    mapping(uint256 => uint256[]) private giftTemplateIdToGiftids;
    //Mapping gift type to gift limit.
    mapping(uint256 => uint256) private giftTypeToGiftLimit;

    
    //mapping gift template to gift selled sum.
    mapping(uint256 => uint256) private giftTypeToSelledSum;

    //Gift template known as 0 generation gift
    struct GiftTemplateToken {
        uint256 giftPrice;
        uint256 giftLimit;
        //gift image url
        string giftImgUrl;
        //gift animation url
        string giftName;
    }
    //virtual gift token
    struct GiftToken {
        uint256 giftPrice;
        uint256 giftType;
        //gift image url
        string giftImgUrl;
        //gift animation url
        string giftName;
    }     

    modifier onlyHavePermission(){
        require(allowPermission[msg.sender] == true || msg.sender == defaultGiftOwner);
        _;
    }

    modifier onlyOwner(){
         require(msg.sender == defaultGiftOwner);
         _;
    }

    //@dev Constructor 
    function VirtualGift() public {

        defaultGiftOwner = msg.sender;
        
        GiftToken memory newGift = GiftToken({
            giftPrice: 0,
            giftType: 0,
            giftImgUrl: "",
            giftName: ""
        });

         GiftTemplateToken memory newGiftTemplate = GiftTemplateToken({
                giftPrice: 0,
                giftLimit: 0,
                giftImgUrl: "",
                giftName: ""
            });
        
        giftStorageArry.push(newGift); // id = 0
        giftTemplateStorageArry.push(newGiftTemplate);
       
    }

    function addPermission(address _addr) 
    public 
    onlyOwner{
        allowPermission[_addr] = true;
    }
    
    function removePermission(address _addr) 
    public 
    onlyOwner{
        allowPermission[_addr] = false;
    }


     ///@dev Buy a gift while create a new gift based on gift template.
     ///Make sure to call Gifto.approve() fist, before calling this function
    function sendGift(uint256 _type, 
                      address recipient)
                     public 
                     onlyHavePermission
                     returns(uint256 _giftId)
                     {
        //Check if the created gifts sum <  gift Limit
        require(giftTypeToSelledSum[_type] < giftTemplateStorageArry[_type].giftLimit);
         //_type must be a valid value
        require(_type > 0 && _type < giftTemplateStorageArry.length);
        //Mint a virtual gift.
        _giftId = _mintGift(_type, recipient);
        giftTypeToSelledSum[_type]++;
        return _giftId;
    }

    /// @dev Mint gift.
    function _mintGift(uint256 _type, 
                       address recipient)
                     internal returns (uint256) 
                     {

        GiftToken memory newGift = GiftToken({
            giftPrice: giftTemplateStorageArry[_type].giftPrice,
            giftType: _type,
            giftImgUrl: giftTemplateStorageArry[_type].giftImgUrl,
            giftName: giftTemplateStorageArry[_type].giftName
        });
        
        uint256 giftId = giftStorageArry.push(newGift) - 1;
        //Add giftid to gift template mapping 
        giftTemplateIdToGiftids[_type].push(giftId);
        giftExists[giftId] = true;
        //Reassign Ownership for new owner
        _transfer(0, recipient, giftId);
        //Trigger Ethereum Event
        Creation(msg.sender, giftId);
        return giftId;
    }

    /// @dev Initiate gift template.
    /// A gift template means a gift of "0" generation's
    function createGiftTemplate(uint256 _price,
                         uint256 _limit, 
                         string _imgUrl,
                         string _giftName) 
                         public onlyHavePermission
                         returns (uint256 giftTemplateId)
                         {
        //Check these variables
        require(_price > 0);
        bytes memory imgUrlStringTest = bytes(_imgUrl);
        bytes memory giftNameStringTest = bytes(_giftName);
        require(imgUrlStringTest.length > 0);
        require(giftNameStringTest.length > 0);
        require(_limit > 0);
        require(msg.sender != address(0));
        //Create GiftTemplateToken
        GiftTemplateToken memory newGiftTemplate = GiftTemplateToken({
                giftPrice: _price,
                giftLimit: _limit,
                giftImgUrl: _imgUrl,
                giftName: _giftName
        });
        //Push GiftTemplate into storage.
        giftTemplateId = giftTemplateStorageArry.push(newGiftTemplate) - 1;
        giftTypeToGiftLimit[giftTemplateId] = _limit;
        return giftTemplateId;
        
    }
    
    function updateTemplate(uint256 templateId, 
                            uint256 _newPrice, 
                            uint256 _newlimit, 
                            string _newUrl, 
                            string _newName)
    public
    onlyOwner {
        giftTemplateStorageArry[templateId].giftPrice = _newPrice;
        giftTemplateStorageArry[templateId].giftLimit = _newlimit;
        giftTemplateStorageArry[templateId].giftImgUrl = _newUrl;
        giftTemplateStorageArry[templateId].giftName = _newName;
    }
    
    function getGiftSoldFromType(uint256 giftType)
    public
    constant
    returns(uint256){
        return giftTypeToSelledSum[giftType];
    }

    //@dev Retrieving gifts by template.
    function getGiftsByTemplateId(uint256 templateId) 
    public 
    constant 
    returns(uint256[] giftsId) {
        return giftTemplateIdToGiftids[templateId];
    }
 
    //@dev Retrievings all gift template ids
    function getAllGiftTemplateIds() 
    public 
    constant 
    returns(uint256[]) {
        
        if (giftTemplateStorageArry.length > 1) {
            uint256 theLength = giftTemplateStorageArry.length - 1;
            uint256[] memory resultTempIds = new uint256[](theLength);
            uint256 resultIndex = 0;
           
            for (uint256 i = 1; i <= theLength; i++) {
                resultTempIds[resultIndex] = i;
                resultIndex++;
            }
             return resultTempIds;
        }
        require(giftTemplateStorageArry.length > 1);
       
    }

    //@dev Retrieving gift template by it's id
    function getGiftTemplateById(uint256 templateId) 
                                public constant returns(
                                uint256 _price,
                                uint256 _limit,
                                string _imgUrl,
                                string _giftName
                                ){
        require(templateId > 0);
        require(templateId < giftTemplateStorageArry.length);
        GiftTemplateToken memory giftTemplate = giftTemplateStorageArry[templateId];
        _price = giftTemplate.giftPrice;
        _limit = giftTemplate.giftLimit;
        _imgUrl = giftTemplate.giftImgUrl;
        _giftName = giftTemplate.giftName;
        return (_price, _limit, _imgUrl, _giftName);
    }

    /// @dev Retrieving gift info by gift id.
    function getGift(uint256 _giftId) 
                    public constant returns (
                    uint256 giftType,
                    uint256 giftPrice,
                    string imgUrl,
                    string giftName
                    ) {
        require(_giftId < giftStorageArry.length);
        GiftToken memory gToken = giftStorageArry[_giftId];
        giftType = gToken.giftType;
        giftPrice = gToken.giftPrice;
        imgUrl = gToken.giftImgUrl;
        giftName = gToken.giftName;
        return (giftType, giftPrice, imgUrl, giftName);
    }

    /// @dev transfer gift to a new owner.
    /// @param _to : 
    /// @param _giftId :
    function transfer(address _to, uint256 _giftId) external returns (bool success){
        require(giftExists[_giftId]);
        require(_to != 0x0);
        require(msg.sender != _to);
        require(msg.sender == ownerOf(_giftId));
        require(_to != address(this));
        _transfer(msg.sender, _to, _giftId);
        return true;
    }

    /// @dev change Gifto contract's address or another type of token, like Ether.
    /// @param newAddress Gifto contract address
    function setGiftoAddress(address newAddress) public onlyOwner {
        Gifto = ERC20(newAddress);
    }
    
    /// @dev Retrieving Gifto contract adress
    function getGiftoAddress() public constant returns (address giftoAddress) {
        return address(Gifto);
    }

    /// @dev returns total supply for this token
    function totalSupply() public  constant returns (uint256){
        return giftStorageArry.length - 1;
    }
    
    //@dev 
    //@param _owner 
    //@return 
    function balanceOf(address _owner)  public  constant  returns (uint256 giftSum) {
        return balances[_owner];
    }
    
    /// @dev 
    /// @return owner
    function ownerOf(uint256 _giftId) public constant returns (address _owner) {
        require(giftExists[_giftId]);
        return giftIndexToOwners[_giftId];
    }
    
    /// @dev approved owner 
    /// @param _to :
    function approve(address _to, uint256 _giftId) public {
        require(msg.sender == ownerOf(_giftId));
        require(msg.sender != _to);
        
        ownerToApprovedAddsToGifIds[msg.sender][_to] = _giftId;
        //Ethereum Event
        Approval(msg.sender, _to, _giftId);
    }
    
    /// @dev 
    /// @param _owner : 
    /// @param _spender :
    function allowance(address _owner, address _spender) public constant returns (uint256 giftId) {
        return ownerToApprovedAddsToGifIds[_owner][_spender];
    }
    
    /// @dev 
    /// @param _giftId :
    function takeOwnership(uint256 _giftId) public {
        //Check if exits
        require(giftExists[_giftId]);
        
        address oldOwner = ownerOf(_giftId);
        address newOwner = msg.sender;
        
        require(newOwner != oldOwner);
        //New owner has to be approved by oldowner.
        require(ownerToApprovedAddsToGifIds[oldOwner][newOwner] == _giftId);

        //transfer gift for new owner
        _transfer(oldOwner, newOwner, _giftId);
        delete ownerToApprovedAddsToGifIds[oldOwner][newOwner];
        //Ethereum Event
        Transfer(oldOwner, newOwner, _giftId);
    }
    
    /// @dev transfer gift for new owner "_to"
    /// @param _from : 
    /// @param _to : 
    /// @param _giftId :
    function _transfer(address _from, address _to, uint256 _giftId) internal {
        require(balances[_to] + 1 > balances[_to]);
        balances[_to]++;
        giftIndexToOwners[_giftId] = _to;
   
        if (_from != address(0)) {
            balances[_from]--;
        }
        
        //Ethereum event.
        Transfer(_from, _to, _giftId);
    }
    
    /// @dev transfer Gift for new owner(_to) which is approved.
    /// @param _from : address of owner of gift
    /// @param _to : recipient address
    /// @param _giftId : gift id
    function transferFrom(address _from, address _to, uint256 _giftId) external {

        require(_to != address(0));
        require(_to != address(this));
        //Check if this spender(_to) is approved to the gift.
        require(ownerToApprovedAddsToGifIds[_from][_to] == _giftId);
        require(_from == ownerOf(_giftId));

        //@dev reassign ownership of the gift. 
        _transfer(_from, _to, _giftId);
        //Delete approved spender
        delete ownerToApprovedAddsToGifIds[_from][_to];
    }
    
    /// @dev Retrieving gifts by address _owner
    function giftsOfOwner(address _owner)  public view returns (uint256[] ownerGifts) {
        
        uint256 giftCount = balanceOf(_owner);
        if (giftCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](giftCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;

            uint256 giftId;
            
            for (giftId = 0; giftId <= total; giftId++) {
                if (giftIndexToOwners[giftId] == _owner) {
                    result[resultIndex] = giftId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
     
    /// @dev withdraw GTO and ETH in this contract 
    function withdrawGTO() 
    onlyOwner 
    public { 
        Gifto.transfer(defaultGiftOwner, Gifto.balanceOf(address(this))); 
    }
    
    function withdraw()
    onlyOwner
    public
    returns (bool){
        return defaultGiftOwner.send(this.balance);
    }
}