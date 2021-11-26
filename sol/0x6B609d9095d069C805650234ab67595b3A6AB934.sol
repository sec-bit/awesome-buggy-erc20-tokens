pragma solidity ^0.4.18;

/**
 * IPausable
 *
 * Simple interface to pause and resume 
 *
 * #created 11/10/2017
 * #author Frank Bonnet
 */
interface IPausable {


    /**
     * Returns whether the implementing contract is 
     * currently paused or not
     *
     * @return Whether the paused state is active
     */
    function isPaused() public view returns (bool);


    /**
     * Change the state to paused
     */
    function pause() public;


    /**
     * Change the state to resume, undo the effects 
     * of calling pause
     */
    function resume() public;
}


/**
 * IOwnership
 *
 * Perminent ownership
 *
 * #created 01/10/2017
 * #author Frank Bonnet
 */
interface IOwnership {

    /**
     * Returns true if `_account` is the current owner
     *
     * @param _account The address to test against
     */
    function isOwner(address _account) public view returns (bool);


    /**
     * Gets the current owner
     *
     * @return address The current owner
     */
    function getOwner() public view returns (address);
}


/**
 * Ownership
 *
 * Perminent ownership
 *
 * #created 01/10/2017
 * #author Frank Bonnet
 */
contract Ownership is IOwnership {

    // Owner
    address internal owner;


    /**
     * Access is restricted to the current owner
     */
    modifier only_owner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * The publisher is the inital owner
     */
    function Ownership() public {
        owner = msg.sender;
    }


    /**
     * Returns true if `_account` is the current owner
     *
     * @param _account The address to test against
     */
    function isOwner(address _account) public view returns (bool) {
        return _account == owner;
    }


    /**
     * Gets the current owner
     *
     * @return address The current owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }
}


/**
 * ERC20 compatible token interface
 *
 * - Implements ERC 20 Token standard
 * - Implements short address attack fix
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
interface IToken { 

    /** 
     * Get the total supply of tokens
     * 
     * @return The total supply
     */
    function totalSupply() public view returns (uint);


    /** 
     * Get balance of `_owner` 
     * 
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) public view returns (uint);


    /** 
     * Send `_value` token to `_to` from `msg.sender`
     * 
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint _value) public returns (bool);


    /** 
     * Send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * 
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint _value) public returns (bool);


    /** 
     * `msg.sender` approves `_spender` to spend `_value` tokens
     * 
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint _value) public returns (bool);


    /** 
     * Get the amount of remaining tokens that `_spender` is allowed to spend from `_owner`
     * 
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) public view returns (uint);
}


/**
 * IManagedToken
 *
 * Adds the following functionality to the basic ERC20 token
 * - Locking
 * - Issuing
 * - Burning 
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
interface IManagedToken { 

    /** 
     * Returns true if the token is locked
     * 
     * @return Whether the token is locked
     */
    function isLocked() public view returns (bool);


    /**
     * Locks the token so that the transfering of value is disabled 
     *
     * @return Whether the unlocking was successful or not
     */
    function lock() public returns (bool);


    /**
     * Unlocks the token so that the transfering of value is enabled 
     *
     * @return Whether the unlocking was successful or not
     */
    function unlock() public returns (bool);


    /**
     * Issues `_value` new tokens to `_to`
     *
     * @param _to The address to which the tokens will be issued
     * @param _value The amount of new tokens to issue
     * @return Whether the tokens where sucessfully issued or not
     */
    function issue(address _to, uint _value) public returns (bool);


    /**
     * Burns `_value` tokens of `_from`
     *
     * @param _from The address that owns the tokens to be burned
     * @param _value The amount of tokens to be burned
     * @return Whether the tokens where sucessfully burned or not 
     */
    function burn(address _from, uint _value) public returns (bool);
}


/**
 * ITokenRetriever
 *
 * Allows tokens to be retrieved from a contract
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
interface ITokenRetriever {

    /**
     * Extracts tokens from the contract
     *
     * @param _tokenContract The address of ERC20 compatible token
     */
    function retrieveTokens(address _tokenContract) public;
}


/**
 * TokenRetriever
 *
 * Allows tokens to be retrieved from a contract
 *
 * #created 18/10/2017
 * #author Frank Bonnet
 */
