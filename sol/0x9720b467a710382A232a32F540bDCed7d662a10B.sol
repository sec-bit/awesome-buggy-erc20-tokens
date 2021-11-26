pragma solidity 0.4.18;
/**
    Used for administrration of the VZT Token Contract
*/

contract Administration {

    // keeps track of the contract owner
    address     public  owner;
    // keeps track of the contract administrator
    address     public  administrator;
    // keeps track of hte song token exchange
    address     public  songTokenExchange;
    // keeps track of the royalty information contract
    address     public  royaltyInformationContract;
    // keeps track of whether or not the admin contract is frozen
    bool        public  administrationContractFrozen;

    // keeps track of the contract moderators
    mapping (address => bool) public moderators;

    event ModeratorAdded(address indexed _invoker, address indexed _newMod, bool indexed _newModAdded);
    event ModeratorRemoved(address indexed _invoker, address indexed _removeMod, bool indexed _modRemoved);
    event AdministratorAdded(address indexed _invoker, address indexed _newAdmin, bool indexed _newAdminAdded);
    event RoyaltyInformationContractSet(address indexed _invoker, address indexed _newRoyaltyContract, bool indexed _newRoyaltyContractSet);
    event SongTokenExchangeContractSet(address indexed _invoker, address indexed _newSongTokenExchangeContract, bool indexed _newSongTokenExchangeSet);

    function Administration() {
        owner = 0x79926C875f2636808de28CD73a45592587A537De;
        administrator = 0x79926C875f2636808de28CD73a45592587A537De;
        administrationContractFrozen = false;
    }

    /// @dev checks to see if the contract is frozen
    modifier isFrozen() {
        require(administrationContractFrozen);
        _;
    }

    /// @dev checks to see if the contract is not frozen
    modifier notFrozen() {
        require(!administrationContractFrozen);
        _;
    }

    /// @dev checks to see if the msg.sender is owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev checks to see if msg.sender is owner, or admin
    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == administrator);
        _;
    }

    /// @dev checks to see if msg.sender is owner, admin, or song token exchange
    modifier onlyAdminOrExchange() {
        require(msg.sender == owner || msg.sender == songTokenExchange || msg.sender == administrator);
        _;
    }

    /// @dev checks to see if msg.sender is privileged
    modifier onlyModerator() {
        if (msg.sender == owner) {_;}
        if (msg.sender == administrator) {_;}
        if (moderators[msg.sender]) {_;}
    }

    /// @notice used to freeze the administration contract
    function freezeAdministrationContract() public onlyAdmin notFrozen returns (bool frozen) {
        administrationContractFrozen = true;
        return true;
    }

    /// @notice used to unfreeze the administration contract
    function unfreezeAdministrationContract() public onlyAdmin isFrozen returns (bool unfrozen) {
        administrationContractFrozen = false;
        return true;
    }

    /// @notice used to set the royalty information contract
    function setRoyaltyInformationContract(address _royaltyInformationContract) public onlyAdmin notFrozen returns (bool set) {
        royaltyInformationContract = _royaltyInformationContract;
        RoyaltyInformationContractSet(msg.sender, _royaltyInformationContract, true);
        return true;
    }

    /// @notice used to set the song token exchange
    function setTokenExchange(address _songTokenExchange) public onlyAdmin notFrozen returns (bool set) {
        songTokenExchange = _songTokenExchange;
        SongTokenExchangeContractSet(msg.sender, _songTokenExchange, true);
        return true;
    }

    /// @notice used to add a moderator
    function addModerator(address _newMod) public onlyAdmin notFrozen returns (bool success) {
        moderators[_newMod] = true;
        ModeratorAdded(msg.sender, _newMod, true);
        return true;
    }

    /// @notice used to remove a moderator
    function removeModerator(address _removeMod) public onlyAdmin notFrozen returns (bool success) {
        moderators[_removeMod] = false;
        ModeratorRemoved(msg.sender, _removeMod, true);
        return true;
    }

    /// @notice used to set an administrator
    function setAdministrator(address _administrator) public onlyOwner notFrozen returns (bool success) {
        administrator = _administrator;
        AdministratorAdded(msg.sender, _administrator, true);
        return true;
    }

    /// @notice used to transfer contract ownership
    function transferOwnership(address _newOwner) public onlyOwner notFrozen returns (bool success) {
        owner = _newOwner;
        return true;
    }
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

/**
    Version: 1.0.1
*/

