pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract SafeERC20 {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances    
    mapping (address => uint256) public balanceOf;
    // Owner of account approves the transfer of an amount to another account
    mapping (address => mapping(address => uint256)) allowed;
    

    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }
    
    
        // @notice send `value` token to `to` from `msg.sender`
    // @param to The address of the recipient
    // @param value The amount of token to be transferred
    // @return the transaction address and send the event as Transfer
    function transfer(address to, uint256 value) public {
        require (
            balanceOf[msg.sender] >= value && value > 0
        );
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        Transfer(msg.sender, to, value);
    }

    // @notice send `value` token to `to` from `from`
    // @param from The address of the sender
    // @param to The address of the recipient
    // @param value The amount of token to be transferred
    // @return the transaction address and send the event as Transfer
    function transferFrom(address from, address to, uint256 value) public {
        require (
            allowed[from][msg.sender] >= value && balanceOf[from] >= value && value > 0
        );
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
    }

    // Allow spender to withdraw from your account, multiple times, up to the value amount.
    // If this function is called again it overwrites the current allowance with value.
    // @param spender The address of the sender
    // @param value The amount to be approved
    // @return the transaction address and send the event as Approval
    function approve(address spender, uint256 value) public {
        require (
            balanceOf[msg.sender] >= value && value > 0
        );
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
    }

    // Check the allowed value for the spender to withdraw from owner
    // @param owner The address of the owner
    // @param spender The address of the spender
    // @return the amount which spender is still allowed to withdraw from owner
    function allowance(address _owner, address spender) public constant returns (uint256) {
        return allowed[_owner][spender];
    }

    // What is the balance of a particular account?
    // @param who The address of the particular account
    // @return the balanace the particular account

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract BITTOToken is SafeERC20, owned {

    using SafeMath for uint256;



    // Token properties
    string public name = "BITTO";
    string public symbol = "BITTO";
    uint256 public decimals = 18;

    uint256 public _totalSupply = 33000000e18;


    

    // how many token units a buyer gets per wei
    uint public price = 800;


    uint256 public fundRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    // Constructor
    // @notice RQXToken Contract
    // @return the transaction address
    function BITTOToken() public {
 
        balanceOf[owner] = _totalSupply;

    }

    function transfertoken (uint256 _amount, address recipient) public onlyOwner {
         require(recipient != 0x0);
         require(balanceOf[owner] >= _amount);
         balanceOf[owner] = balanceOf[owner].sub(_amount);
         balanceOf[recipient] = balanceOf[recipient].add(_amount);

    }
    
    function burn(uint256 _amount) public onlyOwner{
        require(balanceOf[owner] >= _amount);
        balanceOf[owner] -= _amount;
        _totalSupply -= _amount;
    }
    // Payable method
    // @notice Anyone can buy the tokens on tokensale by paying ether
    function () public payable {
        tokensale(msg.sender);
        
    }
    // update price 
    
    function updatePrice (uint _newpice) public onlyOwner {
        price = _newpice;
    }
    // @notice tokensale
    // @param recipient The address of the recipient
    // @return the transaction address and send the event as Transfer
    function tokensale(address recipient) public payable {
        require(recipient != 0x0);


        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(price);

        // update state
        fundRaised = fundRaised.add(weiAmount);

        balanceOf[owner] = balanceOf[owner].sub(tokens);
        balanceOf[recipient] = balanceOf[recipient].add(tokens);



        TokenPurchase(msg.sender, recipient, weiAmount, tokens);
        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        owner.transfer(msg.value);
    }

}