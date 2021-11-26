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
	 
	struct TokenStruct {
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
		TokenStruct memory tkn;
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
* @title PalestinoToken
* @dev Very simple ERC23 Token example, where all tokens are pre-assigned to the creator.
*/
contract PalestinoToken is ERC223Token, Ownable {

	string public constant name = "Palestino";
	string public constant symbol = "PALE";
	uint256 public constant decimals = 3;

	uint256 constant INITIAL_SUPPLY = 10000000 * 1E3;
	
	/**
	* @dev Constructor that gives msg.sender all of existing tokens.
	*/
	function PalestinoToken() public {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
	}

	/**
	* @dev if ether is sent to this address, send it back.
	*/
	function () public {
		revert();
	}
}

/**
* @title PalestinoTokenSale
* @dev This is ICO Contract. 
* This class accepts the token address as argument to talk with contract.
* Once contract is deployed, funds are transferred to ICO smart contract address and then distributed with investor.
* Sending funds to this ensures that no more than desired tokens are sold.
*/
contract PalestinoTokenSale is Ownable, ERC223Receiver {
	using SafeMath for uint256;

	// The token being sold, this holds reference to main token contract
	PalestinoToken public token;

	// timestamp when sale starts
	uint256 public startingTimestamp = 1515974400;

	// amount of token to be sold on sale
	uint256 public maxTokenForSale = 10000000 * 1E3;

	// amount of token sold so far
	uint256 public totalTokenSold;

	// amount of ether raised in sale
	uint256 public totalEtherRaised;

	// ether raised per wallet
	mapping(address => uint256) public etherRaisedPerWallet;

	// walle which will receive the ether funding
	address public wallet;

	// is contract close and ended
	bool internal isClose = false;

	struct RoundStruct {
		uint256 number;
		uint256 fromAmount;
		uint256 toAmount;
		uint256 price;
	}

	RoundStruct[9] public rounds;

	// token purchsae event
	event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount, uint256 _timestamp);

	// manual transfer by admin for external purchase
	event TransferManual(address indexed _from, address indexed _to, uint256 _value, string _message);

	/**
	* @dev Constructor that initializes token contract with token address in parameter
	*/
	function PalestinoTokenSale(address _token, address _wallet) public {
		// set token
		token = PalestinoToken(_token);

		// set wallet
		wallet = _wallet;

		// setup rounds
		rounds[0] = RoundStruct(0, 0	    ,  2500000E3, 0.01 ether);
		rounds[1] = RoundStruct(1, 2500000E3,  3000000E3, 0.02 ether);
		rounds[2] = RoundStruct(2, 3000000E3,  3500000E3, 0.03 ether);
		rounds[3] = RoundStruct(3, 3500000E3,  4000000E3, 0.06 ether);
		rounds[4] = RoundStruct(4, 4000000E3,  4500000E3, 0.10 ether);
		rounds[5] = RoundStruct(5, 4500000E3,  5000000E3, 0.18 ether);
		rounds[6] = RoundStruct(6, 5000000E3,  5500000E3, 0.32 ether);
		rounds[7] = RoundStruct(7, 5500000E3,  6000000E3, 0.57 ether);
		rounds[8] = RoundStruct(8, 6000000E3, 10000000E3, 1.01 ether);
	}

	/**
	 * @dev Function that validates if the purchase is valid by verifying the parameters
	 *
	 * @param value Amount of ethers sent
	 * @param amount Total number of tokens user is trying to buy.
	 *
	 * @return checks various conditions and returns the bool result indicating validity.
	 */
	function isValidPurchase(uint256 value, uint256 amount) internal constant returns (bool) {
		// check if timestamp is falling in the range
		bool validTimestamp = startingTimestamp <= block.timestamp;

		// check if value of the ether is valid
		bool validValue = value != 0;

		// check if the tokens available in contract for sale
		bool validAmount = maxTokenForSale.sub(totalTokenSold) >= amount && amount > 0;

		// validate if all conditions are met
		return validTimestamp && validValue && validAmount && !isClose;
	}

	/**
	 * @dev Function that returns the current round
	 *
	 * @return checks various conditions and returns the current round.
	 */
	function getCurrentRound() public constant returns (RoundStruct) {
		for(uint256 i = 0 ; i < rounds.length ; i ++) {
			if(rounds[i].fromAmount <= totalTokenSold && totalTokenSold < rounds[i].toAmount) {
				return rounds[i];
			}
		}
	}

	/**
	 * @dev Function that returns the estimate token round by sending amount
	 *
	 * @param amount Amount of tokens expected
	 *
	 * @return checks various conditions and returns the estimate token round.
	 */
	function getEstimatedRound(uint256 amount) public constant returns (RoundStruct) {
		for(uint256 i = 0 ; i < rounds.length ; i ++) {
			if(rounds[i].fromAmount > (totalTokenSold + amount)) {
				return rounds[i - 1];
			}
		}

		return rounds[rounds.length - 1];
	}

	/**
	 * @dev Function that returns the maximum token round by sending amount
	 *
	 * @param amount Amount of tokens expected
	 *
	 * @return checks various conditions and returns the maximum token round.
	 */
	function getMaximumRound(uint256 amount) public constant returns (RoundStruct) {
		for(uint256 i = 0 ; i < rounds.length ; i ++) {
			if((totalTokenSold + amount) <= rounds[i].toAmount) {
				return rounds[i];
			}
		}
	}

	/**
	 * @dev Function that calculates the tokens which should be given to user by iterating over rounds
	 *
	 * @param value Amount of ethers sent
	 *
	 * @return checks various conditions and returns the token amount.
	 */
	function getTokenAmount(uint256 value) public constant returns (uint256 , uint256) {
		// assume we are sending no tokens	
		uint256 totalAmount = 0;

		// interate until we have some value left for buying
		while(value > 0) {
			
			// get current round by passing queue value also 
			RoundStruct memory estimatedRound = getEstimatedRound(totalAmount);
			// find tokens left in current round.
			uint256 tokensLeft = estimatedRound.toAmount.sub(totalTokenSold.add(totalAmount));

			// derive tokens can be bought in current round with round price 
			uint256 tokensBuys = value.mul(1E3).div(estimatedRound.price);

			// check if it is last round and still value left
			if(estimatedRound.number == rounds[rounds.length - 1].number) {
				// its last round 

				// no tokens left in round and still got value 
				if(tokensLeft == 0 && value > 0) {
					return (totalAmount , value);
				}
			}

			// if tokens left > tokens buy 
			if(tokensLeft >= tokensBuys) {
				totalAmount = totalAmount.add(tokensBuys);
				value = 0;
				return (totalAmount , value);
			} else {
				uint256 tokensLeftValue = tokensLeft.mul(estimatedRound.price).div(1E3);
				totalAmount = totalAmount.add(tokensLeft);
				value = value.sub(tokensLeftValue);
			}
		}

		return (0 , value);
	}
	
	/**
	 * @dev Default fallback method which will be called when any ethers are sent to contract
	 */
	function() public payable {
		buyTokens(msg.sender);
	}

	/**
	 * @dev Function that is called either externally or by default payable method
	 *
	 * @param beneficiary who should receive tokens
	 */
	function buyTokens(address beneficiary) public payable {
		require(beneficiary != address(0));

		// value sent by buyer
		uint256 value = msg.value;

		// calculate token amount from the ethers sent
		var (amount, leftValue) = getTokenAmount(value);

		// if there is any left value then return 
		if(leftValue > 0) {
			value = value.sub(leftValue);
			msg.sender.transfer(leftValue);
		}

		// validate the purchase
		require(isValidPurchase(value , amount));

		// update the state to log the sold tokens and raised ethers.
		totalTokenSold = totalTokenSold.add(amount);
		totalEtherRaised = totalEtherRaised.add(value);
		etherRaisedPerWallet[msg.sender] = etherRaisedPerWallet[msg.sender].add(value);

		// transfer tokens from contract balance to beneficiary account. calling ERC223 method
		bytes memory empty;
		token.transfer(beneficiary, amount, empty);
		
		// log event for token purchase
		TokenPurchase(msg.sender, beneficiary, value, amount, now);
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
	* @dev Method called by owner to change the wallet address
	*/
	function setWallet(address _wallet) onlyOwner public {
		wallet = _wallet;
	}

	/**
	* @dev Method called by owner of contract to withdraw funds
	*/
	function withdraw() onlyOwner public {
		wallet.transfer(this.balance);
	}

	/**
	* @dev close contract 
	* This will send remaining token balance to owner
	* This will distribute available funds across team members
	*/	
	function close() onlyOwner public {
		// send remaining tokens back to owner.
		uint256 tokens = token.balanceOf(this); 
		token.transfer(owner , tokens);

		// withdraw funds 
		withdraw();

		// mark the flag to indicate closure of the contract
		isClose = true;
	}
}