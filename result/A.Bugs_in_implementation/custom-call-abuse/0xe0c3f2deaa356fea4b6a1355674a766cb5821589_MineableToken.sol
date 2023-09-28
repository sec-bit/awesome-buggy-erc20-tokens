// compiler: 0.4.21+commit.dfe3193c.Emscripten.clang
pragma solidity ^0.4.21;

// Ethereum Token callback
interface tokenRecipient {
  function receiveApproval( address from, uint256 value, bytes data ) external;
}

// ERC223 callback
interface ContractReceiver {
  function tokenFallback( address from, uint value, bytes data ) external;
}

contract owned {
  address public owner;

  function owned() public {
    owner = msg.sender;
  }

  function changeOwner( address _miner ) public onlyOwner {
    owner = _miner;
  }

  modifier onlyOwner {
    require (msg.sender == owner);
    _;
  }
}

// ERC20 token with added ERC223 and Ethereum-Token support
//
// Blend of multiple interfaces:
// - https://theethereum.wiki/w/index.php/ERC20_Token_Standard
// - https://www.ethereum.org/token (uncontrolled, non-standard)
// - https://github.com/Dexaran/ERC23-tokens/blob/Recommended/ERC223_Token.sol

contract MineableToken is owned {

  string  public name;
  string  public symbol;
  uint8   public decimals;
  uint256 public totalSupply;

  uint256 public supplyCap;

  mapping( address => uint256 ) balances_;

  mapping( address => mapping(address => uint256) ) allowances_;

  // ERC20
  event Approval( address indexed owner,
                  address indexed spender,
                  uint value );

  // ERC20-compatible version only, breaks ERC223 compliance but etherscan
  // and exchanges only support ERC20 version. Can't overload events

  event Transfer( address indexed from,
                  address indexed to,
                  uint256 value );
                  //bytes    data );

  // Ethereum Token
  event Burn( address indexed from,
              uint256 value );

  function MineableToken() public {

    decimals = uint8(18); // audit recommended 18 decimals
    supplyCap = 833333333 * 10**uint256(decimals);

    name = "ORST";
    symbol = "ORS";
  }

  function mine( uint256 qty ) public onlyOwner {
    require (    (totalSupply + qty) > totalSupply
              && (totalSupply + qty) <= supplyCap
            );

    totalSupply += qty;
    balances_[owner] += qty;
    emit Transfer( address(0), owner, qty );
  }

  function cap() public constant returns(uint256) {
    return supplyCap;
  }

  // ERC20
  function balanceOf( address owner ) public constant returns (uint) {
    return balances_[owner];
  }

  // ERC20
  function approve( address spender, uint256 value ) public
  returns (bool success)
  {
    // WARNING! When changing the approval amount, first set it back to zero
    // AND wait until the transaction is mined. Only afterwards set the new
    // amount. Otherwise you may be prone to a race condition attack.
    // See: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

    allowances_[msg.sender][spender] = value;
    emit Approval( msg.sender, spender, value );
    return true;
  }
 
  // recommended fix for known attack on any ERC20
  function safeApprove( address _spender,
                        uint256 _currentValue,
                        uint256 _value ) public
  returns (bool success)
  {
    // If current allowance for _spender is equal to _currentValue, then
    // overwrite it with _value and return true, otherwise return false.

    if (allowances_[msg.sender][_spender] == _currentValue)
      return approve(_spender, _value);

    return false;
  }

  // ERC20
  function allowance( address owner, address spender ) public constant
  returns (uint256 remaining)
  {
    return allowances_[owner][spender];
  }

  // ERC20
  function transfer(address to, uint256 value) public
  {
    bytes memory empty; // null
    _transfer( msg.sender, to, value, empty );
  }

  // ERC20
  function transferFrom( address from, address to, uint256 value ) public
  returns (bool success)
  {
    require( value <= allowances_[from][msg.sender] );

    allowances_[from][msg.sender] -= value;
    bytes memory empty;
    _transfer( from, to, value, empty );

    return true;
  }

  // Ethereum Token
  function approveAndCall( address spender,
                           uint256 value,
                           bytes context ) public
  returns (bool success)
  {
    if ( approve(spender, value) )
    {
      tokenRecipient recip = tokenRecipient( spender );

      if (isContract(recip))
        recip.receiveApproval( msg.sender, value, context );

      return true;
    }

    return false;
  }        

  // Ethereum Token
  function burn( uint256 value ) public
  returns (bool success)
  {
    require( balances_[msg.sender] >= value );
    balances_[msg.sender] -= value;
    totalSupply -= value;

    emit Burn( msg.sender, value );
    return true;
  }

  // Ethereum Token
  function burnFrom( address from, uint256 value ) public
  returns (bool success)
  {
    require( balances_[from] >= value );
    require( value <= allowances_[from][msg.sender] );

    balances_[from] -= value;
    allowances_[from][msg.sender] -= value;
    totalSupply -= value;

    emit Burn( from, value );
    return true;
  }

  // ERC223 Transfer and invoke specified callback
  function transfer( address to,
                     uint value,
                     bytes data,
                     string custom_fallback ) public returns (bool success)
  {
    _transfer( msg.sender, to, value, data );

    // throws if custom_fallback is not a valid contract call
    require( address(to).call.value(0)(bytes4(keccak256(custom_fallback)),
             msg.sender,
             value,
             data) );

    return true;
  }

  // ERC223 Transfer to a contract or externally-owned account
  function transfer( address to, uint value, bytes data ) public
  returns (bool success)
  {
    if (isContract(to)) {
      return transferToContract( to, value, data );
    }

    _transfer( msg.sender, to, value, data );
    return true;
  }

  // ERC223 Transfer to contract and invoke tokenFallback() method
  function transferToContract( address to, uint value, bytes data ) private
  returns (bool success)
  {
    _transfer( msg.sender, to, value, data );

    ContractReceiver rx = ContractReceiver(to);

    if (isContract(rx)) {
      rx.tokenFallback( msg.sender, value, data );
      return true;
    }

    return false;
  }

  // ERC223 fetch contract size (must be nonzero to be a contract)
  function isContract( address _addr ) private constant returns (bool)
  {
    uint length;
    assembly { length := extcodesize(_addr) }
    return (length > 0);
  }

  function _transfer( address from,
                      address to,
                      uint value,
                      bytes data ) internal
  {
    require( to != 0x0 );
    require( balances_[from] >= value );
    require( balances_[to] + value > balances_[to] ); // catch overflow

    // no transfers allowed before ICO ends 26MAY2018 0900 CET
    if (msg.sender != owner) require( now >= 1527321600 );

    balances_[from] -= value;
    balances_[to] += value;

    bytes memory ignore;
    ignore = data;                    // ignore compiler warning
    emit Transfer( from, to, value ); // ignore data
  }
}