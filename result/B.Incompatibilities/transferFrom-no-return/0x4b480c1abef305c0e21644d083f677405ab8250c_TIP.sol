pragma solidity ^0.4.17;

// StandardToken code from LINK token contract.

/**
 * ERC20Basic
 * Simpler version of ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public totalSupply;

    function balanceOf(address who) constant returns(uint);

    function transfer(address to, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * Math operations with safety checks
 */
library SafeMath {
    function mul(uint a, uint b) internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns(uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns(uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns(uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns(uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns(uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns(uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }
}


/**
 * Basic token
 * Basic version of StandardToken, with no allowances
 */
contract BasicToken is ERC20Basic {
    using SafeMath
    for uint;

    mapping(address => uint) balances;

    /**
     * Fix for the ERC20 short address attack  
     */
    modifier onlyPayloadSize(uint size) {
        if (msg.data.length < size + 4) {
            throw;
        }
        _;
    }

    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner) constant returns(uint balance) {
        return balances[_owner];
    }

}


/**
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns(uint);

    function transferFrom(address from, address to, uint value);

    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

    mapping(address => mapping(address => uint)) allowed;

    function transferFrom(address _from, address _to, uint _value) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) constant returns(uint remaining) {
        return allowed[_owner][_spender];
    }
}

contract TIP is StandardToken {
    string public constant symbol = "TIP";
    string public constant name = "EthereumTipToken";
    uint8 public constant decimals = 8;

    uint256 public reservedSupply = 10000000 * 10 ** 8;
    uint256 public transferAmount = 10000 * 10 ** 8;

    address public owner;

    mapping(address => uint256) address_claimed_tokens;

    function TIP() {
        owner = msg.sender;
        totalSupply = 100000000 * 10 ** 8; //100M
        balances[owner] = 100000000 * 10 ** 8;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Default function called when ETH is send to the contract.
    function() payable {
        // No ETH transfer allowed.
        require(msg.value == 0);

        require(balances[owner] >= reservedSupply);

        require(address_claimed_tokens[msg.sender] == 0); // return if already claimed

        balances[owner] -= transferAmount;
        balances[msg.sender] += transferAmount;
        address_claimed_tokens[msg.sender] += transferAmount;
        Transfer(owner, msg.sender, transferAmount);
    }

    function distribute(address[] addresses) onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            if (address_claimed_tokens[addresses[i]] == 0) {
                balances[owner] -= transferAmount;
                balances[addresses[i]] += transferAmount;
                address_claimed_tokens[addresses[i]] += transferAmount;
                Transfer(owner, addresses[i], transferAmount);
            }
        }
    }

}