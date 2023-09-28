pragma solidity ^0.4.16;

contract SafeMath {
     function safeMul(uint a, uint b) internal returns (uint) {
          uint c = a * b;
          assert(a == 0 || c / a == b);
          return c;
     }

     function safeSub(uint a, uint b) internal returns (uint) {
          assert(b <= a);
          return a - b;
     }

     function safeAdd(uint a, uint b) internal returns (uint) {
          uint c = a + b;
          assert(c>=a && c>=b);
          return c;
     }
}

// ERC20 standard
contract StdToken {
     function transfer(address, uint256) returns(bool);
     function transferFrom(address, address, uint256) returns(bool);
     function balanceOf(address) constant returns (uint256);
     function approve(address, uint256) returns (bool);
     function allowance(address, address) constant returns (uint256);
}

contract GoldmintVote1 {
// Fields:
     address public creator = 0x0;
     bool public stopped = false;
     StdToken mntpToken; 

     mapping(address => bool) isVoted;
     mapping(address => bool) votes;
     uint public totalVotes = 0;
     uint public votedYes = 0;

// Functions:
     function GoldmintVote1(address _mntpContractAddress) {
          require(_mntpContractAddress!=0);

          creator = msg.sender;
          mntpToken = StdToken(_mntpContractAddress);
     }

     function vote(bool _answer) public {
          require(!stopped);

          // 1 - should be Goldmint MNTP token holder 
          // with >1 MNTP token balance
          uint256 balance = mntpToken.balanceOf(msg.sender);
          require(balance>=10 ether);

          // 2 - can vote only once 
          require(isVoted[msg.sender]==false);

          // save vote
          votes[msg.sender] = _answer;
          isVoted[msg.sender] = true;

          ++totalVotes;
          if(_answer){
               ++votedYes;
          }
     }

     function getVoteBy(address _a) public constant returns(bool) {
          require(isVoted[_a]==true);
          return votes[_a];
     }

     function stop() public {
          require(msg.sender==creator);
          stopped = true;
     }
}