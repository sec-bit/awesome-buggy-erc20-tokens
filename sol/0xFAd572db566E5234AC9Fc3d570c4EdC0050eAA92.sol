pragma solidity ^0.4.16;

// copyright contact@bytether.com

contract BasicAccessControl {
    address public owner;
    address[] public moderators;

    function BasicAccessControl() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        if (msg.sender != owner) {
            bool found = false;
            for (uint index = 0; index < moderators.length; index++) {
                if (moderators[index] == msg.sender) {
                    found = true;
                    break;
                }
            }
            require(found);
        }
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function Kill() onlyOwner public {
        selfdestruct(owner);
    }

    function AddModerator(address _newModerator) onlyOwner public {
        if (_newModerator != address(0)) {
            for (uint index = 0; index < moderators.length; index++) {
                if (moderators[index] == _newModerator) {
                    return;
                }
            }
            moderators.push(_newModerator);
        }
    }
    
    function RemoveModerator(address _oldModerator) onlyOwner public {
        uint foundIndex = 0;
        for (; foundIndex < moderators.length; foundIndex++) {
            if (moderators[foundIndex] == _oldModerator) {
                break;
            }
        }
        if (foundIndex < moderators.length) {
            moderators[foundIndex] = moderators[moderators.length-1];
            delete moderators[moderators.length-1];
            moderators.length--;
        }
    }
}

interface TokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

interface CrossForkDistribution {
    function getDistributedAmount(uint64 _requestId, string _btcAddress, address _receiver) public;
}

interface CrossForkCallback {
    function callbackCrossFork(uint64 _requestId, uint256 _amount, bytes32 _referCodeHash) public;
}

contract TokenERC20 {
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

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

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}

