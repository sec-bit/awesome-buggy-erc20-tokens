pragma solidity ^0.4.11;

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

contract KolkhaCoin {

  modifier msgDataSize(uint nVar) {assert(msg.data.length == nVar*32 + 4); _ ;}

  string public constant name = "Kolkha";
  string public constant symbol = "KHC";
  uint public constant decimals = 6;
  uint public totalSupply;

  using SafeMath for uint;

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approved(address indexed _owner, address indexed _spender, uint _value);

  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;

  function KolkhaCoin(uint initialSupply){
    balanceOf[msg.sender] = initialSupply;
    totalSupply = initialSupply;
  }

  function transfer(address _to, uint _value) public msgDataSize(2) returns(bool success)
  {
    success = false;
    require(balanceOf[msg.sender] >= _value); //Check if the sender has enough balance
    require(balanceOf[_to].add(_value) > balanceOf[_to]); //Avoid overflow, and _value=0
    require(_value > 0); //just to be safe

    //Perform the transfer
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);

    Transfer(msg.sender, _to, _value); //Fire the event
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public msgDataSize(3) returns (bool success)  {
    require(allowance[_from][_to] >= _value); //check allowance, from _from to _to
    require(balanceOf[_from] >= _value); //Check if there's enough coins on the _from account
    require(balanceOf[_to].add(_value) > balanceOf[_to]); //Avoid overflow, and _value = 0
    require(_value > 0); //Just in case

    //Transfer
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);

    //Retract _value coins from allowance
    allowance[_from][_to] = allowance[_from][_to].sub(_value);

    //Fire the event
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) public msgDataSize(2) returns(bool success) {
    success = false;
    allowance[msg.sender][_spender] = _value;
    Approved(msg.sender, _spender, _value);
    return true;
  }

  //Once the block is mined
  /*uint public constant blockReward = 1e6;
  function claimBlockReward() {
    balanceOf[block.coinbase] += blockReward;
    totalSupply += blockReward;
  }*/
}