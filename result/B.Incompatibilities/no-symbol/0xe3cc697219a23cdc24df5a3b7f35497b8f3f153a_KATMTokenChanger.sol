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
 * ITransferableOwnership
 *
 * Enhances ownership by allowing the current owner to 
 * transfer ownership to a new owner
 *
 * #created 01/10/2017
 * #author Frank Bonnet
 */
interface ITransferableOwnership {
    

    /**
     * Transfer ownership to `_newOwner`
     *
     * @param _newOwner The address of the account that will become the new owner 
     */
    function transferOwnership(address _newOwner) public;
}



/**
 * TransferableOwnership
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
 * ITokenChanger
 *
 * Basic token changer public interface 
 *
 * #created 06/10/2017
 * #author Frank Bonnet
 */
interface ITokenChanger {


    /**
     * Returns true if '_token' is on of the tokens that are 
     * managed by this token changer
     * 
     * @param _token The address being tested
     * @return Whether the '_token' is part of this token changer
     */
    function isToken(address _token) public view returns (bool);


    /**
     * Returns the address of the left token
     *
     * @return Left token address
     */
    function getLeftToken() public view returns (address);


    /**
     * Returns the address of the right token
     *
     * @return Right token address
     */
    function getRightToken() public view returns (address);


    /**
     * Returns the fee that is paid in tokens when using 
     * the token changer
     *
     * @return The percentage of tokens that is charged
     */
    function getFee() public view returns (uint);

    
    /**
     * Returns the rate that is used to change between tokens
     *
     * @return The rate used when changing tokens
     */
    function getRate() public view returns (uint);


    /**
     * Returns the precision of the rate and fee params
     *
     * @return The amount of decimals used
     */
    function getPrecision() public view returns (uint);


    /**
     * Calculates and returns the fee based on `_value` of tokens
     *
     * @return The actual fee
     */
    function calculateFee(uint _value) public view returns (uint);
}


/**
 * TokenChanger
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
    function TokenChanger(address _tokenLeft, address _tokenRight, uint _rate, uint _fee, uint _decimals, bool _paused, bool _burn) public {
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
    function isToken(address _token) public view returns (bool) {
        return _token == address(tokenLeft) || _token == address(tokenRight);
    }


    /**
     * Returns the address of the left token
     *
     * @return Left token address
     */
    function getLeftToken() public view returns (address) {
        return tokenLeft;
    }


    /**
     * Returns the address of the right token
     *
     * @return Right token address
     */
    function getRightToken() public view returns (address) {
        return tokenRight;
    }


    /**
     * Returns the fee that is paid in tokens when using 
     * the token changer
     *
     * @return The percentage of tokens that is charged
     */
    function getFee() public view returns (uint) {
        return fee;
    }


    /**
     * Returns the rate that is used to change between tokens
     *
     * @return The rate used when changing tokens
     */
    function getRate() public view returns (uint) {
        return rate;
    }


    /**
     * Returns the precision of the rate and fee params
     *
     * @return The amount of decimals used
     */
    function getPrecision() public view returns (uint) {
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
    function isPaused() public view returns (bool) {
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
    function calculateFee(uint _value) public view returns (uint) {
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
 * ATM Token Changer
 *
 * This contract of this token changer will allow anyone with a current balance of ATM, 
 * to deposit it and in return receive KATX, or KATM.
 *
 * KATM maintaining the primary security functions of the KATM token as 
 * outlined within the whitepaper.
 *
 * KATX as indicated by its ‘X’ designation is the utility token for those who are under strict 
 * compliance within their country of residence, and does not entitle holders to profit sharing.
 *
 * #created 30/10/2017
 * #author Frank Bonnet
 */
contract KATMTokenChanger is TokenChanger, TokenObserver, TransferableOwnership, TokenRetriever, IAuthenticationManager {

    enum Stages {
        Deploying,
        Deployed
    }

    Stages public stage;

    // Authentication
    IAuthenticator private authenticator;
    bool private requireAuthentication;


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
     * Throw if not authenticated
     * 
     * @param _account The account that is authenticated
     */
    modifier authenticate(address _account) {
        require(!requireAuthentication || authenticator.authenticate(_account));
        _;
    }


    /**
     * Construct Security - Utility token changer
     *
     * @param _security Ref to the Security token smart-contract
     * @param _utility Ref to the Utiltiy token smart-contract
     */
    function KATMTokenChanger(address _security, address _utility) public
        TokenChanger(_security, _utility, 8000, 500, 4, false, true) {
        stage = Stages.Deploying;
    }


    /**
     * Setup authentication
     *
     * @param _authenticator The address of the authenticator (whitelist)
     * @param _requireAuthentication Wether the crowdale requires contributors to be authenticated
     */
    function setupWhitelist(address _authenticator, bool _requireAuthentication) public only_owner at_stage(Stages.Deploying) {
        authenticator = IAuthenticator(_authenticator);
        requireAuthentication = _requireAuthentication;
    }


    /**
     * After calling the deploy function the crowdsale
     * rules become immutable 
     */
    function deploy() public only_owner at_stage(Stages.Deploying) {
        stage = Stages.Deployed;
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
     * Event handler that initializes the token conversion
     * 
     * Called by `_token` when a token amount is received on 
     * the address of this token changer
     *
     * @param _token The token contract that received the transaction
     * @param _from The account or contract that send the transaction
     * @param _value The value of tokens that where received
     */
    function onTokensReceived(address _token, address _from, uint _value) internal is_token(_token) authenticate(_from) at_stage(Stages.Deployed) {
        require(_token == msg.sender);
        
        // Convert tokens
        convert(_token, _from, _value);
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
    }


    /**
     * Prevents the accidental sending of ether
     */
    function () public payable {
        revert();
    }
}