contract BTHToken is BasicAccessControl, TokenERC20, CrossForkCallback {
    // metadata
    string public constant name = "Bytether";
    string public constant symbol = "BTH";
    uint256 public constant decimals = 18;
    string public version = "1.0";
    
    // cross fork data
    enum ForkResultCode { 
        SUCCESS,
        TRIGGERED,
        RECEIVED,
        PENDING,
        FAILED,
        ID_MISMATCH,
        NOT_ENOUGH_BALANCE,
        NOT_RECEIVED
    }
    enum ClaimReferResultCode {
        SUCCESS,
        NOT_ENOUGH_BALANCE
    }
    struct CrossForkData {
        string btcAddress;
        address receiver;
        uint256 amount;
        bytes32 referCodeHash;
        uint createTime;
    }
    uint64 public crossForkCount = 0;
    uint public referBenefitRate = 10; // 10 btc -> 1 bth
    bool public crossForking = false;
    mapping (uint64 => CrossForkData) crossForkMapping;
    mapping (string => uint64) crossForkIds;
    mapping (bytes32 => uint256) referBenefits; // referCodeHash -> bth amount
    address public crossForkDistribution = 0x0; // crossfork contract
    uint256 public constant satoshi_bth_decimals = 10 ** 10;
    
    event LogRevertCrossFork(bytes32 indexed btcAddressHash, address indexed receiver, uint64 indexed requestId, uint256 amount, ForkResultCode result);
    event LogTriggerCrossFork(bytes32 indexed btcAddressHash, uint64 indexed requestId, ForkResultCode result);
    event LogCrossFork(uint64 indexed requestId, address receiver, uint256 amount, ForkResultCode result);
    event LogClaimReferBenefit(bytes32 indexed referCodeHash, address receiver, uint256 amount, ClaimReferResultCode result);
    
    // deposit address
    address public crossForkFundDeposit; // deposit address for cross fork
    address public bthFundDeposit; // deposit address for user growth pool & marketing
    address public developerFundDeposit; // deposit address for developer fund
    
    // fund distribution
    uint256 public crossForkFund = 17 * (10**6) * 10**decimals; //17m reserved for BitCoin Cross-Fork
    uint256 public marketingFund = 2  * (10**6) * 10**decimals; //2m reserved for marketing
    uint256 public userPoolFund  = 1  * (10**6) * 10**decimals; //1m for user growth pool
    uint256 public developerFund = 1  * (10**6) * 10**decimals; //1m reserved for developers
    
    // for future feature
    uint256 public sellPrice;
    uint256 public buyPrice;
    bool public trading = false;
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    
    // modifier
    modifier isCrossForking {
        require(crossForking == true || msg.sender == owner);
        require(crossForkDistribution != 0x0);
        _;
    }
    
    modifier isTrading {
        require(trading == true || msg.sender == owner);
        _;
    } 

    // constructor
    function BTHToken(address _crossForkDistribution, address _crossForkFundDeposit, address _bthFundDeposit, address _developerFundDeposit) public {
        totalSupply = crossForkFund + marketingFund + userPoolFund + developerFund;
        crossForkDistribution = _crossForkDistribution;
        crossForkFundDeposit = _crossForkFundDeposit;
        bthFundDeposit = _bthFundDeposit;
        developerFundDeposit = _developerFundDeposit;
        
        balanceOf[crossForkFundDeposit] += crossForkFund;
        balanceOf[bthFundDeposit] += marketingFund + userPoolFund;
        balanceOf[developerFundDeposit] += developerFund;
    }

    function () payable public {}
    
    // only admin
    function setCrossForkDistribution(address _crossForkDistribution) onlyOwner public {
        crossForkDistribution = _crossForkDistribution;
    }

    function setDepositAddress(address _crossForkFund, address _bthFund, address _developerFund) onlyOwner public {
        crossForkFundDeposit = _crossForkFund;
        bthFundDeposit = _bthFund;
        developerFundDeposit = _developerFund;
    }

    function setPrices(uint256 _newSellPrice, uint256 _newBuyPrice) onlyOwner public {
        sellPrice = _newSellPrice;
        buyPrice = _newBuyPrice;
    }

    function setReferBenefitRate(uint _rate) onlyOwner public {
        referBenefitRate = _rate;
    }
    
    // only moderators
    function toggleCrossForking() onlyModerators public {
        crossForking = !crossForking;
    }
    
    function toggleTrading() onlyModerators public {
        trading = !trading;
    }
    
    function claimReferBenefit(string _referCode, address _receiver) onlyModerators public {
        bytes32 referCodeHash = keccak256(_referCode);
        uint256 totalAmount = referBenefits[referCodeHash];
        if (totalAmount==0) {
            LogClaimReferBenefit(referCodeHash, _receiver, 0, ClaimReferResultCode.SUCCESS);
            return;
        }
        if (balanceOf[bthFundDeposit] < totalAmount) {
            LogClaimReferBenefit(referCodeHash, _receiver, 0, ClaimReferResultCode.NOT_ENOUGH_BALANCE);
            return;
        }
        
        referBenefits[referCodeHash] = 0;
        balanceOf[bthFundDeposit] -= totalAmount;
        balanceOf[_receiver] += totalAmount;
        LogClaimReferBenefit(referCodeHash, _receiver, totalAmount, ClaimReferResultCode.SUCCESS);
    }

    // in case there is an error
    function revertCrossFork(string _btcAddress) onlyModerators public {
        bytes32 btcAddressHash = keccak256(_btcAddress);
        uint64 requestId = crossForkIds[_btcAddress];
        if (requestId == 0) {
            LogRevertCrossFork(btcAddressHash, 0x0, 0, 0, ForkResultCode.NOT_RECEIVED);
            return;
        }
        CrossForkData storage crossForkData = crossForkMapping[requestId];
        uint256 amount = crossForkData.amount;        
        address receiver = crossForkData.receiver;
        if (balanceOf[receiver] < crossForkData.amount) {
            LogRevertCrossFork(btcAddressHash, receiver, requestId, amount, ForkResultCode.NOT_ENOUGH_BALANCE);
            return;
        }
        
        // revert
        balanceOf[crossForkData.receiver] -= crossForkData.amount;
        balanceOf[crossForkFundDeposit] += crossForkData.amount;
        crossForkIds[_btcAddress] = 0;
        crossForkData.btcAddress = "";
        crossForkData.receiver = 0x0;
        crossForkData.amount = 0;
        crossForkData.createTime = 0;
        
        // revert refer claimable amount if possible
        if (referBenefits[crossForkData.referCodeHash] > 0) {
            uint256 deductAmount = crossForkData.amount;
            if (referBenefits[crossForkData.referCodeHash] < deductAmount) {
                deductAmount = referBenefits[crossForkData.referCodeHash];
            }
            referBenefits[crossForkData.referCodeHash] -= deductAmount;
        }
        
        LogRevertCrossFork(btcAddressHash, receiver, requestId, amount, ForkResultCode.SUCCESS);
    }

    // public
    function getCrossForkId(string _btcAddress) constant public returns(uint64) {
        return crossForkIds[_btcAddress];
    }
    
    function getCrossForkData(uint64 _id) constant public returns(string, address, uint256, uint) {
        CrossForkData storage crossForkData = crossForkMapping[_id];
        return (crossForkData.btcAddress, crossForkData.receiver, crossForkData.amount, crossForkData.createTime);
    }
    
    function getReferBenefit(string _referCode) constant public returns(uint256) {
        return referBenefits[keccak256(_referCode)];
    }
    
    function callbackCrossFork(uint64 _requestId, uint256 _amount, bytes32 _referCodeHash) public {
        if (msg.sender != crossForkDistribution || _amount == 0) {
            LogCrossFork(_requestId, 0x0, 0, ForkResultCode.FAILED);
            return;
        }
        CrossForkData storage crossForkData = crossForkMapping[_requestId];
        if (crossForkData.receiver == 0x0) {
            LogCrossFork(_requestId, crossForkData.receiver, 0, ForkResultCode.ID_MISMATCH);
            return;
        }
        if (crossForkIds[crossForkData.btcAddress] != 0) {
            LogCrossFork(_requestId, crossForkData.receiver, crossForkData.amount, ForkResultCode.RECEIVED);
            return;
        }
        crossForkIds[crossForkData.btcAddress] = _requestId;
        crossForkData.amount = _amount*satoshi_bth_decimals;
        
        // add fund for address
        if (balanceOf[crossForkFundDeposit] < crossForkData.amount) {
            LogCrossFork(_requestId, crossForkData.receiver, crossForkData.amount, ForkResultCode.NOT_ENOUGH_BALANCE);
            return;
        }
        balanceOf[crossForkFundDeposit] -= crossForkData.amount;
        balanceOf[crossForkData.receiver] += crossForkData.amount;
        if (referBenefitRate > 0) {
            crossForkData.referCodeHash = _referCodeHash;
            referBenefits[_referCodeHash] += crossForkData.amount / referBenefitRate;
        }
        
        LogCrossFork(_requestId, crossForkData.receiver, crossForkData.amount, ForkResultCode.SUCCESS);
    }
    
    function triggerCrossFork(string _btcAddress) isCrossForking public returns(ForkResultCode) {
        bytes32 btcAddressHash = keccak256(_btcAddress);
        if (crossForkIds[_btcAddress] > 0) {
            LogTriggerCrossFork(btcAddressHash, crossForkIds[_btcAddress], ForkResultCode.RECEIVED);
            return ForkResultCode.RECEIVED;
        }

        crossForkCount += 1;
        CrossForkData storage crossForkData = crossForkMapping[crossForkCount];
        crossForkData.btcAddress = _btcAddress;
        crossForkData.receiver = msg.sender;
        crossForkData.amount = 0;
        crossForkData.createTime = now;
        CrossForkDistribution crossfork = CrossForkDistribution(crossForkDistribution);
        crossfork.getDistributedAmount(crossForkCount, _btcAddress, msg.sender);
        LogTriggerCrossFork(btcAddressHash, crossForkIds[_btcAddress], ForkResultCode.TRIGGERED);
        return ForkResultCode.TRIGGERED;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);
        require (balanceOf[_from] > _value);
        require (balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }
    
    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        frozenAccount[_target] = _freeze;
        FrozenFunds(_target, _freeze);
    }
    
    function buy() payable isTrading public {
        uint amount = msg.value / buyPrice;
        _transfer(this, msg.sender, amount);
    }

    function sell(uint256 amount) isTrading public {
        require(this.balance >= amount * sellPrice);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount * sellPrice);
    }
    
    
}