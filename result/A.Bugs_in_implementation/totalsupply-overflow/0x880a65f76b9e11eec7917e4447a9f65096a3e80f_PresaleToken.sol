pragma solidity ^0.4.15;


// ERC20 token interface is implemented only partially.

contract PresaleToken {

        function PresaleToken() public {
        address tokenManager = 0xE2e16E48B09602b3E6Ba50B7fed950254cBE895d;
        address escrow = 0xBD4CB8e76D58Cc7E6D53aD475d599e8f4c110C19;
        balanceOf[escrow] += 60000000000000000000000000; // 60M
        totalSupply += 60000000000000000000000000;

        }
    /*/
     *  Constants
    /*/

    string public name = "Just Wallet";
    string public  symbol = "JWT";
    uint   public decimals = 18;

    uint public constant PRICE = 5000; 



    uint public constant TOKEN_SUPPLY_LIMIT = PRICE * 150000 * (1 ether / 1 wei);

    /*/
     *  Token state
    /*/

    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }

    Phase public currentPhase = Phase.Created;
    uint public totalSupply = 0; // amount of tokens already sold

    // Token manager has exclusive priveleges to call administrative
    // functions on this contract.
    address public tokenManager;

    // Gathered funds can be withdrawn only to escrow's address.
    address public escrow;

    // Crowdsale manager has exclusive priveleges to burn presale tokens.
    address public crowdsaleManager;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public isSaler;
    mapping (address => mapping (address => uint256)) public allowance;
    
    modifier onlyTokenManager() { 
        require(msg.sender == tokenManager); 
        _; 
    }
    modifier onlyCrowdsaleManager() {
        require(msg.sender == crowdsaleManager); 
        _; 
    }

    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }

    /*/
     *  Events
    /*/

    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogPhaseSwitch(Phase newPhase);
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /*/
     *  Public functions
    /*/

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[_from] > _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(balanceOf[msg.sender] - _value < balanceOf[msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }

    // Transfer the balance from owner's account to another account
    // only escrow can send token (to send token private sale)
    function transfer(address _to, uint256 _value) public
        onlyEscrow
    {
        _transfer(msg.sender, _to, _value);
    }

    /*
    *        >=3000 ETH: 1ETH = 6000 JWT
    *        >=300 ETH: 1ETH = 4800 JWT
    *        <300 ETH: 1ETH = 3450 JWT
    */
    function getBonus(uint value) internal returns (uint bonus) {
        require(value != 0);
        if (value >= (3000 * 10**18)) {
            return value * 2550;
        } else if (value >= (300 * 10**18)) {
            return value * 1350;
        }
        return 0;
    }


    function() payable public {
        buy(msg.sender);
    }
    
    function buy(address _buyer) payable public {
        // Available only if presale is running.
        require(currentPhase == Phase.Running);
        require(msg.value != 0);
        uint newTokens = msg.value * PRICE + getBonus(msg.value);
        require (totalSupply + newTokens < TOKEN_SUPPLY_LIMIT);
        balanceOf[_buyer] += newTokens;
        totalSupply += newTokens;
        LogBuy(_buyer, newTokens);
    }
    
    function buyTokens(address _saler) payable public {
        // Available only if presale is running.
        require(isSaler[_saler] == true);
        require(currentPhase == Phase.Running);

        require(msg.value != 0);
        uint newTokens = msg.value * PRICE + getBonus(msg.value);
        uint tokenForSaler = newTokens / 20;
        
        require(totalSupply + newTokens + tokenForSaler <= TOKEN_SUPPLY_LIMIT);
        
        balanceOf[_saler] += tokenForSaler;
        balanceOf[msg.sender] += newTokens;

        totalSupply += newTokens;
        totalSupply += tokenForSaler;
        
        LogBuy(msg.sender, newTokens);
    }


    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function burnTokens(address _owner) public
        onlyCrowdsaleManager
    {
        // Available only during migration phase
        require(currentPhase == Phase.Migrating);

        uint tokens = balanceOf[_owner];
        require(tokens != 0);
        balanceOf[_owner] = 0;
        totalSupply -= tokens;
        LogBurn(_owner, tokens);

        // Automatically switch phase when migration is done.
        if (totalSupply == 0) {
            currentPhase = Phase.Migrated;
            LogPhaseSwitch(Phase.Migrated);
        }
    }


    /*/
     *  Administrative functions
    /*/
    function setPresalePhase(Phase _nextPhase) public
        onlyTokenManager
    {
        bool canSwitchPhase
            =  (currentPhase == Phase.Created && _nextPhase == Phase.Running)
            || (currentPhase == Phase.Running && _nextPhase == Phase.Paused)
                // switch to migration phase only if crowdsale manager is set
            || ((currentPhase == Phase.Running || currentPhase == Phase.Paused)
                && _nextPhase == Phase.Migrating
                && crowdsaleManager != 0x0)
            || (currentPhase == Phase.Paused && _nextPhase == Phase.Running)
                // switch to migrated only if everyting is migrated
            || (currentPhase == Phase.Migrating && _nextPhase == Phase.Migrated
                && totalSupply == 0);

        require(canSwitchPhase);
        currentPhase = _nextPhase;
        LogPhaseSwitch(_nextPhase);
    }


    function withdrawEther() public
        onlyTokenManager
    {
        require(escrow != 0x0);
        // Available at any phase.
        if (this.balance > 0) {
            escrow.transfer(this.balance);
        }
    }


    function setCrowdsaleManager(address _mgr) public
        onlyTokenManager
    {
        // You can't change crowdsale contract when migration is in progress.
        require(currentPhase != Phase.Migrating);
        crowdsaleManager = _mgr;
    }

    function addSaler(address _mgr) public
        onlyTokenManager
    {
        require(currentPhase != Phase.Migrating);
        isSaler[_mgr] = true;
    }

    function removeSaler(address _mgr) public
        onlyTokenManager
    {
        require(currentPhase != Phase.Migrating);
        isSaler[_mgr] = false;
    }
    
     function mintToken(address target, uint256 mintedAmount) public onlyCrowdsaleManager {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, tokenManager, mintedAmount);
        Transfer(tokenManager, target, mintedAmount);
    }
    
    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
     /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

   
}