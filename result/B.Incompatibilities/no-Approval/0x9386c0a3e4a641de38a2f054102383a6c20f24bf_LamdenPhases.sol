pragma solidity ^0.4.13;

contract Ownable {

    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    address newOwner;
    function transferOwnership(address _newOwner) onlyOwner {
        if (_newOwner != address(0)) {
            newOwner = _newOwner;
        }
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract ERC20 is Ownable {
    /* Public variables of the token */
    string public standard;

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public initialSupply;

    bool public locked;

    uint256 public creationBlock;

    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ERC20(
    uint256 _initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol,
    bool transferAllSupplyToOwner,
    bool _locked
    ) {
        standard = 'ERC20 0.1';

        initialSupply = _initialSupply;

        if (transferAllSupplyToOwner) {
            setBalance(msg.sender, initialSupply);
        }
        else {
            setBalance(this, initialSupply);
        }

        name = tokenName;
        // Set the name for display purposes
        symbol = tokenSymbol;
        // Set the symbol for display purposes
        decimals = decimalUnits;
        // Amount of decimals for display purposes
        locked = _locked;
        creationBlock = block.number;
    }

    /* internal balances */

    function setBalance(address holder, uint256 amount) internal {
        balances[holder] = amount;
    }

    function transferInternal(address _from, address _to, uint256 value) internal returns (bool success) {
        if (value == 0) {
            return true;
        }

        if (balances[_from] < value) {
            return false;
        }

        if (balances[_to] + value <= balances[_to]) {
            return false;
        }

        setBalance(_from, balances[_from] - value);
        setBalance(_to, balances[_to] + value);

        Transfer(_from, _to, value);

        return true;
    }

    /* public methods */
    function totalSupply() returns (uint256) {
        return initialSupply;
    }

    function balanceOf(address _address) returns (uint256) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2) returns (bool) {
        require(locked == false);

        bool status = transferInternal(msg.sender, _to, _value);

        require(status == true);

        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if(locked) {
            return false;
        }

        allowance[msg.sender][_spender] = _value;

        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        if (locked) {
            return false;
        }

        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (locked) {
            return false;
        }

        if (allowance[_from][msg.sender] < _value) {
            return false;
        }

        bool _success = transferInternal(_from, _to, _value);

        if (_success) {
            allowance[_from][msg.sender] -= _value;
        }

        return _success;
    }

}

contract MintingERC20 is ERC20 {

    mapping (address => bool) public minters;

    uint256 public maxSupply;

    function MintingERC20(
    uint256 _initialSupply,
    uint256 _maxSupply,
    string _tokenName,
    uint8 _decimals,
    string _symbol,
    bool _transferAllSupplyToOwner,
    bool _locked
    )
    ERC20(_initialSupply, _tokenName, _decimals, _symbol, _transferAllSupplyToOwner, _locked)

    {
        standard = "MintingERC20 0.1";
        minters[msg.sender] = true;
        maxSupply = _maxSupply;
    }


    function addMinter(address _newMinter) onlyOwner {
        minters[_newMinter] = true;
    }


    function removeMinter(address _minter) onlyOwner {
        minters[_minter] = false;
    }


    function mint(address _addr, uint256 _amount) onlyMinters returns (uint256) {
        if (locked == true) {
            return uint256(0);
        }

        if (_amount == uint256(0)) {
            return uint256(0);
        }
        if (initialSupply + _amount <= initialSupply){
            return uint256(0);
        }
        if (initialSupply + _amount > maxSupply) {
            return uint256(0);
        }

        initialSupply += _amount;
        balances[_addr] += _amount;
        Transfer(this, _addr, _amount);
        return _amount;
    }


    modifier onlyMinters () {
        require(true == minters[msg.sender]);
        _;
    }
}

contract Lamden is MintingERC20 {


    uint8 public decimals = 18;

    string public tokenName = "Lamden Tau";

    string public tokenSymbol = "TAU";

    uint256 public  maxSupply = 500 * 10 ** 6 * uint(10) ** decimals; // 500,000,000

    // We block token transfers till ICO end.
    bool public transferFrozen = true;

    function Lamden(
    uint256 initialSupply,
    bool _locked
    ) MintingERC20(initialSupply, maxSupply, tokenName, decimals, tokenSymbol, false, _locked) {
        standard = 'Lamden 0.1';
    }

    function setLocked(bool _locked) onlyOwner {
        locked = _locked;
    }

    // Allow token transfer.
    function freezing(bool _transferFrozen) onlyOwner {
        transferFrozen = _transferFrozen;
    }

    // ERC20 functions
    // =========================

    function transfer(address _to, uint _value) returns (bool) {
        require(!transferFrozen);
        return super.transfer(_to, _value);

    }

    // should  not have approve/transferFrom
    function approve(address, uint) returns (bool success)  {
        require(false);
        return false;
        //        super.approve(_spender, _value);
    }

    function approveAndCall(address, uint256, bytes) returns (bool success) {
        require(false);
        return false;
    }

    function transferFrom(address, address, uint)  returns (bool success) {
        require(false);
        return false;
        //        super.transferFrom(_from, _to, _value);
    }
}

contract LamdenTokenAllocation is Ownable {

    Lamden public tau;

    uint256 public constant LAMDEN_DECIMALS = 10 ** 18;

    uint256 allocatedTokens = 0;

    Allocation[] allocations;

    struct Allocation {
    address _address;
    uint256 amount;
    }


    function LamdenTokenAllocation(
    address _tau,
    address[] addresses
    ){
        require(uint8(addresses.length) == uint8(14));
        allocations.push(Allocation(addresses[0], 20000000 * LAMDEN_DECIMALS)); //Stu
        allocations.push(Allocation(addresses[1], 12500000 * LAMDEN_DECIMALS)); //Nick
        allocations.push(Allocation(addresses[2], 8750000 * LAMDEN_DECIMALS)); //James
        allocations.push(Allocation(addresses[3], 8750000 * LAMDEN_DECIMALS)); //Mario
        allocations.push(Allocation(addresses[4], 250000 * LAMDEN_DECIMALS));     // Advisor
        allocations.push(Allocation(addresses[5], 250000 * LAMDEN_DECIMALS));  // Advisor
        allocations.push(Allocation(addresses[6], 250000 * LAMDEN_DECIMALS));  // Advisor
        allocations.push(Allocation(addresses[7], 250000 * LAMDEN_DECIMALS));  // Advisor
        allocations.push(Allocation(addresses[8], 250000 * LAMDEN_DECIMALS));  // Advisor
        allocations.push(Allocation(addresses[9], 250000 * LAMDEN_DECIMALS));  // Advisor
        allocations.push(Allocation(addresses[10], 250000 * LAMDEN_DECIMALS));  // Advisor
        allocations.push(Allocation(addresses[11], 250000 * LAMDEN_DECIMALS));  // Advisor
        allocations.push(Allocation(addresses[12], 48000000 * LAMDEN_DECIMALS));  // enterpriseCaseStudies
        allocations.push(Allocation(addresses[13], 50000000  * LAMDEN_DECIMALS));  // AKA INNOVATION FUND
        tau = Lamden(_tau);
    }

    function allocateTokens(){
        require(uint8(allocations.length) == uint8(14));
        require(address(tau) != 0x0);
        require(allocatedTokens == 0);
        for (uint8 i = 0; i < allocations.length; i++) {
            Allocation storage allocation = allocations[i];
            uint256 mintedAmount = tau.mint(allocation._address, allocation.amount);
            require(mintedAmount == allocation.amount);
            allocatedTokens += allocation.amount;
        }
    }

    function setTau(address _tau) onlyOwner {
        tau = Lamden(_tau);
    }
}


contract LamdenPhases is Ownable {

    uint256 public constant LAMDEN_DECIMALS = 10 ** 18;

    uint256 public soldTokens;

    uint256 public collectedEthers;

    uint256 todayCollectedEthers;

    uint256 icoInitialThresholds;

    uint256 currentDay;

    Phase[] public phases;

    Lamden public tau;

    uint8 currentPhase;

    address etherHolder;

    address investor = 0x3669ad54675E94e14196528786645c858b8391F1;

    mapping(address => uint256) alreadyContributed;

    struct Phase {
    uint256 price;
    uint256 maxAmount;
    uint256 since;
    uint256 till;
    uint256 soldTokens;
    uint256 collectedEthers;
    bool isFinished;
    mapping (address => bool) whitelist;
    }

    function LamdenPhases(
    address _etherHolder,
    address _tau,
    uint256 _tokenPreIcoPrice,
    uint256 _preIcoSince,
    uint256 _preIcoTill,
    uint256 preIcoMaxAmount, // 1,805,067.01326114 +   53,280,090
    uint256 _tokenIcoPrice,
    uint256 _icoSince,
    uint256 _icoTill,
    uint256 icoMaxAmount,
    uint256 icoThresholds
    )
    {
        phases.push(Phase(_tokenPreIcoPrice, preIcoMaxAmount, _preIcoSince, _preIcoTill, 0, 0, false));
        phases.push(Phase(_tokenIcoPrice, icoMaxAmount, _icoSince, _icoTill, 0, 0, false));
        etherHolder = _etherHolder;
        icoInitialThresholds = icoThresholds;
        tau = Lamden(_tau);
    }

    // call add minter from TAU token after contract deploying
    function sendTokensToInvestor() onlyOwner {
        uint256 mintedAmount = mintInternal(investor, (1805067013261140000000000));
        require(mintedAmount == uint256(1805067013261140000000000));
    }

    function getIcoTokensAmount(uint256 value, uint256 time, address _address) returns (uint256) {
        if (value == 0) {
            return uint256(0);
        }
        uint256 amount = 0;

        for (uint8 i = 0; i < phases.length; i++) {
            Phase storage phase = phases[i];

            if (phase.whitelist[_address] == false) {
                continue;
            }
						
            if(phase.isFinished){
                continue;
            }

            if (phase.since > time) {
                continue;
            }

            if (phase.till < time) {
                continue;
            }
            currentPhase = i;

            // should we be multiplying by 10 ** 18???
            // 1 eth = 1000000000000000000 / 
            uint256 phaseAmount = value * LAMDEN_DECIMALS / phase.price;
            
            amount += phaseAmount;

            if (phase.maxAmount < amount + soldTokens) {
                return uint256(0);
            }
            //            phase.soldTokens += amount;
            phase.collectedEthers += value;
        }
        return amount;
    }

    function() payable {
        bool status = buy(msg.sender, msg.value);
        require(status == true);
    }

    function setInternalFinished(uint8 phaseId, bool _finished) internal returns (bool){
        if (phases.length < phaseId) {
            return false;
        }

        Phase storage phase = phases[phaseId];

        if (phase.isFinished == true) {
            return true;
        }

        phase.isFinished = _finished;

        return true;
    }

    function setFinished(uint8 phaseId, bool _finished) onlyOwner returns (bool){
        return setInternalFinished(phaseId, _finished);
    }

    function buy(address _address, uint256 _value) internal returns (bool) {
        if (_value == 0) {
            return false;
        }

        if (phases.length < currentPhase) {
            return false;
        }
        Phase storage icoPhase = phases[1];

        if (icoPhase.since <= now) {

            currentPhase = 1;
            uint256 daysInterval = (now - icoPhase.since) / uint256(86400);
            uint256 todayMaxEthers = icoInitialThresholds;

            if (daysInterval != currentDay) {
                currentDay = daysInterval;
                todayCollectedEthers = 0;
            }

            todayMaxEthers = icoInitialThresholds * (2 ** daysInterval);

            if(alreadyContributed[_address] + _value > todayMaxEthers) {
                return false;
            }

            alreadyContributed[_address] += _value;
        }

        uint256 tokenAmount = getIcoTokensAmount(_value, now, _address);

        if (tokenAmount == 0) {
            return false;
        }

        uint256 mintedAmount = mintInternal(_address, tokenAmount);
        require(mintedAmount == tokenAmount);

        collectedEthers += _value;

        Phase storage phase = phases[currentPhase];
        if (soldTokens == phase.maxAmount) {
            setInternalFinished(currentPhase, true);
        }
        return true;
    }

    function setTau(address _tau) onlyOwner {
        tau = Lamden(_tau);
    }

    function setPhase(uint8 phaseId, uint256 since, uint256 till, uint256 price) onlyOwner returns (bool) {
        if (phases.length <= phaseId) {
            return false;
        }

        if (price == 0) {
            return false;
        }
        Phase storage phase = phases[phaseId];

        if (phase.isFinished == true) {
            return false;
        }
        phase.since = since;
        phase.till = till;

        phase.price = price;

        return true;
    }

    function transferEthers() onlyOwner {
        require(etherHolder != 0x0);
        etherHolder.transfer(this.balance);
    }

    function addToWhitelist(uint8 phaseId, address _address) onlyOwner {

        require(phases.length > phaseId);

        Phase storage phase = phases[phaseId];

        phase.whitelist[_address] = true;

    }

    function removeFromWhitelist(uint8 phaseId, address _address) onlyOwner {

        require(phases.length > phaseId);

        Phase storage phase = phases[phaseId];

        phase.whitelist[_address] = false;

    }

    function mint(address _address, uint256 tokenAmount) onlyOwner returns (uint256) {
        return mintInternal(_address, tokenAmount);
    }

    function mintInternal(address _address, uint256 tokenAmount) internal returns (uint256) {
        require(address(tau) != 0x0);
        uint256 mintedAmount = tau.mint(_address, tokenAmount);
        require(mintedAmount == tokenAmount);

        require(phases.length > currentPhase);
        Phase storage phase = phases[currentPhase];
        phase.soldTokens += tokenAmount;
        soldTokens += tokenAmount;
        return tokenAmount;
    }

    function getPhase(uint8 phaseId) returns (uint256, uint256, uint256, uint256, uint256, uint256, bool)
    {

        require(phases.length > phaseId);

        Phase storage phase = phases[phaseId];

        return (phase.price, phase.maxAmount, phase.since, phase.till, phase.soldTokens, phase.collectedEthers, phase.isFinished);

    }

}