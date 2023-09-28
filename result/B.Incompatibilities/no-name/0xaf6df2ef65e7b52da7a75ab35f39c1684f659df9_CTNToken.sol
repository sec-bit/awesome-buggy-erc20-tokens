pragma solidity ^0.4.15;

/**
* assert(2 + 2 is 4 - 1 thats 3) Quick Mafs 
*/
library QuickMafs {
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a * _b;
        assert(_a == 0 || c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = _a / _b;
        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

/** 
* The ownable contract contains an owner address. This give us simple ownership privledges and can allow ownship transfer. 
*/
contract Ownable {

     /** 
     * The owner/admin of the contract
     */ 
     address public owner;
    
     /**
     * Constructor for contract. Sets The contract creator to the default owner.
     */
     function Ownable() public {
         owner = msg.sender;
     }
    
    /**
    * Modifier to apply to methods to restrict access to the owner
    */
     modifier onlyOwner(){
         require(msg.sender == owner);
         _; //Placeholder for method content
     }
    
    /**
    * Transfer the ownership to a new owner can only be done by the current owner. 
    */
    function transferOwnership(address _newOwner) public onlyOwner {
    
        //Only make the change if required
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }
    }
    
    /**
    *  ERC Token Standard #20 Interface
    */
    contract ERC20 {
    
    /**
    * Get the total token supply
    */
    function totalSupply() public constant returns (uint256 _totalSupply);
    
    /**
    * Get the account balance of another account with address _owner
    */
    function balanceOf(address _owner) public constant returns (uint256 balance);
    
    /**
    * Send _amount of tokens to address _to
    */
    function transfer(address _to, uint256 _amount) public returns (bool success);
    
    /**
    * Send _amount of tokens from address _from to address _to
    */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
    
    /**
    * Allow _spender to withdraw from your account, multiple times, up to the _amount.
    * If this function is called again it overwrites the current allowance with _amount.
    * this function is required for some DEX functionality
    */
    function approve(address _spender, uint256 _amount) public returns (bool success);
    
    /**
    * Returns the amount which _spender is still allowed to withdraw from _owner
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
    /**
    * Triggered when tokens are transferred.
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    
    /**
    * Triggered whenever approve(address _spender, uint256 _amount) is called.
    */
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}


/**
* The CTN Token
*/
contract CTNToken is ERC20, Ownable {

using QuickMafs for uint256;

string public constant SYMBOL = "CTN";
string public constant NAME = "Crypto Trust Network";
uint8 public constant DECIMALS = 18;

/**
* Total supply of tokens
*/
uint256 totalTokens;

/**
* The initial supply of coins before minting
 */
uint256 initialSupply;

/**
* Balances for each account
*/
mapping(address => uint256) balances;

/**
* Whos allowed to withdrawl funds from which accounts
*/
mapping(address => mapping (address => uint256)) allowed;

/**
 * If the token is tradable
 */ 
 bool tradable;
 
/**
* The address to store the initialSupply
*/
address public vault;

/**
* If the coin can be minted
*/
bool public mintingFinished = false;

/**
 * Event for when new coins are created 
 */
event Mint(address indexed _to, uint256 _value);

/**
* Event that is fired when token sale is over
*/
event MintFinished();

/**
 * Tokens can now be traded
 */ 
event TradableTokens(); 


/**
 * Allows this coin to be traded between users
 */ 
modifier isTradable(){
    require(tradable);
    _;
}

/**
 * If this coin can be minted modifier
 */
modifier canMint() {
    require(!mintingFinished);
    _;
}


/**
* Initializing the token with the owner and the amount of coins excluding the token sale
*/
function CTNToken() public {
    initialSupply = 4500000 * 1 ether;
    totalTokens = initialSupply;
    tradable = false;
    vault = 0x6e794AAA2db51fC246b1979FB9A9849f53919D1E; 
    balances[vault] = balances[vault].add(initialSupply); //Set initial supply to the vault
}

/**
* To get the total supply of CTN coins 
*/
function totalSupply() public constant returns (uint256 totalAmount) {
      totalAmount = totalTokens;
}

/**
* To get the total supply of CTN coins 
*/
function baseSupply() public constant returns (uint256 initialAmount) {
      initialAmount = initialSupply;
}

/**
* Returns the balance of the wallet
*/ 
function balanceOf(address _address) public constant returns (uint256 balance) {
    return balances[_address];
}


function transfer(address _to, uint256 _amount) public isTradable returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(msg.sender, _to, _amount);
    return true;
}
  /**
  * Send _amount of tokens from address _from to address _to
  * The transferFrom method is used for a withdraw workflow, allowing contracts to send
  * tokens on your behalf, for example to "deposit" to a contract address and/or to charge
  * fees in sub-currencies; the command should fail unless the _from account has
  * deliberately authorized the sender of the message via some mechanism; we propose
  * these standardized APIs for approval:
  */
  function transferFrom(
      address _from,
      address _to,
      uint256 _amount
 ) public isTradable returns (bool success) 
 {
    var _allowance = allowed[_from][msg.sender];

    /** 
    *   QuickMaf will roll back any changes so no need to check before these operations
    */
    balances[_to] = balances[_to].add(_amount);
    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = _allowance.sub(_amount);
    Transfer(_from, _to, _amount);
    return true;  
 }

/**
* Allows an address to transfer money out this is administered by the contract owner who can specify how many coins an account can take.
* Needs to be called to feault the amount to 0 first -> https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
*/
function approve(address _spender, uint256 _amount) public returns (bool) {
    /**
    *Set the amount they are able to spend to 0 first so that transaction ordering cannot allow multiple withdrawls asyncly
    *This function always requires to calls if a user has an amount they can withdrawl.
    */
    require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
}


/**
 * Check the amount of tokens the owner has allowed to a spender
 */
function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
     return allowed[_owner][_spender];
}

/**
 * Makes the coin tradable between users cannot be undone
 */
function makeTradable() public onlyOwner {
    tradable = true;
    TradableTokens();
}

/**
* Mint tokens to users
*/
function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
    totalTokens = totalTokens.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
}

