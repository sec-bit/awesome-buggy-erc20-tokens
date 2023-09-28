pragma solidity ^0.4.4;

/**
 * @title Contract for object that have an owner
 */
contract Owned {
    /**
     * Contract owner address
     */
    address public owner;

    /**
     * @dev Delegate contract to another person
     * @param _owner New owner address 
     */
    function setOwner(address _owner) onlyOwner
    { owner = _owner; }

    /**
     * @dev Owner check modifier
     */
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}

/**
 * @title Common pattern for destroyable contracts 
 */
contract Destroyable {
    address public hammer;

    /**
     * @dev Hammer setter
     * @param _hammer New hammer address
     */
    function setHammer(address _hammer) onlyHammer
    { hammer = _hammer; }

    /**
     * @dev Destroy contract and scrub a data
     * @notice Only hammer can call it 
     */
    function destroy() onlyHammer
    { suicide(msg.sender); }

    /**
     * @dev Hammer check modifier
     */
    modifier onlyHammer { if (msg.sender != hammer) throw; _; }
}

/**
 * @title Generic owned destroyable contract
 */
contract Object is Owned, Destroyable {
    function Object() {
        owner  = msg.sender;
        hammer = msg.sender;
    }
}

// Standard token interface (ERC 20)
// https://github.com/ethereum/EIPs/issues/20
contract ERC20 
{
// Functions:
    /// @return total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256);

// Events:
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Asset recipient interface
 */
contract Recipient {
    /**
     * @dev On received ethers
     * @param sender Ether sender
     * @param amount Ether value
     */
    event ReceivedEther(address indexed sender,
                        uint256 indexed amount);

    /**
     * @dev On received custom ERC20 tokens
     * @param from Token sender
     * @param value Token value
     * @param token Token contract address
     * @param extraData Custom additional data
     */
    event ReceivedTokens(address indexed from,
                         uint256 indexed value,
                         address indexed token,
                         bytes extraData);

    /**
     * @dev Receive approved ERC20 tokens
     * @param _from Spender address
     * @param _value Transaction value
     * @param _token ERC20 token contract address
     * @param _extraData Custom additional data
     */
    function receiveApproval(address _from, uint256 _value,
                             ERC20 _token, bytes _extraData) {
        if (!_token.transferFrom(_from, this, _value)) throw;
        ReceivedTokens(_from, _value, _token, _extraData);
    }

    /**
     * @dev Catch sended to contract ethers
     */
    function () payable
    { ReceivedEther(msg.sender, msg.value); }
}


/**
 * @title Token contract represents any asset in digital economy
 */
contract Token is Object, ERC20 {
    /* Short description of token */
    string public name;
    string public symbol;

    /* Total count of tokens exist */
    uint public totalSupply;

    /* Fixed point position */
    uint8 public decimals;
    
    /* Token approvement system */
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
 
    /**
     * @dev Get balance of plain address
     * @param _owner is a target address
     * @return amount of tokens on balance
     */
    function balanceOf(address _owner) constant returns (uint256)
    { return balances[_owner]; }
 
    /**
     * @dev Take allowed tokens
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) constant returns (uint256)
    { return allowances[_owner][_spender]; }

    /* Token constructor */
    function Token(string _name, string _symbol, uint8 _decimals, uint _count) {
        name        = _name;
        symbol      = _symbol;
        decimals    = _decimals;
        totalSupply = _count;
        balances[msg.sender] = _count;
    }
 
    /**
     * @dev Transfer self tokens to given address
     * @param _to destination address
     * @param _value amount of token values to send
     * @notice `_value` tokens will be sended to `_to`
     * @return `true` when transfer done
     */
    function transfer(address _to, uint _value) returns (bool) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to]        += _value;
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
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var avail = allowances[_from][msg.sender]
                  > balances[_from] ? balances[_from]
                                    : allowances[_from][msg.sender];
        if (avail >= _value) {
            allowances[_from][msg.sender] -= _value;
            balances[_from] -= _value;
            balances[_to]   += _value;
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    /**
     * @dev Give to target address ability for self token manipulation without sending
     * @param _spender target address (future requester)
     * @param _value amount of token values for approving
     */
    function approve(address _spender, uint256 _value) returns (bool) {
        allowances[msg.sender][_spender] += _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Reset count of tokens approved for given address
     * @param _spender target address (future requester)
     */
    function unapprove(address _spender)
    { allowances[msg.sender][_spender] = 0; }
}

contract TokenEmission is Token {
    function TokenEmission(string _name, string _symbol, uint8 _decimals,
                           uint _start_count)
             Token(_name, _symbol, _decimals, _start_count)
    {}

    /**
     * @dev Token emission
     * @param _value amount of token values to emit
     * @notice owner balance will be increased by `_value`
     */
    function emission(uint _value) onlyOwner {
        // Overflow check
        if (_value + totalSupply < totalSupply) throw;

        totalSupply     += _value;
        balances[owner] += _value;
    }
 
    /**
     * @dev Burn the token values from sender balance and from total
     * @param _value amount of token values for burn 
     * @notice sender balance will be decreased by `_value`
     */
    function burn(uint _value) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            totalSupply      -= _value;
        }
    }
}

