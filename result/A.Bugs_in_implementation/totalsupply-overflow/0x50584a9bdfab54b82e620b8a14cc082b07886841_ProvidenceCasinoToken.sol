pragma solidity ^0.4.17;
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
    /* Public variables of the token */
    string public standard = "PVE 1.0";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /*************************************************/
    mapping(address=>uint256) public indexes;
    mapping(uint256=>address) public addresses;
    uint256 public lastIndex = 0;
    /*************************************************/

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
        /*****************************************/
        addresses[1] = msg.sender;
        indexes[msg.sender] = 1;
        lastIndex = 1;
        /*****************************************/
    }

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

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts _ to get the coins */
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
}

contract ProvidenceCasinoToken is owned, token {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping(address=>bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    uint256 public constant initialSupply = 200000000 * 10**18;
    uint8 public constant decimalUnits = 18;
    string public tokenName = "Providence Crypto Casino";
    string public tokenSymbol = "PVE";
    function ProvidenceCasinoToken() token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}
     /* Send coins */
    function transfer(address _to, uint256 _value) {
        if(!canHolderTransfer()) throw;
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        if (frozenAccount[msg.sender]) throw;                // Check if frozen
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        if(_value > 0){
            if(balanceOf[msg.sender] == 0){
                addresses[indexes[msg.sender]] = addresses[lastIndex];
                indexes[addresses[lastIndex]] = indexes[msg.sender];
                indexes[msg.sender] = 0;
                delete addresses[lastIndex];
                lastIndex--;
            }
            if(indexes[_to]==0){
                lastIndex++;
                addresses[lastIndex] = _to;
                indexes[_to] = lastIndex;
            }
        }
    }

    function getAddresses() constant returns (address[]){
        address[] memory addrs = new address[](lastIndex);
        for(uint i = 0; i < lastIndex; i++){
            addrs[i] = addresses[i+1];
        }
        return addrs;
    }

    function distributeTokens(uint _amount) onlyOwner returns (uint) {
        if(balanceOf[owner] < _amount) throw;
        uint distributed = 0;

        for(uint i = 0; i < lastIndex; i++){
            address holder = addresses[i+1];
            uint reward = (_amount * balanceOf[holder] / totalSupply);
            balanceOf[holder] += reward;
            distributed += reward;
            Transfer(owner, holder, reward);
        }

        balanceOf[owner] -= distributed;
        return distributed;
    }

    /************************************************************************/
    bool public locked = true;
    address public icoAddress;
    function unlockTransfer() onlyOwner {
        locked = false;
    }

    function lockTransfer() onlyOwner {
        locked = true;
    }

    function canHolderTransfer() constant returns (bool){
        return !locked || msg.sender == owner || msg.sender == icoAddress;
    }
    function setIcoAddress(address _icoAddress) onlyOwner {
        icoAddress = _icoAddress;
    }

    /************************************************************************/

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                        // Check if frozen
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }


    function freeze(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable {
        uint amount = msg.value / buyPrice;                // calculates the amount
        if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                   // adds the amount to buyer's balance
        balanceOf[this] -= amount;                         // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);                // execute an event reflecting the change
    }

    function sell(uint256 amount) {
        if (balanceOf[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
        balanceOf[this] += amount;                         // adds the amount to owner's balance
        balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller's balance
        if (!msg.sender.send(amount * sellPrice)) {        // sends ether to the seller. It's important
            throw;                                         // to do this last to avoid recursion attacks
        } else {
            Transfer(msg.sender, this, amount);            // executes an event reflecting on the change
        }
    }
}