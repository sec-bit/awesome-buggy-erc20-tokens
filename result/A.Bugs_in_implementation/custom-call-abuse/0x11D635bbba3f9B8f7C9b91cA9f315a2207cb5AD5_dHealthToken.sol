pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * Library easily handles the cases of overflow as well as underflow. 
 * Also ensures that balance does nto get naegative
 */
library SafeMath {
	// multiplies two values safely and returns result
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	// devides two values safely and returns result
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return c;
	}

	// subtracts two values safely and returns result
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	// adds two values safely and returns result
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;

	// Event to log whenever the ownership is tranferred
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	/**
	 * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	function Ownable() public {
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
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

/**
 * @title Timestamped
 * @dev The Timestamped contract has sets dummy timestamp for method calls
 */
contract Timestamped is Ownable {
	uint256 public ts = 0;
	uint256 public plus = 0;

	function getBlockTime() public view returns (uint256) {
		if(ts > 0) {
			return ts + plus;
		} else {
			return block.timestamp + plus; 
		}
	}
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
	uint256 public totalSupply;
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		bytes memory empty;
		Transfer(msg.sender, _to, _value, empty);
		return true;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20, BasicToken {

	// tracks the allowance of address. 
	mapping (address => mapping (address => uint256)) internal allowed;


	/**
	 * @dev Transfer tokens from one address to another
	 * @param _from address The address which you want to send tokens from
	 * @param _to address The address which you want to transfer to
	 * @param _value uint256 the amount of tokens to be transferred
	 */
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

		bytes memory empty;
		Transfer(_from, _to, _value, empty);
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
	function approve(address _spender, uint256 _value) public returns (bool) {
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
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	/**
	 * @dev Increase the amount of tokens that an owner allowed to a spender.
	 *
	 * approve should be called when allowed[_spender] == 0. To increment
	 * allowed value is better to use this function to avoid 2 calls (and wait until
	 * the first transaction is mined)
	 * From MonolithDAO Token.sol
	 * @param _spender The address which will spend the funds.
	 * @param _addedValue The amount of tokens to increase the allowance by.
	 */
	function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	/**
	 * @dev Decrease the amount of tokens that an owner allowed to a spender.
	 *
	 * approve should be called when allowed[_spender] == 0. To decrement
	 * allowed value is better to use this function to avoid 2 calls (and wait until
	 * the first transaction is mined)
	 * From MonolithDAO Token.sol
	 * @param _spender The address which will spend the funds.
	 * @param _subtractedValue The amount of tokens to decrease the allowance by.
	 */
	function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}

/**
 * @title ERC23Receiver interface
 * @dev see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC223Receiver {
	 
	struct TKN {
		address sender;
		uint256 value;
		bytes data;
		bytes4 sig;
	}
	
	/**
	 * @dev Fallback function. Our ICO contract should implement this contract to receve ERC23 compatible tokens.
	 * ERC23 protocol checks if contract has implemented this fallback method or not. 
	 * If this method is not implemented then tokens are not sent.
	 * This method is introduced to avoid loss of tokens 
	 *
	 * @param _from The address which will transfer the tokens.
	 * @param _value Amount of tokens received.
	 * @param _data Data sent along with transfer request.
	 */
	function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
		TKN memory tkn;
		tkn.sender = _from;
		tkn.value = _value;
		tkn.data = _data;
		// uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
		// tkn.sig = bytes4(u);
	  
		/* tkn variable is analogue of msg variable of Ether transaction
		*  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
		*  tkn.value the number of tokens that were sent   (analogue of msg.value)
		*  tkn.data is data of token transaction   (analogue of msg.data)
		*  tkn.sig is 4 bytes signature of function
		*  if data of token transaction is a function execution
		*/
	}
}

/**
 * @title ERC23 interface
 * @dev see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC223 {
	uint256 public totalSupply;
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function transfer(address to, uint256 value, bytes data) public returns (bool);
	function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
}

/**
 * @title Standard ERC223Token token
 *
 * @dev Implementation of the ERC23 token.
 * @dev https://github.com/ethereum/EIPs/issues/223
 */

