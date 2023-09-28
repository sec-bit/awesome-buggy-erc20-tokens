pragma solidity ^0.4.15;

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Controllable {
  address public controller;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
   */
  function Controllable() public {
    controller = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newController The address to transfer ownership to.
   */
  function transferControl(address newController) public onlyController {
    if (newController != address(0)) {
      controller = newController;
    }
  }

}

contract ProofTokenInterface is Controllable {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
  event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function totalSupply() public constant returns (uint);
  function totalSupplyAt(uint _blockNumber) public constant returns(uint);
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint);
  function transfer(address _to, uint256 _amount) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
  function approve(address _spender, uint256 _amount) public returns (bool success);
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  function mint(address _owner, uint _amount) public returns (bool);
  function importPresaleBalances(address[] _addresses, uint256[] _balances, address _presaleAddress) public returns (bool);
  function lockPresaleBalances() public returns (bool);
  function finishMinting() public returns (bool);
  function enableTransfers(bool _value) public;
  function enableMasterTransfers(bool _value) public;
  function createCloneToken(uint _snapshotBlock, string _cloneTokenName, string _cloneTokenSymbol) public returns (address);

}

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

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  function Pausable() public {}

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract TokenSale is Pausable {

  using SafeMath for uint256;

  ProofTokenInterface public proofToken;
  uint256 public totalWeiRaised;
  uint256 public tokensMinted;
  uint256 public totalSupply;
  uint256 public contributors;
  uint256 public decimalsMultiplier;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public remainingTokens;
  uint256 public allocatedTokens;

  bool public finalized;
  bool public proofTokensAllocated;

  uint256 public constant BASE_PRICE_IN_WEI = 88000000000000000;

  uint256 public constant PUBLIC_TOKENS = 1181031 * (10 ** 18);
  uint256 public constant TOTAL_PRESALE_TOKENS = 112386712924725508802400;
  uint256 public constant TOKENS_ALLOCATED_TO_PROOF = 1181031 * (10 ** 18);

  address public constant PROOF_MULTISIG = 0x99892Ac6DA1b3851167Cb959fE945926bca89f09;

  uint256 public tokenCap = PUBLIC_TOKENS - TOTAL_PRESALE_TOKENS;
  uint256 public cap = tokenCap / (10 ** 18);
  uint256 public weiCap = cap * BASE_PRICE_IN_WEI;

  uint256 public firstCheckpointPrice = (BASE_PRICE_IN_WEI * 85) / 100;
  uint256 public secondCheckpointPrice = (BASE_PRICE_IN_WEI * 90) / 100;
  uint256 public thirdCheckpointPrice = (BASE_PRICE_IN_WEI * 95) / 100;

  uint256 public firstCheckpoint = (weiCap * 5) / 100;
  uint256 public secondCheckpoint = (weiCap * 10) / 100;
  uint256 public thirdCheckpoint = (weiCap * 20) / 100;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event NewClonedToken(address indexed _cloneToken);
  event OnTransfer(address _from, address _to, uint _amount);
  event OnApprove(address _owner, address _spender, uint _amount);
  event LogInt(string _name, uint256 _value);
  event Finalized();

  function TokenSale(
    address _tokenAddress,
    uint256 _startTime,
    uint256 _endTime) public {
    require(_tokenAddress != 0x0);
    require(_startTime > 0);
    require(_endTime > _startTime);

    startTime = _startTime;
    endTime = _endTime;
    proofToken = ProofTokenInterface(_tokenAddress);

    decimalsMultiplier = (10 ** 18);
  }


  /**
   * High level token purchase function
   */
  function() public payable {
    buyTokens(msg.sender);
  }

  /**
   * Low level token purchase function
   * @param _beneficiary will receive the tokens.
   */
  function buyTokens(address _beneficiary) public payable whenNotPaused whenNotFinalized {
    require(_beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 priceInWei = getPriceInWei();
    totalWeiRaised = totalWeiRaised.add(weiAmount);

    uint256 tokens = weiAmount.mul(decimalsMultiplier).div(priceInWei);
    tokensMinted = tokensMinted.add(tokens);
    require(tokensMinted < tokenCap);

    contributors = contributors.add(1);

    proofToken.mint(_beneficiary, tokens);
    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    forwardFunds();
  }


  /**
   * Get the price in wei for current premium
   * @return price
   */
  function getPriceInWei() constant public returns (uint256) {

    uint256 price;

    if (totalWeiRaised < firstCheckpoint) {
      price = firstCheckpointPrice;
    } else if (totalWeiRaised < secondCheckpoint) {
      price = secondCheckpointPrice;
    } else if (totalWeiRaised < thirdCheckpoint) {
      price = thirdCheckpointPrice;
    } else {
      price = BASE_PRICE_IN_WEI;
    }

    return price;
  }

  /**
  * Forwards funds to the tokensale wallet
  */
  function forwardFunds() internal {
    PROOF_MULTISIG.transfer(msg.value);
  }


  /**
  * Validates the purchase (period, minimum amount, within cap)
  * @return {bool} valid
  */
  function validPurchase() internal constant returns (bool) {
    uint256 current = now;
    bool withinPeriod = current >= startTime && current <= endTime;
    bool nonZeroPurchase = msg.value != 0;

    return nonZeroPurchase && withinPeriod;
  }

  /**
  * Returns the total Proof token supply
  * @return total supply {uint256}
  */
  function totalSupply() public constant returns (uint256) {
    return proofToken.totalSupply();
  }

  /**
  * Returns token holder Proof Token balance
  * @param _owner {address}
  * @return token balance {uint256}
  */
  function balanceOf(address _owner) public constant returns (uint256) {
    return proofToken.balanceOf(_owner);
  }

  /**
  * Change the Proof Token controller
  * @param _newController {address}
  */
  function changeController(address _newController) public {
    require(isContract(_newController));
    proofToken.transferControl(_newController);
  }


  function enableTransfers() public {
    if (now < endTime) {
      require(msg.sender == owner);
    }

    proofToken.enableTransfers(true);
  }

  function lockTransfers() public onlyOwner {
    require(now < endTime);
    proofToken.enableTransfers(false);
  }

  function enableMasterTransfers() public onlyOwner {
    proofToken.enableMasterTransfers(true);
  }

  function lockMasterTransfers() public onlyOwner {
    proofToken.enableMasterTransfers(false);
  }

  function isContract(address _addr) constant internal returns(bool) {
      uint size;
      if (_addr == 0)
        return false;
      assembly {
          size := extcodesize(_addr)
      }
      return size>0;
  }

  /**
  * Allocates Proof tokens to the given Proof Token wallet
  */
  function allocateProofTokens() public onlyOwner whenNotFinalized {
    proofToken.mint(PROOF_MULTISIG, TOKENS_ALLOCATED_TO_PROOF);
    proofTokensAllocated = true;
  }

  /**
  * Finalize the token sale (can only be called by owner)
  */
  function finalize() public onlyOwner {
    require(paused);
    require(proofTokensAllocated);

    proofToken.finishMinting();
    proofToken.enableTransfers(true);
    Finalized();

    finalized = true;
  }

  modifier whenNotFinalized() {
    require(!paused);
    _;
  }

}