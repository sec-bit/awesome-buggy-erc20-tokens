pragma solidity ^0.4.19;

/* TODO: Add reporting mechanism to punish revealing votes off-chain either on purpose or by using weak salt for computing vote commit hash */


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}


contract CryptoTask is Ownable {
   
    uint MAX_UINT32 = 4294967295;
    uint MIN_TASK_VALUE = 200000000000000000000;
    uint CLIENT_TIME_TO_DECIDE = 3 days;
    uint VOTING_PERIOD = 5 days;
    /*uint public MIN_TASK_VALUE = 2000000000000000000;
    uint public CLIENT_TIME_TO_DECIDE = 15 minutes;
    uint public VOTING_PERIOD = 15 minutes;*/
    
    struct Task {
        address client;
        address fl;
        uint taskValue;
        uint workTime;
        uint applyTime;
        uint solutionSubmittedTime;
        uint disputeStartedTime;
        bytes32 blockHash;
        mapping(address => bytes32) voteCommits;
        mapping(uint32 => uint32) votes;
        mapping(uint32 => address) voters;
        uint32 votesTotal;
        uint32 votesClient;
        uint32 votesFl;        
        uint32 stage;
        uint prev;
        uint next;
    }
    //due to stack depth error not everything could be fitted to the struct
    mapping(uint => string) public titles;
    mapping(uint => string) public descriptions;
    mapping(uint => string) public solutions;
    mapping(uint => uint) public disputeBlockNos;
    
    
    ERC20 public tokenContract = ERC20(0x4545750F39aF6Be4F237B6869D4EccA928Fd5A85);
    
    //owner can prevent new task submissions if platform is to be moved to a new contract
    //apart from this and airdrops, owner has no other privileges
    bool public migrating;
    mapping(address => uint32) public ADs;
    
    mapping(uint => Task) public tasks;
    uint public tasksSize;
    uint public lastTaskIndex;
    mapping(address => uint) public stakes;
    mapping(address => uint) public lastStakings;
    uint public totalStake;
    
    
    function setMigrating(bool willMigrate) onlyOwner {
        migrating = willMigrate;
    }
    
    function setMinTaskValue(uint minTaskValue) onlyOwner {
        MIN_TASK_VALUE = minTaskValue;
    }
    
    function postTask(string title, string description, uint taskValue, uint workTime) {
        require(!migrating && taskValue > MIN_TASK_VALUE);
        
        tasksSize++;
        
        tasks[tasksSize].client = msg.sender;
        titles[tasksSize] = title;
        tasks[tasksSize].workTime = workTime;
        tasks[tasksSize].taskValue = taskValue;
        descriptions[tasksSize] = description;
        
        //linked list connecting
        tasks[tasksSize].prev = lastTaskIndex;
        if(lastTaskIndex > 0) {
            tasks[lastTaskIndex].next = tasksSize;
        }
        lastTaskIndex = tasksSize;
        
        tokenContract.transferFrom(msg.sender, this, taskValue + taskValue/10);
    }
    
    function applyForTask(uint taskID) {
        require(tasks[taskID].stage == 0 && tasks[taskID].client != address(0));
        tasks[taskID].fl = msg.sender;
        tasks[taskID].applyTime = now;
        tasks[taskID].stage = 1;
        tokenContract.transferFrom(msg.sender, this, tasks[taskID].taskValue/10);
    }
    
    function submitSolution(uint taskID, string solution) {
        require(tasks[taskID].stage == 1 && msg.sender == tasks[taskID].fl && now < tasks[taskID].applyTime + tasks[taskID].workTime);
        solutions[taskID] = solution;
        tasks[taskID].solutionSubmittedTime = now;
        tasks[taskID].stage = 2;
    }
    
    function startDispute(uint taskID) {
        require(tasks[taskID].stage == 2 && tasks[taskID].client == msg.sender && now < tasks[taskID].solutionSubmittedTime + CLIENT_TIME_TO_DECIDE);
        disputeBlockNos[taskID] = block.number;
        tasks[taskID].stage = 3;
    }
    
    //commitDispute and startDispute need to be separate stages to ensure blockHash randomness
    function commitDispute(uint taskID) {
        require(tasks[taskID].stage == 3 && tasks[taskID].client == msg.sender && now < tasks[taskID].solutionSubmittedTime + CLIENT_TIME_TO_DECIDE && block.number > disputeBlockNos[taskID]+5);
        tasks[taskID].blockHash = block.blockhash(disputeBlockNos[taskID]);
        tasks[taskID].disputeStartedTime = now;
        tasks[taskID].stage = 4;
    }
    
    function commitVote(uint taskID, bytes32 voteHash) {
        require(tasks[taskID].stage == 4 && now < tasks[taskID].disputeStartedTime + VOTING_PERIOD && tasks[taskID].voteCommits[msg.sender] == bytes32(0));
        tasks[taskID].voteCommits[msg.sender] = voteHash;
    }
    
    function revealVote(uint taskID, uint8 v, bytes32 r, bytes32 s, uint32 vote, bytes32 salt) {
        //100 sec buffer between commit and reveal vote stages
        require(tasks[taskID].stage == 4 && now > tasks[taskID].disputeStartedTime + VOTING_PERIOD+100 && now < tasks[taskID].disputeStartedTime + 2*VOTING_PERIOD && tasks[taskID].voteCommits[msg.sender] != bytes32(0));
        //check that revealed signature matches public key, that stake is high enough (selection likelihood proportional to stake), that tokens haven't been moved around since dispute started to prevent biasing the selection likelihood, that revealed vote matches the vote commit
        if(ecrecover(keccak256(taskID, tasks[taskID].blockHash), v, r, s) == msg.sender && (10*MAX_UINT32)/(uint(s) % (MAX_UINT32+1)) > totalStake/stakes[msg.sender] && lastStakings[msg.sender] < tasks[taskID].disputeStartedTime && keccak256(salt, vote) == tasks[taskID].voteCommits[msg.sender]) {
            if(vote==1) {
                tasks[taskID].votesClient++;
            } else if(vote==2) {
                tasks[taskID].votesFl++;
            } else {
                throw;
            }
            tasks[taskID].votes[tasks[taskID].votesTotal] = vote;
            tasks[taskID].voters[tasks[taskID].votesTotal] = msg.sender;
            tasks[taskID].votesTotal++;
            //prevent multiple revealing of same vote
            tasks[taskID].voteCommits[msg.sender] = bytes32(0);
        }
    }
    
    function finalizeTask(uint taskID) {
        uint taskValueTenth = tasks[taskID].taskValue/10;
        uint reviewerReward;
        uint32 i;
        
        //cancel posted task no has applied for yet
        if(tasks[taskID].stage == 0 && msg.sender == tasks[taskID].client) {
            tokenContract.transfer(tasks[taskID].client, tasks[taskID].taskValue + taskValueTenth);
            tasks[taskID].stage = 5;
        }
        //accept freelancer's solution
        else if(tasks[taskID].stage == 2 && msg.sender == tasks[taskID].client) {
            tokenContract.transfer(tasks[taskID].fl, tasks[taskID].taskValue + taskValueTenth);
            tokenContract.transfer(tasks[taskID].client, taskValueTenth);
            tasks[taskID].stage = 6;
        }
        //client didn't review freelancer's solution on time, treated as solution accepted
        else if((tasks[taskID].stage == 2 || tasks[taskID].stage == 3) && now > tasks[taskID].solutionSubmittedTime + CLIENT_TIME_TO_DECIDE) {
            tokenContract.transfer(tasks[taskID].fl, tasks[taskID].taskValue + 2*taskValueTenth);
            tasks[taskID].stage = 7;
        }
        //dispute was started and reviewers voted in freelancer's favour
        else if(tasks[taskID].stage == 4 && tasks[taskID].votesFl > tasks[taskID].votesClient && now > tasks[taskID].disputeStartedTime + 2*VOTING_PERIOD) {
            tokenContract.transfer(tasks[taskID].fl, tasks[taskID].taskValue + taskValueTenth);
            reviewerReward = taskValueTenth / tasks[taskID].votesFl;
            //distribute reviewer rewards
            for(i=0; i < tasks[taskID].votesTotal; i++) {
                if(tasks[taskID].votes[i] == 2) {
                    tokenContract.transfer(tasks[taskID].voters[i], reviewerReward);
                }
            }
            tasks[taskID].stage = 8;
        }
        //freelancer didn't submit solution on time, client gets freelancer's escrow
        else if(tasks[taskID].stage == 1 && now > tasks[taskID].applyTime + tasks[taskID].workTime) {
            tokenContract.transfer(tasks[taskID].client, tasks[taskID].taskValue + 2*taskValueTenth);
            tasks[taskID].stage = 9;
        }
        //dispute was started and reviewers voted in client's favour
        else if(tasks[taskID].stage == 4 && tasks[taskID].votesClient >= tasks[taskID].votesFl && now > tasks[taskID].disputeStartedTime + 2*VOTING_PERIOD) {
            if(tasks[taskID].votesTotal == 0) {
                tokenContract.transfer(tasks[taskID].client, tasks[taskID].taskValue + taskValueTenth);
                tokenContract.transfer(tasks[taskID].fl, taskValueTenth);
            } else {
                tokenContract.transfer(tasks[taskID].client, tasks[taskID].taskValue + taskValueTenth);
                reviewerReward = taskValueTenth / tasks[taskID].votesClient;
                //distribute reviewer rewards
                for(i=0; i < tasks[taskID].votesTotal; i++) {
                    if(tasks[taskID].votes[i] == 1) {
                        tokenContract.transfer(tasks[taskID].voters[i], reviewerReward);
                    }
                }
            }
            tasks[taskID].stage = 10;
        } else {
            throw;
        }
        
        //connect linked list after the task removal
        if(tasks[taskID].prev > 0) {
            tasks[tasks[taskID].prev].next = tasks[taskID].next;
        }
        if(tasks[taskID].next > 0) {
            tasks[tasks[taskID].next].prev = tasks[taskID].prev;
        }
        if(taskID == lastTaskIndex) {
            lastTaskIndex = tasks[taskID].prev;
        }
        
        //if users who received airdrops
        if(ADs[tasks[taskID].client] > 0) {
            ADs[tasks[taskID].client]++;
        }
        if(ADs[tasks[taskID].fl] > 0) {
            ADs[tasks[taskID].fl]++;
        }
    }
    
    
    function addStake(uint value) {
        if(value > 0) {
            stakes[msg.sender] += value;
            lastStakings[msg.sender] = now;
            totalStake += value;
            tokenContract.transferFrom(msg.sender, this, value);
        }
    }
    
    function withdrawStake(uint value) {
        if(value > 0 && stakes[msg.sender] >= value) {
            //received airdrop but completed less than 10 tasks
            if(ADs[msg.sender] > 0 && ADs[msg.sender] < 10) {
                throw;
            }
            stakes[msg.sender] -= value;
            lastStakings[msg.sender] = now;
            totalStake -= value;
            tokenContract.transfer(msg.sender, value);
        }
    }
    
    //airdrop
    function addStakeAD(uint value, address recipient) onlyOwner {
        //prevent owner from adding a small value to set regular user to airdropped user
        if(value > 0 && value > 1000*stakes[recipient]) {
            stakes[recipient] += value;
            lastStakings[recipient] = now;
            totalStake += value;
            ADs[recipient]++;
            tokenContract.transferFrom(msg.sender, this, value);
        }
    }
    
    
    function getVoteCommit(uint taskID, address commiter) constant returns (bytes32 commit) {
        return tasks[taskID].voteCommits[commiter];
    }
    
    function getVote(uint taskID, uint32 index) constant returns (uint32 vote) {
        return tasks[taskID].votes[index];
    }
    
    function getVoter(uint taskID, uint32 index) constant returns (address voter) {
        return tasks[taskID].voters[index];
    }
    
}