contract Vezt is Administration {
    using SafeMath for uint256;

    uint256                 public  totalSupply;
    uint8                   public  decimals;
    string                  public  name;
    string                  public  symbol;
    bool                    public  tokenTransfersFrozen;
    bool                    public  tokenMintingEnabled;
    bool                    public  contractLaunched;

    mapping (address => uint256)                        public balances;
    mapping (address => mapping (address => uint256))   public allowed;


    event Transfer(address indexed _sender, address indexed _recipient, uint256 _amount);
    event Approve(address indexed _owner, address indexed _spender, uint256 _amount);
    event LaunchContract(address indexed _launcher, bool _launched);
    event FreezeTokenTransfers(address indexed _invoker, bool _frozen);
    event ThawTokenTransfers(address indexed _invoker, bool _thawed);
    event MintTokens(address indexed _minter, uint256 _amount, bool indexed _minted);
    event TokenMintingDisabled(address indexed _invoker, bool indexed _disabled);
    event TokenMintingEnabled(address indexed _invoker, bool indexed _enabled);
    event SongTokenAdded(address indexed _songTokenAddress, bool indexed _songTokenAdded);
    event SongTokenRemoved(address indexed _songTokenAddress, bool indexed _songTokenRemoved);

    function Vezt() {
        name = "Vezt";
        symbol = "VZT";
        decimals = 18;
        totalSupply = 125000000000000000000000000;
        balances[0x79926C875f2636808de28CD73a45592587A537De] = balances[0x79926C875f2636808de28CD73a45592587A537De].add(totalSupply);
        tokenTransfersFrozen = true;
        tokenMintingEnabled = false;
        contractLaunched = false;
    }

    /**
        @dev Used by admin to send bulk amount of transfers, primary purpose to replay tx from the crowdfund to make it easier to do bulk sending
        @notice Can also be used for general bulk transfers  via the associated python script
     */
    function transactionReplay(address _receiver, uint256 _amount)
        public
        onlyOwner
        returns (bool replayed)
    {
        require(transferCheck(msg.sender, _receiver, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(msg.sender, _receiver, _amount);
        return true;
    }

    /**
        @notice Used to launch the contract
     */
    function launchContract() 
        public
        onlyOwner
        returns (bool launched)
    {
        require(!contractLaunched);
        tokenTransfersFrozen = false;
        tokenMintingEnabled = true;
        contractLaunched = true;
        LaunchContract(msg.sender, true);
        return true;
    }

    /**
        @notice Used to disable token minting
     */
    function disableTokenMinting() 
        public
        onlyOwner
        returns (bool disabled) 
    {
        tokenMintingEnabled = false;
        TokenMintingDisabled(msg.sender, true);
        return true;
    }

    /**
        @notice Used to enable token minting
     */
    function enableTokenMinting() 
        public
        onlyOwner
        returns (bool enabled)
    {
        tokenMintingEnabled = true;
        TokenMintingEnabled(msg.sender, true);
        return true;
    }

    /**
        @notice Used to freeze token transfers
     */
    function freezeTokenTransfers()
        public
        onlyOwner
        returns (bool frozen)
    {
        tokenTransfersFrozen = true;
        FreezeTokenTransfers(msg.sender, true);
        return true;
    }

    /**
        @notice Used to thaw token tra4nsfers
     */
    function thawTokenTransfers()
        public
        onlyOwner
        returns (bool thawed)
    {
        tokenTransfersFrozen = false;
        ThawTokenTransfers(msg.sender, true);
        return true;
    }

    /**
        @notice Used to transfer funds
     */
    function transfer(address _receiver, uint256 _amount)
        public
        returns (bool transferred)
    {
        require(transferCheck(msg.sender, _receiver, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(msg.sender, _receiver, _amount);
        return true;
    }

    /**
        @notice Used to transfer funds on behalf of someone
     */
    function transferFrom(address _owner, address _receiver, uint256 _amount) 
        public 
        returns (bool transferred)
    {
        require(allowed[_owner][msg.sender] >= _amount);
        require(transferCheck(_owner, _receiver, _amount));
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(_owner, _receiver, _amount);
        return true;
    }

    /**
        @notice Used to approve someone to spend funds on your behalf
     */
    function approve(address _spender, uint256 _amount)
        public
        returns (bool approved)
    {
        require(_amount > 0);
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_amount);
        Approve(msg.sender, _spender, _amount);
        return true;
    }
    
    /**
        @notice Used to burn tokens
     */
    function tokenBurner(uint256 _amount)
        public
        onlyOwner
        returns (bool burned)
    {
        require(_amount > 0);
        require(totalSupply.sub(_amount) >= 0);
        require(balances[msg.sender] >= _amount);
        require(balances[msg.sender].sub(_amount) >= 0);
        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        Transfer(msg.sender, 0, _amount);
        return true;
    }

    /**
        @notice Used to mint new tokens
    */
    function tokenFactory(uint256 _amount)
        public 
        onlyOwner
        returns (bool minted)
    {
        // this calls the token minter function which is used to do a sanity check of the parameters being passed in
        require(tokenMinter(_amount, msg.sender));
        totalSupply = totalSupply.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        Transfer(0, msg.sender, _amount);
        return true;
    }

    // Internals

    /**
        @dev Low level function used to do a sanity check of minting params
     */
    function tokenMinter(uint256 _amount, address _sender)
        internal
        view
        returns (bool valid)
    {
        require(tokenMintingEnabled);
        require(_amount > 0);
        require(_sender != address(0x0));
        require(totalSupply.add(_amount) > 0);
        require(totalSupply.add(_amount) > totalSupply);
        require(balances[_sender].add(_amount) > 0);
        require(balances[_sender].add(_amount) > balances[_sender]);
        return true;
    }
    
    /**
        @dev Prevents people from sending to a  a null address        
        @notice Low level function used to do a sanity check of transfer parameters
     */
    function transferCheck(address _sender, address _receiver, uint256 _amount)
        internal
        view
        returns (bool valid)
    {
        require(!tokenTransfersFrozen);
        require(_amount > 0);
        require(_receiver != address(0));
        require(balances[_sender] >= _amount); // added check
        require(balances[_sender].sub(_amount) >= 0);
        require(balances[_receiver].add(_amount) > 0);
        require(balances[_receiver].add(_amount) > balances[_receiver]);
        return true;
    }

    // Getters

    /**
        @notice Used to retrieve total supply
     */
    function totalSupply() 
        public
        view
        returns (uint256 _totalSupply)
    {
        return totalSupply;
    }


    /**
        @notice Used to retrieve balance of a user
     */
    function balanceOf(address _person)
        public
        view
        returns (uint256 _balanceOf)
    {
        return balances[_person];
    }

    /**
        @notice Used to retrieve the allowed balance of someone
     */
    function allowance(address _owner, address _spender)
        public 
        view
        returns (uint256 _allowance)
    {
        return allowed[_owner][_spender];
    }

}