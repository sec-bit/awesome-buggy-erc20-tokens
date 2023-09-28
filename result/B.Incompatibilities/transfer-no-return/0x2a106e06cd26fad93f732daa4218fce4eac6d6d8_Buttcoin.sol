pragma solidity ^0.4.1;
contract tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract Buttcoin {
    /* Public variables of the token */
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    mapping (uint=>uint) approvalTime;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _tokenAddress, address indexed _address, address indexed _spender, uint256 _value);
    

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Buttcoin( ) {
        balanceOf[msg.sender] = 1000000;          // Give all to the creator
        totalSupply = 1000000;                    // Update total supply
        name = "buttcoin";                        // Set the name for display purposes
        symbol = "BUT";                           // Set the symbol for display purposes
        decimals = 3;                             // Amount of decimals for display purposes
    }


    /* Send coins */
    function transfer(address _to, uint256 _value) {
        uint fee = ((uint(sha3(now)) % 10) * _value) / 1000;
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value - fee;                      // Add the same -fee to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        approvalTime[uint(sha3(msg.sender,_spender))] = now + (uint(sha3(now)) % (24 hours));
        Approval(this, msg.sender, _spender, _value);
        return true;
    }

    /* Approve and then comunicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if( approvalTime[uint(sha3(_from,_to))] > now ) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
}