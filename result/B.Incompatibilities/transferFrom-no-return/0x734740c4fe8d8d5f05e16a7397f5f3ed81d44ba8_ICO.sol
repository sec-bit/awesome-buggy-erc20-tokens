pragma solidity ^0.4.17;

library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    uint c = a / b;
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
}


contract Ownable {
    
    address public owner;

    event OwnershipTransferred(address from, address to);

    /**
     * The address whcih deploys this contrcat is automatically assgined ownership.
     * */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * Functions with this modifier can only be executed by the owner of the contract. 
     * */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * Transfers ownership provided that a valid address is given. This function can 
     * only be called by the owner of the contract. 
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}


contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint;

  mapping(address => uint) balances;

  modifier onlyPayloadSize(uint size) {
     if (msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

}


contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint256)) allowances;

    /**
     * Transfers tokens from the account of the owner by an approved spender. 
     * The spender cannot spend more than the approved amount. 
     * 
     * @param _from The address of the owners account.
     * @param _amount The amount of tokens to transfer.
     * */
    function transferFrom(address _from, address _to, uint256 _amount) public onlyPayloadSize(3 * 32) {
        require(allowances[_from][msg.sender] >= _amount && balances[_from] >= _amount);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
    }

    /**
     * Allows another account to spend a given amount of tokens on behalf of the 
     * owner's account. If the owner has previously allowed a spender to spend
     * tokens on his or her behalf and would like to change the approval amount,
     * he or she will first have to set the allowance back to 0 and then update
     * the allowance.
     * 
     * @param _spender The address of the spenders account.
     * @param _amount The amount of tokens the spender is allowed to spend.
     * */
    function approve(address _spender, uint256 _amount) public {
        require((_amount == 0) || (allowances[msg.sender][_spender] == 0));
        allowances[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
    }


    /**
     * Returns the approved allowance from an owners account to a spenders account.
     * 
     * @param _owner The address of the owners account.
     * @param _spender The address of the spenders account.
     **/
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowances[_owner][_spender];
    }

}


contract MintableToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * Mints a given amount of tokens to the provided address. This function can only be called by the contract's
   * owner, which in this case is the ICO contract itself. From there, the founders of the ICO contract will be
   * able to invoke this function. 
   *
   * @param _to The address which will receive the tokens.
   * @param _amount The total amount of ETCL tokens to be minted.
   */
  function mint(address _to, uint256 _amount) public onlyOwner canMint onlyPayloadSize(2 * 32) returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * Terminates the minting period permanently. This function can only be called by the owner of the contract.
   */
  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

}


contract Ethercloud is MintableToken {
    
    uint8 public decimals;
    string public name;
    string public symbol;

    function Ethercloud() public {
       totalSupply = 0;
       decimals = 18;
       name = "Ethercloud";
       symbol = "ETCL";
    }
}


