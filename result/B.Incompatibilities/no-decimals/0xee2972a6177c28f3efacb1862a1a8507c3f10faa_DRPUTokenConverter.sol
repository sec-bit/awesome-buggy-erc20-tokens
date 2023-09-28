pragma solidity ^0.4.15;

/**
 * @title Ownership interface
 *
 * Perminent ownership
 *
 * #created 01/10/2017
 * #author Frank Bonnet
 */
contract IOwnership {

    /**
     * Returns true if `_account` is the current owner
     *
     * @param _account The address to test against
     */
    function isOwner(address _account) constant returns (bool);


    /**
     * Gets the current owner
     *
     * @return address The current owner
     */
    function getOwner() constant returns (address);
}


/**
 * @title Ownership
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
     * The publisher is the inital owner
     */
    function Ownership() {
        owner = msg.sender;
    }


    /**
     * Access is restricted to the current owner
     */
    modifier only_owner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * Returns true if `_account` is the current owner
     *
     * @param _account The address to test against
     */
    function isOwner(address _account) public constant returns (bool) {
        return _account == owner;
    }


    /**
     * Gets the current owner
     *
     * @return address The current owner
     */
    function getOwner() public constant returns (address) {
        return owner;
    }
}


/**
 * @title Transferable ownership interface
 *
 * Enhances ownership by allowing the current owner to 
 * transfer ownership to a new owner
 *
 * #created 01/10/2017
 * #author Frank Bonnet
 */
contract ITransferableOwnership {
    

    /**
     * Transfer ownership to `_newOwner`
     *
     * @param _newOwner The address of the account that will become the new owner 
     */
    function transferOwnership(address _newOwner);
}


/**
 * @title Transferable ownership
 *
 * Enhances ownership by allowing the current owner to 
 * transfer ownership to a new owner
 *
 * #created 01/10/2017
 * #author Frank Bonnet
 */
contract TransferableOwnership is ITransferableOwnership, Ownership {


    /**
     * Transfer ownership to `_newOwner`
     *
     * @param _newOwner The address of the account that will become the new owner 
     */
    function transferOwnership(address _newOwner) public only_owner {
        owner = _newOwner;
    }
}


/**
 * @title Pausable interface
 *
 * Simple interface to pause and resume 
 *
 * #created 11/10/2017
 * #author Frank Bonnet
 */
contract IPausable {

    /**
     * Returns whether the implementing contract is 
     * currently paused or not
     *
     * @return Whether the paused state is active
     */
    function isPaused() constant returns (bool);


    /**
     * Change the state to paused
     */
    function pause();


    /**
     * Change the state to resume, undo the effects 
     * of calling pause
     */
    function resume();
}


/**
 * @title IAuthenticationManager 
 *
 * Allows the authentication process to be enabled and disabled
 *
 * #created 15/10/2017
 * #author Frank Bonnet
 */
contract IAuthenticationManager {
    

    /**
     * Returns true if authentication is enabled and false 
     * otherwise
     *
     * @return Whether the converter is currently authenticating or not
     */
    function isAuthenticating() constant returns (bool);


    /**
     * Enable authentication
     */
    function enableAuthentication();


    /**
     * Disable authentication
     */
    function disableAuthentication();
}


/**
 * @title IAuthenticator 
 *
 * Authenticator interface
 *
 * #created 15/10/2017
 * #author Frank Bonnet
 */
contract IAuthenticator {
    

    /**
     * Authenticate 
     *
     * Returns whether `_account` is authenticated or not
     *
     * @param _account The account to authenticate
     * @return whether `_account` is successfully authenticated
     */
    function authenticate(address _account) constant returns (bool);
}


/**
 * @title IWhitelist 
 *
 * Whitelist authentication interface
 *
 * #created 04/10/2017
 * #author Frank Bonnet
 */
