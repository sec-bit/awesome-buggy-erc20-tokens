pragma solidity ^0.4.13;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {

  address public owner;
  function Ownable() { owner = msg.sender; }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {owner = newOwner;}
}

contract ERC20Interface {

  function totalSupply() constant returns (uint256 totalSupply);

  function balanceOf(address _owner) constant returns (uint256 balance);

  function transfer(address _to, uint256 _value) returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

  function approve(address _spender, uint256 _value) returns (bool success);

  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

 }

contract GMPToken is Ownable, ERC20Interface {

  /* Public variables of the token */
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  /* This creates an array with all balances */
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

  /* Constuctor: Initializes contract with initial supply tokens to the creator of the contract */
  function GMPToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
      ) {
      balances[msg.sender] = initialSupply;              // Give the creator all initial tokens
      totalSupply = initialSupply;                        // Update total supply
      name = tokenName;                                   // Set the name for display purposes
      symbol = tokenSymbol;                               // Set the symbol for display purposes
      decimals = decimalUnits;                            // Amount of decimals for display purposes
  }

  /* Implementation of ERC20Interface */

  function totalSupply() constant returns (uint256 totalSupply) { return totalSupply; }

  function balanceOf(address _owner) constant returns (uint256 balance) { return balances[_owner]; }

  /* Internal transfer, only can be called by this contract */
  function _transfer(address _from, address _to, uint _amount) internal {
      require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
      require (balances[_from] > _amount);                // Check if the sender has enough
      require (balances[_to] + _amount > balances[_to]); // Check for overflows
      balances[_from] -= _amount;                         // Subtract from the sender
      balances[_to] += _amount;                            // Add the same to the recipient
      Transfer(_from, _to, _amount);

  }

  function transfer(address _to, uint256 _amount) returns (bool success) {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    require (_value < allowed[_from][msg.sender]);     // Check allowance
    allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function mintToken(uint256 mintedAmount) onlyOwner {
      balances[Ownable.owner] += mintedAmount;
      totalSupply += mintedAmount;
      Transfer(0, Ownable.owner, mintedAmount);
  }

}


contract Crowdsale is Ownable {

  using SafeMath for uint256;

  // The token being sold
  GMPToken public token;

  // Flag setting that investments are allowed (both inclusive)
  bool public saleIsActive;

  // address where funds are collected
  address public wallet;

  // Price for 1 token in wei. i.e. 562218890554723
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  /* -----------   A D M I N        F U N C T I O N S    ----------- */

  function Crowdsale(uint256 initialRate, address targetWallet, uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) {

    //Checks
    require(initialRate > 0);
    require(targetWallet != 0x0);

    //Init
    token = new GMPToken(initialSupply, tokenName, decimalUnits, tokenSymbol);
    rate = initialRate;
    wallet = targetWallet;
    saleIsActive = true;

  }

  function close() onlyOwner {
    selfdestruct(owner);
  }

  //Transfer token to
  function transferToAddress(address targetWallet, uint256 tokenAmount) onlyOwner {
    token.transfer(targetWallet, tokenAmount);
  }


  //Setters
  function enableSale() onlyOwner {
    saleIsActive = true;
  }

  function disableSale() onlyOwner {
    saleIsActive = false;
  }

  function setRate(uint256 newRate)  onlyOwner {
    rate = newRate;
  }

  //Mint new tokens
  function mintToken(uint256 mintedAmount) onlyOwner {
    token.mintToken(mintedAmount);
  }



  /* -----------   P U B L I C      C A L L B A C K       F U N C T I O N     ----------- */

  function () payable {

    require(msg.sender != 0x0);
    require(saleIsActive);
    require(msg.value > rate);

    uint256 weiAmount = msg.value;

    //Update total wei counter
    weiRaised = weiRaised.add(weiAmount);

    //Calc number of tokents
    uint256 tokenAmount = weiAmount.div(rate);

    //Forward wei to wallet account
    wallet.transfer(msg.value);

    //Transfer token to sender
    token.transfer(msg.sender, tokenAmount);
    TokenPurchase(msg.sender, wallet, weiAmount, tokenAmount);

  }



}