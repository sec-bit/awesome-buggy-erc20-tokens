pragma solidity ^0.4.17;

// ----------------------------------------------------------------------------
//
// GZR 'Gizer Gaming' token presale contract
//
// For details, please visit: http://www.gizer.io
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
//
// SafeM (div not needed but kept for completeness' sake)
//
// ----------------------------------------------------------------------------

library SafeM {

  function add(uint a, uint b) public pure returns (uint c) {
    c = a + b;
    require( c >= a );
  }

  function sub(uint a, uint b) public pure returns (uint c) {
    require( b <= a );
    c = a - b;
  }

  function mul(uint a, uint b) public pure returns (uint c) {
    c = a * b;
    require( a == 0 || c / a == b );
  }

  function div(uint a, uint b) public pure returns (uint c) {
    c = a / b;
  }  

}


// ----------------------------------------------------------------------------
//
// Owned contract
//
// ----------------------------------------------------------------------------

contract Owned {

  address public owner;
  address public newOwner;

  // Events ---------------------------

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferred(address indexed _to);

  // Modifier -------------------------

  modifier onlyOwner {
    require( msg.sender == owner );
    _;
  }

  // Functions ------------------------

  function Owned() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require( _newOwner != owner );
    require( _newOwner != address(0x0) );
    newOwner = _newOwner;
    OwnershipTransferProposed(owner, _newOwner);
  }

  function acceptOwnership() public {
    require( msg.sender == newOwner );
    owner = newOwner;
    OwnershipTransferred(owner);
  }

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//
// ----------------------------------------------------------------------------

contract ERC20Interface {

  // Events ---------------------------

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

  // Functions ------------------------

  function totalSupply() public view returns (uint);
  function balanceOf(address _owner) public view returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) public view returns (uint remaining);

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20
//
// ----------------------------------------------------------------------------

contract ERC20Token is ERC20Interface, Owned {
  
  using SafeM for uint;

  uint public tokensIssuedTotal = 0;
  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

  // Functions ------------------------

  /* Total token supply */

  function totalSupply() public view returns (uint) {
    return tokensIssuedTotal;
  }

  /* Get the account balance for an address */

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  /* Transfer the balance from owner's account to another account */

  function transfer(address _to, uint _amount) public returns (bool success) {
    // amount sent cannot exceed balance
    require( balances[msg.sender] >= _amount );

    // update balances
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to]        = balances[_to].add(_amount);

    // log event
    Transfer(msg.sender, _to, _amount);
    return true;
  }

  /* Allow _spender to withdraw from your account up to _amount */

  function approve(address _spender, uint _amount) public returns (bool success) {
    // approval amount cannot exceed the balance
    require( balances[msg.sender] >= _amount );
      
    // update allowed amount
    allowed[msg.sender][_spender] = _amount;
    
    // log event
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  /* Spender of tokens transfers tokens from the owner's balance */
  /* Must be pre-approved by owner */

  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    // balance checks
    require( balances[_from] >= _amount );
    require( allowed[_from][msg.sender] >= _amount );

    // update balances and allowed amount
    balances[_from]            = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to]              = balances[_to].add(_amount);

    // log event
    Transfer(_from, _to, _amount);
    return true;
  }

  /* Returns the amount of tokens approved by the owner */
  /* that can be transferred by spender */

  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


// ----------------------------------------------------------------------------
//
// GZR token presale
//
// ----------------------------------------------------------------------------

