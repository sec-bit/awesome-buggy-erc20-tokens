/*
https://lumberscout.io : aut viam inveniam aut faciam
*/


pragma solidity ^0.4.19;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


/**
   @title ERC827 interface, an extension of ERC20 token standard
   Interface of a ERC827 token, following the ERC20 standard with extra
   methods to transfer value and data and execute calls in transfers and
   approvals.
 */
contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
  function balanceOf(address _owner) public view returns (uint256 balance) {
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

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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



/**
   @title ERC827, an extension of ERC20 token standard
   Implementation the ERC827, following the ERC20 standard with extra
   methods to transfer value and data and execute calls in transfers and
   approvals.
   Uses OpenZeppelin StandardToken.
 */
contract ERC827Token is ERC827, StandardToken {

  /**
     @dev Addition to ERC20 token methods. It allows to
     approve the transfer of value and execute a call with the sent data.
     Beware that changing an allowance with this method brings the risk that
     someone may use both the old and the new allowance by unfortunate
     transaction ordering. One possible solution to mitigate this race condition
     is to first reduce the spender's allowance to 0 and set the desired value
     afterwards:
     https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     @param _spender The address that will spend the funds.
     @param _value The amount of tokens to be spent.
     @param _data ABI-encoded contract call to call `_to` address.
     @return true if the call function was executed successfully
   */
  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call(_data));

    return true;
  }

  /**
     @dev Addition to ERC20 token methods. Transfer tokens to a specified
     address and execute a call with the sent data on the same transaction
     @param _to address The address which you want to transfer to
     @param _value uint256 the amout of tokens to be transfered
     @param _data ABI-encoded contract call to call `_to` address.
     @return true if the call function was executed successfully
   */
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call(_data));
    return true;
  }

  /**
     @dev Addition to ERC20 token methods. Transfer tokens from one address to
     another and make a contract call on the same transaction
     @param _from The address which you want to send tokens from
     @param _to The address which you want to transfer to
     @param _value The amout of tokens to be transferred
     @param _data ABI-encoded contract call to call `_to` address.
     @return true if the call function was executed successfully
   */
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call(_data));
    return true;
  }

  /**
   * @dev Addition to StandardToken methods. Increase the amount of tokens that
   * an owner allowed to a spender and execute a call with the sent data.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   * @param _data ABI-encoded contract call to call `_spender` address.
   */
  function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    require(_spender.call(_data));

    return true;
  }

  /**
   * @dev Addition to StandardToken methods. Decrease the amount of tokens that
   * an owner allowed to a spender and execute a call with the sent data.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   * @param _data ABI-encoded contract call to call `_spender` address.
   */
  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    require(_spender.call(_data));

    return true;
  }

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


