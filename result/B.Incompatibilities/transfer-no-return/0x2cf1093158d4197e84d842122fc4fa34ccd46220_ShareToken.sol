contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract ShareToken {
    /* Public variables of the token */
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    address public corporationContract;
    mapping (address => bool) public identityApproved;
    mapping (address => bool) public voteLock; // user must keep at least 1 share if they are involved in voting  True=locked

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    /* This generates a public event on the blockchain that will notify clients */
    //event Transfer(address indexed from, address indexed to, uint256 beforesender, uint256 beforereceiver, uint256 value, uint256 time);

    uint256 public transferCount = 0;


    struct pasttransfer {
      address  from;
      address  to;
      uint256 beforesender;
      uint256 beforereceiver;
      uint256 value;
      uint256 time;
    }

    pasttransfer[] transfers;

    modifier onlyCorp() {
        require(msg.sender == corporationContract);
        _;
    }
    // Sender: Corporation  --->
    function ShareToken() {

    }

    function init(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol, address _owner) {
      corporationContract = msg.sender;
      balanceOf[_owner] = initialSupply;                     // Give the creator all initial tokens
      identityApproved[_owner] = true;
      totalSupply = initialSupply;                        // Update total supply
      allowance[_owner][corporationContract] = (totalSupply - 1);   // Allow corporation to sell shares to new members if approved
      name = tokenName;                                   // Set the name for display purposes
      symbol = tokenSymbol;                               // Set the symbol for display purposes
      decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    function approveMember(address _newMember) public  returns (bool) {
        identityApproved[_newMember] = true;
        return true;
    }

    function Transfer(address from, address to, uint256 beforesender, uint256 beforereceiver, uint256 value, uint256 time) {
      transferCount++;
      pasttransfer memory t;
      t.from = from;
      t.to = to;
      t.beforesender = beforesender;
      t.beforereceiver = beforereceiver;
      t.value = value;
      t.time = time;
      transfers.push(t);
    }

    // /* Send coins */
    //  must have identityApproved + can't sell last token using transfer
    function transfer(address _to, uint256 _value) public {
        if (balanceOf[msg.sender] < (_value + 1)) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows
        require(identityApproved[_to]);
        uint256 receiver = balanceOf[_to];
        uint256 sender = balanceOf[msg.sender];
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, sender, receiver, _value, now);                   // Notify anyone listening that this transfer took place
    }
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    /* Approve and then comunicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balanceOf[_from] < (_value + 1)) revert();                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert();   // Check allowance
        require(identityApproved[_to]);
        uint256 receiver = balanceOf[_to];
        uint256 sender = balanceOf[_from];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to,sender, receiver, _value, now);
        return true;
    }
    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        revert();     // Prevents accidental sending of ether
    }

    function isApproved(address _user) constant returns (bool) {
        return identityApproved[_user];
    }

    function getTransferCount() public view returns (uint256 count) {
      return transferCount;
    }

    function getTransfer(uint256 i) public view returns (address from, address to, uint256 beforesender, uint256 beforereceiver, uint256 value, uint256 time) {
      pasttransfer memory t = transfers[i];
      return (t.from, t.to, t.beforesender, t.beforereceiver, t.value, t.time);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function getBalance(address _owner) public view returns (uint256 balance) {
      return balanceOf[_owner];
    }
}