contract TokenRetriever is ITokenRetriever {

    /**
     * Extracts tokens from the contract
     *
     * @param _tokenContract The address of ERC20 compatible token
     */
    function retrieveTokens(address _tokenContract) public {
        IToken tokenInstance = IToken(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(this);
        if (tokenBalance > 0) {
            tokenInstance.transfer(msg.sender, tokenBalance);
        }
    }
}


/**
 * IAuthenticator 
 *
 * Authenticator interface
 *
 * #created 15/10/2017
 * #author Frank Bonnet
 */
interface IAuthenticator {
    

    /**
     * Authenticate 
     *
     * Returns whether `_account` is authenticated or not
     *
     * @param _account The account to authenticate
     * @return whether `_account` is successfully authenticated
     */
    function authenticate(address _account) public view returns (bool);
}


/**
 * IAuthenticationManager 
 *
 * Allows the authentication process to be enabled and disabled
 *
 * #created 15/10/2017
 * #author Frank Bonnet
 */
interface IAuthenticationManager {
    

    /**
     * Returns true if authentication is enabled and false 
     * otherwise
     *
     * @return Whether the converter is currently authenticating or not
     */
    function isAuthenticating() public view returns (bool);


    /**
     * Enable authentication
     */
    function enableAuthentication() public;


    /**
     * Disable authentication
     */
    function disableAuthentication() public;
}


/**
 * IWingsAdapter
 * 
 * WINGS DAO Price Discovery & Promotion Pre-Beta https://www.wings.ai
 *
 * #created 04/10/2017
 * #author Frank Bonnet
 */
interface IWingsAdapter {

    /**
     * Get the total raised amount of Ether
     *
     * Can only increase, meaning if you withdraw ETH from the wallet, it should be not modified (you can use two fields 
     * to keep one with a total accumulated amount) amount of ETH in contract and totalCollected for total amount of ETH collected
     *
     * @return Total raised Ether amount
     */
    function totalCollected() public view returns (uint);
}


/**
 * IPersonalCrowdsaleProxy
 *
 * #created 22/11/2017
 * #author Frank Bonnet
 */
interface IPersonalCrowdsaleProxy {

    /**
     * Receive ether and issue tokens
     * 
     * This function requires that msg.sender is not a contract. This is required because it's 
     * not possible for a contract to specify a gas amount when calling the (internal) send() 
     * function. Solidity imposes a maximum amount of gas (2300 gas at the time of writing)
     * 
     * Contracts can call the contribute() function instead
     */
    function () public payable;
}


/**
 * PersonalCrowdsaleProxy
 *
 * #created 22/11/2017
 * #author Frank Bonnet
 */
contract PersonalCrowdsaleProxy is IPersonalCrowdsaleProxy {

    address public owner;
    ICrowdsale public target;
    

    /**
     * Deploy proxy
     *
     * @param _owner Owner of the proxy
     * @param _target Target crowdsale
     */
    function PersonalCrowdsaleProxy(address _owner, address _target) public {
        target = ICrowdsale(_target);
        owner = _owner;
    }


    /**
     * Receive contribution and forward to the target crowdsale
     * 
     * This function requires that msg.sender is not a contract. This is required because it's 
     * not possible for a contract to specify a gas amount when calling the (internal) send() 
     * function. Solidity imposes a maximum amount of gas (2300 gas at the time of writing)
     */
    function () public payable {
        target.contributeFor.value(msg.value)(owner);
    }
}


/**
 * ICrowdsaleProxy
 *
 * #created 23/11/2017
 * #author Frank Bonnet
 */
interface ICrowdsaleProxy {

    /**
     * Receive ether and issue tokens to the sender
     * 
     * This function requires that msg.sender is not a contract. This is required because it's 
     * not possible for a contract to specify a gas amount when calling the (internal) send() 
     * function. Solidity imposes a maximum amount of gas (2300 gas at the time of writing)
     * 
     * Contracts can call the contribute() function instead
     */
    function () public payable;


    /**
     * Receive ether and issue tokens to the sender
     *
     * @return The accepted ether amount
     */
    function contribute() public payable returns (uint);


    /**
     * Receive ether and issue tokens to `_beneficiary`
     *
     * @param _beneficiary The account that receives the tokens
     * @return The accepted ether amount
     */
    function contributeFor(address _beneficiary) public payable returns (uint);
}


/**
 * CrowdsaleProxy
 *
 * #created 22/11/2017
 * #author Frank Bonnet
 */
contract CrowdsaleProxy is ICrowdsaleProxy {

    address public owner;
    ICrowdsale public target;
    

    /**
     * Deploy proxy
     *
     * @param _owner Owner of the proxy
     * @param _target Target crowdsale
     */
    function CrowdsaleProxy(address _owner, address _target) public {
        target = ICrowdsale(_target);
        owner = _owner;
    }


    /**
     * Receive contribution and forward to the crowdsale
     * 
     * This function requires that msg.sender is not a contract. This is required because it's 
     * not possible for a contract to specify a gas amount when calling the (internal) send() 
     * function. Solidity imposes a maximum amount of gas (2300 gas at the time of writing)
     */
    function () public payable {
        target.contributeFor.value(msg.value)(msg.sender);
    }


    /**
     * Receive ether and issue tokens to the sender
     *
     * @return The accepted ether amount
     */
    function contribute() public payable returns (uint) {
        target.contributeFor.value(msg.value)(msg.sender);
    }


    /**
     * Receive ether and issue tokens to `_beneficiary`
     *
     * @param _beneficiary The account that receives the tokens
     * @return The accepted ether amount
     */
    function contributeFor(address _beneficiary) public payable returns (uint) {
        target.contributeFor.value(msg.value)(_beneficiary);
    }
}


/**
 * ICrowdsale
 *
 * Base crowdsale interface to manage the sale of 
 * an ERC20 token
 *
 * #created 09/09/2017
 * #author Frank Bonnet
 */
interface ICrowdsale {

    /**
     * Returns true if the contract is currently in the presale phase
     *
     * @return True if in presale phase
     */
    function isInPresalePhase() public view returns (bool);


    /**
     * Returns true if the contract is currently in the ended stage
     *
     * @return True if ended
     */
    function isEnded() public view returns (bool);


    /**
     * Returns true if `_beneficiary` has a balance allocated
     *
     * @param _beneficiary The account that the balance is allocated for
     * @param _releaseDate The date after which the balance can be withdrawn
     * @return True if there is a balance that belongs to `_beneficiary`
     */
    function hasBalance(address _beneficiary, uint _releaseDate) public view returns (bool);


    /** 
     * Get the allocated token balance of `_owner`
     * 
     * @param _owner The address from which the allocated token balance will be retrieved
     * @return The allocated token balance
     */
    function balanceOf(address _owner) public view returns (uint);


    /** 
     * Get the allocated eth balance of `_owner`
     * 
     * @param _owner The address from which the allocated eth balance will be retrieved
     * @return The allocated eth balance
     */
    function ethBalanceOf(address _owner) public view returns (uint);


    /** 
     * Get invested and refundable balance of `_owner` (only contributions during the ICO phase are registered)
     * 
     * @param _owner The address from which the refundable balance will be retrieved
     * @return The invested refundable balance
     */
    function refundableEthBalanceOf(address _owner) public view returns (uint);


    /**
     * Returns the rate and bonus release date
     *
     * @param _phase The phase to use while determining the rate
     * @param _volume The amount wei used to determine what volume multiplier to use
     * @return The rate used in `_phase` multiplied by the corresponding volume multiplier
     */
    function getRate(uint _phase, uint _volume) public view returns (uint);


    /**
     * Convert `_wei` to an amount in tokens using 
     * the `_rate`
     *
     * @param _wei amount of wei to convert
     * @param _rate rate to use for the conversion
     * @return Amount in tokens
     */
    function toTokens(uint _wei, uint _rate) public view returns (uint);


    /**
     * Receive ether and issue tokens to the sender
     * 
     * This function requires that msg.sender is not a contract. This is required because it's 
     * not possible for a contract to specify a gas amount when calling the (internal) send() 
     * function. Solidity imposes a maximum amount of gas (2300 gas at the time of writing)
     * 
     * Contracts can call the contribute() function instead
     */
    function () public payable;


    /**
     * Receive ether and issue tokens to the sender
     *
     * @return The accepted ether amount
     */
    function contribute() public payable returns (uint);


    /**
     * Receive ether and issue tokens to `_beneficiary`
     *
     * @param _beneficiary The account that receives the tokens
     * @return The accepted ether amount
     */
    function contributeFor(address _beneficiary) public payable returns (uint);


    /**
     * Withdraw allocated tokens
     */
    function withdrawTokens() public;


    /**
     * Withdraw allocated ether
     */
    function withdrawEther() public;


    /**
     * Refund in the case of an unsuccessful crowdsale. The 
     * crowdsale is considered unsuccessful if minAmount was 
     * not raised before end of the crowdsale
     */
    function refund() public;
}


/**
 * Crowdsale
 *
 * Abstract base crowdsale contract that manages the sale of 
 * an ERC20 token
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
contract Crowdsale is ICrowdsale, Ownership {

    enum Stages {
        Deploying,
        Deployed,
        InProgress,
        Ended
    }

    struct Balance {
        uint eth;
        uint tokens;
        uint index;
    }

    struct Percentage {
        uint eth;
        uint tokens;
        bool overwriteReleaseDate;
        uint fixedReleaseDate;
        uint index; 
    }

    struct Payout {
        uint percentage;
        uint vestingPeriod;
    }

    struct Phase {
        uint rate;
        uint end;
        uint bonusReleaseDate;
        bool useVolumeMultiplier;
    }

    struct VolumeMultiplier {
        uint rateMultiplier;
        uint bonusReleaseDateMultiplier;
    }

    // Crowdsale details
    uint public baseRate;
    uint public minAmount; 
    uint public maxAmount; 
    uint public minAcceptedAmount;
    uint public minAmountPresale; 
    uint public maxAmountPresale;
    uint public minAcceptedAmountPresale;

    // Company address
    address public beneficiary; 

    // Denominators
    uint internal percentageDenominator;
    uint internal tokenDenominator;

    // Crowdsale state
    uint public start;
    uint public presaleEnd;
    uint public crowdsaleEnd;
    uint public raised;
    uint public allocatedEth;
    uint public allocatedTokens;
    Stages public stage;

    // Token contract
    IManagedToken public token;

    // Invested balances
    mapping (address => uint) private balances;

    // Alocated balances
    mapping (address => mapping(uint => Balance)) private allocated;
    mapping(address => uint[]) private allocatedIndex;

    // Stakeholders
    mapping (address => Percentage) private stakeholderPercentages;
    address[] private stakeholderPercentagesIndex;
    Payout[] private stakeholdersPayouts;

    // Crowdsale phases
    Phase[] private phases;

    // Volume multipliers
    mapping (uint => VolumeMultiplier) private volumeMultipliers;
    uint[] private volumeMultiplierThresholds;

    
    /**
     * Throw if at stage other than current stage
     * 
     * @param _stage expected stage to test for
     */
    modifier at_stage(Stages _stage) {
        require(stage == _stage);
        _;
    }


    /**
     * Only after crowdsaleEnd plus `_time`
     * 
     * @param _time Time to pass
     */
    modifier only_after(uint _time) {
        require(now > crowdsaleEnd + _time);
        _;
    }


    /**
     * Only after crowdsale
     */
    modifier only_after_crowdsale() {
        require(now > crowdsaleEnd);
        _;
    }


    /**
     * Throw if sender is not beneficiary
     */
    modifier only_beneficiary() {
        require(beneficiary == msg.sender);
        _;
    }


    /**
     * Start in the deploying stage
     */
    function Crowdsale() public {
        stage = Stages.Deploying;
    }


    /**
     * Setup the crowdsale
     *
     * @param _start The timestamp of the start date
     * @param _token The token that is sold
     * @param _tokenDenominator The token amount of decimals that the token uses
     * @param _percentageDenominator The percision of percentages
     * @param _minAmountPresale The min cap for the presale
     * @param _maxAmountPresale The max cap for the presale
     * @param _minAcceptedAmountPresale The lowest accepted amount during the presale phase
     * @param _minAmount The min cap for the ICO
     * @param _maxAmount The max cap for the ICO
     * @param _minAcceptedAmount The lowest accepted amount during the ICO phase
     */
    function setup(uint _start, address _token, uint _tokenDenominator, uint _percentageDenominator, uint _minAmountPresale, uint _maxAmountPresale, uint _minAcceptedAmountPresale, uint _minAmount, uint _maxAmount, uint _minAcceptedAmount) public only_owner at_stage(Stages.Deploying) {
        token = IManagedToken(_token);
        tokenDenominator = _tokenDenominator;
        percentageDenominator = _percentageDenominator;
        start = _start;
        minAmountPresale = _minAmountPresale;
        maxAmountPresale = _maxAmountPresale;
        minAcceptedAmountPresale = _minAcceptedAmountPresale;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        minAcceptedAmount = _minAcceptedAmount;
    }


    /**
     * Setup rates and phases
     *
     * @param _baseRate The rate without bonus
     * @param _phaseRates The rates for each phase
     * @param _phasePeriods The periods that each phase lasts (first phase is the presale phase)
     * @param _phaseBonusLockupPeriods The lockup period that each phase lasts
     * @param _phaseUsesVolumeMultiplier Wheter or not volume bonusses are used in the respective phase
     */
    function setupPhases(uint _baseRate, uint[] _phaseRates, uint[] _phasePeriods, uint[] _phaseBonusLockupPeriods, bool[] _phaseUsesVolumeMultiplier) public only_owner at_stage(Stages.Deploying) {
        baseRate = _baseRate;
        presaleEnd = start + _phasePeriods[0]; // First phase is expected to be the presale phase
        crowdsaleEnd = start; // Plus the sum of the rate phases

        for (uint i = 0; i < _phaseRates.length; i++) {
            crowdsaleEnd += _phasePeriods[i];
            phases.push(Phase(_phaseRates[i], crowdsaleEnd, 0, _phaseUsesVolumeMultiplier[i]));
        }

        for (uint ii = 0; ii < _phaseRates.length; ii++) {
            if (_phaseBonusLockupPeriods[ii] > 0) {
                phases[ii].bonusReleaseDate = crowdsaleEnd + _phaseBonusLockupPeriods[ii];
            }
        }
    }


    /**
     * Setup stakeholders
     *
     * @param _stakeholders The addresses of the stakeholders (first stakeholder is the beneficiary)
     * @param _stakeholderEthPercentages The eth percentages of the stakeholders
     * @param _stakeholderTokenPercentages The token percentages of the stakeholders
     * @param _stakeholderTokenPayoutOverwriteReleaseDates Wheter the vesting period is overwritten for the respective stakeholder
     * @param _stakeholderTokenPayoutFixedReleaseDates The vesting period after which the whole percentage of the tokens is released to the respective stakeholder
     * @param _stakeholderTokenPayoutPercentages The percentage of the tokens that is released at the respective date
     * @param _stakeholderTokenPayoutVestingPeriods The vesting period after which the respective percentage of the tokens is released
     */
    function setupStakeholders(address[] _stakeholders, uint[] _stakeholderEthPercentages, uint[] _stakeholderTokenPercentages, bool[] _stakeholderTokenPayoutOverwriteReleaseDates, uint[] _stakeholderTokenPayoutFixedReleaseDates, uint[] _stakeholderTokenPayoutPercentages, uint[] _stakeholderTokenPayoutVestingPeriods) public only_owner at_stage(Stages.Deploying) {
        beneficiary = _stakeholders[0]; // First stakeholder is expected to be the beneficiary
        for (uint i = 0; i < _stakeholders.length; i++) {
            stakeholderPercentagesIndex.push(_stakeholders[i]);
            stakeholderPercentages[_stakeholders[i]] = Percentage(
                _stakeholderEthPercentages[i], 
                _stakeholderTokenPercentages[i], 
                _stakeholderTokenPayoutOverwriteReleaseDates[i],
                _stakeholderTokenPayoutFixedReleaseDates[i], i);
        }

        // Percentages add up to 100
        for (uint ii = 0; ii < _stakeholderTokenPayoutPercentages.length; ii++) {
            stakeholdersPayouts.push(Payout(_stakeholderTokenPayoutPercentages[ii], _stakeholderTokenPayoutVestingPeriods[ii]));
        }
    }

    
    /**
     * Setup volume multipliers
     *
     * @param _volumeMultiplierRates The rates will be multiplied by this value (denominated by 4)
     * @param _volumeMultiplierLockupPeriods The lockup periods will be multiplied by this value (denominated by 4)
     * @param _volumeMultiplierThresholds The volume thresholds for each respective multiplier
     */
    function setupVolumeMultipliers(uint[] _volumeMultiplierRates, uint[] _volumeMultiplierLockupPeriods, uint[] _volumeMultiplierThresholds) public only_owner at_stage(Stages.Deploying) {
        require(phases.length > 0);
        volumeMultiplierThresholds = _volumeMultiplierThresholds;
        for (uint i = 0; i < volumeMultiplierThresholds.length; i++) {
            volumeMultipliers[volumeMultiplierThresholds[i]] = VolumeMultiplier(_volumeMultiplierRates[i], _volumeMultiplierLockupPeriods[i]);
        }
    }
    

    /**
     * After calling the deploy function the crowdsale
     * rules become immutable 
     */
    function deploy() public only_owner at_stage(Stages.Deploying) {
        require(phases.length > 0);
        require(stakeholderPercentagesIndex.length > 0);
        stage = Stages.Deployed;
    }


    /**
     * Prove that beneficiary is able to sign transactions 
     * and start the crowdsale
     */
    function confirmBeneficiary() public only_beneficiary at_stage(Stages.Deployed) {
        stage = Stages.InProgress;
    }


    /**
     * Returns true if the contract is currently in the presale phase
     *
     * @return True if in presale phase
     */
    function isInPresalePhase() public view returns (bool) {
        return stage == Stages.InProgress && now >= start && now <= presaleEnd;
    }


    /**
     * Returns true if the contract is currently in the ended stage
     *
     * @return True if ended
     */
    function isEnded() public view returns (bool) {
        return stage == Stages.Ended;
    }


    /**
     * Returns true if `_beneficiary` has a balance allocated
     *
     * @param _beneficiary The account that the balance is allocated for
     * @param _releaseDate The date after which the balance can be withdrawn
     * @return True if there is a balance that belongs to `_beneficiary`
     */
    function hasBalance(address _beneficiary, uint _releaseDate) public view returns (bool) {
        return allocatedIndex[_beneficiary].length > 0 && _releaseDate == allocatedIndex[_beneficiary][allocated[_beneficiary][_releaseDate].index];
    }


    /** 
     * Get the allocated token balance of `_owner`
     * 
     * @param _owner The address from which the allocated token balance will be retrieved
     * @return The allocated token balance
     */
    function balanceOf(address _owner) public view returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < allocatedIndex[_owner].length; i++) {
            sum += allocated[_owner][allocatedIndex[_owner][i]].tokens;
        }

        return sum;
    }


    /** 
     * Get the allocated eth balance of `_owner`
     * 
     * @param _owner The address from which the allocated eth balance will be retrieved
     * @return The allocated eth balance
     */
    function ethBalanceOf(address _owner) public view returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < allocatedIndex[_owner].length; i++) {
            sum += allocated[_owner][allocatedIndex[_owner][i]].eth;
        }

        return sum;
    }


    /** 
     * Get invested and refundable balance of `_owner` (only contributions during the ICO phase are registered)
     * 
     * @param _owner The address from which the refundable balance will be retrieved
     * @return The invested refundable balance
     */
    function refundableEthBalanceOf(address _owner) public view returns (uint) {
        return now > crowdsaleEnd && raised < minAmount ? balances[_owner] : 0;
    }


    /**
     * Returns the current phase based on the current time
     *
     * @return The index of the current phase
     */
    function getCurrentPhase() public view returns (uint) {
        for (uint i = 0; i < phases.length; i++) {
            if (now <= phases[i].end) {
                return i;
                break;
            }
        }

        return uint(-1); // Does not exist (underflow)
    }


    /**
     * Returns the rate and bonus release date
     *
     * @param _phase The phase to use while determining the rate
     * @param _volume The amount wei used to determin what volume multiplier to use
     * @return The rate used in `_phase` multiplied by the corresponding volume multiplier
     */
    function getRate(uint _phase, uint _volume) public view returns (uint) {
        uint rate = 0;
        if (stage == Stages.InProgress && now >= start) {
            Phase storage phase = phases[_phase];
            rate = phase.rate;

            // Find volume multiplier
            if (phase.useVolumeMultiplier && volumeMultiplierThresholds.length > 0 && _volume >= volumeMultiplierThresholds[0]) {
                for (uint i = volumeMultiplierThresholds.length; i > 0; i--) {
                    if (_volume >= volumeMultiplierThresholds[i - 1]) {
                        VolumeMultiplier storage multiplier = volumeMultipliers[volumeMultiplierThresholds[i - 1]];
                        rate += phase.rate * multiplier.rateMultiplier / percentageDenominator;
                        break;
                    }
                }
            }
        }
        
        return rate;
    }


    /**
     * Get distribution data based on the current phase and 
     * the volume in wei that is being distributed
     * 
     * @param _phase The current crowdsale phase
     * @param _volume The amount wei used to determine what volume multiplier to use
     * @return Volumes and corresponding release dates
     */
    function getDistributionData(uint _phase, uint _volume) internal view returns (uint[], uint[]) {
        Phase storage phase = phases[_phase];
        uint remainingVolume = _volume;

        bool usingMultiplier = false;
        uint[] memory volumes = new uint[](1);
        uint[] memory releaseDates = new uint[](1);

        // Find volume multipliers
        if (phase.useVolumeMultiplier && volumeMultiplierThresholds.length > 0 && _volume >= volumeMultiplierThresholds[0]) {
            uint phaseReleasePeriod = phase.bonusReleaseDate - crowdsaleEnd;
            for (uint i = volumeMultiplierThresholds.length; i > 0; i--) {
                if (_volume >= volumeMultiplierThresholds[i - 1]) {
                    if (!usingMultiplier) {
                        volumes = new uint[](i + 1);
                        releaseDates = new uint[](i + 1);
                        usingMultiplier = true;
                    }

                    VolumeMultiplier storage multiplier = volumeMultipliers[volumeMultiplierThresholds[i - 1]];
                    uint releaseDate = phase.bonusReleaseDate + phaseReleasePeriod * multiplier.bonusReleaseDateMultiplier / percentageDenominator;
                    uint volume = remainingVolume - volumeMultiplierThresholds[i - 1];

                    // Store increment
                    volumes[i] = volume;
                    releaseDates[i] = releaseDate;

                    remainingVolume -= volume;
                }
            }
        }

        // Store increment
        volumes[0] = remainingVolume;
        releaseDates[0] = phase.bonusReleaseDate;

        return (volumes, releaseDates);
    }


    /**
     * Convert `_wei` to an amount in tokens using 
     * the `_rate`
     *
     * @param _wei amount of wei to convert
     * @param _rate rate to use for the conversion
     * @return Amount in tokens
     */
    function toTokens(uint _wei, uint _rate) public view returns (uint) {
        return _wei * _rate * tokenDenominator / 1 ether;
    }


    /**
     * Receive Eth and issue tokens to the sender
     * 
     * This function requires that msg.sender is not a contract. This is required because it's 
     * not possible for a contract to specify a gas amount when calling the (internal) send() 
     * function. Solidity imposes a maximum amount of gas (2300 gas at the time of writing)
     * 
     * Contracts can call the contribute() function instead
     */
    function () public payable {
        require(msg.sender == tx.origin);
        _handleTransaction(msg.sender, msg.value);
    }


    /**
     * Receive ether and issue tokens to the sender
     *
     * @return The accepted ether amount
     */
    function contribute() public payable returns (uint) {
        return _handleTransaction(msg.sender, msg.value);
    }


    /**
     * Receive ether and issue tokens to `_beneficiary`
     *
     * @param _beneficiary The account that receives the tokens
     * @return The accepted ether amount
     */
    function contributeFor(address _beneficiary) public payable returns (uint) {
        return _handleTransaction(_beneficiary, msg.value);
    }


    /**
     * Function to end the crowdsale by setting 
     * the stage to Ended
     */
    function endCrowdsale() public at_stage(Stages.InProgress) {
        require(now > crowdsaleEnd || raised >= maxAmount);
        require(raised >= minAmount);
        stage = Stages.Ended;

        // Unlock token
        if (!token.unlock()) {
            revert();
        }

        // Allocate tokens (no allocation can be done after this period)
        uint totalTokenSupply = IToken(token).totalSupply() + allocatedTokens;
        for (uint i = 0; i < stakeholdersPayouts.length; i++) {
            Payout storage p = stakeholdersPayouts[i];
            _allocateStakeholdersTokens(totalTokenSupply * p.percentage / percentageDenominator, now + p.vestingPeriod);
        }

        // Allocate remaining ETH
        _allocateStakeholdersEth(this.balance - allocatedEth, 0);
    }


    /**
     * Withdraw allocated tokens
     */
    function withdrawTokens() public {
        withdrawTokensTo(msg.sender);
    }


    /**
     * Withdraw allocated tokens
     *
     * @param _beneficiary Address to send to
     */
    function withdrawTokensTo(address _beneficiary) public {
        uint tokensToSend = 0;
        for (uint i = 0; i < allocatedIndex[msg.sender].length; i++) {
            uint releaseDate = allocatedIndex[msg.sender][i];
            if (releaseDate <= now) {
                Balance storage b = allocated[msg.sender][releaseDate];
                tokensToSend += b.tokens;
                b.tokens = 0;
            }
        }

        if (tokensToSend > 0) {
            allocatedTokens -= tokensToSend;
            if (!token.issue(_beneficiary, tokensToSend)) {
                revert();
            }
        }
    }


    /**
     * Withdraw allocated ether
     */
    function withdrawEther() public {
        withdrawEtherTo(msg.sender);
    }


    /**
     * Withdraw allocated ether
     *
     * @param _beneficiary Address to send to
     */
    function withdrawEtherTo(address _beneficiary) public {
        uint ethToSend = 0;
        for (uint i = 0; i < allocatedIndex[msg.sender].length; i++) {
            uint releaseDate = allocatedIndex[msg.sender][i];
            if (releaseDate <= now) {
                Balance storage b = allocated[msg.sender][releaseDate];
                ethToSend += b.eth;
                b.eth = 0;
            }
        }

        if (ethToSend > 0) {
            allocatedEth -= ethToSend;
            if (!_beneficiary.send(ethToSend)) {
                revert();
            }
        }
    }


    /**
     * Refund in the case of an unsuccessful crowdsale. The 
     * crowdsale is considered unsuccessful if minAmount was 
     * not raised before end of the crowdsale
     */
    function refund() public only_after_crowdsale at_stage(Stages.InProgress) {
        refundTo(msg.sender);
    }


    /**
     * Refund in the case of an unsuccessful crowdsale. The 
     * crowdsale is considered unsuccessful if minAmount was 
     * not raised before end of the crowdsale
     *
     * @param _beneficiary Address to send to
     */
    function refundTo(address _beneficiary) public only_after_crowdsale at_stage(Stages.InProgress) {
        require(raised < minAmount);

        uint receivedAmount = balances[msg.sender];
        balances[msg.sender] = 0;

        if (receivedAmount > 0 && !_beneficiary.send(receivedAmount)) {
            balances[msg.sender] = receivedAmount;
        }
    }


    /**
     * Failsafe and clean-up mechanism
     */
    function destroy() public only_beneficiary only_after(2 years) {
        selfdestruct(beneficiary);
    }


    /**
     * Handle incoming transaction
     * 
     * @param _beneficiary Tokens are issued to this account
     * @param _received The amount that was received
     * @return The accepted ether amount
     */
    function _handleTransaction(address _beneficiary, uint _received) internal at_stage(Stages.InProgress) returns (uint) {
        require(now >= start && now <= crowdsaleEnd);
        require(isAcceptingContributions());
        require(isAcceptedContributor(_beneficiary));

        if (isInPresalePhase()) {
            return _handlePresaleTransaction(
                _beneficiary, _received);
        } else {
            return _handlePublicsaleTransaction(
                _beneficiary, _received);
        }
    }


    /**
     * Handle incoming transaction during the presale phase
     * 
     * @param _beneficiary Tokens are issued to this account
     * @param _received The amount that was received
     * @return The accepted ether amount
     */
    function _handlePresaleTransaction(address _beneficiary, uint _received) private returns (uint) {
        require(_received >= minAcceptedAmountPresale);
        require(raised < maxAmountPresale);

        uint acceptedAmount;
        if (raised + _received > maxAmountPresale) {
            acceptedAmount = maxAmountPresale - raised;
        } else {
            acceptedAmount = _received;
        }

        raised += acceptedAmount;

        // During the presale phase - Non refundable
        _allocateStakeholdersEth(acceptedAmount, 0); 

        // Issue tokens
        _distributeTokens(_beneficiary, _received, acceptedAmount);
        return acceptedAmount;
    }


    /**
     * Handle incoming transaction during the publicsale phase
     * 
     * @param _beneficiary Tokens are issued to this account
     * @param _received The amount that was received
     * @return The accepted ether amount
     */
    function _handlePublicsaleTransaction(address _beneficiary, uint _received) private returns (uint) {
        require(_received >= minAcceptedAmount);
        require(raised >= minAmountPresale);
        require(raised < maxAmount);

        uint acceptedAmount;
        if (raised + _received > maxAmount) {
            acceptedAmount = maxAmount - raised;
        } else {
            acceptedAmount = _received;
        }

        raised += acceptedAmount;
        
        // During the ICO phase - 100% refundable
        balances[_beneficiary] += acceptedAmount; 

        // Issue tokens
        _distributeTokens(_beneficiary, _received, acceptedAmount);
        return acceptedAmount;
    }


    /**
     * Distribute tokens 
     *
     * Tokens can be issued by instructing the token contract to create new tokens or by 
     * allocating tokens and instructing the token contract to create the tokens later
     * 
     * @param _beneficiary Tokens are issued to this account
     * @param _received The amount that was received
     * @param _acceptedAmount The amount that was accepted
     */
    function _distributeTokens(address _beneficiary, uint _received, uint _acceptedAmount) private {
        uint tokensToIssue = 0;
        uint phase = getCurrentPhase();
        var rate = getRate(phase, _acceptedAmount);
        if (rate == 0) {
            revert(); // Paused phase
        }

        // Volume multipliers
        var (volumes, releaseDates) = getDistributionData(
            phase, _acceptedAmount);
        
        // Allocate tokens
        for (uint i = 0; i < volumes.length; i++) {
            var tokensAtCurrentRate = toTokens(volumes[i], rate);
            if (rate > baseRate && releaseDates[i] > now) {
                uint bonusTokens = tokensAtCurrentRate * (rate - baseRate) / rate;
                _allocateTokens(_beneficiary, bonusTokens, releaseDates[i]);

                tokensToIssue += tokensAtCurrentRate - bonusTokens;
            } else {
                tokensToIssue += tokensAtCurrentRate;
            }
        }

        // Issue tokens
        if (tokensToIssue > 0 && !token.issue(_beneficiary, tokensToIssue)) {
            revert();
        }

        // Refund due to max cap hit
        if (_received - _acceptedAmount > 0 && !_beneficiary.send(_received - _acceptedAmount)) {
            revert();
        }
    }


    /**
     * Allocate ETH
     *
     * @param _beneficiary The account to alocate the eth for
     * @param _amount The amount of ETH to allocate
     * @param _releaseDate The date after which the eth can be withdrawn
     */    
    function _allocateEth(address _beneficiary, uint _amount, uint _releaseDate) internal {
        if (hasBalance(_beneficiary, _releaseDate)) {
            allocated[_beneficiary][_releaseDate].eth += _amount;
        } else {
            allocated[_beneficiary][_releaseDate] = Balance(
                _amount, 0, allocatedIndex[_beneficiary].push(_releaseDate) - 1);
        }

        allocatedEth += _amount;
    }


    /**
     * Allocate Tokens
     *
     * @param _beneficiary The account to allocate the tokens for
     * @param _amount The amount of tokens to allocate
     * @param _releaseDate The date after which the tokens can be withdrawn
     */    
    function _allocateTokens(address _beneficiary, uint _amount, uint _releaseDate) internal {
        if (hasBalance(_beneficiary, _releaseDate)) {
            allocated[_beneficiary][_releaseDate].tokens += _amount;
        } else {
            allocated[_beneficiary][_releaseDate] = Balance(
                0, _amount, allocatedIndex[_beneficiary].push(_releaseDate) - 1);
        }

        allocatedTokens += _amount;
    }


    /**
     * Allocate ETH for stakeholders
     *
     * @param _amount The amount of ETH to allocate
     * @param _releaseDate The date after which the eth can be withdrawn
     */    
    function _allocateStakeholdersEth(uint _amount, uint _releaseDate) internal {
        for (uint i = 0; i < stakeholderPercentagesIndex.length; i++) {
            Percentage storage p = stakeholderPercentages[stakeholderPercentagesIndex[i]];
            if (p.eth > 0) {
                _allocateEth(stakeholderPercentagesIndex[i], _amount * p.eth / percentageDenominator, _releaseDate);
            }
        }
    }


    /**
     * Allocate Tokens for stakeholders
     *
     * @param _amount The amount of tokens created
     * @param _releaseDate The date after which the tokens can be withdrawn (unless overwitten)
     */    
    function _allocateStakeholdersTokens(uint _amount, uint _releaseDate) internal {
        for (uint i = 0; i < stakeholderPercentagesIndex.length; i++) {
            Percentage storage p = stakeholderPercentages[stakeholderPercentagesIndex[i]];
            if (p.tokens > 0) {
                _allocateTokens(
                    stakeholderPercentagesIndex[i], 
                    _amount * p.tokens / percentageDenominator, 
                    p.overwriteReleaseDate ? p.fixedReleaseDate : _releaseDate);
            }
        }
    }


    /**
     * Allows the implementing contract to validate a 
     * contributing account
     *
     * @param _contributor Address that is being validated
     * @return Wheter the contributor is accepted or not
     */
    function isAcceptedContributor(address _contributor) internal view returns (bool);


    /**
     * Allows the implementing contract to prevent the accepting 
     * of contributions
     *
     * @return Wheter contributions are accepted or not
     */
    function isAcceptingContributions() internal view returns (bool);
}


