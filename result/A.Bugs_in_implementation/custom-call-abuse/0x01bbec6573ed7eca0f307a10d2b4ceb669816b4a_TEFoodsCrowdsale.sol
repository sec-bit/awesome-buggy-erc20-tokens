pragma solidity ^0.4.19;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

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


contract ERC827 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}


contract TEFoodsToken is Ownable, ERC20Interface {

  using SafeMath for uint;

  string public constant name = "TEFOOD FARM TO FORK FOOD TRACEABILITY SYSTEM LICENSE TOKEN";
  string public constant symbol = "TFOOD";
  uint8 public constant decimals = 18;
  uint constant _totalSupply = 1000000000 * 1 ether;
  uint public transferrableTime = 1521712800;
  uint _vestedSupply;
  uint _circulatingSupply;
  mapping (address => uint) balances;
  mapping (address => mapping(address => uint)) allowed;

  struct vestedBalance {
    address addr;
    uint balance;
  }
  mapping (uint => vestedBalance[]) vestingMap;



  function TEFoodsToken () public {
    owner = msg.sender;
    balances[0x00] = _totalSupply;
  }

  event VestedTokensReleased(address to, uint amount);

  function allocateTokens (address addr, uint amount) public onlyOwner returns (bool) {
    require (addr != 0x00);
    require (amount > 0);
    balances[0x00] = balances[0x00].sub(amount);
    balances[addr] = balances[addr].add(amount);
    _circulatingSupply = _circulatingSupply.add(amount);
    assert (_vestedSupply.add(_circulatingSupply).add(balances[0x00]) == _totalSupply);
    return true;
  }

  function allocateVestedTokens (address addr, uint amount, uint vestingPeriod) public onlyOwner returns (bool) {
    require (addr != 0x00);
    require (amount > 0);
    require (vestingPeriod > 0);
    balances[0x00] = balances[0x00].sub(amount);
    vestingMap[vestingPeriod].push( vestedBalance (addr,amount) );
    _vestedSupply = _vestedSupply.add(amount);
    assert (_vestedSupply.add(_circulatingSupply).add(balances[0x00]) == _totalSupply);
    return true;
  }

  function releaseVestedTokens (uint vestingPeriod) public {
    require (now >= transferrableTime.add(vestingPeriod));
    require (vestingMap[vestingPeriod].length > 0);
    require (vestingMap[vestingPeriod][0].balance > 0);
    var v = vestingMap[vestingPeriod];
    for (uint8 i = 0; i < v.length; i++) {
      balances[v[i].addr] = balances[v[i].addr].add(v[i].balance);
      _circulatingSupply = _circulatingSupply.add(v[i].balance);
      _vestedSupply = _vestedSupply.sub(v[i].balance);
      v[i].balance = 0;
      VestedTokensReleased(v[i].addr, v[i].balance);
    }
  }

  function enableTransfers () public onlyOwner returns (bool) {
    if (now.add(86400) < transferrableTime) {
      transferrableTime = now.add(86400);
    }
    owner = 0x00;
    return true;
  }

  function () public payable {
    revert();
  }

  function totalSupply() public constant returns (uint) {
    return _circulatingSupply;
  }

  function balanceOf(address tokenOwner) public constant returns (uint balance) {
    return balances[tokenOwner];
  }

  function vestedBalanceOf(address tokenOwner, uint vestingPeriod) public constant returns (uint balance) {
    var v = vestingMap[vestingPeriod];
    for (uint8 i = 0; i < v.length; i++) {
      if (v[i].addr == tokenOwner) return v[i].balance;
    }
    return 0;
  }

  function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }

  function transfer(address to, uint tokens) public returns (bool success) {
    require (now >= transferrableTime);
    require (to != address(this));
    require (balances[msg.sender] >= tokens);
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint tokens) public returns (bool success) {
    require (spender != address(this));
    allowed[msg.sender][spender] = tokens;
    Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    require (now >= transferrableTime);
    require (to != address(this));
    require (allowed[from][msg.sender] >= tokens);
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    Transfer(from, to, tokens);
    return true;
  }

}

contract TEFoods827Token is TEFoodsToken, ERC827 {

  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    super.approve(_spender, _value);
    require(_spender.call(_data));
    return true;
  }

  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    super.transfer(_to, _value);
    require(_to.call(_data));
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    super.transferFrom(_from, _to, _value);
    require(_to.call(_data));
    return true;
  }

}


