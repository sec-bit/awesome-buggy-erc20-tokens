pragma solidity ^0.4.2;
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
}

contract Quitcoin is owned {
/* Public variables of the token */
    string public standard = 'Token 0.1';
    string public name = "Quitcoin";
    string public symbol = "QUIT";
    uint8 public decimals;
    uint256 public totalSupply;
    uint public timeOfLastDistribution;
    uint256 public rateOfEmissionPerYear;
    address[] public arrayOfNonTrivialAccounts;
    uint256 public trivialThreshold;

    bytes32 public currentChallenge = 1;
    uint public timeOfLastProof;
    uint public difficulty = 10**77;
    uint public max = 2**256-1;
    uint public numclaimed = 0;
    address[] public arrayOfAccountsThatHaveClaimed;

    uint public ownerDailyWithdrawal = 0;
    uint public timeOfLastOwnerWithdrawal = 0;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => bool) public accountClaimedReward;


    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event FrozenFunds(address target, bool frozen);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Quitcoin() {
        balanceOf[msg.sender] = 324779816*10**10;              // Give the creator all initial tokens
        totalSupply = 324779816*10**10;                        // Update total supply
        decimals = 10;                            // Amount of decimals for display purposes
	timeOfLastDistribution = now;
	rateOfEmissionPerYear = 6773979019428571428;
	trivialThreshold = 10**8;
	arrayOfNonTrivialAccounts.push(msg.sender);
	timeOfLastProof = now;
    }

    function interestDistribution() {
	if (now-timeOfLastDistribution < 1 days) throw;
	if (totalSupply < 4639711657142857143) throw;
	if (totalSupply > 2*324779816*10**10) throw;

	rateOfEmissionPerYear = 846747377428571428;

	uint256 starttotalsupply = totalSupply;

	for (uint i = 0; i < arrayOfNonTrivialAccounts.length; i ++) {
	    totalSupply += balanceOf[arrayOfNonTrivialAccounts[i]] * rateOfEmissionPerYear / 365 / starttotalsupply;
	    balanceOf[arrayOfNonTrivialAccounts[i]] += balanceOf[arrayOfNonTrivialAccounts[i]] * rateOfEmissionPerYear / 365 / starttotalsupply;
	}

	timeOfLastDistribution = now;
    }

    function proofOfWork(uint nonce) {
	uint n = uint(sha3(sha3(sha3(nonce, currentChallenge, msg.sender))));
	if (n < difficulty) throw;
	if (totalSupply > 4639711657142857143) throw;
	if (accountClaimedReward[msg.sender]) throw;
	
	balanceOf[msg.sender] += rateOfEmissionPerYear/365/24/60/10;
	totalSupply += rateOfEmissionPerYear/365/24/60/10;
	
	numclaimed += 1;
	arrayOfAccountsThatHaveClaimed.push(msg.sender);
	accountClaimedReward[msg.sender] = true;

	if (balanceOf[msg.sender] > trivialThreshold && balanceOf[msg.sender] - (rateOfEmissionPerYear/365/24/60/10) <= trivialThreshold) arrayOfNonTrivialAccounts.push(msg.sender);
	if (numclaimed > 49) {
	    uint timeSinceLastProof = (now-timeOfLastProof);
	    difficulty = max - (max-difficulty) * (timeSinceLastProof / 5 minutes);

	    timeOfLastProof = now;
	    currentChallenge = sha3(nonce, currentChallenge, block.blockhash(block.number-1));
	    numclaimed = 0;
	    for (uint i = 0; i < arrayOfAccountsThatHaveClaimed.length; i ++) {
		accountClaimedReward[arrayOfAccountsThatHaveClaimed[i]] = false;
	    }
	    arrayOfAccountsThatHaveClaimed = new address[](0);
	}
    }


    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
	if (frozenAccount[msg.sender]) throw;
	if (totalSupply < 4639711657142857143) throw;
	if (msg.sender == owner) {
	    if (now - timeOfLastOwnerWithdrawal > 1 days) {
		ownerDailyWithdrawal = 0;
		timeOfLastOwnerWithdrawal = now;
	    }
	    if (_value+ownerDailyWithdrawal > 324779816*10**8 || totalSupply < 4747584953171428570) throw;
	    ownerDailyWithdrawal += _value;
	}
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
	if (balanceOf[msg.sender] <= trivialThreshold && balanceOf[msg.sender] + _value > trivialThreshold) {
	    for (uint i = 0; i < arrayOfNonTrivialAccounts.length; i ++) {
		if (msg.sender == arrayOfNonTrivialAccounts[i]) {
		    delete arrayOfNonTrivialAccounts[i];
		    arrayOfNonTrivialAccounts[i] = arrayOfNonTrivialAccounts[arrayOfNonTrivialAccounts.length-1];
		    arrayOfNonTrivialAccounts.length --;
		    break;
		}
	    }
	} 
        balanceOf[_to] += _value;                 
	if (balanceOf[_to] > trivialThreshold && balanceOf[_to] - _value <= trivialThreshold) arrayOfNonTrivialAccounts.push(_to);
        Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
	Approval(msg.sender, _spender, _value);
        return true;
    }


    /* Approve and then comunicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
	if (frozenAccount[_from]) throw;
	if (totalSupply < 4639711657142857143) throw;
	if (_from == owner) {
	    if (now - timeOfLastOwnerWithdrawal > 1 days) {
		ownerDailyWithdrawal = 0;
		timeOfLastOwnerWithdrawal = now;
	    }
	    if (_value+ownerDailyWithdrawal > 324779816*10**8 || totalSupply < 4747584953171428570) throw;
	    ownerDailyWithdrawal += _value;
	}
        balanceOf[_from] -= _value;                          // Subtract from the sender
	if (balanceOf[_from] <= trivialThreshold && balanceOf[_from] + _value > trivialThreshold) {
	    for (uint i = 0; i < arrayOfNonTrivialAccounts.length; i ++) {
		if (_from == arrayOfNonTrivialAccounts[i]) {
		    delete arrayOfNonTrivialAccounts[i];
		    arrayOfNonTrivialAccounts[i] = arrayOfNonTrivialAccounts[arrayOfNonTrivialAccounts.length-1];
		    arrayOfNonTrivialAccounts.length --;
		    break;
		}
	    }
	} 
        balanceOf[_to] += _value;                            
	if (balanceOf[_to] > trivialThreshold && balanceOf[_to] - _value <= trivialThreshold) arrayOfNonTrivialAccounts.push(_to);
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function raiseTrivialThreshold(uint256 newTrivialThreshold) onlyOwner {
	trivialThreshold = newTrivialThreshold;
	for (uint i = arrayOfNonTrivialAccounts.length; i > 0; i --) {
	    if (balanceOf[arrayOfNonTrivialAccounts[i-1]] <= trivialThreshold) {
		delete arrayOfNonTrivialAccounts[i-1];
		arrayOfNonTrivialAccounts[i-1] = arrayOfNonTrivialAccounts[arrayOfNonTrivialAccounts.length-1];
		arrayOfNonTrivialAccounts.length --;
	    }
	}
    }

    function freezeAccount(address target, bool freeze) onlyOwner {
	frozenAccount[target] = freeze;
	FrozenFunds(target, freeze);
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }
}