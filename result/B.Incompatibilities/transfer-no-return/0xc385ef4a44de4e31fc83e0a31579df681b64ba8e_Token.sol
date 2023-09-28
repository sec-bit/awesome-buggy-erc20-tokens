pragma solidity ^0.4.18;


contract Owned {
    address public owner;
    function Owned() public {
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


interface tokenRecipient { function receiveApproval(address _from, uint _value, address _token, bytes _extraData) public; }


contract TokenBase is Owned {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public totalSupply;
    uint public tokenUnit = 10 ** uint(decimals);
    uint public wanUnit = 10000 * tokenUnit;
    uint public foundingTime;

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);

    function TokenBase() public {
        foundingTime = now;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}


contract WorkProff is TokenBase {
    uint public oneYear = 1 years;
    uint public minerTotalSupply = 3900 * wanUnit;
    uint public minerTotalYears = 20;
    uint public minerTotalTime = minerTotalYears * oneYear;
    uint public minerPreSupply = minerTotalSupply / 2;
    uint public minerPreTime = 7 days;
    uint public minerTotalReward = 0;
    uint public minerTimeOfLastProof;
    uint public minerDifficulty = 10 ** 32;
    bytes32 public minerCurrentChallenge;

    function WorkProff() public {
        minerTimeOfLastProof = now;
    }
    
    function proofOfWork(uint nonce) public {
        require(minerTotalReward < minerTotalSupply);
        bytes8 n = bytes8(sha3(nonce, minerCurrentChallenge));
        require(n >= bytes8(minerDifficulty));

        uint timeSinceLastProof = (now - minerTimeOfLastProof);
        require(timeSinceLastProof >= 5 seconds);
        
        uint reward = 0;
        if (now - foundingTime < minerPreTime) {
            reward = timeSinceLastProof * minerPreSupply / minerPreTime;
        } else {
            reward = timeSinceLastProof * (minerTotalSupply - minerPreSupply) / minerTotalTime;
        }

        balanceOf[msg.sender] += reward;
        totalSupply += reward;
        minerTotalReward += reward;
        minerDifficulty = minerDifficulty * 10 minutes / timeSinceLastProof + 1;
        minerTimeOfLastProof = now;
        minerCurrentChallenge = sha3(nonce, minerCurrentChallenge, block.blockhash(block.number - 1));
        Transfer(0, this, reward);
        Transfer(this, msg.sender, reward);
    }
}


contract Option is WorkProff {
    uint public optionTotalSupply;
    uint public optionInitialSupply = 6600 * wanUnit;
    uint public optionTotalTimes = 5;
    uint public optionExerciseSpan = 1 years;

    mapping (address => uint) public optionOf;
    mapping (address => uint) public optionExerciseOf;

    event OptionTransfer(address indexed from, address indexed to, uint option, uint exercised);
    event OptionExercise(address indexed addr, uint value);

    function Option() public {
        optionTotalSupply = optionInitialSupply;
        optionOf[msg.sender] = optionInitialSupply;
        optionExerciseOf[msg.sender] = 0;
    }

    function min(uint a, uint b) private returns (uint) {
        return a < b ? a : b;
    }

    function _checkOptionExercise(uint option, uint exercised) internal returns (bool) {
        uint canExercisedTimes = min(optionTotalTimes, (now - foundingTime) / optionExerciseSpan + 1);
        return exercised <= option * canExercisedTimes / optionTotalTimes;
    }

    function _optionTransfer(address _from, address _to, uint _option, uint _exercised) internal {
        require(_to != 0x0);
        require(optionOf[_from] >= _option);
        require(optionOf[_to] + _option > optionOf[_to]);
        require(optionExerciseOf[_from] >= _exercised);
        require(optionExerciseOf[_to] + _exercised > optionExerciseOf[_to]);
        require(_checkOptionExercise(_option, _exercised));
        require(_checkOptionExercise(optionOf[_from] - _option, optionExerciseOf[_from] - _exercised));

        uint previousOptions = optionOf[_from] + optionOf[_to];
        uint previousExercised = optionExerciseOf[_from] + optionExerciseOf[_to];
        optionOf[_from] -= _option;
        optionOf[_to] += _option;
        optionExerciseOf[_from] -= _exercised;
        optionExerciseOf[_to] += _exercised;
        OptionTransfer(_from, _to, _option, _exercised);
        assert(optionOf[_from] + optionOf[_to] == previousOptions);
        assert(optionExerciseOf[_from] + optionExerciseOf[_to] == previousExercised);
    }

    function optionTransfer(address _to, uint _option, uint _exercised) public {
        _optionTransfer(msg.sender, _to, _option, _exercised);
    }

    function optionExercise(uint value) public {
        require(_checkOptionExercise(optionOf[msg.sender], optionExerciseOf[msg.sender] + value));
        optionExerciseOf[msg.sender] += value;
        balanceOf[msg.sender] += value;
        totalSupply += value;
        Transfer(0, this, value);
        Transfer(this, msg.sender, value);
        OptionExercise(msg.sender, value);
    }
}

contract Token is Option {
    uint public initialSupply = 0 * wanUnit;
    uint public reserveSupply = 10500 * wanUnit;
    uint public sellSupply = 9000 * wanUnit;

    function Token() public {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        name = "ZBC";
        symbol = "ZBC";
    }

    function releaseReserve(uint value) onlyOwner public {
        require(reserveSupply >= value);
        balanceOf[owner] += value;
        totalSupply += value;
        reserveSupply -= value;
        Transfer(0, this, value);
        Transfer(this, owner, value);
    }

    function releaseSell(uint value) onlyOwner public {
        require(sellSupply >= value);
        balanceOf[owner] += value;
        totalSupply += value;
        sellSupply -= value;
        Transfer(0, this, value);
        Transfer(this, owner, value);
    }
}