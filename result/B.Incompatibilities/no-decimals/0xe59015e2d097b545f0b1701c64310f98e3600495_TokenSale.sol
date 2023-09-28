pragma solidity ^0.4.18;

 
 /*
 * NYX Token sale
 *
 * Supports ERC20, ERC223 stadards
 *
 * The NYX token is mintable during Token Sale. On Token Sale finalization it
 * will be minted up to the cap and minting will be finished forever
 */


pragma solidity ^0.4.18;


/*************************************************************************
 * import "./include/MintableToken.sol" : start
 *************************************************************************/

/*************************************************************************
 * import "zeppelin/contracts/token/StandardToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./BasicToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./ERC20Basic.sol" : start
 *************************************************************************/


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/*************************************************************************
 * import "./ERC20Basic.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "../math/SafeMath.sol" : start
 *************************************************************************/


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
/*************************************************************************
 * import "../math/SafeMath.sol" : end
 *************************************************************************/


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
  function transfer(address _to, uint256 _value) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}
/*************************************************************************
 * import "./BasicToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./ERC20.sol" : start
 *************************************************************************/





/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/*************************************************************************
 * import "./ERC20.sol" : end
 *************************************************************************/


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
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}
/*************************************************************************
 * import "zeppelin/contracts/token/StandardToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "zeppelin/contracts/ownership/Ownable.sol" : start
 *************************************************************************/


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}
/*************************************************************************
 * import "zeppelin/contracts/ownership/Ownable.sol" : end
 *************************************************************************/

/**
 * Mintable token
 */

contract MintableToken is StandardToken, Ownable {
    uint public totalSupply = 0;
    address minter;

    modifier onlyMinter(){
        require(minter == msg.sender);
        _;
    }

    function setMinter(address _minter) onlyOwner {
        minter = _minter;
    }

    function mint(address _to, uint _amount) onlyMinter {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0x0), _to, _amount);
    }
}
/*************************************************************************
 * import "./include/MintableToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./include/ERC23PayableToken.sol" : start
 *************************************************************************/



/*************************************************************************
 * import "./ERC23.sol" : start
 *************************************************************************/




/*
 * ERC23
 * ERC23 interface
 * see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC23 is ERC20Basic {
    function transfer(address to, uint value, bytes data);

    event TransferData(address indexed from, address indexed to, uint value, bytes data);
}
/*************************************************************************
 * import "./ERC23.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./ERC23PayableReceiver.sol" : start
 *************************************************************************/

/*
* Contract that is working with ERC223 tokens
*/

contract ERC23PayableReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) payable;
}

/*************************************************************************
 * import "./ERC23PayableReceiver.sol" : end
 *************************************************************************/

/**  https://github.com/Dexaran/ERC23-tokens/blob/master/token/ERC223/ERC223BasicToken.sol
 *
 */
contract ERC23PayableToken is BasicToken, ERC23{
    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address to, uint value, bytes data){
        transferAndPay(to, value, data);
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address to, uint value) returns (bool){
        bytes memory empty;
        transfer(to, value, empty);
        return true;
    }

    function transferAndPay(address to, uint value, bytes data) payable {

        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(to)
        }

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        if(codeLength>0) {
            ERC23PayableReceiver receiver = ERC23PayableReceiver(to);
            receiver.tokenFallback.value(msg.value)(msg.sender, value, data);
        }else if(msg.value > 0){
            to.transfer(msg.value);
        }

        Transfer(msg.sender, to, value);
        if(data.length > 0)
            TransferData(msg.sender, to, value, data);
    }
}
/*************************************************************************
 * import "./include/ERC23PayableToken.sol" : end
 *************************************************************************/


contract NYXToken is MintableToken, ERC23PayableToken {
    string public constant name = "NYX Token";
    string public constant symbol = "NYX";

    bool public transferEnabled = true;

    //The cap is 15 mln NYX
    uint private constant CAP = 15*(10**6);

    function mint(address _to, uint _amount){
        require(totalSupply.add(_amount) <= CAP);
        super.mint(_to, _amount);
    }

    function NYXToken(address team) {
        //Transfer ownership on the token to team on creation
        transferOwnership(team);
        // minter is the TokenSale contract
        minter = msg.sender; 
        /// Preserve 3 000 000 tokens for the team
        mint(team, 3000000);
    }

    /**
    * Overriding all transfers to check if transfers are enabled
    */
    function transferAndPay(address to, uint value, bytes data) payable{
        require(transferEnabled);
        super.transferAndPay(to, value, data);
    }

    function enableTransfer(bool enabled) onlyOwner{
        transferEnabled = enabled;
    }

}

