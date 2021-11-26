pragma solidity ^0.4.2;
/**
 * @title Contract for object that have an owner
 */
contract Owned {
    /**
     * Contract owner address
     */
    address public owner;

    /**
     * @dev Store owner on creation
     */
    function Owned() { owner = msg.sender; }

    /**
     * @dev Delegate contract to another person
     * @param _owner is another person address
     */
    function delegate(address _owner) onlyOwner
    { owner = _owner; }

    /**
     * @dev Owner check modifier
     */
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}
/**
 * @title Token contract represents any asset in digital economy
 */
contract Token is Owned {
    event Transfer(address indexed _from,  address indexed _to,      uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /* Short description of token */
    string public name;
    string public symbol;

    /* Total count of tokens exist */
    uint public totalSupply;

    /* Fixed point position */
    uint8 public decimals;
    
    /* Token approvement system */
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
 
    /**
     * @return available balance of `sender` account (self balance)
     */
    function getBalance() constant returns (uint)
    { return balanceOf[msg.sender]; }
 
    /**
     * @dev This method returns non zero result when sender is approved by
     *      argument address and target address have non zero self balance
     * @param _address target address 
     * @return available for `sender` balance of given address
     */
    function getBalance(address _address) constant returns (uint) {
        return allowance[_address][msg.sender]
             > balanceOf[_address] ? balanceOf[_address]
                                   : allowance[_address][msg.sender];
    }
 
    /* Token constructor */
    function Token(string _name, string _symbol, uint8 _decimals, uint _count) {
        name     = _name;
        symbol   = _symbol;
        decimals = _decimals;
        totalSupply           = _count;
        balanceOf[msg.sender] = _count;
    }
 
    /**
     * @dev Transfer self tokens to given address
     * @param _to destination address
     * @param _value amount of token values to send
     * @notice `_value` tokens will be sended to `_to`
     * @return `true` when transfer done
     */
    function transfer(address _to, uint _value) returns (bool) {
        if (balanceOf[msg.sender] >= _value) {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to]        += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    /**
     * @dev Transfer with approvement mechainsm
     * @param _from source address, `_value` tokens shold be approved for `sender`
     * @param _to destination address
     * @param _value amount of token values to send 
     * @notice from `_from` will be sended `_value` tokens to `_to`
     * @return `true` when transfer is done
     */
    function transferFrom(address _from, address _to, uint _value) returns (bool) {
        var avail = allowance[_from][msg.sender]
                  > balanceOf[_from] ? balanceOf[_from]
                                     : allowance[_from][msg.sender];
        if (avail >= _value) {
            allowance[_from][msg.sender] -= _value;
            balanceOf[_from] -= _value;
            balanceOf[_to]   += _value;
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    /**
     * @dev Give to target address ability for self token manipulation without sending
     * @param _address target address
     * @param _value amount of token values for approving
     */
    function approve(address _address, uint _value) {
        allowance[msg.sender][_address] += _value;
        Approval(msg.sender, _address, _value);
    }

    /**
     * @dev Reset count of tokens approved for given address
     * @param _address target address
     */
    function unapprove(address _address)
    { allowance[msg.sender][_address] = 0; }
}
/**
 * @title Ethereum crypto currency extention for Token contract
 */
contract TokenEther is Token {
    function TokenEther(string _name, string _symbol)
             Token(_name, _symbol, 18, 0)
    {}

    /**
     * @dev This is the way to withdraw money from token
     * @param _value how many tokens withdraw from balance
     */
    function withdraw(uint _value) {
        if (balanceOf[msg.sender] >= _value) {
            balanceOf[msg.sender] -= _value;
            totalSupply           -= _value;
            if(!msg.sender.send(_value)) throw;
        }
    }

    /**
     * @dev This is the way to refill your token balance by ethers
     */
    function refill() payable returns (bool) {
        balanceOf[msg.sender] += msg.value;
        totalSupply           += msg.value;
        return true;
    }

    /**
     * @dev This method is called when money sended to contract address,
     *      a synonym for refill()
     */
    function () payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply           += msg.value;
    }
}
contract AiraEtherFunds is TokenEther {
    function AiraEtherFunds(string _name, string _symbol) TokenEther(_name, _symbol) {}

    /**
     * @dev Event spawned when activation request received
     */
    event ActivationRequest(address indexed sender, bytes32 indexed code);

    /**
     * @dev String to bytes32 conversion helper
     */
    function stringToBytes32(string memory source) constant returns (bytes32 result)
    { assembly { result := mload(add(source, 32)) } }

    // Balance limit
    uint public limit;
    
    function setLimit(uint _limit) onlyOwner
    { limit = _limit; }

    // Account activation fee
    uint public fee;
    
    function setFee(uint _fee) onlyOwner
    { fee = _fee; }

    // AiraEtherBot
    address public bot;

    function setBot(address _bot) onlyOwner
    { bot = _bot; }

    modifier onlyBot { if (msg.sender != bot) throw; _; }

    /**
     * @dev Refill balance and activate it by code
     * @param _code is activation code
     */
    function activate(string _code) payable {
        var value = msg.value;
 
        // Get a fee
        if (fee > 0) {
            if (value < fee) throw;
            balanceOf[owner] += fee;
            value            -= fee;
        }

        // Refund over limit
        if (limit > 0 && value > limit) {
            var refund = value - limit;
            if (!msg.sender.send(refund)) throw;
            value = limit;
        }

        // Refill account balance
        balanceOf[msg.sender] += value;
        totalSupply           += value;

        // Activation event
        ActivationRequest(msg.sender, stringToBytes32(_code));
    }

    /**
     * @dev This is the way to refill your token balance by ethers
     */
    function refill() payable returns (bool) {
        // Throw when over limit
        if (balanceOf[msg.sender] + msg.value > limit) throw;

        // Refill
        balanceOf[msg.sender] += msg.value;
        totalSupply           += msg.value;
        return true;
    }

    /**
     * @dev This method is called when money sended to contract address,
     *      a synonym for refill()
     */
    function () payable {
        // Throw when over limit
        if (balanceOf[msg.sender] + msg.value > limit) throw;

        // Refill
        balanceOf[msg.sender] += msg.value;
        totalSupply           += msg.value;
    }

    /**
     * @dev Internal transfer for AIRA
     * @param _from source address
     * @param _to destination address
     * @param _value amount of token values to send 
     */
    function airaTransfer(address _from, address _to, uint _value) onlyBot {
        if (balanceOf[_from] >= _value) {
            balanceOf[_from] -= _value;
            balanceOf[_to]   += _value;
            Transfer(_from, _to, _value);
        }
    }

    /**
     * @dev Outgoing transfer for AIRA
     * @param _from source address
     * @param _to destination address
     * @param _value amount of token values to send 
     */
    function airaSend(address _from, address _to, uint _value) onlyBot {
        if (balanceOf[_from] >= _value) {
            balanceOf[_from] -= _value;
            totalSupply      -= _value;
            Transfer(_from, _to, _value);
            if (!_to.send(_value)) throw;
        }
    }
}