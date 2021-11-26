pragma solidity 0.4.18;

// implement safemath as a library
library SafeMath {

  // We use `pure` bbecause it promises that the value for the function depends ONLY
  // on the function arguments
  function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

contract Administration {

    address     public owner;
    
    mapping (address => bool) public moderators;
    mapping (address => string) privilegeStatus;

    event AddMod(address indexed _invoker, address indexed _newMod, bool indexed _modAdded);
    event RemoveMod(address indexed _invoker, address indexed _removeMod, bool indexed _modRemoved);

    function Administration() public {
        owner = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner)
        public
        onlyOwner
        returns (bool success)
    {
        owner = _newOwner;
        return true;
        
    }

    function addModerator(address _newMod)
        public
        onlyOwner
        returns (bool added)
     {
        require(_newMod != address(0x0));
        moderators[_newMod] = true;
        AddMod(msg.sender, _newMod, true);
        return true;
    }
    
    function removeModerator(address _removeMod)
        public
        onlyOwner
        returns (bool removed)
    {
        require(_removeMod != address(0x0));
        moderators[_removeMod] = false;
        RemoveMod(msg.sender, _removeMod, true);
        return true;
    }

    function getRoleStatus(address _addr)
        public
        view  // We use view as we promise to not change state, but are reading from a state variable
        returns (string _role)
    {
        return privilegeStatus[_addr];
    }
}

contract CoinMarketAlert is Administration {
    using SafeMath for uint256;

    address[]   public      userAddresses;
    uint256     public      totalSupply;
    uint256     public      usersRegistered;
    uint8       public      decimals;
    string      public      name;
    string      public      symbol;
    bool        public      tokenTransfersFrozen;
    bool        public      tokenMintingEnabled;
    bool        public      contractLaunched;


    struct AlertCreatorStruct {
        address alertCreator;
        uint256 alertsCreated;
    }

    AlertCreatorStruct[]   public      alertCreators;
    
    // Alert Creator Entered (Used to prevetnt duplicates in creator array)
    mapping (address => bool) public userRegistered;
    // Tracks approval
    mapping (address => mapping (address => uint256)) public allowance;
    //[addr][balance]
    mapping (address => uint256) public balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approve(address indexed _owner, address indexed _spender, uint256 _amount);
    event MintTokens(address indexed _minter, uint256 _amountMinted, bool indexed Minted);
    event FreezeTransfers(address indexed _freezer, bool indexed _frozen);
    event ThawTransfers(address indexed _thawer, bool indexed _thawed);
    event TokenBurn(address indexed _burner, uint256 _amount, bool indexed _burned);
    event EnableTokenMinting(bool Enabled);

    function CoinMarketAlert()
        public {
        symbol = "CMA";
        name = "Coin Market Alert";
        decimals = 18;
        // 50 Mil in wei
        totalSupply = 50000000000000000000000000;
        balances[msg.sender] = 50000000000000000000000000;
        tokenTransfersFrozen = true;
        tokenMintingEnabled = false;
    }

    /// @notice Used to launch start the contract
    function launchContract()
        public
        onlyAdmin
        returns (bool launched)
    {
        require(!contractLaunched);
        tokenTransfersFrozen = false;
        tokenMintingEnabled = true;
        contractLaunched = true;
        EnableTokenMinting(true);
        return true;
    }
    
    /// @dev keeps a list of addresses that are participating in the site
    function registerUser(address _user) 
        private
        returns (bool registered)
    {
        usersRegistered = usersRegistered.add(1);
        AlertCreatorStruct memory acs;
        acs.alertCreator = _user;
        alertCreators.push(acs);
        userAddresses.push(_user);
        userRegistered[_user] = true;
        return true;
    }

    /// @notice Manual payout for site users
    /// @param _user Ethereum address of the user
    /// @param _amount The mount of CMA tokens in wei to send
    function singlePayout(address _user, uint256 _amount)
        public
        onlyAdmin
        returns (bool paid)
    {
        require(!tokenTransfersFrozen);
        require(_amount > 0);
        require(transferCheck(owner, _user, _amount));
        if (!userRegistered[_user]) {
            registerUser(_user);
        }
        balances[_user] = balances[_user].add(_amount);
        balances[owner] = balances[owner].add(_amount);
        Transfer(owner, _user, _amount);
        return true;
    }

    /// @dev low-level minting function not accessible externally
    function tokenMint(address _invoker, uint256 _amount) 
        private
        returns (bool raised)
    {
        require(balances[owner].add(_amount) > balances[owner]);
        require(balances[owner].add(_amount) > 0);
        require(totalSupply.add(_amount) > 0);
        require(totalSupply.add(_amount) > totalSupply);
        totalSupply = totalSupply.add(_amount);
        balances[owner] = balances[owner].add(_amount);
        MintTokens(_invoker, _amount, true);
        return true;
    }

    /// @notice Used to mint tokens, only usable by the contract owner
    /// @param _amount The amount of CMA tokens in wei to mint
    function tokenFactory(uint256 _amount)
        public
        onlyAdmin
        returns (bool success)
    {
        require(_amount > 0);
        require(tokenMintingEnabled);
        require(tokenMint(msg.sender, _amount));
        return true;
    }

    /// @notice Used to burn tokens
    /// @param _amount The amount of CMA tokens in wei to burn
    function tokenBurn(uint256 _amount)
        public
        onlyAdmin
        returns (bool burned)
    {
        require(_amount > 0);
        require(_amount < totalSupply);
        require(balances[owner] > _amount);
        require(balances[owner].sub(_amount) >= 0);
        require(totalSupply.sub(_amount) >= 0);
        balances[owner] = balances[owner].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        TokenBurn(msg.sender, _amount, true);
        return true;
    }

    /// @notice Used to freeze token transfers
    function freezeTransfers()
        public
        onlyAdmin
        returns (bool frozen)
    {
        tokenTransfersFrozen = true;
        FreezeTransfers(msg.sender, true);
        return true;
    }

    /// @notice Used to thaw token transfers
    function thawTransfers()
        public
        onlyAdmin
        returns (bool thawed)
    {
        tokenTransfersFrozen = false;
        ThawTransfers(msg.sender, true);
        return true;
    }

    /// @notice Used to transfer funds
    /// @param _receiver The destination ethereum address
    /// @param _amount The amount of CMA tokens in wei to send
    function transfer(address _receiver, uint256 _amount)
        public
        returns (bool _transferred)
    {
        require(!tokenTransfersFrozen);
        require(transferCheck(msg.sender, _receiver, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(msg.sender, _receiver, _amount);
        return true;
    }

    /// @notice Used to transfer funds on behalf of one person
    /// @param _owner Person you are allowed to spend funds on behalf of
    /// @param _receiver Person to receive the funds
    /// @param _amount Amoun of CMA tokens in wei to send
    function transferFrom(address _owner, address _receiver, uint256 _amount)
        public
        returns (bool _transferredFrom)
    {
        require(!tokenTransfersFrozen);
        require(allowance[_owner][msg.sender].sub(_amount) >= 0);
        require(transferCheck(_owner, _receiver, _amount));
        balances[_owner] = balances[_owner].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        allowance[_owner][_receiver] = allowance[_owner][_receiver].sub(_amount);
        Transfer(_owner, _receiver, _amount);
        return true;
    }

    /// @notice Used to approve a third-party to send funds on your behalf
    /// @param _spender The person you are allowing to spend on your behalf
    /// @param _amount The amount of CMA tokens in wei they are allowed to spend
    function approve(address _spender, uint256 _amount)
        public
        returns (bool approved)
    {
        require(_amount > 0);
        require(balances[msg.sender] > 0);
        allowance[msg.sender][_spender] = _amount;
        Approve(msg.sender, _spender, _amount);
        return true;
    }

     //GETTERS//
    ///////////

    
    /// @dev low level function used to do a sanity check of input data for CMA token transfers
    /// @param _sender This is the msg.sender, the person sending the CMA tokens
    /// @param _receiver This is the address receiving the CMA tokens
    /// @param _value This is the amount of CMA tokens in wei to send
    function transferCheck(address _sender, address _receiver, uint256 _value) 
        private
        view
        returns (bool safe) 
    {
        require(_value > 0);
        require(_receiver != address(0));
        require(balances[_sender].sub(_value) >= 0);
        require(balances[_receiver].add(_value) > balances[_receiver]);
        return true;
    }

    /// @notice Used to retrieve total supply
    function totalSupply()
        public
        view
        returns (uint256 _totalSupply)
    {
        return totalSupply;
    }

    /// @notice Used to look up balance of a user
    function balanceOf(address _person)
        public
        view
        returns (uint256 balance)
    {
        return balances[_person];
    }

    /// @notice Used to look up allowance of a user
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 allowed)
    {
        return allowance[_owner][_spender];
    }
}