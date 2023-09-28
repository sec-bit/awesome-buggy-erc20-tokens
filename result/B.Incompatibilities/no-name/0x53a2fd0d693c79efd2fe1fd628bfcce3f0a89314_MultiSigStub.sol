pragma solidity ^0.4.15;

/**
 * @title MultiSigStub  
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @dev Contract that delegates calls to a library to build a full MultiSigWallet that is cheap to create. 
 */
contract MultiSigStub {

    address[] public owners;
    address[] public tokens;
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }
    
    function MultiSigStub(address[] _owners, uint256 _required) {
        //bytes4 sig = bytes4(sha3("constructor(address[],uint256)"));
        bytes4 sig = 0x36756a23;
        uint argarraysize = (2 + _owners.length);
        uint argsize = (1 + argarraysize) * 32;
        uint size = 4 + argsize;
        bytes32 mData = _malloc(size);

        assembly {
            mstore(mData, sig)
            codecopy(add(mData, 0x4), sub(codesize, argsize), argsize)
        }
        _delegatecall(mData, size);
    }
    
    modifier delegated {
        uint size = msg.data.length;
        bytes32 mData = _malloc(size);

        assembly {
            calldatacopy(mData, 0x0, size)
        }

        bytes32 mResult = _delegatecall(mData, size);
        _;
        assembly {
            return(mResult, 0x20)
        }
    }
    
    function()
        payable
        delegated
    {

    }

    function submitTransaction(address destination, uint value, bytes data)
        public
        delegated
        returns (uint)
    {
        
    }
    
    function confirmTransaction(uint transactionId)
        public
        delegated
    {
        
    }
    
    function watch(address _tokenAddr)
        public
        delegated
    {
        
    }
    
    function setMyTokenList(address[] _tokenList)  
        public
        delegated
    {

    }
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        delegated
        returns (bool)
    {

    }
    
    /*
    * Web3 call functions
    */
    function tokenBalances(address tokenAddress) 
        public
        constant 
        delegated 
        returns (uint)
    {

    }


    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        delegated
        returns (uint)
    {

    }

    /// @dev Returns total number of transactions after filters are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        delegated
        returns (uint)
    {

    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    /// @dev Returns list of tokens.
    /// @return List of token addresses.
    function getTokenList()
        public
        constant
        returns (address[])
    {
        return tokens;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
    }


    function _malloc(uint size) 
        private 
        returns(bytes32 mData) 
    {
        assembly {
            mData := mload(0x40)
            mstore(0x40, add(mData, size))
        }
    }

    function _delegatecall(bytes32 mData, uint size) 
        private 
        returns(bytes32 mResult) 
    {
        address target = 0xc0FFeEE61948d8993864a73a099c0E38D887d3F4; //Multinetwork
        mResult = _malloc(32);
        bool failed;

        assembly {
            failed := iszero(delegatecall(sub(gas, 10000), target, mData, size, mResult, 0x20))
        }

        assert(!failed);
    }
    
}

contract MultiSigFactory {
    
    event Create(address indexed caller, address createdContract);

    function create(address[] owners, uint256 required) returns (address wallet){
        wallet = new MultiSigStub(owners, required); 
        Create(msg.sender, wallet);
    }
    
}

///////////////////////////////////////////////////////////////////
// MultiSigTokenWallet as in 0xc0FFeEE61948d8993864a73a099c0E38D887d3F4
///////////////////////////////////////////////////////////////////

pragma solidity ^0.4.15;

contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256 balance);
    function allowance(address owner, address spender) constant returns (uint256 remaining);
    function transfer(address to, uint256 value) returns (bool ok); 
    function transferFrom(address from, address to, uint256 value) returns (bool ok);
    function approve(address spender, uint256 value) returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MultiSigTokenWallet {

    address[] public owners;
    address[] public tokens;
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    uint public transactionCount;
    
    mapping (address => uint) public tokenBalances;
    mapping (address => bool) public isOwner;
    mapping (address => address[]) public userList;
    uint public required;
    uint public nonce;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed _sender, uint indexed _transactionId);
    event Revocation(address indexed _sender, uint indexed _transactionId);
    event Submission(uint indexed _transactionId);
    event Execution(uint indexed _transactionId);
    event ExecutionFailure(uint indexed _transactionId);
    event Deposit(address indexed _sender, uint _value);
    event TokenDeposit(address _token, address indexed _sender, uint _value);
    event OwnerAddition(address indexed _owner);
    event OwnerRemoval(address indexed _owner);
    event RequirementChange(uint _required);
    
    modifier onlyWallet() {
        require (msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require (!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require (isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require (transactions[transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require (confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require (!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require (_address != 0);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require (ownerCount <= MAX_OWNER_COUNT && _required <= ownerCount && _required != 0 && ownerCount != 0);
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

    /**
    * Public functions
    * 
    **/
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function constructor(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        require(owners.length == 0 && required == 0);
        for (uint i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /**
    * @notice deposit a ERC20 token. The amount of deposit is the allowance set to this contract.
    * @param _token the token contract address
    * @param _data might be used by child implementations
    **/ 
    function depositToken(address _token, bytes _data) 
        public 
    {
        address sender = msg.sender;
        uint amount = ERC20(_token).allowance(sender, this);
        deposit(sender, amount, _token, _data);
    }
        
    /**
    * @notice deposit a ERC20 token. The amount of deposit is the allowance set to this contract.
    * @param _token the token contract address
    * @param _data might be used by child implementations
    **/ 
    function deposit(address _from, uint256 _amount, address _token, bytes _data) 
        public 
    {
        if (_from == address(this))
            return;
        uint _nonce = nonce;
        bool result = ERC20(_token).transferFrom(_from, this, _amount);
        assert(result);
        //ERC23 not executed _deposited tokenFallback by
        if (nonce == _nonce) {
            _deposited(_from, _amount, _token, _data);
        }
    }
    /**
    * @notice watches for balance in a token contract
    * @param _tokenAddr the token contract address
    **/   
    function watch(address _tokenAddr) 
        ownerExists(msg.sender) 
    {
        uint oldBal = tokenBalances[_tokenAddr];
        uint newBal = ERC20(_tokenAddr).balanceOf(this);
        if (newBal > oldBal) {
            _deposited(0x0, newBal-oldBal, _tokenAddr, new bytes(0));
        }
    }

    function setMyTokenList(address[] _tokenList) 
        public
    {
        userList[msg.sender] = _tokenList;
    }

    function setTokenList(address[] _tokenList) 
        onlyWallet
    {
        tokens = _tokenList;
    }
    
    /**
    * @notice ERC23 Token fallback
    * @param _from address incoming token
    * @param _amount incoming amount
    **/    
    function tokenFallback(address _from, uint _amount, bytes _data) 
        public 
    {
        _deposited(_from, _amount, msg.sender, _data);
    }
        
    /** 
    * @notice Called MiniMeToken approvesAndCall to this contract, calls deposit.
    * @param _from address incoming token
    * @param _amount incoming amount
    * @param _token the token contract address
    * @param _data (might be used by child classes)
    */ 
    function receiveApproval(address _from, uint256 _amount, address _token, bytes _data) {
        deposit(_from, _amount, _token, _data);
    }
    

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        uint _len = owners.length - 1;
        for (uint i = 0; i < _len; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param owner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

    /**
    * @dev gives full ownership of this wallet to `_dest` removing older owners from wallet
    * @param _dest the address of new controller
    **/    
    function releaseWallet(address _dest)
        public
        notNull(_dest)
        ownerDoesNotExist(_dest)
        onlyWallet
    {
        address[] memory _owners = owners;
        uint numOwners = _owners.length;
        addOwner(_dest);
        for (uint i = 0; i < numOwners; i++) {
            removeOwner(_owners[i]);
        }
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txx = transactions[transactionId];
            txx.executed = true;
            if (txx.destination.call.value(txx.value)(txx.data)) {
                Execution(transactionId);
            } else {
                ExecutionFailure(transactionId);
                txx.executed = false;
            }
        }
    }

    /**
    * @dev withdraw all recognized tokens balances and ether to `_dest`
    * @param _dest the address of receiver
    **/    
    function withdrawEverything(address _dest) 
        public
        notNull(_dest)
        onlyWallet
    {
        withdrawAllTokens(_dest);
        _dest.transfer(this.balance);
    }

    /**
    * @dev withdraw all recognized tokens balances to `_dest`
    * @param _dest the address of receiver
    **/    
    function withdrawAllTokens(address _dest) 
        public 
        notNull(_dest)
        onlyWallet
    {
        address[] memory _tokenList;
        if (userList[_dest].length > 0) {
            _tokenList = userList[_dest];
        } else {
            _tokenList = tokens;
        }
        uint len = _tokenList.length;
        for (uint i = 0;i < len; i++) {
            address _tokenAddr = _tokenList[i];
            uint _amount = tokenBalances[_tokenAddr];
            if (_amount > 0) {
                delete tokenBalances[_tokenAddr];
                ERC20(_tokenAddr).transfer(_dest, _amount);
            }
        }
    }

    /**
    * @dev withdraw `_tokenAddr` `_amount` to `_dest`
    * @param _tokenAddr the address of the token
    * @param _dest the address of receiver
    * @param _amount the number of tokens to send
    **/
    function withdrawToken(address _tokenAddr, address _dest, uint _amount)
        public
        notNull(_dest)
        onlyWallet 
    {
        require(_amount > 0);
        uint _balance = tokenBalances[_tokenAddr];
        require(_amount <= _balance);
        tokenBalances[_tokenAddr] = _balance - _amount;
        bool result = ERC20(_tokenAddr).transfer(_dest, _amount);
        assert(result);
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*
    * Internal functions
    */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        Submission(transactionId);
    }
    
    /**
    * @dev register the deposit
    **/
    function _deposited(address _from,  uint _amount, address _tokenAddr, bytes) 
        internal 
    {
        TokenDeposit(_tokenAddr,_from,_amount);
        nonce++;
        if (tokenBalances[_tokenAddr] == 0) {
            tokens.push(_tokenAddr);  
            tokenBalances[_tokenAddr] = ERC20(_tokenAddr).balanceOf(this);
        } else {
            tokenBalances[_tokenAddr] += _amount;
        }
    }
    
    /*
    * Web3 call functions
    */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
        }
    }

    /// @dev Returns total number of transactions after filters are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed)
                count += 1;
        }
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    /// @dev Returns list of tokens.
    /// @return List of token addresses.
    function getTokenList()
        public
        constant
        returns (address[])
    {
        return tokens;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
    }

}