/**
 * @title Crowdfunding contract
 */
contract Crowdfunding is Object, Recipient {
    /**
     * @dev Target fund account address
     */
    address public fund;

    /**
     * @dev Bounty token address
     */
    TokenEmission public bounty;
    
    /**
     * @dev Distribution of donations
     */
    mapping(address => uint256) public donations;

    /**
     * @dev Total funded value
     */
    uint256 public totalFunded;

    /**
     * @dev Documentation reference
     */
    string public reference;

    /**
     * @dev Crowdfunding configuration
     */
    Params public config;

    struct Params {
        /* start/stop block stamps */
        uint256 startBlock;
        uint256 stopBlock;

        /* Minimal/maximal funded value */
        uint256 minValue;
        uint256 maxValue;
        
        /**
         * Bounty ratio equation:
         *   bountyValue = value * ratio / scale
         * where
         *   ratio = R - (block - B) / S * V
         *  R - start bounty ratio
         *  B - start block number
         *  S - bounty reduction step in blocks 
         *  V - bounty reduction value
         */
        uint256 bountyScale;
        uint256 startRatio;
        uint256 reductionStep;
        uint256 reductionValue;
    }

    /**
     * @dev Calculate bounty value by reduction equation
     * @param _value Input donation value
     * @param _block Input block number
     * @return Bounty value
     */
    function bountyValue(uint256 _value, uint256 _block) constant returns (uint256) {
        if (_block < config.startBlock || _block > config.stopBlock)
            return 0;

        var R = config.startRatio;
        var B = config.startBlock;
        var S = config.reductionStep;
        var V = config.reductionValue;
        uint256 ratio = R - (_block - B) / S * V; 
        return _value * ratio / config.bountyScale; 
    }

    /**
     * @dev Crowdfunding running checks
     */
    modifier onlyRunning {
        bool isRunning = totalFunded + msg.value <= config.maxValue
                      && block.number >= config.startBlock
                      && block.number <= config.stopBlock;
        if (!isRunning) throw;
        _;
    }

    /**
     * @dev Crowdfundung failure checks
     */
    modifier onlyFailure {
        bool isFailure = totalFunded  < config.minValue
                      && block.number > config.stopBlock;
        if (!isFailure) throw;
        _;
    }

    /**
     * @dev Crowdfunding success checks
     */
    modifier onlySuccess {
        bool isSuccess = totalFunded >= config.minValue
                      && block.number > config.stopBlock;
        if (!isSuccess) throw;
        _;
    }

    /**
     * @dev Crowdfunding contract initial 
     * @param _fund Destination account address
     * @param _bounty Bounty token address
     * @param _reference Reference documentation link
     * @param _startBlock Funding start block number
     * @param _stopBlock Funding stop block nubmer
     * @param _minValue Minimal funded value in wei 
     * @param _maxValue Maximal funded value in wei
     * @param _scale Bounty scaling factor by funded value
     * @param _startRatio Initial bounty ratio
     * @param _reductionStep Bounty reduction step in blocks 
     * @param _reductionValue Bounty reduction value
     * @notice this contract should be owner of bounty token
     */
    function Crowdfunding(
        address _fund,
        address _bounty,
        string  _reference,
        uint256 _startBlock,
        uint256 _stopBlock,
        uint256 _minValue,
        uint256 _maxValue,
        uint256 _scale,
        uint256 _startRatio,
        uint256 _reductionStep,
        uint256 _reductionValue
    ) {
        fund      = _fund;
        bounty    = TokenEmission(_bounty);
        reference = _reference;

        config.startBlock     = _startBlock;
        config.stopBlock      = _stopBlock;
        config.minValue       = _minValue;
        config.maxValue       = _maxValue;
        config.bountyScale    = _scale;
        config.startRatio     = _startRatio;
        config.reductionStep  = _reductionStep;
        config.reductionValue = _reductionValue;
    }

    /**
     * @dev Receive Ether token and send bounty
     */
    function () payable onlyRunning {
        ReceivedEther(msg.sender, msg.value);

        totalFunded           += msg.value;
        donations[msg.sender] += msg.value;

        var bountyVal = bountyValue(msg.value, block.number);
        if (bountyVal == 0) throw;

        bounty.emission(bountyVal);
        bounty.transfer(msg.sender, bountyVal);
    }

    /**
     * @dev Withdrawal balance on successfull finish
     */
    function withdraw() onlySuccess
    { if (!fund.send(this.balance)) throw; }

    /**
     * @dev Refund donations when no minimal value achieved
     */
    function refund() onlyFailure {
        var donation = donations[msg.sender];
        donations[msg.sender] = 0;
        if (!msg.sender.send(donation)) throw;
    }

    /**
     * @dev Disable receive another tokens
     */
    function receiveApproval(address _from, uint256 _value,
                             ERC20 _token, bytes _extraData)
    { throw; }
}

