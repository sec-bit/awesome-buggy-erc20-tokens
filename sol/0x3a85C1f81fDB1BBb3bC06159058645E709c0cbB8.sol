pragma solidity ^0.4.18;

contract useContractWeb {

  ContractWeb internal web = ContractWeb(0xA2a7F4bf61b5bf07611739941F62Dec30541840A);

}

contract Owned {

  address public owner = msg.sender;

  function transferOwner(address _newOwner) onlyOwner public returns (bool) {
    owner = _newOwner;
    return true;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

}

contract CheckPayloadSize {

  modifier onlyPayloadSize(uint256 _size) {
    require(msg.data.length >= _size + 4);
    _;
  }

}

contract CanTransferTokens is CheckPayloadSize, Owned {

  function transferCustomToken(address _token, address _to, uint256 _value) onlyPayloadSize(3 * 32) onlyOwner public returns (bool) {
    Token tkn = Token(_token);
    return tkn.transfer(_to, _value);
  }

}

contract SafeMath {

  function add(uint256 x, uint256 y) pure internal returns (uint256) {
    require(x <= x + y);
    return x + y;
  }

  function sub(uint256 x, uint256 y) pure internal returns (uint256) {
    require(x >= y);
    return x - y;
  }

}

contract CheckIfContract {

  function isContract(address _addr) view internal returns (bool) {
    uint256 length;
    if (_addr == address(0x0)) return false;
    assembly {
      length := extcodesize(_addr)
    }
    if(length > 0) {
      return true;
    } else {
      return false;
    }
  }
}

contract ContractReceiver {

  TKN internal fallback;

  struct TKN {
    address sender;
    uint256 value;
    bytes data;
    bytes4 sig;
  }

  function getFallback() view public returns (TKN) {
    return fallback;
  }


  function tokenFallback(address _from, uint256 _value, bytes _data) public returns (bool) {
    TKN memory tkn;
    tkn.sender = _from;
    tkn.value = _value;
    tkn.data = _data;
    uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
    tkn.sig = bytes4(u);
    fallback = tkn;
    return true;
  }

}

contract Token1st {

  address public currentTradingSystem;
  address public currentExchangeSystem;

  mapping(address => uint) public balanceOf;
  mapping(address => mapping (address => uint)) public allowance;
  mapping(address => mapping (address => uint)) public tradingBalanceOf;
  mapping(address => mapping (address => uint)) public exchangeBalanceOf;

  /* @notice get balance of a specific address */
  function getBalanceOf(address _address) view public returns (uint amount){
    return balanceOf[_address];
  }

  event Transfer (address _to, address _from, uint _decimalAmount);

  /* A contract or user attempts to get the coins */
  function transferDecimalAmountFrom(address _from, address _to, uint _value) public returns (bool success) {
    require(balanceOf[_from]
      - tradingBalanceOf[_from][currentTradingSystem]
      - exchangeBalanceOf[_from][currentExchangeSystem] >= _value);                 // Check if the sender has enough
    require(balanceOf[_to] + (_value) >= balanceOf[_to]);  // Check for overflows
    require(_value <= allowance[_from][msg.sender]);   // Check allowance
    balanceOf[_from] -= _value;                          // Subtract from the sender
    balanceOf[_to] += _value;                            // Add the same to the recipient
    allowance[_from][msg.sender] -= _value;
    Transfer(_to, _from, _value);
    return true;
  }

    /* Allow another contract or user to spend some tokens in your behalf */
  function approveSpenderDecimalAmount(address _spender, uint _value) public returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    return true;
  }

}

