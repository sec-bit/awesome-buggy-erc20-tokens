pragma solidity ^0.4.16;


contract FarmCoin {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);
  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  function mintToken(address to, uint256 value) returns (uint256);
  function changeTransfer(bool allowed);
}

 
contract FarmCoinSale {

    uint256 public maxMintable;
    uint256 public totalMinted;
    uint256 public decimals = 18;
    uint256 rate;
    uint public endBlock;
    uint public startBlock;
    uint public exchangeRate= rate;
    uint public startTime;
    bool public isFunding;
    FarmCoin public Token;
    address public ETHWallet;
    uint256 public heldTotal;

    bool private configSet;
    address public creator;

    mapping (address => uint256) public heldTokens;
    mapping (address => uint) public heldTimeline;

    event Contribution(address from, uint256 amount);
    event ReleaseTokens(address from, uint256 amount);


    function FarmCoinSale() {
        startBlock = block.number;
        maxMintable = 4000000000000000000000000; // 3 million max sellable (18 decimals)
        ETHWallet = 0x3b444fC8c2C45DCa5e6610E49dC54423c5Dcd86E;
        isFunding = true;
        creator = msg.sender;
        createHeldCoins();
        startTime = 1517461200000;
        exchangeRate= rate;
        }

 // start and end dates where crowdsale is allowed (both inclusive)
  uint256 constant public START = 1517461200000; // +new Date(2018, 2, 1) / 1000
  uint256 constant public END = 1522555200000; // +new Date(2018, 4, 1) / 1000

// @return the rate in FARM per 1 ETH according to the time of the tx and the FARM pricing program.
    // @Override
  function getRate() constant returns (uint256 rate) {
    if      (now < START)            return rate = 840; // presale, 40% bonus
    else if (now <= START +  6 days) return rate = 810; // day 1 to 6, 35% bonus
    else if (now <= START + 13 days) return rate = 780; // day 7 to 13, 30% bonus
    else if (now <= START + 20 days) return rate = 750; // day 14 to 20, 25% bonus
    else if (now <= START + 28 days) return rate = 720; // day 21 to 28, 20% bonus
    return rate = 600; // no bonus
  }

    // setup function to be ran only 1 time
    // setup token address
    // setup end Block number
    function setup(address TOKEN, uint endBlockTime) {
        require(!configSet);
        Token = FarmCoin(TOKEN);
        endBlock = endBlockTime;
        configSet = true;
    }

    function closeSale() external {
      require(msg.sender==creator);
      isFunding = false;
    }

    // CONTRIBUTE FUNCTION
    // converts ETH to TOKEN and sends new TOKEN to the sender
    function contribute() external payable {
        require(msg.value>0);
        require(isFunding);
        require(block.number <= endBlock);
        uint256 amount = msg.value * exchangeRate;
        uint256 total = totalMinted + amount;
        require(total<=maxMintable);
        totalMinted += total;
        ETHWallet.transfer(msg.value);
        Token.mintToken(msg.sender, amount);
        Contribution(msg.sender, amount);
    }

    // update the ETH/COIN rate
    function updateRate(uint256 rate) external {
        require(msg.sender==creator);
        require(isFunding);
        exchangeRate = rate;
    }

    // change creator address
    function changeCreator(address _creator) external {
        require(msg.sender==creator);
        creator = _creator;
    }

    // change transfer status for FarmCoin token
    function changeTransferStats(bool _allowed) external {
        require(msg.sender==creator);
        Token.changeTransfer(_allowed);
    }

    // internal function that allocates a specific amount of ATYX at a specific block number.
    // only ran 1 time on initialization
    function createHeldCoins() internal {
        // TOTAL SUPPLY = 5,000,000
        createHoldToken(msg.sender, 1000);
        createHoldToken(0xd9710D829fa7c36E025011b801664009E4e7c69D, 100000000000000000000000);
        createHoldToken(0xd9710D829fa7c36E025011b801664009E4e7c69D, 100000000000000000000000);
    }

    // function to create held tokens for developer
    function createHoldToken(address _to, uint256 amount) internal {
        heldTokens[_to] = amount;
        heldTimeline[_to] = block.number + 0;
        heldTotal += amount;
        totalMinted += heldTotal;
    }

    // function to release held tokens for developers
    function releaseHeldCoins() external {
        uint256 held = heldTokens[msg.sender];
        uint heldBlock = heldTimeline[msg.sender];
        require(!isFunding);
        require(held >= 0);
        require(block.number >= heldBlock);
        heldTokens[msg.sender] = 0;
        heldTimeline[msg.sender] = 0;
        Token.mintToken(msg.sender, held);
        ReleaseTokens(msg.sender, held);
    }


}