contract IWhitelist is IAuthenticator {
    

    /**
     * Returns whether an entry exists for `_account`
     *
     * @param _account The account to check
     * @return whether `_account` is has an entry in the whitelist
     */
    function hasEntry(address _account) constant returns (bool);


    /**
     * Add `_account` to the whitelist
     *
     * If an account is currently disabled, the account is reenabled, otherwise 
     * a new entry is created
     *
     * @param _account The account to add
     */
    function add(address _account);


    /**
     * Remove `_account` from the whitelist
     *
     * Will not actually remove the entry but disable it by updating
     * the accepted record
     *
     * @param _account The account to remove
     */
    function remove(address _account);
}


/**
 * @title Token retrieve interface
 *
 * Allows tokens to be retrieved from a contract
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
contract ITokenRetriever {

    /**
     * Extracts tokens from the contract
     *
     * @param _tokenContract The address of ERC20 compatible token
     */
    function retrieveTokens(address _tokenContract);
}


/**
 * @title Token retrieve
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
 * @title Token observer interface
 *
 * Allows a token smart-contract to notify observers 
 * when tokens are received
 *
 * #created 09/10/2017
 * #author Frank Bonnet
 */
contract ITokenObserver {

    /**
     * Called by the observed token smart-contract in order 
     * to notify the token observer when tokens are received
     *
     * @param _from The address that the tokens where send from
     * @param _value The amount of tokens that was received
     */
    function notifyTokensReceived(address _from, uint _value);
}


/**
 * @title Abstract token observer
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
 * @title ERC20 compatible token interface
 *
 * - Implements ERC 20 Token standard
 * - Implements short address attack fix
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
contract IToken { 

    /** 
     * Get the total supply of tokens
     * 
     * @return The total supply
     */
    function totalSupply() constant returns (uint);


    /** 
     * Get balance of `_owner` 
     * 
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) constant returns (uint);


    /** 
     * Send `_value` token to `_to` from `msg.sender`
     * 
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint _value) returns (bool);


    /** 
     * Send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * 
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint _value) returns (bool);


    /** 
     * `msg.sender` approves `_spender` to spend `_value` tokens
     * 
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint _value) returns (bool);


    /** 
     * Get the amount of remaining tokens that `_spender` is allowed to spend from `_owner`
     * 
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) constant returns (uint);
}


/**
 * @title ManagedToken interface
 *
 * Adds the following functionality to the basic ERC20 token
 * - Locking
 * - Issuing
 * - Burning 
 *
 * #created 29/09/2017
 * #author Frank Bonnet
 */
contract IManagedToken is IToken { 

    /** 
     * Returns true if the token is locked
     * 
     * @return Whether the token is locked
     */
    function isLocked() constant returns (bool);


    /**
     * Locks the token so that the transfering of value is disabled 
     *
     * @return Whether the unlocking was successful or not
     */
    function lock() returns (bool);


    /**
     * Unlocks the token so that the transfering of value is enabled 
     *
     * @return Whether the unlocking was successful or not
     */
    function unlock() returns (bool);


    /**
     * Issues `_value` new tokens to `_to`
     *
     * @param _to The address to which the tokens will be issued
     * @param _value The amount of new tokens to issue
     * @return Whether the tokens where sucessfully issued or not
     */
    function issue(address _to, uint _value) returns (bool);


    /**
     * Burns `_value` tokens of `_from`
     *
     * @param _from The address that owns the tokens to be burned
     * @param _value The amount of tokens to be burned
     * @return Whether the tokens where sucessfully burned or not 
     */
    function burn(address _from, uint _value) returns (bool);
}


/**
 * @title Token Changer interface
 *
 * Basic token changer public interface 
 *
 * #created 06/10/2017
 * #author Frank Bonnet
 */
contract ITokenChanger {

    /**
     * Returns true if '_token' is on of the tokens that are 
     * managed by this token changer
     * 
     * @param _token The address being tested
     * @return Whether the '_token' is part of this token changer
     */
    function isToken(address _token) constant returns (bool);


    /**
     * Returns the address of the left token
     *
     * @return Left token address
     */
    function getLeftToken() constant returns (address);


    /**
     * Returns the address of the right token
     *
     * @return Right token address
     */
    function getRightToken() constant returns (address);


    /**
     * Returns the fee that is paid in tokens when using 
     * the token changer
     *
     * @return The percentage of tokens that is charged
     */
    function getFee() constant returns (uint);

    
    /**
     * Returns the rate that is used to change between tokens
     *
     * @return The rate used when changing tokens
     */
    function getRate() constant returns (uint);


    /**
     * Returns the precision of the rate and fee params
     *
     * @return The amount of decimals used
     */
    function getPrecision() constant returns (uint);


    /**
     * Calculates and returns the fee based on `_value` of tokens
     *
     * @return The actual fee
     */
    function calculateFee(uint _value) constant returns (uint);
}


