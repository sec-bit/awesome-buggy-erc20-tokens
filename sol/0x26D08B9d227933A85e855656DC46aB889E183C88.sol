pragma solidity ^0.4.15;

contract PlaykeyICO {

  // Constants
  // =========

  uint256 public constant tokensPerEth = 250; // PKT per ETH
  uint256 public constant tokenLimit = 100 * 1e6 * 1e18;
  uint256 public constant tokensForSale = tokenLimit * 60 / 100;
  uint256 public presaleSold = 0;


  // Events
  // ======

  event RunIco();
  event PauseIco();
  event FinishIco(address team, address foundation, address advisors, address bounty);


  // State variables
  // ===============

  PKT public pkt;

  address public team;
  modifier teamOnly { require(msg.sender == team); _; }

  enum IcoState { Presale, Running, Paused, Finished }
  IcoState public icoState = IcoState.Presale;


  // Constructor
  // ===========

  function PlaykeyICO(address _team) {
    team = _team;
    pkt = new PKT(this, tokenLimit);
  }


  // Public functions
  // ================

  // Here you can buy some tokens (just don't forget to provide enough gas).
  function() external payable {
    buyFor(msg.sender);
  }


  function buyFor(address _investor) public payable {
    require(icoState == IcoState.Running);
    require(msg.value > 0);
    buy(_investor, msg.value);
  }


  function getPresaleTotal(uint256 _value) public constant returns (uint256) {
    if(_value < 60 ether) {
      return _value * tokensPerEth;
    }

    if(_value >= 60 ether && _value < 150 ether) {
      return calcPresaleDiscount(_value, 25);
    }

    if(_value >= 150 ether && _value < 500 ether) {
      return calcPresaleDiscount(_value, 30);
    }

    if(_value >= 500 ether) {
      return calcPresaleDiscount(_value, 35);
    }
  }


  function getTotal(uint256 _value) public constant returns (uint256) {
    uint256 _pktValue = _value * tokensPerEth;
    uint256 _bonus = getBonus(_pktValue, pkt.totalSupply() - presaleSold);

    return _pktValue + _bonus;
  }


  function getBonus(uint256 _pktValue, uint256 _sold) public constant returns (uint256) {
    uint256[8] memory _bonusPattern = [ uint256(150), 125, 100, 75, 50, 38, 25, 13 ];
    uint256 _step = (tokensForSale - presaleSold) / 10;
    uint256 _bonus = 0;

    for(uint8 i = 0; i < _bonusPattern.length; ++i) {
      uint256 _min = _step * i;
      uint256 _max = _step * (i + 1);
      if(_sold >= _min && _sold < _max) {
        uint256 _bonusPart = min(_pktValue, _max - _sold);
        _bonus += _bonusPart * _bonusPattern[i] / 1000;
        _pktValue -= _bonusPart;
        _sold  += _bonusPart;
      }
    }

    return _bonus;
  }


  // Priveleged functions
  // ====================

  function mintForEarlyInvestors(address[] _investors, uint256[] _values) external teamOnly {
    require(_investors.length == _values.length);
    for (uint256 i = 0; i < _investors.length; ++i) {
      mintPresaleTokens(_investors[i], _values[i]);
    }
  }


  function mintFor(address _investor, uint256 _pktValue) external teamOnly {
    require(icoState != IcoState.Finished);
    require(pkt.totalSupply() + _pktValue <= tokensForSale);

    pkt.mint(_investor, _pktValue);
  }


  function withdrawEther(uint256 _value) external teamOnly {
    team.transfer(_value);
  }


  // Save tokens from contract
  function withdrawToken(address _tokenContract, uint256 _value) external teamOnly {
    ERC20 _token = ERC20(_tokenContract);
    _token.transfer(team, _value);
  }


  function withdrawTokenFromPkt(address _tokenContract, uint256 _value) external teamOnly {
    pkt.withdrawToken(_tokenContract, team, _value);
  }


  // ICO state management: start / pause / finish
  // --------------------------------------------

  function startIco() external teamOnly {
    require(icoState == IcoState.Presale || icoState == IcoState.Paused);
    icoState = IcoState.Running;
    RunIco();
  }


  function pauseIco() external teamOnly {
    require(icoState == IcoState.Running);
    icoState = IcoState.Paused;
    PauseIco();
  }


  function finishIco(address _team, address _foundation, address _advisors, address _bounty) external teamOnly {
    require(icoState == IcoState.Running || icoState == IcoState.Paused);

    icoState = IcoState.Finished;
    uint256 _teamFund = pkt.totalSupply() * 2 / 3;

    uint256 _den = 10000;
    pkt.mint(_team, _teamFund * 5000 / _den);
    pkt.mint(_foundation, _teamFund * 3125 / _den);
    pkt.mint(_advisors, _teamFund * 1500 / _den);
    pkt.mint(_bounty, _teamFund - _teamFund * 9625 / _den);

    pkt.defrost();

    FinishIco(_team, _foundation, _advisors, _bounty);
  }


  // Private functions
  // =================

  function mintPresaleTokens(address _investor, uint256 _value) internal {
    require(icoState == IcoState.Presale);
    require(_value > 0);

    uint256 _pktValue = getPresaleTotal(_value);

    require(pkt.totalSupply() + _pktValue <= tokensForSale);

    pkt.mint(_investor, _pktValue);
    presaleSold += _pktValue;
  }


  function calcPresaleDiscount(uint256 _value, uint256 _percent) internal constant returns (uint256) {
    return _value * tokensPerEth * 100 / (100 - _percent);
  }


  function min(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }


  function buy(address _investor, uint256 _value) internal {
    uint256 _total = getTotal(_value);

    require(pkt.totalSupply() + _total <= tokensForSale);

    pkt.mint(_investor, _total);
  }
}

/**
 * @title Math
 * @dev Assorted math operations
 */

library Math {
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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract PKT is StandardToken {

  // Constants
  // =========

  string public constant name = "Playkey Token";
  string public constant symbol = "PKT";
  uint8 public constant decimals = 18;
  uint256 public tokenLimit;


  // State variables
  // ===============

  address public ico;
  modifier icoOnly { require(msg.sender == ico); _; }

  // Tokens are frozen until ICO ends.
  bool public tokensAreFrozen = true;


  // Constructor
  // ===========

  function PKT(address _ico, uint256 _tokenLimit) {
    ico = _ico;
    tokenLimit = _tokenLimit;
  }


  // Priveleged functions
  // ====================

  // Mint few tokens and transfer them to some address.
  function mint(address _holder, uint256 _value) external icoOnly {
    require(_holder != address(0));
    require(_value != 0);
    require(totalSupply + _value <= tokenLimit);

    balances[_holder] += _value;
    totalSupply += _value;
    Transfer(0x0, _holder, _value);
  }


  // Allow token transfer.
  function defrost() external icoOnly {
    tokensAreFrozen = false;
  }


  // Save tokens from contract
  function withdrawToken(address _tokenContract, address where, uint256 _value) external icoOnly {
    ERC20 _token = ERC20(_tokenContract);
    _token.transfer(where, _value);
  }


  // ERC20 functions
  // =========================

  function transfer(address _to, uint256 _value)  public returns (bool) {
    require(!tokensAreFrozen);
    return super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!tokensAreFrozen);
    return super.transferFrom(_from, _to, _value);
  }


  function approve(address _spender, uint256 _value) public returns (bool) {
    require(!tokensAreFrozen);
    return super.approve(_spender, _value);
  }
}