pragma solidity 0.4.19;


contract Token {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);

    function issue(address _to, uint _value) public returns (bool);
    function transferOwnership(address _newOwner) public;
}


contract Registry {
    function updateFee(uint256 _fee) public;
    function transferOwnership(address _newOwner) public;
}


contract DAO {
    function payFee() public payable;
}


contract TokenRecipient {
    address public receiver = 0xD86b17d42E4385293B961BE704602eDF0f4b3eB8;

    event receivedEther(address sender, uint amount);

    // Dev donations
    function () public payable {
        receiver.transfer(msg.value);
        receivedEther(msg.sender, msg.value);
    }

    function payFee() public payable {
        receivedEther(msg.sender, msg.value);
    }

    function withdrawTokenBalance(uint256 _value, address _token) public {
        Token erc20 = Token(_token);
        require(erc20.transfer(receiver, _value));
    }

    function withdrawFullTokenBalance(address _token) public {
        Token erc20 = Token(_token);
        require(erc20.transfer(receiver, erc20.balanceOf(this)));
    }

}


/**
 * The shareholder association contract itself
 */
contract EngravedDAO is TokenRecipient {

    event ProposalAdded(uint proposalID);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, uint result, uint quorum, bool active);
    event ChangeOfRules(uint newMinimumQuorum, uint newDebatingPeriodInMinutes, address newEgcToken);

    uint public dividend;

    uint public minimumQuorum;
    uint public debatingPeriodInMinutes;
    Proposal[] public proposals;
    uint public numProposals;

    uint public minAmount;

    Token public egcToken;
    Token public egrToken;

    Registry public ownership;
    Registry public integrity;

    // Payment dates
    uint256 public withdrawStart;

    // EGC stored balances for dividends
    mapping (address => uint256) internal lockedBalances;

    enum ProposalType {
        TransferOwnership,
        ChangeOwnershipFee,
        ChangeIntegrityFee
    }

    struct Proposal {
        string description;
        uint votingDeadline;
        bool executed;
        bool proposalPassed;
        uint numberOfVotes;
        Vote[] votes;
        mapping (address => bool) voted;
        ProposalType proposalType;
        uint newFee;
        address newDao;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }

    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyShareholders {
        require(egcToken.balanceOf(msg.sender) > 0);
        _;
    }

    /**
     * Constructor function
     *
     * First time setup
     */
    function EngravedDAO(
        address _ownershipAddress,
        address _integrityAddress,
        address _egrTokenAddress,
        address _egcTokenAddress,
        uint _minimumQuorum,
        uint _debatingPeriodInMinutes,
        uint _minAmount
    ) public {
        ownership = Registry(_ownershipAddress);
        integrity = Registry(_integrityAddress);
        egrToken = Token(_egrTokenAddress);
        egcToken = Token(_egcTokenAddress);

        withdrawStart = block.timestamp;

        if (_minimumQuorum == 0) {
            _minimumQuorum = 1;
        }

        minimumQuorum = _minimumQuorum;
        debatingPeriodInMinutes = _debatingPeriodInMinutes;
        ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, egcToken);

        minAmount = _minAmount;
    }

    function withdrawDividends() public {
        // Locked balance is positive
        require(lockedBalances[msg.sender] > 0);

        // On time
        require(block.timestamp >= withdrawStart + 3 days && block.timestamp < withdrawStart + 1 weeks);

        uint256 locked = lockedBalances[msg.sender];
        lockedBalances[msg.sender] = 0;

        uint256 earnings = dividend * locked / 1e18;

        // Send tokens back to the stakeholder
        egcToken.transfer(msg.sender, locked);
        msg.sender.transfer(earnings);
    }

    function unlockFunds() public {
        // Locked balance is positive
        require(lockedBalances[msg.sender] > 0);

        uint256 locked = lockedBalances[msg.sender];
        lockedBalances[msg.sender] = 0;

        // Send tokens back to the stakeholder
        egcToken.transfer(msg.sender, locked);
    }

    // Lock funds for dividends payment
    function lockFunds(uint _value) public {
        // Three days before the payment date
        require(block.timestamp >= withdrawStart && block.timestamp < withdrawStart + 3 days);

        lockedBalances[msg.sender] += _value;

        require(egcToken.allowance(msg.sender, this) >= _value);
        require(egcToken.transferFrom(msg.sender, this, _value));
    }

    function newOwnershipFeeProposal(
        uint256 _newFee,
        string _jobDescription
    )
        public onlyShareholders
        returns (uint proposalID)
    {
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.description = _jobDescription;
        p.votingDeadline = block.timestamp + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        p.proposalType = ProposalType.ChangeOwnershipFee;
        p.newFee = _newFee;
        ProposalAdded(proposalID);
        numProposals = proposalID+1;

        return proposalID;
    }

    function newIntegrityFeeProposal(
        uint256 _newFee,
        string _jobDescription
    )
        public onlyShareholders
        returns (uint proposalID)
    {
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.description = _jobDescription;
        p.votingDeadline = block.timestamp + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        p.proposalType = ProposalType.ChangeIntegrityFee;
        p.newFee = _newFee;
        ProposalAdded(proposalID);
        numProposals = proposalID+1;

        return proposalID;
    }

    function newTransferProposal(
        address _newDao,
        string _jobDescription
    )
        public onlyShareholders
        returns (uint proposalID)
    {
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.description = _jobDescription;
        p.votingDeadline = block.timestamp + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        p.proposalType = ProposalType.TransferOwnership;
        p.newDao = _newDao;
        ProposalAdded(proposalID);
        numProposals = proposalID+1;

        return proposalID;
    }

    /**
     * Log a vote for a proposal
     *
     * Vote `supportsProposal? in support of : against` proposal #`proposalNumber`
     *
     * @param proposalNumber number of proposal
     * @param supportsProposal either in favor or against it
     */
    function vote(
        uint proposalNumber,
        bool supportsProposal
    )
        public onlyShareholders
        returns (uint voteID)
    {
        Proposal storage p = proposals[proposalNumber];
        require(p.voted[msg.sender] != true);

        voteID = p.votes.length++;
        p.votes[voteID] = Vote({inSupport: supportsProposal, voter: msg.sender});
        p.voted[msg.sender] = true;
        p.numberOfVotes = voteID + 1;
        Voted(proposalNumber, supportsProposal, msg.sender);
        return voteID;
    }

    /**
     * Finish vote
     *
     * Count the votes proposal #`proposalNumber` and execute it if approved
     *
     * @param proposalNumber proposal number
     */
    function executeProposal(uint proposalNumber) public {
        Proposal storage p = proposals[proposalNumber];

        require(block.timestamp > p.votingDeadline && !p.executed);

        // ...then tally the results
        uint quorum = 0;
        uint yea = 0;
        uint nay = 0;

        for (uint i = 0; i < p.votes.length; ++i) {
            Vote storage v = p.votes[i];
            uint voteWeight = egcToken.balanceOf(v.voter);
            quorum += voteWeight;
            if (v.inSupport) {
                yea += voteWeight;
            } else {
                nay += voteWeight;
            }
        }

        require(quorum >= minimumQuorum); // Check if a minimum quorum has been reached

        if (yea > nay) {
            // Proposal passed; execute the transaction

            p.executed = true;

            if (p.proposalType == ProposalType.ChangeOwnershipFee) {
                changeOwnershipFee(p.newFee);
            } else if (p.proposalType == ProposalType.ChangeIntegrityFee) {
                changeIntegrityFee(p.newFee);
            } else if (p.proposalType == ProposalType.TransferOwnership) {
                transferOwnership(p.newDao);
            }

            p.proposalPassed = true;
        } else {
            // Proposal failed
            p.proposalPassed = false;
        }

        // Fire Events
        ProposalTallied(proposalNumber, yea - nay, quorum, p.proposalPassed);
    }

    function startIncomeDistribution() public {
        require(withdrawStart + 90 days < block.timestamp);

        uint256 totalSupply = egcToken.totalSupply();
        require(totalSupply > 0);

        // At least 1 wei per XEG so dividend > 0
        dividend = this.balance * 1e18 / totalSupply;
        require(dividend >= minAmount);

        withdrawStart = block.timestamp;
    }

    function tokenExchange(uint _amount) public {
        require(egrToken.allowance(msg.sender, this) >= _amount);
        require(egrToken.transferFrom(msg.sender, 0x0, _amount));
        // 100 XEG (18 decimals) per EGR (3 decimals)
        require(egcToken.issue(msg.sender, _amount * 1e17));
    }

    function changeOwnershipFee(uint256 _newFee) private {
        ownership.updateFee(_newFee);
    }

    function changeIntegrityFee(uint256 _newFee) private {
        integrity.updateFee(_newFee);
    }

    function transferOwnership(address _newDao) private {
        require(block.timestamp > withdrawStart + 1 weeks);

        // Transfer all ether to the new DAO
        DAO(_newDao).payFee.value(this.balance)();

        // Transfer ownership of the owned contracts
        ownership.transferOwnership(_newDao);
        integrity.transferOwnership(_newDao);
        egrToken.transferOwnership(_newDao);
        egcToken.transferOwnership(_newDao);
    }

}