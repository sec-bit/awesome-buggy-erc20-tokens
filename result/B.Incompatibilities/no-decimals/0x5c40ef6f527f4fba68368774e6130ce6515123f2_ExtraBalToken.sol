contract ExtraBalToken {
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }

    uint constant D160 = 0x10000000000000000000000000000000000000000;

    address public owner;

    function ExtraBalToken() {
        owner = msg.sender;
    }

    bool public sealed;
    // The 160 LSB is the address of the balance
    // The 96 MSB is the balance of that address.
    function fill(uint[] data) {
        if ((msg.sender != owner)||(sealed))
            throw;

        for (uint i=0; i<data.length; i++) {
            address a = address( data[i] & (D160-1) );
            uint amount = data[i] / D160;
            if (balanceOf[a] == 0) {   // In case it's filled two times, it only increments once
                balanceOf[a] = amount;
                totalSupply += amount;
            }
        }
    }

    function seal() {
        if ((msg.sender != owner)||(sealed))
            throw;

        sealed= true;
    }

}