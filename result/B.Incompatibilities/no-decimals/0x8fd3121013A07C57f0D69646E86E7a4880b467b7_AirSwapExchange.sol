pragma solidity ^0.4.11;

// See the Github at https://github.com/airswap/contracts

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/* Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20 */

contract ERC20 is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) public balances; // *added public
    mapping (address => mapping (address => uint256)) public allowed; // *added public
}

/** @title AirSwap exchange contract.
  * Assumes makers and takers have approved this contract to access their balances.
  */
contract AirSwapExchange {

    // Mapping of order hash to bool (true = already filled).
    mapping (bytes32 => bool) public fills;

    // Events that are emitted in different scenarios.
    event Filled(address indexed makerAddress, uint makerAmount, address indexed makerToken, address takerAddress, uint takerAmount, address indexed takerToken, uint256 expiration, uint256 nonce);
    event Canceled(address indexed makerAddress, uint makerAmount, address indexed makerToken, address takerAddress, uint takerAmount, address indexed takerToken, uint256 expiration, uint256 nonce);

    /** Event thrown when a trade fails
      * Error codes:
      * 1 -> 'The makeAddress and takerAddress must be different',
      * 2 -> 'The order has expired',
      * 3 -> 'This order has already been filled',
      * 4 -> 'The ether sent with this transaction does not match takerAmount',
      * 5 -> 'No ether is required for a trade between tokens',
      * 6 -> 'The sender of this transaction must match the takerAddress',
      * 7 -> 'Order has already been cancelled or filled'
      */
    event Failed(uint code, address indexed makerAddress, uint makerAmount, address indexed makerToken, address takerAddress, uint takerAmount, address indexed takerToken, uint256 expiration, uint256 nonce);

    /** Fills an order by transferring tokens between (maker or escrow) and taker.
      * maker is given tokenA to taker,
      */
    function fill(address makerAddress, uint makerAmount, address makerToken,
                  address takerAddress, uint takerAmount, address takerToken,
                  uint256 expiration, uint256 nonce, uint8 v, bytes32 r, bytes32 s) payable {

        if (makerAddress == takerAddress) {
            msg.sender.transfer(msg.value);
            Failed(1,
            makerAddress, makerAmount, makerToken,
            takerAddress, takerAmount, takerToken,
            expiration, nonce);
            return;
        }

        // Check if this order has expired
        if (expiration < now) {
            msg.sender.transfer(msg.value);
            Failed(2,
                makerAddress, makerAmount, makerToken,
                takerAddress, takerAmount, takerToken,
                expiration, nonce);
            return;
        }

        // Validate the message by signature.
        bytes32 hash = validate(makerAddress, makerAmount, makerToken,
            takerAddress, takerAmount, takerToken,
            expiration, nonce, v, r, s);

        // Check if this order has already been filled
        if (fills[hash]) {
            msg.sender.transfer(msg.value);
            Failed(3,
                makerAddress, makerAmount, makerToken,
                takerAddress, takerAmount, takerToken,
                expiration, nonce);
            return;
        }

        // Check to see if this an order for ether.
        if (takerToken == address(0x0)) {

            // Check to make sure the message value is the order amount.
            if (msg.value == takerAmount) {

                // Mark order as filled to prevent reentrancy.
                fills[hash] = true;

                // Perform the trade between makerAddress and takerAddress.
                // The transfer will throw if there's a problem.
                assert(transfer(makerAddress, takerAddress, makerAmount, makerToken));

                // Transfer the ether received from sender to makerAddress.
                makerAddress.transfer(msg.value);

                // Log an event to indicate completion.
                Filled(makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);

            } else {
                msg.sender.transfer(msg.value);
                Failed(4,
                    makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);
            }

        } else {
            // This is an order trading two tokens
            // Check that no ether has been sent accidentally
            if (msg.value != 0) {
                msg.sender.transfer(msg.value);
                Failed(5,
                    makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);
                return;
            }

            if (takerAddress == msg.sender) {

                // Mark order as filled to prevent reentrancy.
                fills[hash] = true;

                // Perform the trade between makerAddress and takerAddress.
                // The transfer will throw if there's a problem.
                // Assert should never fail
                assert(trade(makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken));

                // Log an event to indicate completion.
                Filled(
                    makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);

            } else {
                Failed(6,
                    makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);
            }
        }
    }

    /** Cancels an order by refunding escrow and adding it to the fills mapping.
      * Will log an event if
      * - order has been cancelled or
      * - order has already been filled
      * and will do nothing if the maker of the order in question is not the
      * msg.sender
      */
    function cancel(address makerAddress, uint makerAmount, address makerToken,
                    address takerAddress, uint takerAmount, address takerToken,
                    uint256 expiration, uint256 nonce, uint8 v, bytes32 r, bytes32 s) {

        // Validate the message by signature.
        bytes32 hash = validate(makerAddress, makerAmount, makerToken,
            takerAddress, takerAmount, takerToken,
            expiration, nonce, v, r, s);

        // Only the maker can cancel an order
        if (msg.sender == makerAddress) {

            // Check that order has not already been filled/cancelled
            if (fills[hash] == false) {

                // Cancel the order by considering it filled.
                fills[hash] = true;

                // Broadcast an event to the blockchain.
                Canceled(makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);

            } else {
                Failed(7,
                    makerAddress, makerAmount, makerToken,
                    takerAddress, takerAmount, takerToken,
                    expiration, nonce);
            }
        }
    }

    /** Atomic trade of tokens between first party and second party.
      * Throws if one of the trades does not go through.
      */
    function trade(address makerAddress, uint makerAmount, address makerToken,
                   address takerAddress, uint takerAmount, address takerToken) private returns (bool) {
        return (transfer(makerAddress, takerAddress, makerAmount, makerToken) &&
        transfer(takerAddress, makerAddress, takerAmount, takerToken));
    }

    /** Transfers tokens from first party to second party.
      * Prior to a transfer being done by the contract, ensure that
      * tokenVal.approve(this, amount, {from : address}) has been called
      * throws if the transferFrom of the token returns false
      * returns true if, the transfer went through
      */
    function transfer(address from, address to, uint amount, address token) private returns (bool) {
        require(ERC20(token).transferFrom(from, to, amount));
        return true;
    }

    /** Validates order arguments for fill() and cancel() functions. */
    function validate(address makerAddress, uint makerAmount, address makerToken,
                      address takerAddress, uint takerAmount, address takerToken,
                      uint256 expiration, uint256 nonce, uint8 v, bytes32 r, bytes32 s) private returns (bytes32) {

        // Hash arguments to identify the order.
        bytes32 hashV = keccak256(makerAddress, makerAmount, makerToken,
            takerAddress, takerAmount, takerToken,
            expiration, nonce);

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = sha3(prefix, hashV);

        require(ecrecover(prefixedHash, v, r, s) == makerAddress);

        return hashV;
    }
}