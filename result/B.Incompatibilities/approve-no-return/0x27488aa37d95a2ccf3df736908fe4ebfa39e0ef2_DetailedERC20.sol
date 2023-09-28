pragma solidity ^0.4.15;

contract ERC20 {
    function totalSupply() external constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) external constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _old, uint256 _new) external returns (bool success);
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function ERC20() internal {
    }
}

library SafeMath {
    uint256 constant private    MAX_UINT256     = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd (uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert (x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub (uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert (x >= y);
        return x - y;
    }

    function safeMul (uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        assert(x == 0 || z / x == y);
    }

    function safeDiv (uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
        return z;
    }
}

contract DetailedERC20 is ERC20 {

    using SafeMath for uint256;

    address public              owner;

    string  public              name;
    string  public              symbol;
    uint8   public              decimals;
    string  public              description;
    uint256 private             summarySupply;

    mapping(address => uint256)                      private   accounts;
    mapping(address => mapping (address => uint256)) private   allowed;

    function DetailedERC20(string _name, string _symbol,string _description, uint8 _decimals, uint256 _startTokens) public {
        owner = msg.sender;

        accounts[owner]  = _startTokens;
        summarySupply    = _startTokens;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        description = _description;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(64) external returns (bool success) {
        if (accounts[msg.sender] >= _value) {
            accounts[msg.sender] = accounts[msg.sender].safeSub(_value);
            accounts[_to] = accounts[_to].safeAdd(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(64) external returns (bool success) {
        if ((accounts[_from] >= _value) && (allowed[_from][msg.sender] >= _value)) {
            accounts[_from] = accounts[_from].safeSub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].safeSub(_value);
            accounts[_to] = accounts[_to].safeAdd(_value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _old, uint256 _new) onlyPayloadSize(64) external returns (bool success) {
        if (_old == allowed[msg.sender][_spender]) {
            allowed[msg.sender][_spender] = _new;
            Approval(msg.sender, _spender, _new);
            return true;
        } else {
            return false;
        }
    }

    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) external constant returns (uint256 balance) {
        if (_owner == 0x00)
            return accounts[msg.sender];
        return accounts[_owner];
    }

    function totalSupply() external constant returns (uint256 _totalSupply) {
        _totalSupply = summarySupply;
    }
}