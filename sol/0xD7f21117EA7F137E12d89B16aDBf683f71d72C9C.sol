/* Author: Victor Mezrin  victor@mezrin.com */


pragma solidity ^0.4.18;



/**
 * @title SafeMathInterface
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMathInterface {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256);
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256);
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256);
  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256);
}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath is SafeMathInterface {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title CommonModifiersInterface
 * @dev Base contract which contains common checks.
 */
contract CommonModifiersInterface {

  /**
   * @dev Assemble the given address bytecode. If bytecode exists then the _addr is a contract.
   */
  function isContract(address _targetAddress) internal constant returns (bool);

  /**
   * @dev modifier to allow actions only when the _targetAddress is a contract.
   */
  modifier onlyContractAddress(address _targetAddress) {
    require(isContract(_targetAddress) == true);
    _;
  }
}



/**
 * @title CommonModifiers
 * @dev Base contract which contains common checks.
 */
contract CommonModifiers is CommonModifiersInterface {

  /**
   * @dev Assemble the given address bytecode. If bytecode exists then the _addr is a contract.
   */
  function isContract(address _targetAddress) internal constant returns (bool) {
    require (_targetAddress != address(0x0));

    uint256 length;
    assembly {
      //retrieve the size of the code on target address, this needs assembly
      length := extcodesize(_targetAddress)
    }
    return (length > 0);
  }
}



/**
 * @title AssetIDInterface
 * @dev Interface of a contract that assigned to an asset (JNT, jUSD etc.)
 * @dev Contracts for the same asset (like JNT, jUSD etc.) will have the same AssetID.
 * @dev This will help to avoid misconfiguration of contracts
 */
contract AssetIDInterface {
  function getAssetID() public constant returns (string);
  function getAssetIDHash() public constant returns (bytes32);
}



/**
 * @title AssetID
 * @dev Base contract implementing AssetIDInterface
 */
contract AssetID is AssetIDInterface {

  /* Storage */

  string assetID;


  /* Constructor */

  function AssetID(string _assetID) public {
    require(bytes(_assetID).length > 0);

    assetID = _assetID;
  }


  /* Getters */

  function getAssetID() public constant returns (string) {
    return assetID;
  }

  function getAssetIDHash() public constant returns (bytes32) {
    return keccak256(assetID);
  }
}


/**
 * @title OwnableInterface
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract OwnableInterface {

  /**
   * @dev The getter for "owner" contract variable
   */
  function getOwner() public constant returns (address);

  /**
   * @dev Throws if called by any account other than the current owner.
   */
  modifier onlyOwner() {
    require (msg.sender == getOwner());
    _;
  }
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is OwnableInterface {

  /* Storage */

  address owner = address(0x0);
  address proposedOwner = address(0x0);


  /* Events */

  event OwnerAssignedEvent(address indexed newowner);
  event OwnershipOfferCreatedEvent(address indexed currentowner, address indexed proposedowner);
  event OwnershipOfferAcceptedEvent(address indexed currentowner, address indexed proposedowner);
  event OwnershipOfferCancelledEvent(address indexed currentowner, address indexed proposedowner);


  /**
   * @dev The constructor sets the initial `owner` to the passed account.
   */
  function Ownable() public {
    owner = msg.sender;

    OwnerAssignedEvent(owner);
  }


  /**
   * @dev Old owner requests transfer ownership to the new owner.
   * @param _proposedOwner The address to transfer ownership to.
   */
  function createOwnershipOffer(address _proposedOwner) external onlyOwner {
    require (proposedOwner == address(0x0));
    require (_proposedOwner != address(0x0));
    require (_proposedOwner != address(this));

    proposedOwner = _proposedOwner;

    OwnershipOfferCreatedEvent(owner, _proposedOwner);
  }


  /**
   * @dev Allows the new owner to accept an ownership offer to contract control.
   */
  //noinspection UnprotectedFunction
  function acceptOwnershipOffer() external {
    require (proposedOwner != address(0x0));
    require (msg.sender == proposedOwner);

    address _oldOwner = owner;
    owner = proposedOwner;
    proposedOwner = address(0x0);

    OwnerAssignedEvent(owner);
    OwnershipOfferAcceptedEvent(_oldOwner, owner);
  }


  /**
   * @dev Old owner cancels transfer ownership to the new owner.
   */
  function cancelOwnershipOffer() external {
    require (proposedOwner != address(0x0));
    require (msg.sender == owner || msg.sender == proposedOwner);

    address _oldProposedOwner = proposedOwner;
    proposedOwner = address(0x0);

    OwnershipOfferCancelledEvent(owner, _oldProposedOwner);
  }


  /**
   * @dev The getter for "owner" contract variable
   */
  function getOwner() public constant returns (address) {
    return owner;
  }

  /**
   * @dev The getter for "proposedOwner" contract variable
   */
  function getProposedOwner() public constant returns (address) {
    return proposedOwner;
  }
}