contract TALLY is ERC827Token, Ownable
{
    using SafeMath for uint256;
    
    string public constant name = "TALLY";
    string public constant symbol = "TLY";
    uint256 public constant decimals = 18;
    
    address public foundationAddress;
    address public developmentFundAddress;
    uint256 public constant DEVELOPMENT_FUND_LOCK_TIMESPAN = 2 years;
    
    uint256 public developmentFundUnlockTime;
    
    bool public tokenSaleEnabled;
    
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public preSaleTLYperETH;
    
    uint256 public preferredSaleStartTime;
    uint256 public preferredSaleEndTime;
    uint256 public preferredSaleTLYperETH;

    uint256 public mainSaleStartTime;
    uint256 public mainSaleEndTime;
    uint256 public mainSaleTLYperETH;
    
    uint256 public preSaleTokensLeftForSale = 70000000 * (uint256(10)**decimals);
    uint256 public preferredSaleTokensLeftForSale = 70000000 * (uint256(10)**decimals);
    
    uint256 public minimumAmountToParticipate = 0.5 ether;
    
    mapping(address => uint256) public addressToSpentEther;
    mapping(address => uint256) public addressToPurchasedTokens;
    
    function TALLY() public
    {
        owner = 0xd512fa9Ca3DF0a2145e77B445579D4210380A635;
        developmentFundAddress = 0x4D18700A05D92ae5e49724f13457e1959329e80e;
        foundationAddress = 0xf1A2e7a164EF56807105ba198ef8F2465B682B16;
        
        balances[developmentFundAddress] = 300000000 * (uint256(10)**decimals);
        Transfer(0x0, developmentFundAddress, balances[developmentFundAddress]);
        
        balances[this] = 1000000000 * (uint256(10)**decimals);
        Transfer(0x0, this, balances[this]);
        
        totalSupply_ = balances[this] + balances[developmentFundAddress];
        
        preSaleTLYperETH = 30000;
        preferredSaleTLYperETH = 25375;
        mainSaleTLYperETH = 20000;
        
        preSaleStartTime = 1518652800;
        preSaleEndTime = 1519516800; // 15 february 2018 - 25 february 2018
        
        preferredSaleStartTime = 1519862400;
        preferredSaleEndTime = 1521072000; // 01 march 2018 - 15 march 2018
        
        mainSaleStartTime = 1521504000;
        mainSaleEndTime = 1526774400; // 20 march 2018 - 20 may 2018
        
        tokenSaleEnabled = true;
        
        developmentFundUnlockTime = now + DEVELOPMENT_FUND_LOCK_TIMESPAN;
    }
    
    function () payable external
    {
        require(tokenSaleEnabled);
        
        require(msg.value >= minimumAmountToParticipate);
        
        uint256 tokensPurchased;
        if (now >= preSaleStartTime && now < preSaleEndTime)
        {
            tokensPurchased = msg.value.mul(preSaleTLYperETH);
            preSaleTokensLeftForSale = preSaleTokensLeftForSale.sub(tokensPurchased);
        }
        else if (now >= preferredSaleStartTime && now < preferredSaleEndTime)
        {
            tokensPurchased = msg.value.mul(preferredSaleTLYperETH);
            preferredSaleTokensLeftForSale = preferredSaleTokensLeftForSale.sub(tokensPurchased);
        }
        else if (now >= mainSaleStartTime && now < mainSaleEndTime)
        {
            tokensPurchased = msg.value.mul(mainSaleTLYperETH);
        }
        else
        {
            revert();
        }
        
        addressToSpentEther[msg.sender] = addressToSpentEther[msg.sender].add(msg.value);
        addressToPurchasedTokens[msg.sender] = addressToPurchasedTokens[msg.sender].add(tokensPurchased);
        
        this.transfer(msg.sender, tokensPurchased);
    }
    
    function refund() external
    {
        // Only allow refunds before the main sale has ended
        require(now < mainSaleEndTime);
        
        uint256 tokensRefunded = addressToPurchasedTokens[msg.sender];
        uint256 etherRefunded = addressToSpentEther[msg.sender];
        addressToPurchasedTokens[msg.sender] = 0;
        addressToSpentEther[msg.sender] = 0;
        
        // Send the tokens back to this contract
        balances[msg.sender] = balances[msg.sender].sub(tokensRefunded);
        balances[this] = balances[this].add(tokensRefunded);
        Transfer(msg.sender, this, tokensRefunded);
        
        // Add the tokens back to the pre-sale or preferred sale
        if (now < preSaleEndTime)
        {
            preSaleTokensLeftForSale = preSaleTokensLeftForSale.add(tokensRefunded);
        }
        else if (now < preferredSaleEndTime)
        {
            preferredSaleTokensLeftForSale = preferredSaleTokensLeftForSale.add(tokensRefunded);
        }
        
        // Send the ether back to the user
        msg.sender.transfer(etherRefunded);
    }
    
    // Prevent the development fund from transferring its tokens while they are locked
    function transfer(address _to, uint256 _value) public returns (bool)
    {
        if (msg.sender == developmentFundAddress && now < developmentFundUnlockTime) revert();
        super.transfer(_to, _value);
    }
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool)
    {
        if (msg.sender == developmentFundAddress && now < developmentFundUnlockTime) revert();
        super.transfer(_to, _value, _data);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
        if (_from == developmentFundAddress && now < developmentFundUnlockTime) revert();
        super.transferFrom(_from, _to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool)
    {
        if (_from == developmentFundAddress && now < developmentFundUnlockTime) revert();
        super.transferFrom(_from, _to, _value, _data);
    }
    
    // Allow the owner to retrieve all the collected ETH
    function drain() external onlyOwner
    {
        owner.transfer(this.balance);
    }
    
    // Allow the owner to enable or disable the token sale at any time.
    function enableTokenSale() external onlyOwner
    {
        tokenSaleEnabled = true;
    }
    function disableTokenSale() external onlyOwner
    {
        tokenSaleEnabled = false;
    }
    
    function moveUnsoldTokensToFoundation() external onlyOwner
    {
        this.transfer(foundationAddress, balances[this]);
    }
    
    // Pre-sale configuration
    function setPreSaleTLYperETH(uint256 _newTLYperETH) public onlyOwner
    {
        preSaleTLYperETH = _newTLYperETH;
    }
    function setPreSaleStartAndEndTime(uint256 _newStartTime, uint256 _newEndTime) public onlyOwner
    {
        preSaleStartTime = _newStartTime;
        preSaleEndTime = _newEndTime;
    }
    
    // Preferred sale configuration
    function setPreferredSaleTLYperETH(uint256 _newTLYperETH) public onlyOwner
    {
        preferredSaleTLYperETH = _newTLYperETH;
    }
    function setPreferredSaleStartAndEndTime(uint256 _newStartTime, uint256 _newEndTime) public onlyOwner
    {
        preferredSaleStartTime = _newStartTime;
        preferredSaleEndTime = _newEndTime;
    }
    
    // Main sale configuration
    function setMainSaleTLYperETH(uint256 _newTLYperETH) public onlyOwner
    {
        mainSaleTLYperETH = _newTLYperETH;
    }
    function setMainSaleStartAndEndTime(uint256 _newStartTime, uint256 _newEndTime) public onlyOwner
    {
        mainSaleStartTime = _newStartTime;
        mainSaleEndTime = _newEndTime;
    }
}