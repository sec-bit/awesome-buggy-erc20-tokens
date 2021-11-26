/**
 *  NotaryPlatformToken.sol v1.0.0
 * 
 *  Bilal Arif - https://twitter.com/furusiyya_
 *  Notary Platform
 */

pragma solidity ^0.4.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract Ownable {
     /*
      @title Ownable
      @dev The Ownable contract has an owner address, and provides basic authorization control
      functions, this simplifies the implementation of "user permissions".
    */

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable(address _owner){
    owner = _owner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private rentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}
contract Pausable is Ownable {
  
  event Pause(bool indexed state);

  bool private paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev return the current state of contract
   */
  function Paused() external constant returns(bool){ return paused; }

  /**
   * @dev called by the owner to pause or unpause, triggers stopped state
   * on first call and returns to normal state on second call
   */
  function tweakState() external onlyOwner {
    paused = !paused;
    Pause(paused);
  }

}
contract Allocations{

	// timestamp when token release is enabled
  	uint256 private releaseTime;

	mapping (address => uint256) private allocations;

	function Allocations(){
		releaseTime = now + 200 days;
		allocate();
	}

	/**
	 * @notice NTRY Token distribution between team members.
	 */
    function allocate() private {
      allocations[0xab1cb1740344A9280dC502F3B8545248Dc3045eA] = 4000000 * 1 ether;
      allocations[0x330709A59Ab2D1E1105683F92c1EE8143955a357] = 4000000 * 1 ether;
      allocations[0xAa0887fc6e8896C4A80Ca3368CFd56D203dB39db] = 3000000 * 1 ether;
      allocations[0x1fbA1d22435DD3E7Fa5ba4b449CC550a933E72b3] = 200000 * 1 ether;
      allocations[0xC9d5E2c7e40373ae576a38cD7e62E223C95aBFD4] = 200000 * 1 ether;
      allocations[0xabc0B64a38DE4b767313268F0db54F4cf8816D9C] = 220000 * 1 ether;
      allocations[0x5d85bCDe5060C5Bd00DBeDF5E07F43CE3Ccade6f] = 50000 * 1 ether;
      allocations[0xecb1b0231CBC0B04015F9e5132C62465C128B578] = 500000 * 1 ether;
      allocations[0xFF22FA2B3e5E21817b02a45Ba693B7aC01485a9C] = 2955000 * 1 ether;
    }

	/**
	 * @notice Transfers tokens held by timelock to beneficiary.
	 */
	function release() internal returns (uint256 amount){
		amount = allocations[msg.sender];
		allocations[msg.sender] = 0;
		return amount;
	}

	/**
  	 * @dev returns releaseTime
  	 */
	function RealeaseTime() external constant returns(uint256){ return releaseTime; }

    modifier timeLock() { 
		require(now >= releaseTime);
		_; 
	}

	modifier isTeamMember() { 
		require(allocations[msg.sender] >= 10000 * 1 ether); 
		_; 
	}

}


contract NotaryPlatformToken is Pausable, Allocations, ReentrancyGuard{

  using SafeMath for uint256;

  string constant name = "Notary Platform Token";
  string constant symbol = "NTRY";
  uint8 constant decimals = 18;
  uint256 totalSupply = 150000000 * 1 ether;

  mapping(address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function NotaryPlatformToken() Ownable(0x1538EF80213cde339A333Ee420a85c21905b1b2D){
    // Allocate initial balance to the owner //
    balances[0x244092a2FECFC48259cf810b63BA3B3c0B811DCe] = 134875000 * 1 ether;  
  }


  /** Externals **/

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) external whenNotPaused onlyPayloadSize(2 * 32) returns (bool) {
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) external constant returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) external whenNotPaused returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) external whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) external whenNotPaused returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) external whenNotPaused returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
  * @notice Transfers tokens held by timelock to beneficiary.
  */
  function claim() external whenNotPaused nonReentrant timeLock isTeamMember {
    balances[msg.sender] = balances[msg.sender].add(release());
  }

  /**
   *                  ========== Token migration support ========
   */
  uint256 public totalMigrated;
  bool private upgrading = false;
  MigrationAgent private agent;
  event Migrate(address indexed _from, address indexed _to, uint256 _value);
  event Upgrading(bool status);

  function migrationAgent() external constant returns(address){ return agent; }
  function upgradingEnabled()  external constant returns(bool){ return upgrading; }

  /**
   * @notice Migrate tokens to the new token contract.
   * @dev Required state: Operational Migration
   * @param _value The amount of token to be migrated
   */
  function migrate(uint256 _value) external nonReentrant isUpgrading {
    require(_value > 0);
    require(_value <= balances[msg.sender]);
    require(agent.isMigrationAgent());

    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    totalMigrated = totalMigrated.add(_value);
    
    if(!agent.migrateFrom(msg.sender, _value)){
      revert();
    }
    Migrate(msg.sender, agent, _value);
  }

  /**
   * @notice Set address of migration target contract and enable migration
   * process.
   * @param _agent The address of the MigrationAgent contract
   */
  function setMigrationAgent(address _agent) external isUpgrading onlyOwner {
    require(_agent != 0x00);
    agent = MigrationAgent(_agent);
    if(!agent.isMigrationAgent()){
      revert();
    }
    
    if(agent.originalSupply() != totalSupply){
      revert();
    }
  }

  /**
   * @notice Enable upgrading to allow tokens migration to new contract
   * process.
   */
  function tweakUpgrading() external onlyOwner{
      upgrading = !upgrading;
      Upgrading(upgrading);
  }


  /** Interface marker */
  function isTokenContract() external constant returns (bool) {
    return true;
  }

  modifier isUpgrading() { 
    require(upgrading); 
    _; 
  }


  /**
   * Fix for the ERC20 short address attack
   *
   * http://vessenes.com/the-erc20-short-address-attack-explained/
   */
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length > size + 4);
     _;
  }

  function () {
    //if ether is sent to this address, send it back.
    revert();
  }

}

/// @title Migration Agent interface
contract MigrationAgent {

  uint256 public originalSupply;
  
  function migrateFrom(address _from, uint256 _value) external returns(bool);
  
  /** Interface marker */
  function isMigrationAgent() external constant returns (bool) {
    return true;
  }
}