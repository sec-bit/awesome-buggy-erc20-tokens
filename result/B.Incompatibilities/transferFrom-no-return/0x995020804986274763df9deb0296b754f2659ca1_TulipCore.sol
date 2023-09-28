pragma solidity ^0.4.18;

contract AccessControl {
  address public owner;
  address[] public admins;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyAdmins {
    bool found = false;

    for (uint i = 0; i < admins.length; i++) {
      if (admins[i] == msg.sender) {
        found = true;
        break;
      }
    }

    require(found);
    _;
  }

  function addAdmin(address _adminAddress) public onlyOwner {
    admins.push(_adminAddress);
  }
}

contract ERC721 {
    // Required Functions
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address);
    function transfer(address _to, uint _tokenId) public;
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    // Optional Functions
    function name() public pure returns (string);
    function symbol() public pure returns (string);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);

    // Required Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
}

contract TulipBase is AccessControl {
  struct Tulip {
    uint256 genes;
    uint256 createTime;
    bytes32 name;
  }

  Tulip[] public tulips;
  mapping (uint256 => address) public tulipToOwner;
  mapping (address => uint256[]) internal ownerToTulips;
  mapping (uint256 => address) public tulipToApproved;

  function _generateTulip(bytes32 _name, address _owner, uint16 _gen) internal returns (uint256 id) {
    id = tulips.length;
    uint256 createTime = block.timestamp;

    // Insecure RNG, but good enough for our purposes
    uint256 seed = uint(block.blockhash(block.number - 1)) + uint(block.blockhash(block.number - 100))
      + uint(block.coinbase) + createTime + id;
    uint256 traits = uint256(keccak256(seed));
    // last 16 bits are generation number
    uint256 genes = traits / 0x10000 * 0x10000 + _gen;

    Tulip memory newTulip = Tulip(genes, createTime, _name);
    tulips.push(newTulip);
    tulipToOwner[id] = _owner;
    ownerToTulips[_owner].push(id);
  }

  function _transferTulip(address _from, address _to, uint256 _id) internal {
    tulipToOwner[_id] = _to;
    ownerToTulips[_to].push(_id);
    tulipToApproved[_id] = address(0);

    uint256[] storage fromTulips = ownerToTulips[_from];
    for (uint256 i = 0; i < fromTulips.length; i++) {
      if (fromTulips[i] == _id) {
        break;
      }
    }
    assert(i < fromTulips.length);

    fromTulips[i] = fromTulips[fromTulips.length - 1];
    delete fromTulips[fromTulips.length - 1];
    fromTulips.length--;
  }
}

