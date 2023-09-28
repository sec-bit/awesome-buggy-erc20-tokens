pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
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
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}


/// @dev Implements access control to the Chronos contract.
contract ChronosAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;
    
    function ChronosAccessControl() public {
        // The creator of the contract is the initial CFO.
        cfoAddress = msg.sender;
    }
    
    /// @dev Access modifier for CFO-only functionality.
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current contract owner.
    /// @param _newCFO The address of the new CFO.
    function setCFO(address _newCFO) external onlyOwner {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
}


/// @dev Defines base data structures for Chronos.
contract ChronosBase is ChronosAccessControl {
    using SafeMath for uint256;
 
    /// @notice Boolean indicating whether a game is live.
    bool public gameStarted;
    
    /// @notice The player who started the game.
    address public gameStarter;
    
    /// @notice The last player to have entered.
    address public lastPlayer;
    
    /// @notice The timestamp the last wager times out.
    uint256 public lastWagerTimeoutTimestamp;

    /// @notice The number of seconds before the game ends.
    uint256 public timeout;
    
    /// @notice The number of seconds before the game ends -- setting
    /// for the next game.
    uint256 public nextTimeout;
    
    /// @notice The minimum number of seconds before the game ends.
    uint256 public minimumTimeout;
    
    /// @notice The minmum number of seconds before the game ends --
    /// setting for the next game.
    uint256 public nextMinimumTimeout;
    
    /// @notice The number of wagers required to move to the
    /// minimum timeout.
    uint256 public numberOfWagersToMinimumTimeout;
    
    /// @notice The number of wagers required to move to the
    /// minimum timeout -- setting for the next game.
    uint256 public nextNumberOfWagersToMinimumTimeout;
    
    /// @notice The wager index of the the current wager in the game.
    uint256 public wagerIndex = 0;
    
    /// @notice Calculate the current game's timeout.
    function calculateTimeout() public view returns(uint256) {
        if (wagerIndex >= numberOfWagersToMinimumTimeout || numberOfWagersToMinimumTimeout == 0) {
            return minimumTimeout;
        } else {
            // This cannot underflow, as timeout is guaranteed to be
            // greater than or equal to minimumTimeout.
            uint256 difference = timeout - minimumTimeout;
            
            // Calculate the decrease in timeout, based on the number of wagers performed.
            uint256 decrease = difference.mul(wagerIndex).div(numberOfWagersToMinimumTimeout);
            
            // This subtraction cannot underflow, as decrease is guaranteed to be less than or equal to timeout.            
            return (timeout - decrease);
        }
    }
}


/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}


/// @dev Defines base finance functionality for Chronos.
contract ChronosFinance is ChronosBase, PullPayment {
    /// @notice The dev fee in 1/1000th
    /// of a percentage.
    uint256 public feePercentage = 2500;
    
    /// @notice The game starter fee.
    uint256 public gameStarterDividendPercentage = 1000;
    
    /// @notice The wager price.
    uint256 public price;
    
    /// @notice The wager price -- setting for the next game.
    uint256 public nextPrice;
    
    /// @notice The current prize pool (in wei).
    uint256 public prizePool;
    
    /// @notice The current 7th wager pool (in wei).
    uint256 public wagerPool;
    
    /// @notice Sets a new game starter dividend percentage.
    /// @param _gameStarterDividendPercentage The new game starter dividend percentage.
    function setGameStartedDividendPercentage(uint256 _gameStarterDividendPercentage) external onlyCFO {
        // Game started dividend percentage must be 0.5% at least and 4% at the most.
        require(500 <= _gameStarterDividendPercentage && _gameStarterDividendPercentage <= 4000);
        
        gameStarterDividendPercentage = _gameStarterDividendPercentage;
    }
    
    /// @dev Send funds to a beneficiary. If sending fails, assign
    /// funds to the beneficiary's balance for manual withdrawal.
    /// @param beneficiary The beneficiary's address to send funds to
    /// @param amount The amount to send.
    function _sendFunds(address beneficiary, uint256 amount) internal {
        if (!beneficiary.send(amount)) {
            // Failed to send funds. This can happen due to a failure in
            // fallback code of the beneficiary, or because of callstack
            // depth.
            // Send funds asynchronously for manual withdrawal by the
            // beneficiary.
            asyncSend(beneficiary, amount);
        }
    }
    
    /// @notice Withdraw (unowed) contract balance.
    function withdrawFreeBalance() external onlyCFO {
        // Calculate the free (unowed) balance.
        uint256 freeBalance = this.balance.sub(totalPayments).sub(prizePool).sub(wagerPool);
        
        cfoAddress.transfer(freeBalance);
    }
}


