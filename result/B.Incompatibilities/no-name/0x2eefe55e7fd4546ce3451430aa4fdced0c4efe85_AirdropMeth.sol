pragma solidity ^0.4.18;

contract Ownable {
  address public owner;
  address public newOwner;
  event OwnershipTransferred(address indexed _from, address indexed _to);
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AirdropMeth is Ownable{
    ERC20 public token;
    address public creator;
    
    event LogAccountAmount(address indexed user, uint256 indexed amount);

    function AirdropMeth(address _token) public {
        token = ERC20(_token);
        owner = msg.sender;
    }

    function setToken(address _token) public {
        token = ERC20(_token);
    }

    // Uses transferFrom so you'll need to approve some tokens before this one to
    // this contract address
    function startAirdropFrom(address _fromAddr, address[] users, uint256 amounts) public onlyOwner {
        for(uint256 i = 0; i < users.length; i++) {
            
            LogAccountAmount(users[i], amounts);

            token.transferFrom(_fromAddr, users[i], amounts);
        }
    }
    
    function startAirdrop(address[] _user, uint256 _amount) public onlyOwner {
    	for(uint256 i = 0; i < _user.length; i++) {
        	token.transfer(_user[i], _amount);
        }
    }
    function removeContract() public onlyOwner {
            selfdestruct(msg.sender);
            
        }
}