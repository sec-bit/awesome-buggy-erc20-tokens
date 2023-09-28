/**
*
The MIT License (MIT)

Copyright (c) 2018 Bitindia.
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
For more information regarding the MIT License visit: https://opensource.org/licenses/MIT

@AUTHOR Bitindia. https://bitindia.co/
*
*/


pragma solidity ^0.4.15;


contract IERC20 {
    function totalSupply() public constant returns (uint _totalSupply);
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


/**
 * @title Ownable
 * @notice The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @notice The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @notice Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/**
 * BitindiaVestingContract 
 * This Contract is a custodian for Bitindia Tokens reserved for Founders
 * Founders can claim as per fixed Vesting Schedule
 * Founders can only claim the amount alloted to them before initialization
 * The Contract gets into a locked state once initialized and no more founder address can be further added
 * The Founder addresses are added using addVestingUser method and logs an Event AddUser on successful addition
 * Only the contract owner can add the Vesting users and cannot change the address once inititialized
 * Anyone can check the state inititialized, as its a public variable
 * Once initialized, founders can anytime change their claim address, and this can be done only using their private key,
 * No body else can change claimant address other than themselves.
 * No kind of recovery is possible once the private key of any claimant is lost and any unclaimed tokens will be locked in this contract forever
 */ 
contract BitindiaVestingContract is Ownable{

  IERC20 token;

  mapping (address => uint256) ownersMap;

  mapping (address => uint256) ownersMapFirstPeriod;    
  mapping (address => uint256) ownersMapSecondPeriod;    
  mapping (address => uint256) ownersMapThirdPeriod;   

  /**
   * Can be initialized only once all the committed token amount is deposited to this contract
   * Once initialized, it cannot be set False again
   * Once initialized, no more founder address can be registered
   */ 
  bool public initialized = false;

  /**
   * At any point displays total anount that is yet to be claimed
   */
  uint256 public totalCommitted;

  /**
   * To avoid too many address changes,  * 
   */ 
  mapping (address => address)  originalAddressTraker;
  mapping (address => uint) changeAddressAttempts;

  /**
   *  Fixed Vesting Schedule   *
   */
  uint256 public constant firstDueDate = 1544486400;    // Human time (GMT): Tuesday, 11 December 2018 00:00:00
  uint256 public constant secondDueDate = 1560211200;   // Human time (GMT): Tuesday, Tuesday, 11 June 2019 00:00:00
  uint256 public constant thirdDueDate = 1576022400;    // Human time (GMT): Wednesday, 11 December 2019 00:00:00

  /**
   * Address of the Token to be vested 
   */
  address public constant tokenAddress = 0x420335D3DEeF2D5b87524Ff9D0fB441F71EA621f;
  
  /**
   * Event to log change of address request if successful, only the Actual owner can transfer its ownership
   *  
   */
  event ChangeClaimAddress(address oldAddress, address newAddress);

  /**
   * Event to log claimed amount once the vesting condition is met.
   */
  event AmountClaimed(address user, uint256 amount);

  /**
   * Event to Log added user
   */ 
  event AddUser(address userAddress, uint256 amount);
 
  /**
   * Cnstr BitindiaVestingContract
   * Sets the vesting period in utc timestamp and the vesting token address
   */
  function BitindiaVestingContract() public {
      token = IERC20(tokenAddress);
      initialized = false;
      totalCommitted = 0;
  }

  /**
   *    Initializes the contract only once 
   *    Requires token balance to be atleast equal to total commited, any amount greater than commited is lost in the contract forever  
   */ 
  function initialize() public onlyOwner
  {
      require(totalCommitted>0);
      require(totalCommitted <= token.balanceOf(this));
      if(!initialized){
            initialized = true;
      }
  }

  /**
   * @notice To check if Contract is active
   */
  modifier whenContractIsActive() {
    // Check if Contract is active
    require(initialized);
    _;
  }

  /**
   * @notice To check if Contract is not yet initialized
   */
  modifier preInitState() {
    // Check if Contract is not initialized
    require(!initialized);
    _;
  }

   /**
   * @notice To check if Claimable
   */
  modifier whenClaimable() {
    // Check if Contract is active
    assert(now>firstDueDate);
    _;
  }
  
  /**
   * Asserts the msg sender to have valid stake in the vesting schedule, else eat up their GAS 
   * this is to discourage SPAMMERS
   */ 
  modifier checkValidUser(){
    assert(ownersMap[msg.sender]>0);
    _;
  }

  /**
   * @notice Can be called only before initialization
   * Equal vesting in three periods
   */
  function addVestingUser(address user, uint256 amount) public onlyOwner preInitState {
      uint256 oldAmount = ownersMap[user];
      ownersMap[user] = amount;
      ownersMapFirstPeriod[user] = amount/3;         
      ownersMapSecondPeriod[user] = amount/3;
      ownersMapThirdPeriod[user] = amount - ownersMapFirstPeriod[user] - ownersMapSecondPeriod[user];
      originalAddressTraker[user] = user;
      changeAddressAttempts[user] = 0;
      totalCommitted += (amount - oldAmount);
      AddUser(user, amount);
  }
  
  /**
   * This is to change the address of the claimant.
   * SPRECIAL NOTE: ONLY THE VALID CLAIMANT CAN change its address and nobody else can do this  
   */
  function changeClaimAddress(address newAddress) public checkValidUser{

      // Validates if Change address is not meant to Spam
      address origAddress = originalAddressTraker[msg.sender];
      uint newCount = changeAddressAttempts[origAddress]+1;
      assert(newCount<5);
      changeAddressAttempts[origAddress] = newCount;
      
      // Do the address change transaction
      uint256 balance = ownersMap[msg.sender];
      ownersMap[msg.sender] = 0;
      ownersMap[newAddress] = balance;


      // Do the address change transaction for FirstPeriod
      balance = ownersMapFirstPeriod[msg.sender];
      ownersMapFirstPeriod[msg.sender] = 0;
      ownersMapFirstPeriod[newAddress] = balance;

      // Do the address change transaction for SecondPeriod
      balance = ownersMapSecondPeriod[msg.sender];
      ownersMapSecondPeriod[msg.sender] = 0;
      ownersMapSecondPeriod[newAddress] = balance;


      // Do the address change transaction for FirstPeriod
      balance = ownersMapThirdPeriod[msg.sender];
      ownersMapThirdPeriod[msg.sender] = 0;
      ownersMapThirdPeriod[newAddress] = balance;


      // Update Original Address Tracker Map 
      originalAddressTraker[newAddress] = origAddress;
      ChangeClaimAddress(msg.sender, newAddress);
  }


  /**
   * Admin function to restart attempt counts for a user
   */
  function updateChangeAttemptCount(address user) public onlyOwner{
    address origAddress = originalAddressTraker[user];
    changeAddressAttempts[origAddress] = 0;
  }

  /**
   * Check the balance of the Vesting Contract
   */
  function getBalance() public constant returns (uint256) {
      return token.balanceOf(this);
  }

  /**
   * To claim the vesting amount
   * Asserts the vesting condition is met
   * Asserts callee to be valid vested user 
   * Claims as per Vesting Schedule and remaining eligible balance
   */
  function claimAmount() internal whenContractIsActive whenClaimable checkValidUser{
      uint256 amount = 0;
      uint256 periodAmount = 0;
      if(now>firstDueDate){
        periodAmount = ownersMapFirstPeriod[msg.sender];
        if(periodAmount > 0){
          ownersMapFirstPeriod[msg.sender] = 0;
          amount += periodAmount;
        }
      }

      if(now>secondDueDate){
        periodAmount = ownersMapSecondPeriod[msg.sender];
        if(periodAmount > 0){
          ownersMapSecondPeriod[msg.sender] = 0;
          amount += periodAmount;
        }
      }

      if(now>thirdDueDate){
        periodAmount = ownersMapThirdPeriod[msg.sender];
        if(periodAmount > 0){
          ownersMapThirdPeriod[msg.sender] = 0;
          amount += periodAmount;
        }
      }
      require(amount>0);
      ownersMap[msg.sender]= ownersMap[msg.sender]-amount;
      token.transfer(msg.sender, amount);
      totalCommitted -= amount;

  }


   /**
   * Main fallback to claim tokens after successful vesting
   * Asserts the sender to be a valid owner of tokens and vesting period is over
   */
  function () external payable {
      claimAmount();
  }


  /**
   * To check total remaining claimable amount
   */
   function getClaimable() public constant returns (uint256){
       return totalCommitted;
   }
   
   /**
    * Check Own Balance 
    * Works only for transaction senders with valid Balance
    */ 
   function getMyBalance() public checkValidUser constant returns (uint256){
       
       return ownersMap[msg.sender];
       
   }
   


}