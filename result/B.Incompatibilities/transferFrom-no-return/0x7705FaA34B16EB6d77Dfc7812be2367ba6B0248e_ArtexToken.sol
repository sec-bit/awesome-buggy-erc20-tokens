pragma solidity ^ 0.4.13;

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

contract PreArtexToken {
    struct Investor {
        uint amountTokens;
        uint amountWei;
    }

    uint public etherPriceUSDWEI;
    address public beneficiary;
    uint public totalLimitUSDWEI;
    uint public minimalSuccessUSDWEI;
    uint public collectedUSDWEI;

    uint public state;

    uint public crowdsaleStartTime;
    uint public crowdsaleFinishTime;

    mapping(address => Investor) public investors;
    mapping(uint => address) public investorsIter;
    uint public numberOfInvestors;
}

contract Owned {

    address public owner;
    address public newOwner;
    address public oracle;
    address public btcOracle;

    function Owned() payable {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    modifier onlyOwnerOrOracle {
        require(owner == msg.sender || oracle == msg.sender);
        _;
    }

    modifier onlyOwnerOrBtcOracle {
        require(owner == msg.sender || btcOracle == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner external {
        require(_owner != 0);
        newOwner = _owner;
    }

    function confirmOwner() external {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }

    function changeOracle(address _oracle) onlyOwner external {
        require(_oracle != 0);
        oracle = _oracle;
    }

    function changeBtcOracle(address _btcOracle) onlyOwner external {
        require(_btcOracle != 0);
        btcOracle = _btcOracle;
    }
}

contract KnownContract {
    function transfered(address _sender, uint256 _value, bytes32[] _data) external;
}

contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) constant returns(uint);

    function transfer(address to, uint value);

    function allowance(address owner, address spender) constant returns(uint);

    function transferFrom(address from, address to, uint value);

    function approve(address spender, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

    event Transfer(address indexed from, address indexed to, uint value);
}

contract Stateful {
    enum State {
        Initial,
        PreSale,
        WaitingForSale,
        Sale,
        CrowdsaleCompleted,
        SaleFailed
    }

    State public state = State.Initial;

    event StateChanged(State oldState, State newState);

    function setState(State newState) internal {
        State oldState = state;
        state = newState;
        StateChanged(oldState, newState);
    }
}

contract Crowdsale is Owned, Stateful {

    uint public etherPriceUSDWEI;
    address public beneficiary;
    uint public totalLimitUSDWEI;
    uint public minimalSuccessUSDWEI;
    uint public collectedUSDWEI;

    uint public crowdsaleStartTime;
    uint public crowdsaleFinishTime;

    uint public tokenPriceUSDWEI = 100000000000000000;

    struct Investor {
        uint amountTokens;
        uint amountWei;
    }

    struct BtcDeposit {
        uint amountBTCWEI;
        uint btcPriceUSDWEI;
        address investor;
    }

    mapping(bytes32 => BtcDeposit) public btcDeposits;

    mapping(address => Investor) public investors;
    mapping(uint => address) public investorsIter;
    uint public numberOfInvestors;

    mapping(uint => address) public investorsToWithdrawIter;
    uint public numberOfInvestorsToWithdraw;

    function Crowdsale() payable Owned() {}

    //abstract methods
    function emitTokens(address _investor, uint _usdwei) internal returns(uint tokensToEmit);

    function emitAdditionalTokens() internal;

    function burnTokens(address _address, uint _amount) internal;

    function() payable crowdsaleState limitNotExceeded crowdsaleNotFinished {
        uint valueWEI = msg.value;
        uint valueUSDWEI = valueWEI * etherPriceUSDWEI / 1 ether;
        if (collectedUSDWEI + valueUSDWEI > totalLimitUSDWEI) { // don't need so much ether
            valueUSDWEI = totalLimitUSDWEI - collectedUSDWEI;
            valueWEI = valueUSDWEI * 1 ether / etherPriceUSDWEI;
            uint weiToReturn = msg.value - valueWEI;
            bool isSent = msg.sender.call.gas(3000000).value(weiToReturn)();
            require(isSent);
            collectedUSDWEI = totalLimitUSDWEI; // to be sure!                                              
        } else {
            collectedUSDWEI += valueUSDWEI;
        }
        emitTokensFor(msg.sender, valueUSDWEI, valueWEI);
    }

    function depositUSD(address _to, uint _amountUSDWEI) external onlyOwner crowdsaleState limitNotExceeded crowdsaleNotFinished {
        collectedUSDWEI += _amountUSDWEI;
        emitTokensFor(_to, _amountUSDWEI, 0);
    }

    function depositBTC(address _to, uint _amountBTCWEI, uint _btcPriceUSDWEI, bytes32 _btcTxId) external onlyOwnerOrBtcOracle crowdsaleState limitNotExceeded crowdsaleNotFinished {
        uint valueUSDWEI = _amountBTCWEI * _btcPriceUSDWEI / 1 ether;
        BtcDeposit storage btcDep = btcDeposits[_btcTxId];
        require(btcDep.amountBTCWEI == 0);
        btcDep.amountBTCWEI = _amountBTCWEI;
        btcDep.btcPriceUSDWEI = _btcPriceUSDWEI;
        btcDep.investor = _to;
        collectedUSDWEI += valueUSDWEI;
        emitTokensFor(_to, valueUSDWEI, 0);
    }

    function emitTokensFor(address _investor, uint _valueUSDWEI, uint _valueWEI) internal {
        var emittedTokens = emitTokens(_investor, _valueUSDWEI);
        Investor storage inv = investors[_investor];
        if (inv.amountTokens == 0) { // new investor
            investorsIter[numberOfInvestors++] = _investor;
        }
        inv.amountTokens += emittedTokens;
        if (state == State.Sale) {
            inv.amountWei += _valueWEI;
        }
    }

    function startPreSale(
        address _beneficiary,
        uint _etherPriceUSDWEI,
        uint _totalLimitUSDWEI,
        uint _crowdsaleDurationDays) external onlyOwner {
        require(state == State.Initial);
        crowdsaleStartTime = now;
        beneficiary = _beneficiary;
        etherPriceUSDWEI = _etherPriceUSDWEI;
        totalLimitUSDWEI = _totalLimitUSDWEI;
        crowdsaleFinishTime = now + _crowdsaleDurationDays * 1 days;
        collectedUSDWEI = 0;
        setState(State.PreSale);
    }

    function finishPreSale() public onlyOwner {
        require(state == State.PreSale);
        bool isSent = beneficiary.call.gas(3000000).value(this.balance)();
        require(isSent);
        setState(State.WaitingForSale);
    }

    function startSale(
        address _beneficiary,
        uint _etherPriceUSDWEI,
        uint _totalLimitUSDWEI,
        uint _crowdsaleDurationDays,
        uint _minimalSuccessUSDWEI) external onlyOwner {

        require(state == State.WaitingForSale);
        crowdsaleStartTime = now;
        beneficiary = _beneficiary;
        etherPriceUSDWEI = _etherPriceUSDWEI;
        totalLimitUSDWEI = _totalLimitUSDWEI;
        crowdsaleFinishTime = now + _crowdsaleDurationDays * 1 days;
        minimalSuccessUSDWEI = _minimalSuccessUSDWEI;
        collectedUSDWEI = 0;
        setState(State.Sale);
    }

    function failSale(uint _investorsToProcess) public {
        require(state == State.Sale);
        require(now >= crowdsaleFinishTime && collectedUSDWEI < minimalSuccessUSDWEI);
        while (_investorsToProcess > 0 && numberOfInvestors > 0) {
            address addr = investorsIter[--numberOfInvestors];
            Investor memory inv = investors[addr];
            burnTokens(addr, inv.amountTokens);
            --_investorsToProcess;
            delete investorsIter[numberOfInvestors];

            investorsToWithdrawIter[numberOfInvestorsToWithdraw] = addr;
            numberOfInvestorsToWithdraw++;
        }
        if (numberOfInvestors > 0) {
            return;
        }
        setState(State.SaleFailed);
    }

    function completeSale(uint _investorsToProcess) public onlyOwner {
        require(state == State.Sale);
        require(collectedUSDWEI >= minimalSuccessUSDWEI);

        while (_investorsToProcess > 0 && numberOfInvestors > 0) {
            --numberOfInvestors;
            --_investorsToProcess;
            delete investors[investorsIter[numberOfInvestors]];
            delete investorsIter[numberOfInvestors];
        }

        if (numberOfInvestors > 0) {
            return;
        }

        emitAdditionalTokens();

        bool isSent = beneficiary.call.gas(3000000).value(this.balance)();
        require(isSent);
        setState(State.CrowdsaleCompleted);
    }

    function setEtherPriceUSDWEI(uint _etherPriceUSDWEI) external onlyOwnerOrOracle {
        etherPriceUSDWEI = _etherPriceUSDWEI;
    }

    function setBeneficiary(address _beneficiary) external onlyOwner() {
        require(_beneficiary != 0);
        beneficiary = _beneficiary;
    }

    // This function must be called by token holder in case of crowdsale failed
    function withdrawBack() external saleFailedState {
        returnInvestmentsToInternal(msg.sender);
    }

    function returnInvestments(uint _investorsToProcess) public saleFailedState {
        while (_investorsToProcess > 0 && numberOfInvestorsToWithdraw > 0) {
            address addr = investorsToWithdrawIter[--numberOfInvestorsToWithdraw];
            delete investorsToWithdrawIter[numberOfInvestorsToWithdraw];
            --_investorsToProcess;
            returnInvestmentsToInternal(addr);
        }
    }

    function returnInvestmentsTo(address _to) public saleFailedState {
        returnInvestmentsToInternal(_to);
    }

    function returnInvestmentsToInternal(address _to) internal {
        Investor memory inv = investors[_to];
        uint value = inv.amountWei;
        if (value > 0) {
            delete investors[_to];
            require(_to.call.gas(3000000).value(value)());
        }
    }

    function withdrawFunds(uint _value) public onlyOwner {
        require(state == State.PreSale || (state == State.Sale && collectedUSDWEI > minimalSuccessUSDWEI));
        if (_value == 0) {
            _value = this.balance;
        }
        bool isSent = beneficiary.call.gas(3000000).value(_value)();
        require(isSent);
    }

    modifier crowdsaleNotFinished {
        require(now < crowdsaleFinishTime);
        _;
    }

    modifier limitNotExceeded {
        require(collectedUSDWEI < totalLimitUSDWEI);
        _;
    }

    modifier crowdsaleState {
        require(state == State.PreSale || state == State.Sale);
        _;
    }

    modifier saleFailedState {
        require(state == State.SaleFailed);
        _;
    }

    modifier completedSaleState {
        require(state == State.CrowdsaleCompleted);
        _;
    }
}

contract Token is Crowdsale, ERC20 {

    mapping(address => uint) internal balances;
    mapping(address => mapping(address => uint)) public allowed;
    uint8 public constant decimals = 8;

    function Token() payable Crowdsale() {}

    function balanceOf(address who) constant returns(uint) {
        return balances[who];
    }

    function transfer(address _to, uint _value) public completedSaleState onlyPayloadSize(2 * 32) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]); // overflow
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public completedSaleState onlyPayloadSize(3 * 32) {
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]); // overflow
        require(allowed[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public completedSaleState {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant completedSaleState returns(uint remaining) {
        return allowed[_owner][_spender];
    }

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
}

contract MigratableToken is Token {

    function MigratableToken() payable Token() {}

    bool stateMigrated = false;
    address public migrationAgent;
    uint public totalMigrated;
    address public migrationHost;
    mapping(address => bool) migratedInvestors;

    event Migrated(address indexed from, address indexed to, uint value);

    function setMigrationHost(address _address) external onlyOwner {
        require(_address != 0);
        migrationHost = _address;
    }

    function migrateStateFromHost() external onlyOwner {
        require(stateMigrated == false && migrationHost != 0);

        PreArtexToken preArtex = PreArtexToken(migrationHost);

        state = Stateful.State.PreSale;

        etherPriceUSDWEI = preArtex.etherPriceUSDWEI();
        beneficiary = preArtex.beneficiary();
        totalLimitUSDWEI = preArtex.totalLimitUSDWEI();
        minimalSuccessUSDWEI = preArtex.minimalSuccessUSDWEI();
        collectedUSDWEI = preArtex.collectedUSDWEI();

        crowdsaleStartTime = preArtex.crowdsaleStartTime();
        crowdsaleFinishTime = preArtex.crowdsaleFinishTime();

        stateMigrated = true;
    }

    function migrateInvestorsFromHost(uint batchSize) external onlyOwner {
        require(migrationHost != 0);

        PreArtexToken preArtex = PreArtexToken(migrationHost);

        uint numberOfInvestorsToMigrate = preArtex.numberOfInvestors();
        uint currentNumberOfInvestors = numberOfInvestors;

        require(currentNumberOfInvestors < numberOfInvestorsToMigrate);

        for (uint i = 0; i < batchSize; i++) {
            uint index = currentNumberOfInvestors + i;
            if (index < numberOfInvestorsToMigrate) {
                address investor = preArtex.investorsIter(index);
                migrateInvestorsFromHostInternal(investor, preArtex);                
            }
            else
                break;
        }
    }

    function migrateInvestorFromHost(address _address) external onlyOwner {
        require(migrationHost != 0);

        PreArtexToken preArtex = PreArtexToken(migrationHost);

        migrateInvestorsFromHostInternal(_address, preArtex);
    }

    function migrateInvestorsFromHostInternal(address _address, PreArtexToken preArtex) internal {
        require(state != State.SaleFailed && migratedInvestors[_address] == false);

        var (tokensToTransfer, weiToTransfer) = preArtex.investors(_address);

        require(tokensToTransfer > 0);

        balances[_address] = tokensToTransfer;
        totalSupply += tokensToTransfer;
        migratedInvestors[_address] = true;

        if (state != State.CrowdsaleCompleted) {
            Investor storage investor = investors[_address];
            investorsIter[numberOfInvestors] = _address;
            
            numberOfInvestors++;

            investor.amountTokens += tokensToTransfer;
            investor.amountWei += weiToTransfer;
        }

        Transfer(this, _address, tokensToTransfer);
    }

    //migration by investor
    function migrate() external {
        require(migrationAgent != 0);
        uint value = balances[msg.sender];
        balances[msg.sender] -= value;
        Transfer(msg.sender, this, value);
        totalSupply -= value;
        totalMigrated += value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, value);
        Migrated(msg.sender, migrationAgent, value);
    }

    function setMigrationAgent(address _agent) external onlyOwner {
        require(migrationAgent == 0);
        migrationAgent = _agent;
    }
}

contract ArtexToken is MigratableToken {

    string public constant symbol = "ARX";

    string public constant name = "Artex Token";

    mapping(address => bool) public allowedContracts;

    function ArtexToken() payable MigratableToken() {}

    function emitTokens(address _investor, uint _valueUSDWEI) internal returns(uint tokensToEmit) {
        tokensToEmit = getTokensToEmit(_valueUSDWEI);
        require(balances[_investor] + tokensToEmit > balances[_investor]); // overflow
        require(tokensToEmit > 0);
        balances[_investor] += tokensToEmit;
        totalSupply += tokensToEmit;
        Transfer(this, _investor, tokensToEmit);
    }

    function getTokensToEmit(uint _valueUSDWEI) internal constant returns (uint) {
        uint percentWithBonus;
        if (state == State.PreSale) {
            percentWithBonus = 130;
        } else if (state == State.Sale) {
            if (_valueUSDWEI < 1000 * 1 ether)
                percentWithBonus = 100;
            else if (_valueUSDWEI < 5000 * 1 ether)
                percentWithBonus = 103;
            else if (_valueUSDWEI < 10000 * 1 ether)
                percentWithBonus = 105;
            else if (_valueUSDWEI < 50000 * 1 ether)
                percentWithBonus = 110;
            else if (_valueUSDWEI < 100000 * 1 ether)
                percentWithBonus = 115;
            else
                percentWithBonus = 120;
        }

        return (_valueUSDWEI * percentWithBonus * (10 ** uint(decimals))) / (tokenPriceUSDWEI * 100);
    }

    function emitAdditionalTokens() internal {
        uint tokensToEmit = totalSupply * 100 / 74 - totalSupply;
        require(balances[beneficiary] + tokensToEmit > balances[beneficiary]); // overflow
        require(tokensToEmit > 0);
        balances[beneficiary] += tokensToEmit;
        totalSupply += tokensToEmit;
        Transfer(this, beneficiary, tokensToEmit);
    }

    function burnTokens(address _address, uint _amount) internal {
        balances[_address] -= _amount;
        totalSupply -= _amount;
        Transfer(_address, this, _amount);
    }

    function addAllowedContract(address _address) external onlyOwner {
        require(_address != 0);
        allowedContracts[_address] = true;
    }

    function removeAllowedContract(address _address) external onlyOwner {
        require(_address != 0);
        delete allowedContracts[_address];
    }

    function transferToKnownContract(address _to, uint256 _value, bytes32[] _data) external onlyAllowedContracts(_to) {
        var knownContract = KnownContract(_to);
        transfer(_to, _value);
        knownContract.transfered(msg.sender, _value, _data);
    }

    modifier onlyAllowedContracts(address _address) {
        require(allowedContracts[_address] == true);
        _;
    }
}