pragma solidity ^0.4.18;

/**
 * @author Hieu Phan - https://github.com/phanletrunghieu
 * @author Hanh Pham - https://github.com/HanhPhamPhuoc
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

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
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


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
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

/*****
    * Orginally from https://github.com/OpenZeppelin/zeppelin-solidity
    * Modified by https://github.com/agarwalakarsh
    */

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
/*****
    * @title Basic Token
    * @dev Basic Version of a Generic Token
    */
contract ERC20BasicToken is Pausable{
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    //Fix for the ERC20 short address attack.
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4) ;
        _;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) whenNotPaused internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }


    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused onlyPayloadSize(2 * 32) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) whenNotPaused onlyPayloadSize(2 * 32) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * @notice Create `mintedAmount` tokens and send it to `target`
     * @param target Address to receive the tokens
     * @param mintedAmount the amount of tokens it will receive
     */
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }

    /**
  	 * Return balance of an account
     * @param _owner the address to get balance
  	 */
  	function balanceOf(address _owner) public constant returns (uint balance) {
  		return balances[_owner];
  	}

    /**
  	 * Return allowance for other address
     * @param _owner The address spend to the other
     * @param _spender The address authorized to spend
  	 */
  	function allowance(address _owner, address _spender) public constant returns (uint remaining) {
  		return allowance[_owner][_spender];
  	}
}

contract JWCToken is ERC20BasicToken {
	using SafeMath for uint256;

	string public constant name      = "JWC Blockchain Ventures";   //tokens name
	string public constant symbol    = "JWC";                       //token symbol
	uint256 public constant decimals = 18;                          //token decimal
	string public constant version   = "1.0";                       //tokens version

	uint256 public constant tokenPreSale         = 100000000 * 10**decimals;//tokens for pre-sale
	uint256 public constant tokenPublicSale      = 400000000 * 10**decimals;//tokens for public-sale
	uint256 public constant tokenReserve         = 300000000 * 10**decimals;//tokens for reserve
	uint256 public constant tokenTeamSupporter   = 120000000 * 10**decimals;//tokens for Team & Supporter
	uint256 public constant tokenAdvisorPartners = 80000000  * 10**decimals;//tokens for Advisor

	address public icoContract;

	// constructor
	function JWCToken() public {
		totalSupply = tokenPreSale + tokenPublicSale + tokenReserve + tokenTeamSupporter + tokenAdvisorPartners;
	}

	/**
	 * Set ICO Contract for this token to make sure called by our ICO contract
	 * @param _icoContract - ICO Contract address
	 */
	function setIcoContract(address _icoContract) public onlyOwner {
		if (_icoContract != address(0)) {
			icoContract = _icoContract;
		}
	}

	/**
	 * Sell tokens when ICO. Only called by ICO Contract
	 * @param _recipient - address send ETH to buy tokens
	 * @param _value - amount of ETHs
	 */
	function sell(address _recipient, uint256 _value) public whenNotPaused returns (bool success) {
		assert(_value > 0);
		require(msg.sender == icoContract);

		balances[_recipient] = balances[_recipient].add(_value);

		Transfer(0x0, _recipient, _value);
		return true;
	}

	/**
	 * Pay bonus & affiliate to address
	 * @param _recipient - address to receive bonus & affiliate
	 * @param _value - value bonus & affiliate to give
	 */
	function payBonusAffiliate(address _recipient, uint256 _value) public returns (bool success) {
		assert(_value > 0);
		require(msg.sender == icoContract);

		balances[_recipient] = balances[_recipient].add(_value);
		totalSupply = totalSupply.add(_value);

		Transfer(0x0, _recipient, _value);
		return true;
	}
}

/**
 * Store config of phase ICO
 */
contract IcoPhase {
  uint256 public constant phasePresale_From = 1515679200;//14h 20/01/2018 GMT (test 14h 11/01/2018 GMT)
  uint256 public constant phasePresale_To = 1517839200;//14h 05/02/2018 GMT

  uint256 public constant phasePublicSale1_From = 1519912800;//14h 01/03/2018 GMT
  uint256 public constant phasePublicSale1_To = 1520344800;//14h 06/03/2018 GMT

  uint256 public constant phasePublicSale2_From = 1520344800;//14h 06/03/2018 GMT
  uint256 public constant phasePublicSale2_To = 1520776800;//14h 11/03/2018 GMT

  uint256 public constant phasePublicSale3_From = 1520776800;//14h 11/03/2018 GMT
  uint256 public constant phasePublicSale3_To = 1521208800;//14h 16/03/2018 GMT
}

