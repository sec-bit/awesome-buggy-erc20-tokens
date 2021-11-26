pragma solidity ^0.4.8;
contract Soarcoin {

    mapping (address => uint256) balances;               // each address in this contract may have tokens. 
    address internal owner = 0x4Bce8E9850254A86a1988E2dA79e41Bc6793640d;                // the owner is the creator of the smart contract
    string public name = "Soarcoin";                     // name of this contract and investment fund
    string public symbol = "SOAR";                       // token symbol
    uint8 public decimals = 6;                           // decimals (for humans)
    uint256 public totalSupply = 5000000000000000;  
           
    modifier onlyOwner()
    {
        if (msg.sender != owner) throw;
        _;
    }

    function Soarcoin() { balances[owner] = totalSupply; }    

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // query balance
    function balanceOf(address _owner) constant returns (uint256 balance)
    {
        return balances[_owner];
    }

    // transfer tokens from one address to another
    function transfer(address _to, uint256 _value) returns (bool success)
    {
        if(_value <= 0) throw;                                      // Check send token value > 0;
        if (balances[msg.sender] < _value) throw;                   // Check if the sender has enough
        if (balances[_to] + _value < balances[_to]) throw;          // Check for overflows                          
        balances[msg.sender] -= _value;                             // Subtract from the sender
        balances[_to] += _value;                                    // Add the same to the recipient, if it's the contact itself then it signals a sell order of those tokens                       
        Transfer(msg.sender, _to, _value);                          // Notify anyone listening that this transfer took place
        return true;      
    }

    function mint(address _to, uint256 _value) onlyOwner
    {
        if(_value <= 0) throw;
    	balances[_to] += _value;
    	totalSupply += _value;
    }
}

/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract Token is Soarcoin {

    /// @return total amount of tokens
    

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */