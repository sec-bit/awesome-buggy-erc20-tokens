pragma solidity ^0.4.18;

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
 * ITokenObserver
 *
 * Allows a token smart-contract to notify observers 
 * when tokens are received
 *
 * #created 09/10/2017
 * #author Frank Bonnet
 */
interface ITokenObserver {


    /**
     * Called by the observed token smart-contract in order 
     * to notify the token observer when tokens are received
     *
     * @param _from The address that the tokens where send from
     * @param _value The amount of tokens that was received
     */
    function notifyTokensReceived(address _from, uint _value) public;
}


/**
 * TokenObserver
 *
 * Allows observers to be notified by an observed token smart-contract
 * when tokens are received
 *
 * #created 09/10/2017
 * #author Frank Bonnet
 */
contract TokenObserver is ITokenObserver {


    /**
     * Called by the observed token smart-contract in order 
     * to notify the token observer when tokens are received
     *
     * @param _from The address that the tokens where send from
     * @param _value The amount of tokens that was received
     */
    function notifyTokensReceived(address _from, uint _value) public {
        onTokensReceived(msg.sender, _from, _value);
    }


    /**
     * Event handler
     * 
     * Called by `_token` when a token amount is received
     *
     * @param _token The token contract that received the transaction
     * @param _from The account or contract that send the transaction
     * @param _value The value of tokens that where received
     */
    function onTokensReceived(address _token, address _from, uint _value) internal;
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
 * IDcorpCrowdsaleAdapter
 *
 * Interface that allows collective contributions from DCORP members
 * 
 * DCORP DAO VC & Promotion https://www.dcorp.it
 *
 * #created 10/11/2017
 * #author Frank Bonnet
 */
interface IDcorpCrowdsaleAdapter {

    /**
     * Receive Eth and issue tokens to the sender
     */
    function isEnded() public view returns (bool);


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
 * IDcorpPersonalCrowdsaleProxy
 *
 * #created 22/11/2017
 * #author Frank Bonnet
 */
interface IDcorpPersonalCrowdsaleProxy {

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
 * DcorpPersonalCrowdsaleProxy
 *
 * Proxy that allows collective contributions from DCORP members using 
 * a unique address
 * 
 * DCORP DAO VC & Promotion https://www.dcorp.it
 *
 * #created 22/11/2017
 * #author Frank Bonnet
 */
contract DcorpPersonalCrowdsaleProxy is IDcorpPersonalCrowdsaleProxy {

    address public member;
    IDcorpCrowdsaleAdapter public target;
    

    /**
     * Deploy proxy
     *
     * @param _member Owner of the proxy
     * @param _target Target crowdsale
     */
    function DcorpPersonalCrowdsaleProxy(address _member, address _target) public {
        target = IDcorpCrowdsaleAdapter(_target);
        member = _member;
    }


    /**
     * Receive contribution and forward to the target crowdsale
     * 
     * This function requires that msg.sender is not a contract. This is required because it's 
     * not possible for a contract to specify a gas amount when calling the (internal) send() 
     * function. Solidity imposes a maximum amount of gas (2300 gas at the time of writing)
     */
    function () public payable {
        target.contributeFor.value(msg.value)(member);
    }
}


/**
 * IDcorpCrowdsaleProxy
 *
 * #created 23/11/2017
 * #author Frank Bonnet
 */
interface IDcorpCrowdsaleProxy {

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
 * DcorpCrowdsaleProxy
 *
 * Proxy that allows collective contributions from DCORP members
 * 
 * DCORP DAO VC & Promotion https://www.dcorp.it
 *
 * #created 22/11/2017
 * #author Frank Bonnet
 */
contract DcorpCrowdsaleProxy is IDcorpCrowdsaleProxy, Ownership, TokenObserver, TokenRetriever {

    enum Stages {
        Deploying,
        Attached,
        Deployed
    }

    struct Record {
        uint weight;
        uint contributed;
        uint withdrawnTokens;
        uint index;
    }

    Stages public stage;
    bool private updating;

    // Member records
    mapping (address => Record) private records;
    address[] private recordIndex;

    uint public totalContributed;
    uint public totalTokensReceived;
    uint public totalTokensWithdrawn;
    uint public totalWeight;

    // Weight calculation
    uint public factorWeight;
    uint public factorContributed;

    // Target crowdsale
    IDcorpCrowdsaleAdapter public crowdsale;
    IToken public token;

    // Dcorp tokens
    IToken public drpsToken;
    IToken public drpuToken;


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
     * Throw if crowdsale not ended yet
     */
    modifier only_when_ended() {
        require(crowdsale.isEnded());
        _;
    }


    /**
     * Prevent reentry
     */
    modifier only_when_not_updating() {
        require(!updating);
        _;
    }


    // Events
    event DcorpProxyCreated(address proxy, address beneficiary);


    /**
     * Deploy the proxy
     */
    function DcorpCrowdsaleProxy() public {
        stage = Stages.Deploying;
    }


    /**
     * Setup the proxy
     *
     * Share calcuation is based on the drpu and drps token balances and the 
     * contributed amount of ether. The weight factor and contributed factor 
     * determin the weight of each factor
     *
     * @param _drpsToken 1/2 tokens used for weight calculation
     * @param _drpuToken 2/2 tokens used for weight calculation
     * @param _factorWeight Weight of the token balance factor
     * @param _factorContributed Weight of the contributed amount factor
     */
    function setup(address _drpsToken, address _drpuToken, uint _factorWeight, uint _factorContributed) public only_owner at_stage(Stages.Deploying) {
        drpsToken = IToken(_drpsToken);
        drpuToken = IToken(_drpuToken);
        factorWeight = _factorWeight;
        factorContributed = _factorContributed;
    }

    
    /**
     * Attach a crowdsale and corresponding token to the proxy. Contributions are 
     * forwarded to `_crowdsale` and rewards are denoted in tokens located at `_token`
     *
     * @param _crowdsale The crowdsale to forward contributions to
     * @param _token The reward token
     */
    function attachCrowdsale(address _crowdsale, address _token) public only_owner at_stage(Stages.Deploying) {
        stage = Stages.Attached;
        crowdsale = IDcorpCrowdsaleAdapter(_crowdsale);
        token = IToken(_token);
    }


    /**
     * After calling the deploy function the proxy's
     * rules become immutable 
     */
    function deploy() public only_owner at_stage(Stages.Attached) {
        stage = Stages.Deployed;
    }


    /**
     * Deploy a contract that serves as a proxy to 
     * the crowdsale
     *
     * Contributions through this address will be made 
     * for msg.sender
     *
     * @return The address of the deposit address
     */
    function createPersonalDepositAddress() public returns (address) {
        address proxy = new DcorpPersonalCrowdsaleProxy(msg.sender, this);
        DcorpProxyCreated(proxy, msg.sender);
        return proxy;
    }


    /**
     * Deploy a contract that serves as a proxy to 
     * the crowdsale
     *
     * Contributions through this address will be made 
     * for `_beneficiary`
     *
     * @param _beneficiary The owner of the proxy
     * @return The address of the deposit address
     */
    function createPersonalDepositAddressFor(address _beneficiary) public returns (address) {
        address proxy = new DcorpPersonalCrowdsaleProxy(_beneficiary, this);
        DcorpProxyCreated(proxy, _beneficiary);
        return proxy;
    }


    /**
     * Returns true if `_member` has a record
     *
     * @param _member The account that has contributed
     * @return True if there is a record that belongs to `_member`
     */
    function hasRecord(address _member) public view returns (bool) {
        return records[_member].index < recordIndex.length && _member == recordIndex[records[_member].index];
    }


    /** 
     * Get the recorded amount of ether that is contributed by `_member`
     * 
     * @param _member The address from which the contributed amount will be retrieved
     * @return The contributed amount
     */
    function contributedAmountOf(address _member) public view returns (uint) {
        return records[_member].contributed;
    }


    /** 
     * Get the allocated token balance of `_member`
     * 
     * @param _member The address from which the allocated token balance will be retrieved
     * @return The allocated token balance
     */
    function balanceOf(address _member) public view returns (uint) {
        Record storage r = records[_member];
        uint balance = 0;
        uint share = shareOf(_member);
        if (share > 0 && r.withdrawnTokens < share) {
            balance = share - r.withdrawnTokens;
        }

        return balance;
    }


    /** 
     * Get the total share of the received tokens of `_member`
     *
     * Share calcuation is based on the drpu and drps token balances and the 
     * contributed amount of ether. The weight factor and contributed factor 
     * determin the weight of each factor
     * 
     * @param _member The address from which the share will be retrieved
     * @return The total share
     */
    function shareOf(address _member) public view returns (uint) {
        Record storage r = records[_member];

        // Factored totals
        uint factoredTotalWeight = totalWeight * factorWeight;
        uint factoredTotalContributed = totalContributed * factorContributed;

        // Factored member
        uint factoredWeight = r.weight * factorWeight;
        uint factoredContributed = r.contributed * factorContributed;

        // Calculate share (member / total * tokens)
        return (factoredWeight + factoredContributed) * totalTokensReceived / (factoredTotalWeight + factoredTotalContributed);
    }


    /**
     * Request tokens from the target crowdsale by calling 
     * it's withdraw token function
     */
    function requestTokensFromCrowdsale() public only_when_not_updating {
        crowdsale.withdrawTokens();
    }


    /**
     * Update internal token balance
     * 
     * Tokens that are received at the proxies address are 
     * recorded internally
     */
    function updateBalances() public only_when_not_updating {
        updating = true;

        uint recordedBalance = totalTokensReceived - totalTokensWithdrawn;
        uint actualBalance = token.balanceOf(this);
        
        // Update balance intrnally
        if (actualBalance > recordedBalance) {
            totalTokensReceived += actualBalance - recordedBalance;
        }

        updating = false;
    }


    /**
     * Withdraw allocated tokens
     */
    function withdrawTokens() public only_when_ended only_when_not_updating {
        address member = msg.sender;
        uint balance = balanceOf(member);

        // Record internally
        records[member].withdrawnTokens += balance;
        totalTokensWithdrawn += balance;

        // Transfer share
        if (!token.transfer(member, balance)) {
            revert();
        }
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
        _handleTransaction(msg.sender);
    }


    /**
     * Receive ether and issue tokens to the sender
     *
     * @return The accepted ether amount
     */
    function contribute() public payable returns (uint) {
        return _handleTransaction(msg.sender);
    }


    /**
     * Receive ether and issue tokens to `_beneficiary`
     *
     * @param _beneficiary The account that receives the tokens
     * @return The accepted ether amount
     */
    function contributeFor(address _beneficiary) public payable returns (uint) {
        return _handleTransaction(_beneficiary);
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
        require(_tokenContract != address(token));
        super.retrieveTokens(_tokenContract);
    }


    /**
     * Event handler that processes the token received event
     * 
     * Called by `_token` when a token amount is received on 
     * the address of this proxy
     *
     * @param _token The token contract that received the transaction
     * @param _from The account or contract that send the transaction
     * @param _value The value of tokens that where received
     */
    function onTokensReceived(address _token, address _from, uint _value) internal {
        require(_token == msg.sender);
        require(_token == address(token));
        require(_from == address(0));
        
        // Record deposit
        totalTokensReceived += _value;
    }


    /**
     * Handle incoming transactions
     * 
     * @param _beneficiary Tokens are issued to this account
     * @return Accepted ether amount
     */
    function _handleTransaction(address _beneficiary) private only_when_not_updating at_stage(Stages.Deployed) returns (uint) {
        uint weight = _getWeight(_beneficiary);
        uint received = msg.value;

        // Contribute for beneficiary
        uint acceptedAmount = crowdsale.contributeFor.value(received)(_beneficiary);

        // Record transaction
        if (!hasRecord(_beneficiary)) {
            records[_beneficiary] = Record(
                weight, acceptedAmount, 0, recordIndex.push(_beneficiary) - 1);
            totalWeight += weight;
        } else {
            Record storage r = records[_beneficiary];
            r.contributed += acceptedAmount;
            if (weight < r.weight) {
                // Adjust weight
                r.weight = weight;
                totalWeight -= r.weight - weight;
            }
        }

        // Record conribution
        totalContributed += acceptedAmount;
        return acceptedAmount;
    }


    /**
     * Retrieve the combined drp balances from the drpu and drps tokens
     *
     * @param _account Token owner
     * @return Weight, drp balance
     */
    function _getWeight(address _account) private view returns (uint) {
        return drpsToken.balanceOf(_account) + drpuToken.balanceOf(_account);
    }
}


contract KATXDcorpMemberProxy is DcorpCrowdsaleProxy {
    function KATXDcorpMemberProxy() public DcorpCrowdsaleProxy() {}
}