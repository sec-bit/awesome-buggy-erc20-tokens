pragma solidity ^0.4.11;

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

contract IERC20 {

    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public;
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public;
    function allowance(address owner, address spender) public constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract BriskCoin is IERC20 {

    using SafeMath for uint256;

    // Token properties
    string public name = "BriskCoin";
    string public symbol = "BSK";
    uint public decimals = 18;

    uint public _totalSupply = 100000000000e18;

    uint public _icoSupply = 70000000000e18; // crowdsale

    uint public _futureSupply = 30000000000e18; // futureUse

    // Balances for each account
    mapping (address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping (address => mapping(address => uint256)) allowed;

    uint256 public startTime;

    // Owner of Token
    address public owner;

    // how many token units a buyer gets per wei
    uint public PRICE = 400000;

    uint public maxCap = 70000000000e18 ether; // 50000 ether

    // amount of raised money in wei
    uint256 public fundRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // modifier to allow only owner has full control on the function
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Constructor
    // @notice BSK Token Contract
    // @return the transaction address
    function BriskCoin() public payable {
        startTime = now;
        owner = msg.sender;

        balances[owner] = _totalSupply; 
    }

    // Payable method
    // @notice Anyone can buy the tokens on tokensale by paying ether
    function () public payable {
        tokensale(msg.sender);
    }

    // @notice tokensale
    // @param recipient The address of the recipient
    // @return the transaction address and send the event as Transfer
    function tokensale(address recipient) public payable {
        require(recipient != 0x0);

        uint256 weiAmount = msg.value;
        uint tokens = weiAmount.mul(getPrice());

        require(_icoSupply >= tokens);

        balances[owner] = balances[owner].sub(tokens);
        balances[recipient] = balances[recipient].add(tokens);

        _icoSupply = _icoSupply.sub(tokens);

        TokenPurchase(msg.sender, recipient, weiAmount, tokens);
		if ( tokens == 0 ) {
		recipient.transfer(msg.value);
		} else {
		owner.transfer(msg.value);
}    }

    // @return total tokens supplied
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    // What is the balance of a particular account?
    // @param who The address of the particular account
    // @return the balanace the particular account
    function balanceOf(address who) public constant returns (uint256) {
        return balances[who];
    }

    // Token distribution to founder, develoment team, partners, charity, and bounty
    function sendFutureSupplyToken(address to, uint256 value) public onlyOwner {
        require (
            to != 0x0 && value > 0 && _futureSupply >= value
        );

        balances[owner] = balances[owner].sub(value);
        balances[to] = balances[to].add(value);
        _futureSupply = _futureSupply.sub(value);
        Transfer(owner, to, value);
    }

    // @notice send `value` token to `to` from `msg.sender`
    // @param to The address of the recipient
    // @param value The amount of token to be transferred
    // @return the transaction address and send the event as Transfer
    function transfer(address to, uint256 value) public {
        require (
            balances[msg.sender] >= value && value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
    }

    // @notice send `value` token to `to` from `from`
    // @param from The address of the sender
    // @param to The address of the recipient
    // @param value The amount of token to be transferred
    // @return the transaction address and send the event as Transfer
    function transferFrom(address from, address to, uint256 value) public {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
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
            balances[msg.sender] >= value && value > 0
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

    // Get current price of a Token
    // @return the price or token value for a ether
    function getPrice() public constant returns (uint result) {
        if ( now >= startTime  && now <= startTime + 6 days) {
    	    return PRICE.mul(2);
    	} else if ( now >= startTime + 16 days  && now <= startTime + 31 days) {
    	    return PRICE.mul(35).div(20);
    	} else if ( now >= startTime + 41 days  && now <= startTime + 51 days) {
    	    return PRICE.mul(5).div(4);
    	} else if ( now >= startTime + 61 days && now <= startTime + 66 days) {
    	    return PRICE;
    	} else {
    	    return 0;
    	}
    }

}