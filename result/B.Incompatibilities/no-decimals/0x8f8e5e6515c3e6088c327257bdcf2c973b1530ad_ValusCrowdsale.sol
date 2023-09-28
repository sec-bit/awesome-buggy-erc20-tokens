pragma solidity ^0.4.17;

contract owned {
    
    address public owner;
    
    function owned() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract IValusToken {
  function mintTokens(address _to, uint256 _amount);
  function totalSupply() constant returns (uint256 totalSupply);
}

contract IERC20Token {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function approve(address _spender, uint256 _value) returns (bool success) {}
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ValusCrowdsale is owned {
    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public minEthToRaise;
    uint256 public maxEthToRaise;
    uint256 public totalEthRaised;
    address public multisigAddress;
    
    IValusToken valusTokenContract; 

    uint256 nextFreeParticipantIndex;
    mapping (uint => address) participantIndex;
    mapping (address => uint256) participantContribution;
    
    bool crowdsaleHasStarted;
    bool softCapReached;
    bool hardCapReached;
    bool crowdsaleHasSucessfulyEnded;
    uint256 blocksInADay;
    bool ownerHasClaimedTokens;
    
    uint256 lastEthReturnIndex;
    mapping (address => bool) hasClaimedEthWhenFail;
    
    event CrowdsaleStarted(uint256 _blockNumber);
    event CrowdsaleSoftCapReached(uint256 _blockNumber);
    event CrowdsaleHardCapReached(uint256 _blockNumber);
    event CrowdsaleEndedSuccessfuly(uint256 _blockNumber, uint256 _amountRaised);
    event Crowdsale(uint256 _blockNumber, uint256 _ammountRaised);
    event ErrorSendingETH(address _from, uint256 _amount);
    
    function ValusCrowdsale(){
        
        blocksInADay = 2950;
        startBlock = 4363310;
        endBlock = startBlock + blocksInADay * 29;      
        minEthToRaise = 3030 * 10**18;                     
        maxEthToRaise = 30303 * 10**18;                 
        multisigAddress = 0x4e8FD5605028E12E1e7b1Fa60d437d310fa97Bb2;
    }
    
  //  
  /* User accessible methods */   
  //  
    
    function () payable{
      if(msg.value == 0) throw;
      if (crowdsaleHasSucessfulyEnded || block.number > endBlock) throw;        // Throw if the Crowdsale has ended     
      if (!crowdsaleHasStarted){                                                // Check if this is the first Crowdsale transaction       
        if (block.number >= startBlock){                                        // Check if the Crowdsale should start        
          crowdsaleHasStarted = true;                                           // Set that the Crowdsale has started         
          CrowdsaleStarted(block.number);                                       // Raise CrowdsaleStarted event     
        } else{
          throw;
        }
      }
      if (participantContribution[msg.sender] == 0){                            // Check if the sender is a new user       
        participantIndex[nextFreeParticipantIndex] = msg.sender;                // Add a new user to the participant index       
        nextFreeParticipantIndex += 1;
      }  
      if (maxEthToRaise > (totalEthRaised + msg.value)){                        // Check if the user sent too much ETH       
        participantContribution[msg.sender] += msg.value;                       // Add contribution      
        totalEthRaised += msg.value; // Add to total eth Raised
        valusTokenContract.mintTokens(msg.sender, getValusTokenIssuance(block.number, msg.value));
        if (!softCapReached && totalEthRaised >= minEthToRaise){                // Check if the min treshold has been reached one time        
          CrowdsaleSoftCapReached(block.number);                                // Raise CrowdsalesoftCapReached event        
          softCapReached = true;                                                // Set that the min treshold has been reached       
        }     
      }else{                                                                    // If user sent to much eth       
        uint maxContribution = maxEthToRaise - totalEthRaised;                  // Calculate maximum contribution       
        participantContribution[msg.sender] += maxContribution;                 // Add maximum contribution to account      
        totalEthRaised += maxContribution;  
        valusTokenContract.mintTokens(msg.sender, getValusTokenIssuance(block.number, maxContribution));
        uint toReturn = msg.value - maxContribution;                            // Calculate how much should be returned       
        crowdsaleHasSucessfulyEnded = true;                                     // Set that Crowdsale has successfully ended    
        CrowdsaleHardCapReached(block.number);
        hardCapReached = true;
        CrowdsaleEndedSuccessfuly(block.number, totalEthRaised);      
        if(!msg.sender.send(toReturn)){                                        // Refund the balance that is over the cap         
          ErrorSendingETH(msg.sender, toReturn);                               // Raise event for manual return if transaction throws       
        }     
      }     
    }
    
    /* Users can claim ETH by themselves if they want to in case of ETH failure */   
    function claimEthIfFailed(){    
      if (block.number <= endBlock || totalEthRaised >= minEthToRaise) throw; // Check if Crowdsale has failed    
      if (participantContribution[msg.sender] == 0) throw;                    // Check if user has participated     
      if (hasClaimedEthWhenFail[msg.sender]) throw;                           // Check if this account has already claimed ETH    
      uint256 ethContributed = participantContribution[msg.sender];           // Get participant ETH Contribution     
      hasClaimedEthWhenFail[msg.sender] = true;     
      if (!msg.sender.send(ethContributed)){      
        ErrorSendingETH(msg.sender, ethContributed);                          // Raise event if send failed, solve manually     
      }   
    } 

    /* Owner can return eth for multiple users in one call */  
    function batchReturnEthIfFailed(uint256 _numberOfReturns) onlyOwner{    
      if (block.number < endBlock || totalEthRaised >= minEthToRaise) throw;    // Check if Crowdsale failed  
      address currentParticipantAddress;    
      uint256 contribution;
      for (uint cnt = 0; cnt < _numberOfReturns; cnt++){      
        currentParticipantAddress = participantIndex[lastEthReturnIndex];       // Get next account       
        if (currentParticipantAddress == 0x0) return;                           // Check if participants were reimbursed      
        if (!hasClaimedEthWhenFail[currentParticipantAddress]) {                // Check if user has manually recovered ETH         
          contribution = participantContribution[currentParticipantAddress];    // Get accounts contribution        
          hasClaimedEthWhenFail[msg.sender] = true;                             // Set that user got his ETH back         
          if (!currentParticipantAddress.send(contribution)){                   // Send fund back to account          
             ErrorSendingETH(currentParticipantAddress, contribution);           // Raise event if send failed, resolve manually         
          }       
        }       
        lastEthReturnIndex += 1;    
      }   
    }
      
    /* Owner sets new address of escrow */
    function changeMultisigAddress(address _newAddress) onlyOwner {     
      multisigAddress = _newAddress;
    } 
    
    /* Show how many participants was */
    function participantCount() constant returns(uint){
      return nextFreeParticipantIndex;
    }

    /* Owner can claim reserved tokens on the end of crowsale */  
    function claimTeamTokens(address _to) onlyOwner{     
      if (!crowdsaleHasSucessfulyEnded) throw; 
      if (ownerHasClaimedTokens) throw;
        
      valusTokenContract.mintTokens(_to, valusTokenContract.totalSupply() * 49/51); /* 51% Crowdsale - 49% VALUS */
      ownerHasClaimedTokens = true;
    } 
      
    /* Set token contract where mints will be done (tokens will be issued) */  
    function setTokenContract(address _valusTokenContractAddress) onlyOwner {     
      valusTokenContract = IValusToken(_valusTokenContractAddress);   
    }   
       
    function getValusTokenIssuance(uint256 _blockNumber, uint256 _ethSent) constant returns(uint){
      if (_blockNumber >= startBlock && _blockNumber < startBlock + blocksInADay * 2) return _ethSent * 3882;
      if (_blockNumber >= startBlock + blocksInADay * 2 && _blockNumber < startBlock + blocksInADay * 7) return _ethSent * 3667; 
      if (_blockNumber >= startBlock + blocksInADay * 7 && _blockNumber < startBlock + blocksInADay * 14) return _ethSent * 3511; 
      if (_blockNumber >= startBlock + blocksInADay * 14 && _blockNumber < startBlock + blocksInADay * 21) return _ethSent * 3402; 
      if (_blockNumber >= startBlock + blocksInADay * 21 ) return _ethSent * 3300;
    }
    
    /* Withdraw funds from contract */  
    function withdrawEther() onlyOwner{     
      if (this.balance == 0) throw;                                            // Check if there is balance on the contract     
      if (totalEthRaised < minEthToRaise) throw;                               // Check if minEthToRaise treshold is exceeded     
          
      if(multisigAddress.send(this.balance)){}                                 // Send the contract's balance to multisig address   
    }

    function endCrowdsale() onlyOwner{
      if (totalEthRaised < minEthToRaise) throw;
      if (block.number < endBlock) throw;
      crowdsaleHasSucessfulyEnded = true;
      CrowdsaleEndedSuccessfuly(block.number, totalEthRaised);
    }
    
    
    function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner{
    IERC20Token(_tokenAddress).transfer(_to, _amount);
    }
    /* Getters */     
    
    function getVlsTokenAddress() constant returns(address _tokenAddress){    
      return address(valusTokenContract);   
    }   
    
    function crowdsaleInProgress() constant returns (bool answer){    
      return crowdsaleHasStarted && !crowdsaleHasSucessfulyEnded;   
    }   
    
    function participantContributionInEth(address _querryAddress) constant returns (uint256 answer){    
      return participantContribution[_querryAddress];   
    }
    
    /* Withdraw remaining balance to manually return where contract send has failed */  
    function withdrawRemainingBalanceForManualRecovery() onlyOwner{     
      if (this.balance == 0) throw;                                         // Check if there is balance on the contract    
      if (block.number < endBlock) throw;                                   // Check if Crowdsale failed    
      if (participantIndex[lastEthReturnIndex] != 0x0) throw;               // Check if all the participants have been reimbursed     
      if (multisigAddress.send(this.balance)){}                             // Send remainder so it can be manually processed   
    }
}