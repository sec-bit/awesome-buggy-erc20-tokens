pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}


/*****
* @title A DADI Contract
*/
contract DadiSale is Ownable {
    using SafeMath for uint256;

    StandardToken public token;                         // The DADI ERC20 token */
    address[] public saleWallets;

    struct WhitelistUser {
      uint256 pledged;
      uint index;
    }

    struct Investor {
      uint256 tokens;
      uint256 contribution;
      bool distributed;
      uint index;
    }

    uint256 public tokenSupply;
    uint256 public tokensPurchased = 0;
    uint256 public tokenPrice = 500;                    // USD$0.50
    uint256 public ethRate = 200;                       // ETH to USD Rate, set by owner: 1 ETH = ethRate USD
 
    mapping(address => WhitelistUser) private whitelisted;
    address[] private whitelistedIndex;
    mapping(address => Investor) private investors;
    address[] private investorIndex;

    /*****
    * State for Sale Modes
    *  0 - Preparing:            All contract initialization calls
    *  1 - Sale:                 Contract is in the Sale Period
    *  2 - SaleFinalized         Sale period is finalized, no more payments are allowed
    *  3 - Success:              Sale Successful
    *  4 - TokenDistribution:    Sale finished, tokens can be distributed
    *  5 - Closed:               Sale closed, no tokens more can be distributed
    */
    enum SaleState { Preparing, Sale, SaleFinalized, Success, TokenDistribution, Closed }
    SaleState public state = SaleState.Preparing;

    event LogTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 tokens);
    event LogTokenDistribution(address recipient, uint256 tokens);
    event LogRedistributeTokens(address recipient, SaleState _state, uint256 tokens);
    event LogFundTransfer(address wallet, uint256 value);
    event LogRefund(address wallet, uint256 value);
    event LogStateChange(SaleState _state);
    event LogNewWhitelistUser(address indexed userAddress, uint index, uint256 value);

    /*****
    * @dev Modifier to check that amount transferred is not 0
    */
    modifier nonZero() {
        require(msg.value != 0);
        _;
    }

    /*****
    * @dev The constructor function to initialize the sale
    * @param _token                         address   the address of the ERC20 token for the sale
    * @param _tokenSupply                   uint256   the amount of tokens available
    */
    function DadiSale (StandardToken _token, uint256 _tokenSupply) public {
        require(_token != address(0));
        require(_tokenSupply != 0);

        token = StandardToken(_token);
        tokenSupply = _tokenSupply * (uint256(10) ** 18);
    }

    /*****
    * @dev Fallback Function to buy the tokens
    */
    function () public nonZero payable {
        require(state == SaleState.Sale);
        buyTokens(msg.sender, msg.value);
    }

    /*****
    * @dev Allows the contract owner to add a new Sale wallet, used to hold funds safely
    * @param _wallet        address     The address of the wallet
    * @return success       bool        Returns true if executed successfully
    */
    function addSaleWallet (address _wallet) public onlyOwner returns (bool) {
        require(_wallet != address(0));
        saleWallets.push(_wallet);
        return true;
    }

    /*****
    * @dev Allows the contract owner to a single whitelist user
    * @param userAddress     address      The wallet address to whitelist
    * @param pledged         uint256      The amount pledged by the user
    */
    function addWhitelistUser(address userAddress, uint256 pledged) public onlyOwner {
        if (!isWhitelisted(userAddress)) {
            whitelisted[userAddress].index = whitelistedIndex.push(userAddress) - 1;
          
            LogNewWhitelistUser(userAddress, whitelisted[userAddress].index, pledged);
        }

        whitelisted[userAddress].pledged = pledged * 1000;
    }

    /*****
    * @dev Calculates the number of tokens that can be bought for the amount of Wei transferred
    * @param _amount    uint256     The amount of money invested by the investor
    * @return tokens    uint256     The number of tokens purchased for the amount invested
    */
    function calculateTokens (uint256 _amount) public constant returns (uint256 tokens) {
        tokens = _amount * ethRate / tokenPrice;
        return tokens;
    }

    /*****
    * @dev Called by the owner of the contract to modify the sale state
    */
    function setState (uint256 _state) public onlyOwner {
        state = SaleState(uint(_state));
        LogStateChange(state);
    }

    /*****
    * @dev Called by the owner of the contract to start the Sale
    * @param rate   uint256  the current ETH USD rate, multiplied by 1000
    */
    function startSale (uint256 rate) public onlyOwner {
        state = SaleState.Sale;
        updateEthRate(rate);
        LogStateChange(state);
    }

    /*****
    * @dev Allow updating the ETH USD exchange rate
    * @param rate   uint256  the current ETH USD rate, multiplied by 1000
    * @return bool  Return true if the contract is in PartnerSale Period
    */
    function updateEthRate (uint256 rate) public onlyOwner returns (bool) {
        require(rate >= 100000);
        
        ethRate = rate;
        return true;
    }

    function updateTokenSupply (uint256 _tokenSupply)  public onlyOwner returns (bool) {
        require(_tokenSupply != 0);
        tokenSupply = _tokenSupply * (uint256(10) ** 18);
        return true;
    }

    /*****
    * @dev Allows transfer of tokens to a recipient who has purchased offline, during the Sale
    * @param _recipient     address     The address of the recipient of the tokens
    * @param _tokens        uint256     The number of tokens purchased by the recipient
    * @return success       bool        Returns true if executed successfully
    */
    function offlineTransaction (address _recipient, uint256 _tokens) public onlyOwner returns (bool) {
        require(_tokens > 0);

        // Convert to a token with decimals 
        uint256 tokens = _tokens * (uint256(10) ** uint8(18));

        // if the number of tokens is greater than available, reject tx
        if (tokens >= getTokensAvailable()) {
            revert();
        }

        addToInvestor(_recipient, 0, tokens);

        // Increase the count of tokens purchased in the sale
        updateSaleParameters(tokens);

        LogTokenPurchase(msg.sender, _recipient, 0, tokens);

        return true;
    }

    /*****
    * @dev Called by the owner of the contract to finalize the ICO
    *      and redistribute funds (if any)
    */
    function finalizeSale () public onlyOwner {
        state = SaleState.Success;
        LogStateChange(state);

        // Transfer any ETH to one of the Sale wallets
        if (this.balance > 0) {
            forwardFunds(this.balance);
        }
    }

    /*****
    * @dev Called by the owner of the contract to close the Sale and redistribute any crumbs.
    * @param recipient     address     The address of the recipient of the tokens
    */
    function closeSale (address recipient) public onlyOwner {
        state = SaleState.Closed;
        LogStateChange(state);

        // redistribute unsold tokens to DADI ecosystem
        uint256 remaining = getTokensAvailable();
        updateSaleParameters(remaining);

        if (remaining > 0) {
            token.transfer(recipient, remaining);
            LogRedistributeTokens(recipient, state, remaining);
        }
    }

    /*****
    * @dev Called by the owner of the contract to allow tokens to be distributed
    */
    function setTokenDistribution () public onlyOwner {
        state = SaleState.TokenDistribution;
        LogStateChange(state);
    }

    /*****
    * @dev Called by the owner of the contract to distribute tokens to investors
    * @param _address       address     The address of the investor for which to distribute tokens
    * @return success       bool        Returns true if executed successfully
    */
    function distributeTokens (address _address) public onlyOwner returns (bool) {
        require(state == SaleState.TokenDistribution);
        
        // get the tokens available for the investor
        uint256 tokens = investors[_address].tokens;
        require(tokens > 0);

        require(investors[_address].distributed == false);

        investors[_address].distributed = true;

        token.transfer(_address, tokens);
      
        LogTokenDistribution(_address, tokens);
        return true;
    }

    /*****
    * @dev Called by the owner of the contract to distribute tokens to investors who used a non-ERC20 wallet address
    * @param _purchaseAddress        address     The address the investor used to buy tokens
    * @param _tokenAddress           address     The address to send the tokens to
    * @return success                bool        Returns true if executed successfully
    */
    function distributeToAlternateAddress (address _purchaseAddress, address _tokenAddress) public onlyOwner returns (bool) {
        require(state == SaleState.TokenDistribution);
        
        // get the tokens available for the investor
        uint256 tokens = investors[_purchaseAddress].tokens;
        require(tokens > 0);

        require(investors[_purchaseAddress].distributed == false);

        investors[_purchaseAddress].distributed = true;

        token.transfer(_tokenAddress, tokens);
      
        LogTokenDistribution(_tokenAddress, tokens);
        return true;
    }

    /*****
    * @dev Called by the owner of the contract to redistribute tokens if an investor has been refunded offline
    * @param investorAddress         address     The address the investor used to buy tokens
    * @param recipient               address     The address to send the tokens to
    */
    function redistributeTokens (address investorAddress, address recipient) public onlyOwner {
        uint256 tokens = investors[investorAddress].tokens;
        require(tokens > 0);
        require(investors[investorAddress].distributed == false);
        
        // set flag, so they can't be redistributed
        investors[investorAddress].distributed = true;
        token.transfer(recipient, tokens);

        LogRedistributeTokens(recipient, state, tokens);
    }

    /*****
    * @dev Get the amount of Sale tokens left for purchase
    * @return uint256 the count of tokens available
    */
    function getTokensAvailable () public constant returns (uint256) {
        return tokenSupply - tokensPurchased;
    }

    /*****
    * @dev Get the total count of tokens purchased in all the Sale periods
    * @return uint256 the count of tokens purchased
    */
    function getTokensPurchased () public constant returns (uint256) {
        return tokensPurchased;
    }

    /*****
    * @dev Get the balance sent to the contract
    * @return uint256 the amount sent to this contract, in Wei
    */
    function getBalance () public constant returns (uint256) {
        return this.balance;
    }

    /*****
    * @dev Converts an amount sent in Wei to the equivalent in USD
    * @param _amount      uint256       the amount sent to the contract, in Wei
    * @return uint256  the amount sent to this contract, in USD
    */
    function ethToUsd (uint256 _amount) public constant returns (uint256) {
        return (_amount * ethRate) / (uint256(10) ** 18);
    }

    /*****
    * @dev Get a whitelisted user
    * @param userAddress      address       the wallet address of the user
    * @return uint256  the amount pledged by the user
    * @return uint     the index of the user
    */
    function getWhitelistUser (address userAddress) public constant returns (uint256 pledged, uint index) {
        require(isWhitelisted(userAddress));
        return(whitelisted[userAddress].pledged, whitelisted[userAddress].index);
    }

    /*****
    * @dev Get count of contributors
    * @return uint     the number of unique contributors
    */
    function getInvestorCount () public constant returns (uint count) {
        return investorIndex.length;
    }

    /*****
    * @dev Get an investor
    * @param _address      address       the wallet address of the investor
    * @return uint256  the amount contributed by the user
    * @return uint256  the number of tokens assigned to the user
    * @return uint     the index of the user
    */
    function getInvestor (address _address) public constant returns (uint256 contribution, uint256 tokens, bool distributed, uint index) {
        require(isInvested(_address));
        return(investors[_address].contribution, investors[_address].tokens, investors[_address].distributed, investors[_address].index);
    }

    /*****
    * @dev Get a user's whitelisted state
    * @param userAddress      address       the wallet address of the user
    * @return bool  true if the user is in the whitelist
    */
    function isWhitelisted (address userAddress) internal constant returns (bool isIndeed) {
        if (whitelistedIndex.length == 0) return false;
        return (whitelistedIndex[whitelisted[userAddress].index] == userAddress);
    }

    /*****
    * @dev Get a user's invested state
    * @param _address      address       the wallet address of the user
    * @return bool  true if the user has already contributed
    */
    function isInvested (address _address) internal constant returns (bool isIndeed) {
        if (investorIndex.length == 0) return false;
        return (investorIndex[investors[_address].index] == _address);
    }

    /*****
    * @dev Update a user's invested state
    * @param _address      address       the wallet address of the user
    * @param _value        uint256       the amount contributed in this transaction
    * @param _tokens       uint256       the number of tokens assigned in this transaction
    */
    function addToInvestor(address _address, uint256 _value, uint256 _tokens) internal {
        // add the user to the investorIndex if this is their first contribution
        if (!isInvested(_address)) {
            investors[_address].index = investorIndex.push(_address) - 1;
        }
      
        investors[_address].tokens = investors[_address].tokens.add(_tokens);
        investors[_address].contribution = investors[_address].contribution.add(_value);
        investors[_address].distributed = false;
    }

    /*****
    * @dev Send ether to the Sale collection wallets
    */
    function forwardFunds (uint256 _value) internal {
        uint accountNumber;
        address account;

        // move funds to a random SaleWallet
        if (saleWallets.length > 0) {
            accountNumber = getRandom(saleWallets.length) - 1;
            account = saleWallets[accountNumber];
            account.transfer(_value);
            LogFundTransfer(account, _value);
        }
    }

    /*****
    * @dev Internal function to assign tokens to the contributor
    * @param _address       address     The address of the contributing investor
    * @param _value         uint256     The amount invested 
    * @return success       bool        Returns true if executed successfully
    */
    function buyTokens (address _address, uint256 _value) internal returns (bool) {
        require(isWhitelisted(_address));

        require(isValidContribution(_address, _value));

        uint256 boughtTokens = calculateTokens(_value);
        require(boughtTokens != 0);

        // if the number of tokens calculated for the given value is 
        // greater than the tokens available, reject the payment
        if (boughtTokens > getTokensAvailable()) {
            revert();
        }

        // update investor state
        addToInvestor(_address, _value, boughtTokens);

        forwardFunds(_value);

        updateSaleParameters(boughtTokens);

        LogTokenPurchase(msg.sender, _address, _value, boughtTokens);

        return true;
    }

    /*****
    * @dev Check that the amount sent in the transaction is below the pledged amount.
    * Factors in previous transactions by the same user
    * @param _address         address     The address of the user making the transaction
    * @param _amount          uint256     The amount sent in the transaction
    * @return        bool        Returns true if the amount is valid
    */
    function isValidContribution (address _address, uint256 _amount) internal constant returns (bool valid) {
        return ethToUsd(_amount + investors[_address].contribution) <= whitelisted[_address].pledged;
    }

    /*****
    * @dev Generates a random number from 1 to max based on the last block hash
    * @param max     uint  the maximum value 
    * @return a random number
    */
    function getRandom(uint max) internal constant returns (uint randomNumber) {
        return (uint(keccak256(block.blockhash(block.number - 1))) % max) + 1;
    }

    /*****
    * @dev Internal function to modify parameters based on tokens bought
    * @param _tokens        uint256     The number of tokens purchased
    */
    function updateSaleParameters (uint256 _tokens) internal {
        tokensPurchased = tokensPurchased.add(_tokens);
    }
}