/**
 * MoxyOne Crowdsale
 *
 * Advancing the blockchain industry by creating seamless and secure debit card 
 * and payment infrastructure for every company, project and ICO that issues cryptocurrency tokens. 
 *
 * #created 06/01/2018
 * #author Frank Bonnet
 */
contract MoxyOneCrowdsale is Crowdsale, TokenRetriever, IPausable, IAuthenticationManager, IWingsAdapter {

    // State
    bool private paused;

    // Authentication
    IAuthenticator private authenticator;
    bool private requireAuthentication;


    /**
     * Returns whether the implementing contract is 
     * currently paused or not
     *
     * @return Whether the paused state is active
     */
    function isPaused() public view returns (bool) {
        return paused;
    }


    /**
     * Change the state to paused
     */
    function pause() public only_owner {
        paused = true;
    }


    /**
     * Change the state to resume, undo the effects 
     * of calling pause
     */
    function resume() public only_owner {
        paused = false;
    }


    /**
     * Setup authentication
     *
     * @param _authenticator The address of the authenticator (whitelist)
     * @param _requireAuthentication Wether the crowdale requires contributors to be authenticated
     */
    function setupAuthentication(address _authenticator, bool _requireAuthentication) public only_owner at_stage(Stages.Deploying) {
        authenticator = IAuthenticator(_authenticator);
        requireAuthentication = _requireAuthentication;
    }


    /**
     * Returns true if authentication is enabled and false 
     * otherwise
     *
     * @return Whether the converter is currently authenticating or not
     */
    function isAuthenticating() public view returns (bool) {
        return requireAuthentication;
    }


    /**
     * Enable authentication
     */
    function enableAuthentication() public only_owner {
        requireAuthentication = true;
    }


    /**
     * Disable authentication
     */
    function disableAuthentication() public only_owner {
        requireAuthentication = false;
    }


    /**
     * Validate a contributing account
     *
     * @param _contributor Address that is being validated
     * @return Wheter the contributor is accepted or not
     */
    function isAcceptedContributor(address _contributor) internal view returns (bool) {
        return !requireAuthentication || authenticator.authenticate(_contributor);
    }


    /**
     * Indicate if contributions are currently accepted
     *
     * @return Wheter contributions are accepted or not
     */
    function isAcceptingContributions() internal view returns (bool) {
        return !paused;
    }


    /**
     * Wings integration - Get the total raised amount of Ether
     *
     * Can only increased, means if you withdraw ETH from the wallet, should be not modified (you can use two fields 
     * to keep one with a total accumulated amount) amount of ETH in contract and totalCollected for total amount of ETH collected
     *
     * @return Total raised Ether amount
     */
    function totalCollected() public view returns (uint) {
        return raised;
    }


    /**
     * Failsafe mechanism
     * 
     * Allows the owner to retrieve tokens from the contract that 
     * might have been send there by accident
     *
     * @param _tokenContract The address of ERC20 compatible token
     */
    function retrieveTokens(address _tokenContract) public only_owner {
        super.retrieveTokens(_tokenContract);

        // Retrieve tokens from our token contract
        ITokenRetriever(token).retrieveTokens(_tokenContract);
    }
}