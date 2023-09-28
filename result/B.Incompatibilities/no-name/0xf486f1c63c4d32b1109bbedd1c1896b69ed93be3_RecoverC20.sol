pragma solidity ^0.4.17;

contract Token { // ERC20 standard

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract RecoverC20 {

  address public owner;
  Token public C20Token;

  address[] public addressList;
  mapping (address => bool) public added;
  mapping (address => uint256) public allowances;

  address public receivingAddress = 0x9bb3fdb9CD7B6D63Abfb493a362845EBAc5f94c7; // TODO: change

  uint public index = 0;

  modifier onlyOwner { // exempt vestingContract and fundWallet to allow dev allocations
    require(msg.sender == owner);
    _;
  }

  function RecoverC20(address tokenAddress) public { // constructor
    owner = msg.sender;
    C20Token = Token(tokenAddress);
  }

  function resetIndex() public onlyOwner {
    index = 0;
  }

  function addAddresses(address[] tokenHolders) public onlyOwner {
    for(uint i = 0; i < tokenHolders.length; i++) {
      address tokenHolder = tokenHolders[i];
      require(!added[tokenHolder]);
      added[tokenHolder] = true;
      addressList.push(tokenHolder);
    }
  }

  function recoverTokens(uint count) public onlyOwner {
    for(uint i = 0; index < addressList.length && i < count; i++) {
      address tokenHolder = addressList[index];
      uint value = C20Token.allowance(tokenHolder, this); // check allowance of this contract address
      if(value!=0) {
        C20Token.transferFrom(tokenHolder, receivingAddress, value);
      }
      index++;
    }
  }

  function returnAddressList() public constant returns (address[]) {
   return addressList;
 }

}