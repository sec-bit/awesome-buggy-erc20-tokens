pragma solidity ^0.4.13;


contract Token {   
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public returns (bool success) {       
        address sender = msg.sender;
        require(balances[sender] >= _value);
        balances[sender] -= _value;
        balances[_to] += _value;
        Transfer(sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {      
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }    
}

contract GigaGivingToken is StandardToken {
    string public constant NAME = "Giga Coin";
    string public constant SYMBOL = "GC";
    uint256 public constant DECIMALS = 0;
    uint256 public constant TOTAL_TOKENS = 15000000;
    uint256 public constant  CROWDSALE_TOKENS = 12000000;  
    string public constant VERSION = "GC.2";

    function GigaGivingToken () public {
        balances[msg.sender] = TOTAL_TOKENS; 
        totalSupply = TOTAL_TOKENS;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}



library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {    
    uint256 c = a / b;    
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract GigaGivingICO {
    using SafeMath for uint256;
         
    uint256 private fundingGoal;
    uint256 private amountRaised;

    uint256 public constant PHASE_1_PRICE = 1600000000000000;
    uint256 public constant PHASE_2_PRICE = 2000000000000000; 
    uint256 public constant PHASE_3_PRICE = 2500000000000000; 
    uint256 public constant PHASE_4_PRICE = 4000000000000000;
    uint256 public constant PHASE_5_PRICE = 5000000000000000; 
    uint256 public constant DURATION = 5 weeks;  
    uint256 public startTime;
    uint256 public tokenSupply;
 
    address public beneficiary;

    GigaGivingToken public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;

    event GoalReached(address goalBeneficiary, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);
    
    function GigaGivingICO (address icoToken, address icoBeneficiary) public {
        fundingGoal = 1000 ether; 
        startTime = 1510765200;
        beneficiary = icoBeneficiary;
        tokenReward = GigaGivingToken(icoToken);
        tokenSupply = 12000000;
    }

    function () public payable {
        require(now >= startTime);
        require(now <= startTime + DURATION);
        require(!crowdsaleClosed);
        require(msg.value > 0);
        uint256 amount = msg.value;
        uint256 coinTotal = 0;      
        
        if (now > startTime + 4 weeks) {
            coinTotal = amount.div(PHASE_5_PRICE);
        } else if (now > startTime + 3 weeks) {
            coinTotal = amount.div(PHASE_4_PRICE);
        } else if (now > startTime + 2 weeks) {
            coinTotal = amount.div(PHASE_3_PRICE);
        } else if (now > startTime + 1 weeks) {
            coinTotal = amount.div(PHASE_2_PRICE);
        } else {
            coinTotal = amount.div(PHASE_1_PRICE);
        }
       
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        amountRaised = amountRaised.add(amount);
        tokenSupply = tokenSupply.sub(coinTotal);
        tokenReward.transfer(msg.sender, coinTotal);
        FundTransfer(msg.sender, amount, true);
    }  

    modifier afterDeadline() { 
        if (now >= (startTime + DURATION)) {
            _;
        }
    }

    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                tokenReward.transfer(msg.sender, tokenSupply);
                FundTransfer(beneficiary, amountRaised, false);                
            } else {               
                fundingGoalReached = false;
            }
        }
    }
}