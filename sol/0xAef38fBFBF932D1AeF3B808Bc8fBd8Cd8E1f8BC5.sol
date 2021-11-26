pragma solidity ^0.4.8;

contract ICreditBOND{
    function getBondMultiplier(uint _creditAmount, uint _locktime) constant returns (uint bondMultiplier) {}
    function getNewCoinsIssued(uint _lockedBalance, uint _blockDifference, uint _percentReward) constant returns(uint newCoinsIssued){}
}

contract ITokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); 
}

contract IERC20Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}   

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract CreditBIT is IERC20Token {

    struct CreditBalance{
        uint avaliableBalance;
        uint lockedBalance;

        uint bondMultiplier;
        uint lockedUntilBlock;
        uint lastBlockClaimed;
    }

	address public dev;
	address public creditDaoAddress;
    ICreditBOND creditBond;
    address public creditGameAddress;
    address public creditMcAddress;
    bool public lockdown;

    string public standard = 'Creditbit 1.0';
    string public name = 'CreditBIT';
    string public symbol = 'CRB';
    uint8 public decimals = 8;

    uint256 public totalSupply = 0;
    uint public totalAvaliableSupply = 0;
    uint public totalLockedSupply = 0; 

    mapping (address => CreditBalance) balances;
    mapping (address => mapping (address => uint256)) public allowance;

    //event Transfer(address indexed from, address indexed to, uint256 value);
    //event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event LockCredits(address _owner, uint _amount, uint _numberOfBlocks);
    event UnlockCredits(address _owner, uint _amount);
    event Mint(address _owner, uint _amount);

    function CreditBIT() {
        dev = msg.sender;
        lockdown = false;
    }

    function balanceOf(address _owner) constant returns (uint avaliableBalance){
        return balances[_owner].avaliableBalance;
    }

    function lockedBalanceOf(address _owner) constant returns (uint avaliableBalance){
        return balances[_owner].lockedBalance;
    }

    function getAccountData(address _owner) constant returns (uint avaliableBalance, uint lockedBalance, uint bondMultiplier, uint lockedUntilBlock, uint lastBlockClaimed){
        CreditBalance memory tempAccountData = balances[_owner];
        return (
            tempAccountData.avaliableBalance,
            tempAccountData.lockedBalance,
            tempAccountData.bondMultiplier,
            tempAccountData.lockedUntilBlock,
            tempAccountData.lastBlockClaimed
        );
    }

    function lockBalance(uint _amount, uint _lockForBlocks) returns (uint error){
        if (lockdown) throw;
        uint realBlocksLocked;
        if (block.number + _lockForBlocks < balances[msg.sender].lockedUntilBlock){
            realBlocksLocked = balances[msg.sender].lockedUntilBlock;
        }else{
            realBlocksLocked = block.number + _lockForBlocks;
        }
        
        uint realAmount;
        if (balances[msg.sender].avaliableBalance < (_amount * 10**8)) {
            realAmount = (balances[msg.sender].avaliableBalance / 10**8) * 10**8;
        }else{
            realAmount = (_amount * 10**8);
        }

        uint newBondMultiplier = creditBond.getBondMultiplier(realAmount, realBlocksLocked);
        if (newBondMultiplier == 0) throw;

        uint claimError = claimBondReward();

        balances[msg.sender].avaliableBalance -= realAmount;
        balances[msg.sender].lockedBalance += realAmount;
        totalAvaliableSupply -= realAmount;
        totalLockedSupply += realAmount;
        balances[msg.sender].bondMultiplier = newBondMultiplier;
        balances[msg.sender].lockedUntilBlock = realBlocksLocked;
        balances[msg.sender].lastBlockClaimed = block.number;

        return 0;
    }

    function mintMigrationTokens(address _reciever, uint _amount) returns (uint error){
      
        if (msg.sender != creditMcAddress) { return 1; }
        
        mint(_amount, _reciever);
        return 0;
    }

    function claimBondReward() returns (uint error){
        if (lockdown) throw;
        if (balances[msg.sender].lockedBalance == 0) { return 1;}
        
        uint blockDifference = block.number - balances[msg.sender].lastBlockClaimed;
        if (blockDifference < 10){ return 1;}
        
        uint newCreditsIssued = creditBond.getNewCoinsIssued(
            balances[msg.sender].lockedBalance, 
            blockDifference, 
            balances[msg.sender].bondMultiplier);
        if (newCreditsIssued == 0) { return 1; }
        
        if (balances[msg.sender].lockedUntilBlock < block.number ) {
            balances[msg.sender].avaliableBalance += balances[msg.sender].lockedBalance;
            totalAvaliableSupply += balances[msg.sender].lockedBalance;
            totalLockedSupply -= balances[msg.sender].lockedBalance;
            balances[msg.sender].bondMultiplier = 0;
            balances[msg.sender].lockedUntilBlock = 0;
            UnlockCredits(msg.sender, balances[msg.sender].lockedBalance);
            balances[msg.sender].lockedBalance = 0;
        }else{
            balances[msg.sender].lastBlockClaimed = block.number;
        }
        
        mint(newCreditsIssued, msg.sender);
    }
    
    function claimGameReward(address _champion, uint _lockedTokenAmount, uint _lockTime) returns (uint error){
        if (lockdown) throw;
        if (msg.sender != creditGameAddress) { return 1; }
        
        uint newCreditsIssued = creditBond.getNewCoinsIssued(
            _lockedTokenAmount, 
            _lockTime, 
            creditBond.getBondMultiplier(_lockedTokenAmount, _lockTime + block.number));
        if (newCreditsIssued == 0) { return 1; }
        mint(newCreditsIssued, _champion);
        return 0;
    }

    function mintBonusTokensForGames(uint _amount) returns (uint error){
        if (lockdown) throw;
        if (msg.sender != creditDaoAddress) { return 1; }

        mint(_amount, creditGameAddress);
        return 0;
    }

    function mint(uint _newCreditsIssued, address _sender) internal {
       
        totalSupply += _newCreditsIssued;
        totalAvaliableSupply += _newCreditsIssued;
        balances[_sender].avaliableBalance += _newCreditsIssued;
        Transfer(0x0, _sender, _newCreditsIssued);
        Mint(_sender, _newCreditsIssued);
    }

    function transfer(address _to, uint256 _value) returns (bool success){
        if (lockdown) throw;
        if (balances[msg.sender].avaliableBalance < _value) throw;
        if (balances[_to].avaliableBalance + _value < balances[_to].avaliableBalance) throw;
        balances[msg.sender].avaliableBalance -= _value;
        balances[_to].avaliableBalance += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if (lockdown) throw;
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        if (lockdown) throw;
        ITokenRecipient spender = ITokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (lockdown) throw;
        if (balances[_from].avaliableBalance < _value) throw;
        if (balances[_to].avaliableBalance + _value < balances[_to].avaliableBalance) throw;
        if (_value > allowance[_from][msg.sender]) throw;
        balances[_from].avaliableBalance -= _value;
        balances[_to].avaliableBalance += _value;
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    function setCreditBond(address _bondAddress) returns (uint error){
        if (msg.sender != creditDaoAddress) {return 1;}
        
        creditBond = ICreditBOND(_bondAddress);
        return 0;
    }

    function getCreditBondAddress() constant returns (address bondAddress){
        return address(creditBond);
    }
    
    function setCreditDaoAddress(address _daoAddress) returns (uint error){
        if (msg.sender != dev) {return 1;}
        
        creditDaoAddress = _daoAddress;
        return 0;
    }
    
    function setCreditGameAddress(address _gameAddress) returns (uint error){
        if (msg.sender != creditDaoAddress) {return 1;}
        
        creditGameAddress = _gameAddress;
        return 0;
    }
    
    function setCreditMcAddress(address _mcAddress) returns (uint error){
        if (msg.sender != creditDaoAddress) {return 1;}
        
        creditMcAddress = _mcAddress;
        return 0;
    }

    function lockToken() returns (uint error){
        if (msg.sender != creditDaoAddress) {return 1;}

        lockdown = !lockdown;
        return 0;
    }

    function () {
        throw;
    }
}