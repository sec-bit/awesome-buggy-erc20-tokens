pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}






/**
 * @title ERC20 FSN Token Generation and Voluntary Participants Program
 * @dev see https://github.com/FusionFoundation/TokenSale
 */
contract ShareTokenSale is Ownable {

    using SafeMath for uint256;

    ERC20 public token;
    address public receiverAddr;
    uint256 public totalSaleAmount;
    uint256 public totalWannaBuyAmount; 
    uint256 public startTime;
    uint256 public endTime;
    uint256 public userWithdrawalStartTime;
    uint256 public clearStartTime;
    uint256 public withdrawn;
    uint256 public proportion = 1 ether;
    mapping(uint256 => uint256) public globalAmounts;    


    struct Stage {
        uint256 rate;
        uint256 duration;
        uint256 startTime;       
    }
    Stage[] public stages;    


    struct PurchaserInfo {
        bool withdrew;
        bool recorded;
        mapping(uint256 => uint256) amounts;
    }
    mapping(address => PurchaserInfo) public purchaserMapping;
    address[] public purchaserList;

    modifier onlyOpenTime {
        require(isStarted());
        require(!isEnded());
        _;
    }

    modifier onlyAutoWithdrawalTime {
         require(isEnded());
        _;
    }

    modifier onlyUserWithdrawalTime {
        require(isUserWithdrawalTime());
        _;
    }

    modifier purchasersAllWithdrawn {
        require(withdrawn==purchaserList.length);
        _;
    }

    modifier onlyClearTime {
        require(isClearTime());
        _;
    }

    function ShareTokenSale(address _receiverAddr, address _tokenAddr, uint256 _totalSaleAmount, uint256 _startTime) public {
        require(_receiverAddr != address(0));
        require(_tokenAddr != address(0));
        require(_totalSaleAmount > 0);
        require(_startTime > 0);
        receiverAddr = _receiverAddr;
        token = ERC20(_tokenAddr);
        totalSaleAmount = _totalSaleAmount;       
        startTime = _startTime;        
    }

    function isStarted() public view returns(bool) {
        return 0 < startTime && startTime <= now && endTime != 0;
    }   

    function isEnded() public view returns(bool) {
        return now > endTime;
    }

    function isUserWithdrawalTime() public view returns(bool) {
        return now > userWithdrawalStartTime;
    }

    function isClearTime() public view returns(bool) {
        return now > clearStartTime;
    }
    
    function startSale(uint256[] rates, uint256[] durations, uint256 userWithdrawalDelaySec, uint256 clearDelaySec) public onlyOwner {
        require(endTime == 0);
        require(durations.length == rates.length);
        delete stages;
        endTime = startTime;
        for (uint256 i = 0; i < durations.length; i++) {
            uint256 rate = rates[i];
            uint256 duration = durations[i];            
            stages.push(Stage({rate: rate, duration: duration, startTime:endTime}));
            endTime = endTime.add(duration);
        }
        userWithdrawalStartTime = endTime.add(userWithdrawalDelaySec);
        clearStartTime = endTime.add(clearDelaySec);
    }
    
    function getCurrentStage() public onlyOpenTime view returns(uint256) {
        for (uint256 i = stages.length - 1; i >= 0; i--) {
            if (now >= stages[i].startTime) {
                return i;
            }
        }
        revert();
    }

    function getPurchaserCount() public view returns(uint256) {
        return purchaserList.length;
    }


    function _calcProportion() internal {
        if (totalWannaBuyAmount == 0 || totalSaleAmount >= totalWannaBuyAmount) {
            proportion = 1 ether;
            return;
        }
        proportion = totalSaleAmount.mul(1 ether).div(totalWannaBuyAmount);        
    }

    function getSaleInfo(address purchaser) public view returns (uint256, uint256, uint256) {
        PurchaserInfo storage pi = purchaserMapping[purchaser];
        uint256 sendEther = 0;
        uint256 usedEther = 0;
        uint256 getToken = 0;        
        for (uint256 i = 0; i < stages.length; i++) {
            sendEther = sendEther.add(pi.amounts[i]);
            uint256 stageUsedEther = pi.amounts[i].mul(proportion).div(1 ether);
            uint256 stageGetToken = stageUsedEther.mul(stages[i].rate);
            if (stageGetToken > 0) {         
                getToken = getToken.add(stageGetToken);
                usedEther = usedEther.add(stageUsedEther);
            }
        }        
        return (sendEther, usedEther, getToken);
    }
    
    function () payable public {        
        buy();
    }
    
    function buy() payable public onlyOpenTime {
        require(msg.value >= 0.1 ether);
        uint256 stageIndex = getCurrentStage();
        uint256 amount = msg.value;
        PurchaserInfo storage pi = purchaserMapping[msg.sender];
        if (!pi.recorded) {
            pi.recorded = true;
            purchaserList.push(msg.sender);
        }
        pi.amounts[stageIndex] = pi.amounts[stageIndex].add(amount);
        globalAmounts[stageIndex] = globalAmounts[stageIndex].add(amount);
        totalWannaBuyAmount = totalWannaBuyAmount.add(amount.mul(stages[stageIndex].rate));
        _calcProportion();
    }
    
    function _withdrawal(address purchaser) internal {
        require(purchaser != 0x0);
        PurchaserInfo storage pi = purchaserMapping[purchaser];        
        if (pi.withdrew) {
            return;
        }
        pi.withdrew = true;
        withdrawn = withdrawn.add(1);
        var (sendEther, usedEther, getToken) = getSaleInfo(purchaser);
        if (usedEther > 0 && getToken > 0) {
            receiverAddr.transfer(usedEther);
            token.transfer(purchaser, getToken);
            if (sendEther.sub(usedEther) > 0) {                
                purchaser.transfer(sendEther.sub(usedEther));   
            }           
        } else {
            purchaser.transfer(sendEther);
        }
        return;
    }
    
    function withdrawal() payable public onlyUserWithdrawalTime {
        _withdrawal(msg.sender);
    }
    
    function withdrawalFor(uint256 index, uint256 stop) payable public onlyAutoWithdrawalTime onlyOwner {
        for (; index < stop; index++) {
            _withdrawal(purchaserList[index]);
        }
    }
    
    function clear(uint256 tokenAmount, uint256 etherAmount) payable public purchasersAllWithdrawn onlyClearTime onlyOwner {
        if (tokenAmount > 0) {
            token.transfer(receiverAddr, tokenAmount);
        }
        if (etherAmount > 0) {
            receiverAddr.transfer(etherAmount);
        }        
    }
}