/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20Interface {
    function totalSupply() constant returns (uint supply) {}
    function balanceOf(address _owner) constant returns (uint balance) {}
    function transfer(address _to, uint _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {}
    function approve(address _spender, uint _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}



contract WrapperLock is BasicToken {

  address ZEROEX_PROXY = 0x8da0d80f5007ef1e431dd2127178d224e32c2ef4;
  address ETHFINEX;

  string public name;
  string public symbol;
  uint public decimals;
  address public originalToken;

  mapping (address => uint) public depositLock;

  function WrapperLock(address _originalToken, string _name, string _symbol, uint _decimals) {
    originalToken = _originalToken;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    ETHFINEX = 0x5A2143B894C9E8d8DFe2A0e8B80d7DB2689fC382;
  }

  function deposit(uint _value, uint _forTime) returns (bool success) {
    require (_forTime >= 1);
    require (now + _forTime * 1 hours >= depositLock[msg.sender]);
    success = ERC20Interface(originalToken).transferFrom(msg.sender, this, _value);
    if(success) {
      balances[msg.sender] = balances[msg.sender].add(_value);
      depositLock[msg.sender] = now + _forTime * 1 hours;
    }
  }

  function withdraw(uint8 v, bytes32 r, bytes32 s, uint _value, uint signatureValidUntilBlock) returns (bool success) {
    require(balanceOf(msg.sender) >= _value);
    if (now > depositLock[msg.sender]){
      balances[msg.sender] = balances[msg.sender].sub(_value);
      success = ERC20Interface(originalToken).transfer(msg.sender, _value);
    }
    else {
      require(block.number < signatureValidUntilBlock);
      require(isValidSignature(ETHFINEX, keccak256(msg.sender, _value, signatureValidUntilBlock), v, r, s));
      balances[msg.sender] = balances[msg.sender].sub(_value);
      success = ERC20Interface(originalToken).transfer(msg.sender, _value);
    }
  }

  function transferFrom(address _from, address _to, uint _value) {
    assert(msg.sender == ZEROEX_PROXY);
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    Transfer(_from, _to, _value);
  }

  function allowance(address owner, address spender) returns (uint) {
    if(spender == ZEROEX_PROXY) {
      return 2**256 - 1;
    }
  }

  function isValidSignature(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public
        constant
        returns (bool)
    {
        return signer == ecrecover(
            keccak256("\x19Ethereum Signed Message:\n32", hash),
            v,
            r,
            s
        );
    }

}