/**
* Function to stop minting tokens irreversable
*/
function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
}

}

/**
* The initial crowdsale of the token
*/
contract CTNTokenSale is Ownable {


using QuickMafs for uint256;

/**
 * The hard cap of the token sale
 */
uint256 hardCap;

/**
 * The soft cap of the token sale
 */
uint256 softCap;

/**
 * The bonus cap for the token sale
 */
uint256 bonusCap;

/**
 * How many tokens you get per ETH
 */
uint256 tokensPerETH;

/** 
* //the start time of the sale (new Date("Dec 15 2017 18:00:00 GMT").getTime() / 1000)
*/
uint256 public start = 1513360800;


/**
 * The end time of the sale (new Date("Jan 15 2018 18:00:00 GMT").getTime() / 1000)
 */ 
uint256 public end = 1516039200;



/**
 * Two months after the sale ends used to retrieve unclaimed refunds (new Date("Mar 15 2018 18:00:00 GMT").getTime() / 1000)
 */
uint256 public twoMonthsLater = 1521136800;


/**
* Token for minting purposes
*/
CTNToken public token;

/**
* The address to store eth in during sale 
*/
address public vault;


/**
* How much ETH each user has sent to this contract. For softcap unmet refunds
*/
mapping(address => uint256) investments;


/**
* Every purchase during the sale
*/
event TokenSold(address recipient, uint256 etherAmount, uint256 ctnAmount, bool bonus);


/**
* Triggered when tokens are transferred.
*/
event PriceUpdated(uint256 amount);

/**
* Only make certain changes before the sale starts
*/
modifier isPreSale(){
     require(now < start);
    _;
}

/**
* Is the sale still on
*/
modifier isSaleOn() {
    require(now >= start && now <= end);
    _;
}

/**
* Has the sale completed
*/
modifier isSaleFinished() {
    
    bool hitHardCap = token.totalSupply().sub(token.baseSupply()) >= hardCap;
    require(now > end || hitHardCap);
    
    _;
}

/**
* Has the sale completed
*/
modifier isTwoMonthsLater() {
    require(now > twoMonthsLater);
    _;
}

/**
* Make sure we are under the hardcap
*/
modifier isUnderHardCap() {

    bool underHard = token.totalSupply().sub(token.baseSupply()) <= hardCap;
    require(underHard);
    _;
}

/**
* Make sure we are over the soft cap
*/
modifier isOverSoftCap() {
    bool overSoft = token.totalSupply().sub(token.baseSupply()) >= softCap;
    require(overSoft);
    _;
}

/**
* Make sure we are over the soft cap
*/
modifier isUnderSoftCap() {
    bool underSoft = token.totalSupply().sub(token.baseSupply()) < softCap;
    require(underSoft);
    _;
}

/** 
*   The token sale constructor
*/
function CTNTokenSale() public {
    hardCap = 10500000 * 1 ether;
    softCap = 500000 * 1 ether;
    bonusCap = 2000000 * 1 ether;
    tokensPerETH = 536; //Tokens per 1 ETH
    token = new CTNToken();
    vault = 0x6e794AAA2db51fC246b1979FB9A9849f53919D1E; 
}

/**
* Update the ETH price for the token sale
*/
function updatePrice(uint256 _newPrice) public onlyOwner isPreSale {
    tokensPerETH = _newPrice;
    PriceUpdated(_newPrice);
}


/**
* Allows user to buy coins if we are under the hardcap also adds a bonus if under the bonus amount
*/
function createTokens(address recipient) public isUnderHardCap isSaleOn payable {

    uint256 amount = msg.value;
    uint256 tokens = tokensPerETH.mul(amount);
    bool bonus = false;
    
    if (token.totalSupply().sub(token.baseSupply()) < bonusCap) {
        bonus = true;
        tokens = tokens.add(tokens.div(5));
    }
    
    //Add the amount to user invetment total
    investments[msg.sender] = investments[msg.sender].add(msg.value);
    
    token.mint(recipient, tokens);
    
    TokenSold(recipient, amount, tokens, bonus);
}


/**
 * Withdrawl the funds from the contract.
 * Make the token tradeable and finish minting
 */ 
function cleanup() public isTwoMonthsLater {
    vault.transfer(this.balance);
    token.finishMinting();
    token.makeTradable();
}

function destroy() public onlyOwner isTwoMonthsLater {
     token.finishMinting();
     token.makeTradable();
     token.transferOwnership(owner);
     selfdestruct(vault);
}


/**
 * Withdrawl the funds from the contract.
 * Make the token tradeable and finish minting
 */ 
function withdrawl() public isSaleFinished isOverSoftCap {
    vault.transfer(this.balance);
    //Finish the minting and make tradeable before we own the token contract
    token.finishMinting();
    token.makeTradable();
   
}

/**
 * If the soft cap has not been reached and the sale is over investors can reclaim their funds
 */ 
function refund() public isSaleFinished isUnderSoftCap {
    uint256 amount = investments[msg.sender];
    investments[msg.sender] = investments[msg.sender].sub(amount);
    msg.sender.transfer(amount);
}



/**
 * Get the ETH balance of this contract
 */ 
function getBalance() public constant returns (uint256 totalAmount) {
      totalAmount = this.balance;
}



/**
* Fallback function which receives ether and created the appropriate number of tokens for the 
* msg.sender.
*/
function() external payable {
    createTokens(msg.sender);
}
}