contract ERC223Token is ERC223, StandardToken {
	using SafeMath for uint256;

	/**
	 * @dev Function that is called when a user or another contract wants to transfer funds .
	 * This is method where you can supply fallback function name and that function will be triggered.
	 * This method is added as part of ERC23 standard
	 *
	 * @param _to The address which will receive the tokens.
	 * @param _value Amount of tokens received.
	 * @param _data Data sent along with transfer request.
	 * @param _custom_fallback Name of the method which should be called after transfer happens. If this method does not exists on contract then transaction will fail
	 */
	function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success) {
		// check if receiving is contract
		if(isContract(_to)) {
			// validate the address and balance
			require(_to != address(0));
			require(_value <= balances[msg.sender]);

			// SafeMath.sub will throw if there is not enough balance.
			balances[msg.sender] = balances[msg.sender].sub(_value);
			balances[_to] = balances[_to].add(_value);
	
			// invoke custom fallback function			
			assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
			Transfer(msg.sender, _to, _value, _data);
			return true;
		}
		else {
			// receiver is not a contract so perform normal transfer to address
			return transferToAddress(_to, _value, _data);
		}
	}
  

	/**
	 * @dev Function that is called when a user or another contract wants to transfer funds .
	 * You can pass extra data which can be tracked in event.
	 * This method is added as part of ERC23 standard
	 *
	 * @param _to The address which will receive the tokens.
	 * @param _value Amount of tokens received.
	 * @param _data Data sent along with transfer request.
	 */
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
		// check if receiver is contract address
		if(isContract(_to)) {
			// invoke transfer request to contract
			return transferToContract(_to, _value, _data);
		}
		else {
			// invoke transfer request to normal user wallet address
			return transferToAddress(_to, _value, _data);
		}
	}
  
	/**
	 * @dev Standard function transfer similar to ERC20 transfer with no _data .
	 * Added due to backwards compatibility reasons .
	 *
	 * @param _to The address which will receive the tokens.
	 * @param _value Amount of tokens received.
	 */
	function transfer(address _to, uint256 _value) public returns (bool success) {
		//standard function transfer similar to ERC20 transfer with no _data
		//added due to backwards compatibility reasons
		bytes memory empty;

		// check if receiver is contract address
		if(isContract(_to)) {
			// invoke transfer request to contract
			return transferToContract(_to, _value, empty);
		}
		else {
			// invoke transfer request to normal user wallet address
			return transferToAddress(_to, _value, empty);
		}
	}

	/**
	 * @dev assemble the given address bytecode. If bytecode exists then the _addr is a contract.
	 *
	 * @param _addr The address which need to be checked if contract address or wallet address
	 */
	function isContract(address _addr) private view returns (bool is_contract) {
		uint256 length;
		assembly {
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}
		return (length > 0);
	}

	/**
	 * @dev Function that is called when transaction target is an address. This is private method.
	 *
	 * @param _to The address which will receive the tokens.
	 * @param _value Amount of tokens received.
	 * @param _data Data sent along with transfer request.
	 */
	function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool success) {
		// validate the address and balance
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		// Log the transfer event
		Transfer(msg.sender, _to, _value, _data);
		return true;
	}
  
	/**
	 * @dev Function that is called when transaction target is a contract. This is private method.
	 *
	 * @param _to The address which will receive the tokens.
	 * @param _value Amount of tokens received.
	 * @param _data Data sent along with transfer request.
	 */
	function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
		// validate the address and balance
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		// call fallback function of contract
		ERC223Receiver receiver = ERC223Receiver(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		
		// Log the transfer event
		Transfer(msg.sender, _to, _value, _data);
		return true;
	}
}

/**
* @title dHealthToken
* @dev Very simple ERC23 Token example, where all tokens are pre-assigned to the creator.
*/
contract dHealthToken is ERC223Token, Ownable {

	string public constant name = "dHealth";
	string public constant symbol = "dHt";
	uint256 public constant decimals = 18;

	uint256 constant INITIAL_SUPPLY = 500000000 * 1E18;
	
	/**
	* @dev Constructor that gives msg.sender all of existing tokens.
	*/
	function dHealthToken() public {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
	}

	/**
	* @dev if ether is sent to this address, send it back.
	*/
	function() public payable {
		revert();
	}
}

/**
 * @title dHealthTokenDistributor
 * @dev The Distributor contract has an list of team member addresses and their share, 
 * and provides method which can be called to distribute available smart contract balance across users.
 */
contract dHealthTokenDistributor is Ownable, Timestamped {
	using SafeMath for uint256;

	// The token being sold, this holds reference to main token contract
	dHealthToken public token;

	// token vesting contract addresses
	address public communityContract;
	address public foundersContract;
	address public technicalContract;
	address public managementContract;

	// token vesting contract amounts
	uint256 public communityAmount;
	uint256 public foundersAmount;
	uint256 public technicalAmount;
	uint256 public managementAmount;

	/**
	* @dev Constructor that initializes team and share
	*/
	function dHealthTokenDistributor(address _token, address _communityContract, address _foundersContract, address _technicalContract, address _managementContract) public {
		// set token
		token = dHealthToken(_token);

		// initialize contract addresses
		communityContract = _communityContract;
		foundersContract = _foundersContract;
		technicalContract = _technicalContract;
		managementContract = _managementContract;

		// initialize precentage share
		communityAmount = 10000000 * 1E18;
		foundersAmount = 15000000 * 1E18;
		technicalAmount = 55000000 * 1E18;
		managementAmount = 60000000 * 1E18;
	}

	/**
	* @dev distribute funds.
	*/	
	function distribute() onlyOwner public payable {
		bytes memory empty;

		// distribute funds to community 		
		token.transfer(communityContract, communityAmount, empty);

		// distribute funds to founders 		
		token.transfer(foundersContract, foundersAmount, empty);

		// distribute funds to technical 		
		token.transfer(technicalContract, technicalAmount, empty);

		// distribute funds to management 		
		token.transfer(managementContract, managementAmount, empty);
	}
}

