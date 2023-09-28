contract SafeMath {
    
    uint256 constant MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require(x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require(x >= y);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) {
            return 0;
        }
        require(x <= (MAX_UINT256 / y));
        return x * y;
    }
}

contract ReentrancyHandlingContract{

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

    function Owned() {
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

contract Lockable is Owned {

    uint256 public lockedUntilBlock;

    event ContractLocked(uint256 _untilBlock, string _reason);

    modifier lockAffected {
        require(block.number > lockedUntilBlock);
        _;
    }

    function lockFromSelf(uint256 _untilBlock, string _reason) internal {
        lockedUntilBlock = _untilBlock;
        ContractLocked(_untilBlock, _reason);
    }


    function lockUntil(uint256 _untilBlock, string _reason) onlyOwner public {
        lockedUntilBlock = _untilBlock;
        ContractLocked(_untilBlock, _reason);
    }
}

contract ERC20TokenInterface {
  function totalSupply() public constant returns (uint256 _totalSupply);
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract InsurePalTokenInterface {
    function mint(address _to, uint256 _amount) public;
}

contract tokenRecipientInterface {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract KycContractInterface {
    function isAddressVerified(address _address) public view returns (bool);
}









contract KycContract is Owned {
    
    mapping (address => bool) verifiedAddresses;
    
    function isAddressVerified(address _address) public view returns (bool) {
        return verifiedAddresses[_address];
    }
    
    function addAddress(address _newAddress) public onlyOwner {
        require(!verifiedAddresses[_newAddress]);
        
        verifiedAddresses[_newAddress] = true;
    }
    
    function removeAddress(address _oldAddress) public onlyOwner {
        require(verifiedAddresses[_oldAddress]);
        
        verifiedAddresses[_oldAddress] = false;
    }
    
    function batchAddAddresses(address[] _addresses) public onlyOwner {
        for (uint cnt = 0; cnt < _addresses.length; cnt++) {
            assert(!verifiedAddresses[_addresses[cnt]]);
            verifiedAddresses[_addresses[cnt]] = true;
        }
    }
    
    function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) public onlyOwner{
        ERC20TokenInterface(_tokenAddress).transfer(_to, _amount);
    }
    
    function killContract() public onlyOwner {
        selfdestruct(owner);
    }
}