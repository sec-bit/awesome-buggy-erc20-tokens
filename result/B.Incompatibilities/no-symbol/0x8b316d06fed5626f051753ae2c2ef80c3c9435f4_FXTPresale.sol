pragma solidity ^0.4.18;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract PresaleFallbackReceiver {
  bool public presaleFallBackCalled;

  function presaleFallBack(uint256 _presaleWeiRaised) public returns (bool);
}











/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}






/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
}




contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}










contract BTCPaymentI is Ownable, PresaleFallbackReceiver {
  PaymentFallbackReceiver public presale;
  PaymentFallbackReceiver public mainsale;

  function addPayment(address _beneficiary, uint256 _tokens) public;
  function setPresale(address _presale) external;
  function setMainsale(address _mainsale) external;
  function presaleFallBack(uint256) public returns (bool);
}


contract PaymentFallbackReceiver {
  BTCPaymentI public payment;

  enum SaleType { pre, main }

  function PaymentFallbackReceiver(address _payment) public {
    require(_payment != address(0));
    payment = BTCPaymentI(_payment);
  }

  modifier onlyPayment() {
    require(msg.sender == address(payment));
    _;
  }

  event MintByBTC(SaleType _saleType, address indexed _beneficiary, uint256 _tokens);

  /**
   * @dev paymentFallBack() is called in BTCPayment.addPayment().
   * Presale or Mainsale contract should mint token to beneficiary,
   * and apply corresponding ether amount to max ether cap.
   * @param _beneficiary ethereum address who receives tokens
   * @param _tokens amount of FXT to mint
   */
  function paymentFallBack(address _beneficiary, uint256 _tokens) external onlyPayment();
}






/**
 * @title Sudo
 * @dev Some functions should be restricted so as not to be available in any situation.
 * `onlySudoEnabled` modifier controlls it.
 */
contract Sudo is Ownable {
  bool public sudoEnabled;

  modifier onlySudoEnabled() {
    require(sudoEnabled);
    _;
  }

  event SudoEnabled(bool _sudoEnabled);

  function Sudo(bool _sudoEnabled) public {
    sudoEnabled = _sudoEnabled;
  }

  function enableSudo(bool _sudoEnabled) public onlyOwner {
    sudoEnabled = _sudoEnabled;
    SudoEnabled(_sudoEnabled);
  }
}










/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract FXTI is ERC20 {
  bool public sudoEnabled = true;

  function transfer(address _to, uint256 _amount) public returns (bool success);

  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);

  function generateTokens(address _owner, uint _amount) public returns (bool);

  function destroyTokens(address _owner, uint _amount) public returns (bool);

  function blockAddress(address _addr) public;

  function unblockAddress(address _addr) public;

  function enableSudo(bool _sudoEnabled) public;

  function enableTransfers(bool _transfersEnabled) public;

  // byList functions

  function generateTokensByList(address[] _owners, uint[] _amounts) public returns (bool);
}





/**
 * @title KYCInterface
 */
contract KYCI is Ownable {
  function setAdmin(address _addr, bool _value) public returns (bool);
  function isRegistered(address _addr, bool _isPresale) public returns (bool);
  function register(address _addr, bool _isPresale) public;
  function registerByList(address[] _addrs, bool _isPresale) public;
  function unregister(address _addr, bool _isPresale)public;
  function unregisterByList(address[] _addrs, bool _isPresale) public;
}


/**
 * @dev This base contract is inherited by FXTPresale and FXTMainsale
 * and have related contracts address and ether funded in the sale as state.
 * Main purpose of this base contract is to provide the interface to control
 * generating / burning token and increase / decrease ether ether funded in the sale.
 * Those functions are only called in case of emergency situation such as
 * erroneous action handling Bitcoin payment.
 */
