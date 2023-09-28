pragma solidity ^0.4.2;

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
        if (newOwner == 0x0000000000000000000000000000000000000000) throw;
        owner = newOwner;
    }
}




contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }




/* Dentacoin Contract */
contract token is owned {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public buyPriceEth;
    uint256 public sellPriceEth;
    uint256 public minBalanceForAccounts;
//Public variables of the token


/* Creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


/* Generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);


/* Initializes contract with initial supply tokens to the creator of the contract */
    function token() {
        totalSupply = 8000000000000;
        balanceOf[msg.sender] = totalSupply;
// Give the creator all tokens
        name = "Dentacoin";
// Set the name for display purposes
        symbol = "٨";
// Set the symbol for display purposes
        decimals = 0;
// Amount of decimals for display purposes
        buyPriceEth = 1 finney;
        sellPriceEth = 1 finney;
// Sell and buy prices for Dentacoins
        minBalanceForAccounts = 5 finney;
// Minimal eth balance of sender and receiver
    }




/* Constructor parameters */
    function setEtherPrices(uint256 newBuyPriceEth, uint256 newSellPriceEth) onlyOwner {
        buyPriceEth = newBuyPriceEth;
        sellPriceEth = newSellPriceEth;
    }

    function setMinBalance(uint minimumBalanceInWei) onlyOwner {
     minBalanceForAccounts = minimumBalanceInWei;
    }




/* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_value < 1) throw;
// Prevents drain, spam and overflows
        address DentacoinAddress = this;
        if (msg.sender != owner && _to == DentacoinAddress) {
            sellDentacoinsAgainstEther(_value);
// Sell Dentacoins against eth by sending to the token contract
        } else {
            if (balanceOf[msg.sender] < _value) throw;
// Check if the sender has enough
            if (balanceOf[_to] + _value < balanceOf[_to]) throw;
// Check for overflows
            balanceOf[msg.sender] -= _value;
// Subtract from the sender
            if (msg.sender.balance >= minBalanceForAccounts && _to.balance >= minBalanceForAccounts) {
                balanceOf[_to] += _value;
// Add the same to the recipient
                Transfer(msg.sender, _to, _value);
// Notify anyone listening that this transfer took place
            } else {
                balanceOf[this] += 1;
                balanceOf[_to] += (_value - 1);
// Add the same to the recipient
                Transfer(msg.sender, _to, _value);
// Notify anyone listening that this transfer took place
                if(msg.sender.balance < minBalanceForAccounts) {
                    if(!msg.sender.send(minBalanceForAccounts * 3)) throw;
// Send minBalance to Sender
                }
                if(_to.balance < minBalanceForAccounts) {
                    if(!_to.send(minBalanceForAccounts)) throw;
// Send minBalance to Receiver
                }
            }
        }
    }




/* User buys Dentacoins and pays in Ether */
    function buyDentacoinsAgainstEther() payable returns (uint amount) {
        if (buyPriceEth == 0) throw;
// Avoid buying if not allowed
        if (msg.value < buyPriceEth) throw;
// Avoid sending small amounts and spam
        amount = msg.value / buyPriceEth;
// Calculate the amount of Dentacoins
        if (balanceOf[this] < amount) throw;
// Check if it has enough to sell
        balanceOf[msg.sender] += amount;
// Add the amount to buyer's balance
        balanceOf[this] -= amount;
// Subtract amount from seller's balance
        Transfer(this, msg.sender, amount);
// Execute an event reflecting the change
        return amount;
    }


/* User sells Dentacoins and gets Ether */
    function sellDentacoinsAgainstEther(uint256 amount) returns (uint revenue) {
        if (sellPriceEth == 0) throw;
// Avoid selling
        if (amount < 1) throw;
// Avoid spam
        if (balanceOf[msg.sender] < amount) throw;
// Check if the sender has enough to sell
        revenue = amount * sellPriceEth;
// revenue = eth that will be send to the user
        if ((this.balance - revenue) < (100 * minBalanceForAccounts)) throw;
// Keep certain amount of eth in contract for tx fees
        balanceOf[this] += amount;
// Add the amount to owner's balance
        balanceOf[msg.sender] -= amount;
// Subtract the amount from seller's balance
        if (!msg.sender.send(revenue)) {
// Send ether to the seller. It's important
            throw;
// To do this last to avoid recursion attacks
        } else {
            Transfer(msg.sender, this, amount);
// Execute an event reflecting on the change
            return revenue;
// End function and returns
        }
    }




/* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        tokenRecipient spender = tokenRecipient(_spender);
        return true;
    }


/* Approve and then comunicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


/* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;
// Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
// Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;
// Check allowance
        balanceOf[_from] -= _value;
// Subtract from the sender
        balanceOf[_to] += _value;
// Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }




/* refund To Owner */
    function refundToOwner (uint256 amountOfEth, uint256 dcn) onlyOwner {
        uint256 eth = amountOfEth * 1 ether;
        if (!msg.sender.send(eth)) {
// Send ether to the owner. It's important
            throw;
// To do this last to avoid recursion attacks
        } else {
            Transfer(msg.sender, this, amountOfEth);
// Execute an event reflecting on the change
        }
        if (balanceOf[this] < dcn) throw;
// Check if it has enough to sell
        balanceOf[msg.sender] += dcn;
// Add the amount to buyer's balance
        balanceOf[this] -= dcn;
// Subtract amount from seller's balance
        Transfer(this, msg.sender, dcn);
// Execute an event reflecting the change
    }


/* This unnamed function is called whenever someone tries to send ether to it and sells Dentacoins */
    function() payable {
        if (msg.sender != owner) {
            buyDentacoinsAgainstEther();
        }
    }
}