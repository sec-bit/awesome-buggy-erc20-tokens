pragma solidity ^0.4.18;

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}


contract ContractReceiver {
	function tokenFallback(address _from, uint _value, bytes _data) public pure;
}

contract SafeMath
{
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
      }
    
	function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}
	
	function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}
	
	function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}
}

contract protoLEXToken is ERC223, SafeMath{
	mapping(address => uint) balances;
	string public name = "proto-Limited Exchange Token";
	string public symbol = "pLEX";
	uint8 public decimals = 0; // Using a Satoshi as base for our decimals: 0.00000001;
	uint256 public totalSupply = 2000000000; // 2,000,000,000 LEX's, not mineable, not mintable;
	
	address admin;
	
	modifier onlyAdmin()
	{
	    require(msg.sender == admin);
	    _;
	}
	
	function protoLEXToken() public {
		balances[msg.sender] = totalSupply;
	}
	  
	// Function to access name of token .
	function name() public view returns (string _name) {
		return name;
	}
	// Function to access symbol of token .
	function symbol() public view returns (string _symbol) {
		return symbol;
	}
	// Function to access decimals of token .
	function decimals() public view returns (uint8 _decimals) {
		return decimals;
	}
	// Function to access total supply of tokens .
	function totalSupply() public view returns (uint256 _totalSupply) {
		return totalSupply;
	}
	  
	  
	// Function that is called when a user or another contract wants to transfer funds .
	function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
		if(isContract(_to)) {
			if (balanceOf(msg.sender) < _value) revert();
			balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
			balances[_to] = safeAdd(balanceOf(_to), _value);
			assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
			Transfer(msg.sender, _to, _value, _data);
			return true;
		}
		else {
			return transferToAddress(_to, _value, _data);
		}
	}
	  

	// Function that is called when a user or another contract wants to transfer funds .
	function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
		if(isContract(_to)) {
			return transferToContract(_to, _value, _data);
		}
		else {
			return transferToAddress(_to, _value, _data);
		}
	}
	  
	// Standard function transfer similar to ERC20 transfer with no _data .
	// Added due to backwards compatibility reasons .
	function transfer(address _to, uint _value) public returns (bool success) {
		//standard function transfer similar to ERC20 transfer with no _data
		//added due to backwards compatibility reasons
		bytes memory empty;
		if(isContract(_to)) {
			return transferToContract(_to, _value, empty);
		}
		else {
			return transferToAddress(_to, _value, empty);
		}
	}

	//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
	function isContract(address _addr) private view returns (bool is_contract) {
		uint length;
		assembly {
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}
		return (length>0);
	}

	//function that is called when transaction target is an address
	function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
		if (balanceOf(msg.sender) < _value) revert();
		balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
		balances[_to] = safeAdd(balanceOf(_to), _value);
		Transfer(msg.sender, _to, _value, _data);
		return true;
	}
	  
	  //function that is called when transaction target is a contract
	function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
		if (balanceOf(msg.sender) < _value) revert();
		balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
		balances[_to] = safeAdd(balanceOf(_to), _value);
		ContractReceiver receiver = ContractReceiver(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		Transfer(msg.sender, _to, _value, _data);
		return true;
	}
		
	function balanceOf(address _owner) public view returns (uint balance) {
		return balances[_owner];
	}
	
	/*
	* Prototype functions for the full LEX Token
	*/
	
	function AddToWhitelist(address addressToWhitelist) public onlyAdmin
	{
	}
	
	function RegisterContract() public
	{
	}
	
	function RecallTokensFromContract() public onlyAdmin
	{
	}
	
	function supplyAvailable() public view returns (uint supply) {
		return 0;
	}
	function supplyInCirculation() public view returns (uint inCirculation) {
		return 0;
	}
	
}