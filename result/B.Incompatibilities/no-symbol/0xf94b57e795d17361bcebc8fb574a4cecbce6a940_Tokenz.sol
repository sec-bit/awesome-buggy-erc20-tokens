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
contract Tokenz is Owned {
  address public token;
  uint256 public inRate;
  uint256 public outRate;
  uint256 public minRate;
  uint256 public minLot;
  uint256 public leveRage;
  event Received(address indexed user, uint256 ethers, uint256 tokens);
  event Sent(address indexed user, uint256 ethers, uint256 tokens);
  function Tokenz (
    address _token,
    uint256 _inRate,
    uint256 _outRate,
    uint256 _minRate,
    uint256 _minLot,
    uint256 _leveRage
  ) public {
  	token=_token;
  	inRate=_inRate;
  	outRate=_outRate;
  	minRate=_minRate;
  	minLot=_minLot;
  	leveRage=_leveRage;
  }
  function WithdrawToken(address tokenAddress, uint256 tokens) onlyOwner public {
    if (!ERC20(tokenAddress).transfer(owner, tokens)) revert();
  }
  function WithdrawEther(uint256 ethers) onlyOwner public {
    if (this.balance<ethers) revert();
    owner.transfer(ethers);
  }
  function SetInRate (uint256 newrate) onlyOwner public {inRate=newrate;}
  function SetOutRate (uint256 newrate) onlyOwner public {outRate=newrate;}
  function ChangeToken (address newtoken) onlyOwner public {
    if (newtoken==0x0) revert();
    token=newtoken;
  }
  function SetLot (uint256 newlot) onlyOwner public {
    if (newlot<=0) revert();
    minLot=newlot;
  }
  function TokensIn(uint256 tokens) public {
    if (inRate==0) revert();
    uint256 maxtokens=this.balance/inRate;
    if (tokens>maxtokens) tokens=maxtokens;
    if (tokens<minLot) revert();
    uint256 total=ERC20(token).balanceOf(msg.sender);
    if (total<tokens) revert();
    if (!ERC20(token).approve(address(this),tokens)) revert();
    if (!ERC20(token).transferFrom(msg.sender, address(this), tokens)) revert();
    uint256 sum = tokens*inRate;
    msg.sender.transfer(sum);
    uint256 newrate = inRate-tokens*leveRage;
    if (newrate>=minRate) {
      inRate=newrate;
      outRate=outRate-tokens*leveRage;	
    }
    Received(msg.sender, sum, tokens);
  }
  function TokensOut() payable public {
    if (outRate==0) revert();
    uint256 tokens=msg.value/outRate;
    if (tokens<minLot) revert();
    uint256 total=ERC20(token).balanceOf(address(this));
    if (total<=0) revert();
    uint256 change=0;
    uint256 maxeth=total*outRate;
    if (msg.value>maxeth) change=msg.value-maxeth;
    if (change>0) msg.sender.transfer(change);
    if (!ERC20(token).transfer(msg.sender, tokens)) revert();
    outRate=outRate+tokens*leveRage;
    inRate=inRate+tokens*leveRage;
    Sent(msg.sender, msg.value, tokens);
  }
  function () payable public {TokensOut();}
}