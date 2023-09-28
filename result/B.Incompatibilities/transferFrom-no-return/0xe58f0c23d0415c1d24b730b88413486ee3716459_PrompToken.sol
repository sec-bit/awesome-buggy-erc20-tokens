contract Ownable {
  address public owner;


  
  function Ownable() {
    owner = msg.sender;
  }


  
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


 
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}





contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}





contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}





contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

 
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

 
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

 
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}


contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }


  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

 
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract Authorizable {

  address[] authorizers;
  mapping(address => uint) authorizerIndex;

 
  modifier onlyAuthorized {
    require(isAuthorized(msg.sender));
    _;
  }

 
  function Authorizable() {
    authorizers.length = 2;
    authorizers[1] = msg.sender;
    authorizerIndex[msg.sender] = 1;
  }

 
  function getAuthorizer(uint authorizerIndex) external constant returns(address) {
    return address(authorizers[authorizerIndex + 1]);
  }

  
  function isAuthorized(address _addr) constant returns(bool) {
    return authorizerIndex[_addr] > 0;
  }

 
  function addAuthorized(address _addr) external onlyAuthorized {
    authorizerIndex[_addr] = authorizers.length;
    authorizers.length++;
    authorizers[authorizers.length - 1] = _addr;
  }

}


contract ExchangeRate is Ownable {

  event RateUpdated(uint timestamp, bytes32 symbol, uint rate);

  mapping(bytes32 => uint) public rates;

 
  function updateRate(string _symbol, uint _rate) public onlyOwner {
    rates[sha3(_symbol)] = _rate;
    RateUpdated(now, sha3(_symbol), _rate);
  }

 
  function updateRates(uint[] data) public onlyOwner {
    if (data.length % 2 > 0)
      throw;
    uint i = 0;
    while (i < data.length / 2) {
      bytes32 symbol = bytes32(data[i * 2]);
      uint rate = data[i * 2 + 1];
      rates[symbol] = rate;
      RateUpdated(now, symbol, rate);
      i++;
    }
  }

  
  function getRate(string _symbol) public constant returns(uint) {
    return rates[sha3(_symbol)];
  }

}


library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
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

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}



contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint value);
  event MintFinished();

  bool public mintingFinished = false;
  uint public totalSupply = 0;


  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }

 
  function mint(address _to, uint _amount) onlyOwner canMint returns (bool) {
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
}




interface token {
    function transfer(address receiver, uint amount);
}



contract PrompToken is MintableToken {

  string public name = "PrompToken";
  string public symbol = "PROMPT";
  uint public decimals = 2;

  bool public tradingStarted = false;

 
  modifier hasStartedTrading() {
    require(tradingStarted);
    _;
  }

  
  function startTrading() onlyOwner {
    tradingStarted = true;
  }

  
  function transfer(address _to, uint _value) hasStartedTrading {
    super.transfer(_to, _value);
  }

 
  function transferFrom(address _from, address _to, uint _value) hasStartedTrading {
    super.transferFrom(_from, _to, _value);
  }

}



contract MainSale is Ownable, Authorizable {
  using SafeMath for uint;
  event TokenSold(address recipient, uint ether_amount, uint pay_amount, uint exchangerate);
  event AuthorizedCreate(address recipient, uint pay_amount);
  event MainSaleClosed();

  PrompToken public token = new PrompToken();

  address public multisigVault;

  uint hardcap = 314159 ether;
  ExchangeRate public exchangeRate;

  uint public altDeposits = 0;
  uint public start = 1000000000; //new Date("Jan 01 2018 12:00:00 GMT").getTime() / 1000

 
  modifier saleIsOn() {
    require(now > start && now < start + 29 days);
    _;
  }

  
  modifier isUnderHardCap() {
    require(multisigVault.balance + altDeposits <= hardcap);
    _;
  }

 
  function createTokens(address recipient) public isUnderHardCap saleIsOn payable {
    uint rate = exchangeRate.getRate("ETH");
    uint tokens = rate.mul(msg.value).div(1 ether);
    token.mint(recipient, tokens);
    require(multisigVault.send(msg.value));
    TokenSold(recipient, msg.value, tokens, rate);
  }


  function setAltDeposit(uint totalAltDeposits) public onlyOwner {
    altDeposits = totalAltDeposits;
  }

  
  function authorizedCreateTokens(address recipient, uint tokens) public onlyAuthorized {
    token.mint(recipient, tokens);
    AuthorizedCreate(recipient, tokens);
  }

 
  function setHardCap(uint _hardcap) public onlyOwner {
    hardcap = _hardcap;
  }

 
  function setStart(uint _start) public onlyOwner {
    start = _start;
  }

  
  function setMultisigVault(address _multisigVault) public onlyOwner {
    if (_multisigVault != address(0)) {
      multisigVault = _multisigVault;
    }
  }

  
  function setExchangeRate(address _exchangeRate) public onlyOwner {
    exchangeRate = ExchangeRate(_exchangeRate);
  }

 
  function finishMinting() public onlyOwner {
    uint issuedTokenSupply = token.totalSupply();
    uint restrictedTokens = issuedTokenSupply.mul(49).div(51);
    token.mint(multisigVault, restrictedTokens);
    token.finishMinting();
    token.transferOwnership(owner);
    MainSaleClosed();
  }

  
  function retrieveTokens(address _token) public onlyOwner {
    ERC20 token = ERC20(_token);
    token.transfer(multisigVault, token.balanceOf(this));
  }
  
  function() external payable {
    createTokens(msg.sender);
  }
}