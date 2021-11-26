pragma solidity ^0.4.8;

contract Token {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20Token is Token {
    uint256 constant MAX_UINT256 = 2**256 - 1;
    uint256 _totalSupply;
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    function totalSupply() constant returns (uint256 totalSupply) {
         totalSupply = _totalSupply;
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract iBTCoE is ERC20Token{
    function TransferToBTCoE(address _to, uint256 _value) returns (bool success);
    function TransferToSAToE(uint256 _value) returns (bool success);
}

contract iSAToE is ERC20Token{
    function TransferToSAToE(address _to, uint256 _value) returns (bool success);
    function TransferToBTCoE(uint256 _amount) returns (bool success);
}

contract BTCoE is iBTCoE{
    
    string public constant name = "Bitcoin oE"; 
    uint8 public constant decimals = 8;
    string public constant symbol = "BTCoE";

    address public owner;
    mapping(address => bool) airDropped;
    uint256 public airDropStage = 1;
    uint256 public userCount = 0;
    
    address public satoeContract = 0x00;
    uint256 minTxFee = 0.02 ether;
    uint256 maxTxFee = 0.03 ether;
    uint256 minClaimFee = 0.003 ether;
    uint256 maxClaimFee = 0.004 ether;
    uint256 public maxSupply;
    iSAToE satoe;
    bool public satoeLocked = false;
    
    function BTCoE()
    {
        maxSupply  = 21000000 * 10**8;
        _totalSupply = maxSupply;
        
        owner = msg.sender;
        balances[owner] = maxSupply;
        airDropped[owner] = true;
    }
    
    modifier forOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function() payable external
    {
        require (block.number >= 4574200);
        require (airDropStage <= 10);
        require (!airDropped[msg.sender]);
        require(msg.value >= minTxFee);
        require(msg.value <= maxTxFee);
        
        uint256 airDropReward = (2048*10**8)/(2**(airDropStage-1));
        require (balances[owner] >= airDropReward);
        
        balances[owner] -= airDropReward;
        balances[msg.sender] += airDropReward;
        Transfer(owner, msg.sender, airDropReward);
        airDropped[msg.sender] = true;
        
        userCount ++;
        if (userCount == 256*airDropStage)
        {
            userCount = 0;
            airDropStage++;
        }
    }
    //------------------------------------------------------------------------
    function SetSAToEContract(address _address) forOwner
    {
        require (_address != 0x0);
        require (!satoeLocked);
        satoeContract = _address;
        satoe = iSAToE(satoeContract);
    }
    function LockSAToE() forOwner
    {
        require (satoeContract != 0x00);
        satoeLocked = true;
    }
    function TransferToBTCoE(address _to, uint256 _value) returns (bool success) 
    {
        require (msg.sender == satoeContract);
        require (balances[satoeContract] >= _value);
        
        balances[satoeContract] -= _value;
        balances[_to] += _value;
        _totalSupply = maxSupply - balances[satoeContract];
        Transfer(satoeContract, _to, _value);
        return true;
    }
    function TransferToSAToE(uint256 _value) returns (bool success)
    {
        require (satoeContract != 0x00);
        require (_value <= balances[msg.sender]);
        uint256 realMicroSAToE = _value * 10**6;
        
        balances[msg.sender] -= _value;
        balances[satoeContract] += _value;
        _totalSupply = maxSupply - balances[satoeContract];
        Transfer(msg.sender, satoeContract, _value);
        require (satoe.TransferToSAToE(msg.sender, realMicroSAToE));
        return true;
    }
    function balanceOf(address _owner) constant returns (uint256 balance) 
    {
        // balances[satoeContract] is locked
        // check to assure match total supply.
        if(_owner == satoeContract) return 0;
        return balances[_owner];
    }
    //------------------------------------------------------------------------
    function ProcessTxFee() forOwner
    {
        require (owner.send(this.balance));
    }
    function SetTxFee(uint256 minfee, uint256 maxfee) forOwner
    {
        require (minfee < maxfee);
        minTxFee = minfee;
        maxTxFee = maxfee;
    }
    function SetClaimFee(uint256 minfee, uint256 maxfee) forOwner
    {
        require (minfee < maxfee);
        minClaimFee = minfee;
        maxClaimFee = maxfee;
    }
    //------------------------------------------------------------------------
    event ClaimedSignature(address indexed ethAddress, string btcSignature);
    event DeliveredBTC(address indexed ethAddress, uint256 amount);
    bool public allowingClaimBTC = true;
    mapping(address => bool) acceptedClaimers;
    function AllowClaimBTC(bool val) forOwner
    {
        allowingClaimBTC = val;
    }
    function ClaimBTC(string fullSignature) payable
    {
        require (allowingClaimBTC);
        require (!acceptedClaimers[msg.sender]);
        require (msg.value >= minClaimFee);
        require (msg.value <= maxClaimFee);
        
        ClaimedSignature(msg.sender,fullSignature);
    }
    
    function DeliverToClaimers(address[] dests, uint256[] values) forOwner returns (uint256) 
    {
        require (dests.length == values.length);
        uint256 i = 0;
        while (i < dests.length) 
        {
            if(!acceptedClaimers[dests[i]])
            {
                transfer(dests[i], values[i]); 
                acceptedClaimers[dests[i]] = true;
                DeliveredBTC(dests[i], values[i]);
            }
            i += 1;
        }
        return(i);
    }
}