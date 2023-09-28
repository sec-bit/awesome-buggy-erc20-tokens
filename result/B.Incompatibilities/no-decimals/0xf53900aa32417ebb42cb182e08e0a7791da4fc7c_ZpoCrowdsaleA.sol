/**
 *  Crowdsale for 0+1 Tokens.
 *
 *  Based on OpenZeppelin framework.
 *  https://openzeppelin.org
 *
 *  Author: Eversystem Inc.
 **/

pragma solidity ^0.4.18;

/**
 * Safe Math library from OpenZeppelin framework
 * https://openzeppelin.org
 *
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title 0+1 Crowdsale phase 1
1519056000
1521129600
1522512000
1523808000

1525104000
1526400000
1527782400
1529078400

1530374400
1531670400
1533052800
1534348800
 */
contract ZpoCrowdsaleA {
    using SafeMath for uint256;

    // Funding goal and soft cap
    uint256 public constant HARD_CAP = 2000000000 * (10 ** 18);

    // Cap for each term periods
    uint256 public constant ICO_CAP = 7000;

    // Number of stages
    uint256 public constant NUM_STAGES = 4;

    uint256 public constant ICO_START1 = 1518689400;
    uint256 public constant ICO_START2 = ICO_START1 + 300 seconds;
    uint256 public constant ICO_START3 = ICO_START2 + 300 seconds;
    uint256 public constant ICO_START4 = ICO_START3 + 300 seconds;
    uint256 public constant ICO_END = ICO_START4 + 300 seconds;

    /*
    // 2018/02/20 - 2018/03/15
    uint256 public constant ICO_START1 = 1519056000;
    // 2018/03/16 - 2018/03/31
    uint256 public constant ICO_START2 = 1521129600;
    // 2018/04/01 - 2018/04/15
    uint256 public constant ICO_START3 = 1522512000;
    // 2018/04/16 - 2018/04/30
    uint256 public constant ICO_START4 = 1523808000;
    // 2018/04/16 - 2018/04/30
    uint256 public constant ICO_END = 152510399;
    */

    // Exchange rate for each term periods
    uint256 public constant ICO_RATE1 = 20000 * (10 ** 18);
    uint256 public constant ICO_RATE2 = 18000 * (10 ** 18);
    uint256 public constant ICO_RATE3 = 17000 * (10 ** 18);
    uint256 public constant ICO_RATE4 = 16000 * (10 ** 18);

    // Exchange rate for each term periods
    uint256 public constant ICO_CAP1 = 14000;
    uint256 public constant ICO_CAP2 = 21000;
    uint256 public constant ICO_CAP3 = 28000;
    uint256 public constant ICO_CAP4 = 35000;

    // Owner of this contract
    address public owner;

    // The token being sold
    ERC20 public tokenReward;

    // Tokens will be transfered from this address
    address public tokenOwner;

    // Address where funds are collected
    address public wallet;

    // Stage of ICO
    uint256 public stage = 0;

    // Amount of tokens sold
    uint256 public tokensSold = 0;

    // Amount of raised money in wei
    uint256 public weiRaised = 0;

    /**
     * Event for token purchase logging
     *
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event IcoStageStarted(uint256 stage);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function ZpoCrowdsaleA(address _tokenAddress, address _wallet) public {
        require(_tokenAddress != address(0));
        require(_wallet != address(0));

        owner = msg.sender;
        tokenOwner = msg.sender;
        wallet = _wallet;

        tokenReward = ERC20(_tokenAddress);

        stage = 0;
    }

    // Fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // Low level token purchase function
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != address(0));
        require(stage <= NUM_STAGES);
        require(validPurchase());
        require(now <= ICO_END);
        require(weiRaised < ICO_CAP4);
        require(msg.value >= (10 ** 17));
        require(msg.value <= (1000 ** 18));

        determineCurrentStage();
        require(stage >= 1 && stage <= NUM_STAGES);

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(weiAmount);
        require(tokens > 0);

        // Update totals
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);

        assert(tokenReward.transferFrom(tokenOwner, _beneficiary, tokens));
        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        forwardFunds();
    }

    // Send ether to the fund collection wallet
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function determineCurrentStage() internal {
        uint256 prevStage = stage;
        checkCap();

        if (stage < 4 && now >= ICO_START4) {
            stage = 4;
            checkNewPeriod(prevStage);
            return;
        }
        if (stage < 3 && now >= ICO_START3) {
            stage = 3;
            checkNewPeriod(prevStage);
            return;
        }
        if (stage < 2 && now >= ICO_START2) {
            stage = 2;
            checkNewPeriod(prevStage);
            return;
        }
        if (stage < 1 && now >= ICO_START1) {
            stage = 1;
            checkNewPeriod(prevStage);
            return;
        }
    }

    function checkCap() internal {
        if (weiRaised >= ICO_CAP3) {
            stage = 4;
        }
        else if (weiRaised >= ICO_CAP2) {
            stage = 3;
        }
        else if (weiRaised >= ICO_CAP1) {
            stage = 2;
        }
    }

    function checkNewPeriod(uint256 _prevStage) internal {
        if (stage != _prevStage) {
            IcoStageStarted(stage);
        }
    }

    function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 rate = 0;

        if (stage == 1) {
            rate = ICO_RATE1;
        } else if (stage == 2) {
            rate = ICO_RATE2;
        } else if (stage == 3) {
            rate = ICO_RATE3;
        } else if (stage == 4) {
            rate = ICO_RATE4;
        }

        return rate.mul(_weiAmount);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= ICO_START1 && now <= ICO_END;
        bool nonZeroPurchase = msg.value != 0;

        return withinPeriod && nonZeroPurchase;
    }
}