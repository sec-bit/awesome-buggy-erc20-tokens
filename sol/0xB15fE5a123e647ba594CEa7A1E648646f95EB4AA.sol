/*
  Copyright 2017 Sharder Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity ^0.4.18;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/**
* @title Sharder Protocol Token.
* For more information about this token sale, please visit https://sharder.org
* @author Ben - <xy@sharder.org>.
* @dev https://github.com/ethereum/EIPs/issues/20
* @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
*/
contract SharderToken {
    using SafeMath for uint;
    string public constant NAME = "Sharder Storage";
    string public constant SYMBOL = "SS";
    uint public constant DECIMALS = 18;
    uint public totalSupply;

    mapping (address => mapping (address => uint256))  public allowed;
    mapping (address => uint) public balances;

    /// This is where we hold ether during this crowdsale. We will not transfer any ether
    /// out of this address before we invocate the `closeCrowdsale` function to finalize the crowdsale.
    /// This promise is not guanranteed by smart contract by can be verified with public
    /// Ethereum transactions data available on several blockchain browsers.
    /// This is the only address from which `startCrowdsale` and `closeCrowdsale` can be invocated.
    address public owner;

    /// Admin account used to manage after crowdsale
    address public admin;

    mapping (address => bool) public accountLockup;
    mapping (address => uint) public accountLockupTime;
    mapping (address => bool) public frozenAccounts;

    ///   +-----------------------------------------------------------------------------------+
    ///   |                        SS Token Issue Plan - First Round                          |
    ///   +-----------------------------------------------------------------------------------+
    ///   |  Total Sale  |   Airdrop    |  Community Reserve  |  Team Reserve | System Reward |
    ///   +-----------------------------------------------------------------------------------+
    ///   |     50%      |     10%      |         10%         |  Don't Issued | Don't Issued  |
    ///   +-----------------------------------------------------------------------------------+
    ///   | 250,000,000  |  50,000,000  |     50,000,000      |      None     |      None     |
    ///   +-----------------------------------------------------------------------------------+
    uint256 internal constant FIRST_ROUND_ISSUED_SS = 350000000000000000000000000;

    /// Maximum amount of fund to be raised, the sale ends on reaching this amount.
    uint256 public constant HARD_CAP = 1500 ether;

    /// It will be refuned if crowdsale can't acheive the soft cap, all ethers will be refuned.
    uint256 public constant SOFT_CAP = 1000 ether;

    /// 1 ether exchange rate
    /// base the 7-day average close price (Feb.15 through Feb.21, 2018) on CoinMarketCap.com at Feb.21.
    uint256 public constant BASE_RATE = 20719;

    /// 1 ether == 1000 finney
    /// Min contribution: 0.1 ether
    uint256 public constant CONTRIBUTION_MIN = 100 finney;

    /// Max contribution: 5 ether
    uint256 public constant CONTRIBUTION_MAX = 5000 finney;

    /// Sold SS tokens in crowdsale
    uint256 public soldSS = 0;

    uint8[2] internal bonusPercentages = [
    0,
    0
    ];

    uint256 internal constant MAX_PROMOTION_SS = 0;
    uint internal constant NUM_OF_PHASE = 2;
    uint internal constant BLOCKS_PER_PHASE = 86400;

    /// Crowdsale start block number.
    uint public saleStartAtBlock = 0;

    /// Crowdsale ended block number.
    uint public saleEndAtBlock = 0;

    /// Unsold ss token whether isssued.
    bool internal unsoldTokenIssued = false;

    /// Goal whether achieved
    bool internal isGoalAchieved = false;

    /// Received ether
    uint256 internal totalEthReceived = 0;

    /// Issue event index starting from 0.
    uint256 internal issueIndex = 0;

    /*
     * EVENTS
     */
    /// Emitted only once after token sale starts.
    event SaleStarted();

    /// Emitted only once after token sale ended (all token issued).
    event SaleEnded();

    /// Emitted when a function is invocated by unauthorized addresses.
    event InvalidCaller(address caller);

    /// Emitted when a function is invocated without the specified preconditions.
    /// This event will not come alone with an exception.
    event InvalidState(bytes msg);

    /// Emitted for each sucuessful token purchase.
    event Issue(uint issueIndex, address addr, uint ethAmount, uint tokenAmount);

    /// Emitted if the token sale succeeded.
    event SaleSucceeded();

    /// Emitted if the token sale failed.
    /// When token sale failed, all Ether will be return to the original purchasing
    /// address with a minor deduction of transaction fee（gas)
    event SaleFailed();

    // This notifies clients about the amount to transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount to approve
    event Approval(address indexed owner, address indexed spender, uint value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal isNotFrozen {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _transferTokensWithDecimal The amount to be transferred.
    */
    function transfer(address _to, uint _transferTokensWithDecimal) public {
        _transfer(msg.sender, _to, _transferTokensWithDecimal);
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _transferTokensWithDecimal uint the amout of tokens to be transfered
    */
    function transferFrom(address _from, address _to, uint _transferTokensWithDecimal) public returns (bool success) {
        require(_transferTokensWithDecimal <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] -= _transferTokensWithDecimal;
        _transfer(_from, _to, _transferTokensWithDecimal);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    /**
     * Set allowance for other address
     * Allows `_spender` to spend no more than `_approveTokensWithDecimal` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _approveTokensWithDecimal the max amount they can spend
     */
    function approve(address _spender, uint256 _approveTokensWithDecimal) public isNotFrozen returns (bool success) {
        allowed[msg.sender][_spender] = _approveTokensWithDecimal;
        Approval(msg.sender, _spender, _approveTokensWithDecimal);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens than an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifing the amount of tokens still avaible for the spender.
     */
    function allowance(address _owner, address _spender) internal constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    /**
       * Destroy tokens
       * Remove `_value` tokens from the system irreversibly
       *
       * @param _burnedTokensWithDecimal the amount of reserve tokens. !!IMPORTANT is 18 DECIMALS
       */
    function burn(uint256 _burnedTokensWithDecimal) public returns (bool success) {
        require(balances[msg.sender] >= _burnedTokensWithDecimal);   /// Check if the sender has enough
        balances[msg.sender] -= _burnedTokensWithDecimal;            /// Subtract from the sender
        totalSupply -= _burnedTokensWithDecimal;                      /// Updates totalSupply
        Burn(msg.sender, _burnedTokensWithDecimal);
        return true;
    }

    /**
     * Destroy tokens from other account
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _burnedTokensWithDecimal the amount of reserve tokens. !!IMPORTANT is 18 DECIMALS
     */
    function burnFrom(address _from, uint256 _burnedTokensWithDecimal) public returns (bool success) {
        require(balances[_from] >= _burnedTokensWithDecimal);                /// Check if the targeted balance is enough
        require(_burnedTokensWithDecimal <= allowed[_from][msg.sender]);    /// Check allowance
        balances[_from] -= _burnedTokensWithDecimal;                        /// Subtract from the targeted balance
        allowed[_from][msg.sender] -= _burnedTokensWithDecimal;             /// Subtract from the sender's allowance
        totalSupply -= _burnedTokensWithDecimal;                            /// Update totalSupply
        Burn(_from, _burnedTokensWithDecimal);
        return true;
    }

    /*
     * MODIFIERS
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    modifier beforeStart {
        require(!saleStarted());
        _;
    }

    modifier inProgress {
        require(saleStarted() && !saleEnded());
        _;
    }

    modifier afterEnd {
        require(saleEnded());
        _;
    }

    modifier isNotFrozen {
        require( frozenAccounts[msg.sender] != true && now > accountLockupTime[msg.sender] );
        _;
    }

    /**
     * CONSTRUCTOR
     *
     * @dev Initialize the Sharder Token
     */
    function SharderToken() public {
        owner = msg.sender;
        admin = msg.sender;
        totalSupply = FIRST_ROUND_ISSUED_SS;
    }

    /*
     * PUBLIC FUNCTIONS
     */

    ///@dev Set admin account.
    function setAdmin(address _address) public onlyOwner {
       admin=_address;
    }

    ///@dev Set frozen status of account.
    function setAccountFrozenStatus(address _address, bool _frozenStatus) public onlyAdmin {
        require(unsoldTokenIssued);
        frozenAccounts[_address] = _frozenStatus;
    }

    /// @dev Lockup account till the date. Can't lockup again when this account locked already.
    /// 1 year = 31536000 seconds
    /// 0.5 year = 15768000 seconds
    function lockupAccount(address _address, uint _lockupSeconds) public onlyAdmin {
        require((accountLockup[_address] && now > accountLockupTime[_address]) || !accountLockup[_address]);

        // frozen time = now + _lockupSeconds
        accountLockupTime[_address] = now + _lockupSeconds;
        accountLockup[_address] = true;
    }

    /// @dev Start the crowdsale.
    function startCrowdsale(uint _saleStartAtBlock) public onlyOwner beforeStart {
        require(_saleStartAtBlock > block.number);
        saleStartAtBlock = _saleStartAtBlock;
        SaleStarted();
    }

    /// @dev Close the crowdsale and issue unsold tokens to `owner` address.
    function closeCrowdsale() public onlyOwner afterEnd {
        require(!unsoldTokenIssued);

        if (totalEthReceived >= SOFT_CAP) {
            saleEndAtBlock = block.number;
            issueUnsoldToken();
            SaleSucceeded();
        } else {
            SaleFailed();
        }
    }

    /// @dev goal achieved ahead of time
    function goalAchieved() public onlyOwner {
        require(!isGoalAchieved && softCapReached());
        isGoalAchieved = true;
        closeCrowdsale();
    }

    /// @dev Returns the current price.
    function price() public constant returns (uint tokens) {
        return computeTokenAmount(1 ether);
    }

    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function () public payable {
        issueToken(msg.sender);
    }

    /// @dev Issue token based on ether received.
    /// @param recipient Address that newly issued token will be sent to.
    function issueToken(address recipient) public payable inProgress {
        // Personal cap check
        require(balances[recipient].div(BASE_RATE).add(msg.value) <= CONTRIBUTION_MAX);
        // Contribution cap check
        require(CONTRIBUTION_MIN <= msg.value && msg.value <= CONTRIBUTION_MAX);

        uint tokens = computeTokenAmount(msg.value);

        totalEthReceived = totalEthReceived.add(msg.value);
        soldSS = soldSS.add(tokens);

        balances[recipient] = balances[recipient].add(tokens);
        Issue(issueIndex++,recipient,msg.value,tokens);

        require(owner.send(msg.value));
    }

    /// @dev Issue token for reserve.
    /// @param recipient Address that newly issued reserve token will be sent to.
    /// @param _issueTokensWithDecimal the amount of reserve tokens. !!IMPORTANT is 18 DECIMALS
    function issueReserveToken(address recipient, uint256 _issueTokensWithDecimal) onlyOwner public {
        balances[recipient] = balances[recipient].add(_issueTokensWithDecimal);
        totalSupply = totalSupply.add(_issueTokensWithDecimal);
        Issue(issueIndex++,recipient,0,_issueTokensWithDecimal);
    }

    /*
     * INTERNAL FUNCTIONS
     */
    /// @dev Compute the amount of SS token that can be purchased.
    /// @param ethAmount Amount of Ether to purchase SS.
    /// @return Amount of SS token to purchase
    function computeTokenAmount(uint ethAmount) internal constant returns (uint tokens) {
        uint phase = (block.number - saleStartAtBlock).div(BLOCKS_PER_PHASE);

        // A safe check
        if (phase >= bonusPercentages.length) {
            phase = bonusPercentages.length - 1;
        }

        uint tokenBase = ethAmount.mul(BASE_RATE);

        //Check promotion supply and phase bonus
        uint tokenBonus = 0;
        if(totalEthReceived * BASE_RATE < MAX_PROMOTION_SS) {
            tokenBonus = tokenBase.mul(bonusPercentages[phase]).div(100);
        }

        tokens = tokenBase.add(tokenBonus);
    }

    /// @dev Issue unsold token to `owner` address.
    function issueUnsoldToken() internal {
        if (unsoldTokenIssued) {
            InvalidState("Unsold token has been issued already");
        } else {
            // Add another safe guard
            require(soldSS > 0);

            uint256 unsoldSS = totalSupply.sub(soldSS);
            // Issue 'unsoldToken' to the admin account.
            balances[owner] = balances[owner].add(unsoldSS);
            Issue(issueIndex++,owner,0,unsoldSS);

            unsoldTokenIssued = true;
        }
    }

    /// @return true if sale has started, false otherwise.
    function saleStarted() public constant returns (bool) {
        return (saleStartAtBlock > 0 && block.number >= saleStartAtBlock);
    }

    /// @return true if sale has ended, false otherwise.
    /// Sale ended in: a) end time of crowdsale reached, b) hard cap reached, c) goal achieved ahead of time
    function saleEnded() public constant returns (bool) {
        return saleStartAtBlock > 0 && (saleDue() || hardCapReached() || isGoalAchieved);
    }

    /// @return true if sale is due when the last phase is finished.
    function saleDue() internal constant returns (bool) {
        return block.number >= saleStartAtBlock + BLOCKS_PER_PHASE * NUM_OF_PHASE;
    }

    /// @return true if the hard cap is reached.
    function hardCapReached() internal constant returns (bool) {
        return totalEthReceived >= HARD_CAP;
    }

    /// @return true if the soft cap is reached.
    function softCapReached() internal constant returns (bool) {
        return totalEthReceived >= SOFT_CAP;
    }
}