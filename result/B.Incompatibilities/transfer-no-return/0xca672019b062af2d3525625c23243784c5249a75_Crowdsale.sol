pragma solidity ^0.4.2;

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
}

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic {
  
  using SafeMath for uint;
  
  mapping(address => uint) balances;
  
  /*
   * Fix for the ERC20 short address attack  
  */
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
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

contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    // Check is not needed because sub(_allowance, _value) will already revert() if this condition is not met
    // if (_value > _allowance) revert();
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract PullPayment {

  using SafeMath for uint;
  
  mapping(address => uint) public payments;

  event LogRefundETH(address to, uint value);


  /**
  *  Store sent amount as credit to be pulled, called by payer 
  **/
  function asyncSend(address dest, uint amount) internal {
    payments[dest] = payments[dest].add(amount);
  }

  // withdraw accumulated balance, called by payee
  function withdrawPayments() {
    address payee = msg.sender;
    uint payment = payments[payee];
    
    require (payment > 0);
    require (this.balance >= payment);

    payments[payee] = 0;

    require (payee.send(payment));
    
    LogRefundETH(payee,payment);
  }
}

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Pausable is Ownable {
  bool public stopped;

  modifier stopInEmergency {
    require(!stopped);
    _;
  }
  
  modifier onlyInEmergency {
    require(stopped);
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function emergencyStop() external onlyOwner {
    stopped = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
  }

}

/**
 *  UmbrellaCoin token contract.
 */
contract UmbrellaCoin is StandardToken, Ownable {
  string public constant name = "UmbrellaCoin";
  string public constant symbol = "UMC";
  uint public constant decimals = 6;
  address public floatHolder;

  // Constructor
  function UmbrellaCoin() {
      totalSupply = 100000000000000;
      balances[msg.sender] = totalSupply; // Send all tokens to owner
      floatHolder = msg.sender;
  }

}


contract Crowdsale is Ownable{
    using SafeMath for uint;

    address public beneficiary;
    uint public amountRaised; uint public price;
    UmbrellaCoin public tokenReward;

    /* data structure to hold information about campaign contributors */

    /*  at initialization, setup the owner */
    function Crowdsale() {
        beneficiary = 0x6c7a8975e67dBb9c0C9664410862C91A01401fE7;
        price = 1666 szabo;
        tokenReward = UmbrellaCoin(0x190fB342aa6a15eB82903323ae78066fF8616746);
    }

    /* The function without name is the default function that is called whenever anyone sends funds to a contract */
    function () payable {
        if (msg.value < 1 ether || msg.value > 3000 ether) revert();
        uint amount = msg.value;
        amountRaised += amount;
        uint payout = bonus(amount.div(price).mul(1000000));
        beneficiary.transfer(msg.value);
        tokenReward.transfer(msg.sender, payout);
    }

        /*
     *Compute the UmbrellaCoin bonus according to the investment period
     */
    function bonus(uint amount) internal constant returns (uint) {
    if (amountRaised <= 350 ether ) { return amount.mul(4);   // bonus 400%
    } else if (amountRaised >= 351 ether && amountRaised <= 1000 ether ) { return amount.mul(3);   // bonus 300%
    } else if (amountRaised >= 1001 ether && amountRaised <= 1950 ether ) { return amount.mul(2);   // bonus 200%
    } else if (amountRaised >= 1951 ether && amountRaised <= 4000 ether ) { return (amount.mul(15))/10;   // bonus 150%
    }
    return amount;
    }

        /**
     * Transfer remains to owner in case if impossible to do min invest
     */
    function sendCoinsToBeneficiary() onlyOwner public {
        tokenReward.transfer(beneficiary, tokenReward.balanceOf(this));
    }
}