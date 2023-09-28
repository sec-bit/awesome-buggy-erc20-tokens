pragma solidity ^0.4.11;

contract TDT {
    address public owner;
    uint public supply = 10000000000000000000000000;
    string public name = 'TDT';
    string public symbol = 'TDT';
    uint8 public decimals = 18;
    uint public price = 1 finney;
    uint public durationInBlocks = 157553; // 1 month
    uint public amountRaised;
    uint public deadline;
    uint public tokensSold;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    
    mapping (address => mapping (address => uint256)) public allowance;
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    function isOwner() returns (bool isOwner) {
        return msg.sender == owner;
    }
    
    function addressIsOwner(address addr)  returns (bool isOwner) {
        return addr == owner;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function TDT() {
        owner = msg.sender;
        balanceOf[msg.sender] = supply;
        deadline = block.number + durationInBlocks;
    }
    
    function isCrowdsale() returns (bool isCrowdsale) {
        return block.number < deadline;
    }
    
    /* Internal transfer, only can be called by this contract */
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
    
    /* Send coins */
    function transfer(address _to, uint256 _value) {
        _transfer(msg.sender, _to, _value);
    }
    
    /* Transfer tokens from other address */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    /* Set allowance for other address */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function () payable {
        if (isOwner()) {
            owner.transfer(amountRaised);
            FundTransfer(owner, amountRaised, false);
            amountRaised = 0;
        } else if (isCrowdsale()) {
            uint amount = msg.value;
            if (amount == 0) revert();
            
            uint tokensCount = amount * 1000000000000000000 / price;
            if (tokensCount < 1000000000000000000) revert();
            
            balanceOf[msg.sender] += tokensCount;
            supply += tokensCount;
            tokensSold += tokensCount;
            Transfer(0, this, tokensCount);
            Transfer(this, msg.sender, tokensCount);
            amountRaised += amount;
        } else {
            revert();
        }
    }
}