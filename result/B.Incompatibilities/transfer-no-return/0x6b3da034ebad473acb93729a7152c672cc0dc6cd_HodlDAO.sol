pragma solidity ^0.4.10;
/**
* Hodld DAO and ERC20 token
* Author: CurrencyTycoon on GitHub
* License: MIT
* Date: 2017
*
* Deploy with the following args:
* 0, "Hodl DAO", 18, "HODL"
*
*/
contract HodlDAO {
    /* ERC20 Public variables of the token */
    string public version = 'HDAO 0.2';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* ERC20 This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    /* store the block number when a withdrawal has been requested*/
    mapping (address => withdrawalRequest) public withdrawalRequests;
    struct withdrawalRequest {
    uint sinceBlock;
    uint256 amount;
}

    /**
     * feePot collects fees from quick withdrawals. This gets re-distributed to slow-withdrawals
    */
    uint256 public feePot;

    uint32 public constant blockWait = 172800; // roughly 30 days,  (2592000 / 15) - assuming block time is ~15 sec.
    //uint public constant blockWait = 8; // roughly assuming block time is ~15 sec.


    /**
     * ERC20 events these generate a public event on the blockchain that will notify clients
    */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event WithdrawalQuick(address indexed by, uint256 amount, uint256 fee); // quick withdrawal done
    event InsufficientFee(address indexed by, uint256 feeRequired);  // not enough fee paid for quick withdrawal
    event WithdrawalStarted(address indexed by, uint256 amount);
    event WithdrawalDone(address indexed by, uint256 amount, uint256 reward); // amount is the amount that was used to calculate reward
    event WithdrawalPremature(address indexed by, uint blocksToWait); // Needs to wait blocksToWait before withdrawal unlocked
    event Deposited(address indexed by, uint256 amount);

    /**
     * Initializes contract with initial supply tokens to the creator of the contract
     * In our case, there's no initial supply. Tokens will be created as ether is sent
     * to the fall-back function. Then tokens are burned when ether is withdrawn.
     */
    function HodlDAO(
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol
    ) {

        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    /**
     * notPendingWithdrawal modifier guards the function from executing when a
     * withdrawal has been requested and is currently pending
     */
    modifier notPendingWithdrawal {
        if (withdrawalRequests[msg.sender].sinceBlock > 0) throw;
        _;
    }


    /** ERC20 - transfer sends tokens
     * @notice send `_value` token to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) notPendingWithdrawal {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /** ERC20 approve allows another contract to spend some tokens in your behalf
     * @notice `msg.sender` approves `_spender` to spend `_value` tokens
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) notPendingWithdrawal
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    /**
     * ERC-20 Approves and then calls the receiving contract
    */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) notPendingWithdrawal
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

    //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
    //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
    //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

    /**
     * ERC20 A contract attempts to get the coins
     * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value)  notPendingWithdrawal
    returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * withdrawalInitiate initiates the withdrawal by going into a waiting period
     * It remembers the block number & amount held at the time of request.
     * After the waiting period finishes, the call withdrawalComplete
     */
    function withdrawalInitiate() notPendingWithdrawal {
        WithdrawalStarted(msg.sender, balanceOf[msg.sender]);
        withdrawalRequests[msg.sender] = withdrawalRequest(block.number, balanceOf[msg.sender]);
    }

    /**
     * withdrawalComplete is called after the waiting period. The ether will be
     * returned to the caller and the tokens will be burned.
     * A reward will be issued based on the amount in the feePot relative to the
     * amount held when the withdrawal request was made.
     *
     * Gas: 17008
     */
    function withdrawalComplete() returns (bool) {
        withdrawalRequest r = withdrawalRequests[msg.sender];
        if (r.sinceBlock == 0) throw;
        if ((r.sinceBlock + blockWait) > block.number) {
            WithdrawalPremature(msg.sender, r.sinceBlock + blockWait - block.number);
            return false;
        }
        uint256 amount = withdrawalRequests[msg.sender].amount;
        uint256 reward = calculateReward(r.amount);
        withdrawalRequests[msg.sender].sinceBlock = 0;
        withdrawalRequests[msg.sender].amount = 0;

        if (reward > 0) {
            if (feePot - reward > feePot) {
                feePot = 0; // overflow
            } else {
                feePot -= reward;
            }
        }
        doWithdrawal(reward);
        WithdrawalDone(msg.sender, amount, reward);
        return true;

    }

    /**
     * Reward is based on the amount held, relative to total supply of tokens.
     */
    function calculateReward(uint256 v) constant returns (uint256) {
        uint256 reward = 0;
        if (feePot > 0) {
            reward = v / totalSupply * feePot;
        }
        return reward;
    }

    /** calculate the fee for quick withdrawal
     */
    function calculateFee(uint256 v) constant returns  (uint256) {
        uint256 feeRequired = v / (1 wei * 100);
        return feeRequired;
    }

    /**
     * Quick withdrawal, needs to send ether to this function for the fee.
     *
     * Gas use: 44129 (including call to processWithdrawal)
    */
    function quickWithdraw() payable notPendingWithdrawal returns (bool) {
        // calculate required fee
        uint256 amount = balanceOf[msg.sender];
        if (amount <= 0) throw;
        uint256 feeRequired = calculateFee(amount);
        if (msg.value < feeRequired) {
            // not enough fees sent
            InsufficientFee(msg.sender, feeRequired);
            return false;
        }
        uint256 overAmount = msg.value - feeRequired; // calculate any over-payment
        // add fee to the feePot, excluding any over-payment

        if (overAmount > 0) {
            feePot += msg.value - overAmount;
        } else {
            feePot += msg.value;
        }

        doWithdrawal(overAmount); // withdraw + return any over payment
        WithdrawalDone(msg.sender, amount, 0);
        return true;
    }

    /**
     * do withdrawal
     * Gas: 62483
     */
    function doWithdrawal(uint256 extra) internal {
        uint256 amount = balanceOf[msg.sender];

        if (amount <= 0) throw;                 // cannot withdraw
        balanceOf[msg.sender] = 0;
        if (totalSupply > totalSupply - amount) {
            totalSupply = 0; // don't let it overflow
        } else {
            totalSupply -= amount; // deflate the supply!
        }
        Transfer(msg.sender, 0, amount); // burn baby burn
        if (!msg.sender.send(amount + extra)) throw; // return back the ether or rollback if failed
    }


    /**
     * Fallback function when sending ether to the contract
     * Gas use: 65051
    */
    function () payable notPendingWithdrawal {
        uint256 amount = msg.value;  // amount that was sent
        if (amount <= 0) throw; // need to send some ETH
        balanceOf[msg.sender] += amount; // mint new tokens
        totalSupply += amount; // track the supply
        Transfer(0, msg.sender, amount); // notify of the event
        Deposited(msg.sender, amount);
    }
}