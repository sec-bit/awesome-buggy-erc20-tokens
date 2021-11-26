//File: node_modules/giveth-common-contracts/contracts/ERC20.sol
pragma solidity ^0.4.15;


/**
 * @title ERC20
 * @dev A standard interface for tokens.
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20 {
  
    /// @dev Returns the total token supply.
    function totalSupply() public constant returns (uint256 supply);

    /// @dev Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) public constant returns (uint256 balance);

    /// @dev Transfers _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @dev Transfers _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @dev Allows _spender to withdraw from your account multiple times, up to the _value amount
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @dev Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}
//File: node_modules/giveth-common-contracts/contracts/Owned.sol
pragma solidity ^0.4.15;


/// @title Owned
/// @author Adrià Massanet <adria@codecontext.io>
/// @notice The Owned contract has an owner address, and provides basic 
///  authorization control functions, this simplifies & the implementation of
///  "user permissions"
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

    /// @dev The constructor sets the `msg.sender` as the`owner` of the contract
    function Owned() {
        owner = msg.sender;
    }

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner.
    function changeOwnership(address _newOwner) onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

    /// @notice `onlyOwner` Proposes to transfer control of the contract to a
    ///  new owner
    /// @param _newOwnerCandidate The address being proposed as the new owner
    function proposeOwnership(address _newOwnerCandidate) onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

    /// @notice Can only be called by the `newOwnerCandidate`, accepts the
    ///  transfer of ownership
    function acceptOwnership() {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

    /// @notice Decentralizes the contract, this operation cannot be undone 
    /// @param _dac `0xdac` has to be entered for this function to work
    function removeOwnership(address _dac) onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        OwnershipRemoved();     
    }

} 

//File: node_modules/giveth-common-contracts/contracts/Escapable.sol
/*
    Copyright 2016, Jordi Baylina
    Contributor: Adrià Massanet <adria@codecontext.io>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

pragma solidity ^0.4.15;





/// @dev `Escapable` is a base level contract built off of the `Owned`
///  contract that creates an escape hatch function to send its ether to
///  `escapeHatchDestination` when called by the `escapeHatchCaller` in the case that
///  something unexpected happens
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist;

    /// @notice The Constructor assigns the `escapeHatchDestination` and the
    ///  `escapeHatchCaller`
    /// @param _escapeHatchDestination The address of a safe location (usu a
    ///  Multisig) to send the ether held in this contract
    /// @param _escapeHatchCaller The address of a trusted account or contract to
    ///  call `escapeHatch()` to send the ether in this contract to the
    ///  `escapeHatchDestination` it would be ideal that `escapeHatchCaller` cannot move
    ///  funds out of `escapeHatchDestination`
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

    /// @notice The `blacklistEscapeTokens()` marks a token in a whitelist to be
    ///   escaped. The proupose is to be done at construction time.
    /// @param _token the be bloacklisted for escape
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        EscapeHatchBlackistedToken(_token);
    }

    function isTokenEscapable(address _token) constant public returns (bool) {
        return !escapeBlacklist[_token];
    }

    /// @notice The `escapeHatch()` should only be called as a last resort if a
    /// security issue is uncovered or something unexpected happened
    /// @param _token to transfer, use 0x0 for ethers
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

        if (_token == 0x0) {
            balance = this.balance;
            escapeHatchDestination.transfer(balance);
            EscapeHatchCalled(_token, balance);
            return;
        }

        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        token.transfer(escapeHatchDestination, balance);
        EscapeHatchCalled(_token, balance);
    }

    /// @notice Changes the address assigned to call `escapeHatch()`
    /// @param _newEscapeHatchCaller The address of a trusted account or contract to
    ///  call `escapeHatch()` to send the ether in this contract to the
    ///  `escapeHatchDestination` it would be ideal that `escapeHatchCaller` cannot
    ///  move funds out of `escapeHatchDestination`
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}

//File: ./contracts/WithdrawContract.sol
pragma solidity ^0.4.18;
/*
    Copyright 2017, Jordi Baylina

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


/// @dev This declares a few functions from `MiniMeToken` so that the
///  `WithdrawContract` can interface with the `MiniMeToken`
contract MiniMeToken {
    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint);
    function totalSupplyAt(uint _blockNumber) public constant returns(uint);
}




/// @dev This is the main contract, it is intended to distribute deposited funds
///  from a TRUSTED `owner` to token holders of a MiniMe style ERC-20 Token;
///  only deposits from the `owner` using the functions `newTokenPayment()` &
///  `newEtherPayment()` will be distributed, any other funds sent to this
///  contract can only be removed via the `escapeHatch()`
contract WithdrawContract is Escapable {

    /// @dev Tracks the deposits made to this contract
    struct Deposit {
        uint block;    // Determines which token holders are able to collect
        ERC20 token;   // The token address (0x0 if ether)
        uint amount;   // The amount deposited in the smallest unit (wei if ETH)
        bool canceled; // True if canceled by the `owner`
    }

    Deposit[] public deposits; // Array of deposits to this contract
    MiniMeToken rewardToken;     // Token that is used for withdraws

    mapping (address => uint) public nextDepositToPayout; // Tracks Payouts
    mapping (address => mapping(uint => bool)) skipDeposits;

/////////
// Constructor
/////////

    /// @notice The Constructor creates the `WithdrawContract` on the blockchain
    ///  the `owner` role is assigned to the address that deploys this contract
    /// @param _rewardToken The address of the token that is used to determine the
    ///  distribution of the deposits according to the balance held at the
    ///  deposit's specified `block`
    /// @param _escapeHatchCaller The address of a trusted account or contract
    ///  to call `escapeHatch()` to send the specified token (or ether) held in
    ///  this contract to the `escapeHatchDestination`
    /// @param _escapeHatchDestination The address of a safe location (usu a
    ///  Multisig) to send the ether and tokens held in this contract when the
    ///  `escapeHatch()` is called
    function WithdrawContract(
        MiniMeToken _rewardToken,
        address _escapeHatchCaller,
        address _escapeHatchDestination)
        Escapable(_escapeHatchCaller, _escapeHatchDestination)
        public
    {
        rewardToken = _rewardToken;
    }

    /// @dev When ether is sent to this contract `newEtherDeposit()` is called
    function () payable public {
        newEtherDeposit(0);
    }
/////////
// Owner Functions
/////////

    /// @notice Adds an ether deposit to `deposits[]`; only the `owner` can
    ///  deposit into this contract
    /// @param _block The block height that determines the snapshot of token
    ///  holders that will be able to withdraw their share of this deposit; this
    ///  block must be set in the past, if 0 it defaults to one block before the
    ///  transaction
    /// @return _idDeposit The id number for the deposit
    function newEtherDeposit(uint _block)
        public onlyOwner payable
        returns (uint _idDeposit)
    {
        require(msg.value>0);
        require(_block < block.number);
        _idDeposit = deposits.length ++;

        // Record the deposit
        Deposit storage d = deposits[_idDeposit];
        d.block = _block == 0 ? block.number -1 : _block;
        d.token = ERC20(0);
        d.amount = msg.value;
        NewDeposit(_idDeposit, ERC20(0), msg.value);
    }

    /// @notice Adds a token deposit to `deposits[]`; only the `owner` can
    ///  call this function and it will only work if the account sending the
    ///  tokens has called `approve()` so that this contract can call
    ///  `transferFrom()` and take the tokens
    /// @param _token The address for the ERC20 that is being deposited
    /// @param _amount The quantity of tokens that is deposited into the
    ///  contract in the smallest unit of tokens (if a token has its decimals
    ///  set to 18 and 1 token is sent, the `_amount` would be 10^18)
    /// @param _block The block height that determines the snapshot of token
    ///  holders that will be able to withdraw their share of this deposit; this
    ///  block must be set in the past, if 0 it defaults to one block before the
    ///  transaction
    /// @return _idDeposit The id number for the deposit
    function newTokenDeposit(ERC20 _token, uint _amount, uint _block)
        public onlyOwner
        returns (uint _idDeposit)
    {
        require(_amount > 0);
        require(_block < block.number);

        // Must `approve()` this contract in a previous transaction
        require( _token.transferFrom(msg.sender, address(this), _amount) );
        _idDeposit = deposits.length ++;

        // Record the deposit
        Deposit storage d = deposits[_idDeposit];
        d.block = _block == 0 ? block.number -1 : _block;
        d.token = _token;
        d.amount = _amount;
        NewDeposit(_idDeposit, _token, _amount);
    }

    /// @notice This function is a failsafe function in case a token is
    ///  deposited that has an issue that could prevent it's withdraw loop break
    ///  (e.g. transfers are disabled), can only be called by the `owner`
    /// @param _idDeposit The id number for the deposit being canceled
    function cancelPaymentGlobally(uint _idDeposit) public onlyOwner {
        require(_idDeposit < deposits.length);
        deposits[_idDeposit].canceled = true;
        CancelPaymentGlobally(_idDeposit);
    }

/////////
// Public Functions
/////////
    /// @notice Sends all the tokens and ether to the token holder by looping
    ///  through all the deposits, determining the appropriate amount by
    ///  dividing the `totalSupply` by the number of tokens the token holder had
    ///  at `deposit.block` for each deposit; this function may have to be
    ///  called multiple times if their are many deposits
    function withdraw() public {
        uint acc = 0; // Accumulates the amount of tokens/ether to be sent
        uint i = nextDepositToPayout[msg.sender]; // Iterates through the deposits
        require(i<deposits.length);
        ERC20 currentToken = deposits[i].token; // Sets the `currentToken` to ether

        require(msg.gas>149000); // Throws if there is no gas to do at least a single transfer.
        while (( i< deposits.length) && ( msg.gas > 148000)) {
            Deposit storage d = deposits[i];

            // Make sure `deposit[i]` shouldn't be skipped
            if ((!d.canceled)&&(!isDepositSkiped(msg.sender, i))) {

                // The current diposti is different of the accumulated until now,
                // so we return the accumulated tokens until now and resset the
                // accumulator.
                if (currentToken != d.token) {
                    nextDepositToPayout[msg.sender] = i;
                    require(doPayment(i-1, msg.sender, currentToken, acc));
                    assert(nextDepositToPayout[msg.sender] == i);
                    currentToken = d.token;
                    acc =0;
                }

                // Accumulate the amount to send for the `currentToken`
                acc +=  d.amount *
                        rewardToken.balanceOfAt(msg.sender, d.block) /
                            rewardToken.totalSupplyAt(d.block);
            }

            i++; // Next deposit :-D
        }
        // Return the accumulated tokens.
        nextDepositToPayout[msg.sender] = i;
        require(doPayment(i-1, msg.sender, currentToken, acc));
        assert(nextDepositToPayout[msg.sender] == i);
    }

    /// @notice This function is a failsafe function in case a token holder
    ///  wants to skip a payment, can only be applied to one deposit at a time
    ///  and only affects the payment for the `msg.sender` calling the function;
    ///  can be undone by calling again with `skip == false`
    /// @param _idDeposit The id number for the deposit being canceled
    /// @param _skip True if the caller wants to skip the payment for `idDeposit`
    function skipPayment(uint _idDeposit, bool _skip) public {
        require(_idDeposit < deposits.length);
        skipDeposits[msg.sender][_idDeposit] = _skip;
        SkipPayment(_idDeposit, _skip);
    }

/////////
// Constant Functions
/////////

    /// @notice Calculates the amount of a given token (or ether) the holder can
    ///  receive
    /// @param _token The address of the token being queried, 0x0 = ether
    /// @param _holder The address being checked
    /// @return The amount of `token` able to be collected in the smallest
    ///  unit of the `token` (wei for ether)
    function getPendingReward(ERC20 _token, address _holder) public constant returns(uint) {
        uint acc =0;
        for (uint i=nextDepositToPayout[msg.sender]; i<deposits.length; i++) {
            Deposit storage d = deposits[i];
            if ((d.token == _token)&&(!d.canceled) && (!isDepositSkiped(_holder, i))) {
                acc +=  d.amount *
                    rewardToken.balanceOfAt(_holder, d.block) /
                        rewardToken.totalSupplyAt(d.block);
            }
        }
        return acc;
    }

    /// @notice A check to see if a specific address has anything to collect
    /// @param _holder The address being checked for available deposits
    /// @return True if there are payments to be collected
    function canWithdraw(address _holder) public constant returns (bool) {
        if (nextDepositToPayout[_holder] == deposits.length) return false;
        for (uint i=nextDepositToPayout[msg.sender]; i<deposits.length; i++) {
            Deposit storage d = deposits[i];
            if ((!d.canceled) && (!isDepositSkiped(_holder, i))) {
                uint amount =  d.amount *
                    rewardToken.balanceOfAt(_holder, d.block) /
                        rewardToken.totalSupplyAt(d.block);
                if (amount>0) return true;
            }
        }
        return false;
    }

    /// @notice Checks how many deposits have been made
    /// @return The number of deposits
    function nDeposits() public constant returns (uint) {
        return deposits.length;
    }

    /// @notice Checks to see if a specific deposit has been skipped
    /// @param _holder The address being checked for available deposits
    /// @param _idDeposit The id number for the deposit being canceled
    /// @return True if the specified deposit has been skipped
    function isDepositSkiped(address _holder, uint _idDeposit) public constant returns(bool) {
        return skipDeposits[_holder][_idDeposit];
    }

/////////
// Internal Functions
/////////

    /// @notice Transfers `amount` of `token` to `dest`, only used internally,
    ///  and does not throw, will always return `true` or `false`
    /// @param _token The address for the ERC20 that is being transferred
    /// @param _dest The destination address of the transfer
    /// @param _amount The quantity of tokens that is being transferred
    ///  denominated in the smallest unit of tokens (if a token has its decimals
    ///  set to 18 and 1 token is being transferred the `amount` would be 10^18)
    /// @return True if the payment succeeded
    function doPayment(uint _idDeposit,  address _dest, ERC20 _token, uint _amount) internal returns (bool) {
        if (_amount == 0) return true;
        if (address(_token) == 0) {
            if (!_dest.send(_amount)) return false;   // If we can't send, we continue...
        } else {
            if (!_token.transfer(_dest, _amount)) return false;
        }
        Withdraw(_idDeposit, _dest, _token, _amount);
        return true;
    }

    function getBalance(ERC20 _token, address _holder) internal constant returns (uint) {
        if (address(_token) == 0) {
            return _holder.balance;
        } else {
            return _token.balanceOf(_holder);
        }
    }

/////////
// Events
/////////

    event Withdraw(uint indexed lastIdPayment, address indexed holder, ERC20 indexed tokenContract, uint amount);
    event NewDeposit(uint indexed idDeposit, ERC20 indexed tokenContract, uint amount);
    event CancelPaymentGlobally(uint indexed idDeposit);
    event SkipPayment(uint indexed idDeposit, bool skip);
}