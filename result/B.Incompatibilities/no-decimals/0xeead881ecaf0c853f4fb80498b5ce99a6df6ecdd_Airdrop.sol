pragma solidity ^0.4.18;

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

contract Airdrop {
    ERC20 public token;
    
    event LogAccountAmount(address indexed user, uint256 indexed amount);

    function Airdrop(address _token) public {
        token = ERC20(_token);
    }

    function setToken(address _token) public {
        token = ERC20(_token);
    }

    // Uses transferFrom so you'll need to approve some tokens before this one to
    // this contract address
    function startAirdrop(address[] users, uint256[] amounts) public {
        for(uint256 i = 0; i < users.length; i++) {
            address account = users[i];
            uint256 amount = amounts[i];
            
            LogAccountAmount(account, amount);
            
            token.transfer(account, amount);
        }
    }
    
    function recoverTokens(address _user, uint256 _amount) public {
        token.transfer(_user, _amount);
    }
}