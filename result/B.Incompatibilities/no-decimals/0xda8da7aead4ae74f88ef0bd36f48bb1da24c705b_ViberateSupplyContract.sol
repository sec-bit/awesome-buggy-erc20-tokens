contract IERC20Token {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function approve(address _spender, uint256 _value) returns (bool success) {}
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract IVestedContract{
    function getTokenBalance() public constant returns(uint);
}


contract ViberateSupplyContract{
    
    address tokenAddress;
    address communityLockedAddress;
    address teamLockedAddress;
    
    function ViberateSupplyContract(){
        tokenAddress = 0x2C974B2d0BA1716E644c1FC59982a89DDD2fF724;
        communityLockedAddress = 0x12eb08e27eEc735a16dB29b660070cf10808dE63;
        teamLockedAddress = 0x4026f73F99427C6b70c9b101321895CEE6B72659;
    }
    
    function totalSupply() constant returns (uint){
        return IERC20Token(tokenAddress).totalSupply();
    }
    
    function totalAvaliableSupply() constant returns (uint){
       return IERC20Token(tokenAddress).totalSupply() - IVestedContract(communityLockedAddress).getTokenBalance() - IVestedContract(teamLockedAddress).getTokenBalance(); 
    }
}