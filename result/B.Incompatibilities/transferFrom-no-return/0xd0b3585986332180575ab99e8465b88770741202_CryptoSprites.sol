pragma solidity ^0.4.2;

// The below two interfaces (KittyCore and SaleClockAuction) are from Crypto Kitties. This contract will have to call the Crypto Kitties contracts to find the owner of a Kitty, the properties of a Kitty and a Kitties price.
interface KittyCore {

    function ownerOf (uint256 _tokenId) external view returns (address owner);
    
    function getKitty (uint256 _id) external view returns (bool isGestating, bool isReady, uint256 cooldownIndex, uint256 nextActionAt, uint256 siringWithId, uint256 birthTime, uint256 matronId, uint256 sireId, uint256 generation, uint256 genes);
    
}

interface SaleClockAuction {
    
    function getCurrentPrice (uint256 _tokenId) external view returns (uint256);
    
    function getAuction(uint256 _tokenId) external view returns (address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt);
    
}

// ERC721 token standard is used for non-fungible assets, like Sprites (non-fungible because they can't be split into pieces and don't have equal value). Technically this contract will also be ERC20 compliant.
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    
    function allowance(address _owner, address _spender) view returns (uint remaining);

    // Events
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);

    function name() public view returns (string);
    function symbol() public view returns (string);
    
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract CryptoSprites is ERC721 {
    
    address public owner;
    
    address KittyCoreAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;

    address SaleClockAuctionAddress = 0xb1690C08E213a35Ed9bAb7B318DE14420FB57d8C;

    // 1.5% of Sprite sales to go to Heifer International: https://www.heifer.org/what-you-can-do/give/digital-currency.html (not affiliated with this game)
    address charityAddress = 0xb30cb3b3E03A508Db2A0a3e07BA1297b47bb0fb1;
    
    uint public etherForOwner;
    uint public etherForCharity;
    
    uint public ownerCut = 15; // 1.5% (15/1000 - see the buySprite() function) of Sprite sales go to owner of this contract
    uint public charityCut = 15; // 1.5% of Sprite sales also go to an established charity (Heifer International)
    
    uint public featurePrice = 10**16; // 0.01 Ether to feature a sprite
    
    // With the below the default price of a Sprite of a kitty would be only 10% of the kitties price. If for example priceMultiplier = 15 and priceDivider = 10, then the default price of a sprite would be 1.5 times the price of its kitty. Since Solidity doesn't allow decimals, two numbers are needed for  flexibility in setting the default price a sprite would be in relation to the price of its kitten, in case that's needed later (owner of this contract can change the default price of Sprites anytime). 
    // The default price of a Sprite may easily increase later to be more than 10%
    uint public priceMultiplier = 1;
    uint public priceDivider = 10;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function CryptoSprites() {
        owner = msg.sender;
    }
    
    uint[] public featuredSprites;
    
    uint[] public allPurchasedSprites;
    
    uint public totalFeatures;
    uint public totalBuys;
    
    struct BroughtSprites {
        address owner;
        uint spriteImageID;
        bool forSale;
        uint price;
        uint timesTraded;
        bool featured;
    }
    
    mapping (uint => BroughtSprites) public broughtSprites;
    
    // This may include Sprites the user previously owned but doesn't anymore
    mapping (address => uint[]) public spriteOwningHistory;
    
    mapping (address => uint) public numberOfSpritesOwnedByUser;
    
    // First address is the address of a Sprite owner, second address is an address having approval to move a token belonging to the first address, uint[] is the array of Sprites belonging to the first address that the second address has approval to transfer
    mapping (address => mapping (address => uint[])) public allowed;
    
    bytes4 constant InterfaceSignature_ERC165 = bytes4(keccak256('supportsInterface(bytes4)'));
    
    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)'));

    function() payable {
        
    }
    
    function adjustDefaultSpritePrice (uint _priceMultiplier, uint _priceDivider) onlyOwner {
        require (_priceMultiplier > 0);
        require (_priceDivider > 0);
        priceMultiplier = _priceMultiplier;
        priceDivider = _priceDivider;
    }
    
    function adjustCut (uint _ownerCut, uint _charityCut) onlyOwner {
        require (_ownerCut + _charityCut < 51); // Keep this contract honest by allowing the maximum combined cut to be no more than 5% (50/1000) of sales
        ownerCut = _ownerCut;
        charityCut = _charityCut;
    }
    
    function adjustFeaturePrice (uint _featurePrice) onlyOwner {
        require (_featurePrice > 0);
        featurePrice = _featurePrice;
    }
    
    function withdraw() onlyOwner {
        owner.transfer(etherForOwner);
        charityAddress.transfer(etherForCharity);
        etherForOwner = 0;
        etherForCharity = 0;
    }
    
    function featureSprite (uint spriteId) payable {
        // Do not need to require user to be the owner of a Sprite to feature it
        // require (msg.sender == broughtSprites[spriteId].owner);
        require (msg.value == featurePrice);
        broughtSprites[spriteId].featured = true;

        if (broughtSprites[spriteId].timesTraded == 0) {
            address kittyOwner = KittyCore(KittyCoreAddress).ownerOf(spriteId);
            uint priceIfAny = SaleClockAuction(SaleClockAuctionAddress).getCurrentPrice(spriteId);
            
            // When featuring a Sprite that hasn't been traded before, if the original Kitty is for sale, update this Sprite with a price and set forSale = true - as long as msg.sender is the owner of the Kitty. Otherwise it could be that the owner of the Kitty removed the Sprite for sale and a different user could feature the Sprite and have it listed for sale
            if (priceIfAny > 0 && msg.sender == kittyOwner) {
                broughtSprites[spriteId].price = priceIfAny * priceMultiplier / priceDivider;
                broughtSprites[spriteId].forSale = true;
            }
            
            broughtSprites[spriteId].owner = kittyOwner;
            broughtSprites[spriteId].spriteImageID = uint(block.blockhash(block.number-1))%360 + 1;
            
            numberOfSpritesOwnedByUser[kittyOwner]++;
        }
        
        totalFeatures++;
        etherForOwner += msg.value;
        featuredSprites.push(spriteId);
    }
    
    function buySprite (uint spriteId) payable {
        
        uint _ownerCut;
        uint _charityCut;
        
        if (broughtSprites[spriteId].forSale == true) {
            
            // Buying a sprite that has been purchased or featured before, from a player of this game who has listed it for sale
            
            _ownerCut = ((broughtSprites[spriteId].price / 1000) * ownerCut);
            _charityCut = ((broughtSprites[spriteId].price / 1000) * charityCut);
            
            require (msg.value == broughtSprites[spriteId].price + _ownerCut + _charityCut);
            
            broughtSprites[spriteId].owner.transfer(broughtSprites[spriteId].price);
            
            numberOfSpritesOwnedByUser[broughtSprites[spriteId].owner]--;
            
            if (broughtSprites[spriteId].timesTraded == 0) {
                // Featured sprite that is being purchased for the first time
                allPurchasedSprites.push(spriteId);
            }
            
            Transfer (msg.sender, broughtSprites[spriteId].owner, spriteId);
            
        } else {
            
            // Buying a sprite that has never been brought before, from a kitten currently listed for sale in the CryptoKitties contract. The sale price will go to the owner of the kitten in the CryptoKitties contract (who very possibly would have never even heard of this game)
            
            require (broughtSprites[spriteId].timesTraded == 0);
            require (broughtSprites[spriteId].price == 0);
            
            // Here we are looking up the price of the Sprite's corresponding Kitty
            
            uint priceIfAny = SaleClockAuction(SaleClockAuctionAddress).getCurrentPrice(spriteId);
            require (priceIfAny > 0); // If the kitten in the CryptoKitties contract isn't for sale, a Sprite for it won't be for sale either
            
            _ownerCut = ((priceIfAny / 1000) * ownerCut) * priceMultiplier / priceDivider;
            _charityCut = ((priceIfAny / 1000) * charityCut) * priceMultiplier / priceDivider;
            
            require (msg.value == (priceIfAny * priceMultiplier / priceDivider) + _ownerCut + _charityCut);
            
            address kittyOwner = KittyCore(KittyCoreAddress).ownerOf(spriteId);
            
            kittyOwner.transfer(priceIfAny * priceMultiplier / priceDivider);
            
            allPurchasedSprites.push(spriteId);
            
            broughtSprites[spriteId].spriteImageID = uint(block.blockhash(block.number-1))%360 + 1; // Random number to determine what image/character the sprite will be
            
            Transfer (kittyOwner, msg.sender, spriteId);
            
        }
        
        totalBuys++;
        
        spriteOwningHistory[msg.sender].push(spriteId);
        numberOfSpritesOwnedByUser[msg.sender]++;
        
        broughtSprites[spriteId].owner = msg.sender;
        broughtSprites[spriteId].forSale = false;
        broughtSprites[spriteId].timesTraded++;
        broughtSprites[spriteId].featured = false;
            
        etherForOwner += _ownerCut;
        etherForCharity += _charityCut;
        
    }
    
    // Also used to adjust price if already for sale
    function listSpriteForSale (uint spriteId, uint price) {
        require (price > 0);
        if (broughtSprites[spriteId].owner != msg.sender) {
            require (broughtSprites[spriteId].timesTraded == 0);
            
            // This will be the owner of a Crypto Kitty, who can control the price of their unbrought Sprite
            address kittyOwner = KittyCore(KittyCoreAddress).ownerOf(spriteId);
            require (kittyOwner == msg.sender);
            
            broughtSprites[spriteId].owner = msg.sender;
            broughtSprites[spriteId].spriteImageID = uint(block.blockhash(block.number-1))%360 + 1; 
        }
        broughtSprites[spriteId].forSale = true;
        broughtSprites[spriteId].price = price;
    }
    
    function removeSpriteFromSale (uint spriteId) {
        if (broughtSprites[spriteId].owner != msg.sender) {
            require (broughtSprites[spriteId].timesTraded == 0);
            address kittyOwner = KittyCore(KittyCoreAddress).ownerOf(spriteId);
            require (kittyOwner == msg.sender);
            broughtSprites[spriteId].price = 1; // When a user buys a Sprite Id that isn't for sale in the buySprite() function (ie. would be a Sprite that's never been brought before, for a Crypto Kitty that's for sale), one of the requirements is broughtSprites[spriteId].price == 0, which will be the case by default. By making the price = 1 this will throw and the Sprite won't be able to be brought
        } 
        broughtSprites[spriteId].forSale = false;
    }
    
    // The following functions are in case a different contract wants to pull this data, which requires a function returning it (even if the variables are public) since solidity contracts can't directly pull storage of another contract
    
    function featuredSpritesLength() view external returns (uint) {
        return featuredSprites.length;
    }
    
    function usersSpriteOwningHistory (address user) view external returns (uint[]) {
        return spriteOwningHistory[user];
    }
    
    function lookupSprite (uint spriteId) view external returns (address, uint, bool, uint, uint, bool) {
        return (broughtSprites[spriteId].owner, broughtSprites[spriteId].spriteImageID, broughtSprites[spriteId].forSale, broughtSprites[spriteId].price, broughtSprites[spriteId].timesTraded, broughtSprites[spriteId].featured);
    }
    
    function lookupFeaturedSprites (uint spriteId) view external returns (uint) {
        return featuredSprites[spriteId];
    }
    
    function lookupAllSprites (uint spriteId) view external returns (uint) {
        return allPurchasedSprites[spriteId];
    }
    
    // Will call SaleClockAuction to get the owner of a kitten and check its price (if it's for sale). We're calling the getAuction() function in the SaleClockAuction to get the kitty owner (that function returns 5 variables, we only want the owner). ownerOf() in the KittyCore contract won't return the kitty owner if the kitty is for sale, and this probably won't be used (including it in case it's needed to lookup an owner of a kitty not for sale later for any reason)
    
    function lookupKitty (uint kittyId) view returns (address, uint, address) {
        
        var (kittyOwner,,,,) = SaleClockAuction(SaleClockAuctionAddress).getAuction(kittyId);

        uint priceIfAny = SaleClockAuction(SaleClockAuctionAddress).getCurrentPrice(kittyId);
        
        address kittyOwnerNotForSale = KittyCore(KittyCoreAddress).ownerOf(kittyId);

        return (kittyOwner, priceIfAny, kittyOwnerNotForSale);

    }
    
    // The below two functions will pull all info of a kitten. Split into two functions otherwise stack too deep errors. These may not even be needed, may just be used so the website can display all info of a kitten when someone looks it up.
    
    function lookupKittyDetails1 (uint kittyId) view returns (bool, bool, uint, uint, uint) {
        
        var (isGestating, isReady, cooldownIndex, nextActionAt, siringWithId,,,,,) = KittyCore(KittyCoreAddress).getKitty(kittyId);
        
        return (isGestating, isReady, cooldownIndex, nextActionAt, siringWithId);
        
    }
    
    function lookupKittyDetails2 (uint kittyId) view returns (uint, uint, uint, uint, uint) {
        
        var(,,,,,birthTime, matronId, sireId, generation, genes) = KittyCore(KittyCoreAddress).getKitty(kittyId);
        
        return (birthTime, matronId, sireId, generation, genes);
        
    }
    
    // ERC-721 required functions below
    
    string public name = 'Crypto Sprites';
    string public symbol = 'CRS';
    uint8 public decimals = 0; // Sprites are non-fungible, ie. can't be divided into pieces
    
    function name() public view returns (string) {
        return name;
    }
    
    function symbol() public view returns (string) {
        return symbol;
    }
    
    function totalSupply() public view returns (uint) {
        return allPurchasedSprites.length;
    }
    
    function balanceOf (address _owner) public view returns (uint) {
        return numberOfSpritesOwnedByUser[_owner];
    }
    
    function ownerOf (uint _tokenId) external view returns (address){
        return broughtSprites[_tokenId].owner;
    }
    
    function approve (address _to, uint256 _tokenId) external {
        require (broughtSprites[_tokenId].owner == msg.sender);
        allowed [msg.sender][_to].push(_tokenId);
        Approval (msg.sender, _to, _tokenId);
    }
    
    function transfer (address _to, uint _tokenId) external {
        require (broughtSprites[_tokenId].owner == msg.sender);
        broughtSprites[_tokenId].owner = _to;
        numberOfSpritesOwnedByUser[msg.sender]--;
        numberOfSpritesOwnedByUser[_to]++;
        spriteOwningHistory[_to].push(_tokenId);
        Transfer (msg.sender, _to, _tokenId);
    }

    function transferFrom (address _from, address _to, uint256 _tokenId) external {
        // This array shouldn't be big at all (if it's even more than 1 item) unless someone owns a huge number of Sprites and has called approve() on each of their Sprites to allow a certain address to transfer each one of them
        for (uint i = 0; i < allowed[_from][msg.sender].length; i++) {
            if (allowed[_from][msg.sender][i] == _tokenId) {
                require (broughtSprites[_tokenId].owner == _from);
                numberOfSpritesOwnedByUser[broughtSprites[_tokenId].owner]--;
                numberOfSpritesOwnedByUser[_to]++;
                spriteOwningHistory[_to].push(_tokenId);
                broughtSprites[_tokenId].owner = _to;
                Transfer (broughtSprites[_tokenId].owner, _to, _tokenId);
            } 
        }
    }
    
    function allowance (address _owner, address _spender) view returns (uint) {
        return allowed[_owner][_spender].length;
    }
    
    function supportsInterface (bytes4 _interfaceID) external view returns (bool) {

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }
    
}