/**
 * This contract will give bonus for user when buy tokens. The bonus will be paid after finishing ICO
 */
contract Bonus is IcoPhase, Ownable {
	using SafeMath for uint256;

	//decimals of tokens
	uint256 constant decimals = 18;

	//enable/disable
	bool public isBonus;

	//max tokens for time bonus
	uint256 public maxTimeBonus = 225000000*10**decimals;

	//max tokens for amount bonus
	uint256 public maxAmountBonus = 125000000*10**decimals;

	//storage
	mapping(address => uint256) public bonusAccountBalances;
	mapping(uint256 => address) public bonusAccountIndex;
	uint256 public bonusAccountCount;

	uint256 public indexPaidBonus;//amount of accounts have been paid bonus

	function Bonus() public {
		isBonus = true;
	}

	/**
	 * Enable bonus
	 */
	function enableBonus() public onlyOwner returns (bool)
	{
		require(!isBonus);
		isBonus=true;
		return true;
	}

	/**
	 * Disable bonus
	 */
	function disableBonus() public onlyOwner returns (bool)
	{
		require(isBonus);
		isBonus=false;
		return true;
	}

	/**
	 * Get bonus percent by time
	 */
	function getTimeBonus() public constant returns(uint256) {
		uint256 bonus = 0;

		if(now>=phasePresale_From && now<phasePresale_To){
			bonus = 40;
		} else if (now>=phasePublicSale1_From && now<phasePublicSale1_To) {
			bonus = 20;
		} else if (now>=phasePublicSale2_From && now<phasePublicSale2_To) {
			bonus = 10;
		} else if (now>=phasePublicSale3_From && now<phasePublicSale3_To) {
			bonus = 5;
		}

		return bonus;
	}

	/**
	 * Get bonus by eth
	 * @param _value - eth to convert to bonus
	 */
	function getBonusByETH(uint256 _value) public pure returns(uint256) {
		uint256 bonus = 0;

		if(_value>=1500*10**decimals){
			bonus=_value.mul(25)/100;
		} else if(_value>=300*10**decimals){
			bonus=_value.mul(20)/100;
		} else if(_value>=150*10**decimals){
			bonus=_value.mul(15)/100;
		} else if(_value>=30*10**decimals){
			bonus=_value.mul(10)/100;
		} else if(_value>=15*10**decimals){
			bonus=_value.mul(5)/100;
		}

		return bonus;
	}

	/**
	 * Get bonus balance of an account
	 * @param _owner - the address to get bonus of
	 */
	function balanceBonusOf(address _owner) public constant returns (uint256 balance)
	{
		return bonusAccountBalances[_owner];
	}

	/**
	 * Get bonus balance of an account
	 */
	function payBonus() public onlyOwner returns (bool success);
}


/**
 * This contract will give affiliate for user when buy tokens. The affiliate will be paid after finishing ICO
 */
