pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @dev Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/v1.4.0/contracts/math/SafeMath.sol
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
        assert(b > 0);
        uint256 c = a / b;
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
 * @dev Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/v1.4.0/contracts/ownership/Ownable.sol
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
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
 * @dev Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/v1.4.0/contracts/lifecycle/Pausable.sol
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
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 * @dev Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/v1.4.0/contracts/token/ERC20Basic.sol
 */
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 * @dev Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/v1.4.0/contracts/token/BasicToken.sol
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/v1.4.0/contracts/token/ERC20.sol
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/v1.4.0/contracts/token/StandardToken.sol
 */
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        uint256 _allowance = allowed[_from][msg.sender];

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
     * @return A boolean that indicates if the operation was successful.
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
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/v1.4.0/contracts/token/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    address public mintAddress;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier onlyMint() {
        require(msg.sender == mintAddress);
        _;
    }

    /**
     * @dev Function to change address that is allowed to do emission.
     * @param _mintAddress Address of the emission contract.
     */
    function setMintAddress(address _mintAddress) public onlyOwner {
        require(_mintAddress != address(0));
        mintAddress = _mintAddress;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) public onlyMint canMint returns (bool) {
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
    function finishMinting() public onlyMint canMint returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 * @dev Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/v1.4.0/contracts/token/TokenTimelock.sol
 */
contract TokenTimelock {
    // ERC20 basic token contract being held
    ERC20Basic public token;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // timestamp when token release is enabled
    uint256 public releaseTime;

    /**
     * @dev The TokenTimelock constructor sets token address, beneficiary and time to release.
     * @param _token Address of the token
     * @param _beneficiary Address that will receive the tokens after release
     * @param _releaseTime Time that will allow release the tokens
     */
    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
        require(_releaseTime > now);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    /**
     * @dev Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        require(now >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.transfer(beneficiary, amount);
    }
}

/**
 * @title CraftyCrowdsale
 * @dev CraftyCrowdsale is a contract for managing a Crafty token crowdsale.
 */
contract CraftyCrowdsale is Pausable {
    using SafeMath for uint256;

    // Amount received from each address
    mapping(address => uint256) received;

    // The token being sold
    MintableToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public preSaleStart;
    uint256 public preSaleEnd;
    uint256 public saleStart;
    uint256 public saleEnd;

    // amount of tokens sold
    uint256 public issuedTokens = 0;

    // token cap
    uint256 public constant hardCap = 5000000000 * 10**8; // 50%

    // token wallets
    uint256 constant teamCap = 1450000000 * 10**8; // 14.5%
    uint256 constant advisorCap = 450000000 * 10**8; // 4.5%
    uint256 constant bountyCap = 100000000 * 10**8; // 1%
    uint256 constant fundCap = 3000000000 * 10**8; // 30%

    // Number of days the tokens will be locked
    uint256 constant lockTime = 180 days;

    // wallets
    address public etherWallet;
    address public teamWallet;
    address public advisorWallet;
    address public fundWallet;
    address public bountyWallet;

    // timelocked tokens
    TokenTimelock teamTokens;

    uint256 public rate;

    enum State { BEFORE_START, SALE, REFUND, CLOSED }
    State currentState = State.BEFORE_START;

    /**
     * @dev Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);

    /**
     * @dev Event for refund
     * @param to who sent wei
     * @param amount amount of wei refunded
     */
    event Refund(address indexed to, uint256 amount);

    /**
     * @dev modifier to allow token creation only when the sale is on
     */
    modifier saleIsOn() {
        require(
            (
                (now >= preSaleStart && now < preSaleEnd) || 
                (now >= saleStart && now < saleEnd)
            ) && 
            issuedTokens < hardCap && 
            currentState == State.SALE
        );
        _;
    }

    /**
     * @dev modifier to allow action only before sale
     */
    modifier beforeSale() {
        require( now < preSaleStart);
        _;
    }

    /**
     * @dev modifier that fails if state doesn't match
     */
    modifier inState(State _state) {
        require(currentState == _state);
        _;
    }

    /**
     * @dev CraftyCrowdsale constructor sets the token, period and exchange rate
     * @param _token The address of Crafty Token.
     * @param _preSaleStart The start time of pre-sale.
     * @param _preSaleEnd The end time of pre-sale.
     * @param _saleStart The start time of sale.
     * @param _saleEnd The end time of sale.
     * @param _rate The exchange rate of tokens.
     */
    function CraftyCrowdsale(address _token, uint256 _preSaleStart, uint256 _preSaleEnd, uint256 _saleStart, uint256 _saleEnd, uint256 _rate) public {
        require(_token != address(0));
        require(_preSaleStart < _preSaleEnd && _preSaleEnd < _saleStart && _saleStart < _saleEnd);
        require(_rate > 0);

        token = MintableToken(_token);
        preSaleStart = _preSaleStart;
        preSaleEnd = _preSaleEnd;
        saleStart = _saleStart;
        saleEnd = _saleEnd;
        rate = _rate;
    }

    /**
     * @dev Fallback function can be used to buy tokens
     */
    function () public payable {
        if(msg.sender != owner)
            buyTokens();
    }

    /**
     * @dev Function used to buy tokens
     */
    function buyTokens() public saleIsOn whenNotPaused payable {
        require(msg.sender != address(0));
        require(msg.value >= 20 finney);

        uint256 weiAmount = msg.value;
        uint256 currentRate = getRate(weiAmount);

        // calculate token amount to be created
        uint256 newTokens = weiAmount.mul(currentRate).div(10**18);

        require(issuedTokens.add(newTokens) <= hardCap);
        
        issuedTokens = issuedTokens.add(newTokens);
        received[msg.sender] = received[msg.sender].add(weiAmount);
        token.mint(msg.sender, newTokens);
        TokenPurchase(msg.sender, msg.sender, newTokens);

        etherWallet.transfer(msg.value);
    }

    /**
     * @dev Function used to change the exchange rate.
     * @param _rate The new rate.
     */
    function setRate(uint256 _rate) public onlyOwner beforeSale {
        require(_rate > 0);

        rate = _rate;
    }

    /**
     * @dev Function used to set wallets and enable the sale.
     * @param _etherWallet Address of ether wallet.
     * @param _teamWallet Address of team wallet.
     * @param _advisorWallet Address of advisors wallet.
     * @param _bountyWallet Address of bounty wallet.
     * @param _fundWallet Address of fund wallet.
     */
    function setWallets(address _etherWallet, address _teamWallet, address _advisorWallet, address _bountyWallet, address _fundWallet) public onlyOwner inState(State.BEFORE_START) {
        require(_etherWallet != address(0));
        require(_teamWallet != address(0));
        require(_advisorWallet != address(0));
        require(_bountyWallet != address(0));
        require(_fundWallet != address(0));

        etherWallet = _etherWallet;
        teamWallet = _teamWallet;
        advisorWallet = _advisorWallet;
        bountyWallet = _bountyWallet;
        fundWallet = _fundWallet;

        uint256 releaseTime = saleEnd + lockTime;

        // Mint locked tokens
        teamTokens = new TokenTimelock(token, teamWallet, releaseTime);
        token.mint(teamTokens, teamCap);

        // Mint released tokens
        token.mint(advisorWallet, advisorCap);
        token.mint(bountyWallet, bountyCap);
        token.mint(fundWallet, fundCap);

        currentState = State.SALE;
    }

    /**
     * @dev Generate tokens to specific address, necessary to accept other cryptos.
     * @param beneficiary Address of the beneficiary.
     * @param newTokens Amount of tokens to be minted.
     */
    function generateTokens(address beneficiary, uint256 newTokens) public onlyOwner {
        require(beneficiary != address(0));
        require(newTokens > 0);
        require(issuedTokens.add(newTokens) <= hardCap);

        issuedTokens = issuedTokens.add(newTokens);
        token.mint(beneficiary, newTokens);
        TokenPurchase(msg.sender, beneficiary, newTokens);
    }

    /**
     * @dev Finish crowdsale and token minting.
     */
    function finishCrowdsale() public onlyOwner inState(State.SALE) {
        require(now > saleEnd);
        // tokens not sold to fund
        uint256 unspentTokens = hardCap.sub(issuedTokens);
        token.mint(fundWallet, unspentTokens);

        currentState = State.CLOSED;

        token.finishMinting();
    }

    /**
     * @dev Enable refund after sale.
     */
    function enableRefund() public onlyOwner inState(State.CLOSED) {
        currentState = State.REFUND;
    }

    /**
     * @dev Check the amount of wei received by beneficiary.
     * @param beneficiary Address of beneficiary.
     */
    function receivedFrom(address beneficiary) public view returns (uint256) {
        return received[beneficiary];
    }

    /**
     * @dev Function used to claim wei if refund is enabled.
     */
    function claimRefund() public whenNotPaused inState(State.REFUND) {
        require(received[msg.sender] > 0);

        uint256 amount = received[msg.sender];
        received[msg.sender] = 0;
        msg.sender.transfer(amount);
        Refund(msg.sender, amount);
    }

    /**
     * @dev Function used to release token of team wallet.
     */
    function releaseTeamTokens() public {
        teamTokens.release();
    }

    /**
     * @dev Function used to reclaim ether by owner.
     */
    function reclaimEther() public onlyOwner {
        owner.transfer(this.balance);
    }

    /**
     * @dev Get exchange rate based on time and amount.
     * @param amount Amount received.
     * @return An uint256 representing the exchange rate.
     */
    function getRate(uint256 amount) internal view returns (uint256) {
        if(now < preSaleEnd) {
            require(amount >= 6797 finney);

            if(amount <= 8156 finney)
                return rate.mul(105).div(100);
            if(amount <= 9515 finney)
                return rate.mul(1055).div(1000);
            if(amount <= 10874 finney)
                return rate.mul(1065).div(1000);
            if(amount <= 12234 finney)
                return rate.mul(108).div(100);
            if(amount <= 13593 finney)
                return rate.mul(110).div(100);
            if(amount <= 27185 finney)
                return rate.mul(113).div(100);
            if(amount > 27185 finney)
                return rate.mul(120).div(100);
        }

        return rate;
    }
}