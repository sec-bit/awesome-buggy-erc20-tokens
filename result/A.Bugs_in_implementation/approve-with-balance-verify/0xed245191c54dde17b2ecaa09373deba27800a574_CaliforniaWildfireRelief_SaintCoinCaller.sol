pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
//
// SNTC SaintCoin token public sale contract
//
// For details, please visit: https://saintcoin.io
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
//
// SafeMath3
//
// Adapted from https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// (no need to implement division)
//
// ----------------------------------------------------------------------------

library SafeMath3 {

  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    assert(a == 0 || c / a == b);
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    assert(c >= a);
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
  event OwnershipTransferred(address indexed _from, address indexed _to);

  // Modifier -------------------------

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  // Functions ------------------------

  function Owned() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) onlyOwner public {
    require(_newOwner != owner);
    require(_newOwner != address(0x0));
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0x0);
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

  function totalSupply() constant public returns (uint);
  function balanceOf(address _owner) constant public returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) constant public returns (uint remaining);

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20
//
// ----------------------------------------------------------------------------

contract ERC20Token is ERC20Interface, Owned {
  
  using SafeMath3 for uint;

  uint public tokensIssuedTotal = 0;

  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) internal allowed;

  // Functions ------------------------

  /* Total token supply */

  function totalSupply() constant public returns (uint) {
    return tokensIssuedTotal;
  }

  /* Get the account balance for an address */

  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

  /* Transfer the balance from owner's account to another account */

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // update balances
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    // log event
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /* Allow _spender to withdraw from your account up to _value */

  function approve(address _spender, uint256 _value) public returns (bool) {
    // approval amount cannot exceed the balance
    require(balances[msg.sender] >= _value);
      
    // update allowed amount
    allowed[msg.sender][_spender] = _value;
    
    // log event
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /* Spender of tokens transfers tokens from the owner's balance */
  /* Must be pre-approved by owner */

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    // update balances and allowed amount
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    // log event
    Transfer(_from, _to, _value);
    return true;
  }

  /* Returns the amount of tokens approved by the owner */
  /* that can be transferred by spender */

  function allowance(address _owner, address _spender) constant public returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract SaintCoinToken is ERC20Token {
    /* Utility variable */
  
    uint constant E6 = 10**6;
  
    /* Basic token data */
  
    string public constant name = "Saint Coins";
    string public constant symbol = "SAINT";
    uint8 public constant decimals = 0;
    
    /* Saint coinds per ETH */
  
    uint public tokensPerEth = 1000;

    /* Fundation contract addresses */
    
    mapping(address => bool) public grantedContracts;

    /* HelpCoin address */

    address public helpCoinAddress;

    event GrantedOrganization(bool isGranted);

    function SaintCoinToken(address _helpCoinAddress) public { 
      helpCoinAddress = _helpCoinAddress;          
    }
    
    function setHelpCoinAddress(address newHelpCoinWalletAddress) public onlyOwner {
        helpCoinAddress = newHelpCoinWalletAddress;
    }

    function sendTo(address _to, uint256 _value) public {
        require(isAuthorized(msg.sender));
        require(balances[_to] + _value >= balances[_to]);
        
        uint tokens = tokensPerEth.mul(_value) / 1 ether;
        
        balances[_to] += tokens;
        tokensIssuedTotal += tokens;

        Transfer(msg.sender, _to, tokens);
    }

    function grantAccess(address _address) public onlyOwner {
        grantedContracts[_address] = true;
        GrantedOrganization(grantedContracts[_address]);
    }
    
    function revokeAccess(address _address) public onlyOwner {
        grantedContracts[_address] = false;
        GrantedOrganization(grantedContracts[_address]);
    }

    function isAuthorized(address _address) public constant returns (bool) {
        return grantedContracts[_address];
    }
}

contract CaliforniaWildfireRelief_SaintCoinCaller is Owned {
    address saintCoinAddress;
    address fundationWalletAddress;
    uint public percentForHelpCoin = 10;

    function CaliforniaWildfireRelief_SaintCoinCaller(address _saintCoinAddress, address _fundationWalletAddress) public {
        require(_saintCoinAddress != address(0x0));
        require(_fundationWalletAddress != address(0x0));
        
        saintCoinAddress = _saintCoinAddress;
        fundationWalletAddress = _fundationWalletAddress;
    }
    
    function setFoundationAddress(address newFoundationWalletAddress) public onlyOwner {
        fundationWalletAddress = newFoundationWalletAddress;
    }

    function setPercentForHelpCoin(uint _percentForHelpCoin) public onlyOwner {
    	percentForHelpCoin = _percentForHelpCoin;
    }

    function () public payable {
        SaintCoinToken sct = SaintCoinToken(saintCoinAddress);
        sct.sendTo(msg.sender, msg.value);
        
        fundationWalletAddress.transfer(this.balance * (100 - percentForHelpCoin) / 100);
        sct.helpCoinAddress().transfer(this.balance);
    }
}