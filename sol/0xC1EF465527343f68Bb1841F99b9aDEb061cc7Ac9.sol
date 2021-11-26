pragma solidity ^0.4.18;

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
}

contract SampleStorage is Ownable {
    
    struct Sample {
        string ipfsHash;
        uint rarity;
    }
    
    mapping (uint32 => Sample) public sampleTypes;
    
    uint32 public numOfSampleTypes;
    
    uint32 public numOfCommon;
    uint32 public numOfRare;
    uint32 public numOfLegendary;

    // The mythical sample is a type common that appears only once in a 1000
    function addNewSampleType(string _ipfsHash, uint _rarityType) public onlyOwner {
        
        if (_rarityType == 0) {
            numOfCommon++;
        } else if (_rarityType == 1) {
            numOfRare++;
        } else if(_rarityType == 2) {
            numOfLegendary++;
        } else if(_rarityType == 3) {
            numOfCommon++;
        }
        
        sampleTypes[numOfSampleTypes] = Sample({
           ipfsHash: _ipfsHash,
           rarity: _rarityType
        });
        
        numOfSampleTypes++;
    }
    
    function getType(uint _randomNum) public view returns (uint32) {
        uint32 range = 0;
        
        if (_randomNum > 0 && _randomNum < 600) {
            range = 600 / numOfCommon;
            return uint32(_randomNum) / range;
            
        } else if(_randomNum >= 600 && _randomNum < 900) {
            range = 300 / numOfRare;
            return uint32(_randomNum) / range;
        } else {
            range = 100 / numOfLegendary;
            return uint32(_randomNum) / range;
        }
    }
    
}