/**
 * @title dHealthEtherDistributor
 * @dev The Distributor contract has an list of team member addresses and their share, 
 * and provides method which can be called to distribute available smart contract balance across users.
 */
contract dHealthEtherDistributor is Ownable, Timestamped {
	using SafeMath for uint256;

	address public projectContract;	
	address public technologyContract;	
	address public founderContract;	

	uint256 public projectShare;
	uint256 public technologyShare;
	uint256 public founderShare;

	/**
	* @dev Constructor that initializes team and share
	*/
	function dHealthEtherDistributor(address _projectContract, address _technologyContract, address _founderContract) public {

		// initialize contract addresses
		projectContract = _projectContract;	
		technologyContract = _technologyContract;	
		founderContract = _founderContract;	

		// initialize precentage share
		projectShare = 72;
		technologyShare = 18;
		founderShare = 10;
	}

	/**
	* @dev distribute funds.
	*/	
	function distribute() onlyOwner public payable {
		uint256 balance = this.balance;
		
		// distribute funds to founders 		
		uint256 founderPart = balance.mul(founderShare).div(100);
		if(founderPart > 0) {
			founderContract.transfer(founderPart);
		}

		// distribute funds to technology 		
		uint256 technologyPart = balance.mul(technologyShare).div(100);
		if(technologyPart > 0) {
			technologyContract.transfer(technologyPart);
		}

		// distribute left balance to project
		uint256 projectPart = this.balance;
		if(projectPart > 0) {
			projectContract.transfer(projectPart);
		}
	}
}

/**
* @title dHealthTokenIncentive
* @dev This is token incentive contract it receives tokens and holds it for certain period of time
*/
contract dHealthTokenIncentive is dHealthTokenDistributor, ERC223Receiver {
	using SafeMath for uint256;

	// The token being sold, this holds reference to main token contract
	dHealthToken public token;

	// amount of token on hold
	uint256 public maxTokenForHold = 140000000 * 1E18;

	// contract timeout 
	uint256 public contractTimeout = 1555286400; // Monday, 15 April 2019 00:00:00

	/**
	* @dev Constructor that initializes vesting contract with contract addresses in parameter
	*/
	function dHealthTokenIncentive(address _token, address _communityContract, address _foundersContract, address _technicalContract, address _managementContract) 
		dHealthTokenDistributor(_token, _communityContract, _foundersContract, _technicalContract, _managementContract)
		public {
		// set token
		token = dHealthToken(_token);
	}

	/**
	* @dev Method called by owner of contract to withdraw all tokens after timeout has reached
	*/
	function withdraw() onlyOwner public {
		require(contractTimeout <= getBlockTime());
		
		// send remaining tokens back to owner.
		uint256 tokens = token.balanceOf(this); 
		bytes memory empty;
		token.transfer(owner, tokens, empty);
	}
}

