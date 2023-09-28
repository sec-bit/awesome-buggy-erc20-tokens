pragma solidity ^0.4.20;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20
{
    function totalSupply()public view returns (uint total_Supply);
    function balanceOf(address who)public view returns (uint256);
    function allowance(address owner, address spender)public view returns (uint);
    function transferFrom(address from, address to, uint value)public returns (bool ok);
    function approve(address spender, uint value)public returns (bool ok);
    function transfer(address to, uint value)public returns (bool ok);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract FiatContract
{
    function USD(uint _id) external constant returns (uint256);
}

contract SATCrowdsale
{
    using SafeMath for uint256;
    
    address public owner;
    bool stopped = false;
    uint256 public startdate;
    uint256 ico_first;
    uint256 ico_second;
    uint256 ico_third;
    uint256 ico_fourth;
    
    enum Stages
    {
        NOTSTARTED,
        ICO,
        PAUSED,
        ENDED
    }
    
    Stages public stage;
    
    FiatContract price = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);
    ERC20 public constant tokenContract = ERC20(0xc56b13ebbCFfa67cFb7979b900b736b3fb480D78);
    
    modifier atStage(Stages _stage)
    {
        require(stage == _stage);
        _;
    }
    
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    function SATCrowdsale() public
    {
        owner = msg.sender;
        stage = Stages.NOTSTARTED;
    }
    
    function () external payable atStage(Stages.ICO)
    {
        require(msg.value >= 1 finney); //for round up and security measures
        require(!stopped && msg.sender != owner);
        
        uint256 ethCent = price.USD(0); //one USD cent in wei
        uint256 tokPrice = ethCent.mul(9); // 1Sat = 9 USD cent
        
        tokPrice = tokPrice.div(10 ** 8); //limit to 10 places
        uint256 no_of_tokens = msg.value.div(tokPrice);
        
        uint256 bonus_token = 0;
        
        // Determine the bonus based on the time and the purchased amount
        if (now < ico_first)
        {
            if (no_of_tokens >=  2000 * (uint256(10)**8) &&
                no_of_tokens <= 19999 * (uint256(10)**8))
            {
                bonus_token = no_of_tokens.mul(50).div(100); // 50% bonus
            }
            else if (no_of_tokens >   19999 * (uint256(10)**8) &&
                     no_of_tokens <= 149999 * (uint256(10)**8))
            {
                bonus_token = no_of_tokens.mul(55).div(100); // 55% bonus
            }
            else if (no_of_tokens > 149999 * (uint256(10)**8))
            {
                bonus_token = no_of_tokens.mul(60).div(100); // 60% bonus
            }
            else
            {
                bonus_token = no_of_tokens.mul(45).div(100); // 45% bonus
            }
        }
        else if (now >= ico_first && now < ico_second)
        {
            if (no_of_tokens >=  2000 * (uint256(10)**8) &&
                no_of_tokens <= 19999 * (uint256(10)**8))
            {
                bonus_token = no_of_tokens.mul(40).div(100); // 40% bonus
            }
            else if (no_of_tokens >   19999 * (uint256(10)**8) &&
                     no_of_tokens <= 149999 * (uint256(10)**8))
            {
                bonus_token = no_of_tokens.mul(45).div(100); // 45% bonus
            }
            else if (no_of_tokens >  149999 * (uint256(10)**8))
            {
                bonus_token = no_of_tokens.mul(50).div(100); // 50% bonus
            }
            else
            {
                bonus_token = no_of_tokens.mul(35).div(100); // 35% bonus
            }
        }
        else if (now >= ico_second && now < ico_third)
        {
            if (no_of_tokens >=  2000 * (uint256(10)**8) &&
                no_of_tokens <= 19999 * (uint256(10)**8))
            {
                bonus_token = no_of_tokens.mul(30).div(100); // 30% bonus
            }
            else if (no_of_tokens >   19999 * (uint256(10)**8) &&
                     no_of_tokens <= 149999 * (uint256(10)**8))
            {
                bonus_token = no_of_tokens.mul(35).div(100); // 35% bonus
            }
            else if (no_of_tokens >  149999 * (uint256(10)**8))
            {
                bonus_token = no_of_tokens.mul(40).div(100); // 40% bonus
            }
            else
            {
                bonus_token = no_of_tokens.mul(25).div(100); // 25% bonus
            }
        }
        else if (now >= ico_third && now < ico_fourth)
        {
            if (no_of_tokens >=  2000 * (uint256(10)**8) &&
                no_of_tokens <= 19999 * (uint256(10)**8))
            {
                bonus_token = no_of_tokens.mul(20).div(100); // 20% bonus
            }
            else if (no_of_tokens >   19999 * (uint256(10)**8) &&
                     no_of_tokens <= 149999 * (uint256(10)**8))
            {
                bonus_token = no_of_tokens.mul(25).div(100); // 25% bonus
            }
            else if (no_of_tokens >  149999 * (uint256(10)**8))
            {
                bonus_token = no_of_tokens.mul(30).div(100); // 30% bonus
            }
            else
            {
                bonus_token = no_of_tokens.mul(15).div(100); // 15% bonus
            }
        }
        
        uint256 total_token = no_of_tokens + bonus_token;
        tokenContract.transfer(msg.sender, total_token);
    }
    
    function startICO(uint256 _startDate) public onlyOwner atStage(Stages.NOTSTARTED)
    {
        stage = Stages.ICO;
        stopped = false;
        startdate = _startDate;
        ico_first = _startDate + 14 days;
        ico_second = ico_first + 14 days;
        ico_third = ico_second + 14 days;
        ico_fourth = ico_third + 14 days;
    }
    
    function pauseICO() external onlyOwner atStage(Stages.ICO)
    {
        stopped = true;
        stage = Stages.PAUSED;
    }
    
    function resumeICO() external onlyOwner atStage(Stages.PAUSED)
    {
        stopped = false;
        stage = Stages.ICO;
    }
    
    function endICO() external onlyOwner atStage(Stages.ICO)
    {
        require(now > ico_fourth);
        stage = Stages.ENDED;
        tokenContract.transfer(0x1, tokenContract.balanceOf(address(this)));
    }
    
    function transferAllUnsoldTokens(address _destination) external onlyOwner 
    {
        require(_destination != 0x0);
        tokenContract.transfer(_destination, tokenContract.balanceOf(address(this)));
    }
    
    function transferPartOfUnsoldTokens(address _destination, uint256 _amount) external onlyOwner
    {
        require(_destination != 0x0);
        tokenContract.transfer(_destination, _amount);
    }
    
    function transferOwnership(address _newOwner) external onlyOwner
    {
        owner = _newOwner;
    }
    
    function drain() external onlyOwner
    {
        owner.transfer(this.balance);
    }
}