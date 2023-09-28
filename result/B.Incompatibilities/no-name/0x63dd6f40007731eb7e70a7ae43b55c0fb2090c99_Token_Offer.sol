/*
Thank you ConsenSys, this contract originated from:
https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts/Standard_Token.sol
Which is itself based on the Ethereum standardized contract APIs:
https://github.com/ethereum/wiki/wiki/Standardized_Contract_APIs
*/

/// @title Standard Token Contract.
contract TokenInterface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _amount) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success);
    function approve(address _spender, uint256 _amount) returns (bool success);
    function allowance(
        address _owner,
        address _spender
    ) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );
}


// compiled using https://ethereum.github.io/browser-solidity/#version=soljson-v0.3.2-2016-05-20-e3c5418.js&optimize=true
contract Token_Offer {
  address public tokenHolder;
  address public owner;
  TokenInterface public tokenContract;
  uint16 public price;  // price in ETH per 100000 tokens. Price 2250 means 2.25 ETH per 100 tokens
  uint public tokensPurchasedTotal;
  uint public ethCostTotal;

  event TokensPurchased(address buyer, uint16 price, uint tokensPurchased, uint ethCost, uint ethSent, uint ethReturned, uint tokenSupplyLeft);
  event Log(string msg, uint val);

  modifier onlyOwnerAllowed() {if (tx.origin != owner) throw; _}

  function Token_Offer(address _tokenContract, address _tokenHolder, uint16 _price)  {
    owner = tx.origin;
    tokenContract = TokenInterface(_tokenContract);
    tokenHolder = _tokenHolder;
    price = _price;
  }

  function tokenSupply() constant returns (uint tokens) {
    uint allowance = tokenContract.allowance(tokenHolder, address(this));
    uint balance = tokenContract.balanceOf(tokenHolder);
    if (allowance < balance) return allowance;
    else return balance;
  }

  function () {
    buyTokens(price);
  }

  function buyTokens() {
    buyTokens(price);
  }

  /// @notice DON'T BUY FROM EXCHANGE! Only buy from normal account in your full control (private key).
  /// @param _bidPrice Price in ETH per 100000 tokens. _bidPrice 2250 means 2.25 ETH per 100 tokens.
  function buyTokens(uint16 _bidPrice) {
    if (tx.origin != msg.sender) { // buyer should be able to handle TheDAO (vote, transfer, ...)
      if (!msg.sender.send(msg.value)) throw; // send ETH back to sender's contract
      Log("Please send from a normal account, not contract/multisig", 0);
      return;
    }
    if (price == 0) {
      if (!tx.origin.send(msg.value)) throw; // send ETH back
      Log("Contract disabled", 0);
      return;
    }
    if (_bidPrice < price) {
      if (!tx.origin.send(msg.value)) throw; // send ETH back
      Log("Bid too low, price is:", price);
      return;
    }
    if (msg.value == 0) {
      Log("No ether received", 0);
      return;
    }
    uint _tokenSupply = tokenSupply();
    if (_tokenSupply == 0) {
      if (!tx.origin.send(msg.value)) throw; // send ETH back
      Log("No tokens available, please try later", 0);
      return;
    }

    uint _tokensToPurchase = (msg.value * 1000) / price;

    if (_tokensToPurchase <= _tokenSupply) { // contract has enough tokens to complete order
      if (!tokenContract.transferFrom(tokenHolder, tx.origin, _tokensToPurchase)) // send tokens
        throw;
      tokensPurchasedTotal += _tokensToPurchase;
      ethCostTotal += msg.value;
      TokensPurchased(tx.origin, price, _tokensToPurchase, msg.value, msg.value, 0, _tokenSupply-_tokensToPurchase);

    } else { // contract low on tokens, partial order execution
      uint _supplyInEth = (_tokenSupply * price) / 1000;
      if (!tx.origin.send(msg.value-_supplyInEth)) // return extra eth
        throw;
      if (!tokenContract.transferFrom(tokenHolder, tx.origin, _tokenSupply)) // send tokens
        throw;
      tokensPurchasedTotal += _tokenSupply;
      ethCostTotal += _supplyInEth;
      TokensPurchased(tx.origin, price, _tokenSupply, _supplyInEth, msg.value, msg.value-_supplyInEth, 0);
    }
  }

  /* == functions below are for owner only == */
  function setPrice(uint16 _price) onlyOwnerAllowed {
    price = _price;
    Log("Price changed:", price); // watch the contract to see updates
  }
  function tokenSupplyChanged() onlyOwnerAllowed {
    Log("Supply changed, new supply:", tokenSupply()); // watch the contract to see updates
  }
  function setTokenHolder(address _tokenHolder) onlyOwnerAllowed {
    tokenHolder = _tokenHolder;
  }
  function setOwner(address _owner) onlyOwnerAllowed {
    owner = _owner;
  }
  function transferETH(address _to, uint _amount) onlyOwnerAllowed {
    if (_amount > address(this).balance) {
      _amount = address(this).balance;
    }
    _to.send(_amount);
  }
}