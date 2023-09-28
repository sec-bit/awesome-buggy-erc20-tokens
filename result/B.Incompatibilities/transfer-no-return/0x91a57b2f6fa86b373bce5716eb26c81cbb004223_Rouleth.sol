pragma solidity ^0.4.8;

contract OwnedByWinsome {

  address public owner;
  mapping (address => bool) allowedWorker;

  function initOwnership(address _owner, address _worker) internal{
    owner = _owner;
    allowedWorker[_owner] = true;
    allowedWorker[_worker] = true;
  }

  function allowWorker(address _new_worker) onlyOwner{
    allowedWorker[_new_worker] = true;
  }
  function removeWorker(address _old_worker) onlyOwner{
    allowedWorker[_old_worker] = false;
  }
  function changeOwner(address _new_owner) onlyOwner{
    owner = _new_owner;
  }
						    
  modifier onlyAllowedWorker{
    if (!allowedWorker[msg.sender]){
      throw;
    }
    _;
  }

  modifier onlyOwner{
    if (msg.sender != owner){
      throw;
    }
    _;
  }

  
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


/*
 * Basic token
 * Basic version of StandardToken, with no allowances
 */
contract BasicToken {
  using SafeMath for uint;
  event Transfer(address indexed from, address indexed to, uint value);
  mapping(address => uint) balances;
  uint public     totalSupply =    0;    			 // Total supply of 500 million Tokens
  
  /*
   * Fix for the ERC20 short address attack  
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
}


contract StandardToken is BasicToken{
  
  event Approval(address indexed owner, address indexed spender, uint value);

  
  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


contract WinToken is StandardToken, OwnedByWinsome{

  string public   name =           "Winsome.io Token";
  string public   symbol =         "WIN";
  uint public     decimals =       18;
  
  mapping (address => bool) allowedMinter;

  function WinToken(address _owner){
    allowedMinter[_owner] = true;
    initOwnership(_owner, _owner);
  }

  function allowMinter(address _new_minter) onlyOwner{
    allowedMinter[_new_minter] = true;
  }
  function removeMinter(address _old_minter) onlyOwner{
    allowedMinter[_old_minter] = false;
  }

  modifier onlyAllowedMinter{
    if (!allowedMinter[msg.sender]){
      throw;
    }
    _;
  }
  function mintTokens(address _for, uint _value_wei) onlyAllowedMinter {
    balances[_for] = balances[_for].add(_value_wei);
    totalSupply = totalSupply.add(_value_wei) ;
    Transfer(address(0), _for, _value_wei);
  }
  function destroyTokens(address _for, uint _value_wei) onlyAllowedMinter {
    balances[_for] = balances[_for].sub(_value_wei);
    totalSupply = totalSupply.sub(_value_wei);
    Transfer(_for, address(0), _value_wei);    
  }
  
}

contract Rouleth
{
  //Game and Global Variables, Structure of gambles
  address public developer;
  uint8 public blockDelay; //nb of blocks to wait before spin
  uint8 public blockExpiration; //nb of blocks before bet expiration (due to hash storage limits)
  uint256 public maxGamble; //max gamble value manually set by config
  uint256 public minGamble; //min gamble value manually set by config

  mapping (address => uint) pendingTokens;
  
  address public WINTOKENADDRESS;
  WinToken winTokenInstance;

  uint public emissionRate;
  
  //Gambles
  enum BetTypes{number, color, parity, dozen, column, lowhigh} 
  struct Gamble
  {
    address player;
    bool spinned; //Was the rouleth spinned ?
    bool win;
    //Possible bet types
    BetTypes betType;
    uint input; //stores number, color, dozen or oddeven
    uint256 wager;
    uint256 blockNumber; //block of bet
    uint256 blockSpinned; //block of spin
    uint8 wheelResult;
  }
  Gamble[] private gambles;

  //Tracking progress of players
  mapping (address=>uint) gambleIndex; //current gamble index of the player
  //records current status of player
  enum Status {waitingForBet, waitingForSpin} mapping (address=>Status) playerStatus; 


  //**********************************************
  //        Management & Config FUNCTIONS        //
  //**********************************************

  function  Rouleth(address _developer, address _winToken) //creation settings
  {
    WINTOKENADDRESS = _winToken;
    winTokenInstance = WinToken(_winToken);
    developer = _developer;
    blockDelay=0; //indicates which block after bet will be used for RNG
    blockExpiration=245; //delay after which gamble expires
    minGamble=10 finney; //configurable min bet
    maxGamble=1 ether; //configurable max bet
    emissionRate = 5;
  }
    
  modifier onlyDeveloper() 
  {
    if (msg.sender!=developer) throw;
    _;
  }

  function addBankroll()
    onlyDeveloper
    payable {
  }

  function removeBankroll(uint256 _amount_wei)
    onlyDeveloper
  {
    if (!developer.send(_amount_wei)) throw;
  }
    
  function changeDeveloper_only_Dev(address new_dev)
    onlyDeveloper
  {
    developer=new_dev;
  }





  //Change some settings within safety bounds
  function changeSettings_only_Dev(uint256 newMinGamble, uint256 newMaxGamble, uint8 newBlockDelay, uint8 newBlockExpiration, uint newEmissionRate)
    onlyDeveloper
  {
    emissionRate = newEmissionRate;
    //MAX BET : limited by payroll/(casinoStatisticalLimit*35)
    if (newMaxGamble<newMinGamble) throw;  
    maxGamble=newMaxGamble; 
    minGamble=newMinGamble;
    //Delay before spin :
    blockDelay=newBlockDelay;
    if (newBlockExpiration < blockDelay + 250) throw;
    blockExpiration=newBlockExpiration;
  }


  //**********************************************
  //                 BETTING FUNCTIONS                    //
  //**********************************************

  //***//basic betting without Mist or contract call
  //activates when the player only sends eth to the contract
  //without specifying any type of bet.
  function ()
    payable
    {
      //defaut bet : bet on red
      betOnColor(false);
    } 

  //***//Guarantees that gamble is under max bet and above min.
  // returns bet value
  function checkBetValue() private returns(uint256)
  {
    if (msg.value < minGamble) throw;
    if (msg.value > maxGamble){
      return maxGamble;
    }
    else{
      return msg.value;
    }
  }



  //Function record bet called by all others betting functions
  function placeBet(BetTypes betType, uint input) private
  {

    if (playerStatus[msg.sender] != Status.waitingForBet) {
      if (!SpinTheWheel(msg.sender)) throw;
    }

    //Once this is done, we can record the new bet
    playerStatus[msg.sender] = Status.waitingForSpin;
    gambleIndex[msg.sender] = gambles.length;
    
    //adapts wager to casino limits
    uint256 betValue = checkBetValue();
    pendingTokens[msg.sender] += betValue * emissionRate;

    
    gambles.push(Gamble(msg.sender, false, false, betType, input, betValue, block.number, 0, 37)); //37 indicates not spinned yet
    
    //refund excess bet (at last step vs re-entry)
    if (betValue < msg.value) {
      if (msg.sender.send(msg.value-betValue)==false) throw;
    }
  }

  function getPendingTokens(address account) constant returns (uint){
    return pendingTokens[account];
  }
  
  function redeemTokens(){
    uint totalTokens = pendingTokens[msg.sender];
    if (totalTokens == 0) return;
    pendingTokens[msg.sender] = 0;

    //ADD POTENTIAL BONUS BASED ON How long waited!
    
    //mint WIN Tokens
    winTokenInstance.mintTokens(msg.sender, totalTokens);
  }

  

  //***//bet on Number	
  function betOnNumber(uint numberChosen)
    payable
  {
    //check that number chosen is valid and records bet
    if (numberChosen>36) throw;
    placeBet(BetTypes.number, numberChosen);
  }

  //***// function betOnColor
  //bet type : color
  //input : 0 for red
  //input : 1 for black
  function betOnColor(bool Black)
    payable
  {
    uint input;
    if (!Black) 
      { 
	input=0;
      }
    else{
      input=1;
    }
    placeBet(BetTypes.color, input);
  }

  //***// function betOnLow_High
  //bet type : lowhigh
  //input : 0 for low
  //input : 1 for low
  function betOnLowHigh(bool High)
    payable
  {
    uint input;
    if (!High) 
      { 
	input=0;
      }
    else 
      {
	input=1;
      }
    placeBet(BetTypes.lowhigh, input);
  }

  //***// function betOnOddEven
  //bet type : parity
  //input : 0 for even
  //input : 1 for odd
  function betOnOddEven(bool Odd)
    payable
  {
    uint input;
    if (!Odd) 
      { 
	input=0;
      }
    else{
      input=1;
    }
    placeBet(BetTypes.parity, input);
  }

  //***// function betOnDozen
  //     //bet type : dozen
  //     //input : 0 for first dozen
  //     //input : 1 for second dozen
  //     //input : 2 for third dozen
  function betOnDozen(uint dozen_selected_0_1_2)
    payable

  {
    if (dozen_selected_0_1_2 > 2) throw;
    placeBet(BetTypes.dozen, dozen_selected_0_1_2);
  }


  // //***// function betOnColumn
  //     //bet type : column
  //     //input : 0 for first column
  //     //input : 1 for second column
  //     //input : 2 for third column
  function betOnColumn(uint column_selected_0_1_2)
    payable
  {
    if (column_selected_0_1_2 > 2) throw;
    placeBet(BetTypes.column, column_selected_0_1_2);
  }

  //**********************************************
  // Spin The Wheel & Check Result FUNCTIONS//
  //**********************************************

  event Win(address player, uint8 result, uint value_won, bytes32 bHash, bytes32 sha3Player, uint gambleId, uint bet);
  event Loss(address player, uint8 result, uint value_loss, bytes32 bHash, bytes32 sha3Player, uint gambleId, uint bet);

  //***//function to spin callable
  // no eth allowed
  function spinTheWheel(address spin_for_player)
  {
    SpinTheWheel(spin_for_player);
  }


  function SpinTheWheel(address playerSpinned) private returns(bool)
  {
    if (playerSpinned==0)
      {
	playerSpinned=msg.sender;         //if no index spins for the sender
      }

    //check that player has to spin
    if (playerStatus[playerSpinned] != Status.waitingForSpin) return false;

    //redundent double check : check that gamble has not been spinned already
    if (gambles[gambleIndex[playerSpinned]].spinned == true) throw;

    
    //check that the player waited for the delay before spin
    //and also that the bet is not expired
    uint playerblock = gambles[gambleIndex[playerSpinned]].blockNumber;
    //too early to spin
    if (block.number <= playerblock+blockDelay) throw;
    //too late, bet expired, player lost
    else if (block.number > playerblock+blockExpiration) solveBet(playerSpinned, 255, false, 1, 0, 0) ;
    //spin !
    else
      {
	uint8 wheelResult;
	//Spin the wheel, 
	bytes32 blockHash= block.blockhash(playerblock+blockDelay);
	//security check that the Hash is not empty
	if (blockHash==0) throw;
	// generate the hash for RNG from the blockHash and the player's address
	bytes32 shaPlayer = sha3(playerSpinned, blockHash, this);
	// get the final wheel result
	wheelResult = uint8(uint256(shaPlayer)%37);
	//check result against bet and pay if win
	checkBetResult(wheelResult, playerSpinned, blockHash, shaPlayer);
      }
    return true;
  }
    

  //CHECK BETS FUNCTIONS private
  function checkBetResult(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  {
    BetTypes betType=gambles[gambleIndex[player]].betType;
    //bet on Number
    if (betType==BetTypes.number) checkBetNumber(result, player, blockHash, shaPlayer);
    else if (betType==BetTypes.parity) checkBetParity(result, player, blockHash, shaPlayer);
    else if (betType==BetTypes.color) checkBetColor(result, player, blockHash, shaPlayer);
    else if (betType==BetTypes.lowhigh) checkBetLowhigh(result, player, blockHash, shaPlayer);
    else if (betType==BetTypes.dozen) checkBetDozen(result, player, blockHash, shaPlayer);
    else if (betType==BetTypes.column) checkBetColumn(result, player, blockHash, shaPlayer);
  }

  // function solve Bet once result is determined : sends to winner, adds loss to profit
  function solveBet(address player, uint8 result, bool win, uint8 multiplier, bytes32 blockHash, bytes32 shaPlayer) private
  {
    //Update status and record spinned
    playerStatus[player]=Status.waitingForBet;
    gambles[gambleIndex[player]].wheelResult=result;
    gambles[gambleIndex[player]].spinned=true;
    gambles[gambleIndex[player]].blockSpinned=block.number;
    uint bet_v = gambles[gambleIndex[player]].wager;
	
    if (win)
      {
	gambles[gambleIndex[player]].win=true;
	uint win_v = (multiplier-1)*bet_v;
	Win(player, result, win_v, blockHash, shaPlayer, gambleIndex[player], bet_v);
	//send win!
	//safe send vs potential callstack overflowed spins
	if (player.send(win_v+bet_v)==false) throw;
      }
    else
      {
	Loss(player, result, bet_v-1, blockHash, shaPlayer, gambleIndex[player], bet_v);
	//send 1 wei to confirm spin if loss
	if (player.send(1)==false) throw;
      }

  }

  // checkbeton number(input)
  // bet type : number
  // input : chosen number
  function checkBetNumber(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  {
    bool win;
    //win
    if (result==gambles[gambleIndex[player]].input)
      {
	win=true;  
      }
    solveBet(player, result,win,36, blockHash, shaPlayer);
  }


  // checkbet on oddeven
  // bet type : parity
  // input : 0 for even, 1 for odd
  function checkBetParity(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  {
    bool win;
    //win
    if (result%2==gambles[gambleIndex[player]].input && result!=0)
      {
	win=true;                
      }
    solveBet(player,result,win,2, blockHash, shaPlayer);
  }
    
  // checkbet on lowhigh
  // bet type : lowhigh
  // input : 0 low, 1 high
  function checkBetLowhigh(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  {
    bool win;
    //win
    if (result!=0 && ( (result<19 && gambles[gambleIndex[player]].input==0)
		       || (result>18 && gambles[gambleIndex[player]].input==1)
		       ) )
      {
	win=true;
      }
    solveBet(player,result,win,2, blockHash, shaPlayer);
  }

  // checkbet on color
  // bet type : color
  // input : 0 red, 1 black
  uint[18] red_list=[1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36];
  function checkBetColor(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  {
    bool red;
    //check if red
    for (uint8 k; k<18; k++)
      { 
	if (red_list[k]==result) 
	  { 
	    red=true; 
	    break;
	  }
      }
    bool win;
    //win
    if ( result!=0
	 && ( (gambles[gambleIndex[player]].input==0 && red)  
	      || ( gambles[gambleIndex[player]].input==1 && !red)  ) )
      {
	win=true;
      }
    solveBet(player,result,win,2, blockHash, shaPlayer);
  }

  // checkbet on dozen
  // bet type : dozen
  // input : 0 first, 1 second, 2 third
  function checkBetDozen(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  { 
    bool win;
    //win on first dozen
    if ( result!=0 &&
	 ( (result<13 && gambles[gambleIndex[player]].input==0)
	   ||
	   (result>12 && result<25 && gambles[gambleIndex[player]].input==1)
	   ||
	   (result>24 && gambles[gambleIndex[player]].input==2) ) )
      {
	win=true;                
      }
    solveBet(player,result,win,3, blockHash, shaPlayer);
  }

  // checkbet on column
  // bet type : column
  // input : 0 first, 1 second, 2 third
  function checkBetColumn(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  {
    bool win;
    //win
    if ( result!=0
	 && ( (gambles[gambleIndex[player]].input==0 && result%3==1)  
	      || ( gambles[gambleIndex[player]].input==1 && result%3==2)
	      || ( gambles[gambleIndex[player]].input==2 && result%3==0)  ) )
      {
	win=true;
      }
    solveBet(player,result,win,3, blockHash, shaPlayer);
  }


  function checkMyBet(address player) constant returns(Status player_status, BetTypes bettype, uint input, uint value, uint8 result, bool wheelspinned, bool win, uint blockNb, uint blockSpin, uint gambleID)
  {
    player_status=playerStatus[player];
    bettype=gambles[gambleIndex[player]].betType;
    input=gambles[gambleIndex[player]].input;
    value=gambles[gambleIndex[player]].wager;
    result=gambles[gambleIndex[player]].wheelResult;
    wheelspinned=gambles[gambleIndex[player]].spinned;
    win=gambles[gambleIndex[player]].win;
    blockNb=gambles[gambleIndex[player]].blockNumber;
    blockSpin=gambles[gambleIndex[player]].blockSpinned;
    gambleID=gambleIndex[player];
    return;
  }

  function getTotalGambles() constant returns(uint){
    return gambles.length;
  }

  
  function getGamblesList(uint256 index) constant returns(address player, BetTypes bettype, uint input, uint value, uint8 result, bool wheelspinned, bool win, uint blockNb, uint blockSpin)
  {
    player=gambles[index].player;
    bettype=gambles[index].betType;
    input=gambles[index].input;
    value=gambles[index].wager;
    result=gambles[index].wheelResult;
    wheelspinned=gambles[index].spinned;
    win=gambles[index].win;
    blockNb=gambles[index].blockNumber;
    blockSpin=gambles[index].blockSpinned;
    return;
  }

} //end of contract