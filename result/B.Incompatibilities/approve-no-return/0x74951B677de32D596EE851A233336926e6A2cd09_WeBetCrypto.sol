pragma solidity ^0.4.18;


/**
 * @title WeBetCrypto
 * @author AL_X
 * @dev The WBC ERC-223 Token Contract
 */
contract WeBetCrypto {
    string public name = "We Bet Crypto";
    string public symbol = "WBA";
	
    address public selfAddress;
    address public admin;
    address[] private users;
	
    uint8 public decimals = 7;
    uint256 public relativeDateSave;
    uint256 public totalFunds;
    uint256 public totalSupply = 400000000000000;
    uint256 public IOUSupply = 0;
    uint256 private amountInCirculation;
    uint256 private currentProfits;
    uint256 private currentIteration;
	uint256 private actualProfitSplit;
	
    bool public isFrozen;
    bool private running;
	
    mapping(address => uint256) balances;
    mapping(address => uint256) moneySpent;
    mapping(address => uint256) monthlyLimit;
	mapping(address => uint256) cooldown;
	
    mapping(address => bool) isAdded;
    mapping(address => bool) claimedBonus;
	mapping(address => bool) bannedUser;
    //mapping(address => bool) loggedUser;
	
    mapping (address => mapping (address => uint256)) allowed;
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
	/**
	 * @notice Ensures admin is caller
	 */
    modifier isAdmin() {
        require(msg.sender == admin);
        //Continue executing rest of method body
        _;
    }
    
    /**
	 * @notice Re-entry protection
	 */
    modifier isRunning() {
        require(!running);
        running = true;
        _;
        running = false;
    }
    
	/**
	 * @notice Ensures system isn't frozen
	 */
    modifier noFreeze() {
        require(!isFrozen);
        _;
    }
    
	/**
	 * @notice Ensures player isn't logged in on platform
	 */
    modifier userNotPlaying(address _user) {
        //require(!loggedUser[_user]);
        uint256 check = 0;
        check -= 1;
        require(cooldown[_user] == check);
        _;
    }
    
    /**
     * @notice Ensures player isn't bannedUser
     */
    modifier userNotBanned(address _user) {
        require(!bannedUser[_user]);
        _;
    }
    
    /**
	 * @notice SafeMath Library safeSub Import
	 * @dev 
	        Since we are dealing with a limited currency
	        circulation of 40 million tokens and values
	        that will not surpass the uint256 limit, only
	        safeSub is required to prevent underflows.
	 */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 z) {
        assert((z = a - b) <= a);
    }
	
	/**
	 * @notice WBC Constructor
	 * @dev 
	        Constructor function containing proper initializations such as 
	        token distribution to the team members and pushing the first 
	        profit split to 6 months when the DApp will already be live.
	 */
    function WeBetCrypto() public {
        admin = msg.sender;
        selfAddress = this;
        balances[0x66AE070A8501E816CA95ac99c4E15C7e132fd289] = 200000000000000;
        addUser(0x66AE070A8501E816CA95ac99c4E15C7e132fd289);
        Transfer(selfAddress, 0x66AE070A8501E816CA95ac99c4E15C7e132fd289, 200000000000000);
        balances[0xcf8d242C523bfaDC384Cc1eFF852Bf299396B22D] = 50000000000000;
        addUser(0xcf8d242C523bfaDC384Cc1eFF852Bf299396B22D);
        Transfer(selfAddress, 0xcf8d242C523bfaDC384Cc1eFF852Bf299396B22D, 50000000000000);
        relativeDateSave = now + 40 days;
        balances[selfAddress] = 150000000000000;
    }
    
    /**
     * @notice Check the name of the token ~ ERC-20 Standard
     * @return {
					"_name": "The token name"
				}
     */
    function name() external constant returns (string _name) {
        return name;
    }
    
	/**
     * @notice Check the symbol of the token ~ ERC-20 Standard
     * @return {
					"_symbol": "The token symbol"
				}
     */
    function symbol() external constant returns (string _symbol) {
        return symbol;
    }
    
    /**
     * @notice Check the decimals of the token ~ ERC-20 Standard
     * @return {
					"_decimals": "The token decimals"
				}
     */
    function decimals() external constant returns (uint8 _decimals) {
        return decimals;
    }
    
    /**
     * @notice Check the total supply of the token ~ ERC-20 Standard
     * @return {
					"_totalSupply": "Total supply of tokens"
				}
     */
    function totalSupply() external constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
    
    /**
     * @notice Query the available balance of an address ~ ERC-20 Standard
	 * @param _owner The address whose balance we wish to retrieve
     * @return {
					"balance": "Balance of the address"
				}
     */
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }
	
	/**
	 * @notice Query the amount of tokens the spender address can withdraw from the owner address ~ ERC-20 Standard
	 * @param _owner The address who owns the tokens
	 * @param _spender The address who can withdraw the tokens
	 * @return {
					"remaining": "Remaining withdrawal amount"
				}
     */
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    /**
     * @notice Query whether the user is eligible for claiming dividence
     * @param _user The address to query
     * @return _success Whether or not the user is eligible
     */
    function eligibleForDividence(address _user) public view returns (bool _success) {
        if (moneySpent[_user] == 0) {
            return false;
		} else if ((balances[_user] + allowed[selfAddress][_user])/moneySpent[_user] > 20) {
		    return false;
        }
        return true;
    }
    
    /**
     * @notice Transfer tokens from an address to another ~ ERC-20 Standard
	 * @dev 
	        Adjusts the monthly limit in case the _from address is the Casino
	        and ensures that the user isn't logged in when retrieving funds
	        so as to prevent against a race attack with the Casino.
     * @param _from The address whose balance we will transfer
     * @param _to The recipient address
	 * @param _value The amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) external noFreeze {
        var _allowance = allowed[_from][_to];
        if (_from == selfAddress) {
            monthlyLimit[_to] = safeSub(monthlyLimit[_to], _value);
            require(cooldown[_to] < now /*&& !loggedUser[_to]*/);
            IOUSupply -= _value;
        }
        balances[_to] = balances[_to]+_value;
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][_to] = safeSub(_allowance, _value);
        addUser(_to);
        Transfer(_from, _to, _value);
    }
    
    /**
	 * @notice Authorize an address to retrieve funds from you ~ ERC-20 Standard
	 * @dev 
	        30 minute cooldown removed for easier participation in
	        trading platforms such as Ether Delta
	 * @param _spender The address you wish to authorize
	 * @param _value The amount of tokens you wish to authorize
	 */
    function approve(address _spender, uint256 _value) external {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }
    
    /**
	 * @notice Transfer the specified amount to the target address ~ ERC-20 Standard
	 * @dev 
	        A boolean is returned so that callers of the function 
	        will know if their transaction went through.
	 * @param _to The address you wish to send the tokens to
	 * @param _value The amount of tokens you wish to send
	 * @return {
					"success": "Transaction success"
				}
     */
    function transfer(address _to, uint256 _value) external isRunning noFreeze returns (bool success) {
        bytes memory empty;
        if (_to == selfAddress) {
            return transferToSelf(_value);
        } else if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value);
        }
    }
    
    /**
	 * @notice Check whether address is a contract ~ ERC-223 Proposed Standard
	 * @param _address The address to check
	 * @return {
					"is_contract": "Result of query"
				}
     */
    function isContract(address _address) internal view returns (bool is_contract) {
        uint length;
        assembly {
            length := extcodesize(_address)
        }
        return length > 0;
    }
    
    /**
	 * @notice Transfer the specified amount to the target address with embedded bytes data ~ ERC-223 Proposed Standard
	 * @dev Includes an extra transferToSelf function to handle Casino deposits
	 * @param _to The address to transfer to
	 * @param _value The amount of tokens to transfer
	 * @param _data Any extra embedded data of the transaction
	 * @return {
					"success": "Transaction success"
				}
     */
    function transfer(address _to, uint256 _value, bytes _data) external isRunning noFreeze returns (bool success){
        if (_to == selfAddress) {
            return transferToSelf(_value);
        } else if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value);
        }
    }
    
    /**
	 * @notice Handles transfer to an ECA (Externally Controlled Account), a normal account ~ ERC-223 Proposed Standard
	 * @param _to The address to transfer to
	 * @param _value The amount of tokens to transfer
	 * @return {
					"success": "Transaction success"
				}
     */
    function transferToAddress(address _to, uint256 _value) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = balances[_to]+_value;
        addUser(_to);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
	 * @notice Handles transfer to a contract ~ ERC-223 Proposed Standard
	 * @param _to The address to transfer to
	 * @param _value The amount of tokens to transfer
	 * @param _data Any extra embedded data of the transaction
	 * @return {
					"success": "Transaction success"
				}
     */
    function transferToContract(address _to, uint256 _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = balances[_to]+_value;
        WeBetCrypto rec = WeBetCrypto(_to);
        rec.tokenFallback(msg.sender, _value, _data);
        addUser(_to);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
	 * @notice Handles Casino deposits ~ Custom ERC-223 Proposed Standard Addition
	 * @param _value The amount of tokens to transfer
	 * @return {
					"success": "Transaction success"
				}
     */
    function transferToSelf(uint256 _value) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[selfAddress] = balances[selfAddress]+_value;
        Transfer(msg.sender, selfAddress, _value);
		allowed[selfAddress][msg.sender] = _value + allowed[selfAddress][msg.sender];
		IOUSupply += _value;
		Approval(selfAddress, msg.sender, allowed[selfAddress][msg.sender]);
        return true;
    }
	
	/**
	 * @notice Empty tokenFallback method to ensure ERC-223 compatibility
	 * @param _sender The address who sent the ERC-223 tokens
	 * @param _value The amount of tokens the address sent to this contract
	 * @param _data Any embedded data of the transaction
	 */
	function tokenFallback(address _sender, uint256 _value, bytes _data) public {}
	
	/**
	 * @notice Check how much Casino withdrawal balance remains for address
	 * @return {
					"remaining": "Withdrawal balance remaining"
				}
     */
    function checkMonthlyLimit() external constant returns (uint256 remaining) {
        return monthlyLimit[msg.sender];
    }
	
	/**
	 * @notice Retrieve ERC Tokens sent to contract
	 * @dev Feel free to contact us and retrieve your ERC tokens should you wish so.
	 * @param _token The token contract address
	 */
    function claimTokens(address _token) isAdmin external { 
		require(_token != selfAddress);
        WeBetCrypto token = WeBetCrypto(_token); 
        uint balance = token.balanceOf(selfAddress); 
        token.transfer(admin, balance); 
    }
    
	/**
	 * @notice Freeze token circulation - splitProfits internal
	 * @dev 
	        Ensures that one doesn't transfer his total balance mid-split to 
	        an account later in the split queue in order to receive twice the
	        monthly profits
	 */
    function assetFreeze() internal {
        isFrozen = true;
    }
    
	/**
	 * @notice Re-enable token circulation - splitProfits internal
	 */
    function assetThaw() internal {
        isFrozen = false;
    }
    
	/**
	 * @notice Freeze token circulation
	 * @dev To be used only in extreme circumstances.
	 */
    function emergencyFreeze() isAdmin external {
        isFrozen = true;
    }
    
	/**
	 * @notice Re-enable token circulation
	 * @dev To be used only in extreme circumstances
	 */
    function emergencyThaw() isAdmin external {
        isFrozen = false;
    }
	
	/**
	 * @notice Disable the splitting function
	 * @dev 
	        To be used in case the system is upgraded to a 
	        node.js operated profit reward system via the 
			alterBankBalance function. Ensures scalability 
			in case userbase gets too big.
	 */
	function emergencySplitToggle() isAdmin external {
		uint temp = 0;
		temp -= 1;
		if (relativeDateSave == temp) {
		    relativeDateSave = now;
		} else {
	    	relativeDateSave = temp;
		}
	}
	
	/**
	 * @notice Add the address to the user list 
	 * @dev Used for the splitting function to take it into account
	 * @param _user User to add to database
	 */
	function addUser(address _user) internal {
		if (!isAdded[_user]) {
            users.push(_user);
            monthlyLimit[_user] = 1000000000000;
            isAdded[_user] = true;
        }
	}
    
	/**
	 * @notice Split the monthly profits of the Casino to the users
	 * @dev 
			The formula that calculates the profit a user is owed can be seen on 
			the white paper. The actualProfitSplit variable stores the actual values
	   		that are distributed to the users to prevent rounding errors from burning 
			tokens. Since gas requirements will spike the more users use our platform,
			a loop-state-save is implemented to ensure scalability.
	 */
    function splitProfits() external {
        uint i;
        if (!isFrozen) {
            require(now >= relativeDateSave);
            assetFreeze();
            require(balances[selfAddress] > 30000000000000);
            relativeDateSave = now + 30 days;
            currentProfits = ((balances[selfAddress]-30000000000000)/10)*7; 
            amountInCirculation = safeSub(400000000000000, balances[selfAddress]) + IOUSupply;
            currentIteration = 0;
			actualProfitSplit = 0;
        } else {
            for (i = currentIteration; i < users.length; i++) {
                monthlyLimit[users[i]] = 1000000000000;
                if (msg.gas < 250000) {
                    currentIteration = i;
                    break;
                }
				if (!eligibleForDividence(users[i])) {
				    moneySpent[users[i]] = 0;
        			checkSplitEnd(i);
                    continue;
				}
				moneySpent[users[i]] = 0;
				actualProfitSplit += ((balances[users[i]]+allowed[selfAddress][users[i]])*currentProfits)/amountInCirculation;
                Transfer(selfAddress, users[i], ((balances[users[i]]+allowed[selfAddress][users[i]])*currentProfits)/amountInCirculation);
                balances[users[i]] += ((balances[users[i]]+allowed[selfAddress][users[i]])*currentProfits)/amountInCirculation;
				checkSplitEnd(i);
            }
        }
    }
	
	/**
	 * @notice Change variables on split end
	 * @param i The current index of the split loop.
	 */
	function checkSplitEnd(uint256 i) internal {
		if (i == users.length-1) {
			assetThaw();
			balances[0x66AE070A8501E816CA95ac99c4E15C7e132fd289] = balances[0x66AE070A8501E816CA95ac99c4E15C7e132fd289] + currentProfits/20;
			balances[selfAddress] = balances[selfAddress] - actualProfitSplit - currentProfits/20;
		}
	}
    
	/**
	 * @notice Rise or lower user bank balance - Backend Function
	 * @dev 
	        This allows adjustment of the balance a user has within the Casino to
			represent earnings and losses.
	 * @param _toAlter The address whose Casino balance to alter
	 * @param _amount The amount to alter it by
	 */
    function alterBankBalance(address _toAlter, uint256 _amount) internal {
        if (_amount > allowed[selfAddress][_toAlter]) {
            IOUSupply += (_amount - allowed[selfAddress][_toAlter]);
            moneySpent[_toAlter] += (_amount - allowed[selfAddress][_toAlter]);
			allowed[selfAddress][_toAlter] = _amount;
			Approval(selfAddress, _toAlter, allowed[selfAddress][_toAlter]);
        } else {
            IOUSupply -= (allowed[selfAddress][_toAlter] - _amount);
            moneySpent[_toAlter] += (allowed[selfAddress][_toAlter] - _amount);
            allowed[selfAddress][_toAlter] = _amount;
			Approval(selfAddress, _toAlter, allowed[selfAddress][_toAlter]);
        }
    }
    
	/**
	 * @notice Freeze user during platform use - Backend Function
	 * @dev Prevents against the ERC-20 race attack on the Casino
	 */
    function platformLogin() userNotBanned(msg.sender) external {
        //loggedUser[msg.sender] = true;
        cooldown[msg.sender] = 0;
        cooldown[msg.sender] -= 1;
    }
	
	/**
	 * @notice De-Freeze user - Backend Function
     * @dev Used when a user logs out or loses connection with the DApp
	 */
	function platformLogout(address _toLogout, uint256 _newBalance) external isAdmin {
		//loggedUser[msg.sender] = false;
		cooldown[_toLogout] = now + 30 minutes;
		alterBankBalance(_toLogout,_newBalance);
	}
	
	/**
	 * @notice Check if user is logged internal
	 * @dev Used to ensure that the user is logged in throughout 
	 *      the whole casino session
	 * @param _toCheck The user address to check
	 */
	function checkLogin(address _toCheck) view external returns (bool) {
	    uint256 check = 0;
	    check -= 1;
	    return (cooldown[_toCheck] == check);
	}
	
	/**
	 * @notice Ban a user
	 * @dev Used in extreme circumstances where the users break the law
	 * @param _user The user to ban
	 */
	function banUser(address _user) external isAdmin {
	    bannedUser[_user] = true;
	    cooldown[_user] = now + 30 minutes;
	}
	
	/**
	 * @notice Unban a user
	 * @dev Used in extreme circumstances where the users have redeemed
	 * @param _user The user to unban
	 */
	function unbanUser(address _user) external isAdmin {
	    bannedUser[_user] = false;
	}
	
	/**
	 * @notice Check if a user is banned
	 * @dev Used by the back-end to give a message to the user
	 * @param _user The user to check
	 */
	function checkBan(address _user) external view returns (bool) {
	    return bannedUser[_user];
	}
	
    /**
	 * @notice Purchase WBC Tokens for Self - ICO
	 */
    function() payable external {
        totalFunds = totalFunds + msg.value;
		address etherTransfer = 0x66AE070A8501E816CA95ac99c4E15C7e132fd289;
        require(msg.value > 0);
		require(msg.sender != etherTransfer);
		require(totalFunds/1 ether < 2000);
        addUser(msg.sender);
        uint256 tokenAmount = msg.value/100000000;
		balances[selfAddress] = balances[selfAddress] - tokenAmount;
        balances[msg.sender] = balances[msg.sender] + tokenAmount;
        Transfer(selfAddress, msg.sender, tokenAmount);
        etherTransfer.transfer(msg.value);
    }
    
    /**
     * @notice Advertising Token Distribution
     * @dev Ensures the user has at least 0.1 Ether on his 
     *      account before distributing 20 WBC
     */
    function claimBonus() external {
        require(msg.sender.balance/(1000 finney) >= 1 && !claimedBonus[msg.sender]);
        claimedBonus[msg.sender] = true;
		allowed[selfAddress][msg.sender] = allowed[selfAddress][msg.sender] + 200000000;
		IOUSupply += 200000000;
        addUser(msg.sender);
		Approval(selfAddress, msg.sender, allowed[selfAddress][msg.sender]);
    }
}