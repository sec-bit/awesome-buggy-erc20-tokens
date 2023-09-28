pragma solidity ^0.4.15;

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * Based on OpenZeppelin
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 *
 * Based on OpenZeppelin
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/token/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 *
 * Based on OpenZeppelin
 */

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/token/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * Based on OpenZeppelin
 */
contract StandardToken is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) internal allowed;

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
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

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
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

// File: contracts/token/BurnableToken.sol

/**
 * @title Burnable Token
 *
 * @dev based on OpenZeppelin
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

// File: contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * Based on OpenZeppelin
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 * Based on OpenZeppelin
 */
contract Claimable is Ownable {
    address public pendingOwner;

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() onlyPendingOwner public {
        OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: contracts/token/ReleasableToken.sol

/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 *
 */
contract ReleasableToken is ERC20, Claimable {

    /* The finalizer contract that allows unlift the transfer limits on this token */
    address public releaseAgent;

    /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
    bool public released = false;

    /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
    mapping (address => bool) public transferAgents;

    /**
     * Limit token transfer until the crowdsale is over.
     *
     */
    modifier canTransfer(address _sender) {
        if(!released) {
            assert(transferAgents[_sender]);
        }
        _;
    }

    /**
     * Set the contract that can call release and make the token transferable.
     *
     * Design choice. Allow reset the release agent to fix fat finger mistakes.
     */
    function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
        require(addr != 0x0);
        // We don't do interface check here as we might want to a normal wallet address to act as a release agent
        releaseAgent = addr;
    }

    /**
     * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
     */
    function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
        require(addr != 0x0);
        transferAgents[addr] = state;
    }

    /**
     * One way function to release the tokens to the wild.
     *
     * Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
     */
    function releaseTokenTransfer() public onlyReleaseAgent {
        released = true;
    }

    /** The function can be called only before or after the tokens have been releasesd */
    modifier inReleaseState(bool releaseState) {
        require(releaseState == released);
        _;
    }

    /** The function can be called only by a whitelisted release agent. */
    modifier onlyReleaseAgent() {
        require(msg.sender == releaseAgent);
        _;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
        // Call StandardToken.transfer()
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
        // Call StandardToken.transferForm()
        return super.transferFrom(_from, _to, _value);
    }

}

// File: contracts/token/CrowdsaleToken.sol

/**
 * @title Base crowdsale token interface
 */
contract CrowdsaleToken is BurnableToken, ReleasableToken {
    uint public decimals;
}

// File: contracts/crowdsale/FinalizeAgent.sol

/**
 * @title Finalize Agent Abstract Contract
 * Finalize agent defines what happens at the end of successful crowdsale.
 */
contract FinalizeAgent {

  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }

  function isSane() public constant returns (bool);

  function finalizeCrowdsale();

}

// File: contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 *
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

// File: contracts/crowdsale/InvestmentPolicyCrowdsale.sol

/**
 * @title Investment Policy Abstract Contract
 *
 * @dev based on TokenMarketNet
 *
 * Apache License, version 2.0 https://github.com/AlgoryProject/algory-ico/blob/master/LICENSE
 */
contract InvestmentPolicyCrowdsale is Pausable {

    /* Do we need to have unique contributor id for each customer */
    bool public requireCustomerId = false;

    /**
      * Do we verify that contributor has been cleared on the server side (accredited investors only).
      * This method was first used in FirstBlood crowdsale to ensure all contributors have accepted terms on sale (on the web).
      */
    bool public requiredSignedAddress = false;

    /* Server side address that signed allowed contributors (Ethereum addresses) that can participate the crowdsale */
    address public signerAddress;

    event InvestmentPolicyChanged(bool newRequireCustomerId, bool newRequiredSignedAddress, address newSignerAddress);

    /**
     * Set policy do we need to have server-side customer ids for the investments.
     *
     */
    function setRequireCustomerId(bool value) onlyOwner external{
        requireCustomerId = value;
        InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
    }

    /**
     * Set policy if all investors must be cleared on the server side first.
     *
     * This is e.g. for the accredited investor clearing.
     *
     */
    function setRequireSignedAddress(bool value, address _signerAddress) external onlyOwner {
        requiredSignedAddress = value;
        signerAddress = _signerAddress;
        InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
    }

    /**
     * Invest to tokens, recognize the payer and clear his address.
     */
    function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) external payable {
        require(requiredSignedAddress);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = sha3(prefix, sha3(msg.sender));
        assert(ecrecover(hash, v, r, s) == signerAddress);
        require(customerId != 0);  // UUIDv4 sanity check
        investInternal(msg.sender, customerId);
    }

    /**
     * Invest to tokens, recognize the payer.
     *
     */
    function buyWithCustomerId(uint128 customerId) external payable {
        require(requireCustomerId);
        require(customerId != 0);
        investInternal(msg.sender, customerId);
    }


    function investInternal(address receiver, uint128 customerId) whenNotPaused internal;
}

