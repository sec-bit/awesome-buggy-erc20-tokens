pragma solidity ^0.4.8;

contract IProxyManagement { 
    function isProxyLegit(address _address) returns (bool){}
    function raiseTransferEvent(address _from, address _to, uint _ammount){}
    function raiseApprovalEvent(address _sender,address _spender,uint _value){}
    function dedicatedProxyAddress() constant returns (address contractAddress){}
}

contract ITokenRecipient { 
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); 
}

contract NeterContract {
    
  
    address public dev;
    address public curator;
    address public creationAddress;
    address public destructionAddress;
    uint256 public totalSupply = 0;
    bool public lockdown = false;


    string public standard = 'Neter token 1.0';
    string public name = 'Neter';
    string public symbol = 'NTR';
    uint8 public decimals = 8;


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    IProxyManagement proxyManagementContract;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Create(address _destination, uint _amount);
    event Destroy(address _destination, uint _amount);


    function NeterContract() { 
        dev = msg.sender;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) returns (uint error) {
        if(balances[msg.sender] < _amount) { return 55; }
        if(balances[_to] + _amount <= balances[_to]) { return 55; }
        if(lockdown) { return 55; }

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        createTransferEvent(true, msg.sender, _to, _amount);              
        return 0;
        
    }

    function transferFrom(address _from, address _to, uint256 _amount) returns (uint error) {
        if(balances[_from] < _amount) { return 55; }
        if(balances[_to] + _amount <= balances[_to]) { return 55; }
        if(_amount > allowed[_from][msg.sender]) { return 55; }
        if(lockdown) { return 55; }

        balances[_from] -= _amount;
        balances[_to] += _amount;
        createTransferEvent(true, _from, _to, _amount);
        allowed[_from][msg.sender] -= _amount;
        return 0;
    }

    function approve(address _spender, uint256 _value) returns (uint error) {
        allowed[msg.sender][_spender] = _value;
        createApprovalEvent(true, msg.sender, _spender, _value);
        return 0;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function transferViaProxy(address _source, address _to, uint256 _amount) returns (uint error){
        if (!proxyManagementContract.isProxyLegit(msg.sender)) { return 1; }

        if (balances[_source] < _amount) {return 55;}
        if (balances[_to] + _amount <= balances[_to]) {return 55;}
        if (lockdown) {return 55;}

        balances[_source] -= _amount;
        balances[_to] += _amount;

        if (msg.sender == proxyManagementContract.dedicatedProxyAddress()){
            createTransferEvent(false, _source, _to, _amount); 
        }else{
            createTransferEvent(true, _source, _to, _amount); 
        }
        return 0;
    }
    
    function transferFromViaProxy(address _source, address _from, address _to, uint256 _amount) returns (uint error) {
        if (!proxyManagementContract.isProxyLegit(msg.sender)){ return 1; }

        if (balances[_from] < _amount) {return 55;}
        if (balances[_to] + _amount <= balances[_to]) {return 55;}
        if (lockdown) {return 55;}
        if (_amount > allowed[_from][_source]) {return 55;}

        balances[_from] -= _amount;
        balances[_to] += _amount;
        allowed[_from][_source] -= _amount;

        if (msg.sender == proxyManagementContract.dedicatedProxyAddress()){
            createTransferEvent(false, _source, _to, _amount); 
        }else{
            createTransferEvent(true, _source, _to, _amount); 
        }
        return 0;
    }
    
    function approveFromProxy(address _source, address _spender, uint256 _value) returns (uint error) {
        if (!proxyManagementContract.isProxyLegit(msg.sender)){ return 1; }

        allowed[_source][_spender] = _value;
        if (msg.sender == proxyManagementContract.dedicatedProxyAddress()){
            createApprovalEvent(false, _source, _spender, _value);
        }else{
            createApprovalEvent(true, _source, _spender, _value);
        }
        return 0;
    }

    function issueNewCoins(address _destination, uint _amount, string _details) returns (uint error){
        if (msg.sender != creationAddress) { return 1;}

        if(balances[_destination] + _amount < balances[_destination]) { return 55;}
        if(totalSupply + _amount < totalSupply) { return 55; }

        totalSupply += _amount;
        balances[_destination] += _amount;
        Create(_destination, _amount);
        createTransferEvent(true, 0x0, _destination, _amount);
        return 0;
    }

    function destroyOldCoins(address _destination, uint _amount, string _details) returns (uint error) {
        if (msg.sender != destructionAddress) { return 1;}

        if (balances[_destination] < _amount) { return 55;} 

        totalSupply -= _amount;
        balances[_destination] -= _amount;
        Destroy(_destination, _amount);
        createTransferEvent(true, _destination, 0x0, _amount);
        return 0;
    }

    function setTokenCurator(address _curatorAddress) returns (uint error){
        if( msg.sender != dev) {return 1;}
     
        curator = _curatorAddress;
        return 0;
    }
    
    function setCreationAddress(address _contractAddress) returns (uint error){ 
        if (msg.sender != curator) { return 1;}
        
        creationAddress = _contractAddress;
        return 0;
    }

    function setDestructionAddress(address _contractAddress) returns (uint error){ 
        if (msg.sender != curator) { return 1;}
        
        destructionAddress = _contractAddress;
        return 0;
    }

    function setProxyManagementContract(address _contractAddress) returns (uint error){
        if (msg.sender != curator) { return 1;}
        
        proxyManagementContract = IProxyManagement(_contractAddress);
        return 0;
    }

    function emergencyLock() returns (uint error){
        if (msg.sender != curator && msg.sender != dev) { return 1; }
        
        lockdown = !lockdown;
        return 0;
    }

    function killContract() returns (uint error){
        if (msg.sender != dev) { return 1; }
        
        selfdestruct(dev);
        return 0;
    }

    function proxyManagementAddress() constant returns (address proxyManagementAddress){
        return address(proxyManagementContract);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        ITokenRecipient spender = ITokenRecipient(_spender);
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

    function createTransferEvent(bool _relayEvent, address _from, address _to, uint256 _value) internal {
        if (_relayEvent){
            proxyManagementContract.raiseTransferEvent(_from, _to, _value);
        }
        Transfer(_from, _to, _value);
    }

    function createApprovalEvent(bool _relayEvent, address _sender, address _spender, uint _value) internal {
        if (_relayEvent){
            proxyManagementContract.raiseApprovalEvent(_sender, _spender, _value);
        }
        Approval(_sender, _spender, _value);
    }

    function () {
        throw;
    }
}