contract GizerTokenPresale is ERC20Token {

  /* Utility variables */
  
  uint constant E6  = 10**6;

  /* Basic token data */

  string public constant name     = "Gizer Gaming Presale Token";
  string public constant symbol   = "GZRPRE";
  uint8  public constant decimals = 6;

  /* Wallets */
  
  address public wallet;
  address public redemptionWallet;

  /* General crowdsale parameters */  
  
  uint public constant MIN_CONTRIBUTION = 1 ether / 10; // 0.1 Ether
  uint public constant MAX_CONTRIBUTION = 100 ether;
  
  /* Private sale */

  uint public constant PRIVATE_SALE_MAX_ETHER = 2300 ether;
  
  /* Presale parameters */
  
  uint public constant DATE_PRESALE_START = 1512050400; // 30-Nov-2017 14:00 UTC
  uint public constant DATE_PRESALE_END   = 1513260000; // 14-Dec-2017 14:00 UTC
  
  uint public constant TOKETH_PRESALE_ONE   = 1150 * E6; // presale wave 1 (  1-100)
  uint public constant TOKETH_PRESALE_TWO   = 1100 * E6; // presale wave 2 (101-500)
  uint public constant TOKETH_PRESALE_THREE = 1075 * E6; // presale - others
  
  uint public constant CUTOFF_PRESALE_ONE = 100; // last contributor wave 1
  uint public constant CUTOFF_PRESALE_TWO = 500; // last contributor wave 2

  uint public constant FUNDING_PRESALE_MAX = 2300 ether;

  /* Presale variables */

  uint public etherReceivedPrivate = 0; // private sale Ether
  uint public etherReceivedCrowd   = 0; // crowdsale Ether

  uint public tokensIssuedPrivate = 0; // private sale tokens
  uint public tokensIssuedCrowd   = 0; // crowdsale tokens
  uint public tokensBurnedTotal   = 0; // tokens burned by owner
  
  uint public presaleContributorCount = 0;
  
  bool public tokensFrozen = false;

  /* Mappings */

  mapping(address => uint) public balanceEthPrivate; // private sale Ether
  mapping(address => uint) public balanceEthCrowd;   // crowdsale Ether

  mapping(address => uint) public balancesPrivate; // private sale tokens
  mapping(address => uint) public balancesCrowd;   // crowdsale tokens

  // Events ---------------------------
  
  event WalletUpdated(address _newWallet);
  event RedemptionWalletUpdated(address _newRedemptionWallet);
  event TokensIssued(address indexed _owner, uint _tokens, uint _balance, uint _tokensIssuedCrowd, bool indexed _isPrivateSale, uint _amount);
  event OwnerTokensBurned(uint _tokensBurned, uint _tokensBurnedTotal);
  
  // Basic Functions ------------------

  /* Initialize */

  function GizerTokenPresale() public {
    wallet = owner;
    redemptionWallet = owner;
  }

  /* Fallback */
  
  function () public payable {
    buyTokens();
  }

  // Information Functions ------------
  
  /* What time is it? */
  
  function atNow() public view returns (uint) {
    return now;
  }

  // Owner Functions ------------------
  
  /* Change the crowdsale wallet address */

  function setWallet(address _wallet) public onlyOwner {
    require( _wallet != address(0x0) );
    wallet = _wallet;
    WalletUpdated(_wallet);
  }

  /* Change the redemption wallet address */

  function setRedemptionWallet(address _wallet) public onlyOwner {
    redemptionWallet = _wallet;
    RedemptionWalletUpdated(_wallet);
  }
  
  /* Issue tokens for ETH received during private sale */

  function privateSaleContribution(address _account, uint _amount) public onlyOwner {
    // checks
    require( _account != address(0x0) );
    require( atNow() < DATE_PRESALE_END );
    require( _amount >= MIN_CONTRIBUTION );
    require( etherReceivedPrivate.add(_amount) <= PRIVATE_SALE_MAX_ETHER );
    
    // same conditions as early presale participants
    uint tokens = TOKETH_PRESALE_ONE.mul(_amount) / 1 ether;
    
    // issue tokens
    issueTokens(_account, tokens, _amount, true); // true => private sale
  }

  /* Freeze tokens */
  
  function freezeTokens() public onlyOwner {
    require( atNow() > DATE_PRESALE_END );
    tokensFrozen = true;
  }
  
  /* Burn tokens held by owner */
  
  function burnOwnerTokens() public onlyOwner {
    // check if there is anything to burn
    require( balances[owner] > 0 );
    
    // update 
    uint tokensBurned = balances[owner];
    balances[owner] = 0;
    tokensIssuedTotal = tokensIssuedTotal.sub(tokensBurned);
    tokensBurnedTotal = tokensBurnedTotal.add(tokensBurned);
    
    // log
    Transfer(owner, 0x0, tokensBurned);
    OwnerTokensBurned(tokensBurned, tokensBurnedTotal);

  }  

  /* Transfer out any accidentally sent ERC20 tokens */

  function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

  // Private functions ----------------

  /* Accept ETH during presale (called by default function) */

  function buyTokens() private {
    // initial checks
    require( atNow() > DATE_PRESALE_START && atNow() < DATE_PRESALE_END );
    require( msg.value >= MIN_CONTRIBUTION && msg.value <= MAX_CONTRIBUTION );
    require( etherReceivedCrowd.add(msg.value) <= FUNDING_PRESALE_MAX );

    // tokens
    uint tokens;
    if (presaleContributorCount < CUTOFF_PRESALE_ONE) {
      // wave 1
      tokens = TOKETH_PRESALE_ONE.mul(msg.value) / 1 ether;
    } else if (presaleContributorCount < CUTOFF_PRESALE_TWO) {
      // wave 2
      tokens = TOKETH_PRESALE_TWO.mul(msg.value) / 1 ether;
    } else {
      // wave 3
      tokens = TOKETH_PRESALE_THREE.mul(msg.value) / 1 ether;
    }
    presaleContributorCount += 1;
    
    // issue tokens
    issueTokens(msg.sender, tokens, msg.value, false); // false => not private sale
  }
  
  /* Issue tokens */
  
  function issueTokens(address _account, uint _tokens, uint _amount, bool _isPrivateSale) private {
    // register tokens purchased and Ether received
    balances[_account] = balances[_account].add(_tokens);
    tokensIssuedCrowd  = tokensIssuedCrowd.add(_tokens);
    tokensIssuedTotal  = tokensIssuedTotal.add(_tokens);
    
    if (_isPrivateSale) {
      tokensIssuedPrivate         = tokensIssuedPrivate.add(_tokens);
      etherReceivedPrivate        = etherReceivedPrivate.add(_amount);
      balancesPrivate[_account]   = balancesPrivate[_account].add(_tokens);
      balanceEthPrivate[_account] = balanceEthPrivate[_account].add(_amount);
    } else {
      etherReceivedCrowd        = etherReceivedCrowd.add(_amount);
      balancesCrowd[_account]   = balancesCrowd[_account].add(_tokens);
      balanceEthCrowd[_account] = balanceEthCrowd[_account].add(_amount);
    }
    
    // log token issuance
    Transfer(0x0, _account, _tokens);
    TokensIssued(_account, _tokens, balances[_account], tokensIssuedCrowd, _isPrivateSale, _amount);

    // transfer Ether out
    if (this.balance > 0) wallet.transfer(this.balance);

  }

  // ERC20 functions ------------------

  /* Override "transfer" */

  function transfer(address _to, uint _amount) public returns (bool success) {
    require( _to == owner || (!tokensFrozen && _to == redemptionWallet) );
    return super.transfer(_to, _amount);
  }
  
  /* Override "transferFrom" */

  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    require( !tokensFrozen && _to == redemptionWallet );
    return super.transferFrom(_from, _to, _amount);
  }

}