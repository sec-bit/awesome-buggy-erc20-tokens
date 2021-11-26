pragma solidity ^0.4.8;

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

contract Killable is Ownable {
  function kill() onlyOwner {
    selfdestruct(owner);
  }
}

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
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


/// @title Veritaseum Purchase
/// @author Riaan F Venter~ RFVenter~ <msg@rfv.io>
contract TokenPurchase is Ownable, Killable, SafeMath {

    uint public constant startTime = 1493130600;            // 2017 April 25th 9:30 EST (14:30 UTC)
    uint public constant closeTime = startTime + 31 days;   // ICO will run for 31 days
    uint public constant price = 33333333333333333;         // Each token has 18 decimal places, just like ether.
    uint private constant priceDayOne = price * 8 / 10;     // Day one price [20 % discount (x * 8 / 10)]
    uint private constant priceDayTwo = price * 9 / 10;     // Day two price [10 % discount (x * 9 / 10)]

    ERC20 public token;                         // the address of the token 

    // //// time test functionality /////
    // uint public now;                //
    //                                 //
    // function setNow(uint _time) {   //
    //     now = _time;                //
    // }                               //
    // //////////////////////////////////

    /// @notice Used to buy tokens with Ether
    /// @return The amount of actual tokens purchased
    function purchaseTokens() payable returns (uint) {
        // check if now is within ICO period, or if the amount sent is nothing
        if ((now < startTime) || (now > closeTime) || (msg.value == 0)) throw;
        
        uint currentPrice;
        // only using safeMath for calculations involving external incoming data (to safe gas)
        if (now < (startTime + 1 days)) {       // day one discount
            currentPrice = priceDayOne;
        } 
        else if (now < (startTime + 2 days)) {  // day two discount
            currentPrice = priceDayTwo;
        }
        else if (now < (startTime + 12 days)) {
            // 1 % reduction in the discounted rate from day 2 until day 12 (sliding scale per second)
            currentPrice = price - ((startTime + 12 days - now) * price / 100 days);
        }
        else {
            currentPrice = price;
        }
        uint tokens = safeMul(msg.value, 1 ether) / currentPrice;       // only one safeMath check is required for the incoming ether value

        if (!token.transferFrom(owner, msg.sender, tokens)) throw;      // if there is some error with the token transfer, throw and return the Ether

        return tokens;                          // after successful purchase, return the amount of tokens purchased value
    }

    //////////////// owner only functions below

    /// @notice Withdraw all Ether in this contract
    /// @return True if successful
    function withdrawEther() payable onlyOwner returns (bool) {
        return owner.send(this.balance);
    }

    /// @notice sets the token that is to be used for this Lottery
    /// @param _token The address of the ERC20 token
    function setToken(address _token) external onlyOwner {     
        token = ERC20(_token);
    }
}