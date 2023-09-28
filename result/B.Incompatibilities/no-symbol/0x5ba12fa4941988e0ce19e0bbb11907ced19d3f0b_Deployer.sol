pragma solidity ^0.4.17;

//Slightly modified SafeMath library - includes a min function
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

//ERC20 function interface
interface ERC20_Interface {
  function totalSupply() public constant returns (uint total_supply);
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _amount) public returns (bool success);
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success);
  function approve(address _spender, uint _amount) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint amount);
}

//Swap factory functions - descriptions can be found in Factory.sol
interface Factory_Interface {
  function createToken(uint _supply, address _party, bool _long, uint _start_date) public returns (address created, uint token_ratio);
  function payToken(address _party, address _token_add) public;
  function deployContract(uint _start_date) public payable returns (address created);
   function getBase() public view returns(address _base1, address base2);
  function getVariables() public view returns (address oracle_addr, uint swap_duration, uint swap_multiplier, address token_a_addr, address token_b_addr);
}


//DRCT_Token functions - descriptions can be found in DRCT_Token.sol
interface DRCT_Token_Interface {
  function addressCount(address _swap) public constant returns (uint count);
  function getHolderByIndex(uint _ind, address _swap) public constant returns (address holder);
  function getBalanceByIndex(uint _ind, address _swap) public constant returns (uint bal);
  function getIndexByAddress(address _owner, address _swap) public constant returns (uint index);
  function createToken(uint _supply, address _owner, address _swap) public;
  function pay(address _party, address _swap) public;
  function partyCount(address _swap) public constant returns(uint count);
}


//Swap Oracle functions - descriptions can be found in Oracle.sol
interface Oracle_Interface{
  function RetrieveData(uint _date) public view returns (uint data);
}


