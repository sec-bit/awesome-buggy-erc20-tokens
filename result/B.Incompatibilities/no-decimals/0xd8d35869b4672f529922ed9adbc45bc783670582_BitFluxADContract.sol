pragma solidity ^0.4.11;

contract ERC20Interface {
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract BitFluxADContract {
    
  // The token being sold
  ERC20Interface public token;

  
  // address where funds are collected
  // address where tokens are deposited and from where we send tokens to buyers
  address public wallet;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function BitFluxADContract(address _wallet, address _tokenAddress) public 
  {
    require(_wallet != 0x0);
    require (_tokenAddress != 0x0);
    wallet = _wallet;
    token = ERC20Interface(_tokenAddress);
  }
  
  // fallback function can be used to buy tokens
  function () public payable {
    throw;
  }

    /**
     * airdrop to token holders
     **/ 
    function BulkTransfer(address[] tokenHolders, uint amount) public {
        require(msg.sender==wallet);
        for(uint i = 0; i<tokenHolders.length; i++)
        {
            token.transferFrom(wallet,tokenHolders[i],amount);
        }
    }
}