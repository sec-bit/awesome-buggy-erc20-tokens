pragma solidity ^0.4.19;

contract SMINT {
    struct Invoice {
        address beneficiary;
        uint amount;
        address payer;
    }
    
    address public owner;
    string public name = 'SMINT';
    string public symbol = 'SMINT';
    uint8 public decimals = 18;
    uint public totalSupply = 100000000000000000000000000000;
    uint public currentInvoice = 0;
    uint public lastEfficientBlockNumber;
    
    /* This creates an array with all balances */
    mapping (address => uint) public balanceOf;
    mapping (address => uint) public frozenBalanceOf;
    mapping (address => uint) public successesOf;
    mapping (address => uint) public failsOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (uint => Invoice) public invoices;
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint value);
    
    event Mine(address indexed miner, uint value, uint rewardAddition);
    event Bill(uint invoiceId);
    event Pay(uint indexed invoiceId);

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function SMINT() public {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        lastEfficientBlockNumber = block.number;
    }
    
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }
    
    /* Unfreeze not more than _value tokens */
    function _unfreezeMaxTokens(uint _value) internal {
        uint amount = frozenBalanceOf[msg.sender] > _value ? _value : frozenBalanceOf[msg.sender];
        if (amount > 0) {
            balanceOf[msg.sender] += amount;
            frozenBalanceOf[msg.sender] -= amount;
            Transfer(this, msg.sender, amount);
        }
    }
    
    function transferAndFreeze(address _to, uint _value) onlyOwner external {
        require(_to != 0x0);
        require(balanceOf[owner] >= _value);
        require(frozenBalanceOf[_to] + _value > frozenBalanceOf[_to]);
        balanceOf[owner] -= _value;
        frozenBalanceOf[_to] += _value;
        Transfer(owner, this, _value);
    }
    
    /* Send coins */
    function transfer(address _to, uint _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function bill(uint _amount) external {
        require(_amount > 0);
        invoices[currentInvoice] = Invoice({
            beneficiary: msg.sender,
            amount: _amount,
            payer: 0x0
        });
        Bill(currentInvoice);
        currentInvoice++;
    }
    
    function pay(uint _invoiceId) external {
        require(_invoiceId < currentInvoice);
        require(invoices[_invoiceId].payer == 0x0);
        _transfer(msg.sender, invoices[_invoiceId].beneficiary, invoices[_invoiceId].amount);
        invoices[_invoiceId].payer = msg.sender;
        Pay(_invoiceId);
    }
    
    /* Transfer tokens from other address */
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    /* Set allowance for other address */
    function approve(address _spender, uint _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function () external payable {
        if (msg.value > 0) {
            revert();
        }
        
        uint minedAtBlock = uint(block.blockhash(block.number - 1));
        uint minedHashRel = uint(sha256(minedAtBlock + uint(msg.sender) + block.timestamp)) % 1000000;
        uint balanceRel = (balanceOf[msg.sender] + frozenBalanceOf[msg.sender]) * 1000000 / totalSupply;
        if (balanceRel > 0) {
            uint k = balanceRel;
            if (k > 255) {
                k = 255;
            }
            k = 2 ** k;
            balanceRel = 500000 / k;
            balanceRel = 500000 - balanceRel;
            if (minedHashRel < balanceRel) {
                uint reward = 100000000000000000 + minedHashRel * 1000000000000000;
                uint rewardAddition = reward * (block.number - lastEfficientBlockNumber) * 197 / 1000000;
                reward += rewardAddition;
                balanceOf[msg.sender] += reward;
                totalSupply += reward;
                _unfreezeMaxTokens(reward);
                Transfer(0, this, reward);
                Transfer(this, msg.sender, reward);
                Mine(msg.sender, reward, rewardAddition);
                successesOf[msg.sender]++;
                lastEfficientBlockNumber = block.number;
            } else {
                Mine(msg.sender, 0, 0);
                failsOf[msg.sender]++;
            }
        } else {
            revert();
        }
    }
}