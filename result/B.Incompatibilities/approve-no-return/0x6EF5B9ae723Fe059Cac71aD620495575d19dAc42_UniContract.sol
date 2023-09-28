pragma solidity ^0.4.7;


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    //assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    //assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    //assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract ERC20Basic {
  uint256 public totalSupply=100000000; 
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract owned {
     function owned() { owner = msg.sender; }
     address owner;

     // This contract only defines a modifier but does not use
     // it - it will be used in derived contracts.
     // The function body is inserted where the special symbol
     // "_;" in the definition of a modifier appears.
     // This means that if the owner calls this function, the
     // function is executed and otherwise, an exception is
     // thrown.
     modifier onlyOwner {
         if(msg.sender != owner)
         {
         throw;
         }
         _;
     }
 }


contract UniContract is StandardToken, owned {


   string public constant name = "SaveUNICOINs";
   string public constant symbol = "UCN";
   uint256 public constant decimals = 0;
   
   //founder & fund collector
   address public multisig;
   address public founder; 
   
   
   //Timings
   uint public start;  
   uint public end;
   uint public launch;
   
   //Dynamic Pricing PRICE IN UCN
   uint256 public PRICE = 300000;  
   
   //Dynamic Status of sold UCN Tokens
   uint256 public OVERALLSOLD = 0;  
   
   //Maximum of Tokens to be sold 85.000.000
   uint256 public MAXTOKENSOLD = 85000000;  
   
   
   
   
  
   function UniContract() onlyOwner { 
       founder = 0x204244062B04089b6Ef55981Ad82119cEBf54F88; 
       multisig= 0x9FA2d2231FE8ac207831B376aa4aE35671619960; 
       start = 1507543200;
       end = 1509098400; 
 	   launch = 1509534000;
       balances[founder] = balances[founder].add(15000000); // Founder (15% = 15.000.000 UCN)
   }
   
   
   
   //Stage Pre-Sale Variables
   
   uint256 public constant PRICE_PRESALE = 300000;  
   uint256 public constant FACTOR_PRESALE = 38;
   uint256 public constant RANGESTART_PRESALE = 0; 
   uint256 public constant RANGEEND_PRESALE = 10000000; 
   
   
   //Stage 1
   uint256 public constant PRICE_1 = 30000;  
   uint256 public constant FACTOR_1 = 460;
   uint256 public constant RANGESTART_1 = 10000001; 
   uint256 public constant RANGEEND_1 = 10100000;
   
   //Stage 2
   uint256 public constant PRICE_2 = 29783;  
   uint256 public constant FACTOR_2 = 495;
   uint256 public constant RANGESTART_2 = 10100001; 
   uint256 public constant RANGEEND_2 = 11000000;
   
   //Stage 3
   uint256 public constant PRICE_3 = 27964;  
   uint256 public constant FACTOR_3 = 580;
   uint256 public constant RANGESTART_3 = 11000001; 
   uint256 public constant RANGEEND_3 = 15000000;
   
   //Stage 4
   uint256 public constant PRICE_4 = 21068;  
   uint256 public constant FACTOR_4 = 800;
   uint256 public constant RANGESTART_4 = 15000001; 
   uint256 public constant RANGEEND_4 = 20000000;
   
   //Stage 5
   uint256 public constant PRICE_5 = 14818;  
   uint256 public constant FACTOR_5 = 1332;
   uint256 public constant RANGESTART_5 = 20000001; 
   uint256 public constant RANGEEND_5 = 30000000;
   
   //Stage 6
   uint256 public constant PRICE_6 = 7310;  
   uint256 public constant FACTOR_6 = 2700;
   uint256 public constant RANGESTART_6 = 30000001; 
   uint256 public constant RANGEEND_6 = 40000000;
   
   //Stage 7
   uint256 public constant PRICE_7 = 3607;  
   uint256 public constant FACTOR_7 = 5450;
   uint256 public constant RANGESTART_7 = 40000001; 
   uint256 public constant RANGEEND_7 = 50000000;
   
   //Stage 8
   uint256 public constant PRICE_8 = 1772;  
   uint256 public constant FACTOR_8 = 11000;
   uint256 public constant RANGESTART_8 = 50000001; 
   uint256 public constant RANGEEND_8 = 60000000;
   
   //Stage 9
   uint256 public constant PRICE_9 = 863;  
   uint256 public constant FACTOR_9 = 23200;
   uint256 public constant RANGESTART_9 = 60000001; 
   uint256 public constant RANGEEND_9 = 70000000;
   
   //Stage 10
   uint256 public constant PRICE_10 = 432;  
   uint256 public constant FACTOR_10 = 46000;
   uint256 public constant RANGESTART_10 = 70000001; 
   uint256 public constant RANGEEND_10 = 80000000;
   
   //Stage 11
   uint256 public constant PRICE_11 = 214;  
   uint256 public constant FACTOR_11 = 78000;
   uint256 public constant RANGESTART_11 = 80000001; 
   uint256 public constant RANGEEND_11 = 85000000;
   

   uint256 public UniCoinSize=0;

 
   function () payable {
     submitTokens(msg.sender);
   }

   /**
    * @dev Creates tokens and send to the specified address.
    * @param recipient The address which will recieve the new tokens.
    */
   function submitTokens(address recipient) payable {
     	if (msg.value == 0) {
       		throw;
     	}
		
   	 	//Permit buying only between 10/09/17 - 10/27/2017 and after 11/01/2017
   	 	if((now > start && now < end) || now > launch)
   	 		{				
        		uint256 tokens = msg.value.mul(PRICE).div( 1 ether);
        		if(tokens.add(OVERALLSOLD) > MAXTOKENSOLD)
   	 				{
   					throw;
   					}
		
   				//Pre-Sale CAP 10,000,000 check
   				if(((tokens.add(OVERALLSOLD)) > RANGEEND_PRESALE) && (now > start && now < end))
   					{
   					throw;
   					}
		
 				   
        		OVERALLSOLD = OVERALLSOLD.add(tokens);	
	
   		 	    // Send UCN to Recipient	
        		balances[recipient] = balances[recipient].add(tokens);
	 
   	 			// Send Funds to MultiSig
        		if (!multisig.send(msg.value)) {
          			throw;
        			}
       		}
   	  	  else
   	  			{
   	  	  		throw;
   	 		   	}
		
		
		//TIMING 10/09/17 - 10/27/17 OR CAP 10,000,000 reached
		
		if(now>start && now <end)
		{
			//Stage Pre-Sale Range 0 - 10,000,000 
			if(OVERALLSOLD >= RANGESTART_PRESALE && OVERALLSOLD <= RANGEEND_PRESALE) 
				{
				PRICE = PRICE_PRESALE - (1 + OVERALLSOLD - RANGESTART_PRESALE).div(FACTOR_PRESALE);
				}
		}
		
		//TIMING 11/01/17 Start Token Sale
		if(now>launch)
		{
		//Stage Post-Pre-Sale Range 0 - 10,000,000 
		if(OVERALLSOLD >= RANGESTART_PRESALE && OVERALLSOLD <= RANGEEND_PRESALE) 
			{
			PRICE = PRICE_PRESALE - (1 + OVERALLSOLD - RANGESTART_PRESALE).div(FACTOR_PRESALE);
			}
		
		//Stage One 10,000,001 - 10,100,000 
		if(OVERALLSOLD >= RANGESTART_1 && OVERALLSOLD <= RANGEEND_1)
			{
			PRICE = PRICE_1 - (1 + OVERALLSOLD - RANGESTART_1).div(FACTOR_1);
			}

		//Stage Two 10,100,001 - 11,000,000
		if(OVERALLSOLD >= RANGESTART_2 && OVERALLSOLD <= RANGEEND_2)
			{
			PRICE = PRICE_2 - (1 + OVERALLSOLD - RANGESTART_2).div(FACTOR_2);
			}

		//Stage Three 11,000,001 - 15,000,000
		if(OVERALLSOLD >= RANGESTART_3 && OVERALLSOLD <= RANGEEND_3)
			{
			PRICE = PRICE_3 - (1 + OVERALLSOLD - RANGESTART_3).div(FACTOR_3);
			}
			
		//Stage Four 15,000,001 - 20,000,000
		if(OVERALLSOLD >= RANGESTART_4 && OVERALLSOLD <= RANGEEND_4)
			{
			PRICE = PRICE_4 - (1 + OVERALLSOLD - RANGESTART_4).div(FACTOR_4);
			}
			
		//Stage Five 20,000,001 - 30,000,000
		if(OVERALLSOLD >= RANGESTART_5 && OVERALLSOLD <= RANGEEND_5)
			{
			PRICE = PRICE_5 - (1 + OVERALLSOLD - RANGESTART_5).div(FACTOR_5);
			}
		
		//Stage Six 30,000,001 - 40,000,000
		if(OVERALLSOLD >= RANGESTART_6 && OVERALLSOLD <= RANGEEND_6)
			{
			PRICE = PRICE_6 - (1 + OVERALLSOLD - RANGESTART_6).div(FACTOR_6);
			}	
		
		//Stage Seven 40,000,001 - 50,000,000
		if(OVERALLSOLD >= RANGESTART_7 && OVERALLSOLD <= RANGEEND_7)
			{
			PRICE = PRICE_7 - (1 + OVERALLSOLD - RANGESTART_7).div(FACTOR_7);
			}
			
		//Stage Eight 50,000,001 - 60,000,000
		if(OVERALLSOLD >= RANGESTART_8 && OVERALLSOLD <= RANGEEND_8)
			{
			PRICE = PRICE_8 - (1 + OVERALLSOLD - RANGESTART_8).div(FACTOR_8);
			}
		
		//Stage Nine 60,000,001 - 70,000,000
		if(OVERALLSOLD >= RANGESTART_9 && OVERALLSOLD <= RANGEEND_9)
			{
			PRICE = PRICE_9 - (1 + OVERALLSOLD - RANGESTART_9).div(FACTOR_9);
			}
		
		//Stage Ten 70,000,001 - 80,000,000
		if(OVERALLSOLD >= RANGESTART_10 && OVERALLSOLD <= RANGEEND_10)
			{
			PRICE = PRICE_10 - (1 + OVERALLSOLD - RANGESTART_10).div(FACTOR_10);
			}	
		
		//Stage Eleven 80,000,001 - 85,000,000
		if(OVERALLSOLD >= RANGESTART_11 && OVERALLSOLD <= RANGEEND_11)
			{
			PRICE = PRICE_11 - (1 + OVERALLSOLD - RANGESTART_11).div(FACTOR_11);
			}
		}
		
	
   }

	 
   function submitEther(address recipient) payable {
     if (msg.value == 0) {
       throw;
     }

     if (!recipient.send(msg.value)) {
       throw;
     }
    
   }


  //Unicorn Shoutbox

  struct MessageQueue {
           string message; 
  		   string from;
           uint expireTimestamp;  
           uint startTimestamp;
           address sender; 
       }

	 
     uint256 public constant maxSpendToken = 3600; //Message should last approx. 1 hour max

     MessageQueue[] public mQueue;
 
	
 
      function addMessageToQueue(string msg_from, string name_from, uint spendToken) {
        if(balances[msg.sender]>spendToken && spendToken>=10)
        {
           if(spendToken>maxSpendToken) 
               {
                   spendToken=maxSpendToken;
               }
           
		   UniCoinSize=UniCoinSize+spendToken;
           
           balances[msg.sender] = balances[msg.sender].sub(spendToken);
          
		  //If first message or last message already expired set newest timestamp
  		  uint expireTimestamp=now;
		  if(mQueue.length>0)
			{
			 if(mQueue[mQueue.length-1].expireTimestamp>now)
			 	{
			 	expireTimestamp = mQueue[mQueue.length-1].expireTimestamp;
				}
			} 
		
		 
		 
           mQueue.push(MessageQueue({
                   message: msg_from, 
  				   from: name_from,
                   expireTimestamp: expireTimestamp.add(spendToken)+60,  //give at least approx 60 seconds per msg
                   startTimestamp: expireTimestamp,
                   sender: msg.sender
               }));
    
        
		 
        }
		else {
		      throw;
		      }
      }
	  
	
    function feedUnicorn(uint spendToken) {
	
   	 	if(balances[msg.sender]>spendToken)
        	{
       	 	UniCoinSize=UniCoinSize.add(spendToken);
        	balances[msg.sender] = balances[msg.sender].sub(spendToken);
			}
		
	 } 
	
	
   function getQueueLength() public constant returns (uint256 result) {
	 return mQueue.length;
   }
   function getMessage(uint256 i) public constant returns (string, string, uint, uint, address){
     return (mQueue[i].message,mQueue[i].from,mQueue[i].expireTimestamp,mQueue[i].startTimestamp,mQueue[i].sender );
   }
   function getPrice() constant returns (uint256 result) {
     return PRICE;
   }
   function getSupply() constant returns (uint256 result) {
     return totalSupply;
   }
   function getSold() constant returns (uint256 result) {
     return OVERALLSOLD;
   }
   function getUniCoinSize() constant returns (uint256 result) {    
     return UniCoinSize; 
   } 
    function getAddress() constant returns (address) {
     return this;
   }
    


  
   // ADMIN Functions

   
   //In emergency cases to stop or change timings 
   function aSetStart(uint256 nstart) onlyOwner {
     start=nstart;
   }
   function aSetEnd(uint256 nend) onlyOwner {
     end=nend;
   }
   function aSetLaunch(uint256 nlaunch) onlyOwner {
     launch=nlaunch;
   }
    

   //We don't want the Unicorn to spread hateful messages 
   function aDeleteMessage(uint256 i,string f,string m) onlyOwner{
     mQueue[i].message=m;
	 mQueue[i].from=f; 
		 }
   
   //Clean house from time to time
   function aPurgeMessages() onlyOwner{
   delete mQueue; 
   }

 }