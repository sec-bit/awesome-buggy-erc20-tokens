pragma solidity ^0.4.8;

/// @title ERC20 Token
/// @author Melonport AG <team@melonport.com>
/// @notice Original taken from https://github.com/ethereum/EIPs/issues/20
/// @notice Checked against integer overflow
contract ERC20 {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

    address public owner;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyowner(address _requester) {
        if (_requester != owner) {
            throw;
        }
        _;
    }

    event Mint(address indexed _owner, uint256 _value, uint256 _totalSupply);
    event Burn(address indexed _owner, uint256 _value, uint256 _totalSupply);
    event ChangeOwner(address indexed _oldOwner, address indexed _newOwner);

    function ERC20() {
        owner = msg.sender;
    }

    function mint(uint _value) onlyowner(msg.sender) {
        if (balances[owner] + _value < balances[owner]) {
            // overflow
            throw;
        }
        balances[owner] += _value;
        totalSupply += _value;
        Mint(owner, _value, totalSupply);
    }

    function burn(uint _value) onlyowner(msg.sender) {
        if (balances[owner] < _value) {
            throw;
        }
        balances[owner] -= _value;
        totalSupply -= _value;
        Burn(owner, _value, totalSupply);
    }

    function changeOwner(address _owner) onlyowner(msg.sender) {
        owner = _owner;
        ChangeOwner(msg.sender, owner);
    }

}