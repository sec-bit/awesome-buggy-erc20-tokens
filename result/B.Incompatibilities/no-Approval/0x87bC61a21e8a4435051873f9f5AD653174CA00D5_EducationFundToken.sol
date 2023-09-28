pragma solidity ^0.4.16;

contract EducationFundToken {

    string public name = "EducationFundToken";
    string public symbol = "EDUT";
    uint8 public decimals = 0;

    address owner = 0x3755530e18033E3EDe5E6b771F1F583bf86EfD10;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function MyKidsEducationFund() public {
        balanceOf[msg.sender] = 1000;
        name = "EducationFundToken";
        symbol = "EDUT";
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function () payable public {
        require(msg.value >= 0);
        uint tokens = msg.value / 1 finney;
        balanceOf[msg.sender] += tokens;
        owner.transfer(msg.value);
    }
}