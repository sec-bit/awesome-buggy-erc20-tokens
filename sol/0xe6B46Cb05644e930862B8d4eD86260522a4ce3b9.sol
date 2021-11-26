pragma solidity 0.4.19;


contract Street {

  // Public Variables of the token
    string public constant NAME = "Street Credit";
    string public constant SYMBOL = "STREET";
    uint8 public constant DECIMALS = 18;
    uint public constant TOTAL_SUPPLY = 100000000 * 10**uint(DECIMALS);
    mapping(address => uint) public balances;
    mapping(address => mapping (address => uint256)) internal allowed;
    uint public constant TOKEN_PRICE = 10 szabo;

    //Private variables
    address private constant BENEFICIARY = 0xff1A7c1037CDb35CD55E4Fe5B73a26F9C673c2bc;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Purchase(address indexed purchaser, uint tokensBought, uint amountContributed);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function Street() public {

        balances[BENEFICIARY] = TOTAL_SUPPLY; // All tokens initially belong to me until they are purchased
        Transfer(address(0), BENEFICIARY, TOTAL_SUPPLY);
    }

    // Any transaction sent to the contract will trigger this anonymous function
    // All ether will be sent to the purchase function
    function () public payable {
        purchaseTokens(msg.sender);
    }

    function name() public pure returns (string) {
        return NAME;
    }

    function symbol() public pure returns (string) {
        return SYMBOL;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(balances[msg.sender] + _value >= balances[msg.sender]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // Purchase tokens from my reserve
    function purchaseTokens(address _buyer) public payable returns (bool) {
        require(_buyer != address(0));
        require(balances[BENEFICIARY] > 0);
        require(msg.value != 0);

        uint amount = msg.value / TOKEN_PRICE;
        BENEFICIARY.transfer(msg.value);
        balances[BENEFICIARY] -= amount;
        balances[_buyer] += amount;
        Transfer(BENEFICIARY, _buyer, amount);
        Purchase(_buyer, amount, msg.value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    // ERC-20 Approval functions
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] += _addedValue;
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}