contract ContractWeb is CanTransferTokens, CheckIfContract {

      //contract name | contract info
  mapping(string => contractInfo) internal contracts;

  event ContractAdded(string _name, address _referredTo);
  event ContractEdited(string _name, address _referredTo);
  event ContractMadePermanent(string _name);

  struct contractInfo {
    address contractAddress;
    bool isPermanent;
  }

  function getContractAddress(string _name) view public returns (address) {
    return contracts[_name].contractAddress;
  }

  function isContractPermanent(string _name) view public returns (bool) {
    return contracts[_name].isPermanent;
  }

  function setContract(string _name, address _address) onlyPayloadSize(2 * 32) onlyOwner public returns (bool) {
    require(isContract(_address));
    require(this != _address);
    require(contracts[_name].contractAddress != _address);
    require(contracts[_name].isPermanent == false);
    address oldAddress = contracts[_name].contractAddress;
    contracts[_name].contractAddress = _address;
    if(oldAddress == address(0x0)) {
      ContractAdded(_name, _address);
    } else {
      ContractEdited(_name, _address);
    }
    return true;
  }

  function makeContractPermanent(string _name) onlyOwner public returns (bool) {
    require(contracts[_name].contractAddress != address(0x0));
    require(contracts[_name].isPermanent == false);
    contracts[_name].isPermanent = true;
    ContractMadePermanent(_name);
    return true;
  }

  function tokenSetup(address _Tokens1st, address _Balancecs, address _Token, address _Conversion, address _Distribution) onlyPayloadSize(5 * 32) onlyOwner public returns (bool) {
    setContract("Token1st", _Tokens1st);
    setContract("Balances", _Balancecs);
    setContract("Token", _Token);
    setContract("Conversion", _Conversion);
    setContract("Distribution", _Distribution);
    return true;
  }

}

contract Balances is CanTransferTokens, SafeMath, useContractWeb {

  mapping(address => uint256) internal _balances;

  function get(address _account) view public returns (uint256) {
    return _balances[_account];
  }

  function tokenContract() view public returns (address) {
    return web.getContractAddress("Token");
  }

  function Balances() public {
    _balances[msg.sender] = 190 * 1000000 * 1000000000000000000;
  }

  modifier onlyToken {
    require(msg.sender == tokenContract());
    _;
  }

  function transfer(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) onlyToken public returns (bool success) {
  _balances[_from] = sub(_balances[_from], _value);
  _balances[_to] = add(_balances[_to], _value);
  return true;
  }

}

