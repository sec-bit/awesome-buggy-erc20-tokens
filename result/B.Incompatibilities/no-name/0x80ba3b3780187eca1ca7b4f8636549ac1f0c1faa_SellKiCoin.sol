pragma solidity ^0.4.18;

contract ERC20 {
  function totalSupply() constant public returns (uint totalsupply);
  function balanceOf(address _owner) constant public returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) constant public returns (uint remaining);
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Owned {
  address public owner;
  event OwnershipTransferred(address indexed _from, address indexed _to);

  function Owned() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    if (msg.sender != owner) revert();
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract SellKiCoin is Owned {
  address public constant payto1=0x4dF46817dc0e8dD69D7DA51b0e2347f5EFdB9671;
  address public constant payto2=0xd58f863De3bb877F24996291cC3C659b3550d58e;
  address public constant payto3=0x574c4DB1E399859753A09D65b6C5586429663701;
  address public constant token=0x8b0e368aF9d27252121205B1db24d9E48f62B236;
  uint256 public constant share1=800;
  uint256 public constant share2=100;
  uint256 public constant share3=5;
  uint256 public sellPrice=2122* 1 szabo;
  uint256 public minLot=5;
	
  event GotTokens(address indexed buyer, uint256 ethersSent, uint256 tokensBought);
	
  function SellKiCoin () public {}
    
  function WithdrawToken(uint256 tokens) onlyOwner public returns (bool ok) {
    return ERC20(token).transfer(owner, tokens);
  }
    
  function SetPrice (uint256 newprice) onlyOwner public {
    sellPrice = newprice * 1 szabo;
  }
  
  function SetMinLot (uint256 newminlot) onlyOwner public {
    if (newminlot>=5) minLot = newminlot;
    else revert();
  }
    
  function WithdrawEther(uint256 ethers) onlyOwner public returns (bool ok) {
    if (this.balance >= ethers) {
      return owner.send(ethers);
    }
  }
    
  function BuyToken() payable public {
    uint tokens = msg.value / sellPrice;
    uint total = ERC20(token).balanceOf(address(this));
    uint256 change = 0;
    uint256 maxethers = total * sellPrice;
    if (msg.value > maxethers) {
      change  = msg.value - maxethers;
    }
    if (change > 0) {
      if (!msg.sender.send(change)) revert();
    }
    if (tokens > minLot) {
      if (!ERC20(token).transfer(msg.sender, tokens)) revert();
      else {
        if (!payto1.send(msg.value*share1/1000)) revert();
        else if (!payto2.send(msg.value*share2/1000)) revert();
        else if (!payto3.send(msg.value*share3/1000)) revert();
        GotTokens(msg.sender, msg.value, tokens);
      }
    }
  }
    
  function () payable public {
    BuyToken();
  }
}