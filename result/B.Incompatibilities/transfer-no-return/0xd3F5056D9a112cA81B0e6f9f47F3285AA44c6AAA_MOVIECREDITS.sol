/**
*MOVIECREDITS: "P2P PAYMENT SYSTEM FOR THE MOVIE INDUSTRY.."
 * CONTRACT CREATOR: MOVIECREDITS/TEAM &  CRYPTO7.BIZ
 * The MOVIECREDITS (EMVC) token contract complies with the ERC20 standard
** (see https://github.com/ethereum/EIPs/issues/20).
 *CENSORSHIP PROTECTION=TRUE| DECIMALS=2
 * SUPPLY = 60000000= 60 M  (EMVC) BUY: RATE= 750 EMVC/ETH
 * */
pragma solidity ^0.4.8;
contract SafeMath{
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
	
	function safeSub(uint a, uint b) internal returns (uint) {
    	assert(b <= a);
    	return a - b;
  }

	function safeAdd(uint a, uint b) internal returns (uint) {
    	uint c = a + b;
    	assert(c >= a);
    	return c;
  }
	function assert(bool assertion) internal {
	    if (!assertion) {
	      return;

	    }
	}
}

       

contract ERC20Moviecredits{

 	function totalSupply() constant returns (uint256 totalSupply) {}
	function balanceOf(address _owner) constant returns (uint256 balance) {}

	function transferFrom(address _from, address _recipient, uint256 _value) returns (bool success) {}
	function approve(address _spender, uint256 _value) returns (bool success) {}
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

	event Transfer(address indexed _from, address indexed _recipient, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}

contract MOVIECREDITS is ERC20Moviecredits, SafeMath{

	
	mapping(address => uint256) balances;

	uint256 public totalSupply;


	function balanceOf(address _owner) constant returns (uint256 balance) {
	    return balances[_owner];
	}

   //** * @dev Fix for the ERC20 short address attack. */
 modifier onlyPayloadSize(uint size) { if(msg.data.length < size + 4) { throw; } _; } 

 function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) { 
 balances[msg.sender] = safeSub(balances[msg.sender], _value);
	    balances[_to] = safeAdd(balances[_to], _value);
	    Transfer(msg.sender,_to,_value); }


	mapping (address => mapping (address => uint256)) allowed;

	function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
	    var _allowance = allowed[_from][msg.sender];
	    
	    balances[_to] = safeAdd(balances[_to], _value);
	    balances[_from] = safeSub(balances[_from], _value);
	    allowed[_from][msg.sender] = safeSub(_allowance, _value);
	    Transfer(_from, _to, _value);
	    return true;
	}

	function approve(address _spender, uint256 _value) returns (bool success) {
	    allowed[msg.sender][_spender] = _value;
	    Approval(msg.sender, _spender, _value);
	    return true;
	}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
	    return allowed[_owner][_spender];
	}




	uint256 public endTime;

	modifier during_offering_time(){
		if (now >= endTime){
			return;

		}else{
			_;
		}
	}

	function () payable during_offering_time {
		createTokens(msg.sender);
	}

	function createTokens(address recipient) payable {
		if (msg.value == 0) {
		 return;

		}

		uint tokens = safeDiv(safeMul(msg.value, price), 1 ether);
		totalSupply = safeSub(totalSupply, tokens);

		balances[recipient] = safeAdd(balances[recipient], tokens);

		if (!owner.send(msg.value)) {
		return;
		}
	}
	string 	public name = "MOVIECREDITS (EMVC)";
	string 	public symbol = "EMVC";
	uint 	public decimals = 2;
	uint256 public INITIAL_SUPPLY = 6000000000;
    
	uint256 public price;
	address public owner;

	function MOVIECREDITS() {
		totalSupply = INITIAL_SUPPLY;
balances[msg.sender] = INITIAL_SUPPLY;  // Give all of the initial tokens to the contract deployer.
		endTime = now + 5 weeks;
		owner 	= msg.sender;
		price 	= 75000;
	}
}