/**
 * @title ManageableInterface
 * @dev Contract that allows to grant permissions to any address
 * @dev In real life we are no able to perform all actions with just one Ethereum address
 * @dev because risks are too high.
 * @dev Instead owner delegates rights to manage an contract to the different addresses and
 * @dev stay able to revoke permissions at any time.
 */
contract ManageableInterface {

  /**
   * @dev Function to check if the manager can perform the action or not
   * @param _manager        address Manager`s address
   * @param _permissionName string  Permission name
   * @return True if manager is enabled and has been granted needed permission
   */
  function isManagerAllowed(address _manager, string _permissionName) public constant returns (bool);

  /**
   * @dev Modifier to use in derived contracts
   */
  modifier onlyAllowedManager(string _permissionName) {
    require(isManagerAllowed(msg.sender, _permissionName) == true);
    _;
  }
}



contract Manageable is OwnableInterface,
                       ManageableInterface {

  /* Storage */

  mapping (address => bool) managerEnabled;  // hard switch for a manager - on/off
  mapping (address => mapping (string => bool)) managerPermissions;  // detailed info about manager`s permissions


  /* Events */

  event ManagerEnabledEvent(address indexed manager);
  event ManagerDisabledEvent(address indexed manager);
  event ManagerPermissionGrantedEvent(address indexed manager, string permission);
  event ManagerPermissionRevokedEvent(address indexed manager, string permission);


  /* Configure contract */

  /**
   * @dev Function to add new manager
   * @param _manager address New manager
   */
  function enableManager(address _manager) external onlyOwner onlyValidManagerAddress(_manager) {
    require(managerEnabled[_manager] == false);

    managerEnabled[_manager] = true;
    ManagerEnabledEvent(_manager);
  }

  /**
   * @dev Function to remove existing manager
   * @param _manager address Existing manager
   */
  function disableManager(address _manager) external onlyOwner onlyValidManagerAddress(_manager) {
    require(managerEnabled[_manager] == true);

    managerEnabled[_manager] = false;
    ManagerDisabledEvent(_manager);
  }

  /**
   * @dev Function to grant new permission to the manager
   * @param _manager        address Existing manager
   * @param _permissionName string  Granted permission name
   */
  function grantManagerPermission(
    address _manager, string _permissionName
  )
    external
    onlyOwner
    onlyValidManagerAddress(_manager)
    onlyValidPermissionName(_permissionName)
  {
    require(managerPermissions[_manager][_permissionName] == false);

    managerPermissions[_manager][_permissionName] = true;
    ManagerPermissionGrantedEvent(_manager, _permissionName);
  }

  /**
   * @dev Function to revoke permission of the manager
   * @param _manager        address Existing manager
   * @param _permissionName string  Revoked permission name
   */
  function revokeManagerPermission(
    address _manager, string _permissionName
  )
    external
    onlyOwner
    onlyValidManagerAddress(_manager)
    onlyValidPermissionName(_permissionName)
  {
    require(managerPermissions[_manager][_permissionName] == true);

    managerPermissions[_manager][_permissionName] = false;
    ManagerPermissionRevokedEvent(_manager, _permissionName);
  }


  /* Getters */

  /**
   * @dev Function to check manager status
   * @param _manager address Manager`s address
   * @return True if manager is enabled
   */
  function isManagerEnabled(
    address _manager
  )
    public
    constant
    onlyValidManagerAddress(_manager)
    returns (bool)
  {
    return managerEnabled[_manager];
  }

  /**
   * @dev Function to check permissions of a manager
   * @param _manager        address Manager`s address
   * @param _permissionName string  Permission name
   * @return True if manager has been granted needed permission
   */
  function isPermissionGranted(
    address _manager, string _permissionName
  )
    public
    constant
    onlyValidManagerAddress(_manager)
    onlyValidPermissionName(_permissionName)
    returns (bool)
  {
    return managerPermissions[_manager][_permissionName];
  }

  /**
   * @dev Function to check if the manager can perform the action or not
   * @param _manager        address Manager`s address
   * @param _permissionName string  Permission name
   * @return True if manager is enabled and has been granted needed permission
   */
  function isManagerAllowed(
    address _manager, string _permissionName
  )
    public
    constant
    onlyValidManagerAddress(_manager)
    onlyValidPermissionName(_permissionName)
    returns (bool)
  {
    return (managerEnabled[_manager] && managerPermissions[_manager][_permissionName]);
  }


  /* Helpers */

  /**
   * @dev Modifier to check manager address
   */
  modifier onlyValidManagerAddress(address _manager) {
    require(_manager != address(0x0));
    _;
  }

  /**
   * @dev Modifier to check name of manager permission
   */
  modifier onlyValidPermissionName(string _permissionName) {
    require(bytes(_permissionName).length != 0);
    _;
  }
}