/**
 * @title Token Changer
 *
 * Provides a generic way to convert between two tokens using a fixed 
 * ratio and an optional fee.
 *
 * #created 06/10/2017
 * #author Frank Bonnet
 */
contract TokenChanger is ITokenChanger, IPausable {

    IManagedToken private tokenLeft; // tokenLeft = tokenRight * rate / precision
    IManagedToken private tokenRight; // tokenRight = tokenLeft / rate * precision

    uint private rate; // Ratio between tokens
    uint private fee; // Percentage lost in transfer
    uint private precision; // Precision 
    bool private paused; // Paused state
    bool private burn; // Whether the changer should burn tokens


    /**
     * Only if '_token' is the left or right token 
     * that of the token changer
     */
    modifier is_token(address _token) {
        require(_token == address(tokenLeft) || _token == address(tokenRight));
        _;
    }


    /**
     * Construct token changer
     *
     * @param _tokenLeft Ref to the 'left' token smart-contract
     * @param _tokenRight Ref to the 'right' token smart-contract
     * @param _rate The rate used when changing tokens
     * @param _fee The percentage of tokens that is charged
     * @param _decimals The amount of decimals used for _rate and _fee
     * @param _paused Whether the token changer starts in the paused state or not
     * @param _burn Whether the changer should burn tokens or not
     */
    function TokenChanger(address _tokenLeft, address _tokenRight, uint _rate, uint _fee, uint _decimals, bool _paused, bool _burn) {
        tokenLeft = IManagedToken(_tokenLeft);
        tokenRight = IManagedToken(_tokenRight);
        rate = _rate;
        fee = _fee;
        precision = _decimals > 0 ? 10**_decimals : 1;
        paused = _paused;
        burn = _burn;
    }

    
    /**
     * Returns true if '_token' is on of the tokens that are 
     * managed by this token changer
     * 
     * @param _token The address being tested
     * @return Whether the '_token' is part of this token changer
     */
    function isToken(address _token) public constant returns (bool) {
        return _token == address(tokenLeft) || _token == address(tokenRight);
    }


    /**
     * Returns the address of the left token
     *
     * @return Left token address
     */
    function getLeftToken() public constant returns (address) {
        return tokenLeft;
    }


    /**
     * Returns the address of the right token
     *
     * @return Right token address
     */
    function getRightToken() public constant returns (address) {
        return tokenRight;
    }


    /**
     * Returns the fee that is paid in tokens when using 
     * the token changer
     *
     * @return The percentage of tokens that is charged
     */
    function getFee() public constant returns (uint) {
        return fee;
    }


    /**
     * Returns the rate that is used to change between tokens
     *
     * @return The rate used when changing tokens
     */
    function getRate() public constant returns (uint) {
        return rate;
    }


    /**
     * Returns the precision of the rate and fee params
     *
     * @return The amount of decimals used
     */
    function getPrecision() public constant returns (uint) {
        return precision;
    }


    /**
     * Returns whether the token changer is currently 
     * paused or not. While being in the paused state 
     * the contract should revert the transaction instead 
     * of converting tokens
     *
     * @return Whether the token changer is in the paused state
     */
    function isPaused() public constant returns (bool) {
        return paused;
    }


    /**
     * Pause the token changer making the contract 
     * revert the transaction instead of converting 
     */
    function pause() public {
        paused = true;
    }


    /**
     * Resume the token changer making the contract 
     * convert tokens instead of reverting the transaction 
     */
    function resume() public {
        paused = false;
    }


    /**
     * Calculates and returns the fee based on `_value` of tokens
     *
     * @param _value The amount of tokens that is being converted
     * @return The actual fee
     */
    function calculateFee(uint _value) public constant returns (uint) {
        return fee == 0 ? 0 : _value * fee / precision;
    }


    /**
     * Converts tokens by burning the tokens received at the token smart-contact 
     * located at `_from` and by issuing tokens at the opposite token smart-contract
     *
     * @param _from The token smart-contract that received the tokens
     * @param _sender The account that send the tokens (token owner)
     * @param _value The amount of tokens that where received
     */
    function convert(address _from, address _sender, uint _value) internal {
        require(!paused);
        require(_value > 0);

        uint amountToIssue;
        if (_from == address(tokenLeft)) {
            amountToIssue = _value * rate / precision;
            tokenRight.issue(_sender, amountToIssue - calculateFee(amountToIssue));
            if (burn) {
                tokenLeft.burn(this, _value);
            }   
        } 
        
        else if (_from == address(tokenRight)) {
            amountToIssue = _value * precision / rate;
            tokenLeft.issue(_sender, amountToIssue - calculateFee(amountToIssue));
            if (burn) {
                tokenRight.burn(this, _value);
            } 
        }
    }
}


