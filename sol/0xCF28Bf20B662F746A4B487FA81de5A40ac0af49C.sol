/*
    Gold Reserve [XGR]
    1.0.0
    
    Rajci 'iFA' Andor @ ifa@fusionwallet.io
*/
pragma solidity 0.4.18;

contract SafeMath {
    /* Internals */
    function safeAdd(uint256 a, uint256 b) internal pure returns(uint256) {
        if ( b > 0 ) {
            assert( a + b > a );
        }
        return a + b;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns(uint256) {
        if ( b > 0 ) {
            assert( a - b < a );
        }
        return a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns(uint256) {
        return a / b;
    }
}

contract Owned {
    /* Variables */
    address public owner = msg.sender;
    /* Externals */
    function replaceOwner(address newOwner) external returns(bool success) {
        require( isOwner() );
        owner = newOwner;
        return true;
    }
    /* Internals */
    function isOwner() internal view returns(bool) {
        return owner == msg.sender;
    }
    /* Modifiers */
    modifier onlyForOwner {
        require( isOwner() );
        _;
    }
}

contract Token is SafeMath, Owned {
    /**
    * @title Gold Reserve [XGR] token
    */
    /* Variables */
    string  public name = "GoldReserve";
    string  public symbol = "XGR";
    uint8   public decimals = 8;
    uint256 public transactionFeeRate   = 20; // 0.02 %
    uint256 public transactionFeeRateM  = 1e3; // 1000
    uint256 public transactionFeeMin    =   2000000; // 0.2 XGR
    uint256 public transactionFeeMax    = 200000000; // 2.0 XGR
    address public databaseAddress;
    address public depositsAddress;
    address public forkAddress;
    address public libAddress;
    /* Constructor */
    function Token(address newDatabaseAddress, address newDepositAddress, address newFrokAddress, address newLibAddress) public {
        databaseAddress = newDatabaseAddress;
        depositsAddress = newDepositAddress;
        forkAddress = newFrokAddress;
        libAddress = newLibAddress;
    }
    /* Fallback */
    function () {
        revert();
    }
    /* Externals */
    function changeDataBaseAddress(address newDatabaseAddress) external onlyForOwner {
        databaseAddress = newDatabaseAddress;
    }
    function changeDepositsAddress(address newDepositsAddress) external onlyForOwner {
        depositsAddress = newDepositsAddress;
    }
    function changeForkAddress(address newForkAddress) external onlyForOwner {
        forkAddress = newForkAddress;
    }
    function changeLibAddress(address newLibAddress) external onlyForOwner {
        libAddress = newLibAddress;
    }
    function changeFees(uint256 rate, uint256 rateMultiplier, uint256 min, uint256 max) external onlyForOwner {
        transactionFeeRate = rate;
        transactionFeeRateM = rateMultiplier;
        transactionFeeMin = min;
        transactionFeeMax = max;
    }
    /**
     * @notice `msg.sender` approves `spender` to spend `amount` tokens on its behalf.
     * @param spender The address of the account able to transfer the tokens
     * @param amount The amount of tokens to be approved for transfer
     * @param nonce The transaction count of the authorised address
     * @return True if the approval was successful
     */
    function approve(address spender, uint256 amount, uint256 nonce) external returns (bool success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x20)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                invalid
            } default {
                return(m, 0x20)
            }
        }
    }
    /**
     * @notice `msg.sender` approves `spender` to spend `amount` tokens on its behalf and notify the spender from your approve with your `extraData` data.
     * @param spender The address of the account able to transfer the tokens
     * @param amount The amount of tokens to be approved for transfer
     * @param nonce The transaction count of the authorised address
     * @param extraData Data to give forward to the receiver
     * @return True if the approval was successful
     */
    function approveAndCall(address spender, uint256 amount, uint256 nonce, bytes extraData) external returns (bool success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x20)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                invalid
            } default {
                return(m, 0x20)
            }
        }
    }
    /**
     * @notice Send `amount` tokens to `to` from `msg.sender`
     * @param to The address of the recipient
     * @param amount The amount of tokens to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address to, uint256 amount) external returns (bool success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x20)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                invalid
            } default {
                return(m, 0x20)
            }
        }
    }
    /**
     * @notice Send `amount` tokens to `to` from `from` on the condition it is approved by `from`
     * @param from The address holding the tokens being transferred
     * @param to The address of the recipient
     * @param amount The amount of tokens to be transferred
     * @return True if the transfer was successful
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x20)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                invalid
            } default {
                return(m, 0x20)
            }
        }
    }
    /**
     * @notice Send `amount` tokens to `to` from `msg.sender` and notify the receiver from your transaction with your `extraData` data
     * @param to The contract address of the recipient
     * @param amount The amount of tokens to be transferred
     * @param extraData Data to give forward to the receiver
     * @return Whether the transfer was successful or not
     */
    function transfer(address to, uint256 amount, bytes extraData) external returns (bool success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x20)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                invalid
            } default {
                return(m, 0x20)
            }
        }
    }
    function mint(address owner, uint256 value) external returns (bool success) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x20)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                invalid
            } default {
                return(m, 0x20)
            }
        }
    }
    /* Internals */
    /* Constants */
    function allowance(address owner, address spender) public constant returns (uint256 remaining, uint256 nonce) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x20)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x40)
            switch success case 0 {
                invalid
            } default {
                return(m, 0x40)
            }
        }
    }
    function getTransactionFee(uint256 value) public constant returns (bool success, uint256 fee) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x20)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x40)
            switch success case 0 {
                invalid
            } default {
                return(m, 0x40)
            }
        }
    }
    function balanceOf(address owner) public constant returns (uint256 value) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x20)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                invalid
            } default {
                return(m, 0x20)
            }
        }
    }
    function balancesOf(address owner) public constant returns (uint256 balance, uint256 lockedAmount) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x20)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x40)
            switch success case 0 {
                invalid
            } default {
                return(m, 0x40)
            }
        }
    }
    function totalSupply() public constant returns (uint256 value) {
        address _trg = libAddress;
        assembly {
            let m := mload(0x20)
            calldatacopy(m, 0, calldatasize)
            let success := delegatecall(gas, _trg, m, calldatasize, m, 0x20)
            switch success case 0 {
                invalid
            } default {
                return(m, 0x20)
            }
        }
    }
    /* Events */
    event AllowanceUsed(address indexed spender, address indexed owner, uint256 indexed value);
    event Mint(address indexed addr, uint256 indexed value);
    event Burn(address indexed addr, uint256 indexed value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Transfer2(address indexed from, address indexed to, uint256 indexed value, bytes data);
}