/**
 * @title PausableInterface
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * @dev Based on zeppelin's Pausable, but integrated with Manageable
 * @dev Contract is in paused state by default and should be explicitly unlocked
 */
contract PausableInterface {

  /**
   * Events
   */

  event PauseEvent();
  event UnpauseEvent();


  /**
   * @dev called by the manager to pause, triggers stopped state
   */
  function pauseContract() public;

  /**
   * @dev called by the manager to unpause, returns to normal state
   */
  function unpauseContract() public;

  /**
   * @dev The getter for "paused" contract variable
   */
  function getPaused() public constant returns (bool);


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenContractNotPaused() {
    require(getPaused() == false);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenContractPaused {
    require(getPaused() == true);
    _;
  }
}



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * @dev Based on zeppelin's Pausable, but integrated with Manageable
 * @dev Contract is in paused state by default and should be explicitly unlocked
 */
contract Pausable is ManageableInterface,
                     PausableInterface {

  /**
   * Storage
   */

  bool paused = true;


  /**
   * @dev called by the manager to pause, triggers stopped state
   */
  function pauseContract() public onlyAllowedManager('pause_contract') whenContractNotPaused {
    paused = true;
    PauseEvent();
  }

  /**
   * @dev called by the manager to unpause, returns to normal state
   */
  function unpauseContract() public onlyAllowedManager('unpause_contract') whenContractPaused {
    paused = false;
    UnpauseEvent();
  }

  /**
   * @dev The getter for "paused" contract variable
   */
  function getPaused() public constant returns (bool) {
    return paused;
  }
}



/**
 * @title BytecodeExecutorInterface interface
 * @dev Implementation of a contract that execute any bytecode on behalf of the contract
 * @dev Last resort for the immutable and not-replaceable contract :)
 */
contract BytecodeExecutorInterface {

  /* Events */

  event CallExecutedEvent(address indexed target,
                          uint256 suppliedGas,
                          uint256 ethValue,
                          bytes32 transactionBytecodeHash);
  event DelegatecallExecutedEvent(address indexed target,
                                  uint256 suppliedGas,
                                  bytes32 transactionBytecodeHash);


  /* Functions */

  function executeCall(address _target, uint256 _suppliedGas, uint256 _ethValue, bytes _transactionBytecode) external;
  function executeDelegatecall(address _target, uint256 _suppliedGas, bytes _transactionBytecode) external;
}



/**
 * @title BytecodeExecutor
 * @dev Implementation of a contract that execute any bytecode on behalf of the contract
 * @dev Last resort for the immutable and not-replaceable contract :)
 */
contract BytecodeExecutor is ManageableInterface,
                             BytecodeExecutorInterface {

  /* Storage */

  bool underExecution = false;


  /* BytecodeExecutorInterface */

  function executeCall(
    address _target,
    uint256 _suppliedGas,
    uint256 _ethValue,
    bytes _transactionBytecode
  )
    external
    onlyAllowedManager('execute_call')
  {
    require(underExecution == false);

    underExecution = true; // Avoid recursive calling
    _target.call.gas(_suppliedGas).value(_ethValue)(_transactionBytecode);
    underExecution = false;

    CallExecutedEvent(_target, _suppliedGas, _ethValue, keccak256(_transactionBytecode));
  }

  function executeDelegatecall(
    address _target,
    uint256 _suppliedGas,
    bytes _transactionBytecode
  )
    external
    onlyAllowedManager('execute_delegatecall')
  {
    require(underExecution == false);

    underExecution = true; // Avoid recursive calling
    _target.delegatecall.gas(_suppliedGas)(_transactionBytecode);
    underExecution = false;

    DelegatecallExecutedEvent(_target, _suppliedGas, keccak256(_transactionBytecode));
  }
}



/**
 * @title CrydrStorageBaseInterface interface
 * @dev Interface of a contract that manages balance of an CryDR
 */
contract CrydrStorageBaseInterface {

  /* Events */

  event CrydrControllerChangedEvent(address indexed crydrcontroller);


  /* Configuration */

  function setCrydrController(address _newController) public;
  function getCrydrController() public constant returns (address);
}



/**
 * @title CrydrStorageBase
 */
contract CrydrStorageBase is CommonModifiersInterface,
                             AssetIDInterface,
                             ManageableInterface,
                             PausableInterface,
                             CrydrStorageBaseInterface {

  /* Storage */

  address crydrController = address(0x0);


  /* CrydrStorageBaseInterface */

  /* Configuration */

  function setCrydrController(
    address _crydrController
  )
    public
    whenContractPaused
    onlyContractAddress(_crydrController)
    onlyAllowedManager('set_crydr_controller')
  {
    require(_crydrController != address(crydrController));
    require(_crydrController != address(this));

    crydrController = _crydrController;
    CrydrControllerChangedEvent(_crydrController);
  }

  function getCrydrController() public constant returns (address) {
    return address(crydrController);
  }


  /* PausableInterface */

  /**
   * @dev Override method to ensure that contract properly configured before it is unpaused
   */
  function unpauseContract() public {
    require(isContract(crydrController) == true);
    require(getAssetIDHash() == AssetIDInterface(crydrController).getAssetIDHash());

    super.unpauseContract();
  }
}



/**
 * @title CrydrStorageBlocksInterface interface
 * @dev Interface of a contract that manages balance of an CryDR
 */
contract CrydrStorageBlocksInterface {

  /* Events */

  event AccountBlockedEvent(address indexed account);
  event AccountUnblockedEvent(address indexed account);
  event AccountFundsBlockedEvent(address indexed account, uint256 value);
  event AccountFundsUnblockedEvent(address indexed account, uint256 value);


  /* Low-level change of blocks and getters */

  function blockAccount(address _account) public;
  function unblockAccount(address _account) public;
  function getAccountBlocks(address _account) public constant returns (uint256);

  function blockAccountFunds(address _account, uint256 _value) public;
  function unblockAccountFunds(address _account, uint256 _value) public;
  function getAccountBlockedFunds(address _account) public constant returns (uint256);
}



/**
 * @title CrydrStorageBlocks
 */
contract CrydrStorageBlocks is SafeMathInterface,
                               PausableInterface,
                               CrydrStorageBaseInterface,
                               CrydrStorageBlocksInterface {

  /* Storage */

  mapping (address => uint256) accountBlocks;
  mapping (address => uint256) accountBlockedFunds;


  /* Constructor */

  function CrydrStorageBlocks() public {
    accountBlocks[0x0] = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  }


  /* Low-level change of blocks and getters */

  function blockAccount(
    address _account
  )
    public
  {
    require(msg.sender == getCrydrController());

    require(_account != address(0x0));

    accountBlocks[_account] = safeAdd(accountBlocks[_account], 1);
    AccountBlockedEvent(_account);
  }

  function unblockAccount(
    address _account
  )
    public
  {
    require(msg.sender == getCrydrController());

    require(_account != address(0x0));

    accountBlocks[_account] = safeSub(accountBlocks[_account], 1);
    AccountUnblockedEvent(_account);
  }

  function getAccountBlocks(
    address _account
  )
    public
    constant
    returns (uint256)
  {
    require(_account != address(0x0));

    return accountBlocks[_account];
  }

  function blockAccountFunds(
    address _account,
    uint256 _value
  )
    public
  {
    require(msg.sender == getCrydrController());

    require(_account != address(0x0));
    require(_value > 0);

    accountBlockedFunds[_account] = safeAdd(accountBlockedFunds[_account], _value);
    AccountFundsBlockedEvent(_account, _value);
  }

  function unblockAccountFunds(
    address _account,
    uint256 _value
  )
    public
  {
    require(msg.sender == getCrydrController());

    require(_account != address(0x0));
    require(_value > 0);

    accountBlockedFunds[_account] = safeSub(accountBlockedFunds[_account], _value);
    AccountFundsUnblockedEvent(_account, _value);
  }

  function getAccountBlockedFunds(
    address _account
  )
    public
    constant
    returns (uint256)
  {
    require(_account != address(0x0));

    return accountBlockedFunds[_account];
  }
}



/**
 * @title CrydrStorageBalanceInterface interface
 * @dev Interface of a contract that manages balance of an CryDR
 */
contract CrydrStorageBalanceInterface {

  /* Events */

  event AccountBalanceIncreasedEvent(address indexed account, uint256 value);
  event AccountBalanceDecreasedEvent(address indexed account, uint256 value);


  /* Low-level change of balance. Implied that totalSupply kept in sync. */

  function increaseBalance(address _account, uint256 _value) public;
  function decreaseBalance(address _account, uint256 _value) public;
  function getBalance(address _account) public constant returns (uint256);
  function getTotalSupply() public constant returns (uint256);
}



/**
 * @title CrydrStorageBalance
 */
contract CrydrStorageBalance is SafeMathInterface,
                                PausableInterface,
                                CrydrStorageBaseInterface,
                                CrydrStorageBalanceInterface {

  /* Storage */

  mapping (address => uint256) balances;
  uint256 totalSupply = 0;


  /* Low-level change of balance and getters. Implied that totalSupply kept in sync. */

  function increaseBalance(
    address _account,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(_account != address(0x0));
    require(_value > 0);

    balances[_account] = safeAdd(balances[_account], _value);
    totalSupply = safeAdd(totalSupply, _value);
    AccountBalanceIncreasedEvent(_account, _value);
  }

  function decreaseBalance(
    address _account,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(_account != address(0x0));
    require(_value > 0);

    balances[_account] = safeSub(balances[_account], _value);
    totalSupply = safeSub(totalSupply, _value);
    AccountBalanceDecreasedEvent(_account, _value);
  }

  function getBalance(address _account) public constant returns (uint256) {
    require(_account != address(0x0));

    return balances[_account];
  }

  function getTotalSupply() public constant returns (uint256) {
    return totalSupply;
  }
}



/**
 * @title CrydrStorageAllowanceInterface interface
 * @dev Interface of a contract that manages balance of an CryDR
 */
contract CrydrStorageAllowanceInterface {

  /* Events */

  event AccountAllowanceIncreasedEvent(address indexed owner, address indexed spender, uint256 value);
  event AccountAllowanceDecreasedEvent(address indexed owner, address indexed spender, uint256 value);


  /* Low-level change of allowance */

  function increaseAllowance(address _owner, address _spender, uint256 _value) public;
  function decreaseAllowance(address _owner, address _spender, uint256 _value) public;
  function getAllowance(address _owner, address _spender) public constant returns (uint256);
}



/**
 * @title CrydrStorageAllowance
 */
contract CrydrStorageAllowance is SafeMathInterface,
                                  PausableInterface,
                                  CrydrStorageBaseInterface,
                                  CrydrStorageAllowanceInterface {

  /* Storage */

  mapping (address => mapping (address => uint256)) allowed;


  /* Low-level change of allowance and getters */

  function increaseAllowance(
    address _owner,
    address _spender,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(_owner != address(0x0));
    require(_spender != address(0x0));
    require(_owner != _spender);
    require(_value > 0);

    allowed[_owner][_spender] = safeAdd(allowed[_owner][_spender], _value);
    AccountAllowanceIncreasedEvent(_owner, _spender, _value);
  }

  function decreaseAllowance(
    address _owner,
    address _spender,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(_owner != address(0x0));
    require(_spender != address(0x0));
    require(_owner != _spender);
    require(_value > 0);

    allowed[_owner][_spender] = safeSub(allowed[_owner][_spender], _value);
    AccountAllowanceDecreasedEvent(_owner, _spender, _value);
  }

  function getAllowance(
    address _owner,
    address _spender
  )
    public
    constant
    returns (uint256)
  {
    require(_owner != address(0x0));
    require(_spender != address(0x0));
    require(_owner != _spender);

    return allowed[_owner][_spender];
  }
}



/**
 * @title CrydrStorageERC20Interface interface
 * @dev Interface of a contract that manages balance of an CryDR and have optimization for ERC20 controllers
 */
contract CrydrStorageERC20Interface {

  /* Events */

  event CrydrTransferredEvent(address indexed from, address indexed to, uint256 value);
  event CrydrTransferredFromEvent(address indexed spender, address indexed from, address indexed to, uint256 value);
  event CrydrSpendingApprovedEvent(address indexed owner, address indexed spender, uint256 value);


  /* ERC20 optimization. _msgsender - account that invoked CrydrView */

  function transfer(address _msgsender, address _to, uint256 _value) public;
  function transferFrom(address _msgsender, address _from, address _to, uint256 _value) public;
  function approve(address _msgsender, address _spender, uint256 _value) public;
}



/**
 * @title CrydrStorageERC20
 */
contract CrydrStorageERC20 is SafeMathInterface,
                              PausableInterface,
                              CrydrStorageBaseInterface,
                              CrydrStorageBalanceInterface,
                              CrydrStorageAllowanceInterface,
                              CrydrStorageBlocksInterface,
                              CrydrStorageERC20Interface {

  function transfer(
    address _msgsender,
    address _to,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(_msgsender != _to);
    require(getAccountBlocks(_msgsender) == 0);
    require(safeSub(getBalance(_msgsender), _value) >= getAccountBlockedFunds(_msgsender));

    decreaseBalance(_msgsender, _value);
    increaseBalance(_to, _value);
    CrydrTransferredEvent(_msgsender, _to, _value);
  }

  function transferFrom(
    address _msgsender,
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(getAccountBlocks(_msgsender) == 0);
    require(getAccountBlocks(_from) == 0);
    require(safeSub(getBalance(_from), _value) >= getAccountBlockedFunds(_from));
    require(_from != _to);

    decreaseAllowance(_from, _msgsender, _value);
    decreaseBalance(_from, _value);
    increaseBalance(_to, _value);
    CrydrTransferredFromEvent(_msgsender, _from, _to, _value);
  }

  function approve(
    address _msgsender,
    address _spender,
    uint256 _value
  )
    public
    whenContractNotPaused
  {
    require(msg.sender == getCrydrController());

    require(getAccountBlocks(_msgsender) == 0);
    require(getAccountBlocks(_spender) == 0);

    uint256 currentAllowance = getAllowance(_msgsender, _spender);
    require(currentAllowance != _value);
    if (currentAllowance > _value) {
      decreaseAllowance(_msgsender, _spender, safeSub(currentAllowance, _value));
    } else {
      increaseAllowance(_msgsender, _spender, safeSub(_value, currentAllowance));
    }

    CrydrSpendingApprovedEvent(_msgsender, _spender, _value);
  }
}



/**
 * @title JCashCrydrStorage
 * @dev Implementation of a contract that manages data of an CryDR
 */
contract JCashCrydrStorage is SafeMath,
                              CommonModifiers,
                              AssetID,
                              Ownable,
                              Manageable,
                              Pausable,
                              BytecodeExecutor,
                              CrydrStorageBase,
                              CrydrStorageBalance,
                              CrydrStorageAllowance,
                              CrydrStorageBlocks,
                              CrydrStorageERC20 {

  /* Constructor */

  function JCashCrydrStorage(string _assetID) AssetID(_assetID) public { }
}



contract JNTStorage is JCashCrydrStorage {
  function JNTStorage() JCashCrydrStorage('JNT') public {}
}