contract SaleBase is Sudo, Pausable, PaymentFallbackReceiver {
  using SafeMath for uint256;

  // related contracts
  FXTI public token;
  KYCI public kyc;
  RefundVault public vault;

  // fuzex account to hold ownership of contracts after sale finalized
  address public fuzexAccount;

  // common sale parameters
  mapping (address => uint256) public beneficiaryFunded;
  uint256 public weiRaised;

  bool public isFinalized; // whether sale is finalized

  /**
   * @dev After sale finalized, token and other contract ownership is transferred to
   * another contract or account. So this modifier doesn't effect contract logic, just
   * make sure of it.
   */
  modifier onlyNotFinalized() {
    require(!isFinalized);
    _;
  }

  function SaleBase(
    address _token,
    address _kyc,
    address _vault,
    address _payment,
    address _fuzexAccount)
    Sudo(false) // sudoEnabled
    PaymentFallbackReceiver(_payment)
    public
  {
    require(_token != address(0)
     && _kyc != address(0)
     && _vault != address(0)
     && _fuzexAccount != address(0));

    token = FXTI(_token);
    kyc = KYCI(_kyc);
    vault = RefundVault(_vault);
    fuzexAccount = _fuzexAccount;
  }

  /**
   * @dev Below 4 functions are only called in case of emergency and certain situation.
   * e.g. Wrong parameters for BTCPayment.addPayment function so that token should be burned and
   * wei-raised should be modified.
   */
  function increaseWeiRaised(uint256 _amount) public onlyOwner onlyNotFinalized onlySudoEnabled {
    weiRaised = weiRaised.add(_amount);
  }

  function decreaseWeiRaised(uint256 _amount) public onlyOwner onlyNotFinalized onlySudoEnabled {
    weiRaised = weiRaised.sub(_amount);
  }

  function generateTokens(address _owner, uint _amount) public onlyOwner onlyNotFinalized onlySudoEnabled returns (bool) {
    return token.generateTokens(_owner, _amount);
  }

  function destroyTokens(address _owner, uint _amount) public onlyOwner onlyNotFinalized onlySudoEnabled returns (bool) {
    return token.destroyTokens(_owner, _amount);
  }

  /**
   * @dev Prevent token holder from transfer.
   */
  function blockAddress(address _addr) public onlyOwner onlyNotFinalized onlySudoEnabled {
    token.blockAddress(_addr);
  }

  function unblockAddress(address _addr) public onlyOwner onlyNotFinalized onlySudoEnabled {
    token.unblockAddress(_addr);
  }

  /**
   * @dev Transfer ownership of other contract whoes owner is `this` to other address.
   */
  function changeOwnership(address _target, address _newOwner) public onlyOwner {
    Ownable(_target).transferOwnership(_newOwner);
  }

  /**
   * @dev Transfer ownership of MiniMeToken whoes controller is `this` to other address.
   */
  function changeController(address _target, address _newOwner) public onlyOwner {
    Controlled(_target).changeController(_newOwner);
  }

  function setFinalize() internal onlyOwner {
    require(!isFinalized);
    isFinalized = true;
  }
}



/**
 * @title FXTPresale
 * @dev Private-sale is finished before this contract is deployed.
 *
 */
