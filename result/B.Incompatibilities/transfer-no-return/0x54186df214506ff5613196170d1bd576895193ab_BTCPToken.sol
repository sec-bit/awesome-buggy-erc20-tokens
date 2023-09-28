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

contract BTCPToken is IERC20 {

    using SafeMath for uint256;

    // Token properties
    string public name = "BitcoinPeso";
    string public symbol = "BTCP";
    uint public decimals = 18;

    uint public _totalSupply = 21000000e18;
    uint public _leftSupply = 21000000e18;

    // Balances for each account
    mapping (address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping (address => mapping(address => uint256)) allowed;

    uint256 public startTime;

    // Owner of Token
    address public owner;

    // how many token units a buyer gets per wei
    uint public PRICE = 1000;

    // amount of raised money in wei

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // modifier to allow only owner has full control on the function
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Constructor
    // @notice BTCPToken Contract
    // @return the transaction address
    function BTCPToken() public payable {
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

        require(_leftSupply >= tokens);

        balances[owner] = balances[owner].sub(tokens);
        balances[recipient] = balances[recipient].add(tokens);

        _leftSupply = _leftSupply.sub(tokens);

        TokenPurchase(msg.sender, recipient, weiAmount, tokens);
    }

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
    function sendBTCPToken(address to, uint256 value) public onlyOwner {
        require (
            to != 0x0 && value > 0 && _leftSupply >= value
        );

        balances[owner] = balances[owner].sub(value);
        balances[to] = balances[to].add(value);
        _leftSupply = _leftSupply.sub(value);
        Transfer(owner, to, value);
    }

    function sendBTCPTokenToMultiAddr(address[] listAddresses, uint256[] amount) onlyOwner {
        require(listAddresses.length == amount.length); 
         for (uint256 i = 0; i < listAddresses.length; i++) {
                require(listAddresses[i] != 0x0); 
                balances[listAddresses[i]] = balances[listAddresses[i]].add(amount[i]);
                balances[owner] = balances[owner].sub(amount[i]);
                Transfer(owner, listAddresses[i], amount[i]);
                _leftSupply = _leftSupply.sub(amount[i]);
         }
    }

    function destroyBTCPToken(address to, uint256 value) public onlyOwner {
        require (
                to != 0x0 && value > 0 && _totalSupply >= value
            );
        balances[to] = balances[to].sub(value);
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
        return PRICE;
    }

    function getTokenDetail() public constant returns (string, string, uint256) {
	return (name, symbol, _totalSupply);
    }
}