contract TEFoodsCrowdsale is Ownable {

  using SafeMath for uint;

  TEFoods827Token public tokenContract;

  uint public constant crowdsaleStartTime = 1519293600;
  uint public constant crowdsaleUncappedTime = 1519336800;
  uint public constant crowdsaleClosedTime = 1521712800;
  uint public maxGasPriceInWei = 50000000000;
  uint public constant contributionCapInWei = 1000000000000000000;
  address public constant teFoodsAddress = 0x27Ca683EdeAB8D03c6B5d7818f78Ba27a2025159;

  uint public constant tokenRateInUsdCents = 5;
  uint public constant ethRateInUsdCents = 92500;
  uint public constant amountToRaiseInUsdCents = 1910000000;
  uint public constant minContributionInUsdCents = 10000;

  uint[4] public tokenBonusTimes = [1519898400,1520503200,1521108000,1521712800];
  uint[4] public tokenBonusPct = [15,12,10,5];

  uint public whitelistedAddressCount;
  uint public contributorCount;
  bool public crowdsaleFinished;
  uint public amountRaisedInUsdCents;

  uint public constant totalTokenSupply = 1000000000 * 1 ether;
  uint public tokensAllocated;

  uint public constant marketingTokenAllocation = 60000000 * 1 ether;
  uint public marketingTokensDistributed;

  mapping (address => bool) presaleAllocated;
  mapping (address => bool) marketingAllocated;

  struct Contributor {
    bool authorised;
    bool contributed;
  }
  mapping (address => Contributor) whitelist;


  event PresaleAllocation(address to, uint usdAmount, uint tokenAmount);
  event MarketingAllocation(address to, uint tokenAmount);
  event CrowdsaleClosed(uint usdRaisedInCents);
  event TokensTransferrable();

  function TEFoodsCrowdsale () public {
    require (teFoodsAddress != 0x00);
    tokenContract = new TEFoods827Token();
  }

  function allocatePresaleTokens (address recipient, uint amountInUsdCents, uint bonusPct, uint vestingPeriodInSeconds) public onlyOwner  {
    require (now < crowdsaleStartTime);
    require (!presaleAllocated[recipient]);
    uint tokenAmount = amountInUsdCents.mul(1 ether).div(tokenRateInUsdCents);
    uint bonusAmount = tokenAmount.mul(bonusPct).div(100);

    if (vestingPeriodInSeconds > 0) {
      require (tokenContract.allocateTokens(recipient, tokenAmount));
      require (tokenContract.allocateVestedTokens(recipient, bonusAmount, vestingPeriodInSeconds));
    } else {
      require (tokenContract.allocateTokens(recipient, tokenAmount.add(bonusAmount)));
    }
    amountRaisedInUsdCents = amountRaisedInUsdCents.add(amountInUsdCents);
    tokensAllocated = tokensAllocated.add(tokenAmount).add(bonusAmount);
    presaleAllocated[recipient] = true;
    PresaleAllocation(recipient, amountInUsdCents, tokenAmount.add(bonusAmount));
  }

  function allocateMarketingTokens (address recipient, uint tokenAmount) public onlyOwner {
    require (!marketingAllocated[recipient]);
    require (marketingTokensDistributed.add(tokenAmount) <= marketingTokenAllocation);
    marketingTokensDistributed = marketingTokensDistributed.add(tokenAmount);
    tokensAllocated = tokensAllocated.add(tokenAmount);
    require (tokenContract.allocateTokens(recipient, tokenAmount));
    marketingAllocated[recipient] = true;
    MarketingAllocation(recipient, tokenAmount);
  }

  function whitelistUsers (address[] addressList) public onlyOwner {
    require (now < crowdsaleStartTime);
    for (uint8 i = 0; i < addressList.length; i++) {
      require (!whitelist[i].authorised);
      whitelist[addressList[i]].authorised = true;
    }
    whitelistedAddressCount = whitelistedAddressCount.add(addressList.length);
  }

  function revokeUsers (address[] addressList) public onlyOwner {
    require (now < crowdsaleStartTime);
    for (uint8 i = 0; i < addressList.length; i++) {
      require (whitelist[i].authorised);
      whitelist[addressList[i]].authorised = false;
    }
    whitelistedAddressCount = whitelistedAddressCount.sub(addressList.length);
  }

  function setMaxGasPrice (uint newMaxInWei) public onlyOwner {
    require(newMaxInWei >= 1000000000);
    maxGasPriceInWei = newMaxInWei;
  }

  function checkWhitelisted (address addr) public view returns (bool) {
    return whitelist[addr].authorised;
  }

  function isOpen () public view returns (bool) {
    return (now >= crowdsaleStartTime && !crowdsaleFinished && now < crowdsaleClosedTime);
  }


  function getRemainingEthAvailable () public view returns (uint) {
    if (crowdsaleFinished || now > crowdsaleClosedTime) return 0;
    return amountToRaiseInUsdCents.sub(amountRaisedInUsdCents).mul(1 ether).div(ethRateInUsdCents);
  }

  function _applyBonus (uint amount) internal view returns (uint) {
    for (uint8 i = 0; i < 3; i++) {
      if (tokenBonusTimes[i] > now) {
        return amount.add(amount.mul(tokenBonusPct[i]).div(100));
      }
    }
    return amount.add(amount.mul(tokenBonusPct[3]).div(100));
  }

  function _allocateTokens(address addr, uint amount) internal {
    require (tokensAllocated.add(amount) <= totalTokenSupply);
    tokensAllocated = tokensAllocated.add(amount);
    teFoodsAddress.transfer(this.balance);
    if (!whitelist[addr].contributed) {
      whitelist[addr].contributed = true;
      contributorCount = contributorCount.add(1);
    }
    require(tokenContract.allocateTokens(addr, amount));
  }

  function () public payable {
    require (tx.gasprice <= maxGasPriceInWei);
    require (msg.value > 0);
    require (now >= crowdsaleStartTime && now <= crowdsaleClosedTime);
    require (whitelist[msg.sender].authorised);
    require (!crowdsaleFinished);
    if (now < crowdsaleUncappedTime) {
      require (!whitelist[msg.sender].contributed);
      require (msg.value <= contributionCapInWei);
    }
    uint usdAmount = msg.value.mul(ethRateInUsdCents).div(1 ether);
    require (usdAmount >= minContributionInUsdCents);
    uint tokenAmount = _applyBonus(msg.value.mul(ethRateInUsdCents).div(tokenRateInUsdCents));
    amountRaisedInUsdCents = amountRaisedInUsdCents.add(usdAmount);
    if (amountRaisedInUsdCents >= amountToRaiseInUsdCents) {
      closeCrowdsale();
    } else {
      _allocateTokens(msg.sender, tokenAmount);
    }
  }

  function closeCrowdsale () public {
    require (!crowdsaleFinished);
    require (now >= crowdsaleStartTime);
    require (msg.sender == owner || amountRaisedInUsdCents >= amountToRaiseInUsdCents);
    crowdsaleFinished = true;

    if (msg.value > 0 && amountRaisedInUsdCents >= amountToRaiseInUsdCents) {

      uint excessEth = amountRaisedInUsdCents.sub(amountToRaiseInUsdCents).mul(1 ether).div(ethRateInUsdCents);
      uint tokenAmount = _applyBonus(msg.value.sub(excessEth).mul(ethRateInUsdCents).div(tokenRateInUsdCents));
      amountRaisedInUsdCents = amountToRaiseInUsdCents;
      msg.sender.transfer(excessEth);
      _allocateTokens(msg.sender, tokenAmount);
    } else if ( amountRaisedInUsdCents < amountToRaiseInUsdCents) {
      tokenAmount = amountToRaiseInUsdCents.sub(amountRaisedInUsdCents).mul(1 ether).div(tokenRateInUsdCents);
      tokensAllocated = tokensAllocated.add(tokenAmount); // burn
    }
    CrowdsaleClosed(amountRaisedInUsdCents);
  }

  function enableTokenTransfers () public onlyOwner {
    require (crowdsaleFinished);
    require (marketingTokensDistributed == marketingTokenAllocation);
    uint remainingTokens = totalTokenSupply.sub(tokensAllocated);
    uint oneYear = remainingTokens.mul(25).div(100);
    uint twoYears = remainingTokens.sub(oneYear);
    tokensAllocated = tokensAllocated.add(remainingTokens);
    require (tokenContract.allocateVestedTokens(teFoodsAddress, oneYear, 31536000));
    require (tokenContract.allocateVestedTokens(teFoodsAddress, twoYears, 63072000));
    require (tokenContract.enableTransfers());
    TokensTransferrable();
  }

}