/// @dev Defines core Chronos functionality.
contract ChronosCore is ChronosFinance {
    
    function ChronosCore(uint256 _price, uint256 _timeout, uint256 _minimumTimeout, uint256 _numberOfWagersToMinimumTimeout) public {
        require(_timeout >= _minimumTimeout);
        
        nextPrice = _price;
        nextTimeout = _timeout;
        nextMinimumTimeout = _minimumTimeout;
        nextNumberOfWagersToMinimumTimeout = _numberOfWagersToMinimumTimeout;
        NextGame(nextPrice, nextTimeout, nextMinimumTimeout, nextNumberOfWagersToMinimumTimeout);
    }
    
    event NextGame(uint256 price, uint256 timeout, uint256 minimumTimeout, uint256 numberOfWagersToMinimumTimeout);
    event Start(address indexed starter, uint256 timestamp, uint256 price, uint256 timeout, uint256 minimumTimeout, uint256 numberOfWagersToMinimumTimeout);
    event End(address indexed winner, uint256 timestamp, uint256 prize);
    event Play(address indexed player, uint256 timestamp, uint256 timeoutTimestamp, uint256 wagerIndex, uint256 newPrizePool);
    
    /// @notice Participate in the game.
    /// @param startNewGameIfIdle Start a new game if the current game is idle.
    function play(bool startNewGameIfIdle) external payable {
        // Check to see if the game should end. Process payment.
        _processGameEnd();
        
        if (!gameStarted) {
            // If the game is not started, the contract must not be paused.
            require(!paused);
            
            // If the game is not started, the player must be willing to start
            // a new game.
            require(startNewGameIfIdle);
            
            // Set the price and timeout.
            price = nextPrice;
            timeout = nextTimeout;
            minimumTimeout = nextMinimumTimeout;
            numberOfWagersToMinimumTimeout = nextNumberOfWagersToMinimumTimeout;
            
            // Start the game.
            gameStarted = true;
            
            // Set the game starter.
            gameStarter = msg.sender;
            
            // Emit start event.
            Start(msg.sender, block.timestamp, price, timeout, minimumTimeout, numberOfWagersToMinimumTimeout);
        }
        
        // Enough Ether must be supplied.
        require(msg.value >= price);
        
        // Calculate the fees and dividends.
        uint256 fee = price.mul(feePercentage).div(100000);
        uint256 dividend = price.mul(gameStarterDividendPercentage).div(100000);
        uint256 wagerPoolPart = price.mul(2).div(7);
        
        // Calculate the timeout.
        uint256 currentTimeout = calculateTimeout();
        
        // Set the last player, timestamp, timeout timestamp, and increase prize.
        lastPlayer = msg.sender;
        lastWagerTimeoutTimestamp = block.timestamp + currentTimeout;
        prizePool = prizePool.add(price.sub(fee).sub(dividend).sub(wagerPoolPart));
        
        // Emit event.
        Play(msg.sender, block.timestamp, lastWagerTimeoutTimestamp, wagerIndex, prizePool);
        
        // Send the game starter dividend.
        _sendFunds(gameStarter, dividend);
        
        // Give the wager price every 7th wager.
        if (wagerIndex > 0 && (wagerIndex % 7) == 0) {
            // Give the wager prize to the sender.
            msg.sender.transfer(wagerPool);
            
            // Reset the wager pool.
            wagerPool = 0;
        }
        
        // Add funds to the wager pool.
        wagerPool = wagerPool.add(wagerPoolPart);
        
        // Increment the wager index.
        wagerIndex = wagerIndex.add(1);
        
        // Refund any excess Ether sent.
        // This subtraction never underflows, as msg.value is guaranteed
        // to be greater than or equal to price.
        uint256 excess = msg.value - price;
        
        if (excess > 0) {
            msg.sender.transfer(excess);
        }
    }
    
    /// @notice Set the parameters for the next game.
    /// @param _price The price of wagers for the next game.
    /// @param _timeout The timeout in seconds for the next game.
    /// @param _minimumTimeout The minimum timeout in seconds for
    /// the next game.
    /// @param _numberOfWagersToMinimumTimeout The number of wagers
    /// required to move to the minimum timeout for the next game.
    function setNextGame(uint256 _price, uint256 _timeout, uint256 _minimumTimeout, uint256 _numberOfWagersToMinimumTimeout) external onlyCFO {
        require(_timeout >= _minimumTimeout);
    
        nextPrice = _price;
        nextTimeout = _timeout;
        nextMinimumTimeout = _minimumTimeout;
        nextNumberOfWagersToMinimumTimeout = _numberOfWagersToMinimumTimeout;
        NextGame(nextPrice, nextTimeout, nextMinimumTimeout, nextNumberOfWagersToMinimumTimeout);
    } 
    
    /// @notice End the game. Pay prize.
    function endGame() external {
        require(_processGameEnd());
    }
    
    /// @dev End the game. Pay prize.
    function _processGameEnd() internal returns(bool) {
        if (!gameStarted) {
            // No game is started.
            return false;
        }
    
        if (block.timestamp <= lastWagerTimeoutTimestamp) {
            // The game has not yet finished.
            return false;
        }
        
        // Calculate the prize. Any leftover funds for the
        // 7th wager prize is added to the prize pool.
        uint256 prize = prizePool.add(wagerPool);
        
        // The game has finished. Pay the prize to the last player.
        _sendFunds(lastPlayer, prize);
        
        // Emit event.
        End(lastPlayer, lastWagerTimeoutTimestamp, prize);
        
        // Reset the game.
        gameStarted = false;
        gameStarter = 0x0;
        lastPlayer = 0x0;
        lastWagerTimeoutTimestamp = 0;
        wagerIndex = 0;
        prizePool = 0;
        wagerPool = 0;
        
        // Indicate ending the game was successful.
        return true;
    }
}