pragma solidity 0.4.16;

// implement safemath as a library
library SafeMath {

  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

// Used for function invoke restriction
contract Owned {

    address public owner; // temporary address

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner)
            revert();
        _; // function code inserted here
    }

    function transferOwnership(address _newOwner) onlyOwner returns (bool success) {
        if (msg.sender != owner)
            revert();
        owner = _newOwner;
        return true;
        
    }
}

contract Vezt is Owned {
    using SafeMath for uint256;

    address[]   public  veztUsers;
    uint256     public  totalSupply;
    uint8       public  decimals;
    string      public  name;
    string      public  symbol;
    bool        public  tokenTransfersFrozen;
    bool        public  tokenMintingEnabled;
    bool        public  contractLaunched;

    mapping (address => mapping (address => uint256))   public allowance;
    mapping (address => uint256)                        public balances;
    mapping (address => uint256)                        public royaltyTracking;
    mapping (address => uint256)                        public icoBalances;
    mapping (address => uint256)                        public veztUserArrayIdentifier;
    mapping (address => bool)                           public veztUserRegistered;

    event Transfer(address indexed _sender, address indexed _recipient, uint256 _amount);
    event Approve(address indexed _owner, address indexed _spender, uint256 _amount);
    event LaunchContract(address indexed _launcher, bool _launched);
    event FreezeTokenTransfers(address indexed _invoker, bool _frozen);
    event ThawTokenTransfers(address indexed _invoker, bool _thawed);
    event MintTokens(address indexed _minter, uint256 _amount, bool indexed _minted);
    event TokenMintingDisabled(address indexed _invoker, bool indexed _disabled);
    event TokenMintingEnabled(address indexed _invoker, bool indexed _enabled);

    function Vezt() {
        name = "Vezt";
        symbol = "VZT";
        decimals = 18;
        //125 million in wei 
        totalSupply = 125000000000000000000000000;
        balances[msg.sender] = balances[msg.sender].add(totalSupply);
        tokenTransfersFrozen = true;
        tokenMintingEnabled = false;
        contractLaunched = false;
    }

    /// @notice Used to log royalties
    /// @param _receiver The eth address of person to receive VZT Tokens
    /// @param _amount The amount of VZT Tokens in wei to send
    function logRoyalty(address _receiver, uint256 _amount)
        onlyOwner
        public 
        returns (bool logged)
    {
        require(transferCheck(msg.sender, _receiver, _amount));
        if (!veztUserRegistered[_receiver]) {
            veztUsers.push(_receiver);
            veztUserRegistered[_receiver] = true;
        }
        require(royaltyTracking[_receiver].add(_amount) > 0);
        require(royaltyTracking[_receiver].add(_amount) > royaltyTracking[_receiver]);
        royaltyTracking[_receiver] = royaltyTracking[_receiver].add(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(owner, _receiver, _amount);
        return true;
    }

    function transactionReplay(address _receiver, uint256 _amount)
        onlyOwner
        public
        returns (bool replayed)
    {
        require(transferCheck(msg.sender, _receiver, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(msg.sender, _receiver, _amount);
        return true;
    }

    /// @notice Used to launch the contract, and enabled token minting
    function launchContract() onlyOwner {
        require(!contractLaunched);
        tokenTransfersFrozen = false;
        tokenMintingEnabled = true;
        contractLaunched = true;
        LaunchContract(msg.sender, true);
    }

    function disableTokenMinting() onlyOwner returns (bool disabled) {
        tokenMintingEnabled = false;
        TokenMintingDisabled(msg.sender, true);
        return true;
    }

    function enableTokenMinting() onlyOwner returns (bool enabled) {
        tokenMintingEnabled = true;
        TokenMintingEnabled(msg.sender, true);
        return true;
    }

    function freezeTokenTransfers() onlyOwner returns (bool success) {
        tokenTransfersFrozen = true;
        FreezeTokenTransfers(msg.sender, true);
        return true;
    }

    function thawTokenTransfers() onlyOwner returns (bool success) {
        tokenTransfersFrozen = false;
        ThawTokenTransfers(msg.sender, true);
        return true;
    }

    /// @notice Used to transfer funds
    /// @param _receiver Eth address to send VZT tokens too
    /// @param _amount The amount of VZT tokens in wei to send
    function transfer(address _receiver, uint256 _amount)
        public
        returns (bool success)
    {
        require(transferCheck(msg.sender, _receiver, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(msg.sender, _receiver, _amount);
        return true;
    }

    /// @notice Used to transfer funds on behalf of owner to receiver
    /// @param _owner The person you are allowed to sends funds on bhhalf of
    /// @param _receiver The person to receive the funds
    /// @param _amount The amount of VZT tokens in wei to send
    function transferFrom(address _owner, address _receiver, uint256 _amount) 
        public 
        returns (bool success)
    {
        require(allowance[_owner][msg.sender] >= _amount);
        require(transferCheck(_owner, _receiver, _amount));
        allowance[_owner][msg.sender] = allowance[_owner][msg.sender].sub(_amount);
        balances[_owner] =  balances[_owner].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(_owner, _receiver, _amount);
        return true;
    }

    /// @notice Used to approve someone to send funds on your behalf
    /// @param _spender The eth address of the person you are approving
    /// @param _amount The amount of VZT tokens _spender is allowed to send (in wei)
    function approve(address _spender, uint256 _amount)
        public
        returns (bool approved)
    {
        require(_amount > 0);
        require(balances[msg.sender] >= _amount);
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_amount);
        return true;
    }

    /// @notice Used to burn tokens and decrease total supply
    /// @param _amount The amount of VZT tokens in wei to burn
    function tokenBurner(uint256 _amount)
        onlyOwner
        returns (bool burned)
    {
        require(_amount > 0);
        require(totalSupply.sub(_amount) > 0);
        require(balances[msg.sender] > _amount);
        require(balances[msg.sender].sub(_amount) > 0);
        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        Transfer(msg.sender, 0, _amount);
        return true;
    }

    /// @notice Low level function Used to create new tokens and increase total supply
    /// @param _amount The amount of VZT tokens in wei to create
    function tokenMinter(uint256 _amount)
        private
        returns (bool minted)
    {
        require(tokenMintingEnabled);
        require(_amount > 0);
        require(totalSupply.add(_amount) > 0);
        require(totalSupply.add(_amount) > totalSupply);
        require(balances[owner].add(_amount) > 0);
        require(balances[owner].add(_amount) > balances[owner]);
        return true;
    }
    /// @notice Used to create new tokens and increase total supply
    /// @param _amount The amount of VZT tokens in wei to create
    function tokenFactory(uint256 _amount) 
        onlyOwner
        returns (bool success)
    {
        require(tokenMinter(_amount));
        totalSupply = totalSupply.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        Transfer(0, msg.sender, _amount);
        return true;
    }

    // GETTER //

    function lookupRoyalty(address _veztUser)
        public
        constant
        returns (uint256 royalties)
    {
        return royaltyTracking[_veztUser];
    }

    /// @notice Reusable code to do sanity check of transfer variables
    function transferCheck(address _sender, address _receiver, uint256 _amount)
        private
        constant
        returns (bool success)
    {
        require(!tokenTransfersFrozen);
        require(_amount > 0);
        require(_receiver != address(0));
        require(balances[_sender].sub(_amount) >= 0);
        require(balances[_receiver].add(_amount) > 0);
        require(balances[_receiver].add(_amount) > balances[_receiver]);
        return true;
    }

    /// @notice Used to retrieve total supply
    function totalSupply() 
        public
        constant
        returns (uint256 _totalSupply)
    {
        return totalSupply;
    }

    /// @notice Used to look up balance of a person
    function balanceOf(address _person)
        public
        constant
        returns (uint256 _balance)
    {
        return balances[_person];
    }

    /// @notice Used to look up the allowance of someone
    function allowance(address _owner, address _spender)
        public
        constant 
        returns (uint256 _amount)
    {
        return allowance[_owner][_spender];
    }
}