contract TokenDB is SafeMath, Owned {
    /* Structures */
    struct allowance_s {
        uint256 amount;
        uint256 nonce;
    }
    struct deposits_s {
        address addr;
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 interestOnEnd;
        uint256 interestBeforeEnd;
        uint256 interestFee;
        uint256 interestMultiplier;
        bool    closeable;
        bool    valid;
    }
    /* Variables */
    mapping(address => mapping(address => allowance_s)) public allowance;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => deposits_s) private deposits;
    mapping(address => uint256) public lockedBalances;
    address public tokenAddress;
    address public depositsAddress;
    uint256 public depositsCounter;
    uint256 public totalSupply;
    /* Constructor */
    /* Externals */
    function changeTokenAddress(address newTokenAddress) external onlyForOwner {
        tokenAddress = newTokenAddress;
    }
    function changeDepositsAddress(address newDepositsAddress) external onlyForOwner {
        depositsAddress = newDepositsAddress;
    }
    function openDeposit(address addr, uint256 amount, uint256 end, uint256 interestOnEnd,
        uint256 interestBeforeEnd, uint256 interestFee, uint256 multiplier, bool closeable) external onlyForDeposits returns(bool success, uint256 DID) {
        depositsCounter += 1;
        DID = depositsCounter;
        lockedBalances[addr] = safeAdd(lockedBalances[addr], amount);
        deposits[DID] = deposits_s(
            addr,
            amount,
            block.number,
            end,
            interestOnEnd,
            interestBeforeEnd,
            interestFee,
            multiplier,
            closeable,
            true
        );
        return (true, DID);
    }
    function closeDeposit(uint256 DID) external onlyForDeposits returns (bool success) {
        require( deposits[DID].valid );
        delete deposits[DID].valid;
        lockedBalances[deposits[DID].addr] = safeSub(lockedBalances[deposits[DID].addr], deposits[DID].amount);
        return true;
    }
    function transfer(address from, address to, uint256 amount, uint256 fee) external onlyForToken returns(bool success) {
        balanceOf[from] = safeSub(balanceOf[from], safeAdd(amount, fee));
        balanceOf[to] = safeAdd(balanceOf[to], amount);
        totalSupply = safeSub(totalSupply, fee);
        return true;
    }
    function increase(address owner, uint256 value) external onlyForToken returns(bool success) {
        balanceOf[owner] = safeAdd(balanceOf[owner], value);
        totalSupply = safeAdd(totalSupply, value);
        return true;
    }
    function decrease(address owner, uint256 value) external onlyForToken returns(bool success) {
        require( safeSub(balanceOf[owner], safeAdd(lockedBalances[owner], value)) >= 0 );
        balanceOf[owner] = safeSub(balanceOf[owner], value);
        totalSupply = safeSub(totalSupply, value);
        return true;
    }
    function setAllowance(address owner, address spender, uint256 amount, uint256 nonce) external onlyForToken returns(bool success) {
        allowance[owner][spender].amount = amount;
        allowance[owner][spender].nonce = nonce;
        return true;
    }
    /* Constants */
    function getAllowance(address owner, address spender) public constant returns(bool success, uint256 remaining, uint256 nonce) {
        return ( true, allowance[owner][spender].amount, allowance[owner][spender].nonce );
    }
    function getDeposit(uint256 UID) public constant returns(address addr, uint256 amount, uint256 start,
        uint256 end, uint256 interestOnEnd, uint256 interestBeforeEnd, uint256 interestFee, uint256 interestMultiplier, bool closeable, bool valid) {
        addr = deposits[UID].addr;
        amount = deposits[UID].amount;
        start = deposits[UID].start;
        end = deposits[UID].end;
        interestOnEnd = deposits[UID].interestOnEnd;
        interestBeforeEnd = deposits[UID].interestBeforeEnd;
        interestFee = deposits[UID].interestFee;
        interestMultiplier = deposits[UID].interestMultiplier;
        closeable = deposits[UID].closeable;
        valid = deposits[UID].valid;
    }
    /* Modifiers */
    modifier onlyForToken {
        require( msg.sender == tokenAddress );
        _;
    }
    modifier onlyForDeposits {
        require( msg.sender == depositsAddress );
        _;
    }
}

