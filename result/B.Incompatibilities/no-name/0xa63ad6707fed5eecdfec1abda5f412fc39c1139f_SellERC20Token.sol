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
contract SellERC20Token is Owned {
  address public token;
  uint256 public sellPrice;
  uint256 public minLot;
  event TokensBought(address indexed buyer, uint256 ethersSent, uint256 tokensBought);
  event TradeStatus(address indexed owner, address indexed token, uint256 price, uint256 lot);
  function SellERC20Token (
    address _token,
    uint256 _sellPrice,
    uint256 _minLot
  ) public {
  	token=_token;
  	sellPrice=_sellPrice;
  	minLot=_minLot;
  }
  function WithdrawToken(uint256 tokens) onlyOwner public returns (bool ok) {
    return ERC20(token).transfer(owner, tokens);
  }
  function WithdrawEther(uint256 ethers) onlyOwner public returns (bool ok) {
    if (this.balance>=ethers) return owner.send(ethers);
  }
  function SetPrice (uint256 newprice) onlyOwner public {
    sellPrice = newprice;
    TradeStatus(owner,token,sellPrice,minLot);
  }
  function ChangeToken (address newtoken) onlyOwner public {
    if (newtoken==0x0) revert();
    token=newtoken;
    TradeStatus(owner,token,sellPrice,minLot);
  }
  function SetLot (uint256 newlot) onlyOwner public {
    if (newlot<=0) revert();
    minLot=newlot;
    TradeStatus(owner,token,sellPrice,minLot);
  }
  function SellToken() payable public {
    uint tokens=msg.value/sellPrice;
    if (tokens<minLot) revert();
    uint total=ERC20(token).balanceOf(address(this));
    uint256 change=0;
    uint256 maxeth=total*sellPrice;
    if (msg.value>maxeth) change=msg.value-maxeth;
    if (change>0) if (!msg.sender.send(change)) revert();
    if (!ERC20(token).transfer(msg.sender, tokens)) revert();
    TokensBought(msg.sender, msg.value, tokens);
    TradeStatus(owner,token,sellPrice,minLot);
  }
  function () payable public {SellToken();}
}