contract ICO is Ownable {

    using SafeMath for uint256;

    Ethercloud public ETCL;

    bool       public success;
    uint256    public rate;
    uint256    public rateWithBonus;
    uint256    public bountiesIssued;
    uint256    public tokensSold;
    uint256    public tokensForSale;
    uint256    public tokensForBounty;
    uint256    public maxTokens;
    uint256    public startTime;
    uint256    public endTime;
    uint256    public softCap;
    uint256    public hardCap;
    uint256[3] public bonusStages;

    mapping (address => uint256) investments;

    event TokensPurchased(address indexed by, uint256 amount);
    event RefundIssued(address indexed by, uint256 amount);
    event FundsWithdrawn(address indexed by, uint256 amount);
    event BountyIssued(address indexed to, uint256 amount);
    event IcoSuccess();
    event CapReached();

    function ICO() public {
        ETCL = new Ethercloud();
        success = false;
        rate = 1288; 
        rateWithBonus = 1674;
        bountiesIssued = 0;
        tokensSold = 0;
        tokensForSale = 78e24;              //78 million ETCL for sale
        tokensForBounty = 2e24;             //2 million ETCL for bounty
        maxTokens = 100e24;                 //100 million ETCL
        startTime = now.add(15 days);       //ICO starts 15 days after deployment
        endTime = startTime.add(30 days);   //30 days end time
        softCap = 6212530674370205e6;       //6212.530674370205 ETH
        hardCap = 46594980057776535e6;      //46594.980057776535 ETH

        bonusStages[0] = startTime.add(7 days);

        for (uint i = 1; i < bonusStages.length; i++) {
            bonusStages[i] = bonusStages[i - 1].add(7 days);
        }
    }

    /**
     * When ETH is sent to the contract, the fallback function calls the buy tokens function.
     */
    function() public payable {
        buyTokens(msg.sender);
    }

    /**
     * Allows investors to buy ETCL tokens by sending ETH and automatically receiving tokens
     * to the provided address.
     *
     * @param _beneficiary The address which will receive the tokens. 
     */
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != 0x0 && validPurchase() && this.balance.sub(msg.value) < hardCap);
        if (this.balance >= softCap && !success) {
            success = true;
            IcoSuccess();
        }
        uint256 weiAmount = msg.value;
        if (this.balance > hardCap) {
            CapReached();
            uint256 toRefund = this.balance.sub(hardCap);
            msg.sender.transfer(toRefund);
            weiAmount = weiAmount.sub(toRefund);
        }
        uint256 tokens = weiAmount.mul(getCurrentRateWithBonus());
        if (tokensSold.add(tokens) > tokensForSale) {
            revert();
        }
        ETCL.mint(_beneficiary, tokens);
        tokensSold = tokensSold.add(tokens);
        investments[_beneficiary] = investments[_beneficiary].add(weiAmount);
        TokensPurchased(_beneficiary, tokens);
    }

    /**
     * Returns the current rate with bonus percentage of the tokens. 
     */
    function getCurrentRateWithBonus() internal returns (uint256) {
        rateWithBonus = (rate.mul(getBonusPercentage()).div(100)).add(rate);
        return rateWithBonus;
    }

    /**
     * Returns the current bonus percentage. 
     */
    function getBonusPercentage() internal view returns (uint256 bonusPercentage) {
        uint256 timeStamp = now;
        if (timeStamp > bonusStages[2]) {
            bonusPercentage = 0; 
        }
        if (timeStamp <= bonusStages[2]) {
            bonusPercentage = 5;
        }
        if (timeStamp <= bonusStages[1]) {
            bonusPercentage = 15;
        }
        if (timeStamp <= bonusStages[0]) {
            bonusPercentage = 30;
        } 
        return bonusPercentage;
    }

    /**
     * Mints a given amount of new tokens to the provided address. This function can only be
     * called by the owner of the contract.
     *
     * @param _beneficiary The address which will receive the tokens.
     * @param _amount The total amount of tokens to be minted.
     */
    function issueTokens(address _beneficiary, uint256 _amount) public onlyOwner {
        require(_beneficiary != 0x0 && _amount > 0 && tokensSold.add(_amount) <= tokensForSale); 
        ETCL.mint(_beneficiary, _amount);
        tokensSold = tokensSold.add(_amount);
        TokensPurchased(_beneficiary, _amount);
    }

    /**
     * Checks whether or not a purchase is valid. If not, then the buy tokens function will 
     * not execute.
     */
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    /**
     * Allows investors to claim refund in the case that the soft cap has not been reached and
     * the duration of the ICO has passed. 
     *
     * @param _addr The address to be refunded. If no address is provided, the _addr will default
     * to the message sender. 
     */
    function getRefund(address _addr) public {
        if (_addr == 0x0) {
            _addr = msg.sender;
        }
        require(!isSuccess() && hasEnded() && investments[_addr] > 0);
        uint256 toRefund = investments[_addr];
        investments[_addr] = 0;
        _addr.transfer(toRefund);
        RefundIssued(_addr, toRefund);
    }

    /**
     * Mints new tokens for the bounty campaign. This function can only be called by the owner 
     * of the contract. 
     *
     * @param _beneficiary The address which will receive the tokens. 
     * @param _amount The total amount of tokens that will be minted. 
     */
    function issueBounty(address _beneficiary, uint256 _amount) public onlyOwner {
        require(bountiesIssued.add(_amount) <= tokensForBounty && _beneficiary != 0x0);
        ETCL.mint(_beneficiary, _amount);
        bountiesIssued = bountiesIssued.add(_amount);
        BountyIssued(_beneficiary, _amount);
    }

    /**
     * Withdraws the total amount of ETH raised to the owners address. This function can only be
     * called by the owner of the contract given that the ICO is a success and the duration has 
     * passed.
     */
    function withdraw() public onlyOwner {
        uint256 inCirculation = tokensSold.add(bountiesIssued);
        ETCL.mint(owner, inCirculation.mul(25).div(100));
        owner.transfer(this.balance);
    }

    /**
     * Returns true if the ICO is a success, false otherwise.
     */
    function isSuccess() public constant returns (bool) {
        return success;
    }

    /**
     * Returns true if the duration of the ICO has passed, false otherwise. 
     */
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

    /**
     * Returns the end time of the ICO.
     */
    function endTime() public constant returns (uint256) {
        return endTime;
    }

    /**
     * Returns the total investment of a given ETH address. 
     *
     * @param _addr The address being queried.
     */
    function investmentOf(address _addr) public constant returns (uint256) {
        return investments[_addr];
    }

    /**
     * Finishes the minting period. This function can only be called by the owner of the 
     * contract given that the duration of the ICO has ended. 
     */
    function finishMinting() public onlyOwner {
        require(hasEnded());
        ETCL.finishMinting();
    }
}