contract TokenLib is SafeMath, Owned {
    /**
    * @title Gold Reserve [XGR] token
    */
    /* Variables */
    string  public name = "GoldReserve";
    string  public symbol = "XGR";
    uint8   public decimals = 8;
    uint256 public transactionFeeRate   = 20; // 0.02 %
    uint256 public transactionFeeRateM  = 1e3; // 1000
    uint256 public transactionFeeMin    =   2000000; // 0.2 XGR
    uint256 public transactionFeeMax    = 200000000; // 2.0 XGR
    address public databaseAddress;
    address public depositsAddress;
    address public forkAddress;
    address public libAddress;
    /* Constructor */
    function TokenLib(address newDatabaseAddress, address newDepositAddress, address newFrokAddress, address newLibAddress) public {
        databaseAddress = newDatabaseAddress;
        depositsAddress = newDepositAddress;
        forkAddress = newFrokAddress;
        libAddress = newLibAddress;
    }
    /* Fallback */
    function () public {
        revert();
    }
    /* Externals */
    function changeDataBaseAddress(address newDatabaseAddress) external onlyForOwner {
        databaseAddress = newDatabaseAddress;
    }
    function changeDepositsAddress(address newDepositsAddress) external onlyForOwner {
        depositsAddress = newDepositsAddress;
    }
    function changeForkAddress(address newForkAddress) external onlyForOwner {
        forkAddress = newForkAddress;
    }
    function changeLibAddress(address newLibAddress) external onlyForOwner {
        libAddress = newLibAddress;
    }
    function changeFees(uint256 rate, uint256 rateMultiplier, uint256 min, uint256 max) external onlyForOwner {
        transactionFeeRate = rate;
        transactionFeeRateM = rateMultiplier;
        transactionFeeMin = min;
        transactionFeeMax = max;
    }
    function approve(address spender, uint256 amount, uint256 nonce) external returns (bool success) {
        _approve(spender, amount, nonce);
        return true;
    }
    function approveAndCall(address spender, uint256 amount, uint256 nonce, bytes extraData) external returns (bool success) {
        _approve(spender, amount, nonce);
        require( checkContract(spender) );
        require( SampleContract(spender).approvedToken(msg.sender, amount, extraData) );
        return true;
    }
    function transfer(address to, uint256 amount) external returns (bool success) {
        bytes memory _data;
        _transfer(msg.sender, to, amount, true, _data);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) external returns (bool success) {
        if ( from != msg.sender ) {
            var (_success, _reamining, _nonce) = TokenDB(databaseAddress).getAllowance(from, msg.sender);
            require( _success );
            _reamining = safeSub(_reamining, amount);
            _nonce = safeAdd(_nonce, 1);
            require( TokenDB(databaseAddress).setAllowance(from, msg.sender, _reamining, _nonce) );
            AllowanceUsed(msg.sender, from, amount);
        }
        bytes memory _data;
        _transfer(from, to, amount, true, _data);
        return true;
    }
    function transfer(address to, uint256 amount, bytes extraData) external returns (bool success) {
        _transfer(msg.sender, to, amount, true, extraData);
        return true;
    }
    function mint(address owner, uint256 value) external returns (bool success) {
        require( msg.sender == forkAddress || msg.sender == depositsAddress );
        _mint(owner, value);
        return true;
    }
    /* Internals */
    function _transfer(address from, address to, uint256 amount, bool fee, bytes extraData) internal {
        bool _success;
        uint256 _fee;
        uint256 _payBack;
        uint256 _amount = amount;
        require( from != 0x00 && to != 0x00 );
        if( fee ) {
            (_success, _fee) = getTransactionFee(amount);
            require( _success );
            if ( TokenDB(databaseAddress).balanceOf(from) == amount ) {
                _amount = safeSub(amount, _fee);
            }
        }
        if ( fee ) {
            Burn(from, _fee);
        }
        Transfer(from, to, _amount);
        Transfer2(from, to, _amount, extraData);
        require( TokenDB(databaseAddress).transfer(from, to, _amount, _fee) );
        if ( isContract(to) ) {
            require( checkContract(to) );
            (_success, _payBack) = SampleContract(to).receiveToken(from, amount, extraData);
            require( _success );
            require( amount > _payBack );
            if ( _payBack > 0 ) {
                bytes memory _data;
                Transfer(to, from, _payBack);
                Transfer2(to, from, _payBack, _data);
                require( TokenDB(databaseAddress).transfer(to, from, _payBack, 0) );
            }
        }
    }
    function _mint(address owner, uint256 value) internal {
        require( TokenDB(databaseAddress).increase(owner, value) );
        Mint(owner, value);
    }
    function _approve(address spender, uint256 amount, uint256 nonce) internal {
        require( msg.sender != spender );
        var (_success, _remaining, _nonce) = TokenDB(databaseAddress).getAllowance(msg.sender, spender);
        require( _success && ( _nonce == nonce ) );
        require( TokenDB(databaseAddress).setAllowance(msg.sender, spender, amount, nonce) );
        Approval(msg.sender, spender, amount);
    }
    function isContract(address addr) internal view returns (bool success) {
        uint256 _codeLength;
        assembly {
            _codeLength := extcodesize(addr)
        }
        return _codeLength > 0;
    }
    function checkContract(address addr) internal view returns (bool appropriate) {
        return SampleContract(addr).XGRAddress() == address(this);
    }
    /* Constants */
    function allowance(address owner, address spender) public constant returns (uint256 remaining, uint256 nonce) {
        var (_success, _remaining, _nonce) = TokenDB(databaseAddress).getAllowance(owner, spender);
        require( _success );
        return (_remaining, _nonce);
    }
    function getTransactionFee(uint256 value) public constant returns (bool success, uint256 fee) {
        fee = safeMul(value, transactionFeeRate) / transactionFeeRateM / 100;
        if ( fee > transactionFeeMax ) { fee = transactionFeeMax; }
        else if ( fee < transactionFeeMin ) { fee = transactionFeeMin; }
        return (true, fee);
    }
    function balanceOf(address owner) public constant returns (uint256 value) {
        return TokenDB(databaseAddress).balanceOf(owner);
    }
    function balancesOf(address owner) public constant returns (uint256 balance, uint256 lockedAmount) {
        return (TokenDB(databaseAddress).balanceOf(owner), TokenDB(databaseAddress).lockedBalances(owner));
    }
    function totalSupply() public constant returns (uint256 value) {
        return TokenDB(databaseAddress).totalSupply();
    }
    /* Events */
    event AllowanceUsed(address indexed spender, address indexed owner, uint256 indexed value);
    event Mint(address indexed addr, uint256 indexed value);
    event Burn(address indexed addr, uint256 indexed value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Transfer2(address indexed from, address indexed to, uint256 indexed value, bytes data);
}

contract Deposits is Owned, SafeMath {
    /* Structures */
    struct depositTypes_s {
        uint256 blockDelay;
        uint256 baseFunds;
        uint256 interestRateOnEnd;
        uint256 interestRateBeforeEnd;
        uint256 interestFee;
        bool closeable;
        bool valid;
    }
    struct deposits_s {
        address addr;
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 interestOnEnd;
        uint256 interestBeforeEnd;
        uint256 interestFee;
        uint256 interestMultiplier;
        bool    closeable;
        bool    valid;
    }
    /* Variables */
    mapping(uint256 => depositTypes_s) public depositTypes;
    uint256 public depositTypesCounter;
    address public tokenAddress;
    address public databaseAddress;
    address public founderAddress;
    uint256 public interestMultiplier = 1e4;
    /* Externals */
    function changeDataBaseAddress(address newDatabaseAddress) external onlyForOwner {
        databaseAddress = newDatabaseAddress;
    }
    function changeTokenAddress(address newTokenAddress) external onlyForOwner {
        tokenAddress = newTokenAddress;
    }
    function changeFounderAddresss(address newFounderAddress) external onlyForOwner {
        founderAddress = newFounderAddress;
    }
    function addDepositType(uint256 blockDelay, uint256 baseFunds, uint256 interestRateOnEnd,
        uint256 interestRateBeforeEnd, uint256 interestFee, bool closeable) external onlyForOwner {
        depositTypesCounter += 1;
        uint256 DTID = depositTypesCounter;
        depositTypes[DTID] = depositTypes_s(
            blockDelay,
            baseFunds,
            interestRateOnEnd,
            interestRateBeforeEnd,
            interestFee,
            closeable,
            true
        );
        EventNewDepositType(
            DTID,
            blockDelay,
            baseFunds,
            interestRateOnEnd,
            interestRateBeforeEnd,
            interestFee,
            closeable
        );
    }
    function rekoveDepositType(uint256 DTID) external onlyForOwner {
        depositTypes[DTID].valid = false;
    }
    function placeDeposit(uint256 amount, uint256 depositType) external checkSelf {
        require( depositTypes[depositType].valid );
        require( depositTypes[depositType].baseFunds <= amount );
        uint256 balance = TokenDB(databaseAddress).balanceOf(msg.sender);
        uint256 locked = TokenDB(databaseAddress).lockedBalances(msg.sender);
        require( safeSub(balance, locked) >= amount );
        var (success, DID) = TokenDB(databaseAddress).openDeposit(
            msg.sender,
            amount,
            safeAdd(block.number, depositTypes[depositType].blockDelay),
            depositTypes[depositType].interestRateOnEnd,
            depositTypes[depositType].interestRateBeforeEnd,
            depositTypes[depositType].interestFee,
            interestMultiplier,
            depositTypes[depositType].closeable
        );
        require( success );
        EventNewDeposit(DID);
    }
    function closeDeposit(address beneficary, uint256 DID) external checkSelf {
        address _beneficary = beneficary;
        if ( _beneficary == 0x00 ) {
            _beneficary = msg.sender;
        }
        var (addr, amount, start, end, interestOnEnd, interestBeforeEnd, interestFee,
            interestM, closeable, valid) = TokenDB(databaseAddress).getDeposit(DID);
        _closeDeposit(_beneficary, DID, deposits_s(addr, amount, start, end, interestOnEnd, interestBeforeEnd, interestFee, interestM, closeable, valid));
    }
    /* Internals */
    function _closeDeposit(address beneficary, uint256 DID, deposits_s data) internal {
        require( data.valid && data.addr == msg.sender );
        var (interest, interestFee) = _calculateInterest(data);
        if ( interest > 0 ) {
            require( Token(tokenAddress).mint(beneficary, interest) );
        }
        if ( interestFee > 0 ) {
            require( Token(tokenAddress).mint(founderAddress, interestFee) );
        }
        require( TokenDB(databaseAddress).closeDeposit(DID) );
        EventDepositClosed(DID, interest, interestFee);
    }
    function _calculateInterest(deposits_s data) internal view returns (uint256 interest, uint256 interestFee) {
        if ( ! data.valid || data.amount <= 0 || data.end <= data.start || block.number <= data.start ) { return (0, 0); }
        uint256 rate;
        uint256 delay;
        if ( data.end <= block.number ) {
            rate = data.interestOnEnd;
            delay = safeSub(data.end, data.start);
        } else {
            require( data.closeable );
            rate = data.interestBeforeEnd;
            delay = safeSub(block.number, data.start);
        }
        if ( rate == 0 ) { return (0, 0); }
        interest = safeDiv(safeMul(safeDiv(safeDiv(safeMul(data.amount, rate), 100), data.interestMultiplier), delay), safeSub(data.end, data.start));
        if ( data.interestFee > 0 && interest > 0) {
            interestFee = safeDiv(safeDiv(safeMul(interest, data.interestFee), 100), data.interestMultiplier);
        }
        if ( interestFee > 0 ) {
            interest = safeSub(interest, interestFee);
        }
    }
    /* Constants */
    function calculateInterest(uint256 DID) public view returns(uint256, uint256) {
        var (addr, amount, start, end, interestOnEnd, interestBeforeEnd, interestFee,
            interestM, closeable, valid) = TokenDB(databaseAddress).getDeposit(DID);
        return _calculateInterest(deposits_s(addr, amount, start, end, interestOnEnd, interestBeforeEnd, interestFee, interestM, closeable, valid));
    }
    /* Modifiers */
    modifier checkSelf {
        require( TokenDB(databaseAddress).tokenAddress() == tokenAddress );
        require( TokenDB(databaseAddress).depositsAddress() == address(this) );
        _;
    }
    /* Events */
    event EventNewDepositType(uint256 indexed DTID, uint256 blockDelay, uint256 baseFunds,
        uint256 interestRateOnEnd, uint256 interestRateBeforeEnd, uint256 interestFee, bool closeable);
    event EventRevokeDepositType(uint256 indexed DTID);
    event EventNewDeposit(uint256 indexed DID);
    event EventDepositClosed(uint256 indexed DID, uint256 indexed interest, uint256 indexed interestFee);
}

contract Fork is Owned {
    /* Variables */
    address public uploader;
    address public tokenAddress;
    /* Constructor */
    function Fork(address _uploader) public {
        uploader = _uploader;
    }
    /* Externals */
    function changeTokenAddress(address newTokenAddress) external onlyForOwner {
        tokenAddress = newTokenAddress;
    }
    function upload(address[] addr, uint256[] amount) external onlyForUploader {
        require( addr.length == amount.length );
        for ( uint256 a=0 ; a<addr.length ; a++ ) {
            require( Token(tokenAddress).mint(addr[a], amount[a]) );
        }
    }
    /* Modifiers */
    modifier onlyForUploader {
        require( msg.sender == uploader );
        _;
    }
}

contract SampleContract is Owned, SafeMath {
    /* Variables */
    mapping(address => uint256) public deposits; // Database of users balance
    address public XGRAddress; // XGR Token address, please do not change this variable name!
    /* Constructor */
    function SampleContract(address newXGRTokenAddress) public {
        /*
            For the first time you need set the XGR token address.
            The contract deployer would be also the owner.
        */
        XGRAddress = newXGRTokenAddress;
    }
    /* Externals */
    function receiveToken(address addr, uint256 amount, bytes data) external onlyFromXGRToken returns(bool, uint256) {
        /*
            @addr has send @amount to ourself. The second return parameter is the refund amount.
            If you don't need the whole amount, you can refund that for the address instantly.
            Please do not change this function name and parameter!
        */
        incomingToken(addr, amount);
        return (true, 0);
    }
    function approvedToken(address addr, uint256 amount, bytes data) external onlyFromXGRToken returns(bool) {
        /*
            @addr has allowed @amount for withdraw from her/his balance. We withdraw that to ourself.
            Please do not change this function name and parameter!
        */
        require( Token(XGRAddress).transferFrom(addr, address(this), amount) );
        incomingToken(addr, amount);
        return true;
    }
    function changeTokenAddress(address newTokenAddress) external onlyForOwner {
        /*
            Maybe the XGR token contract becomes new address, you need maintenance this.
        */
        XGRAddress = newTokenAddress;
    }
    function killThisContract() external onlyForOwner {
        var balance = Token(XGRAddress).balanceOf(address(this)); // get this contract XGR balance
        require( Token(XGRAddress).transfer(msg.sender, balance) ); // send all XGR token to the caller
        selfdestruct(msg.sender); // destruct the contract;
    }
    function withdraw(uint256 amount) external {
        /*
            Some users withdraw XGR token from this contract.
            The contract must pay the XGR token fee, we need to reduce that from the amount;
        */
        var (success, fee) = Token(XGRAddress).getTransactionFee(amount); // Get the transfer fee from the contract
        require( success );
        withdrawToken(msg.sender, amount);
        require( Token(XGRAddress).transfer(msg.sender, safeSub(amount, fee)) );
    }
    /* Internals */
    function incomingToken(address addr, uint256 amount) internal {
        deposits[addr] = safeAdd(deposits[addr], amount);
    }
    function withdrawToken(address addr, uint256 amount) internal {
        deposits[addr] = safeSub(deposits[addr], amount);
    }
    /* Modifiers */
    modifier onlyFromXGRToken {
        require( msg.sender == XGRAddress );
        _;
    }
}