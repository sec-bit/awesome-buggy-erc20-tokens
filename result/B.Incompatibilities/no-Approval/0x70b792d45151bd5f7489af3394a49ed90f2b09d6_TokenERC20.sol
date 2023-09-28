//Solidity code for APMA

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    
    string public name;
    string public symbol;
    uint8 public decimals = 4;
    uint256 public totalSupply;

    // This creates an array with all balances of the APMA holders .
    mapping (address => uint256) public balanceOf;

    //This creates an array of arrays to store the allowance provided by a contract owner to a given address 
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients the transfer of APMA between different accounts
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount of APMA burnt
    event Burn(address indexed from, uint256 value);

    
    // This is the initial function which will be called upon the creation of the APMA contract to generate the supply tokens 
    
    
    function TokenERC20(
    ) public {
        totalSupply = 1000000000 * 10 ** uint256(decimals);  // Total supply of APMA
        balanceOf[msg.sender] = totalSupply;                // Give the creator of the contract all the APMA
        name = "APMA";                                   // Giving the name "APMA"
        symbol = "APMA";                               // Setting the symbol of APMA
    }

    // Internal function for transfer of tokens between 2 different addresses
     
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    
    // Function to transfer APMAs to a given address from the contract owner 
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    // Function to transfer APMAs between two given addresses
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // Setting up the allowance for the spender on the behalf of the contract owner 
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    // Notification for allowance of a spender by the contract owner
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    // Depleting the APMA supply 
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    // Depleting the APMA supply from a given address
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}