pragma solidity ^0.4.11;



contract PullPayInterface {
  function asyncSend(address _dest) public payable;
}

contract Governable {

  // list of admins, council at first spot
  address[] public admins;

  function Governable() {
    admins.length = 1;
    admins[0] = msg.sender;
  }

  modifier onlyAdmins() {
    bool isAdmin = false;
    for (uint256 i = 0; i < admins.length; i++) {
      if (msg.sender == admins[i]) {
        isAdmin = true;
      }
    }
    require(isAdmin == true);
    _;
  }

  function addAdmin(address _admin) public onlyAdmins {
    for (uint256 i = 0; i < admins.length; i++) {
      require(_admin != admins[i]);
    }
    require(admins.length < 10);
    admins[admins.length++] = _admin;
  }

  function removeAdmin(address _admin) public onlyAdmins {
    uint256 pos = admins.length;
    for (uint256 i = 0; i < admins.length; i++) {
      if (_admin == admins[i]) {
        pos = i;
      }
    }
    require(pos < admins.length);
    // if not last element, switch with last
    if (pos < admins.length - 1) {
      admins[pos] = admins[admins.length - 1];
    }
    // then cut off the tail
    admins.length--;
  }

}




contract StorageEnabled {

  // satelite contract addresses
  address public storageAddr;

  function StorageEnabled(address _storageAddr) {
    storageAddr = _storageAddr;
  }


  // ############################################
  // ########### NUTZ FUNCTIONS  ################
  // ############################################


  // all Nutz balances
  function babzBalanceOf(address _owner) constant returns (uint256) {
    return Storage(storageAddr).getBal('Nutz', _owner);
  }
  function _setBabzBalanceOf(address _owner, uint256 _newValue) internal {
    Storage(storageAddr).setBal('Nutz', _owner, _newValue);
  }
  // active supply - sum of balances above
  function activeSupply() constant returns (uint256) {
    return Storage(storageAddr).getUInt('Nutz', 'activeSupply');
  }
  function _setActiveSupply(uint256 _newActiveSupply) internal {
    Storage(storageAddr).setUInt('Nutz', 'activeSupply', _newActiveSupply);
  }
  // burn pool - inactive supply
  function burnPool() constant returns (uint256) {
    return Storage(storageAddr).getUInt('Nutz', 'burnPool');
  }
  function _setBurnPool(uint256 _newBurnPool) internal {
    Storage(storageAddr).setUInt('Nutz', 'burnPool', _newBurnPool);
  }
  // power pool - inactive supply
  function powerPool() constant returns (uint256) {
    return Storage(storageAddr).getUInt('Nutz', 'powerPool');
  }
  function _setPowerPool(uint256 _newPowerPool) internal {
    Storage(storageAddr).setUInt('Nutz', 'powerPool', _newPowerPool);
  }





  // ############################################
  // ########### POWER   FUNCTIONS  #############
  // ############################################

  // all power balances
  function powerBalanceOf(address _owner) constant returns (uint256) {
    return Storage(storageAddr).getBal('Power', _owner);
  }

  function _setPowerBalanceOf(address _owner, uint256 _newValue) internal {
    Storage(storageAddr).setBal('Power', _owner, _newValue);
  }

  function outstandingPower() constant returns (uint256) {
    return Storage(storageAddr).getUInt('Power', 'outstandingPower');
  }

  function _setOutstandingPower(uint256 _newOutstandingPower) internal {
    Storage(storageAddr).setUInt('Power', 'outstandingPower', _newOutstandingPower);
  }

  function authorizedPower() constant returns (uint256) {
    return Storage(storageAddr).getUInt('Power', 'authorizedPower');
  }

  function _setAuthorizedPower(uint256 _newAuthorizedPower) internal {
    Storage(storageAddr).setUInt('Power', 'authorizedPower', _newAuthorizedPower);
  }


  function downs(address _user) constant public returns (uint256 total, uint256 left, uint256 start) {
    uint256 rawBytes = Storage(storageAddr).getBal('PowerDown', _user);
    start = uint64(rawBytes);
    left = uint96(rawBytes >> (64));
    total = uint96(rawBytes >> (96 + 64));
    return;
  }

  function _setDownRequest(address _holder, uint256 total, uint256 left, uint256 start) internal {
    uint256 result = uint64(start) + (left << 64) + (total << (96 + 64));
    Storage(storageAddr).setBal('PowerDown', _holder, result);
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Governable {

  bool public paused = true;

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyAdmins whenNotPaused {
    paused = true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyAdmins whenPaused {
    //TODO: do some checks
    paused = false;
  }

}


/*
 * ERC20Basic
 * Simpler version of ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  function totalSupply() constant returns (uint256);
  function balanceOf(address _owner) constant returns (uint256);
  function transfer(address _to, uint256 _value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC223Basic is ERC20Basic {
    function transfer(address to, uint value, bytes data) returns (bool);
}

/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC223Basic {
  // active supply of tokens
  function activeSupply() constant returns (uint256);
  function allowance(address _owner, address _spender) constant returns (uint256);
  function transferFrom(address _from, address _to, uint _value) returns (bool);
  function approve(address _spender, uint256 _value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Power is Ownable, ERC20Basic {

  event Slashing(address indexed holder, uint value, bytes32 data);

  string public name = "Acebusters Power";
  string public symbol = "ABP";
  uint256 public decimals = 12;


  function balanceOf(address _holder) constant returns (uint256) {
    return ControllerInterface(owner).powerBalanceOf(_holder);
  }

  function totalSupply() constant returns (uint256) {
    return ControllerInterface(owner).powerTotalSupply();
  }

  function activeSupply() constant returns (uint256) {
    return ControllerInterface(owner).outstandingPower();
  }


  // ############################################
  // ########### ADMIN FUNCTIONS ################
  // ############################################

  function slashPower(address _holder, uint256 _value, bytes32 _data) public onlyOwner {
    Slashing(_holder, _value, _data);
  }

  function powerUp(address _holder, uint256 _value) public onlyOwner {
    // NTZ transfered from user's balance to power pool
    Transfer(address(0), _holder, _value);
  }

  // ############################################
  // ########### PUBLIC FUNCTIONS ###############
  // ############################################

  // registers a powerdown request
  function transfer(address _to, uint256 _amountPower) public returns (bool success) {
    // make Power not transferable
    require(_to == address(0));
    ControllerInterface(owner).createDownRequest(msg.sender, _amountPower);
    Transfer(msg.sender, address(0), _amountPower);
    return true;
  }

  function downtime() public returns (uint256) {
    ControllerInterface(owner).downtime;
  }

  function downTick(address _owner) public {
    ControllerInterface(owner).downTick(_owner, now);
  }

  function downs(address _owner) constant public returns (uint256, uint256, uint256) {
    return ControllerInterface(owner).downs(_owner);
  }

}


contract Storage is Ownable {
    struct Crate {
        mapping(bytes32 => uint256) uints;
        mapping(bytes32 => address) addresses;
        mapping(bytes32 => bool) bools;
        mapping(address => uint256) bals;
    }

    mapping(bytes32 => Crate) crates;

    function setUInt(bytes32 _crate, bytes32 _key, uint256 _value) onlyOwner {
        crates[_crate].uints[_key] = _value;
    }

    function getUInt(bytes32 _crate, bytes32 _key) constant returns(uint256) {
        return crates[_crate].uints[_key];
    }

    function setAddress(bytes32 _crate, bytes32 _key, address _value) onlyOwner {
        crates[_crate].addresses[_key] = _value;
    }

    function getAddress(bytes32 _crate, bytes32 _key) constant returns(address) {
        return crates[_crate].addresses[_key];
    }

    function setBool(bytes32 _crate, bytes32 _key, bool _value) onlyOwner {
        crates[_crate].bools[_key] = _value;
    }

    function getBool(bytes32 _crate, bytes32 _key) constant returns(bool) {
        return crates[_crate].bools[_key];
    }

    function setBal(bytes32 _crate, address _key, uint256 _value) onlyOwner {
        crates[_crate].bals[_key] = _value;
    }

    function getBal(bytes32 _crate, address _key) constant returns(uint256) {
        return crates[_crate].bals[_key];
    }
}


contract NutzEnabled is Pausable, StorageEnabled {
  using SafeMath for uint;

  // satelite contract addresses
  address public nutzAddr;


  modifier onlyNutz() {
    require(msg.sender == nutzAddr);
    _;
  }

  function NutzEnabled(address _nutzAddr, address _storageAddr)
    StorageEnabled(_storageAddr) {
    nutzAddr = _nutzAddr;
  }

  // ############################################
  // ########### NUTZ FUNCTIONS  ################
  // ############################################

  // total supply(modified for etherscan display)
  function totalSupply() constant returns (uint256) {
    return activeSupply();
  }

  // total supply(for internal calculations)
  function completeSupply() constant returns (uint256) {
    return activeSupply().add(powerPool()).add(burnPool());
  }

  // allowances according to ERC20
  // not written to storage, as not very critical
  mapping (address => mapping (address => uint)) internal allowed;

  function allowance(address _owner, address _spender) constant returns (uint256) {
    return allowed[_owner][_spender];
  }

  function approve(address _owner, address _spender, uint256 _amountBabz) public onlyNutz whenNotPaused {
    require(_owner != _spender);
    allowed[_owner][_spender] = _amountBabz;
  }

  function _transfer(address _from, address _to, uint256 _amountBabz, bytes _data) internal {
    require(_to != address(this));
    require(_to != address(0));
    require(_amountBabz > 0);
    require(_from != _to);
    _setBabzBalanceOf(_from, babzBalanceOf(_from).sub(_amountBabz));
    _setBabzBalanceOf(_to, babzBalanceOf(_to).add(_amountBabz));
  }

  function transfer(address _from, address _to, uint256 _amountBabz, bytes _data) public onlyNutz whenNotPaused {
    _transfer(_from, _to, _amountBabz, _data);
  }

  function transferFrom(address _sender, address _from, address _to, uint256 _amountBabz, bytes _data) public onlyNutz whenNotPaused {
    allowed[_from][_sender] = allowed[_from][_sender].sub(_amountBabz);
    _transfer(_from, _to, _amountBabz, _data);
  }

}




 /*
 * Contract that is working with ERC223 tokens
 */
 
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data);
}


contract ControllerInterface {


  // State Variables
  bool public paused;
  address public nutzAddr;

  // Nutz functions
  function babzBalanceOf(address _owner) constant returns (uint256);
  function activeSupply() constant returns (uint256);
  function burnPool() constant returns (uint256);
  function powerPool() constant returns (uint256);
  function totalSupply() constant returns (uint256);
  function completeSupply() constant returns (uint256);
  function allowance(address _owner, address _spender) constant returns (uint256);

  function approve(address _owner, address _spender, uint256 _amountBabz) public;
  function transfer(address _from, address _to, uint256 _amountBabz, bytes _data) public;
  function transferFrom(address _sender, address _from, address _to, uint256 _amountBabz, bytes _data) public;

  // Market functions
  function floor() constant returns (uint256);
  function ceiling() constant returns (uint256);

  function purchase(address _sender, uint256 _value, uint256 _price) public returns (uint256);
  function sell(address _from, uint256 _price, uint256 _amountBabz);

  // Power functions
  function powerBalanceOf(address _owner) constant returns (uint256);
  function outstandingPower() constant returns (uint256);
  function authorizedPower() constant returns (uint256);
  function powerTotalSupply() constant returns (uint256);

  function powerUp(address _sender, address _from, uint256 _amountBabz) public;
  function downTick(address _owner, uint256 _now) public;
  function createDownRequest(address _owner, uint256 _amountPower) public;
  function downs(address _owner) constant public returns(uint256, uint256, uint256);
  function downtime() constant returns (uint256);
}


/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments.
 */
contract PullPayment is Ownable {
  using SafeMath for uint256;


  uint public dailyLimit = 1000000000000000000000;  // 1 ETH
  uint public lastDay;
  uint public spentToday;

  // 8bytes date, 24 bytes value
  mapping(address => uint256) internal payments;

  modifier onlyNutz() {
    require(msg.sender == ControllerInterface(owner).nutzAddr());
    _;
  }

  modifier whenNotPaused () {
    require(!ControllerInterface(owner).paused());
     _;
  }

  function balanceOf(address _owner) constant returns (uint256 value) {
    return uint192(payments[_owner]);
  }

  function paymentOf(address _owner) constant returns (uint256 value, uint256 date) {
    value = uint192(payments[_owner]);
    date = (payments[_owner] >> 192);
    return;
  }

  /// @dev Allows to change the daily limit. Transaction has to be sent by wallet.
  /// @param _dailyLimit Amount in wei.
  function changeDailyLimit(uint _dailyLimit) public onlyOwner {
      dailyLimit = _dailyLimit;
  }

  function changeWithdrawalDate(address _owner, uint256 _newDate)  public onlyOwner {
    // allow to withdraw immediately
    // move witdrawal date more days into future
    payments[_owner] = (_newDate << 192) + uint192(payments[_owner]);
  }

  function asyncSend(address _dest) public payable onlyNutz {
    require(msg.value > 0);
    uint256 newValue = msg.value.add(uint192(payments[_dest]));
    uint256 newDate;
    if (isUnderLimit(msg.value)) {
      uint256 date = payments[_dest] >> 192;
      newDate = (date > now) ? date : now;
    } else {
      newDate = now.add(3 days);
    }
    spentToday = spentToday.add(msg.value);
    payments[_dest] = (newDate << 192) + uint192(newValue);
  }


  function withdraw() public whenNotPaused {
    address untrustedRecipient = msg.sender;
    uint256 amountWei = uint192(payments[untrustedRecipient]);

    require(amountWei != 0);
    require(now >= (payments[untrustedRecipient] >> 192));
    require(this.balance >= amountWei);

    payments[untrustedRecipient] = 0;

    assert(untrustedRecipient.call.gas(1000).value(amountWei)());
  }

  /*
   * Internal functions
   */
  /// @dev Returns if amount is within daily limit and resets spentToday after one day.
  /// @param amount Amount to withdraw.
  /// @return Returns if amount is under daily limit.
  function isUnderLimit(uint amount) internal returns (bool) {
    if (now > lastDay.add(24 hours)) {
      lastDay = now;
      spentToday = 0;
    }
    // not using safe math because we don't want to throw;
    if (spentToday + amount > dailyLimit || spentToday + amount < spentToday) {
      return false;
    }
    return true;
  }

}


/**
 * Nutz implements a price floor and a price ceiling on the token being
 * sold. It is based of the zeppelin token contract.
 */
contract Nutz is Ownable, ERC20 {

  event Sell(address indexed seller, uint256 value);

  string public name = "Acebusters Nutz";
  // acebusters units:
  // 10^12 - Nutz   (NTZ)
  // 10^9 - Jonyz
  // 10^6 - Helcz
  // 10^3 - Pascalz
  // 10^0 - Babz
  string public symbol = "NTZ";
  uint256 public decimals = 12;

  // returns balances of active holders
  function balanceOf(address _owner) constant returns (uint) {
    return ControllerInterface(owner).babzBalanceOf(_owner);
  }

  function totalSupply() constant returns (uint256) {
    return ControllerInterface(owner).totalSupply();
  }

  function activeSupply() constant returns (uint256) {
    return ControllerInterface(owner).activeSupply();
  }

  // return remaining allowance
  // if calling return allowed[address(this)][_spender];
  // returns balance of ether parked to be withdrawn
  function allowance(address _owner, address _spender) constant returns (uint256) {
    return ControllerInterface(owner).allowance(_owner, _spender);
  }

  // returns either the salePrice, or if reserve does not suffice
  // for active supply, returns maxFloor
  function floor() constant returns (uint256) {
    return ControllerInterface(owner).floor();
  }

  // returns either the salePrice, or if reserve does not suffice
  // for active supply, returns maxFloor
  function ceiling() constant returns (uint256) {
    return ControllerInterface(owner).ceiling();
  }

  function powerPool() constant returns (uint256) {
    return ControllerInterface(owner).powerPool();
  }


  function _checkDestination(address _from, address _to, uint256 _value, bytes _data) internal {
    // erc223: Retrieve the size of the code on target address, this needs assembly .
    uint256 codeLength;
    assembly {
      codeLength := extcodesize(_to)
    }
    if(codeLength>0) {
      ERC223ReceivingContract untrustedReceiver = ERC223ReceivingContract(_to);
      // untrusted contract call
      untrustedReceiver.tokenFallback(_from, _value, _data);
    }
  }



  // ############################################
  // ########### ADMIN FUNCTIONS ################
  // ############################################

  function powerDown(address powerAddr, address _holder, uint256 _amountBabz) public onlyOwner {
    bytes memory empty;
    _checkDestination(powerAddr, _holder, _amountBabz, empty);
    // NTZ transfered from power pool to user's balance
    Transfer(powerAddr, _holder, _amountBabz);
  }


  function asyncSend(address _pullAddr, address _dest, uint256 _amountWei) public onlyOwner {
    assert(_amountWei <= this.balance);
    PullPayInterface(_pullAddr).asyncSend.value(_amountWei)(_dest);
  }


  // ############################################
  // ########### PUBLIC FUNCTIONS ###############
  // ############################################

  function approve(address _spender, uint256 _amountBabz) public {
    ControllerInterface(owner).approve(msg.sender, _spender, _amountBabz);
    Approval(msg.sender, _spender, _amountBabz);
  }

  function transfer(address _to, uint256 _amountBabz, bytes _data) public returns (bool) {
    ControllerInterface(owner).transfer(msg.sender, _to, _amountBabz, _data);
    Transfer(msg.sender, _to, _amountBabz);
    _checkDestination(msg.sender, _to, _amountBabz, _data);
    return true;
  }

  function transfer(address _to, uint256 _amountBabz) public returns (bool) {
    bytes memory empty;
    return transfer(_to, _amountBabz, empty);
  }

  function transData(address _to, uint256 _amountBabz, bytes _data) public returns (bool) {
    return transfer(_to, _amountBabz, _data);
  }

  function transferFrom(address _from, address _to, uint256 _amountBabz, bytes _data) public returns (bool) {
    ControllerInterface(owner).transferFrom(msg.sender, _from, _to, _amountBabz, _data);
    Transfer(_from, _to, _amountBabz);
    _checkDestination(_from, _to, _amountBabz, _data);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _amountBabz) public returns (bool) {
    bytes memory empty;
    return transferFrom(_from, _to, _amountBabz, empty);
  }

  function () public payable {
    uint256 price = ControllerInterface(owner).ceiling();
    purchase(price);
    require(msg.value > 0);
  }

  function purchase(uint256 _price) public payable {
    require(msg.value > 0);
    uint256 amountBabz = ControllerInterface(owner).purchase(msg.sender, msg.value, _price);
    Transfer(owner, msg.sender, amountBabz);
    bytes memory empty;
    _checkDestination(address(this), msg.sender, amountBabz, empty);
  }

  function sell(uint256 _price, uint256 _amountBabz) public {
    require(_amountBabz != 0);
    ControllerInterface(owner).sell(msg.sender, _price, _amountBabz);
    Sell(msg.sender, _amountBabz);
  }

  function powerUp(uint256 _amountBabz) public {
    Transfer(msg.sender, owner, _amountBabz);
    ControllerInterface(owner).powerUp(msg.sender, msg.sender, _amountBabz);
  }

}


contract MarketEnabled is NutzEnabled {

  uint256 constant INFINITY = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  // address of the pull payemnt satelite
  address public pullAddr;

  // the Token sale mechanism parameters:
  // purchasePrice is the number of NTZ received for purchase with 1 ETH
  uint256 internal purchasePrice;

  // floor is the number of NTZ needed, to receive 1 ETH in sell
  uint256 internal salePrice;

  function MarketEnabled(address _pullAddr, address _storageAddr, address _nutzAddr)
    NutzEnabled(_nutzAddr, _storageAddr) {
    pullAddr = _pullAddr;
  }


  function ceiling() constant returns (uint256) {
    return purchasePrice;
  }

  // returns either the salePrice, or if reserve does not suffice
  // for active supply, returns maxFloor
  function floor() constant returns (uint256) {
    if (nutzAddr.balance == 0) {
      return INFINITY;
    }
    uint256 maxFloor = activeSupply().mul(1000000).div(nutzAddr.balance); // 1,000,000 WEI, used as price factor
    // return max of maxFloor or salePrice
    return maxFloor >= salePrice ? maxFloor : salePrice;
  }

  function moveCeiling(uint256 _newPurchasePrice) public onlyAdmins {
    require(_newPurchasePrice <= salePrice);
    purchasePrice = _newPurchasePrice;
  }

  function moveFloor(uint256 _newSalePrice) public onlyAdmins {
    require(_newSalePrice >= purchasePrice);
    // moveFloor fails if the administrator tries to push the floor so low
    // that the sale mechanism is no longer able to buy back all tokens at
    // the floor price if those funds were to be withdrawn.
    if (_newSalePrice < INFINITY) {
      require(nutzAddr.balance >= activeSupply().mul(1000000).div(_newSalePrice)); // 1,000,000 WEI, used as price factor
    }
    salePrice = _newSalePrice;
  }

  function purchase(address _sender, uint256 _value, uint256 _price) public onlyNutz whenNotPaused returns (uint256) {
    // disable purchases if purchasePrice set to 0
    require(purchasePrice > 0);
    require(_price == purchasePrice);

    uint256 amountBabz = purchasePrice.mul(_value).div(1000000); // 1,000,000 WEI, used as price factor
    // avoid deposits that issue nothing
    // might happen with very high purchase price
    require(amountBabz > 0);

    // make sure power pool grows proportional to economy
    uint256 activeSup = activeSupply();
    uint256 powPool = powerPool();
    if (powPool > 0) {
      uint256 powerShare = powPool.mul(amountBabz).div(activeSup.add(burnPool()));
      _setPowerPool(powPool.add(powerShare));
    }
    _setActiveSupply(activeSup.add(amountBabz));
    _setBabzBalanceOf(_sender, babzBalanceOf(_sender).add(amountBabz));
    return amountBabz;
  }

  function sell(address _from, uint256 _price, uint256 _amountBabz) public onlyNutz whenNotPaused {
    uint256 effectiveFloor = floor();
    require(_amountBabz != 0);
    require(effectiveFloor != INFINITY);
    require(_price == effectiveFloor);

    uint256 amountWei = _amountBabz.mul(1000000).div(effectiveFloor);  // 1,000,000 WEI, used as price factor
    require(amountWei > 0);
    // make sure power pool shrinks proportional to economy
    uint256 powPool = powerPool();
    uint256 activeSup = activeSupply();
    if (powPool > 0) {
      uint256 powerShare = powPool.mul(_amountBabz).div(activeSup.add(burnPool()));
      _setPowerPool(powPool.sub(powerShare));
    }
    _setActiveSupply(activeSup.sub(_amountBabz));
    _setBabzBalanceOf(_from, babzBalanceOf(_from).sub(_amountBabz));
    Nutz(nutzAddr).asyncSend(pullAddr, _from, amountWei);
  }


  // withdraw excessive reserve - i.e. milestones
  function allocateEther(uint256 _amountWei, address _beneficiary) public onlyAdmins {
    require(_amountWei > 0);
    // allocateEther fails if allocating those funds would mean that the
    // sale mechanism is no longer able to buy back all tokens at the floor
    // price if those funds were to be withdrawn.
    require(nutzAddr.balance.sub(_amountWei) >= activeSupply().mul(1000000).div(salePrice)); // 1,000,000 WEI, used as price factor
    Nutz(nutzAddr).asyncSend(pullAddr, _beneficiary, _amountWei);
  }

}


contract PowerEnabled is MarketEnabled {

  // satelite contract addresses
  address public powerAddr;

  // maxPower is a limit of total power that can be outstanding
  // maxPower has a valid value between outstandingPower and authorizedPow/2
  uint256 public maxPower = 0;

  // time it should take to power down
  uint256 public downtime;

  uint public constant MIN_SHARE_OF_POWER = 100000;

  modifier onlyPower() {
    require(msg.sender == powerAddr);
    _;
  }

  function PowerEnabled(address _powerAddr, address _pullAddr, address _storageAddr, address _nutzAddr)
    MarketEnabled(_pullAddr, _nutzAddr, _storageAddr) {
    powerAddr = _powerAddr;
  }

  function setMaxPower(uint256 _maxPower) public onlyAdmins {
    require(outstandingPower() <= _maxPower && _maxPower < authorizedPower());
    maxPower = _maxPower;
  }

  function setDowntime(uint256 _downtime) public onlyAdmins {
    downtime = _downtime;
  }

  function minimumPowerUpSizeBabz() public constant returns (uint256) {
    uint256 completeSupplyBabz = completeSupply();
    if (completeSupplyBabz == 0) {
      return INFINITY;
    }
    return completeSupplyBabz.div(MIN_SHARE_OF_POWER);
  }

  // this is called when NTZ are deposited into the burn pool
  function dilutePower(uint256 _amountBabz, uint256 _amountPower) public onlyAdmins {
    uint256 authorizedPow = authorizedPower();
    uint256 totalBabz = completeSupply();
    if (authorizedPow == 0) {
      // during the first capital increase, set value directly as authorized shares
      _setAuthorizedPower((_amountPower > 0) ? _amountPower : _amountBabz.add(totalBabz));
    } else {
      // in later increases, expand authorized shares at same rate like economy
      _setAuthorizedPower(authorizedPow.mul(totalBabz.add(_amountBabz)).div(totalBabz));
    }
    _setBurnPool(burnPool().add(_amountBabz));
  }

  function _slashPower(address _holder, uint256 _value, bytes32 _data) internal {
    uint256 previouslyOutstanding = outstandingPower();
    _setOutstandingPower(previouslyOutstanding.sub(_value));
    // adjust size of power pool
    uint256 powPool = powerPool();
    uint256 slashingBabz = _value.mul(powPool).div(previouslyOutstanding);
    _setPowerPool(powPool.sub(slashingBabz));
    // put event into satelite contract
    Power(powerAddr).slashPower(_holder, _value, _data);
  }

  function slashPower(address _holder, uint256 _value, bytes32 _data) public onlyAdmins {
    _setPowerBalanceOf(_holder, powerBalanceOf(_holder).sub(_value));
    _slashPower(_holder, _value, _data);
  }

  function slashDownRequest(uint256 _pos, address _holder, uint256 _value, bytes32 _data) public onlyAdmins {
    var (total, left, start) = downs(_holder);
    left = left.sub(_value);
    _setDownRequest(_holder, total, left, start);
    _slashPower(_holder, _value, _data);
  }

  // this is called when NTZ are deposited into the power pool
  function powerUp(address _sender, address _from, uint256 _amountBabz) public onlyNutz whenNotPaused {
    uint256 authorizedPow = authorizedPower();
    require(authorizedPow != 0);
    require(_amountBabz != 0);
    uint256 totalBabz = completeSupply();
    require(totalBabz != 0);
    uint256 amountPow = _amountBabz.mul(authorizedPow).div(totalBabz);
    // check pow limits
    uint256 outstandingPow = outstandingPower();
    require(outstandingPow.add(amountPow) <= maxPower);
    uint256 powBal = powerBalanceOf(_from).add(amountPow);
    require(powBal >= authorizedPow.div(MIN_SHARE_OF_POWER));

    if (_sender != _from) {
      allowed[_from][_sender] = allowed[_from][_sender].sub(_amountBabz);
    }

    _setOutstandingPower(outstandingPow.add(amountPow));
    _setPowerBalanceOf(_from, powBal);
    _setActiveSupply(activeSupply().sub(_amountBabz));
    _setBabzBalanceOf(_from, babzBalanceOf(_from).sub(_amountBabz));
    _setPowerPool(powerPool().add(_amountBabz));
    Power(powerAddr).powerUp(_from, amountPow);
  }

  function powerTotalSupply() constant returns (uint256) {
    uint256 issuedPower = authorizedPower().div(2);
    // return max of maxPower or issuedPower
    return maxPower >= issuedPower ? maxPower : issuedPower;
  }

  function _vestedDown(uint256 _total, uint256 _left, uint256 _start, uint256 _now) internal constant returns (uint256) {
    if (_now <= _start) {
      return 0;
    }
    // calculate amountVested
    // amountVested is amount that can be withdrawn according to time passed
    uint256 timePassed = _now.sub(_start);
    if (timePassed > downtime) {
     timePassed = downtime;
    }
    uint256 amountVested = _total.mul(timePassed).div(downtime);
    uint256 amountFrozen = _total.sub(amountVested);
    if (_left <= amountFrozen) {
      return 0;
    }
    return _left.sub(amountFrozen);
  }

  function createDownRequest(address _owner, uint256 _amountPower) public onlyPower whenNotPaused {
    // prevent powering down tiny amounts
    // when powering down, at least completeSupply/minShare Power should be claimed
    require(_amountPower >= authorizedPower().div(MIN_SHARE_OF_POWER));
    _setPowerBalanceOf(_owner, powerBalanceOf(_owner).sub(_amountPower));

    var (, left, ) = downs(_owner);
    uint256 total = _amountPower.add(left);
    _setDownRequest(_owner, total, total, now);
  }

  // executes a powerdown request
  function downTick(address _holder, uint256 _now) public onlyPower whenNotPaused {
    var (total, left, start) = downs(_holder);
    uint256 amountPow = _vestedDown(total, left, start, _now);

    // prevent power down in tiny steps
    uint256 minStep = total.div(10);
    require(left <= minStep || minStep <= amountPow);

    // calculate token amount representing share of power
    uint256 amountBabz = amountPow.mul(completeSupply()).div(authorizedPower());

    // transfer power and tokens
    _setOutstandingPower(outstandingPower().sub(amountPow));
    left = left.sub(amountPow);
    _setPowerPool(powerPool().sub(amountBabz));
    _setActiveSupply(activeSupply().add(amountBabz));
    _setBabzBalanceOf(_holder, babzBalanceOf(_holder).add(amountBabz));
    // down request completed
    if (left == 0) {
      start = 0;
      total = 0;
    }
    // TODO
    _setDownRequest(_holder, total, left, start);
    Nutz(nutzAddr).powerDown(powerAddr, _holder, amountBabz);
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}





contract Controller is PowerEnabled {

  function Controller(address _powerAddr, address _pullAddr, address _nutzAddr, address _storageAddr) 
    PowerEnabled(_powerAddr, _pullAddr, _nutzAddr, _storageAddr) {
  }

  function setContracts(address _storageAddr, address _nutzAddr, address _powerAddr, address _pullAddr) public onlyAdmins whenPaused {
    storageAddr = _storageAddr;
    nutzAddr = _nutzAddr;
    powerAddr = _powerAddr;
    pullAddr = _pullAddr;
  }

  function changeDailyLimit(uint256 _dailyLimit) public onlyAdmins {
    PullPayment(pullAddr).changeDailyLimit(_dailyLimit);
  }

  function kill(address _newController) public onlyAdmins whenPaused {
    if (powerAddr != address(0)) { Ownable(powerAddr).transferOwnership(msg.sender); }
    if (pullAddr != address(0)) { Ownable(pullAddr).transferOwnership(msg.sender); }
    if (nutzAddr != address(0)) { Ownable(nutzAddr).transferOwnership(msg.sender); }
    if (storageAddr != address(0)) { Ownable(storageAddr).transferOwnership(msg.sender); }
    selfdestruct(_newController);
  }

}