contract Jingle is Ownable, ERC721 {
    
    struct MetaInfo {
        string name;
        string author;
    }
    
    mapping (uint => address) internal tokensForOwner;
    mapping (uint => address) internal tokensForApproved;
    mapping (address => uint[]) internal tokensOwned;
    mapping (uint => uint) internal tokenPosInArr;
    
    mapping(uint => uint[]) internal samplesInJingle;
    mapping(uint => MetaInfo) public jinglesInfo;
    
    mapping(bytes32 => bool) public uniqueJingles;
    
    mapping(uint => uint8[]) public soundEffects;
    mapping(uint => uint8[20]) public settings;
    
    uint public numOfJingles;
    
    address public cryptoJingles;
    Marketplace public marketplaceContract;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event EffectAdded(uint indexed jingleId, uint8[] effectParams);
    event Composed(uint indexed jingleId, address indexed owner, uint32[5] samples, uint32[5] jingleTypes,
            string name, string author, uint8[20] settings);
    
    modifier onlyCryptoJingles() {
        require(msg.sender == cryptoJingles);
        _;
    }
    
    function transfer(address _to, uint256 _jingleId) public {
        require(tokensForOwner[_jingleId] != 0x0);
        require(tokensForOwner[_jingleId] == msg.sender);
        
        tokensForApproved[_jingleId] = 0x0;
        
        removeJingle(msg.sender, _jingleId);
        addJingle(_to, _jingleId);
        
        Approval(msg.sender, 0, _jingleId);
        Transfer(msg.sender, _to, _jingleId);
    }
    
    
    function approve(address _to, uint256 _jingleId) public {
        require(tokensForOwner[_jingleId] != 0x0);
        require(ownerOf(_jingleId) == msg.sender);
        require(_to != msg.sender);
        
        if (_getApproved(_jingleId) != 0x0 || _to != 0x0) {
            tokensForApproved[_jingleId] = _to;
            Approval(msg.sender, _to, _jingleId);
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _jingleId) public {
        require(tokensForOwner[_jingleId] != 0x0);
        require(_getApproved(_jingleId) == msg.sender);
        require(ownerOf(_jingleId) == _from);
        require(_to != 0x0);
        
        tokensForApproved[_jingleId] = 0x0;
        
        removeJingle(_from, _jingleId);
        addJingle(_to, _jingleId);
        
        Approval(_from, 0, _jingleId);
        Transfer(_from, _to, _jingleId);
        
    }
    
    function approveAndSell(uint _jingleId, uint _amount) public {
        approve(address(marketplaceContract), _jingleId);
        
        marketplaceContract.sell(msg.sender, _jingleId, _amount);
    }
    
    function composeJingle(address _owner, uint32[5] jingles, 
    uint32[5] jingleTypes, string name, string author, uint8[20] _settings) public onlyCryptoJingles {
        
        uint _jingleId = numOfJingles;
        
        uniqueJingles[keccak256(jingles)] = true;
        
        tokensForOwner[_jingleId] = _owner;
        
        tokensOwned[_owner].push(_jingleId);
        
        samplesInJingle[_jingleId] = jingles;
        settings[_jingleId] = _settings;
        
        tokenPosInArr[_jingleId] = tokensOwned[_owner].length - 1;
        
        if (bytes(author).length == 0) {
            author = "Soundtoshi Nakajingles";
        }
        
        jinglesInfo[numOfJingles] = MetaInfo({
            name: name,
            author: author
        });
        
        Composed(numOfJingles, _owner, jingles, jingleTypes, 
        name, author, _settings);
        
        numOfJingles++;
    }
    
    function addSoundEffect(uint _jingleId, uint8[] _effectParams) external {
        require(msg.sender == ownerOf(_jingleId));
        
        soundEffects[_jingleId] = _effectParams;
        
        EffectAdded(_jingleId, _effectParams);
    }
    
    function implementsERC721() public pure returns (bool) {
        return true;
    }
    
    function totalSupply() public view returns (uint256) {
        return numOfJingles;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return tokensOwned[_owner].length;
    }
    
    function ownerOf(uint256 _jingleId) public view returns (address) {
        return tokensForOwner[_jingleId];
    }
    
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        return tokensOwned[_owner][_index];
    }
    
    function getSamplesForJingle(uint _jingleId) external view returns(uint[]) {
        return samplesInJingle[_jingleId];
    }
    
    function getAllJingles(address _owner) external view returns(uint[]) {
        return tokensOwned[_owner];
    }
    
    function getMetaInfo(uint _jingleId) external view returns(string, string) {
        return (jinglesInfo[_jingleId].name, jinglesInfo[_jingleId].author);
    }
    
    function _getApproved(uint _jingleId) internal view returns (address) {
        return tokensForApproved[_jingleId];
    }
    
     // Internal functions of the contract
    
    function addJingle(address _owner, uint _jingleId) internal {
        tokensForOwner[_jingleId] = _owner;
        
        tokensOwned[_owner].push(_jingleId);
        
        tokenPosInArr[_jingleId] = tokensOwned[_owner].length - 1;
    }
    
    // find who owns that jingle and at what position is it in the owners arr 
    // Swap that token with the last one in arr and delete the end of arr
    function removeJingle(address _owner, uint _jingleId) internal {
        uint length = tokensOwned[_owner].length;
        uint index = tokenPosInArr[_jingleId];
        uint swapToken = tokensOwned[_owner][length - 1];

        tokensOwned[_owner][index] = swapToken;
        tokenPosInArr[swapToken] = index;

        delete tokensOwned[_owner][length - 1];
        tokensOwned[_owner].length--;
    }
    
    // Owner functions 
    function setCryptoJinglesContract(address _cryptoJingles) public onlyOwner {
        require(cryptoJingles == 0x0);
        
        cryptoJingles = _cryptoJingles;
    }
    
    function setMarketplaceContract(address _marketplace) public onlyOwner {
        require(address(marketplaceContract) == 0x0);
        
        marketplaceContract = Marketplace(_marketplace);
    }
}

