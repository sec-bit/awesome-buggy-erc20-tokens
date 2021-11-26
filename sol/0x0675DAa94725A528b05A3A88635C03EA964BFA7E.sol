pragma solidity 0.4.18;


contract CrowdsaleParameters {
    // Vesting time stamps:
    // 1534672800 = August 19, 2018. 180 days from February 20, 2018. 10:00:00 GMT
    // 1526896800 = May 21, 2018. 90 days from February 20, 2018. 10:00:00 GMT
    uint32 internal vestingTime90Days = 1526896800;
    uint32 internal vestingTime180Days = 1534672800;

    uint256 internal constant presaleStartDate = 1513072800; // Dec-12-2017 10:00:00 GMT
    uint256 internal constant presaleEndDate = 1515751200; // Jan-12-2018 10:00:00 GMT
    uint256 internal constant generalSaleStartDate = 1516442400; // Jan-20-2018 00:00:00 GMT
    uint256 internal constant generalSaleEndDate = 1519120800; // Feb-20-2018 00:00:00 GMT

    struct AddressTokenAllocation {
        address addr;
        uint256 amount;
        uint256 vestingTS;
    }

    AddressTokenAllocation internal presaleWallet       = AddressTokenAllocation(0x43C5FB6b419E6dF1a021B9Ad205A18369c19F57F, 100e6, 0);
    AddressTokenAllocation internal generalSaleWallet   = AddressTokenAllocation(0x0635c57CD62dA489f05c3dC755bAF1B148FeEdb0, 550e6, 0);
    AddressTokenAllocation internal wallet1             = AddressTokenAllocation(0xae46bae68D0a884812bD20A241b6707F313Cb03a,  20e6, vestingTime180Days);
    AddressTokenAllocation internal wallet2             = AddressTokenAllocation(0xfe472389F3311e5ea19B4Cd2c9945b6D64732F13,  20e6, vestingTime180Days);
    AddressTokenAllocation internal wallet3             = AddressTokenAllocation(0xE37dfF409AF16B7358Fae98D2223459b17be0B0B,  20e6, vestingTime180Days);
    AddressTokenAllocation internal wallet4             = AddressTokenAllocation(0x39482f4cd374D0deDD68b93eB7F3fc29ae7105db,  10e6, vestingTime180Days);
    AddressTokenAllocation internal wallet5             = AddressTokenAllocation(0x03736d5B560fE0784b0F5c2D0eA76A7F15E5b99e,   5e6, vestingTime180Days);
    AddressTokenAllocation internal wallet6             = AddressTokenAllocation(0xD21726226c32570Ab88E12A9ac0fb2ed20BE88B9,   5e6, vestingTime180Days);
    AddressTokenAllocation internal foundersWallet      = AddressTokenAllocation(0xC66Cbb7Ba88F120E86920C0f85A97B2c68784755,  30e6, vestingTime90Days);
    AddressTokenAllocation internal wallet7             = AddressTokenAllocation(0x24ce108d1975f79B57c6790B9d4D91fC20DEaf2d,   6e6, 0);
    AddressTokenAllocation internal wallet8genesis      = AddressTokenAllocation(0x0125c6Be773bd90C0747012f051b15692Cd6Df31,   5e6, 0);
    AddressTokenAllocation internal wallet9             = AddressTokenAllocation(0xFCF0589B6fa8A3f262C4B0350215f6f0ed2F630D,   5e6, 0);
    AddressTokenAllocation internal wallet10            = AddressTokenAllocation(0x0D016B233e305f889BC5E8A0fd6A5f99B07F8ece,   4e6, 0);
    AddressTokenAllocation internal wallet11bounty      = AddressTokenAllocation(0x68433cFb33A7Fdbfa74Ea5ECad0Bc8b1D97d82E9,  19e6, 0);
    AddressTokenAllocation internal wallet12            = AddressTokenAllocation(0xd620A688adA6c7833F0edF48a45F3e39480149A6,   4e6, 0);
    AddressTokenAllocation internal wallet13rsv         = AddressTokenAllocation(0x8C393F520f75ec0F3e14d87d67E95adE4E8b16B1, 100e6, 0);
    AddressTokenAllocation internal wallet14partners    = AddressTokenAllocation(0x6F842b971F0076C4eEA83b051523d76F098Ffa52,  96e6, 0);
    AddressTokenAllocation internal wallet15lottery     = AddressTokenAllocation(0xcaA48d91D49f5363B2974bb4B2DBB36F0852cf83,   1e6, 0);

    uint256 public minimumICOCap = 3333;
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    *  Constructor
    *
    *  Sets contract owner to address of constructor caller
    */
    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    *  Change Owner
    *
    *  Changes ownership of this contract. Only owner can call this method.
    *
    * @param newOwner - new owner's address
    */
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TKLNToken is Owned, CrowdsaleParameters {
    /* Public variables of the token */
    string public standard = 'Token 0.1';
    string public name = 'Taklimakan';
    string public symbol = 'TKLN';
    uint8 public decimals = 18;

    /* Arrays of all balances, vesting, approvals, and approval uses */
    mapping (address => uint256) private balances;              // Total token balances
    mapping (address => uint256) private balances90dayFreeze;   // Balances frozen for 90 days after ICO end
    mapping (address => uint256) private balances180dayFreeze;  // Balances frozen for 180 days after ICO end
    mapping (address => uint) private vestingTimesForPools;
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => mapping (address => bool)) private allowanceUsed;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed spender, address indexed from, address indexed to, uint256 value);
    event VestingTransfer(address indexed from, address indexed to, uint256 value, uint256 vestingTime);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Issuance(uint256 _amount); // triggered when the total supply is increased
    event Destruction(uint256 _amount); // triggered when the total supply is decreased
    event NewTKLNToken(address _token);

    /* Miscellaneous */
    uint256 public totalSupply = 0;
    bool public transfersEnabled = true;

    /**
    *  Constructor
    *
    *  Initializes contract with initial supply tokens to the creator of the contract
    */
    function TKLNToken() public {
        owner = msg.sender;

        mintToken(presaleWallet);
        mintToken(generalSaleWallet);
        mintToken(wallet1);
        mintToken(wallet2);
        mintToken(wallet3);
        mintToken(wallet4);
        mintToken(wallet5);
        mintToken(wallet6);
        mintToken(foundersWallet);
        mintToken(wallet7);
        mintToken(wallet8genesis);
        mintToken(wallet9);
        mintToken(wallet10);
        mintToken(wallet11bounty);
        mintToken(wallet12);
        mintToken(wallet13rsv);
        mintToken(wallet14partners);
        mintToken(wallet15lottery);

        NewTKLNToken(address(this));
    }

    modifier transfersAllowed {
        require(transfersEnabled);
        _;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    /**
    *  1. Associate crowdsale contract address with this Token
    *  2. Allocate general sale amount
    *
    * @param _crowdsaleAddress - crowdsale contract address
    */
    function approveCrowdsale(address _crowdsaleAddress) external onlyOwner {
        approveAllocation(generalSaleWallet, _crowdsaleAddress);
    }

    /**
    *  1. Associate pre-sale contract address with this Token
    *  2. Allocate presale amount
    *
    * @param _presaleAddress - pre-sale contract address
    */
    function approvePresale(address _presaleAddress) external onlyOwner {
        approveAllocation(presaleWallet, _presaleAddress);
    }

    function approveAllocation(AddressTokenAllocation tokenAllocation, address _crowdsaleAddress) internal {
        uint uintDecimals = decimals;
        uint exponent = 10**uintDecimals;
        uint amount = tokenAllocation.amount * exponent;

        allowed[tokenAllocation.addr][_crowdsaleAddress] = amount;
        Approval(tokenAllocation.addr, _crowdsaleAddress, amount);
    }

    /**
    *  Get token balance of an address
    *
    * @param _address - address to query
    * @return Token balance of _address
    */
    function balanceOf(address _address) public constant returns (uint256 balance) {
        return balances[_address];
    }

    /**
    *  Get vested token balance of an address
    *
    * @param _address - address to query
    * @return balance that has vested
    */
    function vestedBalanceOf(address _address) public constant returns (uint256 balance) {
        return balances[_address] - balances90dayFreeze[_address] - balances180dayFreeze[_address];
    }

    /**
    *  Get token amount allocated for a transaction from _owner to _spender addresses
    *
    * @param _owner - owner address, i.e. address to transfer from
    * @param _spender - spender address, i.e. address to transfer to
    * @return Remaining amount allowed to be transferred
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
    *  Send coins from sender's address to address specified in parameters
    *
    * @param _to - address to send to
    * @param _value - amount to send in Wei
    */
    function transfer(address _to, uint256 _value) public transfersAllowed onlyPayloadSize(2*32) returns (bool success) {
        updateVesting(msg.sender);

        require(vestedBalanceOf(msg.sender) >= _value);

        // Subtract from the sender
        // _value is never greater than balance of input validation above
        balances[msg.sender] -= _value;

        // If tokens issued from this address need to vest (i.e. this address is a pool), freeze them here
        if (vestingTimesForPools[msg.sender] > 0) {
            addToVesting(msg.sender, _to, vestingTimesForPools[msg.sender], _value);
        }

        // Overflow is never possible due to input validation above
        balances[_to] += _value;

        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    *  Create token and credit it to target address
    *  Created tokens need to vest
    *
    */
    function mintToken(AddressTokenAllocation tokenAllocation) internal {
        // Add vesting time for this pool
        vestingTimesForPools[tokenAllocation.addr] = tokenAllocation.vestingTS;

        uint uintDecimals = decimals;
        uint exponent = 10**uintDecimals;
        uint mintedAmount = tokenAllocation.amount * exponent;

        // Mint happens right here: Balance becomes non-zero from zero
        balances[tokenAllocation.addr] += mintedAmount;
        totalSupply += mintedAmount;

        // Emit Issue and Transfer events
        Issuance(mintedAmount);
        Transfer(address(this), tokenAllocation.addr, mintedAmount);
    }

    /**
    *  Allow another contract to spend some tokens on your behalf
    *
    * @param _spender - address to allocate tokens for
    * @param _value - number of tokens to allocate
    * @return True in case of success, otherwise false
    */
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2*32) returns (bool success) {
        require(_value == 0 || allowanceUsed[msg.sender][_spender] == false);

        allowed[msg.sender][_spender] = _value;
        allowanceUsed[msg.sender][_spender] = false;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
    *  Allow another contract to spend some tokens on your behalf
    *
    * @param _spender - address to allocate tokens for
    * @param _currentValue - current number of tokens approved for allocation
    * @param _value - number of tokens to allocate
    * @return True in case of success, otherwise false
    */
    function approve(address _spender, uint256 _currentValue, uint256 _value) public onlyPayloadSize(3*32) returns (bool success) {
        require(allowed[msg.sender][_spender] == _currentValue);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    *  A contract attempts to get the coins. Tokens should be previously allocated
    *
    * @param _to - address to transfer tokens to
    * @param _from - address to transfer tokens from
    * @param _value - number of tokens to transfer
    * @return True in case of success, otherwise false
    */
    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed onlyPayloadSize(3*32) returns (bool success) {
        updateVesting(_from);

        // Check if the sender has enough
        require(vestedBalanceOf(_from) >= _value);

        // Check allowed
        require(_value <= allowed[_from][msg.sender]);

        // Subtract from the sender
        // _value is never greater than balance because of input validation above
        balances[_from] -= _value;
        // Add the same to the recipient
        // Overflow is not possible because of input validation above
        balances[_to] += _value;

        // Deduct allocation
        // _value is never greater than allowed amount because of input validation above
        allowed[_from][msg.sender] -= _value;

        // If tokens issued from this address need to vest (i.e. this address is a pool), freeze them here
        if (vestingTimesForPools[_from] > 0) {
            addToVesting(_from, _to, vestingTimesForPools[_from], _value);
        }

        Transfer(msg.sender, _from, _to, _value);
        allowanceUsed[_from][msg.sender] = true;

        return true;
    }

    /**
    *  Default method
    *
    *  This unnamed function is called whenever someone tries to send ether to
    *  it. Just revert transaction because there is nothing that Token can do
    *  with incoming ether.
    *
    *  Missing payable modifier prevents accidental sending of ether
    */
    function() public {
    }

    /**
    *  Enable or disable transfers
    *
    * @param _enable - True = enable, False = disable
    */
    function toggleTransfers(bool _enable) external onlyOwner {
        transfersEnabled = _enable;
    }

    /**
    *  Destroy unsold preICO tokens
    *
    */
    function closePresale() external onlyOwner {
        // Destroyed amount is never greater than total supply,
        // so no underflow possible here
        uint destroyedAmount = balances[presaleWallet.addr];
        totalSupply -= destroyedAmount;
        balances[presaleWallet.addr] = 0;
        Destruction(destroyedAmount);
        Transfer(presaleWallet.addr, 0x0, destroyedAmount);
    }

    /**
    *  Destroy unsold general sale tokens
    *
    */
    function closeGeneralSale() external onlyOwner {
        // Destroyed amount is never greater than total supply,
        // so no underflow possible here
        uint destroyedAmount = balances[generalSaleWallet.addr];
        totalSupply -= destroyedAmount;
        balances[generalSaleWallet.addr] = 0;
        Destruction(destroyedAmount);
        Transfer(generalSaleWallet.addr, 0x0, destroyedAmount);
    }

    function addToVesting(address _from, address _target, uint256 _vestingTime, uint256 _amount) internal {
        if (CrowdsaleParameters.vestingTime90Days == _vestingTime) {
            balances90dayFreeze[_target] += _amount;
            VestingTransfer(_from, _target, _amount, _vestingTime);
        } else if (CrowdsaleParameters.vestingTime180Days == _vestingTime) {
            balances180dayFreeze[_target] += _amount;
            VestingTransfer(_from, _target, _amount, _vestingTime);
        }
    }

    function updateVesting(address sender) internal {
        if (CrowdsaleParameters.vestingTime90Days < now) {
            balances90dayFreeze[sender] = 0;
        }
        if (CrowdsaleParameters.vestingTime180Days < now) {
            balances180dayFreeze[sender] = 0;
        }
    }
}