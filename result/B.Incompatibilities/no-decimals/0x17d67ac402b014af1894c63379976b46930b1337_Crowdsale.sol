pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        require(_value <= balances[msg.sender]);

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
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract MintableToken is PausableToken {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract TokenImpl is MintableToken {
    string public name;
    string public symbol;

    // how many token units a buyer gets per ether
    uint256 public rate;

    uint256 public eth_decimal_num = 100000;

    // the target token
    ERC20Basic public targetToken;

    uint256 public exchangedNum;

    event Exchanged(address _owner, uint256 _value);

    function TokenImpl(string _name, string _symbol, uint256 _decimal_num) public {
        name = _name;
        symbol = _symbol;
        eth_decimal_num = _decimal_num;
        paused = true;
    }
    /**
      * @dev exchange tokens of _exchanger.
      */
    function exchange(address _exchanger, uint256 _value) internal {
        require(canExchange());
        uint256 _tokens = (_value.mul(rate)).div(eth_decimal_num);
        targetToken.transfer(_exchanger, _tokens);
        exchangedNum = exchangedNum.add(_value);
        Exchanged(_exchanger, _tokens);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (_to == address(this) || _to == owner) {
            exchange(msg.sender, _value);
        }
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (_to == address(this) || _to == owner) {
            exchange(msg.sender, _value);
        }
        return super.transfer(_to, _value);
    }

    function balanceOfTarget(address _owner) public view returns (uint256 targetBalance) {
        if (targetToken != address(0)) {
            return targetToken.balanceOf(_owner);
        } else {
            return 0;
        }
    }

    function canExchangeNum() public view returns (uint256) {
        if (canExchange()) {
            uint256 _tokens = targetToken.balanceOf(this);
            return (eth_decimal_num.mul(_tokens)).div(rate);
        } else {
            return 0;
        }
    }

    function updateTargetToken(address _target, uint256 _rate) onlyOwner public {
        rate = _rate;
        targetToken = ERC20Basic(_target);
    }

    function canExchange() public view returns (bool) {
        return targetToken != address(0) && rate > 0;
    }


}

contract Crowdsale is Pausable {
    using SafeMath for uint256;

    string public projectName;

    string public tokenName;
    string public tokenSymbol;

    // how many token units a buyer gets per ether
    uint256 public rate;

    // amount of raised money in wei, decimals is 5
    uint256 public ethRaised;
    uint256 public eth_decimal_num = 100000;

    // cap of money in wei
    uint256 public cap;

    // The token being sold
    TokenImpl public token;

    // the target token
    ERC20Basic public targetToken;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value);
    event IncreaseCap(uint256 cap);
    event DecreaseCap(uint256 cap);


    function Crowdsale(string _projectName, string _tokenName, string _tokenSymbol, uint256 _cap) public {
        require(_cap > 0);
        projectName = _projectName;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        cap = _cap.mul(eth_decimal_num);
        token = createTokenContract();
    }

    function newCrowdSale(string _projectName, string _tokenName,
        string _tokenSymbol, uint256 _cap) onlyOwner public {
        require(_cap > 0);
        projectName = _projectName;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        cap = _cap.mul(eth_decimal_num);
        ethRaised = 0;
        token.transferOwnership(owner);
        token = createTokenContract();
        rate = 0;
        targetToken = ERC20Basic(0);
    }


    function createTokenContract() internal returns (TokenImpl) {
        return new TokenImpl(tokenName, tokenSymbol, eth_decimal_num);
    }

    // fallback function can be used to buy tokens
    function() external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) whenNotPaused public payable {
        require(beneficiary != address(0));
        require(msg.value >= (0.00001 ether));

        uint256 ethAmount = (msg.value.mul(eth_decimal_num)).div(1 ether);

        // update state
        ethRaised = ethRaised.add(ethAmount);
        require(ethRaised <= cap);

        token.mint(beneficiary, ethAmount);
        TokenPurchase(msg.sender, beneficiary, ethAmount);

        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        owner.transfer(msg.value);
    }

    // increase the amount of eth
    function increaseCap(uint256 _cap_inc) onlyOwner public {
        require(_cap_inc > 0);
        cap = cap.add(_cap_inc.mul(eth_decimal_num));
        IncreaseCap(cap);
    }

    function decreaseCap(uint256 _cap_dec) onlyOwner public {
        require(_cap_dec > 0);
        cap = cap.sub(_cap_dec.mul(eth_decimal_num));
        if (cap <= ethRaised) {
            cap = ethRaised;
        }
        DecreaseCap(cap);
    }

    function saleRatio() public view returns (uint256 ratio) {
        if (cap == 0) {
            return 0;
        } else {
            return ethRaised.mul(10000).div(cap);
        }
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return token.balanceOf(_owner);
    }

    function balanceOfTarget(address _owner) public view returns (uint256 targetBalance) {
        return token.balanceOfTarget(_owner);
    }

    function canExchangeNum() public view returns (uint256) {
        return token.canExchangeNum();
    }

    function updateTargetToken(address _target, uint256 _rate) onlyOwner public {
        rate = _rate;
        targetToken = ERC20Basic(_target);
        token.updateTargetToken(_target, _rate);
    }

    /**
     * @dev called by the owner to transfer the target token to owner from this contact
     */
    function releaseTargetToken(uint256 _value) onlyOwner public returns (bool) {
        if (targetToken != address(0)) {
            return targetToken.transfer(owner, _value);
        } else {
            return false;
        }
    }


    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pauseToken() onlyOwner public {
        token.pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpauseToken() onlyOwner public {
        token.unpause();
    }


    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return ethRaised >= cap;
    }

}