contract TokenSale is Ownable {
    using SafeMath for uint;

    // Constants
    // =========
    uint private constant millions = 1e6;

    uint private constant CAP = 15*millions;
    uint private constant SALE_CAP = 12*millions;
    uint private constant SOFT_CAP = 1400000;
    
    // Allocated for the team upon contract creation
    // =========
    uint private constant TEAM_CAP = 3000000;

    uint public price = 0.001 ether;
    
    // Hold investor's ether amounts to refund
    address[] contributors;
    mapping(address => uint) contributions;

    // Events
    // ======

    event AltBuy(address holder, uint tokens, string txHash);
    event Buy(address holder, uint tokens);
    event RunSale();
    event PauseSale();
    event FinishSale();
    event PriceSet(uint weiPerNYX);

    // State variables
    // ===============
    bool public presale = true;
    NYXToken public token;
    address authority; //An account to control the contract on behalf of the owner
    address robot; //An account to purchase tokens for altcoins
    bool public isOpen = true;

    // Constructor
    // ===========

    function TokenSale(){
        token = new NYXToken(msg.sender);

        authority = msg.sender;
        robot = msg.sender;
        transferOwnership(msg.sender);
    }

    // Public functions
    // ================
    function togglePresale(bool activate) onlyAuthority {
        presale = activate;
    }


    function getCurrentPrice() constant returns(uint) {
        if(presale) {
            return price - (price*20/100);
        }
        return price;
    }
    /**
    * Computes number of tokens with bonus for the specified ether. Correctly
    * adds bonuses if the sum is large enough to belong to several bonus intervals
    */
    function getTokensAmount(uint etherVal) constant returns (uint) {
        uint tokens = 0;
        tokens += etherVal/getCurrentPrice();
        return tokens;
    }

    function buy(address to) onlyOpen payable{
        uint amount = msg.value;
        uint tokens = getTokensAmountUnderCap(amount);
        
        // owner.transfer(amount);

		token.mint(to, tokens);
		
		uint alreadyContributed = contributions[to];
		if(alreadyContributed == 0) // new contributor
		    contributors.push(to);
		    
		contributions[to] = contributions[to].add(msg.value);

        Buy(to, tokens);
    }

    function () payable{
        buy(msg.sender);
    }

    // Modifiers
    // =================

    modifier onlyAuthority() {
        require(msg.sender == authority || msg.sender == owner);
        _;
    }

    modifier onlyRobot() {
        require(msg.sender == robot);
        _;
    }

    modifier onlyOpen() {
        require(isOpen);
        _;
    }

    // Priveleged functions
    // ====================

    /**
    * Used to buy tokens for altcoins.
    * Robot may call it before TokenSale officially starts to migrate early investors
    */
    function buyAlt(address to, uint etherAmount, string _txHash) onlyRobot {
        uint tokens = getTokensAmountUnderCap(etherAmount);
        token.mint(to, tokens);
        AltBuy(to, tokens, _txHash);
    }

    function setAuthority(address _authority) onlyOwner {
        authority = _authority;
    }

    function setRobot(address _robot) onlyAuthority {
        robot = _robot;
    }

    function setPrice(uint etherPerNYX) onlyAuthority {
        price = etherPerNYX;
        PriceSet(price);
    }

    // SALE state management: start / pause / finalize
    // --------------------------------------------
    function open(bool opn) onlyAuthority {
        isOpen = opn;
        opn ? RunSale() : PauseSale();
    }
    
    function finalizePresale() onlyAuthority {
        // Check for SOFT_CAP
        require(token.totalSupply() > SOFT_CAP + TEAM_CAP);
        // Transfer collected softcap to the team
        owner.transfer(this.balance);
    }

    function finalize() onlyAuthority {
        // Check for SOFT_CAP
        if(token.totalSupply() < SOFT_CAP + TEAM_CAP) { // Soft cap is not reached, return all contributions to investors
            uint x = 0;
            while(x < contributors.length) {
                uint amountToReturn = contributions[contributors[x]];
                contributors[x].transfer(amountToReturn);
                x++;
            }
        }
        
        uint diff = CAP.sub(token.totalSupply());
        if(diff > 0) //The unsold capacity moves to team
            token.mint(owner, diff);
        selfdestruct(owner);
        FinishSale();
    }

    // Private functions
    // =========================

    /**
    * Gets tokens for specified ether provided that they are still under the cap
    */
    function getTokensAmountUnderCap(uint etherAmount) private constant returns (uint){
        uint tokens = getTokensAmount(etherAmount);
        require(tokens > 0);
        require(tokens.add(token.totalSupply()) <= SALE_CAP);
        return tokens;
    }

}