library CreatorCrowdfunding {
    function create(address _fund, address _bounty, string _reference, uint256 _startBlock, uint256 _stopBlock, uint256 _minValue, uint256 _maxValue, uint256 _scale, uint256 _startRatio, uint256 _reductionStep, uint256 _reductionValue) returns (Crowdfunding)
    { return new Crowdfunding(_fund, _bounty, _reference, _startBlock, _stopBlock, _minValue, _maxValue, _scale, _startRatio, _reductionStep, _reductionValue); }

    function version() constant returns (string)
    { return "v0.6.3"; }

    function abi() constant returns (string)
    { return '[{"constant":false,"inputs":[{"name":"_owner","type":"address"}],"name":"setOwner","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"withdraw","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"hammer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"refund","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"config","outputs":[{"name":"startBlock","type":"uint256"},{"name":"stopBlock","type":"uint256"},{"name":"minValue","type":"uint256"},{"name":"maxValue","type":"uint256"},{"name":"bountyScale","type":"uint256"},{"name":"startRatio","type":"uint256"},{"name":"reductionStep","type":"uint256"},{"name":"reductionValue","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"destroy","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_value","type":"uint256"},{"name":"_block","type":"uint256"}],"name":"bountyValue","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_value","type":"uint256"},{"name":"_token","type":"address"},{"name":"_extraData","type":"bytes"}],"name":"receiveApproval","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"bounty","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalFunded","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"fund","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"reference","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"donations","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_hammer","type":"address"}],"name":"setHammer","outputs":[],"payable":false,"type":"function"},{"inputs":[{"name":"_fund","type":"address"},{"name":"_bounty","type":"address"},{"name":"_reference","type":"string"},{"name":"_startBlock","type":"uint256"},{"name":"_stopBlock","type":"uint256"},{"name":"_minValue","type":"uint256"},{"name":"_maxValue","type":"uint256"},{"name":"_scale","type":"uint256"},{"name":"_startRatio","type":"uint256"},{"name":"_reductionStep","type":"uint256"},{"name":"_reductionValue","type":"uint256"}],"payable":false,"type":"constructor"},{"payable":true,"type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"sender","type":"address"},{"indexed":true,"name":"amount","type":"uint256"}],"name":"ReceivedEther","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"value","type":"uint256"},{"indexed":true,"name":"token","type":"address"},{"indexed":false,"name":"extraData","type":"bytes"}],"name":"ReceivedTokens","type":"event"}]'; }
}

/**
 * @title Builder based contract
 */
contract Builder is Object {
    /**
     * @dev this event emitted for every builded contract
     */
    event Builded(address indexed client, address indexed instance);
 
    /* Addresses builded contracts at sender */
    mapping(address => address[]) public getContractsOf;
 
    /**
     * @dev Get last address
     * @return last address contract
     */
    function getLastContract() constant returns (address) {
        var sender_contracts = getContractsOf[msg.sender];
        return sender_contracts[sender_contracts.length - 1];
    }

    /* Building beneficiary */
    address public beneficiary;

    /**
     * @dev Set beneficiary
     * @param _beneficiary is address of beneficiary
     */
    function setBeneficiary(address _beneficiary) onlyOwner
    { beneficiary = _beneficiary; }

    /* Building cost  */
    uint public buildingCostWei;

    /**
     * @dev Set building cost
     * @param _buildingCostWei is cost
     */
    function setCost(uint _buildingCostWei) onlyOwner
    { buildingCostWei = _buildingCostWei; }

    /* Security check report */
    string public securityCheckURI;

    /**
     * @dev Set security check report URI
     * @param _uri is an URI to report
     */
    function setSecurityCheck(string _uri) onlyOwner
    { securityCheckURI = _uri; }
}

//
// AIRA Builder for Crowdfunding contract
//
contract BuilderCrowdfunding is Builder {
    /**
     * @dev Run script creation contract
     * @return address new contract
     */
    function create(
        address _fund,
        address _bounty,
        string _reference,
        uint256 _startBlock,
        uint256 _stopBlock,
        uint256 _minValue,
        uint256 _maxValue,
        uint256 _scale,
        uint256 _startRatio,
        uint256 _reductionStep,
        uint256 _reductionValue,
        address _client
    ) payable returns (address) {
        if (buildingCostWei > 0 && beneficiary != 0) {
            // Too low value
            if (msg.value < buildingCostWei) throw;
            // Beneficiary send
            if (!beneficiary.send(buildingCostWei)) throw;
            // Refund
            if (msg.value > buildingCostWei) {
                if (!msg.sender.send(msg.value - buildingCostWei)) throw;
            }
        } else {
            // Refund all
            if (msg.value > 0) {
                if (!msg.sender.send(msg.value)) throw;
            }
        }

        if (_client == 0)
            _client = msg.sender;
 
        var inst = CreatorCrowdfunding.create(_fund, _bounty, _reference, _startBlock,
                                              _stopBlock, _minValue, _maxValue, _scale,
                                              _startRatio, _reductionStep, _reductionValue);
        inst.setOwner(_client);
        inst.setHammer(_client);
        getContractsOf[_client].push(inst);
        Builded(_client, inst);
        return inst;
    }
}