/**
* @title dHealthTokenGrowth
* @dev This is token growth contract it receives tokens and holds it for certain period of time
*/
contract dHealthTokenGrowth is Ownable, ERC223Receiver, Timestamped {
	using SafeMath for uint256;

	// The token being sold, this holds reference to main token contract
	dHealthToken public token;

	// amount of token on hold
	uint256 public maxTokenForHold = 180000000 * 1E18;

	// exchanges wallet address
	address public exchangesWallet;
	uint256 public exchangesTokens = 45000000 * 1E18;
	uint256 public exchangesLockEndingAt = 1523750400; // Sunday, 15 April 2018 00:00:00
	bool public exchangesStatus = false;

	// countries wallet address
	address public countriesWallet;
	uint256 public countriesTokens = 45000000 * 1E18;
	uint256 public countriesLockEndingAt = 1525132800; // Tuesday, 1 May 2018 00:00:00
	bool public countriesStatus = false;

	// acquisitions wallet address
	address public acquisitionsWallet;
	uint256 public acquisitionsTokens = 45000000 * 1E18;
	uint256 public acquisitionsLockEndingAt = 1526342400; // Tuesday, 15 May 2018 00:00:00
	bool public acquisitionsStatus = false;

	// coindrops wallet address
	address public coindropsWallet;
	uint256 public coindropsTokens = 45000000 * 1E18;
	uint256 public coindropsLockEndingAt = 1527811200; // Friday, 1 June 2018 00:00:00
	bool public coindropsStatus = false;

	// contract timeout 
	uint256 public contractTimeout = 1555286400; // Monday, 15 April 2019 00:00:00

	/**
	* @dev Constructor that initializes vesting contract with contract addresses in parameter
	*/
	function dHealthTokenGrowth(address _token, address _exchangesWallet, address _countriesWallet, address _acquisitionsWallet, address _coindropsWallet) public {
		// set token
		token = dHealthToken(_token);

		// setup wallet addresses
		exchangesWallet = _exchangesWallet;
		countriesWallet = _countriesWallet;
		acquisitionsWallet = _acquisitionsWallet;
		coindropsWallet = _coindropsWallet;
	}

	/**
	* @dev Method called by anyone to withdraw funds to exchanges wallet after locking period
	*/
	function withdrawExchangesToken() public {
		// check if time has reached
		require(exchangesLockEndingAt <= getBlockTime());
		// ensure that tokens are not already transferred
		require(exchangesStatus == false);
		
		// transfer tokens to wallet and change status to prevent double transfer		
		bytes memory empty;
		token.transfer(exchangesWallet, exchangesTokens, empty);
		exchangesStatus = true;
	}

	/**
	* @dev Method called by anyone to withdraw funds to countries wallet after locking period
	*/
	function withdrawCountriesToken() public {
		// check if time has reached
		require(countriesLockEndingAt <= getBlockTime());
		// ensure that tokens are not already transferred
		require(countriesStatus == false);
		
		// transfer tokens to wallet and change status to prevent double transfer		
		bytes memory empty;
		token.transfer(countriesWallet, countriesTokens, empty);
		countriesStatus = true;
	}

	/**
	* @dev Method called by anyone to withdraw funds to acquisitions wallet after locking period
	*/
	function withdrawAcquisitionsToken() public {
		// check if time has reached
		require(acquisitionsLockEndingAt <= getBlockTime());
		// ensure that tokens are not already transferred
		require(acquisitionsStatus == false);
		
		// transfer tokens to wallet and change status to prevent double transfer		
		bytes memory empty;
		token.transfer(acquisitionsWallet, acquisitionsTokens, empty);
		acquisitionsStatus = true;
	}

	/**
	* @dev Method called by anyone to withdraw funds to coindrops wallet after locking period
	*/
	function withdrawCoindropsToken() public {
		// check if time has reached
		require(coindropsLockEndingAt <= getBlockTime());
		// ensure that tokens are not already transferred
		require(coindropsStatus == false);
		
		// transfer tokens to wallet and change status to prevent double transfer		
		bytes memory empty;
		token.transfer(coindropsWallet, coindropsTokens, empty);
		coindropsStatus = true;
	}

	/**
	* @dev Method called by owner of contract to withdraw all tokens after timeout has reached
	*/
	function withdraw() onlyOwner public {
		require(contractTimeout <= getBlockTime());
		
		// send remaining tokens back to owner.
		uint256 tokens = token.balanceOf(this); 
		bytes memory empty;
		token.transfer(owner, tokens, empty);
	}
}