contract FXTPresale is SaleBase {
  uint256 public baseRate = 12000;    // 1 ETH = 12000 FXT
  uint256 public PRE_BONUS = 25;     // presale bonus 25%
  uint256 public BONUS_COEFF = 100;

  // private-sale parameters
  uint256 public privateEtherFunded;
  uint256 public privateMaxEtherCap;

  // presale parameters
  uint256 public presaleMaxEtherCap;
  uint256 public presaleMinPurchase;

  uint256 public maxEtherCap;   // max ether cap for both private-sale & presale

  uint64 public startTime;     // when presale starts
  uint64 public endTime;       // when presale ends

  event PresaleTokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 toFund, uint256 tokens);

  /**
   * @dev only presale registered address can participate presale.
   * private-sale doesn't require to check address because owner deals with it.
   */
  modifier onlyRegistered(address _addr) {
    require(kyc.isRegistered(_addr, true));
    _;
  }

  function FXTPresale(
    address _token,
    address _kyc,
    address _vault,
    address _payment,
    address _fuzexAccount,
    uint64 _startTime,
    uint64 _endTime,
    uint256 _privateEtherFunded,
    uint256 _privateMaxEtherCap,
    uint256 _presaleMaxEtherCap,
    uint256 _presaleMinPurchase)
    SaleBase(_token, _kyc, _vault, _payment, _fuzexAccount)
    public
  {
    require(now < _startTime && _startTime < _endTime);

    require(_privateEtherFunded >= 0);
    require(_privateMaxEtherCap > 0);
    require(_presaleMaxEtherCap > 0);
    require(_presaleMinPurchase > 0);

    require(_presaleMinPurchase < _presaleMaxEtherCap);

    startTime = _startTime;
    endTime = _endTime;

    privateEtherFunded = _privateEtherFunded;
    privateMaxEtherCap = _privateMaxEtherCap;

    presaleMaxEtherCap = _presaleMaxEtherCap;
    presaleMinPurchase = _presaleMinPurchase;

    maxEtherCap = privateMaxEtherCap.add(presaleMaxEtherCap);
    weiRaised = _privateEtherFunded; // ether funded during private-sale

    require(weiRaised <= maxEtherCap);
  }

  function () external payable {
    buyPresale(msg.sender);
  }

  /**
   * @dev paymentFallBack() assumes that paid BTC doesn't exceed the max ether cap.
   * BTC / ETH price (or rate) is determined using reliable outer resources.
   * @param _beneficiary ethereum address who receives tokens
   * @param _tokens amount of FXT to mint
   */
  function paymentFallBack(address _beneficiary, uint256 _tokens)
    external
    onlyPayment
  {
    // only check time and parameters
    require(startTime <= now && now <= endTime);
    require(_beneficiary != address(0));
    require(_tokens > 0);

    uint256 rate = getRate();
    uint256 weiAmount = _tokens.div(rate);

    require(weiAmount >= presaleMinPurchase);

    // funded ether should not exceed max ether cap.
    require(weiRaised.add(weiAmount) <= maxEtherCap);

    weiRaised = weiRaised.add(weiAmount);
    beneficiaryFunded[_beneficiary] = beneficiaryFunded[_beneficiary].add(weiAmount);

    token.generateTokens(_beneficiary, _tokens);
    MintByBTC(SaleType.pre, _beneficiary, _tokens);
  }

  function buyPresale(address _beneficiary)
    public
    payable
    onlyRegistered(_beneficiary)
    whenNotPaused
  {
    // check validity
    require(_beneficiary != address(0));
    require(msg.value >= presaleMinPurchase);
    require(validPurchase());

    uint256 toFund;
    uint256 tokens;

    (toFund, tokens) = buy(_beneficiary);

    PresaleTokenPurchase(msg.sender, _beneficiary, toFund, tokens);
  }

  function buy(address _beneficiary)
    internal
    returns (uint256 toFund, uint256 tokens)
  {
    // calculate eth amount
    uint256 weiAmount = msg.value;
    uint256 totalAmount = weiRaised.add(weiAmount);

    if (totalAmount > maxEtherCap) {
      toFund = maxEtherCap.sub(weiRaised);
    } else {
      toFund = weiAmount;
    }

    require(toFund > 0);
    require(weiAmount >= toFund);

    uint256 rate = getRate();
    tokens = toFund.mul(rate);
    uint256 toReturn = weiAmount.sub(toFund);

    weiRaised = weiRaised.add(toFund);
    beneficiaryFunded[_beneficiary] = beneficiaryFunded[_beneficiary].add(toFund);

    token.generateTokens(_beneficiary, tokens);

    if (toReturn > 0) {
      msg.sender.transfer(toReturn);
    }

    forwardFunds(toFund);
  }

  function validPurchase() internal view returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    bool validTime = now >= startTime && now <= endTime;
    return nonZeroPurchase && !maxReached() && validTime;
  }

  /**
   * @dev get current rate
   */
  function getRate() public view returns (uint256) {
    return calcRate(PRE_BONUS);
  }

  /**
   * @dev Calculate rate wrt _bonus. if _bonus is 15, this function
   * returns baseRate * 1.15.
   * rate = 12000 * (25 + 100) / 100 for 25% bonus
   */
  function calcRate(uint256 _bonus) internal view returns (uint256) {
    return _bonus.add(BONUS_COEFF).mul(baseRate).div(BONUS_COEFF);
  }

  /**
   * @dev Checks whether max ether cap is reached for presale
   * @return true if max ether cap is reaced
   */
  function maxReached() public view  returns (bool) {
    return weiRaised == maxEtherCap;
  }

  function forwardFunds(uint256 _toFund) internal {
    vault.deposit.value(_toFund)(msg.sender);
  }

  function finalizePresale(address _mainsale) public onlyOwner {
      require(!isFinalized);
      require(maxReached() || now > endTime);

      PresaleFallbackReceiver mainsale = PresaleFallbackReceiver(_mainsale);

      require(mainsale.presaleFallBack(weiRaised));
      require(payment.presaleFallBack(weiRaised));

      vault.close();

      changeController(address(token), _mainsale);
      changeOwnership(address(vault), fuzexAccount);

      enableSudo(false);
      setFinalize();
  }
}