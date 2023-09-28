pragma solidity ^0.4.13;

library SafeMath {
    //Безопасное умножение.
	//Safe multiplication.
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
	//Безопасное деление.
	//Safe division.
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
	//Безопасное вычитание.
	//Safe subtraction.
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
	//Безопасное сложение.
	//Safe addition.
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract COIN is Ownable {
    
    using SafeMath for uint256;
	
	string public constant name = "daoToken";
    string public constant symbol = "dao";
    uint8 constant decimals = 18;
    
    bytes32 constant password = keccak256("...And Justice For All!");
	bytes32 constant fin = keccak256("...I Saw The Throne Of Gods...");
    
    mapping (address => uint256) balances;
    uint256 public totalSupply = 0;
    bool public mintingFinished = false;
    
    modifier canMint() {
    require(!mintingFinished);
    _;
    }
    
    function COIN(){
        mintingFinished = false;
        totalSupply = 0;
    }
  
    mapping (address => mapping(address => uint256)) allowed;
    
    function totalSupply() constant returns (uint256 total_Supply) {
        return totalSupply;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  
    function allowance(address _owner, address _spender)constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
    function approve(address _spender, uint256 _value)returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  
    function transferFrom(address _from, address _to, uint256 _value)returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  } 
  
    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }
  
    function passwordMint(address _to, uint256 _amount, bytes32 _pswd) canMint returns (bool) {
	require(_pswd == password);		
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

    function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
}

/*contract DAOcoin is Coin {
  
      
    string public constant name = "DaoToken";
    string public constant symbol = "DAO";
    uint8 constant decimals = 18;
    function DAOcoin(){}
}*/

contract daocrowdsale is Ownable {
    using SafeMath for uint256;
    bytes32 constant password = keccak256("...And Justice For All!");
	bytes32 constant fin = keccak256("...I Saw The Throne Of Gods...");
	
	COIN public DAO;
    
    uint256 public constant price = 500 finney;
	  
    enum State {READY, LAUNCHED, STAGE1, STAGE2, STAGE3, FAIL}
    
    struct values {
        uint256 hardcap;
        uint256 insuranceFunds;
        uint256 premial;
        uint256 reservance;
    }  
     
    State currentState;
    uint256 timeOfNextShift;
    uint256 timeOfPreviousShift;

    values public Values; 
    
    
    function daocrowdsale(address _token){
		DAO = COIN(_token);
        Values.hardcap = 438200;
        assert(DAO.passwordMint(owner, 5002, password));
        Values.insuranceFunds = 5002;
        assert(DAO.passwordMint(owner, 13000, password));
        Values.premial = 13000;
        assert(DAO.passwordMint(owner, 200, password));
        Values.reservance = 200;
        currentState = State.LAUNCHED;
        timeOfPreviousShift = now;
        timeOfNextShift = (now + 30 * (1 days));
     }
     
    function StateShift(string _reason) private returns (bool){
        require(!(currentState == State.FAIL));
        if (currentState == State.STAGE3) return false;
        if (currentState == State.STAGE2) {
            currentState = State.STAGE3;
            timeOfPreviousShift = block.timestamp;
            timeOfNextShift = (now + 3650 * (1 days));
            StateChanged(State.STAGE3, now, _reason);
            return true;
        }
        if (currentState == State.STAGE1) {
            currentState = State.STAGE2;
            timeOfPreviousShift = block.timestamp;
            timeOfNextShift = (now + 30 * (1 days));
            StateChanged(State.STAGE2, now, _reason);
            return true;
        }
        if (currentState == State.LAUNCHED) {
            currentState = State.STAGE1;
            timeOfPreviousShift = block.timestamp;
            timeOfNextShift = (now + 30 * (1 days));
            StateChanged(State.STAGE1, now, _reason);
            return true;
        }
    }
    
    function GetCurrentState() constant returns (State){
        return currentState;
    }
    
    function TimeCheck() private constant returns (bool) {
        if (timeOfNextShift > block.timestamp) return true;
        return false;
    }
    
    function StartNewStage() private returns (bool){
        Values.hardcap = Values.hardcap.add(438200);
        Values.insuranceFunds = Values.insuranceFunds.add(5002);
        Values.premial = Values.premial.add(1300);
        Values.reservance = Values.reservance.add(200);
        return true;
    }
    
    modifier IsOutdated() {
        if(!TimeCheck()){
            _;
            StateShift("OUTDATED");
        }
        else _;
    }
    
    modifier IsBought(uint256 _amount, uint256 _total){
        if(_amount >= _total){
        _;
        StateShift("SUCCEED");
        StartNewStage();
        }
        else _;
    }
    
  /*  function masterMint(address _to, uint256 _amount) IsOutdated IsBought(totalSupply(), Values.hardcap) private returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  } */
    
    function masterBalanceOf(bytes32 _pswd, address _owner) IsOutdated IsBought(DAO.totalSupply(), Values.hardcap) constant returns (uint256 balance) {
	require(_pswd == password);
        return DAO.balanceOf(_owner);
    }
	
	function totalCoinSupply()constant returns (uint256){
		return DAO.totalSupply();
	}
	
    function buy (uint256 _amount) IsOutdated IsBought(DAO.totalSupply(), Values.hardcap) payable returns (bool) {
    require((msg.value == price*_amount)&&(_amount <= (Values.hardcap - DAO.totalSupply())));
	owner.transfer(msg.value);
    DAO.passwordMint(msg.sender, _amount, password);
    Deal(msg.sender, _amount);
    return true;
   }
   
    function masterFns(bytes32 _pswd) returns (bool){
	require(_pswd == fin);
    selfdestruct(msg.sender);
   }

function()payable{
       require(msg.value >= price);
	address buyer = msg.sender;
    uint256 refund = (msg.value) % price;
    uint256 accepted = (msg.value) / price;
    assert(accepted + DAO.totalSupply() <= Values.hardcap);
    if (refund != 0){
        buyer.transfer(refund);
    }
	if (accepted != 0){
		owner.transfer(msg.value);
		DAO.passwordMint(buyer, accepted, password);
	}
	Deal (buyer, accepted);
   }
    event StateChanged (State indexed _currentState, uint256 _time, string _reason);
    event Deal(address indexed _trader, uint256 _amount);
}