pragma solidity ^0.4.18;


/*============================================================================= */
/*=============================ERC721 interface==================================== */
/*============================================================================= */

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Yumin.yang
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    //function ownerOf(uint256 _tokenId) external view returns (address owner);
    //function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    //function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    //event Approval(address owner, address approved, uint256 tokenId);

}


/*============================================================================= */
/*=============================Forever Rose==================================== */
/*============================================================================= */

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Yumin.yang
contract DivisibleForeverRose is ERC721 {
  
    //This contract's owner
    address private contractOwner;

    
    //Gift token storage.
    mapping(uint => GiftToken) giftStorage;

    // Total supply of this token. 
	uint public totalSupply = 10; 

    bool public tradable = false;

    uint foreverRoseId = 1;

    // Divisibility of ownership over a token  
	mapping(address => mapping(uint => uint)) ownerToTokenShare;

	// How much owners have of a token
	mapping(uint => mapping(address => uint)) tokenToOwnersHoldings;

    // If Forever Rose has been created
	mapping(uint => bool) foreverRoseCreated;

    string public name;  
    string public symbol;           
    uint8 public decimals = 1;                                 
    string public version = "1.0";    

    //Special gift token
    struct GiftToken {
        uint256 giftId;
    } 

    //@dev Constructor 
    function DivisibleForeverRose() public {
        contractOwner = msg.sender;
        name = "ForeverRose";
        symbol = "ROSE";  

        // Create Forever rose
        GiftToken memory newGift = GiftToken({
            giftId: foreverRoseId
        });
        giftStorage[foreverRoseId] = newGift;

        
        foreverRoseCreated[foreverRoseId] = true;
        _addNewOwnerHoldingsToToken(contractOwner, foreverRoseId, totalSupply);
        _addShareToNewOwner(contractOwner, foreverRoseId, totalSupply);

    }
    
    // Fallback funciton
    function() public {
        revert();
    }

    function totalSupply() public view returns (uint256 total) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerToTokenShare[_owner][foreverRoseId];
    }

    // We use parameter '_tokenId' as the divisibility
    function transfer(address _to, uint256 _tokenId) external {

        // Requiring this contract be tradable
        require(tradable == true);

        require(_to != address(0));
        require(msg.sender != _to);

        // Take _tokenId as divisibility
        uint256 _divisibility = _tokenId;

        // Requiring msg.sender has Holdings of Forever rose
        require(tokenToOwnersHoldings[foreverRoseId][msg.sender] >= _divisibility);

    
        // Remove divisibilitys from old owner
        _removeShareFromLastOwner(msg.sender, foreverRoseId, _divisibility);
        _removeLastOwnerHoldingsFromToken(msg.sender, foreverRoseId, _divisibility);

        // Add divisibilitys to new owner
        _addNewOwnerHoldingsToToken(_to, foreverRoseId, _divisibility);
        _addShareToNewOwner(_to, foreverRoseId, _divisibility);

        // Trigger Ethereum Event
        Transfer(msg.sender, _to, foreverRoseId);

    }

    // Transfer gift to a new owner.
    function assignSharedOwnership(address _to, uint256 _divisibility)
                               onlyOwner external returns (bool success) 
                               {

        require(_to != address(0));
        require(msg.sender != _to);
        require(_to != address(this));
        
        // Requiring msg.sender has Holdings of Forever rose
        require(tokenToOwnersHoldings[foreverRoseId][msg.sender] >= _divisibility);

        //Remove ownership from oldOwner(msg.sender)
        _removeLastOwnerHoldingsFromToken(msg.sender, foreverRoseId, _divisibility);
        _removeShareFromLastOwner(msg.sender, foreverRoseId, _divisibility);

         //Add ownership to NewOwner(address _to)
        _addShareToNewOwner(_to, foreverRoseId, _divisibility); 
        _addNewOwnerHoldingsToToken(_to, foreverRoseId, _divisibility);

        // Trigger Ethereum Event
        Transfer(msg.sender, _to, foreverRoseId);

        return true;
    }

    function getForeverRose() public view returns(uint256 _foreverRoseId) {
        return giftStorage[foreverRoseId].giftId;
    }

    // Turn on this contract to be tradable, so owners can transfer their token
    function turnOnTradable() public onlyOwner {
        tradable = true;
    }
    
    // ------------------------------ Helper functions (internal functions) ------------------------------

	// Add divisibility to new owner
	function _addShareToNewOwner(address _owner, uint _tokenId, uint _units) internal {
		ownerToTokenShare[_owner][_tokenId] += _units;
	}

	
	// Add the divisibility to new owner
	function _addNewOwnerHoldingsToToken(address _owner, uint _tokenId, uint _units) internal {
		tokenToOwnersHoldings[_tokenId][_owner] += _units;
	}
    
    // Remove divisibility from last owner
	function _removeShareFromLastOwner(address _owner, uint _tokenId, uint _units) internal {
		ownerToTokenShare[_owner][_tokenId] -= _units;
	}
    
    // Remove divisibility from last owner 
	function _removeLastOwnerHoldingsFromToken(address _owner, uint _tokenId, uint _units) internal {
		tokenToOwnersHoldings[_tokenId][_owner] -= _units;
	}

    // Withdraw Ether from this contract to Multi sigin wallet
    function withdrawEther() onlyOwner public returns(bool) {
        return contractOwner.send(this.balance);
    }

    // ------------------------------ Modifier -----------------------------------


     modifier onlyExistentToken(uint _tokenId) {
	    require(foreverRoseCreated[_tokenId] == true);
	    _;
	}

    modifier onlyOwner(){
         require(msg.sender == contractOwner);
         _;
     }

}