contract Affiliate is Ownable {

	//Control Affiliate feature.
	bool public isAffiliate;

	//Affiliate level, init is 1
	uint256 public affiliateLevel = 1;

	//Each user will have different rate
	mapping(uint256 => uint256) public affiliateRate;

	//Keep balance of user
	mapping(address => uint256) public referralBalance;//referee=>value

	mapping(address => address) public referral;//referee=>referrer
	mapping(uint256 => address) public referralIndex;//index=>referee

	uint256 public referralCount;

	//amount of accounts have been paid affiliate
	uint256 public indexPaidAffiliate;

	// max tokens for affiliate
	uint256 public maxAffiliate = 100000000*(10**18);

	/**
	 * Throw if affiliate is disable
	 */
	modifier whenAffiliate() {
		require (isAffiliate);
		_;
	}

	/**
	 * constructor affiliate with level 1 rate = 10%
	 */
	function Affiliate() public {
		isAffiliate=true;
		affiliateLevel=1;
		affiliateRate[0]=10;
	}

	/**
	 * Enable affiliate for the contract
	 */
	function enableAffiliate() public onlyOwner returns (bool) {
		require (!isAffiliate);
		isAffiliate=true;
		return true;
	}

	/**
	 * Disable affiliate for the contract
	 */
	function disableAffiliate() public onlyOwner returns (bool) {
		require (isAffiliate);
		isAffiliate=false;
		return true;
	}

	/**
	 * Return current affiliate level
	 */
	function getAffiliateLevel() public constant returns(uint256)
	{
		return affiliateLevel;
	}

	/**
	 * Update affiliate level by owner
	 * @param _level - new level
	 */
	function setAffiliateLevel(uint256 _level) public onlyOwner whenAffiliate returns(bool)
	{
		affiliateLevel=_level;
		return true;
	}

	/**
	 * Get referrer address
	 * @param _referee - the referee address
	 */
	function getReferrerAddress(address _referee) public constant returns (address)
	{
		return referral[_referee];
	}

	/**
	 * Get referee address
	 * @param _referrer - the referrer address
	 */
	function getRefereeAddress(address _referrer) public constant returns (address[] _referee)
	{
		address[] memory refereeTemp = new address[](referralCount);
		uint count = 0;
		uint i;
		for (i=0; i<referralCount; i++){
			if(referral[referralIndex[i]] == _referrer){
				refereeTemp[count] = referralIndex[i];

				count += 1;
			}
		}

		_referee = new address[](count);
		for (i=0; i<count; i++)
			_referee[i] = refereeTemp[i];
	}

	/**
	 * Mapping referee address with referrer address
	 * @param _parent - the referrer address
	 * @param _child - the referee address
	 */
	function setReferralAddress(address _parent, address _child) public onlyOwner whenAffiliate returns (bool)
	{
		require(_parent != address(0x00));
		require(_child != address(0x00));

		referralIndex[referralCount]=_child;
		referral[_child]=_parent;
		referralCount++;

		referralBalance[_child]=0;

		return true;
	}

	/**
	 * Get affiliate rate by level
	 * @param _level - level to get affiliate rate
	 */
	function getAffiliateRate(uint256 _level) public constant returns (uint256 rate)
	{
		return affiliateRate[_level];
	}

	/**
	 * Set affiliate rate for level
	 * @param _level - the level to be set the new rate
	 * @param _rate - new rate
	 */
	function setAffiliateRate(uint256 _level, uint256 _rate) public onlyOwner whenAffiliate returns (bool)
	{
		affiliateRate[_level]=_rate;
		return true;
	}

	/**
	 * Get affiliate balance of an account
	 * @param _referee - the address to get affiliate of
	 */
	function balanceAffiliateOf(address _referee) public constant returns (uint256)
	{
		return referralBalance[_referee];
	}

	/**
	 * Pay affiliate
	 */
	function payAffiliate() public onlyOwner returns (bool success);
}


/**
 * This contract will send tokens when an account send eth
 * Note: before send eth to token, address has to be registered by registerRecipient function
 */
