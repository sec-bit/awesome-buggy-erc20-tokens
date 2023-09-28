pragma solidity ^0.4.11;
contract FundariaToken {
    string public constant name = "Fundaria Token";
    string public constant symbol = "RI";
    
    uint public totalSupply; // how many tokens supplied at the moment
    uint public supplyLimit; // how many tokens can be supplied    
    uint public course; // course wei for token
 
    mapping(address=>uint256) public balanceOf; // owned tokens
    mapping(address=>mapping(address=>uint256)) public allowance; // allowing third parties to transfer tokens 
    mapping(address=>bool) public allowedAddresses; // allowed addresses to manage some functions    

    address public fundariaPoolAddress; // ether source for Fundaria development
    address creator; // creator address of this contract
    
    event SuppliedTo(address indexed _to, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event SupplyLimitChanged(uint newLimit, uint oldLimit);
    event AllowedAddressAdded(address _address);
    event CourseChanged(uint newCourse, uint oldCourse);
    
    function FundariaToken() {
        allowedAddresses[msg.sender] = true; // add creator address to allowed addresses
        creator = msg.sender;
    }
    
    // condition to be creator address to run some functions
    modifier onlyCreator { 
        if(msg.sender == creator) _; 
    }
    
    // condition to be allowed address to run some functions
    modifier isAllowed {
        if(allowedAddresses[msg.sender]) _; 
    }
    
    // set address for Fundaria source of ether
    function setFundariaPoolAddress(address _fundariaPoolAddress) onlyCreator {
        fundariaPoolAddress = _fundariaPoolAddress;
    }     
    
    // expand allowed addresses with new one    
    function addAllowedAddress(address _address) onlyCreator {
        allowedAddresses[_address] = true;
        AllowedAddressAdded(_address);
    }
    
    // remove allowed address
    function removeAllowedAddress(address _address) onlyCreator {
        delete allowedAddresses[_address];    
    }

    // increase token balance of some address
    function supplyTo(address _to, uint _value) isAllowed {
        totalSupply += _value;
        balanceOf[_to] += _value;
        SuppliedTo(_to, _value);
    }
    
    // limit total tokens can be supplied
    function setSupplyLimit(uint newLimit) isAllowed {
        SupplyLimitChanged(newLimit, supplyLimit);
        supplyLimit = newLimit;
    }                
    
    // set course
    function setCourse(uint newCourse) isAllowed {
        CourseChanged(newCourse, course);
        course = newCourse;
    } 
    
    // token for wei according to course
    function tokenForWei(uint _wei) constant returns(uint) {
        return _wei/course;    
    }
    
    // wei for token according to course
    function weiForToken(uint _token) constant returns(uint) {
        return _token*course;
    } 
    
    // transfer tokens to another address (owner)    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0 || balanceOf[msg.sender] < _value || balanceOf[_to] + _value < balanceOf[_to]) 
            return false; 
        balanceOf[msg.sender] -= _value;                     
        balanceOf[_to] += _value;                            
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    // setting of availability of tokens transference for third party
    function transferFrom(address _from, address _to, uint256 _value) 
        returns (bool success) {
        if(_to == 0x0 || balanceOf[_from] < _value || _value > allowance[_from][msg.sender]) 
            return false;                                
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    // approving transference of tokens for third party
    function approve(address _spender, uint256 _value) 
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    // Prevents accidental sending of ether
    function () {
	    throw; 
    }     
         
}