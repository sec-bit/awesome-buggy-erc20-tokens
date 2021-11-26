pragma solidity ^0.4.11;
/*
Moira ICO Contract

MOI is an ERC-20 Token Standar Compliant

Contract developer: Fares A. Akel C.
f.antonio.akel@gmail.com
MIT PGP KEY ID: 078E41CB
*/

/**
 * @title SafeMath by OpenZeppelin
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract token { //Token functions definition

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    }
contract MOIRAICO {
    //This ico have 4 stages for 4 weeks and the Successful stage when finished
    enum State {
        Preico,
        Ico,
        Successful
    }
    
    State public state = State.Preico; //Set initial stage
    uint startTime = now; //block-time when it was deployed

    //List of prices for each stage, as both, eth and moi have 18 decimal, its a direct factor
    uint[4] tablePrices = [
    58000,
    63800,
    32200
    ];

    mapping (address => uint) balances; //balances mapping
    //public variables
    uint public totalRaised;
    uint public currentBalance;
    uint public preICODeadline;
    uint public ICOdeadline;
    uint public completedAt;
    token public tokenReward;
    address public creator;
    address public beneficiary; 
    string public campaignUrl;
    uint constant version = 1;

    //events for log

    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(
        address _creator,
        address _beneficiary,
        string _url,
        uint256 _preICODeadline,
        uint256 _ICOdeadline);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

    function MOIRAICO (
        string _campaignUrl,
        token _addressOfTokenUsedAsReward )
        public
    {
        creator = msg.sender;
        beneficiary = msg.sender;
        campaignUrl = _campaignUrl;
        preICODeadline = SafeMath.add(startTime,34 days);
        ICOdeadline = SafeMath.add(preICODeadline,30 days);
        currentBalance = 0;
        tokenReward = token(_addressOfTokenUsedAsReward);
        LogFunderInitialized(
            creator,
            beneficiary,
            campaignUrl,
            preICODeadline,
            ICOdeadline);
    }

    function contribute() public notFinished payable {

        require(msg.value > 1 finney); //minimun contribution

        uint tokenBought;
        totalRaised =SafeMath.add(totalRaised, msg.value);
        currentBalance = totalRaised;

        if(state == State.Preico){
            tokenBought = SafeMath.mul(msg.value,tablePrices[0]);
        }
        else if(state == State.Preico && now < (startTime + 1 days)) {
            tokenBought = SafeMath.mul(msg.value,tablePrices[1]);
        }
        else{
            tokenBought = SafeMath.mul(msg.value,tablePrices[2]);
        }

        tokenReward.transfer(msg.sender, tokenBought);
        
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender, tokenBought);
        
        checkIfFundingCompleteOrExpired();
    }

    function checkIfFundingCompleteOrExpired() public {
        
        if(now < ICOdeadline && state!=State.Successful){
            if(now > preICODeadline && state==State.Preico){
                state = State.Ico;    
            }
        }
        else if(now > ICOdeadline && state!=State.Successful) {
            state = State.Successful;
            completedAt = now;
            LogFundingSuccessful(totalRaised);
            finished();  
        }
    }

    function finished() public { //When finished eth and remaining tokens are transfered to beneficiary
        uint remanent;

        require(state == State.Successful);
        require(beneficiary.send(this.balance));
        remanent =  tokenReward.balanceOf(this);
        tokenReward.transfer(beneficiary,remanent);

        currentBalance = 0;

        LogBeneficiaryPaid(beneficiary);
        LogContributorsPayout(beneficiary, remanent);
    }

    function () public payable {
        require(msg.value > 1 finney);
        contribute();
    }
}