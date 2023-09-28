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


//The DRCT_Token is an ERC20 compliant token representing the payout of the swap contract specified in the Factory contract
//Each Factory contract is specified one DRCT Token and the token address can contain many different swap contracts that are standardized at the Factory level
contract DRCT_Token {

  using SafeMath for uint256;

  /*Structs */
  //Keeps track of balance amounts in the balances array
  struct Balance {
    address owner;
    uint amount;
  }

  //This is the factory contract that the token is standardized at
  address public master_contract;
  //Total supply of outstanding tokens in the contract
  uint public total_supply;

  //Mapping from: swap address -> user balance struct (index for a particular user's balance can be found in swap_balances_index)
  mapping(address => Balance[]) swap_balances;
  //Mapping from: swap address -> user -> swap_balances index
  mapping(address => mapping(address => uint)) swap_balances_index;
  //Mapping from: user -> dynamic array of swap addresses (index for a particular swap can be found in user_swaps_index)
  mapping(address => address[]) user_swaps;
  //Mapping from: user -> swap address -> user_swaps index
  mapping(address => mapping(address => uint)) user_swaps_index;

  //Mapping from: user -> total balance accross all entered swaps
  mapping(address => uint) user_total_balances;
  //Mapping from: owner -> spender -> amount allowed
  mapping(address => mapping(address => uint)) allowed;

  //events for transfer and approvals
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

  modifier onlyMaster() {
    require(msg.sender == master_contract);
    _;
  }

  /*Functions*/
  //Constructor
  function DRCT_Token(address _factory) public {
    //Sets values for token name and token supply, as well as the master_contract, the swap.
    master_contract = _factory;
  }
  //Token Creator - This function is called by the factory contract and creates new tokens for the user
  function createToken(uint _supply, address _owner, address _swap) public onlyMaster() {
    //Update total supply of DRCT Tokens
    total_supply = total_supply.add(_supply);
    //Update the total balance of the owner
    user_total_balances[_owner] = user_total_balances[_owner].add(_supply);
    //If the user has not entered any swaps already, push a zeroed address to their user_swaps mapping to prevent default value conflicts in user_swaps_index
    if (user_swaps[_owner].length == 0)
      user_swaps[_owner].push(address(0x0));
    //Add a new swap index for the owner
    user_swaps_index[_owner][_swap] = user_swaps[_owner].length;
    //Push a new swap address to the owner's swaps
    user_swaps[_owner].push(_swap);
    //Push a zeroed Balance struct to the swap balances mapping to prevent default value conflicts in swap_balances_index
    swap_balances[_swap].push(Balance({
      owner: 0,
      amount: 0
    }));
    //Add a new owner balance index for the swap
    swap_balances_index[_swap][_owner] = 1;
    //Push the owner's balance to the swap
    swap_balances[_swap].push(Balance({
      owner: _owner,
      amount: _supply
    }));
  }

  //Called by the factory contract, and pays out to a _party
  function pay(address _party, address _swap) public onlyMaster() {
    uint party_balance_index = swap_balances_index[_swap][_party];
    uint party_swap_balance = swap_balances[_swap][party_balance_index].amount;
    //reduces the users totals balance by the amount in that swap
    user_total_balances[_party] = user_total_balances[_party].sub(party_swap_balance);
    //reduces the total supply by the amount of that users in that swap
    total_supply = total_supply.sub(party_swap_balance);
    //sets the partys balance to zero for that specific swaps party balances
    swap_balances[_swap][party_balance_index].amount = 0;
  }

  //Returns the users total balance (sum of tokens in all swaps the user has tokens in)
  function balanceOf(address _owner) public constant returns (uint balance) { return user_total_balances[_owner]; }

  //Getter for the total_supply of tokens in the contract
  function totalSupply() public constant returns (uint _total_supply) { return total_supply; }

  //Checks whether an address is in a specified swap. If they are, the user_swaps_index for that user and swap will be non-zero
  function addressInSwap(address _swap, address _owner) public view returns (bool) {
    return user_swaps_index[_owner][_swap] != 0;
  }

  //Removes the address from the swap balances for a swap, and moves the last address in the swap into their place
  function removeFromSwapBalances(address _remove, address _swap) internal {
    uint last_address_index = swap_balances[_swap].length.sub(1);
    address last_address = swap_balances[_swap][last_address_index].owner;
    //If the address we want to remove is the final address in the swap
    if (last_address != _remove) {
      uint remove_index = swap_balances_index[_swap][_remove];
      //Update the swap's balance index of the last address to that of the removed address index
      swap_balances_index[_swap][last_address] = remove_index;
      //Set the swap's Balance struct at the removed index to the Balance struct of the last address
      swap_balances[_swap][remove_index] = swap_balances[_swap][last_address_index];
    }
    //Remove the swap_balances index for this address
    delete swap_balances_index[_swap][_remove];
    //Finally, decrement the swap balances length
    swap_balances[_swap].length = swap_balances[_swap].length.sub(1);
  }

  // This is the main function to update the mappings when a transfer happens
  function transferHelper(address _from, address _to, uint _amount) internal {
    //Get memory copies of the swap arrays for the sender and reciever
    address[] memory from_swaps = user_swaps[_from];

    //Iterate over sender's swaps in reverse order until enough tokens have been transferred
    for (uint i = from_swaps.length.sub(1); i > 0; i--) {
      //Get the index of the sender's balance for the current swap
      uint from_swap_user_index = swap_balances_index[from_swaps[i]][_from];
      Balance memory from_user_bal = swap_balances[from_swaps[i]][from_swap_user_index];
      //If the current swap will be entirely depleted - we remove all references to it for the sender
      if (_amount >= from_user_bal.amount) {
        _amount -= from_user_bal.amount;
        //If this swap is to be removed, we know it is the (current) last swap in the user's user_swaps list, so we can simply decrement the length to remove it
        user_swaps[_from].length = user_swaps[_from].length.sub(1);
        //Remove the user swap index for this swap
        delete user_swaps_index[_from][from_swaps[i]];

        //If the _to address already holds tokens from this swap
        if (addressInSwap(from_swaps[i], _to)) {
          //Get the index of the _to balance in this swap
          uint to_balance_index = swap_balances_index[from_swaps[i]][_to];
          assert(to_balance_index != 0);
          //Add the _from tokens to _to
          swap_balances[from_swaps[i]][to_balance_index].amount = swap_balances[from_swaps[i]][to_balance_index].amount.add(from_user_bal.amount);
          //Remove the _from address from this swap's balance array
          removeFromSwapBalances(_from, from_swaps[i]);
        } else {
          //Prepare to add a new swap by assigning the swap an index for _to
          if (user_swaps[_to].length == 0)
            user_swaps_index[_to][from_swaps[i]] = 1;
          else
            user_swaps_index[_to][from_swaps[i]] = user_swaps[_to].length;
          //Add the new swap to _to
          user_swaps[_to].push(from_swaps[i]);
          //Give the reciever the sender's balance for this swap
          swap_balances[from_swaps[i]][from_swap_user_index].owner = _to;
          //Give the reciever the sender's swap balance index for this swap
          swap_balances_index[from_swaps[i]][_to] = swap_balances_index[from_swaps[i]][_from];
          //Remove the swap balance index from the sending party
          delete swap_balances_index[from_swaps[i]][_from];
        }
        //If there is no more remaining to be removed, we break out of the loop
        if (_amount == 0)
          break;
      } else {
        //The amount in this swap is more than the amount we still need to transfer
        uint to_swap_balance_index = swap_balances_index[from_swaps[i]][_to];
        //If the _to address already holds tokens from this swap
        if (addressInSwap(from_swaps[i], _to)) {
          //Because both addresses are in this swap, and neither will be removed, we simply update both swap balances
          swap_balances[from_swaps[i]][to_swap_balance_index].amount = swap_balances[from_swaps[i]][to_swap_balance_index].amount.add(_amount);
        } else {
          //Prepare to add a new swap by assigning the swap an index for _to
          if (user_swaps[_to].length == 0)
            user_swaps_index[_to][from_swaps[i]] = 1;
          else
            user_swaps_index[_to][from_swaps[i]] = user_swaps[_to].length;
          //And push the new swap
          user_swaps[_to].push(from_swaps[i]);
          //_to is not in this swap, so we give this swap a new balance index for _to
          swap_balances_index[from_swaps[i]][_to] = swap_balances[from_swaps[i]].length;
          //And push a new balance for _to
          swap_balances[from_swaps[i]].push(Balance({
            owner: _to,
            amount: _amount
          }));
        }
        //Finally, update the _from user's swap balance
        swap_balances[from_swaps[i]][from_swap_user_index].amount = swap_balances[from_swaps[i]][from_swap_user_index].amount.sub(_amount);
        //Because we have transferred the last of the amount to the reciever, we break;
        break;
      }
    }
  }

  /*
    ERC20 compliant transfer function
    @param - _to: Address to send funds to
    @param - _amount: Amount of token to send
    returns true for successful
  */
  function transfer(address _to, uint _amount) public returns (bool success) {
    uint balance_owner = user_total_balances[msg.sender];

    if (
      _to == msg.sender ||
      _to == address(0) ||
      _amount == 0 ||
      balance_owner < _amount
    ) return false;

    transferHelper(msg.sender, _to, _amount);
    user_total_balances[msg.sender] = user_total_balances[msg.sender].sub(_amount);
    user_total_balances[_to] = user_total_balances[_to].add(_amount);
    Transfer(msg.sender, _to, _amount);
    return true;
  }

  /*
    ERC20 compliant transferFrom function
    @param - _from: Address to send funds from (must be allowed, see approve function)
    @param - _to: Address to send funds to
    @param - _amount: Amount of token to send
    returns true for successful
  */
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    uint balance_owner = user_total_balances[_from];
    uint sender_allowed = allowed[_from][msg.sender];

    if (
      _to == _from ||
      _to == address(0) ||
      _amount == 0 ||
      balance_owner < _amount ||
      sender_allowed < _amount
    ) return false;

    transferHelper(_from, _to, _amount);
    user_total_balances[_from] = user_total_balances[_from].sub(_amount);
    user_total_balances[_to] = user_total_balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    Transfer(_from, _to, _amount);
    return true;
  }

  /*
    ERC20 compliant approve function
    @param - _spender: Party that msg.sender approves for transferring funds
    @param - _amount: Amount of token to approve for sending
    returns true for successful
  */
  function approve(address _spender, uint _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  //Returns the length of the balances array for a swap
  function addressCount(address _swap) public constant returns (uint count) { return swap_balances[_swap].length; }

  //Returns the address associated with a particular index in a particular swap
  function getHolderByIndex(uint _ind, address _swap) public constant returns (address holder) { return swap_balances[_swap][_ind].owner; }

  //Returns the balance associated with a particular index in a particular swap
  function getBalanceByIndex(uint _ind, address _swap) public constant returns (uint bal) { return swap_balances[_swap][_ind].amount; }

  //Returns the index associated with the _owner address in a particular swap
  function getIndexByAddress(address _owner, address _swap) public constant returns (uint index) { return swap_balances_index[_swap][_owner]; }

  //Returns the allowed amount _spender can spend of _owner's balance
  function allowance(address _owner, address _spender) public constant returns (uint amount) { return allowed[_owner][_spender]; }
}


//Swap Deployer Contract-- purpose is to save gas for deployment of Factory contract
contract Tokendeployer {
  address owner;
  address public factory;

  function Tokendeployer(address _factory) public {
    factory = _factory;
    owner = msg.sender;
  }

  function newToken() public returns (address created) {
    require(msg.sender == factory);
    address new_token = new DRCT_Token(factory);
    return new_token;
  }

   function setVars(address _factory, address _owner) public {
    require (msg.sender == owner);
    factory = _factory;
    owner = _owner;
  }
}