contract Sample is Ownable {
    
    mapping (uint => address) internal tokensForOwner;
    mapping (address => uint[]) internal tokensOwned;
    mapping (uint => uint) internal tokenPosInArr;
    
    mapping (uint => uint32) public tokenType;
    
    uint public numOfSamples;
    
    address public cryptoJingles;
    address public sampleRegistry;


    SampleStorage public sampleStorage;
    
    event Mint(address indexed _to, uint256 indexed _tokenId);
    
    modifier onlyCryptoJingles() {
        require(msg.sender == cryptoJingles);
        _;
    }
    
    function Sample(address _sampleStorage) public {
        sampleStorage = SampleStorage(_sampleStorage);
    }
    
    function mint(address _owner, uint _randomNum) public onlyCryptoJingles {
        
        uint32 sampleType = sampleStorage.getType(_randomNum);
        
        addSample(_owner, sampleType, numOfSamples);
        
        Mint(_owner, numOfSamples);
        
        numOfSamples++;
    }
    
    function mintForSampleRegitry(address _owner, uint32 _type) public {
        require(msg.sender == sampleRegistry);
        
        addSample(_owner, _type, numOfSamples);
        
        Mint(_owner, numOfSamples);
        
        numOfSamples++;
    }
    
    function removeSample(address _owner, uint _sampleId) public onlyCryptoJingles {
        uint length = tokensOwned[_owner].length;
        uint index = tokenPosInArr[_sampleId];
        uint swapToken = tokensOwned[_owner][length - 1];

        tokensOwned[_owner][index] = swapToken;
        tokenPosInArr[swapToken] = index;

        delete tokensOwned[_owner][length - 1];
        tokensOwned[_owner].length--;
        
        tokensForOwner[_sampleId] = 0x0;
        
    }
    
    function getSamplesForOwner(address _owner) public constant returns (uint[]) {
        return tokensOwned[_owner];
    }
    
    function getTokenType(uint _sampleId) public constant returns (uint) {
        return tokenType[_sampleId];
    }
    
    function isTokenOwner(uint _tokenId, address _user) public constant returns(bool) {
        return tokensForOwner[_tokenId] == _user;
    }
    
    function getAllSamplesForOwner(address _owner) public constant returns(uint[]) {
        uint[] memory samples = tokensOwned[_owner];
        
        uint[] memory usersSamples = new uint[](samples.length * 2);
        
        uint j = 0;
        
        for(uint i = 0; i < samples.length; ++i) {
            usersSamples[j] = samples[i];
            usersSamples[j + 1] = tokenType[samples[i]];
            j += 2;
        }
        
        return usersSamples;
    }
    
    // Internal functions of the contract
    
    function addSample(address _owner, uint32 _sampleType, uint _sampleId) internal {
        tokensForOwner[_sampleId] = _owner;
        
        tokensOwned[_owner].push(_sampleId);
        
        tokenType[_sampleId] = _sampleType;
        
        tokenPosInArr[_sampleId] = tokensOwned[_owner].length - 1;
    }
    
     // Owner functions 
    // Set the crypto jingles contract can 
    function setCryptoJinglesContract(address _cryptoJingles) public onlyOwner {
        require(cryptoJingles == 0x0);
        
        cryptoJingles = _cryptoJingles;
    }
    
    function setSampleRegistry(address _sampleRegistry) public onlyOwner {
        sampleRegistry = _sampleRegistry;
    }
}

contract CryptoJingles is Ownable {
    
    struct Purchase {
        address user;
        uint blockNumber;
        bool revealed;
        uint numSamples;
        bool exists;
    }
    
    event Purchased(address indexed user, uint blockNumber, uint numJingles, uint numOfPurchases);
    event JinglesOpened(address byWhom, address jingleOwner, uint currBlockNumber);
    
    mapping (uint => bool) public isAlreadyUsed;
    
    mapping(address => string) public authors;

    uint numOfPurchases;
    
    uint MAX_SAMPLES_PER_PURCHASE = 15;
    uint SAMPLE_PRICE = 10 ** 15;
    uint SAMPLES_PER_JINGLE = 5;
    uint NUM_SAMPLE_RANGE = 1000;
    
    Sample public sampleContract;
    Jingle public jingleContract;
    
    function CryptoJingles(address _sample, address _jingle) public {
        numOfPurchases = 0;
        sampleContract = Sample(_sample);
        jingleContract = Jingle(_jingle);
    }
    
    function buySamples(uint _numSamples, address _to) public payable {
        require(_numSamples <= MAX_SAMPLES_PER_PURCHASE);
        require(msg.value >= (SAMPLE_PRICE * _numSamples));
        require(_to != 0x0);
        
         for (uint i = 0; i < _numSamples; ++i) {
            
            bytes32 blockHash = block.blockhash(block.number - 1);
            
            uint randomNum = randomGen(blockHash, i);
            sampleContract.mint(_to, randomNum);
        }
        
        Purchased(_to, block.number, _numSamples, numOfPurchases);
        
        numOfPurchases++;
    }
    
    function composeJingle(string name, uint32[5] samples, uint8[20] settings) public {
        require(jingleContract.uniqueJingles(keccak256(samples)) == false);
        
        uint32[5] memory sampleTypes;
        
        //check if you own all the 5 samples 
        for (uint i = 0; i < SAMPLES_PER_JINGLE; ++i) {
            bool isOwner = sampleContract.isTokenOwner(samples[i], msg.sender);
            
            require(isOwner == true && isAlreadyUsed[samples[i]] == false);
            
            isAlreadyUsed[samples[i]] = true;
            
            sampleTypes[i] = sampleContract.tokenType(samples[i]);
            sampleContract.removeSample(msg.sender, samples[i]);
        }
        
        //create a new jingle containing those 5 samples
        jingleContract.composeJingle(msg.sender, samples, sampleTypes, name,
                            authors[msg.sender], settings);
    }
    
    // Addresses can set their name when composing jingles
    function setAuthorName(string _name) public {
        authors[msg.sender] = _name;
    }
    
    function randomGen(bytes32 blockHash, uint seed) constant public returns (uint randomNumber) {
        return (uint(keccak256(blockHash, block.timestamp, numOfPurchases, seed )) % NUM_SAMPLE_RANGE);
    }
    
    // The only ether kept on this contract are owner money for samples
    function withdraw(uint _amount) public onlyOwner {
        require(_amount <= this.balance);
        
        msg.sender.transfer(_amount);
    }
    
}

