pragma solidity ^0.4.11;

contract SafeMath {
    function mul(uint256 a, uint256 b) internal  returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal  returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal   returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal  returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function pow( uint256 a , uint8 b ) internal returns ( uint256 ){
        uint256 c;
        c = a ** b;
        return c;
    }
}
contract owned {
    bool public OwnerDefined = false;
    address public owner;
    event OwnerEvents(address _addr, uint8 action);
    function owned()
        internal
    {
        require(OwnerDefined == false);
        owner = msg.sender;
        OwnerDefined = true;
        OwnerEvents(msg.sender,1);
    }
}
contract ERC20Token is owned, SafeMath{
    bool public tokenState;
    string public name = "8SM";
    string public symbol = "8SM";
    uint256 public decimals = 8;
    uint256 public totalSupply = mul(25,pow(10,15));
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function init()
        external
    returns ( bool ){
        require(tokenState == false);
        owned;
        tokenState = true;
        balances[this] = totalSupply;
        allowed[this][owner] = totalSupply;
        return true;
    }
    function transfer(address _to, uint256 _value)
        public
    returns ( bool ) {
        require(tokenState == true);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = sub(balances[msg.sender],_value);
        balances[_to] = add(balances[_to],_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value)
        public
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = sub(balances[_from],_value);
        balances[_to] = add(balances[_to],_value);
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender],_value);
        Transfer(_from, _to, _value);
    }
    function balanceOf(address _owner)
        external
        constant
    returns (uint256) {
        require(tokenState == true);
        return balances[_owner];
    }
    function approve(address _spender, uint256 _value)
        external
    returns (bool success) {
        require(tokenState == true);
        require(_spender != address(0));
        require(msg.sender == owner);
        allowed[msg.sender][_spender] = mul(_value, 100000000);
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender)
        external
        constant
    returns (uint256 remaining) {
        require(tokenState == true);
        return allowed[_owner][_spender];
    }
    function changeOwner()
        external
    returns ( bool ){
        require(owner == msg.sender);
        require(tokenState == true);
        allowed[this][owner] = 0;
        owner = msg.sender;
        allowed[this][msg.sender] = balances[this];
        return true;
    }
}
contract disburseToken is SafeMath{
    ERC20Token token;
    bool public state;
    address public tokenAddress; 
    address public owner;
    address public from;
    uint256 public staticblock = 5760;
    function init(address _addr,address _from) external returns(bool){
        require(state == false);
        state = true;
        tokenAddress = _addr;
        token = ERC20Token(_addr);
        owner = msg.sender;
        from = _from;
        return true;
    }
    function changeOwner(address _addr) external returns (bool){
        require(state == true);
        owner = _addr;
        return true;
    }
    function disburse (address char) returns ( bool ){
        require(state == true);
        require(owner == msg.sender);
        uint256 e = sub(block.number,mul(div(block.number,staticblock),staticblock));
        token.transferFrom(from,char,mul(e,4340277));
        return true;
    }
}