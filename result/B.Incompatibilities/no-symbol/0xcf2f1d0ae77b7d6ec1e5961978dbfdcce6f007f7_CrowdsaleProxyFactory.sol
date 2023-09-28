pragma solidity ^0.4.18;

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
     * Withdraw allocated tokens
     *
     * @param _beneficiary Address to send to
     */
    function withdrawTokensTo(address _beneficiary) public;


    /**
     * Withdraw allocated ether
     */
    function withdrawEther() public;


    /**
     * Withdraw allocated ether
     *
     * @param _beneficiary Address to send to
     */
    function withdrawEtherTo(address _beneficiary) public;


    /**
     * Refund in the case of an unsuccessful crowdsale. The 
     * crowdsale is considered unsuccessful if minAmount was 
     * not raised before end of the crowdsale
     */
    function refund() public;


    /**
     * Refund in the case of an unsuccessful crowdsale. The 
     * crowdsale is considered unsuccessful if minAmount was 
     * not raised before end of the crowdsale
     *
     * @param _beneficiary Address to send to
     */
    function refundTo(address _beneficiary) public;
}


/**
 * Adds to the memory signature of the contract 
 * that contains the code that is called by the 
 * dispatcher
 */
contract Dispatchable {


    /**
     * Target contract that contains the code
     */
    address private target;
}


/**
 * The dispatcher is a minimal 'shim' that dispatches calls to a targeted
 * contract without returning any data. 
 *
 * Calls are made using 'delegatecall', meaning all storage and value
 * is kept on the dispatcher.
 */
contract SimpleDispatcher {

    /**
     * Target contract that contains the code
     */
    address private target;


    /**
     * Initialize simple dispatcher
     *
     * @param _target Contract that holds the code
     */
    function SimpleDispatcher(address _target) public {
        target = _target;
    }


    /**
     * Execute target code in the context of the dispatcher
     */
    function () public payable {
        var dest = target;
        assembly {
            calldatacopy(0x0, 0x0, calldatasize)
            switch delegatecall(sub(gas, 10000), dest, 0x0, calldatasize, 0, 0)
            case 0 { revert(0, 0) } // Throw
        }
    }
}


/**
 * PersonalCrowdsaleProxy Dispatcher
 *
 * #created 31/12/2017
 * #author Frank Bonnet
 */
