pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract EthereumBlack {
    // Public variables of ETBT
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public funds;
    address public director;
    bool public saleClosed;
    bool public directorLock;
    uint256 public claimAmount;
    uint256 public payAmount;
    uint256 public feeAmount;
    uint256 public epoch;
    uint256 public retentionMax;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public buried;
    mapping (address => uint256) public claimed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Burn(address indexed _from, uint256 _value);
    
    event Bury(address indexed _target, uint256 _value);
    
    event Claim(address indexed _target, address indexed _payout, address indexed _fee);

    function EthereumBlack() public {
        director = msg.sender;
        name = "Ethereum Black Token";
        symbol = "ETBT";
        decimals = 18;
        saleClosed = false;
        directorLock = false;
        funds = 0;
        totalSupply = 0;
        
        // Token Sale: (50%)
        totalSupply += 1750000 * 10 ** uint256(decimals);
        
        // Reserves: (37%)
        totalSupply += 1295000 * 10 ** uint256(decimals);
        
        // Marketing & Community outreach: (8%)
        totalSupply += 280000 * 10 ** uint256(decimals);
		
        // Team: (5%)
        totalSupply += 175000 * 10 ** uint256(decimals);

		// 500000 ETBT Reserved for donate
        
        // Assign reserved ETBT supply to the director
        balances[director] = totalSupply;
        
        // Define default values for EtherBlack functions
        claimAmount = 5 * 10 ** (uint256(decimals) - 1);
        payAmount = 4 * 10 ** (uint256(decimals) - 1);
        feeAmount = 1 * 10 ** (uint256(decimals) - 1);
        
        // Seconds in a year
        epoch = 31536000;
        
        retentionMax = 40 * 10 ** uint256(decimals);
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    modifier onlyDirector {
        // Director can lock themselves out to complete decentralization of EtherBlack network
        // An alternative is that another smart contract could become the decentralized director
        require(!directorLock);
        
        // Only the director is permitted
        require(msg.sender == director);
        _;
    }
    
    modifier onlyDirectorForce {
        // Only the director is permitted
        require(msg.sender == director);
        _;
    }
    

    function transferDirector(address newDirector) public onlyDirectorForce {
        director = newDirector;
    }
    

    function withdrawFunds() public onlyDirectorForce {
        director.transfer(this.balance);
    }

	
    function selfLock() public payable onlyDirector {
        // The sale must be closed before the director gets locked out
        require(saleClosed);
        
        // Prevents accidental lockout
        require(msg.value == 10 ether);
        
        // Permanently lock out the director
        directorLock = true;
    }
    
    function amendClaim(uint8 claimAmountSet, uint8 payAmountSet, uint8 feeAmountSet, uint8 accuracy) public onlyDirector returns (bool success) {
        require(claimAmountSet == (payAmountSet + feeAmountSet));
        
        claimAmount = claimAmountSet * 10 ** (uint256(decimals) - accuracy);
        payAmount = payAmountSet * 10 ** (uint256(decimals) - accuracy);
        feeAmount = feeAmountSet * 10 ** (uint256(decimals) - accuracy);
        return true;
    }
    

    function amendEpoch(uint256 epochSet) public onlyDirector returns (bool success) {
        // Set the epoch
        epoch = epochSet;
        return true;
    }
    

    function amendRetention(uint8 retentionSet, uint8 accuracy) public onlyDirector returns (bool success) {
        // Set retentionMax
        retentionMax = retentionSet * 10 ** (uint256(decimals) - accuracy);
        return true;
    }
    

    function closeSale() public onlyDirector returns (bool success) {
        // The sale must be currently open
        require(!saleClosed);
        
        // Lock the crowdsale
        saleClosed = true;
        return true;
    }


    function openSale() public onlyDirector returns (bool success) {
        // The sale must be currently closed
        require(saleClosed);
        
        // Unlock the crowdsale
        saleClosed = false;
        return true;
    }
    

    function bury() public returns (bool success) {
        // The address must be previously unburied
        require(!buried[msg.sender]);
        
        // An address must have at least claimAmount to be buried
        require(balances[msg.sender] >= claimAmount);
        
        // Prevent addresses with large balances from getting buried
        require(balances[msg.sender] <= retentionMax);
        
        // Set buried state to true
        buried[msg.sender] = true;
        
        // Set the initial claim clock to 1
        claimed[msg.sender] = 1;
        
        // Execute an event reflecting the change
        Bury(msg.sender, balances[msg.sender]);
        return true;
    }
    

    function claim(address _payout, address _fee) public returns (bool success) {
        // The claimed address must have already been buried
        require(buried[msg.sender]);
        
        // The payout and fee addresses must be different
        require(_payout != _fee);
        
        // The claimed address cannot pay itself
        require(msg.sender != _payout);
        
        // The claimed address cannot pay itself
        require(msg.sender != _fee);
        
        // It must be either the first time this address is being claimed or atleast epoch in time has passed
        require(claimed[msg.sender] == 1 || (block.timestamp - claimed[msg.sender]) >= epoch);
        
        // Check if the buried address has enough
        require(balances[msg.sender] >= claimAmount);
        
        // Reset the claim clock to the current block time
        claimed[msg.sender] = block.timestamp;
        
        // Save this for an assertion in the future
        uint256 previousBalances = balances[msg.sender] + balances[_payout] + balances[_fee];
        
        // Remove claimAmount from the buried address
        balances[msg.sender] -= claimAmount;
        
        // Pay the website owner that invoked the web node that found the ETBT seed key
        balances[_payout] += payAmount;
        
        // Pay the broker node that unlocked the ETBT
        balances[_fee] += feeAmount;
        
        // Execute events to reflect the changes
        Claim(msg.sender, _payout, _fee);
        Transfer(msg.sender, _payout, payAmount);
        Transfer(msg.sender, _fee, feeAmount);
        
        // Failsafe logic that should never be false
        assert(balances[msg.sender] + balances[_payout] + balances[_fee] == previousBalances);
        return true;
    }
    
    /**
     * Crowdsale function
     */
    function () public payable {
        // Check if crowdsale is still active
        require(!saleClosed);
        
        // Minimum amount is 1 finney
        require(msg.value >= 1 finney);
        
        // Price is 1 ETH = 10000 ETBT
        uint256 amount = msg.value * 10000;
        
        // totalSupply limit is 4 million ETBT
        require(totalSupply + amount <= (4000000 * 10 ** uint256(decimals)));
        
        // Increases the total supply
        totalSupply += amount;
        
        // Adds the amount to the balance
        balances[msg.sender] += amount;
        
        // Track ETH amount raised
        funds += msg.value;
        
        // Execute an event reflecting the change
        Transfer(this, msg.sender, amount);
    }

    function _transfer(address _from, address _to, uint _value) internal {
        // Sending addresses cannot be buried
        require(!buried[_from]);
        
        // If the receiving address is buried, it cannot exceed retentionMax
        if (buried[_to]) {
            require(balances[_to] + _value <= retentionMax);
        }
        
        require(_to != 0x0);
        
        require(balances[_from] >= _value);
        
        require(balances[_to] + _value > balances[_to]);
        
        uint256 previousBalances = balances[_from] + balances[_to];
        
        balances[_from] -= _value;
        
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        
        assert(balances[_from] + balances[_to] == previousBalances);
    }


    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Check allowance
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool success) {
        // Buried addresses cannot be approved
        require(!buried[msg.sender]);
        
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


    function burn(uint256 _value) public returns (bool success) {
        // Buried addresses cannot be burnt
        require(!buried[msg.sender]);
        
        // Check if the sender has enough
        require(balances[msg.sender] >= _value);
        
        // Subtract from the sender
        balances[msg.sender] -= _value;
        
        // Updates totalSupply
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }


    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        // Buried addresses cannot be burnt
        require(!buried[_from]);
        
        // Check if the targeted balance is enough
        require(balances[_from] >= _value);
        
        // Check allowance
        require(_value <= allowance[_from][msg.sender]);
        
        // Subtract from the targeted balance
        balances[_from] -= _value;
        
        // Subtract from the sender's allowance
        allowance[_from][msg.sender] -= _value;
        
        // Update totalSupply
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}