contract Marketplace is Ownable {
    
    modifier onlyJingle() {
        require(msg.sender == address(jingleContract));
        _;
    }
    
    struct Order {
        uint price;
        address seller;
        uint timestamp;
        bool exists;
    }
    
    event SellOrder(address owner, uint jingleId, uint price);
    event Bought(uint jingleId, address buyer, uint price);
    event Canceled(address owner, uint jingleId);
    
    uint public numOrders;
    uint public ownerBalance;
    
    uint OWNERS_CUT = 3; // 3 percent of every sale goes to owner
    
    mapping (uint => Order) public sellOrders;
    mapping(uint => uint) public positionOfJingle;
    
    uint[] public jinglesOnSale;
    
    Jingle public jingleContract;
    
    function Marketplace(address _jingle) public {
        jingleContract = Jingle(_jingle);
        ownerBalance = 0;
    }

    function sell(address _owner, uint _jingleId, uint _amount) public onlyJingle {
        require(_amount > 100);
        require(sellOrders[_jingleId].exists == false);
        
        sellOrders[_jingleId] = Order({
           price: _amount,
           seller: _owner,
           timestamp: now,
           exists: true
        });
        
        numOrders++;
        
        // set for iterating
        jinglesOnSale.push(_jingleId);
        positionOfJingle[_jingleId] = jinglesOnSale.length - 1;
        
        //transfer ownership 
        jingleContract.transferFrom(_owner, this, _jingleId);
        
        //Fire an sell event
        SellOrder(_owner, _jingleId, _amount);
    }
    
    function buy(uint _jingleId) public payable {
        require(sellOrders[_jingleId].exists == true);
        require(msg.value >= sellOrders[_jingleId].price);
        
        sellOrders[_jingleId].exists = false;
        
        numOrders--;
        
        //delete stuff for iterating 
        removeOrder(_jingleId);
        
        //transfer ownership 
        jingleContract.transfer(msg.sender, _jingleId);
        
        // transfer money to seller
        uint price = sellOrders[_jingleId].price;
        
        uint threePercent = (price / 100) * OWNERS_CUT;
        
        sellOrders[_jingleId].seller.transfer(price - threePercent);
        
        ownerBalance += threePercent;
        
        //fire and event
        Bought(_jingleId, msg.sender, msg.value);
    }
    
    function cancel(uint _jingleId) public {
        require(sellOrders[_jingleId].exists == true);
        require(sellOrders[_jingleId].seller == msg.sender);
        
        sellOrders[_jingleId].exists = false;
        
        numOrders--;
        
        //delete stuff for iterating 
        removeOrder(_jingleId);
        
        jingleContract.transfer(msg.sender, _jingleId);
        
        //fire and event
        Canceled(msg.sender, _jingleId);
    }
    
    function removeOrder(uint _jingleId) internal {
        uint length = jinglesOnSale.length;
        uint index = positionOfJingle[_jingleId];
        uint lastOne = jinglesOnSale[length - 1];

        jinglesOnSale[index] = lastOne;
        positionOfJingle[lastOne] = index;

        delete jinglesOnSale[length - 1];
        jinglesOnSale.length--;
    }
    
    function getAllJinglesOnSale() public view returns(uint[]) {
        return jinglesOnSale;
    }
    
    //Owners functions 
    function withdraw(uint _amount) public onlyOwner {
        require(_amount <= ownerBalance);
        
        msg.sender.transfer(_amount);
    }
    
}