contract PersonalCrowdsaleProxyDispatcher is SimpleDispatcher {

    // Target
    address public targetCrowdsale;
    address public targetToken;

    // Owner
    address public beneficiary;
    bytes32 private passphraseHash;


    /**
     * Deploy personal proxy
     *
     * @param _target Target contract to dispach calls to
     * @param _targetCrowdsale Target crowdsale to invest in
     * @param _targetToken Token that is bought
     * @param _passphraseHash Hash of the passphrase 
     */
    function PersonalCrowdsaleProxyDispatcher(address _target, address _targetCrowdsale, address _targetToken, bytes32 _passphraseHash) public 
        SimpleDispatcher(_target) {
        targetCrowdsale = _targetCrowdsale;
        targetToken = _targetToken;
        passphraseHash = _passphraseHash;
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
 * IPersonalCrowdsaleProxy
 *
 * #created 22/11/2017
 * #author Frank Bonnet
 */
interface IPersonalCrowdsaleProxy {


    /**
     * Receive ether to forward to the target crowdsale
     */
    function () public payable;


    /**
     * Invest received ether in target crowdsale
     */
    function invest() public;


    /**
     * Request a refund from the target crowdsale
     */
    function refund() public;


    /**
     * Request outstanding token balance from the 
     * target crowdsale
     */
    function updateTokenBalance() public;


    /**
     * Transfer token balance to beneficiary
     */
    function withdrawTokens() public;


    /**
     * Request outstanding ether balance from the 
     * target crowdsale
     */
    function updateEtherBalance() public;


    /**
     * Transfer ether balance to beneficiary
     */
    function withdrawEther() public;
}


/**
 * PersonalCrowdsaleProxy
 *
 * #created 31/12/2017
 * #author Frank Bonnet
 */
contract PersonalCrowdsaleProxy is IPersonalCrowdsaleProxy, Dispatchable {

    // Target
    ICrowdsale public targetCrowdsale;
    IToken public targetToken;

    // Owner
    address public beneficiary;
    bytes32 private passphraseHash;


    /**
     * Restrict call access to when the beneficiary 
     * address is known
     */
    modifier when_beneficiary_is_known() {
        require(beneficiary != address(0));
        _;
    }


    /**
     * Restrict call access to when the beneficiary 
     * address is unknown
     */
    modifier when_beneficiary_is_unknown() {
        require(beneficiary == address(0));
        _;
    }


    /**
     * Set the beneficiary account. Tokens and ether will be send 
     * to this address
     *
     * @param _beneficiary The address to receive tokens and ether
     * @param _passphrase The raw passphrasse
     */
    function setBeneficiary(address _beneficiary, bytes32 _passphrase) public when_beneficiary_is_unknown {
        require(keccak256(_passphrase) == passphraseHash);
        beneficiary = _beneficiary;
    }


    /**
     * Receive ether to forward to the target crowdsale
     */
    function () public payable {
        // Just receive ether
    }


    /**
     * Invest received ether in target crowdsale
     */
    function invest() public {
        targetCrowdsale.contribute.value(this.balance)();
    }


    /**
     * Request a refund from the target crowdsale
     */
    function refund() public {
        targetCrowdsale.refund();
    }


    /**
     * Request outstanding token balance from the 
     * target crowdsale
     */
    function updateTokenBalance() public {
        targetCrowdsale.withdrawTokens();
    }


    /**
     * Transfer token balance to beneficiary
     */
    function withdrawTokens() public when_beneficiary_is_known {
        uint balance = targetToken.balanceOf(this);
        targetToken.transfer(beneficiary, balance);
    }


    /**
     * Request outstanding ether balance from the 
     * target crowdsale
     */
    function updateEtherBalance() public {
        targetCrowdsale.withdrawEther();
    }


    /**
     * Transfer ether balance to beneficiary
     */
    function withdrawEther() public when_beneficiary_is_known {
        beneficiary.transfer(this.balance);
    }
}


/**
 * CrowdsaleProxyFactory
 *
 * #created 21/12/2017
 * #author Frank Bonnet
 */
contract CrowdsaleProxyFactory {

    // Target 
    address public targetCrowdsale;
    address public targetToken;

    // Dispatch target
    address private personalCrowdsaleProxyTarget;


    // Events
    event ProxyCreated(address proxy, address beneficiary);


    /**
     * Deploy factory
     *
     * @param _targetCrowdsale Target crowdsale to invest in
     * @param _targetToken Token that is bought
     */
    function CrowdsaleProxyFactory(address _targetCrowdsale, address _targetToken) public {
        targetCrowdsale = _targetCrowdsale;
        targetToken = _targetToken;
        personalCrowdsaleProxyTarget = new PersonalCrowdsaleProxy();
    }

    
    /**
     * Deploy a contract that serves as a proxy to 
     * the target crowdsale
     *
     * @return The address of the deposit address
     */
    function createProxyAddress() public returns (address) {
        address proxy = new CrowdsaleProxy(msg.sender, targetCrowdsale);
        ProxyCreated(proxy, msg.sender);
        return proxy;
    }


    /**
     * Deploy a contract that serves as a proxy to 
     * the target crowdsale
     *
     * @param _beneficiary The owner of the proxy
     * @return The address of the deposit address
     */
    function createProxyAddressFor(address _beneficiary) public returns (address) {
        address proxy = new CrowdsaleProxy(_beneficiary, targetCrowdsale);
        ProxyCreated(proxy, _beneficiary);
        return proxy;
    }


    /**
     * Deploy a contract that serves as a proxy to 
     * the target crowdsale
     *
     * Contributions through this address will be made 
     * for the person that knows the passphrase
     *
     * @param _passphraseHash Hash of the passphrase 
     * @return The address of the deposit address
     */
    function createPersonalDepositAddress(bytes32 _passphraseHash) public returns (address) {
        address proxy = new PersonalCrowdsaleProxyDispatcher(
            personalCrowdsaleProxyTarget, targetCrowdsale, targetToken, _passphraseHash);
        ProxyCreated(proxy, msg.sender);
        return proxy;
    }


    /**
     * Deploy a contract that serves as a proxy to 
     * the target crowdsale
     *
     * Contributions through this address will be made 
     * for `_beneficiary`
     *
     * @param _beneficiary The owner of the proxy
     * @return The address of the deposit address
     */
    function createPersonalDepositAddressFor(address _beneficiary) public returns (address) {
        PersonalCrowdsaleProxy proxy = PersonalCrowdsaleProxy(new PersonalCrowdsaleProxyDispatcher(
            personalCrowdsaleProxyTarget, targetCrowdsale, targetToken, keccak256(bytes32(_beneficiary))));
        proxy.setBeneficiary(_beneficiary, bytes32(_beneficiary));
        ProxyCreated(proxy, _beneficiary);
        return proxy;
    }
}