pragma solidity ^0.4.17;

library SafeMath {
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint public totalSupply;
  address public owner; //owner
  function balanceOf(address who) constant public returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint;
  mapping(address => uint) balances;

  modifier onlyPayloadSize(uint size) {
     assert(msg.data.length >= size + 4);
     _;
  }
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    if(_to == address(this)) {
        balances[owner] = balances[owner].add(_value);
        Transfer(msg.sender, owner, _value);
    }
    else {
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }
  }
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant public returns (uint balance) {
    return balances[_owner];
  }
}

contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    allowed[_from][msg.sender] = _allowance.sub(_value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
  }
  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) public {
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    assert(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }
  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant public returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

/**
 * @title SmartBillions contract
 */
contract HodlReligion is StandardToken {

    // metadata
    string public constant name = "HODL Religion Token";
    string public constant symbol = "HODL"; // changed due to conflicts
    uint public constant decimals = 18;

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    // constructor
    function HodlReligion() public {
        owner = msg.sender;
        totalSupply = 200000000 * 10**18; // 100M
        balances[this] = totalSupply;
    }

    /**
     * @dev Send ether to buy tokens during ICO
     * @dev or send less than 1 ether to contract to play
     * @dev or send 0 to collect prize
     */
    function () payable external {
        if(msg.value > 0){
            transfer(msg.sender, 10 ** 18); // 1 Token
        }
    }

    function faucet() payable external {
        if(msg.value > 0){
            transfer(msg.sender, 10 ** 18); // 1 Token
        }
    }
}