pragma solidity ^0.4.18;



interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract Lottery {
    // Public variables of the token
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    uint256 public totalSupply;


    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Tickets(address indexed from, uint tickets);
    event SelectWinner50(address indexed winner50);
    event SelectWinner20(address indexed winner20);
    event SelectWinner30(address indexed winner30);
    event FullPool(uint amount);
    

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function Lottery(
    uint256 initialSupply,
    string tokenName,
    string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        owner = msg.sender;
    }


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);

    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferToWinner(address _to, uint256 _value) internal {
        _transfer(this, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }



    address[] pust;
    address[] internal  pool;
    uint internal ticketPrice;
    uint internal seed;
    uint internal stopFlag;
    uint internal total;
    uint internal ticketMax;
    
    
    function setTicketMax (uint amount) public onlyOwner {
        ticketMax = amount;
    }


    function setTicketPrice (uint amount) public onlyOwner {
        ticketPrice = amount;
    }
    
    
    
    function getPoolSize() public constant returns (uint amount) {
        amount = pool.length;
        return amount;
    }
    
    

    function takeAndPush(uint ticketsAmount) internal {
        transfer(this, ticketPrice * ticketsAmount);
        uint i = 0;
        while(i < ticketsAmount) {
            pool.push(msg.sender);
            i++;
        }


    }

    function random50(uint upper) internal returns (uint) {
        seed = uint(keccak256(keccak256(pool[pool.length -1], seed), now));
        return seed % upper;
    }

    function random30(uint upper) internal returns (uint) {
        seed = uint(keccak256(keccak256(pool[pool.length -2], seed), now));
        return seed % upper;
    }

    function random20(uint upper) internal returns (uint) {
        seed = uint(keccak256(keccak256(pool[pool.length -3], seed), now));
        return seed % upper;
    }

    function selectWinner50() public onlyOwner  {
        total = balanceOf[this];
        address winner50 = pool[random50(pool.length)];
        transferToWinner(winner50, (total / 2));
        SelectWinner50(winner50);
    }
    
    
   
        function selectWinner20() public onlyOwner  {
        address winner20 = pool[random20(pool.length)];
        transferToWinner(winner20, (total / 5));
        SelectWinner20(winner20);
    }
    
    
    
        function selectWinner30() public onlyOwner  {
        address winner30 = pool[random30(pool.length)];
        transferToWinner(winner30, (total) - (total / 2) - (total / 5));
        pool = pust;
        SelectWinner30(winner30);
    }
    
    
    function buyTickets(uint ticketsAmount) public  {
        require(balanceOf[msg.sender] >= ticketPrice * ticketsAmount);
        require(balanceOf[this] + (ticketPrice * ticketsAmount) >= balanceOf[this]);
        require(stopFlag != 1);
        require((ticketsAmount + pool.length) <= ticketMax);

        takeAndPush(ticketsAmount);
        
        if((pool.length + ticketsAmount) >= ticketMax) {
            FullPool(ticketMax);
        }

        Tickets(msg.sender, ticketsAmount);
    }

    function stopFlagOn() public onlyOwner {
        stopFlag = 1;
    }

    function stopFlagOff() public onlyOwner {
        stopFlag = 0;
        total = 0;
    }


}