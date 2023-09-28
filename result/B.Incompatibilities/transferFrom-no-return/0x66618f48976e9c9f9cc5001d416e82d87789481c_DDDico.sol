pragma solidity ^0.4.11;

// @title ICO Simple Contract
// @author Harsh Patel

contract SafeMath {

    // @notice SafeMath multiply function
    // @param a Variable 1
    // @param b Variable 2
    // @result { "" : "result of safe multiply"}
    function mul(uint256 a, uint256 b) internal  returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // @notice SafeMath divide function
    // @param a Variable 1
    // @param b Variable 2
    // @result { "" : "result of safe multiply"}
    function div(uint256 a, uint256 b) internal  returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        return c;
    }

    // @notice SafeMath substract function
    // @param a Variable 1
    // @param b Variable 2
    function sub(uint256 a, uint256 b) internal   returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    // @notice SafeMath addition function
    // @param a Variable 1
    // @param b Variable 2
    function add(uint256 a, uint256 b) internal  returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    // @notice SafeMath Power function
    // @param a Variable 1
    // @param b Variable 2
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

    // @notice Initializes Owner Contract and set the first Owner
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

    // Token Definitions
    bool public tokenState;
    string public name = "DropDeck";
    string public symbol = "DDD";
    uint256 public decimals = 8;
    uint256 public totalSupply = 380000000000000000;
    address public ico;
    bool public blockState = true;

    mapping(address => uint256) balances;
    mapping(address => bool) public userBanned;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // @notice Initialize the Token Contract
    // @param _name Name of Token
    // @param _code Short Code of the Token
    // @param _decimals Amount of Decimals for the Token
    // @param _netSupply TotalSupply of Tokens
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

    // @notice Transfers the token
    // @param _to Address of reciver
    // @param _value Value to be transfered
    function transfer(address _to, uint256 _value)
        public
    returns ( bool ) {
        require(tokenState == true);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(blockState == false);
        require(userBanned[msg.sender] == false);
        balances[msg.sender] = sub(balances[msg.sender],_value);
        balances[_to] = add(balances[_to],_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    // @notice Transfers the token on behalf of
    // @param _from Address of sender
    // @param _to Address of reciver
    // @param _value Value to be transfered
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

    // @notice Transfers the token from owner during the ICO
    // @param _to Address of reciver
    // @param _value Value to be transfered
    function transferICO(address _to, uint256 _value)
        public
    returns ( bool ) {
        require(tokenState == true);
        require(_to != address(0));
        require(_value <= balances[this]);
        require(ico == msg.sender);
        balances[this] = sub(balances[this],_value);
        balances[_to] = add(balances[_to],_value);
        Transfer(this, _to, _value);
        return true;
    }

    // @notice Checks balance of Address
    // @param _to Address of token holder
    function balanceOf(address _owner)
        external
        constant
    returns (uint256) {
        require(tokenState == true);
        return balances[_owner];
    }

    // @notice Approves allowance for token holder
    // @param _spender Address of token holder
    // @param _value Amount of Token Transfer to approve
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

    // @notice Fetched Allowance for owner
    // @param _spender Address of token holder
    // @param _owner Amount of token owner
    function allowance(address _owner, address _spender)
        external
        constant
    returns (uint256 remaining) {
        require(tokenState == true);
        return allowed[_owner][_spender];
    }

    // @notice Allows enabling of blocking of transfer for all users
    function blockTokens()
        external
    returns (bool) {
        require(tokenState == true);
        require(msg.sender == owner);
        blockState = true;
        return true;
    }

    // @notice Allows enabling of unblocking of transfer for all users
    function unblockTokens()
        external
    returns (bool) {
        require(tokenState == true);
        require(msg.sender == owner);
        blockState = false;
        return true;
    }

    // @notice Bans an Address
    function banAddress(address _addr)
        external
    returns (bool) {
        require(tokenState == true);
        require(msg.sender == owner);
        userBanned[_addr] = true;
        return true;
    }

    // @notice Un-Bans an Address
    function unbanAddress(address _addr)
        external
    returns (bool) {
        require(tokenState == true);
        require(msg.sender == owner);
        userBanned[_addr] = false;
        return true;
    }

    function setICO(address _ico)
        external
    returns (bool) {
        require(tokenState == true);
        require(msg.sender == owner);
        ico = _ico;
        return true;
    }

    // @notice Transfers the ownership of owner
    // @param newOwner Address of the new owner
    function transferOwnership( address newOwner )
        external
    {
        require(msg.sender == owner);
        require(newOwner != address(0));

        allowed[this][owner] =  0;
        owner = newOwner;
        allowed[this][owner] =  balances[this];
        OwnerEvents(msg.sender,2);
    }


}
contract tokenContract is ERC20Token{

}

contract DDDico is SafeMath {

    tokenContract token;

    bool public state;

    address public wallet;
    address public tokenAddress;
    address public owner;

    uint256 public weiRaised;
    uint256 public hardCap;
    uint256 public tokenSale;
    uint256 public tokenLeft;
    uint256 public applicableRate;
    uint256 weiAmount;
    uint256 tok;

    uint256 public block0 = 4594600;
    uint256 public block1 = 4594840;
    uint256 public block2 = 4600600;
    uint256 public block3 = 4640920;
    uint256 public block4 = 4681240;
    uint256 public block5 = 4721560;
    uint256 public block6 = 4761880;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // @notice Initializes a ICO Contract
    // @param _hardCap Specifies hard cap for ICO in wei
    // @param _wallet Address of the multiSig wallet
    // @param _token Address of the Token Contract
    function DDDico( address _wallet, address _token , uint256 _hardCap, uint256 _tokenSale ) {
        require(_wallet != address(0));
        state = true;
        owner = msg.sender;
        wallet = _wallet;
        tokenAddress = _token;
        token = tokenContract(tokenAddress);
        hardCap = mul(_hardCap,pow(10,16));
        tokenSale = mul(_tokenSale,pow(10,8));
        tokenLeft = tokenSale;
    }

    // @notice Fallback function to invest in ICO
    function () payable {
        buyTokens();
    }

    // @notice Buy Token Function to purchase tokens in ICO
    function buyTokens() public payable {
        require(validPurchase());
        weiAmount               = 0;
        tok                     = 0;
        weiAmount               = msg.value;
        tok                     = div(mul(weiAmount,fetchRate()),pow(10,16));
        weiRaised               = add(weiRaised,weiAmount);
        tokenLeft               = sub(tokenLeft,tok);
        token.transferICO(msg.sender,tok);
        TokenPurchase(msg.sender, msg.sender, weiAmount, tok);
        forwardFunds();
    }

    // @notice Function to forward incomming funds to multi-sig wallet
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @notice Validates the purchase
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = block.number >= block0 && block.number <= block6;
        bool nonZeroPurchase = msg.value != 0;
        bool cap = weiRaised <= hardCap;
        return withinPeriod && nonZeroPurchase && cap;
    }

    // @notice Calculates the rate based on slabs
    function fetchRate() constant returns (uint256){
        if( block0 <= block.number && block1 > block.number ){
            applicableRate = 15000000000;
            return applicableRate;
        }
        if ( block1 <= block.number && block2 > block.number ){
            applicableRate = 14000000000;
            return applicableRate;
        }
        if ( block2 <= block.number && block3 > block.number ){
            applicableRate = 13000000000;
            return applicableRate;
        }
        if ( block3 <= block.number && block4 > block.number ){
            applicableRate = 12000000000;
            return applicableRate;
        }
        if ( block4 <= block.number && block5 > block.number ){
            applicableRate = 11000000000;
            return applicableRate;
        }
        if ( block5 <= block.number && block6 > block.number ){
            applicableRate = 10000000000;
            return applicableRate;
        }
    }

    // @notice Checks weather ICO has ended or not
    function hasEnded() public constant returns (bool)
    {
        return block.number > block6;
    }
}