// File: contracts/crowdsale/PricingStrategy.sol

/**
 * Pricing Strategy - Abstract contract for defining crowdsale pricing.
 */
contract PricingStrategy {

  // How many tokens per one investor is allowed in presale
  uint public presaleMaxValue = 0;

  function isPricingStrategy() external constant returns (bool) {
      return true;
  }

  function getPresaleMaxValue() public constant returns (uint) {
      return presaleMaxValue;
  }

  function isPresaleFull(uint weiRaised) public constant returns (bool);

  function getAmountOfTokens(uint value, uint weiRaised) public constant returns (uint tokensAmount);
}

// File: contracts/crowdsale/AlgoryCrowdsale.sol

/**
 * @title Algory Crowdsale
 *
 * @dev based on TokenMarketNet
 *
 * Apache License, version 2.0 https://github.com/AlgoryProject/algory-ico/blob/master/LICENSE
 */

contract AlgoryCrowdsale is InvestmentPolicyCrowdsale {

    /* Max investment count when we are still allowed to change the multisig address */
    uint constant public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

    using SafeMath for uint;

    /* The token we are selling */
    CrowdsaleToken public token;

    /* How we are going to price our offering */
    PricingStrategy public pricingStrategy;

    /* Post-success callback */
    FinalizeAgent public finalizeAgent;

    /* tokens will be transfered from this address */
    address public multisigWallet;

    /* The party who holds the full token pool and has approve()'ed tokens for this crowdsale */
    address public beneficiary;

    /* the UNIX timestamp start date of the presale */
    uint public presaleStartsAt;

    /* the UNIX timestamp start date of the crowdsale */
    uint public startsAt;

    /* the UNIX timestamp end date of the crowdsale */
    uint public endsAt;

    /* the number of tokens already sold through this contract*/
    uint public tokensSold = 0;

    /* How many wei of funding we have raised */
    uint public weiRaised = 0;

    /** How many wei we have in whitelist declarations*/
    uint public whitelistWeiRaised = 0;

    /* Calculate incoming funds from presale contracts and addresses */
    uint public presaleWeiRaised = 0;

    /* How many distinct addresses have invested */
    uint public investorCount = 0;

    /* How much wei we have returned back to the contract after a failed crowdfund. */
    uint public loadedRefund = 0;

    /* How much wei we have given back to investors.*/
    uint public weiRefunded = 0;

    /* Has this crowdsale been finalized */
    bool public finalized = false;

    /* Allow investors refund theirs money */
    bool public allowRefund = false;

    // Has tokens preallocated */
    bool private isPreallocated = false;

    /** How much ETH each address has invested to this crowdsale */
    mapping (address => uint256) public investedAmountOf;

    /** How much tokens this crowdsale has credited for each investor address */
    mapping (address => uint256) public tokenAmountOf;

    /** Addresses and amount in weis that are allowed to invest even before ICO official opens. */
    mapping (address => uint) public earlyParticipantWhitelist;

    /** State machine
     *
     * - Preparing: All contract initialization calls and variables have not been set yet
     * - PreFunding: We have not passed start time yet, allow buy for whitelisted participants
     * - Funding: Active crowdsale
     * - Success: Passed end time or crowdsale is full (all tokens sold)
     * - Finalized: The finalized has been called and successfully executed
     * - Refunding: Refunds are loaded on the contract for reclaim.
     */
    enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

    // A new investment was made
    event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

    // Refund was processed for a contributor
    event Refund(address investor, uint weiAmount);

    // Address early participation whitelist status changed
    event Whitelisted(address addr, uint value);

    // Crowdsale time boundary has changed
    event TimeBoundaryChanged(string timeBoundary, uint timestamp);

    /** Modified allowing execution only if the crowdsale is currently running.  */
    modifier inState(State state) {
        require(getState() == state);
        _;
    }

    function AlgoryCrowdsale(address _token, address _beneficiary, PricingStrategy _pricingStrategy, address _multisigWallet, uint _presaleStart, uint _start, uint _end) public {
        owner = msg.sender;
        token = CrowdsaleToken(_token);
        beneficiary = _beneficiary;

        presaleStartsAt = _presaleStart;
        startsAt = _start;
        endsAt = _end;

        require(now < presaleStartsAt && presaleStartsAt <= startsAt && startsAt < endsAt);

        setPricingStrategy(_pricingStrategy);
        setMultisigWallet(_multisigWallet);

        require(beneficiary != 0x0 && address(token) != 0x0);
        assert(token.balanceOf(beneficiary) == token.totalSupply());

    }

    function prepareCrowdsale() onlyOwner external {
        require(!isPreallocated);
        require(isAllTokensApproved());
        preallocateTokens();
        isPreallocated = true;
    }

    /**
     * Allow to send money and get tokens.
     */
    function() payable {
        require(!requireCustomerId); // Crowdsale needs to track participants for thank you email
        require(!requiredSignedAddress); // Crowdsale allows only server-side signed participants
        investInternal(msg.sender, 0);
    }

    function setFinalizeAgent(FinalizeAgent agent) onlyOwner external{
        finalizeAgent = agent;
        require(finalizeAgent.isFinalizeAgent());
        require(finalizeAgent.isSane());
    }

    function setPresaleStartsAt(uint presaleStart) inState(State.Preparing) onlyOwner external {
        require(presaleStart <= startsAt && presaleStart < endsAt);
        presaleStartsAt = presaleStart;
        TimeBoundaryChanged('presaleStartsAt', presaleStartsAt);
    }

    function setStartsAt(uint start) onlyOwner external {
        require(presaleStartsAt < start && start < endsAt);
        State state = getState();
        assert(state == State.Preparing || state == State.PreFunding);
        startsAt = start;
        TimeBoundaryChanged('startsAt', startsAt);
    }

    function setEndsAt(uint end) onlyOwner external {
        require(end > startsAt && end > presaleStartsAt);
        endsAt = end;
        TimeBoundaryChanged('endsAt', endsAt);
    }

    function loadEarlyParticipantsWhitelist(address[] participantsArray, uint[] valuesArray) onlyOwner external {
        address participant = 0x0;
        uint value = 0;
        for (uint i = 0; i < participantsArray.length; i++) {
            participant = participantsArray[i];
            value = valuesArray[i];
            setEarlyParticipantWhitelist(participant, value);
        }
    }

    /**
     * Finalize a successful crowdsale.
     */
    function finalize() inState(State.Success) onlyOwner whenNotPaused external {
        require(!finalized);
        finalizeAgent.finalizeCrowdsale();
        finalized = true;
    }

    function allowRefunding(bool val) onlyOwner external {
        State state = getState();
        require(paused || state == State.Success || state == State.Failure || state == State.Refunding);
        allowRefund = val;
    }

    function loadRefund() inState(State.Failure) external payable {
        require(msg.value != 0);
        loadedRefund = loadedRefund.add(msg.value);
    }

    function refund() inState(State.Refunding) external {
        require(allowRefund);
        uint256 weiValue = investedAmountOf[msg.sender];
        require(weiValue != 0);
        investedAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded.add(weiValue);
        Refund(msg.sender, weiValue);
        msg.sender.transfer(weiValue);
    }

    function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner public {
        State state = getState();
        if (state == State.PreFunding || state == State.Funding) {
            require(paused);
        }
        pricingStrategy = _pricingStrategy;
        require(pricingStrategy.isPricingStrategy());
    }

    function setMultisigWallet(address wallet) onlyOwner public {
        require(wallet != 0x0);
        require(investorCount <= MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE);
        multisigWallet = wallet;
    }

    function setEarlyParticipantWhitelist(address participant, uint value) onlyOwner public {
        require(value != 0 && participant != 0x0);
        require(value <= pricingStrategy.getPresaleMaxValue());
        assert(!pricingStrategy.isPresaleFull(whitelistWeiRaised));
        if(earlyParticipantWhitelist[participant] > 0) {
            whitelistWeiRaised = whitelistWeiRaised.sub(earlyParticipantWhitelist[participant]);
        }
        earlyParticipantWhitelist[participant] = value;
        whitelistWeiRaised = whitelistWeiRaised.add(value);
        Whitelisted(participant, value);
    }

    function getTokensLeft() public constant returns (uint) {
        return token.allowance(beneficiary, this);
    }

    function isCrowdsaleFull() public constant returns (bool) {
        return getTokensLeft() == 0;
    }

    function getState() public constant returns (State) {
        if(finalized) return State.Finalized;
        else if (!isPreallocated) return State.Preparing;
        else if (address(finalizeAgent) == 0) return State.Preparing;
        else if (block.timestamp < presaleStartsAt) return State.Preparing;
        else if (block.timestamp >= presaleStartsAt && block.timestamp < startsAt) return State.PreFunding;
        else if (block.timestamp <= endsAt && block.timestamp >= startsAt && !isCrowdsaleFull()) return State.Funding;
        else if (!allowRefund && isCrowdsaleFull()) return State.Success;
        else if (!allowRefund && block.timestamp > endsAt) return State.Success;
        else if (allowRefund && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
        else return State.Failure;
    }

    /**
     * Check is crowdsale can be able to transfer all tokens from beneficiary
     */
    function isAllTokensApproved() private constant returns (bool) {
        return getTokensLeft() == token.totalSupply() - tokensSold
                && token.transferAgents(beneficiary);
    }

    function isBreakingCap(uint tokenAmount) private constant returns (bool limitBroken) {
        return tokenAmount > getTokensLeft();
    }

    function investInternal(address receiver, uint128 customerId) whenNotPaused internal{
        State state = getState();
        require(state == State.PreFunding || state == State.Funding);
        uint weiAmount = msg.value;
        uint tokenAmount = 0;


        if (state == State.PreFunding) {
            require(earlyParticipantWhitelist[receiver] > 0);
            require(weiAmount <= earlyParticipantWhitelist[receiver]);
            assert(!pricingStrategy.isPresaleFull(presaleWeiRaised));
        }

        tokenAmount = pricingStrategy.getAmountOfTokens(weiAmount, weiRaised);
        require(tokenAmount > 0);
        if (investedAmountOf[receiver] == 0) {
            investorCount++;
        }

        investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);

        if (state == State.PreFunding) {
            presaleWeiRaised = presaleWeiRaised.add(weiAmount);
            earlyParticipantWhitelist[receiver] = earlyParticipantWhitelist[receiver].sub(weiAmount);
        }

        require(!isBreakingCap(tokenAmount));

        assignTokens(receiver, tokenAmount);

        require(multisigWallet.send(weiAmount));

        Invested(receiver, weiAmount, tokenAmount, customerId);
    }

    function assignTokens(address receiver, uint tokenAmount) private {
        require(token.transferFrom(beneficiary, receiver, tokenAmount));
    }

    /**
     * Preallocate tokens for developers, company and bounty
     */
    function preallocateTokens() private {
        uint multiplier = 10 ** 18;
        assignTokens(0xc8337b3e03f5946854e6C5d2F5f3Ad0511Bb2599, 4300000 * multiplier); // developers
        assignTokens(0x354d755460A677B60A2B5e025A3b7397856b518E, 4100000 * multiplier); // company
        assignTokens(0x6AC724A02A4f47179A89d4A7532ED7030F55fD34, 2400000 * multiplier); // bounty
    }

}