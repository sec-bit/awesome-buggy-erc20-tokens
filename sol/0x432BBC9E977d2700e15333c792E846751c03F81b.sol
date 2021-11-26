pragma solidity ^0.4.17;

contract NovaAccessControl {
  mapping (address => bool) managers;
  address public cfoAddress;

  function NovaAccessControl() public {
    managers[msg.sender] = true;
  }

  modifier onlyManager() {
    require(managers[msg.sender]);
    _;
  }

  function setManager(address _newManager) external onlyManager {
    require(_newManager != address(0));
    managers[_newManager] = true;
  }

  function removeManager(address mangerAddress) external onlyManager {
    require(mangerAddress != msg.sender);
    managers[mangerAddress] = false;
  }

  function updateCfo(address newCfoAddress) external onlyManager {
    require(newCfoAddress != address(0));
    cfoAddress = newCfoAddress;
  }
}

contract NovaCoin is NovaAccessControl {
  string public name;
  string public symbol;
  uint256 public totalSupply;
  address supplier;
  // 1:1 convert with currency, so to cent
  uint8 public decimals = 2;
  mapping (address => uint256) public balanceOf;
  address public novaContractAddress;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn(address indexed from, uint256 value);
  event NovaCoinTransfer(address indexed to, uint256 value);

  function NovaCoin(uint256 initialSupply, string tokenName, string tokenSymbol) public {
    totalSupply = initialSupply * 10 ** uint256(decimals);
    supplier = msg.sender;
    balanceOf[supplier] = totalSupply;
    name = tokenName;
    symbol = tokenSymbol;
  }

  function _transfer(address _from, address _to, uint _value) internal {
    require(_to != 0x0);
    require(balanceOf[_from] >= _value);
    require(balanceOf[_to] + _value > balanceOf[_to]);
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
  }

  // currently only permit NovaContract to consume
  function transfer(address _to, uint256 _value) external {
    _transfer(msg.sender, _to, _value);
    Transfer(msg.sender, _to, _value);
  }

  function novaTransfer(address _to, uint256 _value) external onlyManager {
    _transfer(supplier, _to, _value);
    NovaCoinTransfer(_to, _value);
  }

  function updateNovaContractAddress(address novaAddress) external onlyManager {
    novaContractAddress = novaAddress;
  }

  // This is function is used for sell Nova properpty only
  // coin can only be trasfered to invoker, and invoker must be Nova contract
  function consumeCoinForNova(address _from, uint _value) external {
    require(msg.sender == novaContractAddress);
    require(balanceOf[_from] >= _value);
    var _to = novaContractAddress;
    require(balanceOf[_to] + _value > balanceOf[_to]);
    uint previousBalances = balanceOf[_from] + balanceOf[_to];
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
  }
}

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
  // Required methods
  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) external view returns (address owner);
  function approve(address _to, uint256 _tokenId) external;
  function transfer(address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;

  // Events
  event Transfer(address from, address to, uint256 tokenId);
  event Approval(address owner, address approved, uint256 tokenId);

  // Optional
  // function name() public view returns (string name);
  // function symbol() public view returns (string symbol);
  // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
  // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

  // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
  function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

// just interface reference
contract NovaLabInterface {
  function bornStar() external returns(uint star) {}
  function bornMeteoriteNumber() external returns(uint mNumber) {}
  function bornMeteorite() external returns(uint mQ) {}
  function mergeMeteorite(uint totalQuality) external returns(bool isSuccess, uint finalMass) {}
}

contract FamedStarInterface {
  function bornFamedStar(address userAddress, uint mass) external returns(uint id, bytes32 name) {}
  function updateFamedStarOwner(uint id, address newOwner) external {}
}

contract Nova is NovaAccessControl,ERC721 {
  // ERC721 Required
  bytes4 constant InterfaceSignature_ERC165 = bytes4(keccak256('supportsInterface(bytes4)'));

  bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('tokensOfOwner(address)')) ^
    bytes4(keccak256('tokenMetadata(uint256,string)'));

  function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
    return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
  }

  function name() public pure returns (string) {
    return "Nova";
  }

  function symbol() public pure returns (string) {
    return "NOVA";
  }

  function totalSupply() public view returns (uint256 total) {
    return validAstroCount;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return astroOwnerToIDsLen[_owner];
  }

  function ownerOf(uint256 _tokenId) external constant returns (address owner) {
    return astroIndexToOwners[_tokenId];
  }

  mapping(address => mapping (address => uint256)) allowed;
  function approve(address _to, uint256 _tokenId) external {
    require(msg.sender == astroIndexToOwners[_tokenId]);
    require(msg.sender != _to);

    allowed[msg.sender][_to] = _tokenId;
    Approval(msg.sender, _to, _tokenId);
  }

  function transfer(address _to, uint256 _tokenId) external {
    _transfer(msg.sender, _to, _tokenId);
    Transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    _transfer(_from, _to, _tokenId);
  }

  function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds) {
    return astroOwnerToIDs[_owner];
  }

  string metaBaseUrl = "http://supernova.duelofkings.com";
  function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl) {
    return metaBaseUrl;
  }

  function updateMetaBaseUrl(string newUrl) external onlyManager {
    metaBaseUrl = newUrl;
  }

  // END of ERC-165 ERC-721

  enum AstroType {Placeholder, Supernova, Meteorite, NormalStar, FamedStar, Dismissed}
  uint public superNovaSupply;
  uint public validAstroCount;
  address public novaCoinAddress;
  address public labAddress;
  address public famedStarAddress;
  uint public astroIDPool;
  uint public priceValidSeconds = 3600; //default 1 hour

  uint novaTransferRate = 30; // 30/1000

  struct Astro {
    uint id; //world unique, astroIDPool start from 1
    uint createTime;
    uint nextAttractTime;
    // [8][8][88][88] -> L to H: astroType, cdIdx, famedID, mass
    uint48 code;
    bytes32 name;
  }

  struct PurchasingRecord {
    uint id;
    uint priceWei;
    uint time;
  }

  Astro[] public supernovas;
  Astro[] public normalStars;
  Astro[] public famedStars;
  Astro[] public meteorites;

  uint32[31] public cd = [
    0,
    uint32(360 minutes),
    uint32(400 minutes),
    uint32(444 minutes),
    uint32(494 minutes),
    uint32(550 minutes),
    uint32(610 minutes),
    uint32(677 minutes),
    uint32(752 minutes),
    uint32(834 minutes),
    uint32(925 minutes),
    uint32(1027 minutes),
    uint32(1140 minutes),
    uint32(1265 minutes),
    uint32(1404 minutes),
    uint32(1558 minutes),
    uint32(1729 minutes),
    uint32(1919 minutes),
    uint32(2130 minutes),
    uint32(2364 minutes),
    uint32(2624 minutes),
    uint32(2912 minutes),
    uint32(3232 minutes),
    uint32(3587 minutes),
    uint32(3982 minutes),
    uint32(4420 minutes),
    uint32(4906 minutes),
    uint32(5445 minutes),
    uint32(6044 minutes),
    uint32(6708 minutes),
    uint32(7200 minutes)
  ];

  // a mapping from astro ID to the address that owns
  mapping (uint => address) public astroIndexToOwners;
  mapping (address => uint[]) public astroOwnerToIDs;
  mapping (address => uint) public astroOwnerToIDsLen;

  mapping (address => mapping(uint => uint)) public astroOwnerToIDIndex;

  mapping (uint => uint) public idToIndex;

  // a mapping from astro name to ID
  mapping (bytes32 => uint256) astroNameToIDs;

  // purchasing mapping
  mapping (address => PurchasingRecord) public purchasingBuyer;

  event PurchasedSupernova(address userAddress, uint astroID);
  event ExplodedSupernova(address userAddress, uint[] newAstroIDs);
  event MergedAstros(address userAddress, uint newAstroID);
  event AttractedMeteorites(address userAddress, uint[] newAstroIDs);
  event UserPurchasedAstro(address buyerAddress, address sellerAddress, uint astroID, uint recordPriceWei, uint value);
  event NovaPurchasing(address buyAddress, uint astroID, uint priceWei);

  // initial supply to managerAddress
  function Nova(uint32 initialSupply) public {
    superNovaSupply = initialSupply;
    validAstroCount = 0;
    astroIDPool = 0;
  }

  function updateNovaTransferRate(uint rate) external onlyManager {
    novaTransferRate = rate;
  }

  function updateNovaCoinAddress(address novaCoinAddr) external onlyManager {
    novaCoinAddress = novaCoinAddr;
  }

  function updateLabContractAddress(address addr) external onlyManager {
    labAddress = addr;
  }

  function updateFamedStarContractAddress(address addr) external onlyManager {
    famedStarAddress = addr;
  }

  function updatePriceValidSeconds(uint newSeconds) external onlyManager {
    priceValidSeconds = newSeconds;
  }

  function getAstrosLength() constant external returns(uint) {
      return astroIDPool;
  }

  function getUserAstroIDs(address userAddress) constant external returns(uint[]) {
    return astroOwnerToIDs[userAddress];
  }

  function getNovaOwnerAddress(uint novaID) constant external returns(address) {
      return astroIndexToOwners[novaID];
  }

  function getAstroInfo(uint id) constant public returns(uint novaId, uint idx, AstroType astroType, string astroName, uint mass, uint createTime, uint famedID, uint nextAttractTime, uint cdTime) {
      if (id > astroIDPool) {
          return;
      }

      (idx, astroType) = _extractIndex(idToIndex[id]);
      if (astroType == AstroType.Placeholder || astroType == AstroType.Dismissed) {
          return;
      }

      Astro memory astro;
      uint cdIdx;

      var astroPool = _getAstroPoolByType(astroType);
      astro = astroPool[idx];
      (astroType, cdIdx, famedID, mass) = _extractCode(astro.code);

      return (id, idx, astroType, _bytes32ToString(astro.name), mass, astro.createTime, famedID, astro.nextAttractTime, cd[cdIdx]);
  }

  function getAstroInfoByIdx(uint index, AstroType aType) constant external returns(uint novaId, uint idx, AstroType astroType, string astroName, uint mass, uint createTime, uint famedID, uint nextAttractTime, uint cdTime) {
      if (aType == AstroType.Placeholder || aType == AstroType.Dismissed) {
          return;
      }

      var astroPool = _getAstroPoolByType(aType);
      Astro memory astro = astroPool[index];
      uint cdIdx;
      (astroType, cdIdx, famedID, mass) = _extractCode(astro.code);
      return (astro.id, index, astroType, _bytes32ToString(astro.name), mass, astro.createTime, famedID, astro.nextAttractTime, cd[cdIdx]);
  }

  function getSupernovaBalance() constant external returns(uint) {
      return superNovaSupply;
  }

  function getAstroPoolLength(AstroType astroType) constant external returns(uint) {
      Astro[] storage pool = _getAstroPoolByType(astroType);
      return pool.length;
  }

  // read from end position
  function getAstroIdxsByPage(uint lastIndex, uint count, AstroType expectedType) constant external returns(uint[] idx, uint idxLen) {
      if (expectedType == AstroType.Placeholder || expectedType == AstroType.Dismissed) {
          return;
      }

      Astro[] storage astroPool = _getAstroPoolByType(expectedType);

      if (lastIndex == 0 || astroPool.length == 0 || lastIndex > astroPool.length) {
          return;
      }

      uint[] memory result = new uint[](count);
      uint start = lastIndex - 1;
      uint i = 0;
      for (uint cursor = start; cursor >= 0 && i < count; --cursor) {
          var astro = astroPool[cursor];
          if (_isValidAstro(_getAstroTypeByCode(astro.code))) {
            result[i++] = cursor;
          }
          if (cursor == 0) {
              break;
          }
      }

      // ugly
      uint[] memory finalR = new uint[](i);
      for (uint cnt = 0; cnt < i; cnt++) {
        finalR[cnt] = result[cnt];
      }

      return (finalR, i);
  }

  function isUserOwnNovas(address userAddress, uint[] novaIDs) constant external returns(bool isOwn) {
      for (uint i = 0; i < novaIDs.length; i++) {
          if (astroIndexToOwners[novaIDs[i]] != userAddress) {
              return false;
          }
      }

      return true;
  }

  function getUserPurchasingTime(address buyerAddress) constant external returns(uint) {
    return purchasingBuyer[buyerAddress].time;
  }

  function _extractIndex(uint codeIdx) pure public returns(uint index, AstroType astroType) {
      astroType = AstroType(codeIdx & 0x0000000000ff);
      index = uint(codeIdx >> 8);
  }

  function _combineIndex(uint index, AstroType astroType) pure public returns(uint codeIdx) {
      codeIdx = uint((index << 8) | uint(astroType));
  }

  function _updateAstroTypeForIndexCode(uint orgCodeIdx, AstroType astroType) pure public returns(uint) {
      return (orgCodeIdx & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00) | (uint(astroType));
  }

  function _updateIndexForIndexCode(uint orgCodeIdx, uint idx) pure public returns(uint) {
      return (orgCodeIdx & 0xff) | (idx << 8);
  }

  function _extractCode(uint48 code) pure public returns(AstroType astroType, uint cdIdx, uint famedID, uint mass) {
     astroType = AstroType(code & 0x0000000000ff);
     if (astroType == AstroType.NormalStar) {
        cdIdx = (code & 0x00000000ff00) >> 8;
        famedID = 0;
        mass = (code & 0xffff00000000) >> 32;
     } else if (astroType == AstroType.FamedStar) {
        cdIdx = (code & 0x00000000ff00) >> 8;
        famedID = (code & 0x0000ffff0000) >> 16;
        mass = (code & 0xffff00000000) >> 32;
     } else if (astroType == AstroType.Supernova) {
        cdIdx = 0;
        famedID = 0;
        mass = 0;
     } else {
        cdIdx = 0;
        famedID = 0;
        mass = (code & 0xffff00000000) >> 32;
     }
  }

  function _getAstroTypeByCode(uint48 code) pure internal returns(AstroType astroType) {
     return AstroType(code & 0x0000000000ff);
  }

  function _getMassByCode(uint48 code) pure internal returns(uint mass) {
     return uint((code & 0xffff00000000) >> 32);
  }

  function _getCdIdxByCode(uint48 code) pure internal returns(uint cdIdx) {
     return uint((code & 0x00000000ff00) >> 8);
  }

  function _getFamedIDByCode(uint48 code) pure internal returns(uint famedID) {
    return uint((code & 0x0000ffff0000) >> 16);
  }

  function _combieCode(AstroType astroType, uint cdIdx, uint famedID, uint mass) pure public returns(uint48 code) {
     if (astroType == AstroType.NormalStar) {
        return uint48(astroType) | (uint48(cdIdx) << 8) | (uint48(mass) << 32);
     } else if (astroType == AstroType.FamedStar) {
        return uint48(astroType) | (uint48(cdIdx) << 8) | (uint48(famedID) << 16) | (uint48(mass) << 32);
     } else if (astroType == AstroType.Supernova) {
        return uint48(astroType);
     } else {
        return uint48(astroType) | (uint48(mass) << 32);
     }
  }

  function _updateAstroTypeForCode(uint48 orgCode, AstroType newType) pure public returns(uint48 newCode) {
     return (orgCode & 0xffffffffff00) | (uint48(newType));
  }

  function _updateCdIdxForCode(uint48 orgCode, uint newIdx) pure public returns(uint48 newCode) {
     return (orgCode & 0xffffffff00ff) | (uint48(newIdx) << 8);
  }

  function _getAstroPoolByType(AstroType expectedType) constant internal returns(Astro[] storage pool) {
      if (expectedType == AstroType.Supernova) {
          return supernovas;
      } else if (expectedType == AstroType.Meteorite) {
          return meteorites;
      } else if (expectedType == AstroType.NormalStar) {
          return normalStars;
      } else if (expectedType == AstroType.FamedStar) {
          return famedStars;
      }
  }

  function _isValidAstro(AstroType astroType) pure internal returns(bool) {
      return astroType != AstroType.Placeholder && astroType != AstroType.Dismissed;
  }

  function _reduceValidAstroCount() internal {
    --validAstroCount;
  }

  function _plusValidAstroCount() internal {
    ++validAstroCount;
  }

  function _addAstro(AstroType astroType, bytes32 astroName, uint mass, uint createTime, uint famedID) internal returns(uint) {
    uint48 code = _combieCode(astroType, 0, famedID, mass);

    var astroPool = _getAstroPoolByType(astroType);
    ++astroIDPool;
    uint idx = astroPool.push(Astro({
        id: astroIDPool,
        name: astroName,
        createTime: createTime,
        nextAttractTime: 0,
        code: code
    })) - 1;

    idToIndex[astroIDPool] = _combineIndex(idx, astroType);

    return astroIDPool;
  }

  function _removeAstroFromUser(address userAddress, uint novaID) internal {
    uint idsLen = astroOwnerToIDsLen[userAddress];
    uint index = astroOwnerToIDIndex[userAddress][novaID];

    if (idsLen > 1 && index != idsLen - 1) {
        uint endNovaID = astroOwnerToIDs[userAddress][idsLen - 1];
        astroOwnerToIDs[userAddress][index] = endNovaID;
        astroOwnerToIDIndex[userAddress][endNovaID] = index;
    }
    astroOwnerToIDs[userAddress][idsLen - 1] = 0;
    astroOwnerToIDsLen[userAddress] = idsLen - 1;
  }

  function _addAstroToUser(address userAddress, uint novaID) internal {
    uint idsLen = astroOwnerToIDsLen[userAddress];
    uint arrayLen = astroOwnerToIDs[userAddress].length;
    if (idsLen == arrayLen) {
      astroOwnerToIDsLen[userAddress] = astroOwnerToIDs[userAddress].push(novaID);
      astroOwnerToIDIndex[userAddress][novaID] = astroOwnerToIDsLen[userAddress] - 1;
    } else {
      // there is gap
      astroOwnerToIDs[userAddress][idsLen] = novaID;
      astroOwnerToIDsLen[userAddress] = idsLen + 1;
      astroOwnerToIDIndex[userAddress][novaID] = idsLen;
    }
  }

  function _burnDownAstro(address userAddress, uint novaID) internal {
    delete astroIndexToOwners[novaID];
    _removeAstroFromUser(userAddress, novaID);

    uint idx;
    AstroType astroType;
    uint orgIdxCode = idToIndex[novaID];
    (idx, astroType) = _extractIndex(orgIdxCode);

    var pool = _getAstroPoolByType(astroType);
    pool[idx].code = _updateAstroTypeForCode(pool[idx].code, AstroType.Dismissed);

    idToIndex[novaID] = _updateAstroTypeForIndexCode(orgIdxCode, AstroType.Dismissed);

    _reduceValidAstroCount();
  }

  function _insertNewAstro(address userAddress, AstroType t, uint mass, bytes32 novaName, uint famedID) internal returns(uint) {
    uint newNovaID = _addAstro(t, novaName, mass, block.timestamp, famedID);
    astroIndexToOwners[newNovaID] = userAddress;
    _addAstroToUser(userAddress, newNovaID);

    _plusValidAstroCount();
    return newNovaID;
  }

  function _bytes32ToString(bytes32 x) internal pure returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
        byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
        if (char != 0) {
            bytesString[charCount] = char;
            charCount++;
        }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
        bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }

  function _stringToBytes32(string source) internal pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
  }

  function _transfer(address _from, address _to, uint _tokenId) internal {
    require(_from == astroIndexToOwners[_tokenId]);
    require(_from != _to && _to != address(0));

    uint poolIdx;
    AstroType itemType;
    (poolIdx, itemType) = _extractIndex(idToIndex[_tokenId]);
    var pool = _getAstroPoolByType(itemType);
    var astro = pool[poolIdx];
    require(_getAstroTypeByCode(astro.code) != AstroType.Dismissed);

    astroIndexToOwners[_tokenId] = _to;

    _removeAstroFromUser(_from, _tokenId);
    _addAstroToUser(_to, _tokenId);

    // Check if it's famous star
    uint famedID = _getFamedIDByCode(astro.code);
    if (famedID > 0) {
      var famedstarContract = FamedStarInterface(famedStarAddress);
      famedstarContract.updateFamedStarOwner(famedID, _to);
    }
  }

  // Purchase action only permit manager to use
  function purchaseSupernova(address targetAddress, uint price) external onlyManager {
    require(superNovaSupply >= 1);
    NovaCoin novaCoinContract = NovaCoin(novaCoinAddress);
    require(novaCoinContract.balanceOf(targetAddress) >= price);
    novaCoinContract.consumeCoinForNova(targetAddress, price);

    superNovaSupply -= 1;
    var newNovaID = _insertNewAstro(targetAddress, AstroType.Supernova, 0, 0, 0);
    PurchasedSupernova(targetAddress, newNovaID);
  }

  // explode one supernova from user's supernova balance, write explode result into user account
  function explodeSupernova(address userAddress, uint novaID) external onlyManager {
    // verifu if user own's this supernova
    require(astroIndexToOwners[novaID] == userAddress);
    uint poolIdx;
    AstroType itemType;
    (poolIdx, itemType) = _extractIndex(idToIndex[novaID]);
    require(itemType == AstroType.Supernova);
    // burn down user's supernova
    _burnDownAstro(userAddress, novaID);

    uint[] memory newAstroIDs;

    var labContract = NovaLabInterface(labAddress);
    uint star = labContract.bornStar();
    if (star > 0) {
        // Got star, check if it's famed star
        newAstroIDs = new uint[](1);
        var famedstarContract = FamedStarInterface(famedStarAddress);
        uint famedID;
        bytes32 novaName;
        (famedID, novaName) = famedstarContract.bornFamedStar(userAddress, star);
        if (famedID > 0) {
            newAstroIDs[0] = _insertNewAstro(userAddress, AstroType.FamedStar, star, novaName, famedID);
        } else {
            newAstroIDs[0] = _insertNewAstro(userAddress, AstroType.NormalStar, star, 0, 0);
        }
    } else {
        uint mNum = labContract.bornMeteoriteNumber();
        newAstroIDs = new uint[](mNum);
        uint m;
        for (uint i = 0; i < mNum; i++) {
            m = labContract.bornMeteorite();
            newAstroIDs[i] = _insertNewAstro(userAddress, AstroType.Meteorite, m, 0, 0);
        }
    }
    ExplodedSupernova(userAddress, newAstroIDs);
  }

  function _merge(address userAddress, uint mergeMass) internal returns (uint famedID, bytes32 novaName, AstroType newType, uint finalMass) {
    var labContract = NovaLabInterface(labAddress);
    bool mergeResult;
    (mergeResult, finalMass) = labContract.mergeMeteorite(mergeMass);
    if (mergeResult) {
        //got star, check if we can get famed star
        var famedstarContract = FamedStarInterface(famedStarAddress);
        (famedID, novaName) = famedstarContract.bornFamedStar(userAddress, mergeMass);
        if (famedID > 0) {
            newType = AstroType.FamedStar;
        } else {
            newType = AstroType.NormalStar;
        }
    } else {
        newType = AstroType.Meteorite;
    }
    return;
  }

  function _combine(address userAddress, uint[] astroIDs) internal returns(uint mergeMass) {
    uint astroID;
    mergeMass = 0;
    uint poolIdx;
    AstroType itemType;
    for (uint i = 0; i < astroIDs.length; i++) {
        astroID = astroIDs[i];
        (poolIdx, itemType) = _extractIndex(idToIndex[astroID]);
        require(astroIndexToOwners[astroID] == userAddress);
        require(itemType == AstroType.Meteorite);
        // start merge
        //mergeMass += meteorites[idToIndex[astroID].index].mass;
        mergeMass += _getMassByCode(meteorites[poolIdx].code);
        // Burn down
        _burnDownAstro(userAddress, astroID);
    }
  }

  function mergeAstros(address userAddress, uint novaCoinCentCost, uint[] astroIDs) external onlyManager {
    // check nova coin balance
    NovaCoin novaCoinContract = NovaCoin(novaCoinAddress);
    require(novaCoinContract.balanceOf(userAddress) >= novaCoinCentCost);
    // check astros
    require(astroIDs.length > 1 && astroIDs.length <= 10);

    uint mergeMass = _combine(userAddress, astroIDs);
    // Consume novaCoin
    novaCoinContract.consumeCoinForNova(userAddress, novaCoinCentCost);
    // start merge
    uint famedID;
    bytes32 novaName;
    AstroType newType;
    uint finalMass;
    (famedID, novaName, newType, finalMass) = _merge(userAddress, mergeMass);
    // Create new Astro
    MergedAstros(userAddress, _insertNewAstro(userAddress, newType, finalMass, novaName, famedID));
  }

  function _attractBalanceCheck(address userAddress, uint novaCoinCentCost) internal {
    // check balance
    NovaCoin novaCoinContract = NovaCoin(novaCoinAddress);
    require(novaCoinContract.balanceOf(userAddress) >= novaCoinCentCost);

    // consume coin
    novaCoinContract.consumeCoinForNova(userAddress, novaCoinCentCost);
  }

  function attractMeteorites(address userAddress, uint novaCoinCentCost, uint starID) external onlyManager {
    require(astroIndexToOwners[starID] == userAddress);
    uint poolIdx;
    AstroType itemType;
    (poolIdx, itemType) = _extractIndex(idToIndex[starID]);

    require(itemType == AstroType.NormalStar || itemType == AstroType.FamedStar);

    var astroPool = _getAstroPoolByType(itemType);
    Astro storage astro = astroPool[poolIdx];
    require(astro.nextAttractTime <= block.timestamp);

    _attractBalanceCheck(userAddress, novaCoinCentCost);

    var labContract = NovaLabInterface(labAddress);
    uint[] memory newAstroIDs = new uint[](1);
    uint m = labContract.bornMeteorite();
    newAstroIDs[0] = _insertNewAstro(userAddress, AstroType.Meteorite, m, 0, 0);
    // update cd
    uint cdIdx = _getCdIdxByCode(astro.code);
    if (cdIdx >= cd.length - 1) {
        astro.nextAttractTime = block.timestamp + cd[cd.length - 1];
    } else {
        astro.code = _updateCdIdxForCode(astro.code, ++cdIdx);
        astro.nextAttractTime = block.timestamp + cd[cdIdx];
    }

    AttractedMeteorites(userAddress, newAstroIDs);
  }

  function setPurchasing(address buyerAddress, address ownerAddress, uint astroID, uint priceWei) external onlyManager {
    require(astroIndexToOwners[astroID] == ownerAddress);
    purchasingBuyer[buyerAddress] = PurchasingRecord({
         id: astroID,
         priceWei: priceWei,
         time: block.timestamp
    });
    NovaPurchasing(buyerAddress, astroID, priceWei);
  }

  function userPurchaseAstro(address ownerAddress, uint astroID) payable external {
    // check valid purchasing tim
    require(msg.sender.balance >= msg.value);
    var record = purchasingBuyer[msg.sender];
    require(block.timestamp < record.time + priceValidSeconds);
    require(record.id == astroID);
    require(record.priceWei <= msg.value);

    uint royalties = uint(msg.value * novaTransferRate / 1000);
    ownerAddress.transfer(msg.value - royalties);
    cfoAddress.transfer(royalties);

    _transfer(ownerAddress, msg.sender, astroID);

    UserPurchasedAstro(msg.sender, ownerAddress, astroID, record.priceWei, msg.value);
    // clear purchasing state
    delete purchasingBuyer[msg.sender];
  }
}