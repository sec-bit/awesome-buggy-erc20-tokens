pragma solidity ^0.4.13;

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant public returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value) ;
}

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public{
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant public returns (uint balance){
    return balances[_owner];
  }

}

contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) public{
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) public{

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant public returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract IAMEToken is StandardToken {
	using SafeMath for uint256;

	/*// keccak256 hash of hidden cap
	string public constant HIDDEN_CAP = "0xd22f19d54193ff5e08e7ba88c8e52ec1b9fc8d4e0cf177e1be8a764fa5b375fa";*/

	// Events
	event CreatedIAM(address indexed _creator, uint256 _amountOfIAM);
	event IAMRefundedForWei(address indexed _refunder, uint256 _amountOfWei);

	// Token data
	string public constant name = "IAME Token";
	string public constant symbol = "IAM";
	uint256 public constant decimals = 18;  // Since our decimals equals the number of wei per ether, we needn't multiply sent values when converting between IAM and ETH.
	string public version = "1.0";

	// Addresses and contracts
	address public executor;
	address public devETHDestination;
	address public reserveIAMDestination;

	// Sale data
	bool public saleHasEnded;
	bool public minCapReached;
	bool public allowRefund;
	mapping (address => uint256) public ETHContributed;
	uint256 public totalETHRaised;
	uint256 public saleStartBlock;
	uint256 public saleEndBlock;
	uint256 public saleFirstPresaleEndBlock;
	uint256 public constant RESERVE_PORTION_MULTIPLIER = 1;  // Multiplier used after sale
	uint256 public constant SECURITY_ETHER_CAP = 1000000 ether;
	uint256 public constant IAM_PER_ETH_BASE_RATE = 1000;  // 1000 IAM = 1 ETH during normal part of token sale
	uint256 public constant IAM_PER_ETH_PRE_SALE_RATE = 2000;
  uint256 public constant PRE_SALE_CAP = 6000000;

	function IAMEToken(
		address _devETHDestination,
		address _reserveIAMDestination,
		uint256 _saleStartBlock,
		uint256 _saleEndBlock
	) {
		// Reject on invalid ETH destination address or  destination address
		if (_devETHDestination == address(0x0)) revert();
		if (_reserveIAMDestination == address(0x0)) revert();
		// Reject if sale ends before the current block
		if (_saleEndBlock <= block.number) revert();
		// Reject if the sale end time is less than the sale start time
		if (_saleEndBlock <= _saleStartBlock) revert();

		executor = msg.sender;
		saleHasEnded = false;
		minCapReached = false;
		allowRefund = false;
		devETHDestination = _devETHDestination;
		reserveIAMDestination = _reserveIAMDestination;
		totalETHRaised = 0;
		saleStartBlock = _saleStartBlock;
		saleEndBlock = _saleEndBlock;
		saleFirstPresaleEndBlock = saleStartBlock + 62608;  // Equivalent to 24 hours later, assuming 14 second blocks
		totalSupply = 0;
	}

	function () payable {
		// If sale is not active, do not create IAM
		if (saleHasEnded) revert();
		if (block.number < saleStartBlock) revert();
		if (block.number > saleEndBlock) revert();
		// Check if the balance is greater than the security cap
		uint256 newEtherBalance = totalETHRaised.add(msg.value);
		if (newEtherBalance > SECURITY_ETHER_CAP) revert();
		// Do not do anything if the amount of ether sent is 0
		if (0 == msg.value) revert();

		// Calculate the IAM to ETH rate for the current time period of the sale
		uint256 curTokenRate = IAM_PER_ETH_BASE_RATE;
		if (block.number < saleFirstPresaleEndBlock || totalSupply < PRE_SALE_CAP) {
		    curTokenRate = IAM_PER_ETH_PRE_SALE_RATE;
		}

		// Calculate the amount of IAM being purchased
		uint256 amountOfIAM = msg.value.mul(curTokenRate);

		// Ensure that the transaction is safe
		uint256 totalSupplySafe = totalSupply.add(amountOfIAM);
		uint256 balanceSafe = balances[msg.sender].add(amountOfIAM);
		uint256 contributedSafe = ETHContributed[msg.sender].add(msg.value);

		// Update individual and total balances
		totalSupply = totalSupplySafe;
		balances[msg.sender] = balanceSafe;

		totalETHRaised = newEtherBalance;
		ETHContributed[msg.sender] = contributedSafe;

		CreatedIAM(msg.sender, amountOfIAM);
	}

	function endSale() {
		// Do not end an already ended sale
		if (saleHasEnded) revert();
		// Can't end a sale that hasn't hit its minimum cap
		if (!minCapReached) revert();
		// Only allow the owner to end the sale
		if (msg.sender != executor) revert();

		saleHasEnded = true;

		// Calculate and create reserve portion of IAM
		uint256 reserveShare = (totalSupply.mul(RESERVE_PORTION_MULTIPLIER));
		uint256 totalSupplySafe = totalSupply.add(reserveShare);

		totalSupply = totalSupplySafe;
		balances[reserveIAMDestination] = reserveShare;

		CreatedIAM(reserveIAMDestination, reserveShare);

		if (this.balance > 0) {
			if (!devETHDestination.call.value(this.balance)()) revert();
		}
	}

	// Allows BlockIAM to withdraw funds
	function withdrawFunds() {
		// Disallow withdraw if the minimum hasn't been reached
		if (!minCapReached) revert();
		if (0 == this.balance) revert();

		if (!devETHDestination.call.value(this.balance)()) revert();
	}

	// Signals that the sale has reached its minimum funding goal
	function triggerMinCap() {
		if (msg.sender != executor) revert();

		minCapReached = true;
	}

	// Opens refunding.
	function triggerRefund() {
		// No refunds if the sale was successful
		if (saleHasEnded) revert();
		// No refunds if minimum cap is hit
		if (minCapReached) revert();
		// No refunds if the sale is still progressing
		if (block.number < saleEndBlock) revert();
		if (msg.sender != executor) revert();

		allowRefund = true;
	}

	function refund() external {
		// No refunds until it is approved
		if (!allowRefund) revert();
		// Nothing to refund
		if (0 == ETHContributed[msg.sender]) revert();

		// Do the refund.
		uint256 etherAmount = ETHContributed[msg.sender];
		ETHContributed[msg.sender] = 0;

		IAMRefundedForWei(msg.sender, etherAmount);
		if (!msg.sender.send(etherAmount)) revert();
	}

	function changeDeveloperETHDestinationAddress(address _newAddress) {
		if (msg.sender != executor) revert();
		devETHDestination = _newAddress;
	}

	function changeReserveIAMDestinationAddress(address _newAddress) {
		if (msg.sender != executor) revert();
		reserveIAMDestination = _newAddress;
	}

	function transfer(address _to, uint _value) {
		// Cannot transfer unless the minimum cap is hit
		if (!minCapReached) revert();

		super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint _value) {
		// Cannot transfer unless the minimum cap is hit
		if (!minCapReached) revert();

		super.transferFrom(_from, _to, _value);
	}
}