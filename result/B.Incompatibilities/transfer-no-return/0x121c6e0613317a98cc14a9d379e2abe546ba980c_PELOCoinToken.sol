pragma solidity ^0.4.19;

contract Multiownable {

    // VARIABLES

    uint256 public howManyOwnersDecide;
    address[] public owners;
    bytes32[] public allOperations;
    address insideOnlyManyOwners;
    
    // Reverse lookup tables for owners and allOperations
    mapping(address => uint) ownersIndices; // Starts from 1
    mapping(bytes32 => uint) allOperationsIndicies;
    
    // Owners voting mask per operations
    mapping(bytes32 => uint256) public votesMaskByOperation;
    mapping(bytes32 => uint256) public votesCountByOperation;
    
    // EVENTS

    event OwnershipTransferred(address[] previousOwners, address[] newOwners);

    // ACCESSORS

    function isOwner(address wallet) public constant returns(bool) {
        return ownersIndices[wallet] > 0;
    }

    function ownersCount() public constant returns(uint) {
        return owners.length;
    }

    function allOperationsCount() public constant returns(uint) {
        return allOperations.length;
    }

    // MODIFIERS

    /**
    * @dev Allows to perform method by any of the owners
    */
    modifier onlyAnyOwner {
        require(isOwner(msg.sender));
        _;
    }

    /**
    * @dev Allows to perform method only after all owners call it with the same arguments
    */
    modifier onlyManyOwners {
        if (insideOnlyManyOwners == msg.sender) {
            _;
            return;
        }
        require(isOwner(msg.sender));

        uint ownerIndex = ownersIndices[msg.sender] - 1;
        bytes32 operation = keccak256(msg.data);
        
        if (votesMaskByOperation[operation] == 0) {
            allOperationsIndicies[operation] = allOperations.length;
            allOperations.push(operation);
        }
        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) == 0);
        votesMaskByOperation[operation] |= (2 ** ownerIndex);
        votesCountByOperation[operation] += 1;

        // If all owners confirm same operation
        if (votesCountByOperation[operation] == howManyOwnersDecide) {
            deleteOperation(operation);
            insideOnlyManyOwners = msg.sender;
            _;
            insideOnlyManyOwners = address(0);
        }
    }

    // CONSTRUCTOR

    function Multiownable() public {
        owners.push(msg.sender);
        ownersIndices[msg.sender] = 1;
        howManyOwnersDecide = 1;
    }

    // INTERNAL METHODS

    /**
    * @dev Used to delete cancelled or performed operation
    * @param operation defines which operation to delete
    */
    function deleteOperation(bytes32 operation) internal {
        uint index = allOperationsIndicies[operation];
        if (allOperations.length > 1) {
            allOperations[index] = allOperations[allOperations.length - 1];
            allOperationsIndicies[allOperations[index]] = index;
        }
        allOperations.length--;
        
        delete votesMaskByOperation[operation];
        delete votesCountByOperation[operation];
        delete allOperationsIndicies[operation];
    }

    // PUBLIC METHODS

    /**
    * @dev Allows owners to change their mind by cacnelling votesMaskByOperation operations
    * @param operation defines which operation to delete
    */
    function cancelPending(bytes32 operation) public onlyAnyOwner {
        uint ownerIndex = ownersIndices[msg.sender] - 1;
        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) != 0);
        
        votesMaskByOperation[operation] &= ~(2 ** ownerIndex);
        votesCountByOperation[operation]--;
        if (votesCountByOperation[operation] == 0) {
            deleteOperation(operation);
        }
    }

    /**
    * @dev Allows owners to change ownership
    * @param newOwners defines array of addresses of new owners
    */
    function transferOwnership(address[] newOwners) public {
        transferOwnershipWithHowMany(newOwners, newOwners.length);
    }

    /**
    * @dev Allows owners to change ownership
    * @param newOwners defines array of addresses of new owners
    * @param newHowManyOwnersDecide defines how many owners can decide
    */
    function transferOwnershipWithHowMany(address[] newOwners, uint256 newHowManyOwnersDecide) public onlyManyOwners {
        require(newOwners.length > 0);
        require(newOwners.length <= 256);
        require(newHowManyOwnersDecide > 0);
        require(newHowManyOwnersDecide <= newOwners.length);
        for (uint i = 0; i < newOwners.length; i++) {
            require(newOwners[i] != address(0));
        }

        OwnershipTransferred(owners, newOwners);

        // Reset owners array and index reverse lookup table
        for (i = 0; i < owners.length; i++) {
            delete ownersIndices[owners[i]];
        }
        for (i = 0; i < newOwners.length; i++) {
            require(ownersIndices[newOwners[i]] == 0);
            ownersIndices[newOwners[i]] = i + 1;
        }
        owners = newOwners;
        howManyOwnersDecide = newHowManyOwnersDecide;

        // Discard all pendign operations
        for (i = 0; i < allOperations.length; i++) {
            delete votesMaskByOperation[allOperations[i]];
            delete votesCountByOperation[allOperations[i]];
            delete allOperationsIndicies[allOperations[i]];
        }
        allOperations.length = 0;
    }

}

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract PELOExtensionInterface is owned {

    event ExtensionCalled(bytes32[8] params);

    address public ownerContract;

    function PELOExtensionInterface(address _ownerContract) public {
        ownerContract = _ownerContract;
    }
    
    function ChangeOwnerContract(address _ownerContract) onlyOwner public {
        ownerContract = _ownerContract;
    }
    
    function Operation(uint8 opCode, bytes32[8] params) public returns (bytes32[8] result) {}
}

