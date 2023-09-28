pragma solidity ^0.4.13;


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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
      revert();
    }
  }
}

/*
 * ERC20Basic
 * Simpler version of ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/*
 * Basic token
 * Basic version of StandardToken, with no allowances
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /*
   * Fix for the ERC20 short address attack
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
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

/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already revert() if this condition is not met
    // if (_value > _allowance) revert();

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }
}


contract RBInformationStore is Ownable {
    address public profitContainerAddress;
    address public companyWalletAddress;
    uint public etherRatioForOwner;
    address public multiSigAddress;
    address public accountAddressForSponsee;
    bool public isPayableEnabledForAll = true;

    modifier onlyMultiSig() {
        require(multiSigAddress == msg.sender);
        _;
    }

    function RBInformationStore
    (
        address _profitContainerAddress,
        address _companyWalletAddress,
        uint _etherRatioForOwner,
        address _multiSigAddress,
        address _accountAddressForSponsee
    ) {
        profitContainerAddress = _profitContainerAddress;
        companyWalletAddress = _companyWalletAddress;
        etherRatioForOwner = _etherRatioForOwner;
        multiSigAddress = _multiSigAddress;
        accountAddressForSponsee = _accountAddressForSponsee;
    }

    function changeProfitContainerAddress(address _address) onlyMultiSig {
        profitContainerAddress = _address;
    }

    function changeCompanyWalletAddress(address _address) onlyMultiSig {
        companyWalletAddress = _address;
    }

    function changeEtherRatioForOwner(uint _value) onlyMultiSig {
        etherRatioForOwner = _value;
    }

    function changeMultiSigAddress(address _address) onlyMultiSig {
        multiSigAddress = _address;
    }

    function changeOwner(address _address) onlyMultiSig {
        owner = _address;
    }

    function changeAccountAddressForSponsee(address _address) onlyMultiSig {
        accountAddressForSponsee = _address;
    }

    function changeIsPayableEnabledForAll() onlyMultiSig {
        isPayableEnabledForAll = !isPayableEnabledForAll;
    }
}


contract Rate {
    uint public ETH_USD_rate;
    RBInformationStore public rbInformationStore;

    modifier onlyOwner() {
        require(msg.sender == rbInformationStore.owner());
        _;
    }

    function Rate(uint _rate, address _address) {
        ETH_USD_rate = _rate;
        rbInformationStore = RBInformationStore(_address);
    }

    function setRate(uint _rate) onlyOwner {
        ETH_USD_rate = _rate;
    }
}

/**
@title SponseeTokenModelSolaCoin
*/
contract SponseeTokenModelSolaCoin is StandardToken {

    string public name = "SOLA COIN";
    string public symbol = "SLC";
    uint8 public decimals = 18;
    uint public totalSupply = 500000000 * (10 ** uint256(decimals));
    uint public cap = 1000000000 * (10 ** uint256(decimals)); // maximum cap = 10 000 000 $ = 1 000 000 000 tokens
    uint public minimumSupport = 500; // minimum support is 5$
    uint public etherRatioForInvestor = 10; // etherRatio (10%) to send ether to investor
    address public sponseeAddress;
    bool public isPayableEnabled = true;
    RBInformationStore public rbInformationStore;
    Rate public rate;

    event LogReceivedEther(address indexed from, address indexed to, uint etherValue, string tokenName);
    event LogBuy(address indexed from, address indexed to, uint indexed value, uint paymentId);
    event LogRollbackTransfer(address indexed from, address indexed to, uint value);
    event LogExchange(address indexed from, address indexed token, uint value);
    event LogIncreaseCap(uint value);
    event LogDecreaseCap(uint value);
    event LogSetRBInformationStoreAddress(address indexed to);
    event LogSetName(string name);
    event LogSetSymbol(string symbol);
    event LogMint(address indexed to, uint value);
    event LogChangeSponseeAddress(address indexed to);
    event LogChangeIsPayableEnabled(bool flag);

    modifier onlyAccountAddressForSponsee() {
        require(rbInformationStore.accountAddressForSponsee() == msg.sender);
        _;
    }

    modifier onlyMultiSig() {
        require(rbInformationStore.multiSigAddress() == msg.sender);
        _;
    }

    // constructor
    function SponseeTokenModelSolaCoin(
        address _rbInformationStoreAddress,
        address _rateAddress,
        address _sponsee,
        address _to
    ) {
        rbInformationStore = RBInformationStore(_rbInformationStoreAddress);
        rate = Rate(_rateAddress);
        sponseeAddress = _sponsee;
        balances[_to] = totalSupply;
    }

    /**
    @notice Receive ether from any EOA accounts. Amount of ether received in this function is distributed to 3 parts.
    One is a profitContainerAddress which is address of containerWallet to dividend to investor of Boost token.
    Another is an ownerAddress which is address of owner of REALBOOST site.
    The other is an sponseeAddress which is address of owner of this contract.
    */
    function() payable {

        // check condition
        require(isPayableEnabled && rbInformationStore.isPayableEnabledForAll());

        // check validation
        if (msg.value <= 0) { revert(); }

        // calculate support amount in USD
        uint supportedAmount = msg.value.mul(rate.ETH_USD_rate()).div(10**18);
        // if support is less than minimum => return money to supporter
        if (supportedAmount < minimumSupport) { revert(); }

        // calculate the ratio of Ether for distribution
        uint etherRatioForOwner = rbInformationStore.etherRatioForOwner();
        uint etherRatioForSponsee = uint(100).sub(etherRatioForOwner).sub(etherRatioForInvestor);

        /* divide Ether */
        // calculate
        uint etherForOwner = msg.value.mul(etherRatioForOwner).div(100);
        uint etherForInvestor = msg.value.mul(etherRatioForInvestor).div(100);
        uint etherForSponsee = msg.value.mul(etherRatioForSponsee).div(100);

        // get address
        address profitContainerAddress = rbInformationStore.profitContainerAddress();
        address companyWalletAddress = rbInformationStore.companyWalletAddress();

        // send Ether
        if (!profitContainerAddress.send(etherForInvestor)) { revert(); }
        if (!companyWalletAddress.send(etherForOwner)) { revert(); }
        if (!sponseeAddress.send(etherForSponsee)) { revert(); }

        // token amount is transfered to sender
        // 1.0 token = 1 cent, 1 usd = 100 cents
        // wei * US$/(10 ** 18 wei) * 100 cent/US$ * (10 ** 18(decimals))
        uint tokenAmount = msg.value.mul(rate.ETH_USD_rate());

        // add tokens
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);

        // increase total supply
        totalSupply = totalSupply.add(tokenAmount);

        // check cap
        if (totalSupply > cap) { revert(); }

        // send Event
        LogReceivedEther(msg.sender, this, msg.value, name);
        LogExchange(msg.sender, this, tokenAmount);
        Transfer(address(0x0), msg.sender, tokenAmount);
    }

    /**
    @notice Change rbInformationStoreAddress.
    @param _address The address of new rbInformationStore
    */
    function setRBInformationStoreAddress(address _address) onlyMultiSig {

        rbInformationStore = RBInformationStore(_address);

        // send Event
        LogSetRBInformationStoreAddress(_address);
    }

    /**
    @notice Change name.
    @param _name The new name of token
    */
    function setName(string _name) onlyAccountAddressForSponsee {

        name = _name;

        // send Event
        LogSetName(_name);
    }

    /**
    @notice Change symbol.
    @param _symbol The new symbol of token
    */
    function setSymbol(string _symbol) onlyAccountAddressForSponsee {

        symbol = _symbol;

        // send Event
        LogSetSymbol(_symbol);
    }

    /**
    @notice Mint new token amount.
    @param _address The address that new token amount is added
    @param _value The new amount of token
    */
    function mint(address _address, uint _value) onlyAccountAddressForSponsee {

        // add tokens
        balances[_address] = balances[_address].add(_value);

        // increase total supply
        totalSupply = totalSupply.add(_value);

        // check cap
        if (totalSupply > cap) { revert(); }

        // send Event
        LogMint(_address, _value);
        Transfer(address(0x0), _address, _value);
    }

    /**
    @notice Increase cap.
    @param _value The amount of token that should be increased
    */
    function increaseCap(uint _value) onlyAccountAddressForSponsee {

        // change cap here
        cap = cap.add(_value);

        // send Event
        LogIncreaseCap(_value);
    }

    /**
    @notice Decrease cap.
    @param _value The amount of token that should be decreased
    */
    function decreaseCap(uint _value) onlyAccountAddressForSponsee {

        // check whether cap is lower than totalSupply or not
        if (totalSupply > cap.sub(_value)) { revert(); }

        // change cap here
        cap = cap.sub(_value);

        // send Event
        LogDecreaseCap(_value);
    }

    /**
    @notice Rollback transfer.
    @param _from The EOA address for rollback transfer
    @param _to The EOA address for rollback transfer
    @param _value The number of token for rollback transfer
    */
    function rollbackTransfer(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) onlyMultiSig {

        balances[_to] = balances[_to].sub(_value);
        balances[_from] = balances[_from].add(_value);

        // send Event
        LogRollbackTransfer(_from, _to, _value);
        Transfer(_from, _to, _value);
    }

    /**
    @notice Transfer from msg.sender for downloading of content.
    @param _to The EOA address for buy content
    @param _value The number of token for buy content
    @param _paymentId The id of content which msg.sender want to buy
    */
    function buy(address _to, uint _value, uint _paymentId) {

        transfer(_to, _value);

        // send Event
        LogBuy(msg.sender, _to, _value, _paymentId);
    }

    /**
    @notice This method will change old sponsee address with new one.
    @param _newAddress new address is set
    */
    function changeSponseeAddress(address _newAddress) onlyAccountAddressForSponsee {

        sponseeAddress = _newAddress;

        // send Event
        LogChangeSponseeAddress(_newAddress);

    }

    /**
    @notice This method will change isPayableEnabled flag.
    */
    function changeIsPayableEnabled() onlyMultiSig {

        isPayableEnabled = !isPayableEnabled;

        // send Event
        LogChangeIsPayableEnabled(isPayableEnabled);

    }
}