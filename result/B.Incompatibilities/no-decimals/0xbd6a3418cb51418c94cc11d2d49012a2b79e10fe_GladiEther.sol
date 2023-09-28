pragma solidity ^0.4.18;

contract Ownable {
    address public owner = msg.sender;
    address public manager = 0xcEd259dB3435BcbC63eC80A2440F94a1c95C69Bb;

    function getOwner() view external returns (address) {
        return owner;
    }

    /// @notice check if the caller is the owner of the contract
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    bool locked;
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    /// @notice change the owner of the contract
    /// @param _newOwner the address of the new owner of the contract.
    function changeOwner(address _newOwner) public
    onlyOwner
    {
        require(_newOwner != 0x0);
        owner = _newOwner;
    }
}

contract WeaponsCore is Ownable
{
    struct WeaponModel {
        uint id;
        uint weaponType;
        uint generation;
        uint price;
    }

    struct WeaponEntity {
        uint modelId;
        uint weaponType;
        uint generation;
        uint dna;
    }

    uint8 public nextWeaponID = 1; // ID for the next weapon

    WeaponModel[] public weaponModels;
    WeaponEntity[] public weaponEntities;
    mapping(uint256 => address) public weaponToOwner;
    mapping(address => uint256[]) internal ownerToWeapons;
    mapping(uint256 => address) public weaponToApproved;

    function WeaponsCore() public payable {
        //registering swords (type 0)
        _registerWeapon(0, 0, 0, 0.01 ether);
        _registerWeapon(1, 0, 1, 0.05 ether);
        _registerWeapon(2, 0, 2, 0.1 ether);
        _registerWeapon(3, 0, 3, 0.25 ether);
        _registerWeapon(4, 0, 4, 0.5 ether);

        //registering axes (type 1)
        _registerWeapon(5, 1, 0, 0.01 ether);
        _registerWeapon(6, 1, 1, 0.05 ether);
        _registerWeapon(7, 1, 2, 0.1 ether);
        _registerWeapon(8, 1, 3, 0.25 ether);
        _registerWeapon(9, 1, 4, 0.5 ether);

        //registering hammers (type 2)
        _registerWeapon(10, 2, 0, 0.01 ether);
        _registerWeapon(11, 2, 1, 0.05 ether);
        _registerWeapon(12, 2, 2, 0.1 ether);
        _registerWeapon(13, 2, 3, 0.25 ether);
        _registerWeapon(14, 2, 4, 0.5 ether);

        //registering bows (type 3)
        _registerWeapon(15, 3, 0, 0.01 ether);
        _registerWeapon(16, 3, 1, 0.05 ether);
        _registerWeapon(17, 3, 2, 0.1 ether);
        _registerWeapon(18, 3, 3, 0.25 ether);
        _registerWeapon(19, 3, 4, 0.5 ether);
    }

    function _registerWeapon(uint _id, uint _type, uint _generation, uint _price) private {
        WeaponModel memory weaponModel = WeaponModel(_id, _type, _generation, _price);
        weaponModels.push(weaponModel);
    }

    function getWeaponEntity(uint256 id) external view returns (uint, uint, uint, uint) {
        WeaponEntity memory weapon = weaponEntities[id];

        return (weapon.modelId, weapon.weaponType, weapon.generation, weapon.dna);
    }

    function getWeaponModel(uint256 id) external view returns (uint, uint, uint, uint) {
        WeaponModel memory weapon = weaponModels[id];

        return (weapon.id, weapon.weaponType, weapon.generation, weapon.price);
    }

    function getWeaponIds() external view returns (uint[]) {
        uint weaponsCount = nextWeaponID - 1;
        uint[] memory _weaponsList = new uint[](weaponsCount);
        for (uint weaponId = 0; weaponId < weaponsCount; weaponId++) {
            _weaponsList[weaponId] = weaponId;
        }

        return _weaponsList;
    }

    /*
    function newWeapon(uint8 _id, uint8 _weaponType, uint8 _attack, uint8 _defense, uint8 _accuracy, uint8 _speed, uint8 _levelRequired, uint8 _criticalHitChance, uint8 _maxDurability, uint8 _durability, uint256 _profit, uint _price) external payable noReentrancy onlyOwner {
        weaponModels[nextWeaponID++] = WeaponModel(_id, _weaponType, _attack, _defense, _accuracy, _speed, _levelRequired, _criticalHitChance, _maxDurability, _durability, _profit, _price);
    }
    */

    function _generateWeapon(address _owner, uint256 _weaponId) internal returns (uint256 id) {
        require(weaponModels[_weaponId].price > 0);
        require(msg.value == weaponModels[_weaponId].price);

        id = weaponEntities.length;
        uint256 createTime = block.timestamp;

        // Insecure RNG, but good enough for our purposes - borrowed from EtherTulips
        uint256 seed = uint(block.blockhash(block.number - 1)) + uint(block.blockhash(block.number - 100))
        + uint(block.coinbase) + createTime + id;
        uint256 dna = uint256(keccak256(seed)) % 1000000000000000;

        WeaponModel memory weaponModel = weaponModels[_weaponId];
        WeaponEntity memory newWeapon = WeaponEntity(_weaponId, weaponModel.weaponType, weaponModel.generation, dna);
        weaponEntities.push(newWeapon);
        weaponToOwner[id] = _owner;
        ownerToWeapons[_owner].push(id);
    }

    function _transferWeapon(address _from, address _to, uint256 _id) internal {
        weaponToOwner[_id] = _to;
        ownerToWeapons[_to].push(_id);
        weaponToApproved[_id] = address(0);

        uint256[] storage fromWeapons = ownerToWeapons[_from];
        for (uint256 i = 0; i < fromWeapons.length; i++) {
            if (fromWeapons[i] == _id) {
                break;
            }
        }
        assert(i < fromWeapons.length);

        fromWeapons[i] = fromWeapons[fromWeapons.length - 1];
        delete fromWeapons[fromWeapons.length - 1];
        fromWeapons.length--;
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


contract WeaponToken is WeaponsCore, ERC721 {

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return weaponEntities.length;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerToWeapons[_owner].length;
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = weaponToOwner[_tokenId];
        require(owner != address(0));
    }

    function transfer(address _to, uint256 _tokenId) public {
        require(_to != address(0));
        require(weaponToOwner[_tokenId] == msg.sender);

        _transferWeapon(msg.sender, _to, _tokenId);
        Transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public {
        require(weaponToOwner[_tokenId] == msg.sender);
        weaponToApproved[_tokenId] = _to;

        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_to != address(0));
        require(weaponToApproved[_tokenId] == msg.sender);
        require(weaponToOwner[_tokenId] == _from);

        _transferWeapon(_from, _to, _tokenId);
        Transfer(_from, _to, _tokenId);
    }

    function name() public pure returns (string) {
        return "GladiEther Weapon";
    }

    function symbol() public pure returns (string) {
        return "GEW";
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < ownerToWeapons[_owner].length);
        return ownerToWeapons[_owner][_index];
    }

    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}


contract WeaponSales is WeaponToken {
    event Purchase(address indexed owner, uint256 unitPrice, uint32 amount);

    function buyWeapon(uint256 _weaponId) public payable returns (uint256 id) {
        id = _generateWeapon(msg.sender, _weaponId);
        Transfer(address(0), msg.sender, id);
        Purchase(msg.sender, weaponModels[_weaponId].price, 1);
    }

    function withdrawBalance(uint256 _amount) external onlyOwner {
        require(_amount <= this.balance);

        msg.sender.transfer(_amount);
    }
}


contract GladiEther is WeaponSales
{
    function GladiEther() public payable {
        owner = msg.sender;
    }

    function getWeapon(uint weaponId) public view returns (uint modelId, uint weaponType, uint generation, uint dna) {
        WeaponEntity memory weapon = weaponEntities[weaponId];

        return (weapon.modelId, weapon.weaponType, weapon.generation, weapon.dna);
    }

    function myWeapons() public view returns (uint256[]) {
        uint256[] memory weaponsMemory = ownerToWeapons[msg.sender];
        return weaponsMemory;
    }

    function kill() public {
        if (msg.sender == owner) selfdestruct(owner);
    }
}