contract TulipToken is TulipBase, ERC721 {

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  function totalSupply() public view returns (uint256) {
    return tulips.length;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownerToTulips[_owner].length;
  }

  function ownerOf(uint256 _tokenId) public view returns (address owner) {
    owner = tulipToOwner[_tokenId];
    require(owner != address(0));
  }

  function transfer(address _to, uint256 _tokenId) public {
    require(_to != address(0));
    require(tulipToOwner[_tokenId] == msg.sender);

    _transferTulip(msg.sender, _to, _tokenId);
    Transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public {
    require(tulipToOwner[_tokenId] == msg.sender);
    tulipToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(_to != address(0));
    require(tulipToApproved[_tokenId] == msg.sender);
    require(tulipToOwner[_tokenId] == _from);

    _transferTulip(_from, _to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

  function name() public pure returns (string) {
    return "Ether Tulips";
  }

  function symbol() public pure returns (string) {
    return "ETHT";
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < ownerToTulips[_owner].length);
    return ownerToTulips[_owner][_index];
  }

  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

contract TulipSales is TulipToken {
  event Purchase(address indexed owner, uint256 unitPrice, uint32 amount);

  uint128 public increasePeriod = 6000; // around 1 day
  uint128 public startBlock;
  uint256[] public genToStartPrice;
  uint256[23] internal exp15;

  function TulipSales() public {
    startBlock = uint128(block.number);
    genToStartPrice.push(10 finney);
    _setExp15();
  }

  // The price increases from the starting price at a rate of 1.5x a day, until
  // a max of 10000x the original price. For gen 0, this corresponds to a cap
  // of 100 ETH.
  function price(uint16 _gen) public view returns (uint256) {
    require(_gen < genToStartPrice.length);

    uint128 periodsElapsed = (uint128(block.number) - startBlock) / increasePeriod;
    return _priceAtPeriod(periodsElapsed, _gen);
  }

  function nextPrice(uint16 _gen) public view returns (uint256 futurePrice, uint128 blocksRemaining, uint128 changeBlock) {
    require(_gen < genToStartPrice.length);

    uint128 periodsElapsed = (uint128(block.number) - startBlock) / increasePeriod;
    futurePrice = _priceAtPeriod(periodsElapsed + 1, _gen);
    blocksRemaining = increasePeriod - (uint128(block.number) - startBlock) % increasePeriod;
    changeBlock = uint128(block.number) + blocksRemaining;
  }

  function buyTulip(bytes32 _name, uint16 _gen) public payable returns (uint256 id) {
    require(_gen < genToStartPrice.length);
    require(msg.value == price(_gen));

    id = _generateTulip(_name, msg.sender, _gen);
    Transfer(address(0), msg.sender, id);
    Purchase(msg.sender, price(_gen), 1);
  }

  function buyTulips(uint32 _amount, uint16 _gen) public payable returns (uint256 firstId) {
    require(_gen < genToStartPrice.length);
    require(msg.value == price(_gen) * _amount);
    require(_amount <= 100);

    for (uint32 i = 0; i < _amount; i++) {
      uint256 id = _generateTulip("", msg.sender, _gen);
      Transfer(address(0), msg.sender, id);

      if (i == 0) {
        firstId = id;
      }
    }
    Purchase(msg.sender, price(_gen), _amount);
  }

  function renameTulip(uint256 _id, bytes32 _name) public {
    require(tulipToOwner[_id] == msg.sender);

    tulips[_id].name = _name;
  }

  function addGen(uint256 _startPrice) public onlyAdmins {
    require(genToStartPrice.length < 65535);

    genToStartPrice.push(_startPrice);
  }

  function withdrawBalance(uint256 _amount) external onlyAdmins {
    require(_amount <= this.balance);

    msg.sender.transfer(_amount);
  }

  function _priceAtPeriod(uint128 _period, uint16 _gen) internal view returns (uint256) {
    if (_period >= exp15.length) {
      return genToStartPrice[_gen] * 10000;
    } else {
      return genToStartPrice[_gen] * exp15[_period] / 1 ether;
    }
  }

  // Set 1 ETH * 1.5^i for 0 <= i <= 22 with 3 significant figures
  function _setExp15() internal {
    exp15 = [
      1000 finney,
      1500 finney,
      2250 finney,
      3380 finney,
      5060 finney,
      7590 finney,
      11400 finney,
      17100 finney,
      25600 finney,
      38400 finney,
      57700 finney,
      86500 finney,
      130 ether,
      195 ether,
      292 ether,
      438 ether,
      657 ether,
      985 ether,
      1480 ether,
      2220 ether,
      3330 ether,
      4990 ether,
      7480 ether
    ];
  }
}

contract TulipCore is TulipSales {
  event ContractUpgrade(address newContract);
  event MaintenanceUpdate(bool maintenance);

  bool public underMaintenance = false;
  bool public deprecated = false;
  address public newContractAddress;

  function TulipCore() public {
    owner = msg.sender;
  }

  function getTulip(uint256 _id) public view returns (
    uint256 genes,
    uint256 createTime,
    string name
  ) {
    Tulip storage tulip = tulips[_id];
    genes = tulip.genes;
    createTime = tulip.createTime;

    bytes memory byteArray = new bytes(32);
    for (uint8 i = 0; i < 32; i++) {
      byteArray[i] = tulip.name[i];
    }
    name = string(byteArray);
  }

  function myTulips() public view returns (uint256[]) {
    uint256[] memory tulipsMemory = ownerToTulips[msg.sender];
    return tulipsMemory;
  }

  function myTulipsBatched(uint256 _startIndex, uint16 _maxAmount) public view returns (
    uint256[] tulipIds,
    uint256 amountRemaining
  ) {
    uint256[] storage tulipArr = ownerToTulips[msg.sender];
    int256 j = int256(tulipArr.length) - 1 - int256(_startIndex);
    uint256 amount = _maxAmount;

    if (j < 0) {
      return (
        new uint256[](0),
        0
      );
    } else if (j + 1 < _maxAmount) {
      amount = uint256(j + 1);
    }
    uint256[] memory resultIds = new uint256[](amount);

    for (uint16 i = 0; i < amount; i++) {
      resultIds[i] = tulipArr[uint256(j)];
      j--;
    }

    return (
      resultIds,
      uint256(j+1)
    );
  }

  function setMaintenance(bool _underMaintenance) public onlyAdmins {
    underMaintenance = _underMaintenance;
    MaintenanceUpdate(underMaintenance);
  }

  function upgradeContract(address _newContractAddress) public onlyAdmins {
    newContractAddress = _newContractAddress;
    deprecated = true;
    ContractUpgrade(_newContractAddress);
  }
}