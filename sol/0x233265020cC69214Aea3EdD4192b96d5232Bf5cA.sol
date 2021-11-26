pragma solidity ^0.4.17;

//Slightly modified SafeMath library - includes a min function
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

//Swap interface- descriptions can be found in TokenToTokenSwap.sol
interface TokenToTokenSwap_Interface {
  function CreateSwap(uint _amount_a, uint _amount_b, bool _sender_is_long, address _senderAdd) public payable;
  function EnterSwap(uint _amount_a, uint _amount_b, bool _sender_is_long, address _senderAdd) public;
  function createTokens() public;
}


//Swap factory functions - descriptions can be found in Factory.sol
interface Factory_Interface {
  function createToken(uint _supply, address _party, bool _long, uint _start_date) public returns (address created, uint token_ratio);
  function payToken(address _party, address _token_add) public;
  function deployContract(uint _start_date) public payable returns (address created);
   function getBase() public view returns(address _base1, address base2);
  function getVariables() public view returns (address oracle_addr, uint swap_duration, uint swap_multiplier, address token_a_addr, address token_b_addr);
}


//This is the basic wrapped Ether contract. 
//All money deposited is transformed into ERC20 tokens at the rate of 1 wei = 1 token
contract Wrapped_Ether {

  using SafeMath for uint256;

  /*Variables*/

  //ERC20 fields
  string public name = "Wrapped Ether";
  uint public total_supply;


  //ERC20 fields
  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

  /*Events*/

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
  event StateChanged(bool _success, string _message);

  /*Functions*/

  //This function creates tokens equal in value to the amount sent to the contract
  function CreateToken() public payable {
    require(msg.value > 0);
    balances[msg.sender] = balances[msg.sender].add(msg.value);
    total_supply = total_supply.add(msg.value);
  }

  /*
  * This function 'unwraps' an _amount of Ether in the sender's balance by transferring Ether to them
  *
  * @param "_amount": The amount of the token to unwrap
  */
  function withdraw(uint _value) public {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    total_supply = total_supply.sub(_value);
    msg.sender.transfer(_value);
  }

  //Returns the balance associated with the passed in _owner
  function balanceOf(address _owner) public constant returns (uint bal) { return balances[_owner]; }

  /*
  * Allows for a transfer of tokens to _to
  *
  * @param "_to": The address to send tokens to
  * @param "_amount": The amount of tokens to send
  */
  function transfer(address _to, uint _amount) public returns (bool success) {
    if (balances[msg.sender] >= _amount
    && _amount > 0
    && balances[_to] + _amount > balances[_to]) {
      balances[msg.sender] = balances[msg.sender].sub(_amount);
      balances[_to] = balances[_to].add(_amount);
      Transfer(msg.sender, _to, _amount);
      return true;
    } else {
      return false;
    }
  }

  /*
  * Allows an address with sufficient spending allowance to send tokens on the behalf of _from
  *
  * @param "_from": The address to send tokens from
  * @param "_to": The address to send tokens to
  * @param "_amount": The amount of tokens to send
  */
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    if (balances[_from] >= _amount
    && allowed[_from][msg.sender] >= _amount
    && _amount > 0
    && balances[_to] + _amount > balances[_to]) {
      balances[_from] = balances[_from].sub(_amount);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
      balances[_to] = balances[_to].add(_amount);
      Transfer(_from, _to, _amount);
      return true;
    } else {
      return false;
    }
  }

  //Approves a _spender an _amount of tokens to use
  function approve(address _spender, uint _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  //Returns the remaining allowance of tokens granted to the _spender from the _owner
  function allowance(address _owner, address _spender) public view returns (uint remaining) { return allowed[_owner][_spender]; }
}

//The User Contract enables the entering of a deployed swap along with the wrapping of Ether.  This contract was specifically made for drct.decentralizedderivatives.org to simplify user metamask calls
contract UserContract{
  TokenToTokenSwap_Interface swap;
  Wrapped_Ether token;
  Factory_Interface factory;

  address public factory_address;
  address owner;

  function UserContract() public {
      owner = msg.sender;
  }

  //The _swapAdd is the address of the deployed contract created from the Factory contract.
  //_amounta and _amountb are the amounts of token_a and token_b (the base tokens) in the swap.  For wrapped Ether, this is wei.
  //_premium is a base payment to the other party for taking the other side of the swap
  // _isLong refers to whether the sender is long or short the reference rate
  //Value must be sent with Initiate and Enter equivalent to the _amounta(in wei) and the premium, and _amountb respectively

  function Initiate(address _swapadd, uint _amounta, uint _amountb, uint _premium, bool _isLong) payable public returns (bool) {
    require(msg.value == _amounta + _premium);
    swap = TokenToTokenSwap_Interface(_swapadd);
    swap.CreateSwap.value(_premium)(_amounta, _amountb, _isLong, msg.sender);
    address token_a_address;
    address token_b_address;
    (token_a_address,token_b_address) = factory.getBase();
    token = Wrapped_Ether(token_a_address);
    token.CreateToken.value(_amounta)();
    bool success = token.transfer(_swapadd,_amounta);
    return success;
  }

  function Enter(uint _amounta, uint _amountb, bool _isLong, address _swapadd) payable public returns(bool){
    require(msg.value ==_amountb);
    swap = TokenToTokenSwap_Interface(_swapadd);
    swap.EnterSwap(_amounta, _amountb, _isLong,msg.sender);
    address token_a_address;
    address token_b_address;
    (token_a_address,token_b_address) = factory.getBase();
    token = Wrapped_Ether(token_b_address);
    token.CreateToken.value(_amountb)();
    bool success = token.transfer(_swapadd,_amountb);
    swap.createTokens();
    return success;

  }


  function setFactory(address _factory_address) public {
      require (msg.sender == owner);
    factory_address = _factory_address;
    factory = Factory_Interface(factory_address);
  }
}