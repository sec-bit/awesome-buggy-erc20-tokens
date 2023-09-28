pragma solidity ^0.4.18;

contract Token {
  /// @return total amount of tokens
  function totalSupply() constant returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to,uint256 _value) returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from,address _to,uint256 _value) returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender,uint256 _value) returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner,address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from,address indexed _to,uint256 _value);
  event Approval(address indexed _owner,address indexed _spender,uint256 _value);

  uint decimals;
  string name;
}

contract SafeMath {
  function safeMul(uint a,uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }


  function safeDiv(uint a,uint b) internal returns (uint) {
    uint c = a / b;
    return c;
  }

  function safeSub(uint a,uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a,uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

contract ShortOrder is SafeMath {

  address admin;

  struct Order {
    uint coupon;
    uint balance;
    uint shortBalance;
    bool tokenDeposit;
    mapping (address => uint) longBalance;
  }

  mapping (address => mapping (bytes32 => Order)) orderRecord;

  event TokenFulfillment(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint blockNumber);
  event CouponDeposit(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint blockNumber);
  event LongPlace(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint value,uint blockNumber);
  event LongBought(address[2] sellerShort,uint[3] amountNonceExpiry,uint blockNumber);
  event TokenLongExercised(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint amount,uint blockNumber);
  event EthLongExercised(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint blockNumber);
  event DonationClaimed(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint balance,uint blockNumber);
  event NonActivationWithdrawal(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint blockNumber);
  event ActivationWithdrawal(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint balance,uint blockNumber);

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function ShortOrder() {
    admin = msg.sender;
  }

  function changeAdmin(address _admin) external onlyAdmin {
    admin = _admin;
  }

  function tokenFulfillmentDeposit(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint8 v,bytes32[2] rs) external {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        tokenEthDMWCPNonce[0],
        tokenEthDMWCPNonce[1], 
        tokenEthDMWCPNonce[2],
        tokenEthDMWCPNonce[3],
        tokenEthDMWCPNonce[4],
        tokenEthDMWCPNonce[5], 
        tokenEthDMWCPNonce[6]
      );
    require(
      ecrecover(keccak256("\x19Ethereum Signed Message:\n32",orderHash),v,rs[0],rs[1]) == msg.sender &&
      block.number > tokenEthDMWCPNonce[2] &&
      block.number <= tokenEthDMWCPNonce[3] && 
      orderRecord[msg.sender][orderHash].balance == tokenEthDMWCPNonce[1] &&
      !orderRecord[msg.sender][orderHash].tokenDeposit
    );
    Token(tokenUser[0]).transferFrom(msg.sender,this,tokenEthDMWCPNonce[0]);
    orderRecord[msg.sender][orderHash].shortBalance = safeAdd(orderRecord[msg.sender][orderHash].shortBalance,tokenEthDMWCPNonce[0]);
    orderRecord[msg.sender][orderHash].tokenDeposit = true;
    TokenFulfillment(tokenUser,tokenEthDMWCPNonce,block.number);
  }

  function depositCoupon(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint8 v,bytes32[2] rs) external payable {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        tokenEthDMWCPNonce[0],
        tokenEthDMWCPNonce[1], 
        tokenEthDMWCPNonce[2],
        tokenEthDMWCPNonce[3],
        tokenEthDMWCPNonce[4],
        tokenEthDMWCPNonce[5], 
        tokenEthDMWCPNonce[6]
      );
    require(
      ecrecover(keccak256("\x19Ethereum Signed Message:\n32",orderHash),v,rs[0],rs[1]) == msg.sender &&
      msg.value == tokenEthDMWCPNonce[1] &&
      block.number <= tokenEthDMWCPNonce[2]
    );
    orderRecord[msg.sender][orderHash].coupon = safeAdd(orderRecord[msg.sender][orderHash].coupon,msg.value);
    CouponDeposit(tokenUser,tokenEthDMWCPNonce,block.number);
  }

  function placeLong(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint8 v,bytes32[2] rs) external payable {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        tokenEthDMWCPNonce[0],
        tokenEthDMWCPNonce[1], 
        tokenEthDMWCPNonce[2],
        tokenEthDMWCPNonce[3],
        tokenEthDMWCPNonce[4],
        tokenEthDMWCPNonce[5], 
        tokenEthDMWCPNonce[6]
      );
    require(
      ecrecover(keccak256("\x19Ethereum Signed Message:\n32",orderHash),v,rs[0],rs[1]) == tokenUser[1] &&
      block.number <= tokenEthDMWCPNonce[2] &&
      orderRecord[tokenUser[1]][orderHash].coupon == tokenEthDMWCPNonce[5] &&
      orderRecord[tokenUser[1]][orderHash].balance <= tokenEthDMWCPNonce[1]
    );
    orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender] = safeAdd(orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender],msg.value);
    orderRecord[tokenUser[1]][orderHash].balance = safeAdd(orderRecord[tokenUser[1]][orderHash].balance,msg.value);
    LongPlace(tokenUser,tokenEthDMWCPNonce,msg.value,block.number);
  }

 function buyLong(address[2] sellerShort,uint[3] amountNonceExpiry,uint8 v,bytes32[3] hashRS) external payable {
    bytes32 longTransferHash = keccak256 (
        sellerShort[0],
        amountNonceExpiry[0],
        amountNonceExpiry[1],
        amountNonceExpiry[2]
    );
    require(
      ecrecover(keccak256("\x19Ethereum Signed Message:\n32",longTransferHash),v,hashRS[1],hashRS[2]) == sellerShort[1] &&
      block.number <= amountNonceExpiry[2] &&
      msg.value == amountNonceExpiry[0]
    );
    sellerShort[0].transfer(amountNonceExpiry[0]);
    orderRecord[sellerShort[1]][hashRS[0]].longBalance[msg.sender] = orderRecord[sellerShort[1]][hashRS[0]].longBalance[sellerShort[0]];
    orderRecord[sellerShort[1]][hashRS[0]].longBalance[sellerShort[0]] = uint(0);
    LongBought(sellerShort,amountNonceExpiry,block.number);
  }

  function exerciseLong(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint8 v,bytes32[2] rs) external {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        tokenEthDMWCPNonce[0],
        tokenEthDMWCPNonce[1], 
        tokenEthDMWCPNonce[2],
        tokenEthDMWCPNonce[3],
        tokenEthDMWCPNonce[4],
        tokenEthDMWCPNonce[5], 
        tokenEthDMWCPNonce[6]
      );
    require(
      ecrecover(keccak256("\x19Ethereum Signed Message:\n32",orderHash),v,rs[0],rs[1]) == tokenUser[1] &&
      block.number > tokenEthDMWCPNonce[3] &&
      block.number <= tokenEthDMWCPNonce[4] &&
      orderRecord[tokenUser[1]][orderHash].balance >= tokenEthDMWCPNonce[1]
    );
    uint couponAmount = safeDiv(safeMul(orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender],orderRecord[tokenUser[1]][orderHash].coupon),orderRecord[tokenUser[1]][orderHash].balance);
    if(orderRecord[msg.sender][orderHash].tokenDeposit) {
      uint amount = safeDiv(safeMul(orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender],orderRecord[tokenUser[1]][orderHash].shortBalance),orderRecord[tokenUser[1]][orderHash].balance);
      msg.sender.transfer(couponAmount);
      Token(tokenUser[0]).transfer(msg.sender,amount);
      orderRecord[tokenUser[1]][orderHash].coupon = safeSub(orderRecord[tokenUser[1]][orderHash].coupon,couponAmount);
      orderRecord[tokenUser[1]][orderHash].balance = safeSub(orderRecord[tokenUser[1]][orderHash].balance,orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender]);
      orderRecord[tokenUser[1]][orderHash].shortBalance = safeSub(orderRecord[tokenUser[1]][orderHash].shortBalance,amount);
      orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender] = uint(0);
      TokenLongExercised(tokenUser,tokenEthDMWCPNonce,amount,block.number);
    }
    else if(!orderRecord[msg.sender][orderHash].tokenDeposit){
      msg.sender.transfer(safeAdd(couponAmount,orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender]));
      orderRecord[tokenUser[1]][orderHash].coupon = safeSub(orderRecord[tokenUser[1]][orderHash].coupon,couponAmount);
      orderRecord[tokenUser[1]][orderHash].balance = safeSub(orderRecord[tokenUser[1]][orderHash].balance,orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender]);
      orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender] = uint(0); 
      EthLongExercised(tokenUser,tokenEthDMWCPNonce,block.number);
    }
  }

  function claimDonations(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint8 v,bytes32[2] rs) external onlyAdmin {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        tokenEthDMWCPNonce[0],
        tokenEthDMWCPNonce[1], 
        tokenEthDMWCPNonce[2],
        tokenEthDMWCPNonce[3],
        tokenEthDMWCPNonce[4],
        tokenEthDMWCPNonce[5], 
        tokenEthDMWCPNonce[6]
      );
    require(
      ecrecover(keccak256("\x19Ethereum Signed Message:\n32",orderHash),v,rs[0],rs[1]) == tokenUser[1] &&
      block.number > tokenEthDMWCPNonce[4]
    );
    admin.transfer(safeAdd(orderRecord[tokenUser[1]][orderHash].coupon,orderRecord[tokenUser[1]][orderHash].balance));
    Token(tokenUser[0]).transfer(admin,orderRecord[tokenUser[1]][orderHash].shortBalance);
    orderRecord[tokenUser[1]][orderHash].balance = uint(0);
    orderRecord[tokenUser[1]][orderHash].coupon = uint(0);
    orderRecord[tokenUser[1]][orderHash].shortBalance = uint(0);
    DonationClaimed(tokenUser,tokenEthDMWCPNonce,orderRecord[tokenUser[1]][orderHash].balance,block.number);
  }

  function nonActivationShortWithdrawal(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint8 v,bytes32[2] rs) external {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        tokenEthDMWCPNonce[0],
        tokenEthDMWCPNonce[1], 
        tokenEthDMWCPNonce[2],
        tokenEthDMWCPNonce[3],
        tokenEthDMWCPNonce[4],
        tokenEthDMWCPNonce[5], 
        tokenEthDMWCPNonce[6]
      );
    require(
      ecrecover(keccak256("\x19Ethereum Signed Message:\n32",orderHash),v,rs[0],rs[1]) == msg.sender &&
      block.number > tokenEthDMWCPNonce[2] &&
      orderRecord[tokenUser[1]][orderHash].balance < tokenEthDMWCPNonce[1]
    );
    msg.sender.transfer(orderRecord[msg.sender][orderHash].coupon);
    orderRecord[msg.sender][orderHash].coupon = uint(0);
    NonActivationWithdrawal(tokenUser,tokenEthDMWCPNonce,block.number);
  }

  function nonActivationWithdrawal(address[2] tokenUser,uint[8] tokenEthDMWCPNonce,uint8 v,bytes32[2] rs) external {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        tokenEthDMWCPNonce[0],
        tokenEthDMWCPNonce[1], 
        tokenEthDMWCPNonce[2],
        tokenEthDMWCPNonce[3],
        tokenEthDMWCPNonce[4],
        tokenEthDMWCPNonce[5], 
        tokenEthDMWCPNonce[6]
      );
    require(
      ecrecover(keccak256("\x19Ethereum Signed Message:\n32",orderHash),v,rs[0],rs[1]) == tokenUser[1] &&
      block.number > tokenEthDMWCPNonce[2] &&
      block.number <= tokenEthDMWCPNonce[4] &&
      orderRecord[tokenUser[1]][orderHash].balance < tokenEthDMWCPNonce[1]
    );
    msg.sender.transfer(orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender]);
    orderRecord[tokenUser[1]][orderHash].balance = safeSub(orderRecord[tokenUser[1]][orderHash].balance,orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender]);
    orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender] = uint(0);
    ActivationWithdrawal(tokenUser,tokenEthDMWCPNonce,orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender],block.number);
  }

  function returnBalance(address _creator,bytes32 orderHash) external constant returns (uint) {
    return orderRecord[_creator][orderHash].balance;
  }

  function returnTokenBalance(address _creator,bytes32 orderHash) external constant returns (uint) {
    return orderRecord[_creator][orderHash].shortBalance;
  }

  function returnUserBalance(address[2] creatorUser,bytes32 orderHash) external constant returns (uint) {
    return orderRecord[creatorUser[0]][orderHash].longBalance[creatorUser[1]];
  }

  function returnCoupon(address _creator,bytes32 orderHash) external constant returns (uint) {
    return orderRecord[_creator][orderHash].coupon;
  }

  function returnTokenDepositState(address _creator,bytes32 orderHash) external constant returns (bool) {
    return orderRecord[_creator][orderHash].tokenDeposit;
  }
 
  function returnHash(address[2] tokenUser,uint[8] tokenEthDMWCPNonce)  external pure returns (bytes32) {
    return  
      keccak256 (
        tokenUser[0],
        tokenUser[1],
        tokenEthDMWCPNonce[0],
        tokenEthDMWCPNonce[1], 
        tokenEthDMWCPNonce[2],
        tokenEthDMWCPNonce[3],
        tokenEthDMWCPNonce[4],
        tokenEthDMWCPNonce[5], 
        tokenEthDMWCPNonce[6]
      );
  }


  function returnAddress(bytes32 orderHash,uint8 v,bytes32[2] rs) external pure returns (address) {
    return ecrecover(orderHash,v,rs[0],rs[1]);
  }

  function returnHashLong(address seller,uint[3] amountNonceExpiry)  external pure returns (bytes32) {
    return keccak256(seller,amountNonceExpiry[0],amountNonceExpiry[1],amountNonceExpiry[2]);
  }

  function returnLongAddress(bytes32 orderHash,uint8 v,bytes32[2] rs) external pure returns (address) {
    return ecrecover(orderHash,v,rs[0],rs[1]);
  }

  function returnCoupon(address[3] tokenUserSender,bytes32 orderHash) external view returns (uint){
    return orderRecord[tokenUserSender[1]][orderHash].coupon;
  }

  function returnLongTokenAmount(address[3] tokenUserSender,bytes32 orderHash) external view returns (uint) {
    return orderRecord[tokenUserSender[1]][orderHash].shortBalance;
  }

}