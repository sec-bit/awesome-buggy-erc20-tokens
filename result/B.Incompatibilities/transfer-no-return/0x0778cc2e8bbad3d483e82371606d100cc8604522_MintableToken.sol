pragma solidity ^0.4.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) constant returns (uint256);

    function transfer(address to, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);

    function transferFrom(address from, address to, uint256 value);

    function approve(address spender, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) public balances;
    mapping (address => bool) public onChain;
    address[] public ownersOfToken;


    function ownersLen() constant returns (uint256) { return ownersOfToken.length; }
    function ownerAddress(uint256 number) constant returns (address) { return ownersOfToken[number]; }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) {

        require(balances[msg.sender] >= _value);
        // Check if the sender has enough
        require(balances[_to] + _value >= balances[_to]);
        // Check for overflows

        if (!onChain[_to]){
            ownersOfToken.push(_to);
            onChain[_to] = true;
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

    // burn tokens from sender balance
    function burn(uint256 _value) {

        require(balances[msg.sender] >= _value);
        // Check if the sender has enough

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply.sub(_value);
        Burn(msg.sender, _value);
    }


    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;
    address[] public ownersOfToken;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint256 _value) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;
        if (!onChain[_to]){
            ownersOfToken.push(_to);
        }
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifing the amount of tokens still avaible for the spender.
     */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


contract Ownable {

    address public owner;
    address public manager;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == manager);
        _;
    }



    function setManager(address _manager) onlyOwner {
        manager = _manager;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    bool exchangeable;

    string public name = "LHCoin";

    string public symbol = "LHC";

    uint256 public decimals = 8;

    uint256 public decimalMultiplier = 100000000;

    bool public mintingFinished = false;

    address bountyCoin;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function MintableToken(){
        mint(msg.sender, 72000000 * decimalMultiplier);
        finishMinting();
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will recieve the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function exchangeBounty(address user, uint amount) {
        assert(msg.sender == bountyCoin);
        assert(exchangeable);
        balances[user] = amount;
        totalSupply += amount;
    }

    function setBountyCoin(address _bountyCoin) onlyAdmin {
        bountyCoin = _bountyCoin;
    }

    function setExchangeable(bool _exchangeable) onlyAdmin {
        exchangeable = _exchangeable;
    }
}


contract MintableTokenBounty is StandardToken, Ownable {

    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    string public name = "LHBountyCoin";

    string public symbol = "LHBC";

    uint256 public decimals = 8;

    uint256 public decimalMultiplier = 100000000;

    bool public mintingFinished = false;

    MintableToken coin;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function MintableTokenBounty() {
        mint(msg.sender, 30000000 * decimalMultiplier);
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will recieve the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyAdmin canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyAdmin returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function setCoin(MintableToken _coin) onlyAdmin {
        coin = _coin;
    }

    function exchangeToken() {
        coin.exchangeBounty(msg.sender, balances[msg.sender]);
        totalSupply -= balances[msg.sender];
        balances[msg.sender] = 0;
    }
}