/*============================================================================= */
/*=============================MultiSig Wallet================================= */
/*============================================================================= */

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="8bf8ffeeedeae5a5eceee4f9eceecbe8e4e5f8eee5f8f2f8a5e5eeff">[email protected]</a>>
contract MultiSigWallet {

   //Load Gifto and IAMICOIN Contracts to this contract.
    //ERC20 private Gifto = ERC20(0x92e87a5622cf9955d1062822454701198a028a72);
    //ERC20 private IAMIToken = ERC20(0xee10a06b2a0cf7e04115edfbee46242136eb6ae1);

    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
    event CoinCreation(address coin);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;
    bool flag = true;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this))
            revert();
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            revert();
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            revert();
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0)
            revert();
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            revert();
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0)
            revert();
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (   ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0)
            revert();
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function MultiSigWallet(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0)
                revert();
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
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
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
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
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
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
            Transaction tx = transactions[transactionId];
            tx.executed = true;
            if (tx.destination.call.value(tx.value)(tx.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                tx.executed = false;
            }
        }
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
        for (uint i=0; i<owners.length; i++) {
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
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
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
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
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
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }

    // Transfer GTO to an outside account
    /*function _withdrawGTO(address _to, uint256 _balance) onlyOwner internal { 
        require(Gifto.balanceOf(address(this)) >= _balance);
        Gifto.transfer(_to, _balance); 
    }

    // Transfer IAMI to an outside account
    function _withdrawIAMI(address _to, uint256 _balance) onlyOwner internal { 
        require(IAMIToken.balanceOf(address(this)) >= _balance);
        IAMIToken.transfer(_to, _balance); 
    }

    // Change Gifto contract's address or another type of token, like Ether.
    function setIAMITokenAddress(address newAddress) public onlyOwner {
        IAMIToken = ERC20(newAddress);
    }

    function setGiftoAddress(address newAddress) public onlyOwner {
        Gifto = ERC20(newAddress);
    }*/

    modifier onlyOwner() {
        require(isOwner[msg.sender] == true);
        _;
    }

    /// @dev Create new forever rose.
    function createForeverRose()
        external
        onlyWallet
    {
        require(flag == true);
        CoinCreation(new DivisibleForeverRose());
        flag = false;
    }
    

}