/**
* @title dHealthTokenSale
* @dev This is ICO Contract. 
* This class accepts the token address as argument to talk with contract.
* Once contract is deployed, funds are transferred to ICO smart contract address and then distributed with investor.
* Sending funds to this ensures that no more than desired tokens are sold.
*/
contract dHealthTokenSale is dHealthEtherDistributor, ERC223Receiver {
	using SafeMath for uint256;

	// The token being sold, this holds reference to main token contract
	dHealthToken public token;

	// amount of token to be sold on sale
	uint256 public maxTokenForSale = 180000000 * 1E18;

	// timestamp when phase 1 starts
	uint256 public phase1StartingAt = 1516924800; // Friday, 26 January 2018 00:00:00
	uint256 public phase1EndingAt = 1518134399; // Thursday, 8 February 2018 23:59:59
	uint256 public phase1MaxTokenForSale = maxTokenForSale * 1 / 3;
	uint256 public phase1TokenPriceInEth = 0.0005 ether;
	uint256 public phase1TokenSold = 0;

	// timestamp when phase 2 starts
	uint256 public phase2StartingAt = 1518134400; // Friday, 9 February 2018 00:00:00
	uint256 public phase2EndingAt = 1519343999; // Thursday, 22 February 2018 23:59:59
	uint256 public phase2MaxTokenForSale = maxTokenForSale * 2 / 3;
	uint256 public phase2TokenPriceInEth = 0.000606060606 ether;
	uint256 public phase2TokenSold = 0;

	// timestamp when phase 3 starts
	uint256 public phase3StartingAt = 1519344000; // Friday, 23 February 2018 00:00:00
	uint256 public phase3EndingAt = 1520553599; // Thursday, 8 March 2018 23:59:59
	uint256 public phase3MaxTokenForSale = maxTokenForSale;
	uint256 public phase3TokenPriceInEth = 0.000769230769 ether;
	uint256 public phase3TokenSold = 0;

	// contract timeout to initiate left funds and token transfer
	uint256 public contractTimeout = 1520553600; // Friday, 9 March 2018 00:00:00

	// growth contract address
	address public growthContract;

	// maximum ether invested per transaction
	uint256 public maxEthPerTransaction = 1000 ether;

	// minimum ether invested per transaction
	uint256 public minEthPerTransaction = 0.01 ether;

	// amount of token sold so far
	uint256 public totalTokenSold;

	// amount of ether raised in sale
	uint256 public totalEtherRaised;

	// ether raised per wallet
	mapping(address => uint256) public etherRaisedPerWallet;

	// is contract close and ended
	bool public isClose = false;

	// is contract paused
	bool public isPaused = false;

	// token purchsae event
	event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount, uint256 _timestamp);

	// manual transfer by admin for external purchase
	event TransferManual(address indexed _from, address indexed _to, uint256 _value, string _message);

	/**
	* @dev Constructor that initializes token contract with token address in parameter
	*/
	function dHealthTokenSale(address _token, address _projectContract, address _technologyContract, address _founderContract, address _growthContract)
		dHealthEtherDistributor(_projectContract, _technologyContract, _founderContract)
		public {
		// set token
		token = dHealthToken(_token);

		// set growth contract address
		growthContract = _growthContract;
	}

	/**
	 * @dev Function that validates if the purchase is valid by verifying the parameters
	 *
	 * @param value Amount of ethers sent
	 * @param amount Total number of tokens user is trying to buy.
	 *
	 * @return checks various conditions and returns the bool result indicating validity.
	 */
	function validate(uint256 value, uint256 amount) internal constant returns (bool) {
		// check if timestamp and amount is falling in the range
		bool validTimestamp = false;
		bool validAmount = false;

		// check if phase 1 is running	
		if(phase1StartingAt <= getBlockTime() && getBlockTime() <= phase1EndingAt) {
			// check if tokens is falling in timerange
			validTimestamp = true;

			// check if token amount is falling in limit
			validAmount = phase1MaxTokenForSale.sub(totalTokenSold) >= amount;
		}

		// check if phase 2 is running	
		if(phase2StartingAt <= getBlockTime() && getBlockTime() <= phase2EndingAt) {
			// check if tokens is falling in timerange
			validTimestamp = true;

			// check if token amount is falling in limit
			validAmount = phase2MaxTokenForSale.sub(totalTokenSold) >= amount;
		}

		// check if phase 3 is running	
		if(phase3StartingAt <= getBlockTime() && getBlockTime() <= phase3EndingAt) {
			// check if tokens is falling in timerange
			validTimestamp = true;

			// check if token amount is falling in limit
			validAmount = phase3MaxTokenForSale.sub(totalTokenSold) >= amount;
		}

		// check if value of the ether is valid
		bool validValue = value != 0;

		// check if the tokens available in contract for sale
		bool validToken = amount != 0;

		// validate if all conditions are met
		return validTimestamp && validAmount && validValue && validToken && !isClose && !isPaused;
	}

	function calculate(uint256 value) internal constant returns (uint256) {
		uint256 amount = 0;
			
		// check if phase 1 is running	
		if(phase1StartingAt <= getBlockTime() && getBlockTime() <= phase1EndingAt) {
			// calculate the amount of tokens
			amount = value.mul(1E18).div(phase1TokenPriceInEth);
		}

		// check if phase 2 is running	
		if(phase2StartingAt <= getBlockTime() && getBlockTime() <= phase2EndingAt) {
			// calculate the amount of tokens
			amount = value.mul(1E18).div(phase2TokenPriceInEth);
		}

		// check if phase 3 is running	
		if(phase3StartingAt <= getBlockTime() && getBlockTime() <= phase3EndingAt) {
			// calculate the amount of tokens
			amount = value.mul(1E18).div(phase3TokenPriceInEth);
		}

		return amount;
	}

	function update(uint256 value, uint256 amount) internal returns (bool) {

		// update the state to log the sold tokens and raised ethers.
		totalTokenSold = totalTokenSold.add(amount);
		totalEtherRaised = totalEtherRaised.add(value);
		etherRaisedPerWallet[msg.sender] = etherRaisedPerWallet[msg.sender].add(value);

		// check if phase 1 is running	
		if(phase1StartingAt <= getBlockTime() && getBlockTime() <= phase1EndingAt) {
			// add tokens to phase1 counts
			phase1TokenSold = phase1TokenSold.add(amount);
		}

		// check if phase 2 is running	
		if(phase2StartingAt <= getBlockTime() && getBlockTime() <= phase2EndingAt) {
			// add tokens to phase2 counts
			phase2TokenSold = phase2TokenSold.add(amount);
		}

		// check if phase 3 is running	
		if(phase3StartingAt <= getBlockTime() && getBlockTime() <= phase3EndingAt) {
			// add tokens to phase3 counts
			phase3TokenSold = phase3TokenSold.add(amount);
		}
	}

	/**
	 * @dev Default fallback method which will be called when any ethers are sent to contract
	 */
	function() public payable {
		buy(msg.sender);
	}

	/**
	 * @dev Function that is called either externally or by default payable method
	 *
	 * @param beneficiary who should receive tokens
	 */
	function buy(address beneficiary) public payable {
		require(beneficiary != address(0));

		// amount of ethers sent
		uint256 value = msg.value;

		// throw error if not enough ethers sent
		require(value >= minEthPerTransaction);

		// refund the extra ethers if sent more than allowed
		if(value > maxEthPerTransaction) {
			// more ethers are sent so refund extra
			msg.sender.transfer(value.sub(maxEthPerTransaction));
			value = maxEthPerTransaction;
		}
		
		// calculate tokens
		uint256 tokens = calculate(value);

		// validate the purchase
		require(validate(value , tokens));

		// update current state 
		update(value , tokens);
		
		// transfer tokens from contract balance to beneficiary account. calling ERC223 method
		bytes memory empty;
		token.transfer(beneficiary, tokens, empty);
		
		// log event for token purchase
		TokenPurchase(msg.sender, beneficiary, value, tokens, now);
	}

	/**
	* @dev transmit token for a specified address. 
	* This is owner only method and should be called using web3.js if someone is trying to buy token using bitcoin or any other altcoin.
	* 
	* @param _to The address to transmit to.
	* @param _value The amount to be transferred.
	* @param _message message to log after transfer.
	*/
	function transferManual(address _to, uint256 _value, string _message) onlyOwner public returns (bool) {
		require(_to != address(0));

		// transfer tokens manually from contract balance
		token.transfer(_to , _value);
		TransferManual(msg.sender, _to, _value, _message);
		return true;
	}

	/**
	* @dev sendToGrowthContract  
	* This will send remaining tokens to growth contract
	*/	
	function sendToGrowthContract() onlyOwner public {
		require(contractTimeout <= getBlockTime());

		// send remaining tokens to growth contract.
		uint256 tokens = token.balanceOf(this); 
		bytes memory empty;
		token.transfer(growthContract, tokens, empty);
	}

	/**
	* @dev sendToVestingContract  
	* This will transfer any available ethers to vesting contracts
	*/	
	function sendToVestingContract() onlyOwner public {
		// distribute funds 
		distribute();
	}

	/**
	* @dev withdraw funds and tokens 
	* This will send remaining token balance to growth contract
	* This will distribute available funds across team members
	*/	
	function withdraw() onlyOwner public {
		require(contractTimeout <= getBlockTime());

		// send remaining tokens to growth contract.
		uint256 tokens = token.balanceOf(this); 
		bytes memory empty;
		token.transfer(growthContract, tokens, empty);

		// distribute funds 
		distribute();
	}

	/**
	* @dev close contract 
	* This will mark contract as closed
	*/	
	function close() onlyOwner public {
		// mark the flag to indicate closure of the contract
		isClose = true;
	}

	/**
	* @dev pause contract 
	* This will mark contract as paused
	*/	
	function pause() onlyOwner public {
		// mark the flag to indicate pause of the contract
		isPaused = true;
	}

	/**
	* @dev resume contract 
	* This will mark contract as resumed
	*/	
	function resume() onlyOwner public {
		// mark the flag to indicate resume of the contract
		isPaused = false;
	}
}