contract Token is CanTransferTokens, SafeMath, CheckIfContract, useContractWeb {

  string public symbol = "SHC";
  string public name = "ShineCoin";
  uint8 public decimals = 18;
  uint256 public totalSupply = 190 * 1000000 * 1000000000000000000;

  mapping (address => mapping (address => uint256)) internal _allowance;

    // ERC20 Events
  event Approval(address indexed from, address indexed to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

    // ERC223 Event
  event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);

  function balanceOf(address _account) view public returns (uint256) {
    return Balances(balancesContract()).get(_account);
  }

  function allowance(address _from, address _to) view public returns (uint256 remaining) {
    return _allowance[_from][_to];
  }

  function balancesContract() view public returns (address) {
    return web.getContractAddress("Balances");
  }

  function Token() public {
    bytes memory empty;
    Transfer(this, msg.sender, 190 * 1000000 * 1000000000000000000);
    Transfer(this, msg.sender, 190 * 1000000 * 1000000000000000000, empty);
  }

  function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) onlyPayloadSize(4 * 32) public returns (bool success) {
    if(isContract(_to)) {
      require(Balances(balancesContract()).get(msg.sender) >= _value);
      Balances(balancesContract()).transfer(msg.sender, _to, _value);
      ContractReceiver receiver = ContractReceiver(_to);
      require(receiver.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
      Transfer(msg.sender, _to, _value);
      Transfer(msg.sender, _to, _value, _data);
      return true;
    } else {
      return transferToAddress(_to, _value, _data);
    }
  }

  function transfer(address _to, uint256 _value, bytes _data) onlyPayloadSize(3 * 32) public returns (bool success) {
    if(isContract(_to)) {
      return transferToContract(_to, _value, _data);
    }
    else {
      return transferToAddress(_to, _value, _data);
    }
  }

  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool success) {
    bytes memory empty;
    if(isContract(_to)) {
      return transferToContract(_to, _value, empty);
    }
    else {
      return transferToAddress(_to, _value, empty);
    }
  }

  function transferToAddress(address _to, uint256 _value, bytes _data) internal returns (bool success) {
    require(Balances(balancesContract()).get(msg.sender) >= _value);
    Balances(balancesContract()).transfer(msg.sender, _to, _value);
    Transfer(msg.sender, _to, _value);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  function transferToContract(address _to, uint256 _value, bytes _data) internal returns (bool success) {
    require(Balances(balancesContract()).get(msg.sender) >= _value);
    Balances(balancesContract()).transfer(msg.sender, _to, _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool) {
    bytes memory empty;
    require(_value > 0 && _allowance[_from][msg.sender] >= _value && Balances(balancesContract()).get(_from) >= _value);
    _allowance[_from][msg.sender] = sub(_allowance[_from][msg.sender], _value);
    if(msg.sender != _to && isContract(_to)) {
      Balances(balancesContract()).transfer(_from, _to, _value);
      ContractReceiver receiver = ContractReceiver(_to);
      receiver.tokenFallback(_from, _value, empty);
    } else {
      Balances(balancesContract()).transfer(_from, _to, _value);
    }
    Transfer(_from, _to, _value);
    Transfer(_from, _to, _value, empty);
    return true;
  }

  function approve(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
    _allowance[msg.sender][_to] = add(_allowance[msg.sender][_to], _value);
    Approval(msg.sender, _to, _value);
    return true;
  }

}

contract Conversion is CanTransferTokens, useContractWeb {

  function token1stContract() view public returns (address) {
    return web.getContractAddress("Token1st");
  }

  function tokenContract() view public returns (address) {
    return web.getContractAddress("Token");
  }

  function deposit() onlyOwner public returns (bool) {
    require(Token(tokenContract()).allowance(owner, this) > 0);
    return Token(tokenContract()).transferFrom(owner, this, Token(tokenContract()).allowance(owner, this));
  }

  function convert() public returns (bool) {
    uint256 senderBalance = Token1st(token1stContract()).getBalanceOf(msg.sender);
    require(Token1st(token1stContract()).allowance(msg.sender, this) >= senderBalance);
    Token1st(token1stContract()).transferDecimalAmountFrom(msg.sender, owner, senderBalance);
    return Token(tokenContract()).transfer(msg.sender, senderBalance * 10000000000);
  }

}

contract Distribution is CanTransferTokens, SafeMath, useContractWeb {

  uint256 public liveSince;
  uint256 public withdrawn;

  function withdrawnReadable() view public returns (uint256) {
    return withdrawn / 1000000000000000000;
  }

  function secondsLive() view public returns (uint256) {
    if(liveSince != 0) {
      return now - liveSince;
    }
  }

  function allowedSince() view public returns (uint256) {
    return secondsLive() * 380265185769276972;
  }

  function allowedSinceReadable() view public returns (uint256) {
    return secondsLive() * 380265185769276972 / 1000000000000000000;
  }

  function stillAllowed() view public returns (uint256) {
    return allowedSince() - withdrawn;
  }

  function stillAllowedReadable() view public returns (uint256) {
    uint256 _1 = allowedSince() - withdrawn;
    return _1 / 1000000000000000000;
  }

  function tokenContract() view public returns (address) {
    return web.getContractAddress("Token");
  }

  function makeLive() onlyOwner public returns (bool) {
    require(liveSince == 0);
    liveSince = now;
    return true;
  }

  function deposit() onlyOwner public returns (bool) {
    require(Token(tokenContract()).allowance(owner, this) > 0);
    return Token(tokenContract()).transferFrom(owner, this, Token(tokenContract()).allowance(owner, this));
  }

  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) onlyOwner public returns (bool) {
    require(stillAllowed() >= _value && _value > 0 && liveSince != 0);
    withdrawn = add(withdrawn, _value);
    return Token(tokenContract()).transfer(_to, _value);
  }

  function transferReadable(address _to, uint256 _value) onlyPayloadSize(2 * 32) onlyOwner public returns (bool) {
    require(stillAllowed() >= _value * 1000000000000000000 && stillAllowed() != 0 && liveSince != 0);
    withdrawn = add(withdrawn, _value * 1000000000000000000);
    return Token(tokenContract()).transfer(_to, _value * 1000000000000000000);
  }

}