/**
 * @title DRPU Converter
 *
 * Will allow DRP token holders to convert their DRP Balance into DRPU at the ratio of 1:2, locking all recieved DRP into the converter.
 *
 * DRPU as indicated by its ‘U’ designation is Dcorp’s utility token for those who are under strict 
 * compliance within their country of residence, and does not entitle holders to profit sharing.
 *
 * https://www.dcorp.it/drpu
 *
 * #created 11/10/2017
 * #author Frank Bonnet
 */
contract DRPUTokenConverter is TokenChanger, IAuthenticationManager, TransferableOwnership, TokenRetriever {

    // Authentication
    IWhitelist private whitelist;
    bool private requireAuthentication;


    /**
     * Construct drp - drpu token changer
     *
     * Rate is multiplied by 10**6 taking into account the difference in 
     * decimals between (old) DRP (2) and DRPU (8)
     *
     * @param _whitelist The address of the whitelist authenticator
     * @param _drp Ref to the (old) DRP token smart-contract
     * @param _drpu Ref to the DRPU token smart-contract https://www.dcorp.it/drpu
     */
    function DRPUTokenConverter(address _whitelist, address _drp, address _drpu) 
        TokenChanger(_drp, _drpu, 2 * 10**6, 0, 0, false, false) {
        whitelist = IWhitelist(_whitelist);
        requireAuthentication = true;
    }


    /**
     * Returns true if authentication is enabled and false 
     * otherwise
     *
     * @return Whether the converter is currently authenticating or not
     */
    function isAuthenticating() public constant returns (bool) {
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
     * Pause the token changer making the contract 
     * revert the transaction instead of converting 
     */
    function pause() public only_owner {
        super.pause();
    }


    /**
     * Resume the token changer making the contract 
     * convert tokens instead of reverting the transaction 
     */
    function resume() public only_owner {
        super.resume();
    }


    /**
     * Request that the (old) drp smart-contract transfers `_value` worth 
     * of (old) drp to the drpu token converter to be converted
     * 
     * Note! This function requires the drpu token converter smart-contract 
     * to be approved to spend at least `_value` worth of (old) drp by the 
     * owner of the tokens by calling the approve() function in the (old) 
     * dpr token smart-contract
     *
     * @param _value The amount of tokens to transfer and convert
     */
    function requestConversion(uint _value) public {
        require(_value > 0);
        address sender = msg.sender;

        // Authenticate
        require(!requireAuthentication || whitelist.authenticate(sender));

        IToken drpToken = IToken(getLeftToken());
        drpToken.transferFrom(sender, this, _value); // Transfer old drp from sender to converter 
        convert(drpToken, sender, _value); // Convert to drps
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
        require(getLeftToken() != _tokenContract); // Ensure that the (old) drp token stays locked
        super.retrieveTokens(_tokenContract);
    }


    /**
     * Prevents the accidental sending of ether
     */
    function () payable {
        revert();
    }
}