/**
* @title dHealthEtherVesting
* @dev This is vesting contract it receives funds and those are used to release funds to fixed address
*/
contract dHealthEtherVesting is Ownable, Timestamped {
	using SafeMath for uint256;

	// wallet address which will receive funds on pay
	address public wallet;

	// timestamp when vesting contract starts, this timestamp matches with sale contract
	uint256 public startingAt = 1516924800; // Friday, 26 January 2018 00:00:00

	// timestamp when vesting ends
	uint256 public endingAt = startingAt + 540 days;

	// how many % of ethers to vest on each call
	uint256 public vestingAmount = 20;

	// timestamp when vesting starts
	uint256 public vestingPeriodLength = 30 days;

	// time after which owner can withdraw all available funds
	uint256 public contractTimeout = startingAt + 2 years;

	// mapping that defines vesting structure
	struct VestingStruct {
		uint256 period; 
		bool status;
		address wallet;
		uint256 amount;
		uint256 timestamp;
	}

	// vesting that tracks vestings done against the period.
	mapping (uint256 => VestingStruct) public vestings;

	// Event to log whenever the payment is done
	event Payouts(uint256 indexed period, bool status, address wallet, uint256 amount, uint256 timestamp);

	/**
	* @dev Constructor that does nothing 
	*/
	function dHealthEtherVesting(address _wallet) public {
		wallet = _wallet;
	}

	/**
	* @dev default payable method to receive funds
	*/
	function() public payable {
		
	}

	/**
	* @dev Method called by owner of contract to withdraw funds
	*/
	function pay(uint256 percentage) public payable {
		// requested amount should always be less than vestingAmount variable
		percentage = percentage <= vestingAmount ? percentage : vestingAmount;

		// calculate amount allowed
		var (period, amount) = calculate(getBlockTime() , this.balance , percentage);

		// payment should not be done if period is zero
		require(period > 0);
		// payment should not be done already
		require(vestings[period].status == false);
		// wallet should not be set already.
		require(vestings[period].wallet == address(0));
		// there should be amount to pay
		require(amount > 0);

		// set period for storage
		vestings[period].period = period;
		// set status to avoid double payment
		vestings[period].status = true;
		// set wallet to track where payment was sent
		vestings[period].wallet = wallet;
		// set wallet to track how much amount sent
		vestings[period].amount = amount;
		// set timestamp of payment
		vestings[period].timestamp = getBlockTime();

		// transfer amount to wallet address
		wallet.transfer(amount);

		// log event
		Payouts(period, vestings[period].status, vestings[period].wallet, vestings[period].amount, vestings[period].timestamp);
	}

	/**
	* @dev Internal method called to current vesting period
	*/
	function getPeriod(uint256 timestamp) public view returns (uint256) {
		for(uint256 i = 1 ; i <= 18 ; i ++) {
			// calculate timestamp range
			uint256 startTime = startingAt + (vestingPeriodLength * (i - 1));
			uint256 endTime = startingAt + (vestingPeriodLength * (i));

			if(startTime <= timestamp && timestamp < endTime) {
				return i;
			}
		}

		// calculate timestamp of last period
		uint256 lastEndTime = startingAt + (vestingPeriodLength * (18));
		if(lastEndTime <= timestamp) {
			return 18;
		}

		return 0;
	}

	/**
	* @dev Internal method called to current vesting period range
	*/
	function getPeriodRange(uint256 timestamp) public view returns (uint256 , uint256) {
		for(uint256 i = 1 ; i <= 18 ; i ++) {
			// calculate timestamp range
			uint256 startTime = startingAt + (vestingPeriodLength * (i - 1));
			uint256 endTime = startingAt + (vestingPeriodLength * (i));

			if(startTime <= timestamp && timestamp < endTime) {
				return (startTime , endTime);
			}
		}

		// calculate timestamp of last period
		uint256 lastStartTime = startingAt + (vestingPeriodLength * (17));
		uint256 lastEndTime = startingAt + (vestingPeriodLength * (18));
		if(lastEndTime <= timestamp) {
			return (lastStartTime , lastEndTime);
		}

		return (0 , 0);
	}

	/**
	* @dev Internal method called to calculate withdrawal amount
	*/
	function calculate(uint256 timestamp, uint256 balance , uint256 percentage) public view returns (uint256 , uint256) {
		// find out current vesting period
		uint256 period = getPeriod(timestamp);
		if(period == 0) {
			// if period is not found then return zero;
			return (0 , 0);
		}

		// get vesting object for period
		VestingStruct memory vesting = vestings[period];	
		
		// check if payment is already done
		if(vesting.status == false) {
			// payment is not done yet
			uint256 amount;

			// if it is last month then send all remaining balance
			if(period == 18) {
				// send all
				amount = balance;
			} else {
				// calculate percentage and send
				amount = balance.mul(percentage).div(100);
			}
			
			return (period, amount);
		} else {
			// payment is already done 
			return (period, 0);
		}		
	}

	/**
	* @dev Method called by owner to change the wallet address
	*/
	function setWallet(address _wallet) onlyOwner public {
		wallet = _wallet;
	}

	/**
	* @dev Method called by owner of contract to withdraw funds after timeout has reached
	*/
	function withdraw() onlyOwner public payable {
		require(contractTimeout <= getBlockTime());
		owner.transfer(this.balance);
	}	
}


