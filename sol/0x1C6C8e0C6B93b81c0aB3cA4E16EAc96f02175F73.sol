pragma solidity ^0.4.18;


contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {
    
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); 
    uint256 c = a / b;
    // assert(a == b * c + a % b); 
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}

contract Ownable {
    
  address public owner;

  
  function Ownable() {
    owner = msg.sender;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract Crowdsale is Ownable {
    
    using SafeMath for uint256;
    
    address public multisig;

   

   

   
 ERC20 public token;
    uint public startTime;
    
  
    uint public endTime;

    uint256 public hardcap;

    uint public rate;
    
    uint public bonusPercent;
    
  
    
  
  uint256 public tokensSold = 0;

 
  uint256 public weiRaised = 0;
  
  
  uint public investorCount = 0;
    
  mapping (address => uint256) public investedAmountOf;

 
  mapping (address => uint256) public tokenAmountOf;
 

  
  struct Promo {
        uint bonus;
        uint EndTime;
    }
 
 mapping (address => Promo) PromoList;
 mapping (uint=>uint) amountBonus;
 uint public level_1_amount=50 ether;
 uint public level_2_amount=100 ether;
 uint public level_3_amount=250 ether;
 uint public level_4_amount=500 ether;
 uint public level_5_amount=1000 ether;
 uint public level_6_amount=100000 ether;
 uint public level_7_amount=1000000 ether;
 uint public level_8_amount=1000000 ether;
 uint public level_9_amount=1000000 ether;
 uint public level_1_percent=20;
 uint public level_2_percent=25;
 uint public level_3_percent=30;
 uint public level_4_percent=35;
 uint public level_5_percent=40;
 uint public level_6_percent=40;
 uint public level_7_percent=40;
 uint public level_8_percent=40;
 uint public level_9_percent=40;
 bool public canExchange=true;
    function Crowdsale() {
        multisig =0x7c27f68b0d5afffb668da3e046adfba6ea1f6bc3;
     
       bonusPercent=130;
        rate =5000;
        startTime =1510704000;
        endTime=1513382399;
     
        hardcap = 1000000000000000;
        token=ERC20(0x292317a267adfb97d1b4e3ffd04f9da399cf973b);
        
    }



  
    function setEndTime(uint _endTime) public onlyOwner{
         require(_endTime>=now&&_endTime>=startTime);
        endTime=_endTime;
    }
    
     function setHardcap(uint256 _hardcap) public onlyOwner{
       
        hardcap=_hardcap;
    }
    
   function setPromo(address _address,uint _amount,uint _endtime) public onlyOwner{
       
       PromoList[_address].bonus=_amount;
        PromoList[_address].EndTime=_endtime;
    }
     function resetAmountBonuses() public onlyOwner
     {
 level_1_amount=0;
 level_2_amount=0;
 level_3_amount=0;
 level_4_amount=0;
 level_5_amount=0;
 level_6_amount=0;
 level_7_amount=0;
 level_8_amount=0;
 level_9_amount=0;
 level_1_percent=0;
 level_2_percent=0;
 level_3_percent=0;
 level_4_percent=0;
 level_5_percent=0;
 level_6_percent=0;
 level_7_percent=0;
 level_8_percent=0;
 level_9_percent=0;
    }
     function setAmountBonuses(uint _level,uint _amount,uint _percent) public onlyOwner
     {
         if (_level==1) 
         {
           level_1_amount=(_amount).mul(1 ether);
          level_1_percent=_percent;
         }
        else if (_level==2) 
         {
           level_2_amount=_amount.mul(1 ether);
          level_2_percent=_percent;
         }
       else  if (_level==3) 
         {
           level_3_amount=_amount.mul(1 ether);
          level_3_percent=_percent;
         }
      else   if (_level==4) 
         {
           level_4_amount=_amount.mul(1 ether);
          level_4_percent=_percent;
         }
      else   if (_level==5) 
         {
           level_5_amount=_amount.mul(1 ether);
          level_5_percent=_percent;
         }
     else    if (_level==6) 
         {
           level_6_amount=_amount.mul(1 ether);
          level_6_percent=_percent;
         }
       else  if (_level==7) 
         {
           level_7_amount=_amount.mul(1 ether);
          level_7_percent=_percent;
         }
      else   if (_level==8) 
         {
           level_8_amount=_amount.mul(1 ether);
          level_8_percent=_percent;
         }
       else  if (_level==9) 
         {
           level_9_amount=_amount.mul(1 ether);
          level_9_percent=_percent;
         }
     }
 
    

    
    
    
    modifier saleIsOn(){
         require(now > startTime && now <= endTime);
         _;
    }
    
    modifier isUnderHardCap() {
   
       require(tokensSold <= hardcap);
        _;
    }
    
    modifier isCanExchange(){
       require(canExchange);
       _;
       }
   
   function calcToken()
      
        returns (uint256)
    {
         uint bonus;
        uint256  tokens=0;
         bonus=bonusPercent;
       if (PromoList[msg.sender].EndTime >=now)
        {
           bonus += PromoList[msg.sender].bonus; 
        }
       
        
           
            if (msg.value>=level_1_amount && msg.value<level_2_amount )
            {
            bonus+=level_1_percent;
            }
            else
             if (msg.value>=level_2_amount && msg.value<level_3_amount )
            {
            bonus+=level_2_percent;
            }
             else
             if (msg.value>=level_3_amount && msg.value<level_4_amount )
            {
            bonus+=level_3_percent;
            }
             else
             if (msg.value>=level_4_amount && msg.value<level_5_amount )
            {
            bonus+=level_4_percent;
            }
             else
             if (msg.value>=level_5_amount && msg.value<level_6_amount )
            {
            bonus+=level_5_percent;
            }
         else
             if (msg.value>=level_6_amount && msg.value<level_7_amount )
            {
            bonus+=level_6_percent;
            }
            else
             if (msg.value>=level_7_amount && msg.value<level_8_amount )
            {
            bonus+=level_7_percent;
            }
             else
             if (msg.value>=level_8_amount && msg.value<level_9_amount )
            {
            bonus+=level_8_percent;
            }
       else
             if (msg.value>=level_9_amount)
            {
            bonus+=level_9_percent;
            }
             uint256 multiplier = 10 **6;
         tokens = multiplier.mul(msg.value).div(1 ether).mul(rate).div(100).mul(bonus);
        
        
       
        return tokens;
    }
       function exchange() public isCanExchange {
     // address myAdrress=this;
     ERC20  oldToken=ERC20(0x12a35383cA24ceb44cdcBBecbEb7baCcB5F3754A);
    ERC20   newToken=ERC20(0x292317a267AdFb97d1b4E3Ffd04f9Da399cf973b);
       

     uint  oldTokenAmount=oldToken.balanceOf(msg.sender);
     //oldToken.approve(myAdrress,oldTokenAmount);
      oldToken.transferFrom(msg.sender,0x0a6d9df476577C0D4A24EB50220fad007e444db8,oldTokenAmount);
 newToken.transferFrom(0x0a6d9df476577C0D4A24EB50220fad007e444db8,msg.sender,oldTokenAmount*105/40);
    
       
   }
    function createTokens() payable saleIsOn isUnderHardCap {
        
      
      
      uint256 tokens=calcToken();
        
         
        assert (tokens >= 10000);
    
        
       
       token.transferFrom(0x0a6d9df476577C0D4A24EB50220fad007e444db8,msg.sender, tokens);
        if(investedAmountOf[msg.sender] == 0) {
      
       investorCount++;
        }
        investedAmountOf[msg.sender] = investedAmountOf[msg.sender].add(msg.value);
        tokenAmountOf[msg.sender] = tokenAmountOf[msg.sender].add(tokens);
        
        weiRaised = weiRaised.add(msg.value);
    tokensSold = tokensSold.add(tokens);  
    
     multisig.transfer(msg.value);
    }

    function() external payable {
        createTokens();
    }
    
}