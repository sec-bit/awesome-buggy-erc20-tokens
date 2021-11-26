library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external;
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external;
  function approve(address spender, uint256 value) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
    function transfer(address _to, uint256 _value) external {
        address _from = msg.sender;
        require (balances[_from] >= _value && balances[_to] + _value > balances[_to]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
    }

    /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */

    function transferFrom(address _from, address _to, uint256 _value) external {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]){
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
      }
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        balance = balances[_owner];
    }

    function approve(address _spender, uint256 _value) external {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
  }
}


contract HadeCoin is BasicToken {

    using SafeMath for uint256;

    /*
       STORAGE
    */

    // name of the token
    string public name = "HADE Platform";

    // symbol of token
    string public symbol = "HADE";

    // decimals
    uint8 public decimals = 18;

    // total supply of Hade Coin
    uint256 public totalSupply = 150000000 * 10**18;

    // multi sign address of founders which hold
    address public adminMultiSig;

    /*
       EVENTS
    */

    event ChangeAdminWalletAddress(uint256  _blockTimeStamp, address indexed _foundersWalletAddress);

    /*
       CONSTRUCTOR
    */

    function HadeCoin(address _adminMultiSig) public {

        adminMultiSig = _adminMultiSig;
        balances[adminMultiSig] = totalSupply;
    }

    /*
       MODIFIERS
    */

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminMultiSig);
        _;
    }

    /*
       OWNER FUNCTIONS
    */

    // @title mint sends new coin to the specificed recepiant
    // @param _to is the recepiant the new coins
    // @param _value is the number of coins to mint
    function mint(address _to, uint256 _value) external onlyAdmin {

        require(_to != address(0));
        require(_value > 0);
        totalSupply += _value;
        balances[_to] += _value;
        Transfer(address(0), _to, _value);
    }

    // @title burn allows the administrator to burn their own tokens
    // @param _value is the number of tokens to burn
    // @dev note that admin can only burn their own tokens
    function burn(uint256 _value) external onlyAdmin {

        require(_value > 0 && balances[msg.sender] >= _value);
        totalSupply -= _value;
        balances[msg.sender] -= _value;
    }

    // @title changeAdminAddress allows to update the owner wallet
    // @param _newAddress is the address of the new admin wallet
    // @dev only callable by current owner
    function changeAdminAddress(address _newAddress)

    external
    onlyAdmin
    nonZeroAddress(_newAddress)
    {
        adminMultiSig = _newAddress;
        ChangeAdminWalletAddress(now, adminMultiSig);
    }

    // @title fallback reverts if a method call does not match
    // @dev reverts if any money is sent
    function() public {
        revert();
    }
}