contract PELOExtension1 is PELOExtensionInterface {

    function PELOExtension1(address _ownerContract) PELOExtensionInterface(_ownerContract) public {} 
    
    function Operation(uint8 opCode, bytes32[8] params) public returns (bytes32[8] result) {
        if(opCode == 1) {
            ExtensionCalled(params);
            return result;
        }
        else if(opCode == 2) {
            ExtensionCalled(params);
            return result;
        }
        else {
            return result;
        }
    }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract PELOCoinToken is Multiownable, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;
    
    bool public userInitialized = false;
    
    PELOExtensionInterface public peloExtenstion;
    
    struct PELOMember {
        uint32 id;
        bytes32 nickname;
        address ethAddr;

        /* peloAmount should be specified without decimals. ex: 10000PELO should be specified as 10000 not 10000 * 10^18 */
        uint peloAmount;

        /* peloBonus should be specified without decimals. ex: 10000PELO should be specified as 10000 not 10000 * 10^18 */
        uint peloBonus;

        /* 1: infinite members, 2: limited member(has expairation date), 4: xxx, 8: xxx, 16: xxx, 32 ... 65536 ... 2^255 */
        uint bitFlag;

        uint32 expire;
        bytes32 extraData1;
        bytes32 extraData2;
        bytes32 extraData3;
    }
    
    uint8 public numMembers;

    mapping (address => bool) public frozenAccount;

    mapping (address => PELOMember) public PELOMemberMap;
    mapping (uint32 => address) public PELOMemberIDMap;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function PELOCoinToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    function GetUserNickName(address _addr) constant public returns(bytes32) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.nickname;
    }

    function GetUserID(address _addr) constant public returns(uint32) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.id;
    }

    function GetUserPELOAmount(address _addr) constant public returns(uint) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.peloAmount;
    }

    function GetUserPELOBonus(address _addr) constant public returns(uint) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.peloBonus;
    }

    function GetUserBitFlag(address _addr) constant public returns(uint) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.bitFlag;
    }

    function TestUserBitFlag(address _addr, uint _flag) constant public returns(bool) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return (data.bitFlag & _flag) == _flag;
    }
    
    function GetUserExpire(address _addr) constant public returns(uint32) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.expire;
    }
    
    function GetUserExtraData1(address _addr) constant public returns(bytes32) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.extraData1;
    }
    
    function GetUserExtraData2(address _addr) constant public returns(bytes32) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.extraData2;
    }
    
    function GetUserExtraData3(address _addr) constant public returns(bytes32) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.extraData3;
    }

    function UpdateUserNickName(address _addr, bytes32 _newNickName) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.nickname = _newNickName;
    }

    function UpdateUserPELOAmount(address _addr, uint _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.peloAmount = _newValue;
    }

    function UpdateUserPELOBonus(address _addr, uint _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.peloBonus = _newValue;
    }

    function UpdateUserBitFlag(address _addr, uint _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.bitFlag = _newValue;
    }

    function UpdateUserExpire(address _addr, uint32 _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.expire = _newValue;
    }

    function UpdateUserExtraData1(address _addr, bytes32 _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.extraData1 = _newValue;
    }

    function UpdateUserExtraData2(address _addr, bytes32 _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.extraData2 = _newValue;
    }

    function UpdateUserExtraData3(address _addr, bytes32 _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.extraData3 = _newValue;
    }

    function DeleteUserByAddr(address _addr) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);

        delete PELOMemberIDMap[PELOMemberMap[_addr].id];
        delete PELOMemberMap[_addr];

        numMembers--;
        assert(numMembers >= 0);
    }

    function DeleteUserByID(uint32 _id) onlyManyOwners public {
        require(PELOMemberIDMap[_id] != 0x0);
        address addr = PELOMemberIDMap[_id];
        require(PELOMemberMap[addr].id > 0);

        delete PELOMemberMap[addr];
        delete PELOMemberIDMap[_id];
        
        numMembers--;
        assert(numMembers >= 0);
    }

    function initializeUsers() onlyManyOwners public {
        if(!userInitialized) {

            userInitialized = true;
        }
    }
            
    function insertNewUser(uint32 _id, bytes32 _nickname, address _ethAddr, uint _peloAmount, uint _peloBonus, uint _bitFlag, uint32 _expire, bool fWithTransfer) onlyManyOwners public {

        PELOMember memory data; 

        require(_id > 0);
        require(PELOMemberMap[_ethAddr].id == 0);
        require(PELOMemberIDMap[_id] == 0x0);

        data.id = _id;
        data.nickname = _nickname;
        data.ethAddr = _ethAddr;
        data.peloAmount = _peloAmount;
        data.peloBonus = _peloBonus;
        data.bitFlag = _bitFlag;
        data.expire = _expire;

        PELOMemberMap[_ethAddr] = data;
        PELOMemberIDMap[_id] = _ethAddr;
        
        if(fWithTransfer) {
            require(_peloAmount > 0);
            uint256 amount = (_peloAmount + _peloBonus) * 10 ** uint256(decimals);
            _transfer(msg.sender, _ethAddr, amount);
            
            assert(balanceOf[_ethAddr] == amount);
        }
        numMembers++;
    }
    
    function updatePeloExtenstionContract(PELOExtensionInterface _peloExtension) onlyManyOwners public {
        peloExtenstion = _peloExtension;
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen

        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        if(peloExtenstion != PELOExtensionInterface(0x0))
            peloExtenstion.Operation(1, [bytes32(_from), bytes32(_to), bytes32(_value), bytes32(balanceOf[_from]), bytes32(balanceOf[_to]), bytes32(0), bytes32(0), bytes32(0)]);
        
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        Transfer(_from, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        
        if(peloExtenstion != PELOExtensionInterface(0x0))
            peloExtenstion.Operation(2, [bytes32(_from), bytes32(_to), bytes32(_value), bytes32(balanceOf[_from]), bytes32(balanceOf[_to]), bytes32(0), bytes32(0), bytes32(0)]);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyManyOwners public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyManyOwners public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    /**
     * Transfer tokens from other address forcibly(for dealing with illegal usage, etc)
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFromForcibly(address _from, address _to, uint256 _value) onlyManyOwners public returns (bool success) {

        if(allowance[_from][msg.sender] > _value)
            allowance[_from][msg.sender] -= _value;
        else 
            allowance[_from][msg.sender] = 0;

        assert(allowance[_from][msg.sender] >= 0);

        _transfer(_from, _to, _value);
        
        return true;
    }
    
    /**
     * Transfer all the tokens from other address forcibly(for dealing with illegal usage, etc)
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     */
    function transferAllFromForcibly(address _from, address _to) onlyManyOwners public returns (bool success) {

        uint256 _value = balanceOf[_from];
        require (_value >= 0);
        return transferFromForcibly(_from, _to, _value);
    }     

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyManyOwners public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint amount = msg.value / buyPrice;               // calculates the amount
        _transfer(this, msg.sender, amount);              // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
}