/**
* @title dHealthTokenVesting
* @dev This is vesting contract it receives tokens and those are used to release tokens to fixed address
*/
contract dHealthTokenVesting is Ownable, Timestamped {
	using SafeMath for uint256;

	// The token being sold, this holds reference to main token contract
	dHealthToken public token;

	// wallet address which will receive tokens on pay
	address public wallet;

	// amount of token to be hold
	uint256 public maxTokenForHold;

	// timestamp when vesting contract starts, this timestamp matches with sale contract
	uint256 public startingAt = 1522281600; // Thursday, 29 March 2018 00:00:00

	// timestamp when vesting ends
	uint256 public endingAt = startingAt + 540 days;

	// how many % of ethers to vest on each call
	uint256 public vestingAmount = 20;

	// timestamp when vesting starts
	uint256 public vestingPeriodLength = 30 days;

	// time after which owner can withdraw all available funds
	uint256 public contractTimeout = startingAt + 2 years;

	// mapping that defines vesting structure
	struct VestingStruct {
		uint256 period; 
		bool status;
		address wallet;
		uint256 amount;
		uint256 timestamp;
	}

	// vesting that tracks vestings done against the period.
	mapping (uint256 => VestingStruct) public vestings;

	// Event to log whenever the payment is done
	event Payouts(uint256 indexed period, bool status, address wallet, uint256 amount, uint256 timestamp);

	/**
	* @dev Constructor that initializes token contract with token address in parameter
	*/
	function dHealthTokenVesting(address _token, address _wallet, uint256 _maxTokenForHold, uint256 _startingAt) public {
		// set token
		token = dHealthToken(_token);

		// set wallet address
		wallet = _wallet;

		// set parameter specific to contract
		maxTokenForHold = _maxTokenForHold;	
		
		// setup timestamp
		startingAt = _startingAt;
		endingAt = startingAt + 540 days;
	}

	/**
	* @dev default payable method to receive funds
	*/
	function() public payable {
		
	}

	/**
	* @dev Method called by owner of contract to withdraw funds
	*/
	function pay(uint256 percentage) public {
		// requested amount should always be less than vestingAmount variable
		percentage = percentage <= vestingAmount ? percentage : vestingAmount;

		// get current token balance
		uint256 balance = token.balanceOf(this); 
		
		// calculate amount allowed
		var (period, amount) = calculate(getBlockTime() , balance , percentage);

		// payment should not be done if period is zero
		require(period > 0);
		// payment should not be done already
		require(vestings[period].status == false);
		// wallet should not be set already.
		require(vestings[period].wallet == address(0));
		// there should be amount to pay
		require(amount > 0);

		// set period for storage
		vestings[period].period = period;
		// set status to avoid double payment
		vestings[period].status = true;
		// set wallet to track where payment was sent
		vestings[period].wallet = wallet;
		// set wallet to track how much amount sent
		vestings[period].amount = amount;
		// set timestamp of payment
		vestings[period].timestamp = getBlockTime();

		// transfer amount to wallet address
		bytes memory empty;
		token.transfer(wallet, amount, empty);

		// log event
		Payouts(period, vestings[period].status, vestings[period].wallet, vestings[period].amount, vestings[period].timestamp);
	}

	/**
	* @dev Internal method called to current vesting period
	*/
	function getPeriod(uint256 timestamp) public view returns (uint256) {
		for(uint256 i = 1 ; i <= 18 ; i ++) {
			// calculate timestamp range
			uint256 startTime = startingAt + (vestingPeriodLength * (i - 1));
			uint256 endTime = startingAt + (vestingPeriodLength * (i));

			if(startTime <= timestamp && timestamp < endTime) {
				return i;
			}
		}

		// calculate timestamp of last period
		uint256 lastEndTime = startingAt + (vestingPeriodLength * (18));
		if(lastEndTime <= timestamp) {
			return 18;
		}

		return 0;
	}

	/**
	* @dev Internal method called to current vesting period range
	*/
	function getPeriodRange(uint256 timestamp) public view returns (uint256 , uint256) {
		for(uint256 i = 1 ; i <= 18 ; i ++) {
			// calculate timestamp range
			uint256 startTime = startingAt + (vestingPeriodLength * (i - 1));
			uint256 endTime = startingAt + (vestingPeriodLength * (i));

			if(startTime <= timestamp && timestamp < endTime) {
				return (startTime , endTime);
			}
		}

		// calculate timestamp of last period
		uint256 lastStartTime = startingAt + (vestingPeriodLength * (17));
		uint256 lastEndTime = startingAt + (vestingPeriodLength * (18));
		if(lastEndTime <= timestamp) {
			return (lastStartTime , lastEndTime);
		}

		return (0 , 0);
	}

	/**
	* @dev Internal method called to calculate withdrawal amount
	*/
	function calculate(uint256 timestamp, uint256 balance , uint256 percentage) public view returns (uint256 , uint256) {
		// find out current vesting period
		uint256 period = getPeriod(timestamp);
		if(period == 0) {
			// if period is not found then return zero;
			return (0 , 0);
		}

		// get vesting object for period
		VestingStruct memory vesting = vestings[period];	
		
		// check if payment is already done
		if(vesting.status == false) {
			// payment is not done yet
			uint256 amount;

			// if it is last month then send all remaining balance
			if(period == 18) {
				// send all
				amount = balance;
			} else {
				// calculate percentage and send
				amount = balance.mul(percentage).div(100);
			}
			
			return (period, amount);
		} else {
			// payment is already done 
			return (period, 0);
		}		
	}

	/**
	* @dev Method called by owner to change the wallet address
	*/
	function setWallet(address _wallet) onlyOwner public {
		wallet = _wallet;
	}

	/**
	* @dev Method called by owner of contract to withdraw funds after timeout has reached
	*/
	function withdraw() onlyOwner public payable {
		require(contractTimeout <= getBlockTime());
		
		// send remaining tokens back to owner.
		uint256 tokens = token.balanceOf(this); 
		bytes memory empty;
		token.transfer(owner, tokens, empty);
	}	
}