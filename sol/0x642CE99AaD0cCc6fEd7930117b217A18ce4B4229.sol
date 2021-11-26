/*

  Copyright 2017 Cofound.it.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.4.13;

contract ReentrnacyHandlingContract{

    bool locked;

    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}

contract Owned {
    address public owner;
    address public newOwner;

    function Owned() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract IToken {
  function totalSupply() public constant returns (uint256 totalSupply);
  function mintTokens(address _to, uint256 _amount) public {}
}

contract IERC20Token {
  function totalSupply() public constant returns (uint256 totalSupply);
  function balanceOf(address _owner) public constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) public returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
  function approve(address _spender, uint256 _value) public returns (bool success) {}
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Crowdsale is ReentrnacyHandlingContract, Owned{

  struct ContributorData{
    uint priorityPassAllowance;
    bool isActive;
    uint contributionAmount;
    uint tokensIssued;
  }

  mapping(address => ContributorData) public contributorList;
  uint public nextContributorIndex;
  mapping(uint => address) public contributorIndexes;

  state public crowdsaleState = state.pendingStart;
  enum state { pendingStart, priorityPass, openedPriorityPass, crowdsale, crowdsaleEnded }

  uint public presaleStartTime;
  uint public presaleUnlimitedStartTime;
  uint public crowdsaleStartTime;
  uint public crowdsaleEndedTime;

  event PresaleStarted(uint blockTime);
  event PresaleUnlimitedStarted(uint blockTime);
  event CrowdsaleStarted(uint blockTime);
  event CrowdsaleEnded(uint blockTime);
  event ErrorSendingETH(address to, uint amount);
  event MinCapReached(uint blockTime);
  event MaxCapReached(uint blockTime);
  event ContributionMade(address indexed contributor, uint amount);


  IToken token = IToken(0x0);
  uint ethToTokenConversion;

  uint public minCap;
  uint public maxP1Cap;
  uint public maxCap;
  uint public ethRaised;

  address public multisigAddress;

  uint nextContributorToClaim;
  mapping(address => bool) hasClaimedEthWhenFail;

  uint public maxTokenSupply;
  bool public ownerHasClaimedTokens;
  uint public presaleBonusTokens;
  address public presaleBonusAddress;
  address public presaleBonusAddressColdStorage;
  bool public presaleBonusTokensClaimed;

  //
  // Unnamed function that runs when eth is sent to the contract
  // @payable
  //
  function() public noReentrancy payable{
    require(msg.value != 0);                        // Throw if value is 0
    require(crowdsaleState != state.crowdsaleEnded);// Check if crowdsale has ended

    bool stateChanged = checkCrowdsaleState();      // Check blocks and calibrate crowdsale state

    if (crowdsaleState == state.priorityPass){
      if (contributorList[msg.sender].isActive){    // Check if contributor is in priorityPass
        processTransaction(msg.sender, msg.value);  // Process transaction and issue tokens
      }else{
        refundTransaction(stateChanged);            // Set state and return funds or throw
      }
    }
    else if(crowdsaleState == state.openedPriorityPass){
      if (contributorList[msg.sender].isActive){    // Check if contributor is in priorityPass
        processTransaction(msg.sender, msg.value);  // Process transaction and issue tokens
      }else{
        refundTransaction(stateChanged);            // Set state and return funds or throw
      }
    }
    else if(crowdsaleState == state.crowdsale){
      processTransaction(msg.sender, msg.value);    // Process transaction and issue tokens
    }
    else{
      refundTransaction(stateChanged);              // Set state and return funds or throw
    }
  }

  //
  // Check crowdsale state and calibrate it
  //
  function checkCrowdsaleState() internal returns (bool){
    if (ethRaised == maxCap && crowdsaleState != state.crowdsaleEnded){                         // Check if max cap is reached
      crowdsaleState = state.crowdsaleEnded;
      MaxCapReached(block.timestamp);                                                              // Close the crowdsale
      CrowdsaleEnded(block.timestamp);                                                             // Raise event
      return true;
    }

    if (block.timestamp > presaleStartTime && block.timestamp <= presaleUnlimitedStartTime){  // Check if we are in presale phase
      if (crowdsaleState != state.priorityPass){                                          // Check if state needs to be changed
        crowdsaleState = state.priorityPass;                                              // Set new state
        PresaleStarted(block.timestamp);                                                     // Raise event
        return true;
      }
    }else if(block.timestamp > presaleUnlimitedStartTime && block.timestamp <= crowdsaleStartTime){ // Check if we are in presale unlimited phase
      if (crowdsaleState != state.openedPriorityPass){                                          // Check if state needs to be changed
        crowdsaleState = state.openedPriorityPass;                                              // Set new state
        PresaleUnlimitedStarted(block.timestamp);                                                  // Raise event
        return true;
      }
    }else if(block.timestamp > crowdsaleStartTime && block.timestamp <= crowdsaleEndedTime){        // Check if we are in crowdsale state
      if (crowdsaleState != state.crowdsale){                                                   // Check if state needs to be changed
        crowdsaleState = state.crowdsale;                                                       // Set new state
        CrowdsaleStarted(block.timestamp);                                                         // Raise event
        return true;
      }
    }else{
      if (crowdsaleState != state.crowdsaleEnded && block.timestamp > crowdsaleEndedTime){        // Check if crowdsale is over
        crowdsaleState = state.crowdsaleEnded;                                                  // Set new state
        CrowdsaleEnded(block.timestamp);                                                           // Raise event
        return true;
      }
    }
    return false;
  }

  //
  // Decide if throw or only return ether
  //
  function refundTransaction(bool _stateChanged) internal{
    if (_stateChanged){
      msg.sender.transfer(msg.value);
    }else{
      revert();
    }
  }

  //
  // Calculate how much user can contribute
  //
  function calculateMaxContribution(address _contributor) constant returns (uint maxContribution){
    uint maxContrib;
    if (crowdsaleState == state.priorityPass){    // Check if we are in priority pass
      maxContrib = contributorList[_contributor].priorityPassAllowance - contributorList[_contributor].contributionAmount;
      if (maxContrib > (maxP1Cap - ethRaised)){   // Check if max contribution is more that max cap
        maxContrib = maxP1Cap - ethRaised;        // Alter max cap
      }
    }
    else{
      maxContrib = maxCap - ethRaised;            // Alter max cap
    }
    return maxContrib;
  }

  //
  // Issue tokens and return if there is overflow
  //
  function processTransaction(address _contributor, uint _amount) internal{
    uint maxContribution = calculateMaxContribution(_contributor);              // Calculate max users contribution
    uint contributionAmount = _amount;
    uint returnAmount = 0;
    if (maxContribution < _amount){                                             // Check if max contribution is lower than _amount sent
      contributionAmount = maxContribution;                                     // Set that user contributes his maximum allowed contribution
      returnAmount = _amount - maxContribution;                                 // Calculate how much he must get back
    }

    if (ethRaised + contributionAmount > minCap && minCap > ethRaised) MinCapReached(block.timestamp);

    if (contributorList[_contributor].isActive == false){                       // Check if contributor has already contributed
      contributorList[_contributor].isActive = true;                            // Set his activity to true
      contributorList[_contributor].contributionAmount = contributionAmount;    // Set his contribution
      contributorIndexes[nextContributorIndex] = _contributor;                  // Set contributors index
      nextContributorIndex++;
    }
    else{
      contributorList[_contributor].contributionAmount += contributionAmount;   // Add contribution amount to existing contributor
    }
    ethRaised += contributionAmount;                                            // Add to eth raised

    ContributionMade(msg.sender, contributionAmount);

    uint tokenAmount = contributionAmount * ethToTokenConversion;               // Calculate how much tokens must contributor get
    if (tokenAmount > 0){
      token.mintTokens(_contributor, tokenAmount);                                // Issue new tokens
      contributorList[_contributor].tokensIssued += tokenAmount;                  // log token issuance
    }
    if (returnAmount != 0) _contributor.transfer(returnAmount);                 // Return overflow of ether
  }

  //
  // Push contributor data to the contract before the crowdsale so that they are eligible for priority pass
  //
  function editContributors(address[] _contributorAddresses, uint[] _contributorPPAllowances) public onlyOwner{
    require(_contributorAddresses.length == _contributorPPAllowances.length); // Check if input data is correct

    for(uint cnt = 0; cnt < _contributorAddresses.length; cnt++){
      if (contributorList[_contributorAddresses[cnt]].isActive){
        contributorList[_contributorAddresses[cnt]].priorityPassAllowance = _contributorPPAllowances[cnt];
      }
      else{
        contributorList[_contributorAddresses[cnt]].isActive = true;
        contributorList[_contributorAddresses[cnt]].priorityPassAllowance = _contributorPPAllowances[cnt];
        contributorIndexes[nextContributorIndex] = _contributorAddresses[cnt];
        nextContributorIndex++;
      }
    }
  }

  //
  // Method is needed for recovering tokens accidentally sent to token address
  //
  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) public onlyOwner{
    IERC20Token(_tokenAddress).transfer(_to, _amount);
  }

  //
  // withdrawEth when minimum cap is reached
  // @owner sets contributions to withdraw
  //
  function withdrawEth() onlyOwner public {
    require(this.balance != 0);
    require(ethRaised >= minCap);

    pendingEthWithdrawal = this.balance;
  }


  uint public pendingEthWithdrawal;
  //
  // pulls the funds that were set to send with calling of
  // withdrawEth when minimum cap is reached
  // @multisig pulls the contributions to self
  //
  function pullBalance() public {
    require(msg.sender == multisigAddress);
    require(pendingEthWithdrawal > 0);

    multisigAddress.transfer(pendingEthWithdrawal);
    pendingEthWithdrawal = 0;
  }

  //
  // Users can claim their contribution if min cap is not raised
  //
  function claimEthIfFailed() public {
    require(block.timestamp > crowdsaleEndedTime && ethRaised < minCap);    // Check if crowdsale has failed
    require(contributorList[msg.sender].contributionAmount > 0);          // Check if contributor has contributed to crowdsaleEndedTime
    require(!hasClaimedEthWhenFail[msg.sender]);                          // Check if contributor has already claimed his eth

    uint ethContributed = contributorList[msg.sender].contributionAmount; // Get contributors contribution
    hasClaimedEthWhenFail[msg.sender] = true;                             // Set that he has claimed
    if (!msg.sender.send(ethContributed)){                                // Refund eth
      ErrorSendingETH(msg.sender, ethContributed);                        // If there is an issue raise event for manual recovery
    }
  }

  //
  // Owner can batch return contributors contributions(eth)
  //
  function batchReturnEthIfFailed(uint _numberOfReturns) public onlyOwner{
    require(block.timestamp > crowdsaleEndedTime && ethRaised < minCap);                // Check if crowdsale has failed
    address currentParticipantAddress;
    uint contribution;
    for (uint cnt = 0; cnt < _numberOfReturns; cnt++){
      currentParticipantAddress = contributorIndexes[nextContributorToClaim];         // Get next unclaimed participant
      if (currentParticipantAddress == 0x0) return;                                   // Check if all the participants were compensated
      if (!hasClaimedEthWhenFail[currentParticipantAddress]) {                        // Check if participant has already claimed
        contribution = contributorList[currentParticipantAddress].contributionAmount; // Get contribution of participant
        hasClaimedEthWhenFail[currentParticipantAddress] = true;                      // Set that he has claimed
        if (!currentParticipantAddress.send(contribution)){                           // Refund eth
          ErrorSendingETH(currentParticipantAddress, contribution);                   // If there is an issue raise event for manual recovery
        }
      }
      nextContributorToClaim += 1;                                                    // Repeat
    }
  }

  //
  // If there were any issue/attach with refund owner can withdraw eth at the end for manual recovery
  //
  function withdrawRemainingBalanceForManualRecovery() public onlyOwner{
    require(this.balance != 0);                                  // Check if there are any eth to claim
    require(block.timestamp > crowdsaleEndedTime);                 // Check if crowdsale is over
    require(contributorIndexes[nextContributorToClaim] == 0x0);  // Check if all the users were refunded
    multisigAddress.transfer(this.balance);                      // Withdraw to multisig
  }

  //
  // Owner can set multisig address for crowdsale
  //
  function setMultisigAddress(address _newAddress) public onlyOwner{
    multisigAddress = _newAddress;
  }

  //
  // Owner can set token address where mints will happen
  //
  function setToken(address _newAddress) public onlyOwner{
    token = IToken(_newAddress);
  }

  //
  // Owner can claim teams tokens when crowdsale has successfully ended
  //
  function claimCoreTeamsTokens(address _to) public onlyOwner{
    require(crowdsaleState == state.crowdsaleEnded);              // Check if crowdsale has ended
    require(!ownerHasClaimedTokens);                              // Check if owner has already claimed tokens

    uint devReward = maxTokenSupply - token.totalSupply();
    if (!presaleBonusTokensClaimed) devReward -= presaleBonusTokens; // If presaleBonusToken has been claimed its ok if not set aside presaleBonusTokens
    token.mintTokens(_to, devReward);                             // Issue Teams tokens
    ownerHasClaimedTokens = true;                                 // Block further mints from this method
  }

  //
  // Presale bonus tokens
  //
  function claimPresaleTokens() public {
    require(msg.sender == presaleBonusAddress);         // Check if sender is address to claim tokens
    require(crowdsaleState == state.crowdsaleEnded);    // Check if crowdsale has ended
    require(!presaleBonusTokensClaimed);                // Check if tokens were already claimed

    token.mintTokens(presaleBonusAddressColdStorage, presaleBonusTokens);             // Issue presale  tokens
    presaleBonusTokensClaimed = true;                   // Block further mints from this method
  }

  function getTokenAddress() public constant returns(address){
    return address(token);
  }

}


contract FutouristCrowdsale is Crowdsale {
  function FutouristCrowdsale() public {
    /* ADAPT */
    presaleStartTime = 1519142400; //20/2/2017/1700
    presaleUnlimitedStartTime = 1519315200; //22/2/2017/1700
    crowdsaleStartTime = 1519747200; //27/2/2017/1700
    crowdsaleEndedTime = 1521561600; //20/3/2017/1700

    minCap = 1 ether;
    maxCap = 4979 ether;
    maxP1Cap = 4979 ether;

    ethToTokenConversion = 47000;

    maxTokenSupply = 1000000000 * 10**18;
    presaleBonusTokens = 115996000  * 10**18;
    presaleBonusAddress = 0xd7C4af0e30EC62a01036e45b6ed37BC6D0a3bd53;
    presaleBonusAddressColdStorage = 0x47D634Ce50170a156ec4300d35BE3b48E17CAaf6;
    /* /ADAPT */
  }
}