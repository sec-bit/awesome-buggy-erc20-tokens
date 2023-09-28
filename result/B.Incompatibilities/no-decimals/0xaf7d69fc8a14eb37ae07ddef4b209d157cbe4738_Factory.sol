pragma solidity ^0.4.17;

interface Deployer_Interface {
  function newContract(address _party, address user_contract, uint _start_date) public payable returns (address created);
  function newToken() public returns (address created);
}

interface DRCT_Token_Interface {
  function addressCount(address _swap) public constant returns (uint count);
  function getHolderByIndex(uint _ind, address _swap) public constant returns (address holder);
  function getBalanceByIndex(uint _ind, address _swap) public constant returns (uint bal);
  function getIndexByAddress(address _owner, address _swap) public constant returns (uint index);
  function createToken(uint _supply, address _owner, address _swap) public;
  function pay(address _party, address _swap) public;
  function partyCount(address _swap) public constant returns(uint count);
}

interface Wrapped_Ether_Interface {
  function totalSupply() public constant returns (uint total_supply);
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _amount) public returns (bool success);
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success);
  function approve(address _spender, uint _amount) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint amount);
  function withdraw(uint _value) public;
  function CreateToken() public;

}

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


//The Factory contract sets the standardized variables and also deploys new contracts based on these variables for the user.  
contract Factory {
  using SafeMath for uint256;
  //Addresses of the Factory owner and oracle. For oracle information, check www.github.com/DecentralizedDerivatives/Oracles
  address public owner;
  address public oracle_address;

  //Address of the user contract
  address public user_contract;
  DRCT_Token_Interface drct_interface;
  Wrapped_Ether_Interface token_interface;

  //Address of the deployer contract
  address deployer_address;
  Deployer_Interface deployer;
  Deployer_Interface tokenDeployer;
  address token_deployer_address;

  address public token_a;
  address public token_b;

  //A fee for creating a swap in wei.  Plan is for this to be zero, however can be raised to prevent spam
  uint public fee;
  //Duration of swap contract in days
  uint public duration;
  //Multiplier of reference rate.  2x refers to a 50% move generating a 100% move in the contract payout values
  uint public multiplier;
  //Token_ratio refers to the number of DRCT Tokens a party will get based on the number of base tokens.  As an example, 1e15 indicates that a party will get 1000 DRCT Tokens based upon 1 ether of wrapped wei. 
  uint public token_ratio1;
  uint public token_ratio2;


  //Array of deployed contracts
  address[] public contracts;
  mapping(address => uint) public created_contracts;
  mapping(uint => address) public long_tokens;
  mapping(uint => address) public short_tokens;

  //Emitted when a Swap is created
  event ContractCreation(address _sender, address _created);

  /*Modifiers*/
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /*Functions*/
  // Constructor - Sets owner
  function Factory() public {
    owner = msg.sender;
  }

  function getTokens(uint _date) public view returns(address _ltoken, address _stoken){
    return(long_tokens[_date],short_tokens[_date]);
  }

  /*
  * Updates the fee amount
  * @param "_fee": The new fee amount
  */
  function setFee(uint _fee) public onlyOwner() {
    fee = _fee;
  }

  /*
  * Sets the deployer address
  * @param "_deployer": The new deployer address
  */
  function setDeployer(address _deployer) public onlyOwner() {
    deployer_address = _deployer;
    deployer = Deployer_Interface(_deployer);
  }

  /*
  * Sets the token_deployer address
  * @param "_tdeployer": The new token deployer address
  */  
  function settokenDeployer(address _tdeployer) public onlyOwner() {
    token_deployer_address = _tdeployer;
    tokenDeployer = Deployer_Interface(_tdeployer);
  }
  /*
  * Sets the user_contract address
  * @param "_userContract": The new userContract address
  */
  function setUserContract(address _userContract) public onlyOwner() {
    user_contract = _userContract;
  }

  /*
  * Returns the base token addresses
  */
  function getBase() public view returns(address _base1, address base2){
    return (token_a, token_b);
  }


  /*
  * Sets token ratio, swap duration, and multiplier variables for a swap
  * @param "_token_ratio1": The ratio of the first token
  * @param "_token_ratio2": The ratio of the second token
  * @param "_duration": The duration of the swap, in seconds
  * @param "_multiplier": The multiplier used for the swap
  */
  function setVariables(uint _token_ratio1, uint _token_ratio2, uint _duration, uint _multiplier) public onlyOwner() {
    token_ratio1 = _token_ratio1;
    token_ratio2 = _token_ratio2;
    duration = _duration;
    multiplier = _multiplier;
  }

  /*
  * Sets the addresses of the tokens used for the swap
  * @param "_token_a": The address of a token to be used
  * @param "_token_b": The address of another token to be used
  */
  function setBaseTokens(address _token_a, address _token_b) public onlyOwner() {
    token_a = _token_a;
    token_b = _token_b;
  }

  //Allows a user to deploy a new swap contract, if they pay the fee
  //returns the newly created swap address and calls event 'ContractCreation'
  function deployContract(uint _start_date) public payable returns (address created) {
    require(msg.value >= fee);
    address new_contract = deployer.newContract(msg.sender, user_contract, _start_date);
    contracts.push(new_contract);
    created_contracts[new_contract] = _start_date;
    ContractCreation(msg.sender,new_contract);
    return new_contract;
  }


  function deployTokenContract(uint _start_date, bool _long) public returns(address _token) {
    address token;
    if (_long){
      require(long_tokens[_start_date] == address(0));
      token = tokenDeployer.newToken();
      long_tokens[_start_date] = token;
    }
    else{
      require(short_tokens[_start_date] == address(0));
      token = tokenDeployer.newToken();
      short_tokens[_start_date] = token;
    }
    return token;
  }



  /*
  * Deploys new tokens on a DRCT_Token contract -- called from within a swap
  * @param "_supply": The number of tokens to create
  * @param "_party": The address to send the tokens to
  * @param "_long": Whether the party is long or short
  * @returns "created": The address of the created DRCT token
  * @returns "token_ratio": The ratio of the created DRCT token
  */
  function createToken(uint _supply, address _party, bool _long, uint _start_date) public returns (address created, uint token_ratio) {
    require(created_contracts[msg.sender] > 0);
    address ltoken = long_tokens[_start_date];
    address stoken = short_tokens[_start_date];
    require(ltoken != address(0) && stoken != address(0));
    if (_long) {
      drct_interface = DRCT_Token_Interface(ltoken);
      drct_interface.createToken(_supply.div(token_ratio1), _party,msg.sender);
      return (ltoken, token_ratio1);
    } else {
      drct_interface = DRCT_Token_Interface(stoken);
      drct_interface.createToken(_supply.div(token_ratio2), _party,msg.sender);
      return (stoken, token_ratio2);
    }
  }
  

  //Allows the owner to set a new oracle address
  function setOracleAddress(address _new_oracle_address) public onlyOwner() { oracle_address = _new_oracle_address; }

  //Allows the owner to set a new owner address
  function setOwner(address _new_owner) public onlyOwner() { owner = _new_owner; }

  //Allows the owner to pull contract creation fees
  function withdrawFees() public onlyOwner() returns(uint atok, uint btok, uint _eth){
   token_interface = Wrapped_Ether_Interface(token_a);
   uint aval = token_interface.balanceOf(address(this));
   if(aval > 0){
      token_interface.withdraw(aval);
    }
   token_interface = Wrapped_Ether_Interface(token_b);
   uint bval = token_interface.balanceOf(address(this));
   if (bval > 0){
    token_interface.withdraw(bval);
  }
   owner.transfer(this.balance);
   return(aval,bval,this.balance);
   }

   function() public payable {

   }

  /*
  * Returns a tuple of many private variables
  * @returns "_oracle_adress": The address of the oracle
  * @returns "_operator": The address of the owner and operator of the factory
  * @returns "_duration": The duration of the swap
  * @returns "_multiplier": The multiplier for the swap
  * @returns "token_a_address": The address of token a
  * @returns "token_b_address": The address of token b
  * @returns "start_date": The start date of the swap
  */
  function getVariables() public view returns (address oracle_addr, uint swap_duration, uint swap_multiplier, address token_a_addr, address token_b_addr){
    return (oracle_address,duration, multiplier, token_a, token_b);
  }

  /*
  * Pays out to a DRCT token
  * @param "_party": The address being paid
  * @param "_long": Whether the _party is long or not
  */
  function payToken(address _party, address _token_add) public {
    require(created_contracts[msg.sender] > 0);
    drct_interface = DRCT_Token_Interface(_token_add);
    drct_interface.pay(_party, msg.sender);
  }

  //Returns the number of contracts created by this factory
    function getCount() public constant returns(uint count) {
      return contracts.length;
  }
}