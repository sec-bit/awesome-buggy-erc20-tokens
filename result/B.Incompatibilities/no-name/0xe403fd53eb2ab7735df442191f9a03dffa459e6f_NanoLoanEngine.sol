pragma solidity ^0.4.15;

contract Oracle {
    event NewSymbol(string _symbol, uint8 _decimals);
    function getTimestamp(string symbol) constant returns(uint256);
    function getRateFor(string symbol) returns (uint256);
    function getCost(string symbol) constant returns (uint256);
    function getDecimals(string symbol) constant returns (uint256);
}

contract Token {
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    function approve(address _spender, uint256 _value) returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) constant returns (uint256 balance);
}

contract RpSafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

    function min(uint256 a, uint256 b) internal returns(uint256) {
        if (a < b) { 
          return a;
        } else { 
          return b; 
        }
    }
    
    function max(uint256 a, uint256 b) internal returns(uint256) {
        if (a > b) { 
          return a;
        } else { 
          return b; 
        }
    }
}


contract NanoLoanEngine is RpSafeMath {
    uint256 public constant VERSION = 15;
    
    Token public token;

    enum Status { initial, lent, paid, destroyed }

    address public owner;
    bool public deprecated;
    uint256 public totalLenderBalance;

    event CreatedLoan(uint _index, address _borrower, address _creator);
    event ApprovedBy(uint _index, address _address);
    event Lent(uint _index, address _lender);
    event CreatedDebt(uint _index, address _lend);
    event DestroyedBy(uint _index, address _address);
    event PartialPayment(uint _index, address _sender, address _from, uint256 _amount);
    event Transfer(uint _index, address _from, address _to);
    event TotalPayment(uint _index);

    function NanoLoanEngine(Token _token) {
        owner = msg.sender;
        token = _token;
    }

    struct Loan {
        Oracle oracle;

        Status status;

        address borrower;
        address cosigner;
        address lender;
        address creator;
        
        uint256 amount;
        uint256 interest;
        uint256 punitoryInterest;
        uint256 interestTimestamp;
        uint256 paid;
        uint256 cosignerFee;
        uint256 interestRate;
        uint256 interestRatePunitory;
        uint256 dueTime;
        uint256 duesIn;

        string currency;
        uint256 cancelableAt;
        uint256 lenderBalance;

        address approvedTransfer;
        uint256 expirationRequest;

        mapping(address => bool) approbations;
    }

    Loan[] private loans;

    // _oracleContract: Address of the Oracle contract, must implement OracleInterface. 0x0 for no oracle
    // _cosigner: Responsable of the payment of the loan if the lender does not pay. 0x0 for no cosigner
    // _cosignerFee: absolute amount in currency
    // _interestRate: 100 000 / interest; ej 100 000 = 100 %; 10 000 000 = 1% (by second)
    function createLoan(Oracle _oracleContract, address _borrower, address _cosigner,
        uint256 _cosignerFee, string _currency, uint256 _amount, uint256 _interestRate,
        uint256 _interestRatePunitory, uint256 _duesIn, uint256 _cancelableAt, uint256 _expirationRequest) returns (uint256) {

        require(!deprecated);
        require(_cancelableAt <= _duesIn);
        require(_oracleContract != address(0) || bytes(_currency).length == 0);
        require(_cosigner != address(0) || _cosignerFee == 0);
        require(_borrower != address(0));
        require(_amount != 0);
        require(_interestRatePunitory != 0);
        require(_interestRate != 0);
        require(_expirationRequest > block.timestamp);

        var loan = Loan(_oracleContract, Status.initial, _borrower, _cosigner, 0x0, msg.sender, _amount,
            0, 0, 0, 0, _cosignerFee, _interestRate, _interestRatePunitory, 0, _duesIn, _currency, _cancelableAt, 0, 0x0, _expirationRequest);
        uint index = loans.push(loan) - 1;
        CreatedLoan(index, _borrower, msg.sender);
        return index;
    }
    
    function getLoanConfig(uint index) constant returns (address oracle, address borrower, address lender, address creator, uint amount, 
        uint cosignerFee, uint interestRate, uint interestRatePunitory, uint duesIn, uint cancelableAt, uint decimals, bytes32 currencyHash, uint256 expirationRequest) {
        Loan storage loan = loans[index];
        oracle = loan.oracle;
        borrower = loan.borrower;
        lender = loan.lender;
        creator = loan.creator;
        amount = loan.amount;
        cosignerFee = loan.cosignerFee;
        interestRate = loan.interestRate;
        interestRatePunitory = loan.interestRatePunitory;
        duesIn = loan.duesIn;
        cancelableAt = loan.cancelableAt;
        decimals = loan.oracle.getDecimals(loan.currency);
        currencyHash = keccak256(loan.currency); 
        expirationRequest = loan.expirationRequest;
    }

    function getLoanState(uint index) constant returns (uint interest, uint punitoryInterest, uint interestTimestamp,
        uint paid, uint dueTime, Status status, uint lenderBalance, address approvedTransfer, bool approved) {
        Loan storage loan = loans[index];
        interest = loan.interest;
        punitoryInterest = loan.punitoryInterest;
        interestTimestamp = loan.interestTimestamp;
        paid = loan.paid;
        dueTime = loan.dueTime;
        status = loan.status;
        lenderBalance = loan.lenderBalance;
        approvedTransfer = loan.approvedTransfer;
        approved = isApproved(index);
    }
    
    function getTotalLoans() constant returns (uint256) { return loans.length; }
    function getOracle(uint index) constant returns (Oracle) { return loans[index].oracle; }
    function getBorrower(uint index) constant returns (address) { return loans[index].borrower; }
    function getCosigner(uint index) constant returns (address) { return loans[index].cosigner; }
    function getLender(uint index) constant returns (address) { return loans[index].lender; }
    function getCreator(uint index) constant returns (address) { return loans[index].creator; }
    function getAmount(uint index) constant returns (uint256) { return loans[index].amount; }
    function getInterest(uint index) constant returns (uint256) { return loans[index].interest; }
    function getPunitoryInterest(uint index) constant returns (uint256) { return loans[index].punitoryInterest; }
    function getInterestTimestamp(uint index) constant returns (uint256) { return loans[index].interestTimestamp; }
    function getPaid(uint index) constant returns (uint256) { return loans[index].paid; }
    function getCosignerFee(uint index) constant returns (uint256) { return loans[index].cosignerFee; }
    function getInterestRate(uint index) constant returns (uint256) { return loans[index].interestRate; }
    function getInterestRatePunitory(uint index) constant returns (uint256) { return loans[index].interestRatePunitory; }
    function getDueTime(uint index) constant returns (uint256) { return loans[index].dueTime; }
    function getDuesIn(uint index) constant returns (uint256) { return loans[index].duesIn; }
    function getCurrency(uint index) constant returns (string) { return loans[index].currency; }
    function getCancelableAt(uint index) constant returns (uint256) { return loans[index].cancelableAt; }
    function getApprobation(uint index, address _address) constant returns (bool) { return loans[index].approbations[_address]; }
    function getStatus(uint index) constant returns (Status) { return loans[index].status; }
    function getLenderBalance(uint index) constant returns (uint256) { return loans[index].lenderBalance; }
    function getCurrencyLength(uint index) constant returns (uint256) { return bytes(loans[index].currency).length; }
    function getCurrencyByte(uint index, uint cindex) constant returns (bytes1) { return bytes(loans[index].currency)[cindex]; }
    function getApprovedTransfer(uint index) constant returns (address) {return loans[index].approvedTransfer; }
    function getCurrencyHash(uint index) constant returns (bytes32) { return keccak256(loans[index].currency); }
    function getCurrencyDecimals(uint index) constant returns (uint256) { return loans[index].oracle.getDecimals(loans[index].currency); }
    function getExpirationRequest(uint index) constant returns (uint256) { return loans[index].expirationRequest; }

    function isApproved(uint index) constant returns (bool) {
        Loan storage loan = loans[index];
        return loan.approbations[loan.borrower] && (loan.approbations[loan.cosigner] || loan.cosigner == address(0));
    }

    function approve(uint index) public returns(bool) {
        Loan storage loan = loans[index];
        require(loan.status == Status.initial);
        loan.approbations[msg.sender] = true;
        ApprovedBy(index, msg.sender);
        return true;
    }

    function lend(uint index) public returns (bool) {
        Loan storage loan = loans[index];
        require(loan.status == Status.initial);
        require(isApproved(index));
        require(block.timestamp <= loan.expirationRequest);

        loan.lender = msg.sender;
        loan.dueTime = safeAdd(block.timestamp, loan.duesIn);
        loan.interestTimestamp = block.timestamp;
        loan.status = Status.lent;

        if (loan.cancelableAt > 0)
            internalAddInterest(index, safeAdd(block.timestamp, loan.cancelableAt));

        uint256 rate = getOracleRate(index);
        require(token.transferFrom(msg.sender, loan.borrower, safeMult(loan.amount, rate)));

        if (loan.cosigner != address(0))
            require(token.transferFrom(msg.sender, loan.cosigner, safeMult(loan.cosignerFee, rate)));
        
        Lent(index, loan.lender);
        return true;
    }

    function destroy(uint index) public returns (bool) {
        Loan storage loan = loans[index];
        require(loan.status != Status.destroyed);
        require(msg.sender == loan.lender || ((msg.sender == loan.borrower || msg.sender == loan.cosigner) && loan.status == Status.initial));
        DestroyedBy(index, msg.sender);
        loan.status = Status.destroyed;
        return true;
    }

    function transfer(uint index, address to) public returns (bool) {
        Loan storage loan = loans[index];
        require(loan.status != Status.destroyed);
        require(msg.sender == loan.lender || msg.sender == loan.approvedTransfer);
        require(to != address(0));
        Transfer(index, loan.lender, to);
        loan.lender = to;
        loan.approvedTransfer = address(0);
        return true;
    }

    function approveTransfer(uint index, address to) public returns (bool) {
        Loan storage loan = loans[index];
        require(msg.sender == loan.lender);
        loan.approvedTransfer = to;
        return true;
    }

    function getPendingAmount(uint index) public constant returns (uint256) {
        Loan storage loan = loans[index];
        return safeSubtract(safeAdd(safeAdd(loan.amount, loan.interest), loan.punitoryInterest), loan.paid);
    }

    function calculateInterest(uint256 timeDelta, uint256 interestRate, uint256 amount) public constant returns (uint256 realDelta, uint256 interest) {
        interest = safeMult(safeMult(100000, amount), timeDelta) / interestRate;
        realDelta = safeMult(interest, interestRate) / (amount * 100000);
    }

    function internalAddInterest(uint index, uint256 timestamp) internal {
        Loan storage loan = loans[index];
        if (timestamp > loan.interestTimestamp) {
            uint256 newInterest = loan.interest;
            uint256 newPunitoryInterest = loan.punitoryInterest;

            uint256 newTimestamp;
            uint256 realDelta;
            uint256 calculatedInterest;

            uint256 deltaTime;
            uint256 pending;

            uint256 endNonPunitory = min(timestamp, loan.dueTime);
            if (endNonPunitory > loan.interestTimestamp) {
                deltaTime = safeSubtract(endNonPunitory, loan.interestTimestamp);
                pending = safeSubtract(loan.amount, loan.paid);
                (realDelta, calculatedInterest) = calculateInterest(deltaTime, loan.interestRate, pending);
                newInterest = safeAdd(calculatedInterest, newInterest);
                newTimestamp = loan.interestTimestamp + realDelta;
            }

            if (timestamp > loan.dueTime) {
                uint256 startPunitory = max(loan.dueTime, loan.interestTimestamp);
                deltaTime = safeSubtract(timestamp, startPunitory);
                pending = safeSubtract(safeAdd(loan.amount, newInterest), loan.paid);
                (realDelta, calculatedInterest) = calculateInterest(deltaTime, loan.interestRatePunitory, pending);
                newPunitoryInterest = safeAdd(newPunitoryInterest, calculatedInterest);
                newTimestamp = startPunitory + realDelta;
            }
            
            if (newInterest != loan.interest || newPunitoryInterest != loan.punitoryInterest) {
                loan.interestTimestamp = newTimestamp;
                loan.interest = newInterest;
                loan.punitoryInterest = newPunitoryInterest;
            }
        }
    }

    function addInterestUpTo(uint index, uint256 timestamp) internal {
        Loan storage loan = loans[index];
        require(loan.status == Status.lent);
        if (timestamp <= block.timestamp) {
            internalAddInterest(index, timestamp);
        }
    }

    function addInterest(uint index) public {
        addInterestUpTo(index, block.timestamp);
    }
    
    function pay(uint index, uint256 _amount, address _from) public returns (bool) {
        Loan storage loan = loans[index];
        require(loan.status == Status.lent);
        addInterest(index);
        uint256 toPay = min(getPendingAmount(index), _amount);

        loan.paid = safeAdd(loan.paid, toPay);
        if (getPendingAmount(index) == 0) {
            TotalPayment(index);
            loan.status = Status.paid;
        }

        uint256 transferValue = safeMult(toPay, getOracleRate(index));
        require(token.transferFrom(msg.sender, this, transferValue));
        loan.lenderBalance = safeAdd(transferValue, loan.lenderBalance);
        totalLenderBalance = safeAdd(transferValue, totalLenderBalance);
        PartialPayment(index, msg.sender, _from, toPay);

        return true;
    }

    function withdrawal(uint index, address to, uint256 amount) public returns (bool) {
        Loan storage loan = loans[index];
        require(to != address(0));
        if (msg.sender == loan.lender && loan.lenderBalance >= amount) {
            loan.lenderBalance = safeSubtract(loan.lenderBalance, amount);
            totalLenderBalance = safeSubtract(totalLenderBalance, amount);
            require(token.transfer(to, amount));
            return true;
        }
    }

    function changeOwner(address to) public {
        require(msg.sender == owner);
        require(to != address(0));
        owner = to;
    }

    function setDeprecated(bool _deprecated) public {
        require(msg.sender == owner);
        deprecated = _deprecated;
    }

    function getOracleRate(uint index) internal returns (uint256) {
        Loan storage loan = loans[index];
        if (loan.oracle == address(0)) 
            return 1;

        uint256 costOracle = loan.oracle.getCost(loan.currency);
        require(token.transferFrom(msg.sender, this, costOracle));
        require(token.approve(loan.oracle, costOracle));
        uint256 rate = loan.oracle.getRateFor(loan.currency);
        require(rate != 0);
        return rate;
    }

    function emergencyWithdrawal(Token _token, address to, uint256 amount) returns (bool) {
        require(msg.sender == owner);
        require(_token != token || safeSubtract(token.balanceOf(this), totalLenderBalance) >= amount);
        require(to != address(0));
        return _token.transfer(to, amount);
    }
}