pragma solidity 0.4.19;

contract Maths {

    function Mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function Div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function Sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function Add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

}

contract Owned is Maths {

    address public owner;        
    bool public transfer_status = true;
    uint256 TotalSupply = 10000000000000000000000000000;
    address public InitialOwnerAddress;
    mapping(address => uint256) UserBalances;
    mapping(address => mapping(address => uint256)) public Allowance;
    uint256 LockInExpiry = Add(block.timestamp, 2629744);
    event OwnershipChanged(address indexed _invoker, address indexed _newOwner);        
    event TransferStatusChanged(bool _newStatus);
    
        
    function Owned() public {
        InitialOwnerAddress = 0xb51e11ce9c9427e85ed23e2a7b12f71e9a6d261b;
        owner = 0xb51e11ce9c9427e85ed23e2a7b12f71e9a6d261b;
    }

    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function ChangeOwner(address _AddressToMake) public _onlyOwner returns (bool _success) {

        owner = _AddressToMake;
        OwnershipChanged(msg.sender, _AddressToMake);

        return true;

    }

    function ChangeTransferStatus(bool _newStatus) public _onlyOwner returns (bool _success) {

        transfer_status = _newStatus;
        TransferStatusChanged(_newStatus);
    
        return true;
    
    }

    function Mint(uint256 _amount) public _onlyOwner returns (bool _success) {

        TotalSupply = Add(TotalSupply, _amount);
        UserBalances[msg.sender] = Add(UserBalances[msg.sender], _amount);

        return true;

    }

    function Burn(uint256 _amount) public _onlyOwner returns (bool _success) {

        require(Sub(UserBalances[msg.sender], _amount) >= 0);
        TotalSupply = Sub(TotalSupply, _amount);
        UserBalances[msg.sender] = Sub(UserBalances[msg.sender], _amount);

        return true;

    }
        
}

contract Core is Owned {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    string name = 'Gregc1131';
    string symbol = '1131';
    uint256 decimals = 18;

    function Core() public {

        UserBalances[0xb51e11ce9c9427e85ed23e2a7b12f71e9a6d261b] = TotalSupply;

    }

    function _transferCheck(address _sender, address _recipient, uint256 _amount) private view returns (bool success) {
                     
        require(transfer_status == true);
        require(_amount > 0);
        require(_recipient != address(0));
        require(UserBalances[_sender] > _amount);
        require(Sub(UserBalances[_sender], _amount) >= 0);
        require(Add(UserBalances[_recipient], _amount) > UserBalances[_recipient]);
            
            if (_sender == InitialOwnerAddress && block.timestamp < LockInExpiry) {
                require(Sub(UserBalances[_sender], _amount) >= 2500000000);
            }
        
        return true;

    }

    function transfer(address _receiver, uint256 _amount) public returns (bool status) {

        require(_transferCheck(msg.sender, _receiver, _amount));
        UserBalances[msg.sender] = Sub(UserBalances[msg.sender], _amount);
        UserBalances[_receiver] = Add(UserBalances[msg.sender], _amount);
        Transfer(msg.sender, _receiver, _amount);
        return true;

    }

    function transferFrom(address _owner, address _receiver, uint256 _amount) public returns (bool status) {

        require(_transferCheck(_owner, _receiver, _amount));
        require(Sub(Allowance[_owner][msg.sender], _amount) >= 0);
        UserBalances[_owner] = Sub(UserBalances[_owner], _amount);
        UserBalances[_receiver] = Add(UserBalances[_receiver], _amount);
        Allowance[_owner][msg.sender] = Sub(Allowance[_owner][msg.sender], _amount);
        Transfer(_owner, _receiver, _amount);

        return true;

    }

    function multiTransfer(address[] _destinations, uint256[] _values) public returns (uint256) {

        uint256 i = 0;

        while (i < _destinations.length) {
            transfer(_destinations[i], _values[i]);
            i += 1;
        }

        return (i);

    }

    function approve(address _spender, uint256 _amount) public returns (bool approved) {

        require(_amount > 0);
        require(UserBalances[msg.sender] > 0);
        Allowance[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);

        return true;

    }

    function balanceOf(address _address) public view returns (uint256 balance) {

        return UserBalances[_address];

    }

    function allowance(address _owner, address _spender) public view returns (uint256 allowed) {

        return Allowance[_owner][_spender];

    }

    function totalSupply() public view returns (uint256 supply) {

        return TotalSupply;

    }

}