contract IcoContract is IcoPhase, Ownable, Pausable, Affiliate, Bonus {
	using SafeMath for uint256;

	JWCToken ccc;

	uint256 public totalTokenSale;
	uint256 public minContribution = 0.1 ether;//minimun eth used to buy tokens
	uint256 public tokenExchangeRate = 7000;//1ETH=7000 tokens
	uint256 public constant decimals = 18;

	uint256 public tokenRemainPreSale;//tokens remain for pre-sale
	uint256 public tokenRemainPublicSale;//tokens for public-sale

	address public ethFundDeposit = 0x3A94528d2a5986Cd2825eE0DA16328dAbc461559;//multi-sig wallet
	address public tokenAddress;

	bool public isFinalized;

	uint256 public maxGasRefund = 0.0046 ether;//maximum gas used to refund for each transaction

	//constructor
	function IcoContract(address _tokenAddress) public {
		tokenAddress = _tokenAddress;

		ccc = JWCToken(tokenAddress);
		totalTokenSale = ccc.tokenPreSale() + ccc.tokenPublicSale();

		tokenRemainPreSale = ccc.tokenPreSale();//tokens remain for pre-sale
		tokenRemainPublicSale = ccc.tokenPublicSale();//tokens for public-sale

		isFinalized=false;
	}

	//usage: web3 change token from eth
	function changeETH2Token(uint256 _value) public constant returns(uint256) {
		uint256 etherRecev = _value + maxGasRefund;
		require (etherRecev >= minContribution);

		uint256 rate = getTokenExchangeRate();

		uint256 tokens = etherRecev.mul(rate);

		//get current phase of ICO
		uint256 phaseICO = getCurrentICOPhase();
		uint256 tokenRemain = 0;
		if(phaseICO == 1){//pre-sale
			tokenRemain = tokenRemainPreSale;
		} else if (phaseICO == 2 || phaseICO == 3 || phaseICO == 4) {
			tokenRemain = tokenRemainPublicSale;
		}

		if (tokenRemain < tokens) {
			tokens=tokenRemain;
		}

		return tokens;
	}

	function () public payable whenNotPaused {
		require (!isFinalized);
		require (msg.sender != address(0));

		uint256 etherRecev = msg.value + maxGasRefund;
		require (etherRecev >= minContribution);

		//get current token exchange rate
		tokenExchangeRate = getTokenExchangeRate();

		uint256 tokens = etherRecev.mul(tokenExchangeRate);

		//get current phase of ICO
		uint256 phaseICO = getCurrentICOPhase();

		require(phaseICO!=0);

		uint256 tokenRemain = 0;
		if(phaseICO == 1){//pre-sale
			tokenRemain = tokenRemainPreSale;
		} else if (phaseICO == 2 || phaseICO == 3 || phaseICO == 4) {
			tokenRemain = tokenRemainPublicSale;
		}

		//throw if tokenRemain==0
		require(tokenRemain>0);

		if (tokenRemain < tokens) {
			//if tokens is not enough to buy

			uint256 tokensToRefund = tokens.sub(tokenRemain);
			uint256 etherToRefund = tokensToRefund / tokenExchangeRate;

			//refund eth to buyer
			msg.sender.transfer(etherToRefund);

			tokens=tokenRemain;
			etherRecev = etherRecev.sub(etherToRefund);

			tokenRemain = 0;
		} else {
			tokenRemain = tokenRemain.sub(tokens);
		}

		//store token remain by phase
		if(phaseICO == 1){//pre-sale
			tokenRemainPreSale = tokenRemain;
		} else if (phaseICO == 2 || phaseICO == 3 || phaseICO == 4) {
			tokenRemainPublicSale = tokenRemain;
		}

		//send token
		ccc.sell(msg.sender, tokens);
		ethFundDeposit.transfer(this.balance);

		//bonus
		if(isBonus){
			//bonus amount
			//get bonus by eth
			uint256 bonusAmountETH = getBonusByETH(etherRecev);
			//get bonus by token
			uint256 bonusAmountTokens = bonusAmountETH.mul(tokenExchangeRate);

			//check if we have enough tokens for bonus
			if(maxAmountBonus>0){
				if(maxAmountBonus>=bonusAmountTokens){
					maxAmountBonus-=bonusAmountTokens;
				} else {
					bonusAmountTokens = maxAmountBonus;
					maxAmountBonus = 0;
				}
			} else {
				bonusAmountTokens = 0;
			}

			//bonus time
			uint256 bonusTimeToken = tokens.mul(getTimeBonus())/100;
			//check if we have enough tokens for bonus
			if(maxTimeBonus>0){
				if(maxTimeBonus>=bonusTimeToken){
					maxTimeBonus-=bonusTimeToken;
				} else {
					bonusTimeToken = maxTimeBonus;
					maxTimeBonus = 0;
				}
			} else {
				bonusTimeToken = 0;
			}

			//store bonus
			if(bonusAccountBalances[msg.sender]==0){//new
				bonusAccountIndex[bonusAccountCount]=msg.sender;
				bonusAccountCount++;
			}

			uint256 bonusTokens=bonusAmountTokens + bonusTimeToken;
			bonusAccountBalances[msg.sender]=bonusAccountBalances[msg.sender].add(bonusTokens);
		}

		//affiliate
		if(isAffiliate){
			address child=msg.sender;
			for(uint256 i=0; i<affiliateLevel; i++){
				uint256 giftToken=affiliateRate[i].mul(tokens)/100;

				//check if we have enough tokens for affiliate
				if(maxAffiliate<=0){
					break;
				} else {
					if(maxAffiliate>=giftToken){
						maxAffiliate-=giftToken;
					} else {
						giftToken = maxAffiliate;
						maxAffiliate = 0;
					}
				}

				address parent = referral[child];
				if(parent != address(0x00)){//has affiliate
					referralBalance[child]=referralBalance[child].add(giftToken);
				}

				child=parent;
			}
		}
	}

	/**
	 * Pay affiliate to address. Called when ICO finish
	 */
	function payAffiliate() public onlyOwner returns (bool success) {
		uint256 toIndex = indexPaidAffiliate + 15;
		if(referralCount < toIndex)
			toIndex = referralCount;

		for(uint256 i=indexPaidAffiliate; i<toIndex; i++) {
			address referee = referralIndex[i];
			payAffiliate1Address(referee);
		}

		return true;
	}

	/**
	 * Pay affiliate to only a address
	 */
	function payAffiliate1Address(address _referee) public onlyOwner returns (bool success) {
		address referrer = referral[_referee];
		ccc.payBonusAffiliate(referrer, referralBalance[_referee]);

		referralBalance[_referee]=0;
		return true;
	}

	/**
	 * Pay bonus to address. Called when ICO finish
	 */
	function payBonus() public onlyOwner returns (bool success) {
		uint256 toIndex = indexPaidBonus + 15;
		if(bonusAccountCount < toIndex)
			toIndex = bonusAccountCount;

		for(uint256 i=indexPaidBonus; i<toIndex; i++)
		{
			payBonus1Address(bonusAccountIndex[i]);
		}

		return true;
	}

	/**
	 * Pay bonus to only a address
	 */
	function payBonus1Address(address _address) public onlyOwner returns (bool success) {
		ccc.payBonusAffiliate(_address, bonusAccountBalances[_address]);
		bonusAccountBalances[_address]=0;
		return true;
	}

	function finalize() external onlyOwner {
		require (!isFinalized);
		// move to operational
		isFinalized = true;
		payAffiliate();
		payBonus();
		ethFundDeposit.transfer(this.balance);
	}

	/**
	 * Get token exchange rate
	 * Note: just use when ICO
	 */
	function getTokenExchangeRate() public constant returns(uint256 rate) {
		rate = tokenExchangeRate;
		if(now<phasePresale_To){
			if(now>=phasePresale_From)
				rate = 10000;
		} else if(now<phasePublicSale3_To){
			rate = 7000;
		}
	}

	/**
	 * Get the current ICO phase
	 */
	function getCurrentICOPhase() public constant returns(uint256 phase) {
		phase = 0;
		if(now>=phasePresale_From && now<phasePresale_To){
			phase = 1;
		} else if (now>=phasePublicSale1_From && now<phasePublicSale1_To) {
			phase = 2;
		} else if (now>=phasePublicSale2_From && now<phasePublicSale2_To) {
			phase = 3;
		} else if (now>=phasePublicSale3_From && now<phasePublicSale3_To) {
			phase = 4;
		}
	}

	/**
	 * Get amount of tokens that be sold
	 */
	function getTokenSold() public constant returns(uint256 tokenSold) {
		//get current phase of ICO
		uint256 phaseICO = getCurrentICOPhase();
		tokenSold = 0;
		if(phaseICO == 1){//pre-sale
			tokenSold = ccc.tokenPreSale().sub(tokenRemainPreSale);
		} else if (phaseICO == 2 || phaseICO == 3 || phaseICO == 4) {
			tokenSold = ccc.tokenPreSale().sub(tokenRemainPreSale) + ccc.tokenPublicSale().sub(tokenRemainPublicSale);
		}
	}

	/**
	 * Set token exchange rate
	 */
	function setTokenExchangeRate(uint256 _tokenExchangeRate) public onlyOwner returns (bool) {
		require(_tokenExchangeRate>0);
		tokenExchangeRate=_tokenExchangeRate;
		return true;
	}

	/**
	 * set min eth contribute
	 * @param _minContribution - min eth to contribute
	 */
	function setMinContribution(uint256 _minContribution) public onlyOwner returns (bool) {
		require(_minContribution>0);
		minContribution=_minContribution;
		return true;
	}

	/**
	 * Change multi-sig address, the address to receive ETH
	 * @param _ethFundDeposit - new multi-sig address
	 */
	function setEthFundDeposit(address _ethFundDeposit) public onlyOwner returns (bool) {
		require(_ethFundDeposit != address(0));
		ethFundDeposit=_ethFundDeposit;
		return true;
	}

	/**
	 * Set max gas to refund when an address send ETH to buy tokens
	 * @param _maxGasRefund - max gas
	 */
	function setMaxGasRefund(uint256 _maxGasRefund) public onlyOwner returns (bool) {
		require(_maxGasRefund > 0);
		maxGasRefund = _maxGasRefund;
		return true;
	}
}