//This contract is the specific DRCT base contract that holds the funds of the contract and redistributes them based upon the change in the underlying values
contract TokenToTokenSwap {

  using SafeMath for uint256;

  /*Enums*/
  //Describes various states of the Swap
  enum SwapState {
    created,
    open,
    started,
    tokenized,
    ready,
    ended
  }

  /*Variables*/

  //Address of the person who created this contract through the Factory
  address creator;
  //The Oracle address (check for list at www.github.com/DecentralizedDerivatives/Oracles)
  address oracle_address;
  Oracle_Interface oracle;

  //Address of the Factory that created this contract
  address public factory_address;
  Factory_Interface factory;

  //Addresses of parties going short and long the rate
  address public long_party;
  address public short_party;

  //Enum state of the swap
  SwapState public current_state;

  //Start and end dates of the swaps - format is the same as block.timestamp
  uint start_date;
  uint end_date;

  //This is the amount that the change will be calculated on.  10% change in rate on 100 Ether notional is a 10 Ether change
  uint multiplier;

  //This is the calculated share for the long and short side of the swap (200,000 is a fully capped move)
  uint share_long;
  uint share_short;

  // pay_to_x refers to the amount of the base token (a or b) to pay to the long or short side based upon the share_long and share_short
  uint pay_to_short_a;
  uint pay_to_long_a;
  uint pay_to_long_b;
  uint pay_to_short_b;

  //Address of created long and short DRCT tokens
  address long_token_address;
  address short_token_address;

  //Number of DRCT Tokens distributed to both parties
  uint num_DRCT_longtokens;
  uint num_DRCT_shorttokens;

  //Addresses of ERC20 tokens used to enter the swap
  address token_a_address;
  address token_b_address;

  //Tokens A and B used for the notional
  ERC20_Interface token_a;
  ERC20_Interface token_b;

  //The notional that the payment is calculated on from the change in the reference rate
  uint public token_a_amount;
  uint public token_b_amount;

  uint public premium;

  //Addresses of the two parties taking part in the swap
  address token_a_party;
  address token_b_party;

  //Duration of the swap,pulled from the Factory contract
  uint duration;
  //Date by which the contract must be funded
  uint enterDate;
  DRCT_Token_Interface token;
  address userContract;

  /*Events*/

  //Emitted when a Swap is created
  event SwapCreation(address _token_a, address _token_b, uint _start_date, uint _end_date, address _creating_party);
  //Emitted when the swap has been paid out
  event PaidOut(address _long_token, address _short_token);

  /*Modifiers*/

  //Will proceed only if the contract is in the expected state
  modifier onlyState(SwapState expected_state) {
    require(expected_state == current_state);
    _;
  }

  /*Functions*/

  /*
  * Constructor - Run by the factory at contract creation
  *
  * @param "_factory_address": Address of the factory that created this contract
  * @param "_creator": Address of the person who created the contract
  * @param "_userContract": Address of the _userContract that is authorized to interact with this contract
  */
  function TokenToTokenSwap (address _factory_address, address _creator, address _userContract, uint _start_date) public {
    current_state = SwapState.created;
    creator =_creator;
    factory_address = _factory_address;
    userContract = _userContract;
    start_date = _start_date;
  }


  //A getter function for retriving standardized variables from the factory contract
  function showPrivateVars() public view returns (address _userContract, uint num_DRCT_long, uint numb_DRCT_short, uint swap_share_long, uint swap_share_short, address long_token_addr, address short_token_addr, address oracle_addr, address token_a_addr, address token_b_addr, uint swap_multiplier, uint swap_duration, uint swap_start_date, uint swap_end_date){
    return (userContract, num_DRCT_longtokens, num_DRCT_shorttokens,share_long,share_short,long_token_address,short_token_address, oracle_address, token_a_address, token_b_address, multiplier, duration, start_date, end_date);
  }

  /*
  * Allows the sender to create the terms for the swap
  * @param "_amount_a": Amount of Token A that should be deposited for the notional
  * @param "_amount_b": Amount of Token B that should be deposited for the notional
  * @param "_sender_is_long": Denotes whether the sender is set as the short or long party
  * @param "_senderAdd": States the owner of this side of the contract (does not have to be msg.sender)
  */
  function CreateSwap(
    uint _amount_a,
    uint _amount_b,
    bool _sender_is_long,
    address _senderAdd
    ) payable public onlyState(SwapState.created) {

    require(
      msg.sender == creator || (msg.sender == userContract && _senderAdd == creator)
    );
    factory = Factory_Interface(factory_address);
    setVars();
    end_date = start_date.add(duration.mul(86400));
    token_a_amount = _amount_a;
    token_b_amount = _amount_b;

    premium = this.balance;
    token_a = ERC20_Interface(token_a_address);
    token_a_party = _senderAdd;
    if (_sender_is_long)
      long_party = _senderAdd;
    else
      short_party = _senderAdd;
    current_state = SwapState.open;
  }

  function setVars() internal{
      (oracle_address,duration,multiplier,token_a_address,token_b_address) = factory.getVariables();
  }

  /*
  * This function is for those entering the swap. The details of the swap are re-entered and checked
  * to ensure the entering party is entering the correct swap. Note that the tokens you are entering with
  * do not need to be entered as a variable, but you should ensure that the contract is funded.
  *
  * @param: all parameters have the same functions as those in the CreateSwap function
  */
  function EnterSwap(
    uint _amount_a,
    uint _amount_b,
    bool _sender_is_long,
    address _senderAdd
    ) public onlyState(SwapState.open) {

    //Require that all of the information of the swap was entered correctly by the entering party.  Prevents partyA from exiting and changing details
    require(
      token_a_amount == _amount_a &&
      token_b_amount == _amount_b &&
      token_a_party != _senderAdd
    );

    token_b = ERC20_Interface(token_b_address);
    token_b_party = _senderAdd;

    //Set the entering party as the short or long party
    if (_sender_is_long) {
      require(long_party == 0);
      long_party = _senderAdd;
    } else {
      require(short_party == 0);
      short_party = _senderAdd;
    }

    SwapCreation(token_a_address, token_b_address, start_date, end_date, token_b_party);
    enterDate = now;
    current_state = SwapState.started;
  }

  /*
  * This function creates the DRCT tokens for the short and long parties, and ensures the short and long parties
  * have funded the contract with the correct amount of the ERC20 tokens A and B
  *
  */
  function createTokens() public onlyState(SwapState.started){

    //Ensure the contract has been funded by tokens a and b within 1 day
    require(
      now < (enterDate + 86400) &&
      token_a.balanceOf(address(this)) >= token_a_amount &&
      token_b.balanceOf(address(this)) >= token_b_amount
    );

    uint tokenratio = 1;
    (long_token_address,tokenratio) = factory.createToken(token_a_amount, long_party,true,start_date);
    num_DRCT_longtokens = token_a_amount.div(tokenratio);
    (short_token_address,tokenratio) = factory.createToken(token_b_amount, short_party,false,start_date);
    num_DRCT_shorttokens = token_b_amount.div(tokenratio);
    current_state = SwapState.tokenized;
    if (premium > 0){
      if (creator == long_party){
      short_party.transfer(premium);
      }
      else {
        long_party.transfer(premium);
      }
    }
  }

  /*
  * This function calculates the payout of the swap. It can be called after the Swap has been tokenized.
  * The value of the underlying cannot reach zero, but rather can only get within 0.001 * the precision
  * of the Oracle.
  */
  function Calculate() internal {
    //require(now >= end_date + 86400);
    //Comment out above for testing purposes
    oracle = Oracle_Interface(oracle_address);
    uint start_value = oracle.RetrieveData(start_date);
    uint end_value = oracle.RetrieveData(end_date);

    uint ratio;
    if (start_value > 0 && end_value > 0)
      ratio = (end_value).mul(100000).div(start_value);
    else if (end_value > 0)
      ratio = 10e10;
    else if (start_value > 0)
      ratio = 0;
    else
      ratio = 100000;

    if (ratio == 100000) {
      share_long = share_short = ratio;
    } else if (ratio > 100000) {
      share_long = ((ratio).sub(100000)).mul(multiplier).add(100000);
      if (share_long >= 200000)
        share_short = 0;
      else
        share_short = 200000-share_long;
    } else {
      share_short = SafeMath.sub(100000,ratio).mul(multiplier).add(100000);
       if (share_short >= 200000)
        share_long = 0;
      else
        share_long = 200000- share_short;
    }

    //Calculate the payouts to long and short parties based on the short and long shares
    calculatePayout();

    current_state = SwapState.ready;
  }

  /*
  * Calculates the amount paid to the short and long parties per token
  */
  function calculatePayout() internal {
    uint ratio;
    token_a_amount = token_a_amount.mul(995).div(1000);
    token_b_amount = token_b_amount.mul(995).div(1000);
    //If ratio is flat just swap tokens, otherwise pay the winner the entire other token and only pay the other side a portion of the opposite token
    if (share_long == 100000) {
      pay_to_short_a = (token_a_amount).div(num_DRCT_longtokens);
      pay_to_long_b = (token_b_amount).div(num_DRCT_shorttokens);
      pay_to_short_b = 0;
      pay_to_long_a = 0;
    } else if (share_long > 100000) {
      ratio = SafeMath.min(100000, (share_long).sub(100000));
      pay_to_long_b = (token_b_amount).div(num_DRCT_shorttokens);
      pay_to_short_a = (SafeMath.sub(100000,ratio)).mul(token_a_amount).div(num_DRCT_longtokens).div(100000);
      pay_to_long_a = ratio.mul(token_a_amount).div(num_DRCT_longtokens).div(100000);
      pay_to_short_b = 0;
    } else {
      ratio = SafeMath.min(100000, (share_short).sub(100000));
      pay_to_short_a = (token_a_amount).div(num_DRCT_longtokens);
      pay_to_long_b = (SafeMath.sub(100000,ratio)).mul(token_b_amount).div(num_DRCT_shorttokens).div(100000);
      pay_to_short_b = ratio.mul(token_b_amount).div(num_DRCT_shorttokens).div(100000);
      pay_to_long_a = 0;
    }
  }

  /*
  * This function can be called after the swap is tokenized or after the Calculate function is called.
  * If the Calculate function has not yet been called, this function will call it.
  * The function then pays every token holder of both the long and short DRCT tokens
  */
  function forcePay(uint _begin, uint _end) public returns (bool) {
    //Calls the Calculate function first to calculate short and long shares
    if(current_state == SwapState.tokenized /*&& now > end_date + 86400*/){
      Calculate();
    }

    //The state at this point should always be SwapState.ready
    require(current_state == SwapState.ready);

    //Loop through the owners of long and short DRCT tokens and pay them

    token = DRCT_Token_Interface(long_token_address);
    uint count = token.addressCount(address(this));
    uint loop_count = count < _end ? count : _end;
    //Indexing begins at 1 for DRCT_Token balances
    for(uint i = loop_count-1; i >= _begin ; i--) {
      address long_owner = token.getHolderByIndex(i, address(this));
      uint to_pay_long = token.getBalanceByIndex(i, address(this));
      paySwap(long_owner, to_pay_long, true);
    }

    token = DRCT_Token_Interface(short_token_address);
    count = token.addressCount(address(this));
    loop_count = count < _end ? count : _end;
    for(uint j = loop_count-1; j >= _begin ; j--) {
      address short_owner = token.getHolderByIndex(j, address(this));
      uint to_pay_short = token.getBalanceByIndex(j, address(this));
      paySwap(short_owner, to_pay_short, false);
    }

    if (loop_count == count){
        token_a.transfer(factory_address, token_a.balanceOf(address(this)));
        token_b.transfer(factory_address, token_b.balanceOf(address(this)));
        PaidOut(long_token_address, short_token_address);
        current_state = SwapState.ended;
      }
    return true;
  }

  /*
  * This function pays the receiver an amount determined by the Calculate function
  *
  * @param "_receiver": The recipient of the payout
  * @param "_amount": The amount of token the recipient holds
  * @param "_is_long": Whether or not the reciever holds a long or short token
  */
  function paySwap(address _receiver, uint _amount, bool _is_long) internal {
    if (_is_long) {
      if (pay_to_long_a > 0)
        token_a.transfer(_receiver, _amount.mul(pay_to_long_a));
      if (pay_to_long_b > 0){
        token_b.transfer(_receiver, _amount.mul(pay_to_long_b));
      }
        factory.payToken(_receiver,long_token_address);
    } else {

      if (pay_to_short_a > 0)
        token_a.transfer(_receiver, _amount.mul(pay_to_short_a));
      if (pay_to_short_b > 0){
        token_b.transfer(_receiver, _amount.mul(pay_to_short_b));
      }
       factory.payToken(_receiver,short_token_address);
    }
  }


  /*
  * This function allows both parties to exit. If only the creator has entered the swap, then the swap can be cancelled and the details modified
  * Once two parties enter the swap, the contract is null after cancelled. Once tokenized however, the contract cannot be ended.
  */
  function Exit() public {
   if (current_state == SwapState.open && msg.sender == token_a_party) {
      token_a.transfer(token_a_party, token_a_amount);
      if (premium>0){
        msg.sender.transfer(premium);
      }
      delete token_a_amount;
      delete token_b_amount;
      delete premium;
      current_state = SwapState.created;
    } else if (current_state == SwapState.started && (msg.sender == token_a_party || msg.sender == token_b_party)) {
      if (msg.sender == token_a_party || msg.sender == token_b_party) {
        token_b.transfer(token_b_party, token_b.balanceOf(address(this)));
        token_a.transfer(token_a_party, token_a.balanceOf(address(this)));
        current_state = SwapState.ended;
        if (premium > 0) { creator.transfer(premium);}
      }
    }
  }
}

//Swap Deployer Contract-- purpose is to save gas for deployment of Factory contract
contract Deployer {
  address owner;
  address factory;

  function Deployer(address _factory) public {
    factory = _factory;
    owner = msg.sender;
  }

  function newContract(address _party, address user_contract, uint _start_date) public returns (address created) {
    require(msg.sender == factory);
    address new_contract = new TokenToTokenSwap(factory, _party, user_contract, _start_date);
    return new_contract;
  }

   function setVars(address _factory, address _owner) public {
    require (msg.sender == owner);
    factory = _factory;
    owner = _owner;
  }
}