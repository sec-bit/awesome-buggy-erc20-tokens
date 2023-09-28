pragma solidity ^0.4.18;


/// @title SafeMath contract - Math operations with safety checks.
/// @author OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
contract SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint a, uint b) internal pure returns (uint) {
        uint c = a ** b;
        assert(c >= a);
        return c;
    }
}

/// @title Abstract ERC20 token interface
contract AbstractToken {

    function balanceOf(address owner) public view returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}



contract Owned {

    address public owner = msg.sender;
    address public potentialOwner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPotentialOwner {
        require(msg.sender == potentialOwner);
        _;
    }

    event NewOwner(address old, address current);
    event NewPotentialOwner(address old, address potential);

    function setOwner(address _new)
        public
        onlyOwner
    {
        NewPotentialOwner(owner, _new);
        potentialOwner = _new;
    }

    function confirmOwnership()
        public
        onlyPotentialOwner
    {
        NewOwner(owner, potentialOwner);
        owner = potentialOwner;
        potentialOwner = 0;
    }
}


/// @title Token contract - Implements Standard ERC20 Token for SberCoin project.
/// @author Nice Folk Out
contract WealthManagement is Owned, SafeMath {

    event DepositReceived(uint256 value);
    event WithdrawPerformed(uint256 value);

    // Wealth Currency (sberTokenAddress)
    address public currency;

    // Trader
    address public trader;

    //Deposit Counter
    uint256 public deposits;

    //Withdraws Counter
    uint256 public withdraws;

    //Trades counterclaim
    uint256 public trades;

    modifier onlyOwnerOrTrader {
        require(msg.sender == owner || msg.sender == trader);
        _;
    }

    /// @dev Contract constructor
    function WealthManagement(address _currency, address _trader)
        public
    {
        currency = _currency;
        trader = _trader;
    }

    function deposit(uint256 depositAmount)
      public
      onlyOwner
    {
      require(AbstractToken(currency).transferFrom(owner, this, depositAmount));
      deposits = add(deposits, depositAmount);
      DepositReceived(depositAmount);
    }

    function withdraw(uint withdrawAmount)
      public
      onlyOwner
    {
      uint256 currentBalance = AbstractToken(currency).balanceOf(address(this));

      require(currentBalance >= withdrawAmount);

      require(AbstractToken(currency).transfer(owner, withdrawAmount));

      withdraws = add(withdraws, withdrawAmount);

      WithdrawPerformed(withdrawAmount);
    }

    function trade()
        public
        onlyOwnerOrTrader
    {
        //In this function we will implement logic of trades for AirSwap/Kyber Network/0x
        trades = trades + 1;
    }
}