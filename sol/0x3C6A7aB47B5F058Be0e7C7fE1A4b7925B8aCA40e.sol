pragma solidity 0.4.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
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
    //Variables
    address public owner;

    address public newOwner;

    //    Modifiers
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
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;

    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20 is Ownable {
    using SafeMath for uint256;

    /* Public variables of the token */
    string public standard;

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    bool public locked;

    uint256 public creationBlock;

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ERC20(
        uint256 _totalSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        bool transferAllSupplyToOwner,
        bool _locked
    ) public {
        standard = "ERC20 0.1";

        totalSupply = _totalSupply;

        if (transferAllSupplyToOwner) {
            setBalance(msg.sender, totalSupply);

            Transfer(0, msg.sender, totalSupply);
        } else {
            setBalance(this, totalSupply);

            Transfer(0, this, totalSupply);
        }

        name = tokenName;
        // Set the name for display purposes
        symbol = tokenSymbol;
        // Set the symbol for display purposes
        decimals = decimalUnits;
        // Amount of decimals for display purposes
        locked = _locked;
        creationBlock = block.number;
    }

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) {
        require(locked == false);

        bool status = transferInternal(msg.sender, _to, _value);

        require(status == true);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (locked) {
            return false;
        }

        allowance[msg.sender][_spender] = _value;

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (locked) {
            return false;
        }

        if (allowance[_from][msg.sender] < _value) {
            return false;
        }

        bool _success = transferInternal(_from, _to, _value);

        if (_success) {
            allowance[_from][msg.sender] -= _value;
        }

        return _success;
    }
    /* internal balances */

    function setBalance(address holder, uint256 amount) internal {
        balanceOf[holder] = amount;
    }

    function transferInternal(address _from, address _to, uint256 value) internal returns (bool success) {
        if (value == 0) {
            return false;
        }

        if (balanceOf[_from] < value) {
            return false;
        }

        setBalance(_from, balanceOf[_from].sub(value));
        setBalance(_to, balanceOf[_to].add(value));

        Transfer(_from, _to, value);

        return true;
    }
}

contract LoggedERC20 is ERC20 {
    /* Structures */
    struct LogValueBlock {
        uint256 value;
        uint256 block;
    }

    LogValueBlock[] public loggedTotalSupply;

    /* This creates an array with all balances */
    mapping (address => LogValueBlock[]) public loggedBalances;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function LoggedERC20(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        bool transferAllSupplyToOwner,
        bool _locked
    )	public
        ERC20(initialSupply, tokenName, decimalUnits, tokenSymbol, transferAllSupplyToOwner, _locked)
    {
        standard = "LogValueBlockToken 0.1";
    }

    function valueAt(LogValueBlock[] storage valueBlocks, uint256 _block) internal returns (uint256) {
        if (valueBlocks.length == 0) {
            return 0;
        }

        if (valueBlocks[0].block > _block) {
            return 0;
        }

        if (valueBlocks[valueBlocks.length.sub(1)].block <= _block) {
            return valueBlocks[valueBlocks.length.sub(1)].value;
        }

        uint256 first = 0;
        uint256 last = valueBlocks.length.sub(1);

        uint256 middle = (first.add(last).add(1)).div(2);

        while (last > first) {
            if (valueBlocks[middle].block <= _block) {
                first = middle;
            } else {
                last = middle.sub(1);
            }

            middle = (first.add(last).add(1)).div(2);
        }

        return valueBlocks[first].value;
    }

    function setBalance(address _address, uint256 value) internal {
        loggedBalances[_address].push(LogValueBlock(value, block.number));

        balanceOf[_address] = value;
    }
}

contract LoggedDividend is Ownable, LoggedERC20 {
    /* Structs */
    struct Dividend {
        uint256 id;

        uint256 block;
        uint256 time;
        uint256 amount;

        uint256 claimedAmount;
        uint256 transferedBack;

        uint256 totalSupply;
        uint256 recycleTime;

        bool recycled;

        mapping (address => bool) claimed;
    }

    /* variables */
    Dividend[] public dividends;

    mapping (address => uint256) dividendsClaimed;

    /* Events */
    event DividendTransfered(
        uint256 id,
        address indexed _address,
        uint256 _block,
        uint256 _amount,
        uint256 _totalSupply
    );

    event DividendClaimed(uint256 id, address indexed _address, uint256 _claim);

    event UnclaimedDividendTransfer(uint256 id, uint256 _value);

    event DividendRecycled(
        uint256 id,
        address indexed _recycler,
        uint256 _blockNumber,
        uint256 _amount,
        uint256 _totalSupply
    );
    
    function LoggedDividend(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        bool transferAllSupplyToOwner,
        bool _locked
    ) 
		public
		LoggedERC20(initialSupply, tokenName, decimalUnits, tokenSymbol, transferAllSupplyToOwner, _locked) {
        
    }

    function addDividend(uint256 recycleTime) public payable onlyOwner {
        require(msg.value > 0);

        uint256 id = dividends.length;
        uint256 _totalSupply = totalSupply;

        dividends.push(
            Dividend(
                id,
                block.number,
                now,
                msg.value,
                0,
                0,
                _totalSupply,
                recycleTime,
                false
            )
        );

        DividendTransfered(id, msg.sender, block.number, msg.value, _totalSupply);
    }

    function claimDividend(uint256 dividendId) public returns (bool) {
        if ((dividends.length).sub(1) < dividendId) {
            return false;
        }

        Dividend storage dividend = dividends[dividendId];

        if (dividend.claimed[msg.sender] == true) {
            return false;
        }

        if (dividend.recycled == true) {
            return false;
        }

        if (now >= dividend.time.add(dividend.recycleTime)) {
            return false;
        }

        uint256 balance = valueAt(loggedBalances[msg.sender], dividend.block);

        if (balance == 0) {
            return false;
        }

        uint256 claim = balance.mul(dividend.amount).div(dividend.totalSupply);

        dividend.claimed[msg.sender] = true;

        dividend.claimedAmount = dividend.claimedAmount.add(claim);

        if (claim > 0) {
            msg.sender.transfer(claim);
            DividendClaimed(dividendId, msg.sender, claim);

            return true;
        }

        return false;
    }

    function claimDividends() public {
        require(dividendsClaimed[msg.sender] < dividends.length);
        for (uint i = dividendsClaimed[msg.sender]; i < dividends.length; i++) {
            if ((dividends[i].claimed[msg.sender] == false) && (dividends[i].recycled == false)) {
                dividendsClaimed[msg.sender] = i.add(1);
                claimDividend(i);
            }
        }
    }

    function recycleDividend(uint256 dividendId) public onlyOwner returns (bool success) {
        if (dividends.length.sub(1) < dividendId) {
            return false;
        }

        Dividend storage dividend = dividends[dividendId];

        if (dividend.recycled) {
            return false;
        }

        dividend.recycled = true;

        return true;
    }

    function refundUnclaimedEthers(uint256 dividendId) public onlyOwner returns (bool success) {
        if ((dividends.length).sub(1) < dividendId) {
            return false;
        }

        Dividend storage dividend = dividends[dividendId];

        if (dividend.recycled == false) {
            if (now < (dividend.time).add(dividend.recycleTime)) {
                return false;
            }
        }

        uint256 claimedBackAmount = (dividend.amount).sub(dividend.claimedAmount);

        dividend.transferedBack = claimedBackAmount;

        if (claimedBackAmount > 0) {
            owner.transfer(claimedBackAmount);

            UnclaimedDividendTransfer(dividendId, claimedBackAmount);

            return true;
        }

        return false;
    }
}

contract PhaseICO is LoggedDividend {
    uint256 public icoSince;
    uint256 public icoTill;

    uint256 public collectedEthers;

    Phase[] public phases;

    struct Phase {
        uint256 price;
        uint256 maxAmount;
    }
    
    function PhaseICO(
        uint256 _icoSince,
        uint256 _icoTill,
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint8 precision,
        bool transferAllSupplyToOwner,
        bool _locked
    ) 
		public
		LoggedDividend(initialSupply, tokenName, precision, tokenSymbol, transferAllSupplyToOwner, _locked) {
        standard = "PhaseICO 0.1";

        icoSince = _icoSince;
        icoTill = _icoTill;
    }

    function() public payable {
        bool status = buy(msg.sender, now, msg.value);

        require(status == true);
    }

    function getIcoTokensAmount(uint256 _collectedEthers, uint256 value) public  constant returns (uint256) {
        uint256 amount;

        uint256 newCollectedEthers = _collectedEthers;
        uint256 remainingValue = value;
        
        for (uint i = 0; i < phases.length; i++) {
            Phase storage phase = phases[i];

            if (phase.maxAmount > newCollectedEthers) {
                if (newCollectedEthers.add(remainingValue) > phase.maxAmount) {
                    uint256 diff = phase.maxAmount.sub(newCollectedEthers);

                    amount = amount.add(diff.mul(1 ether).div(phase.price));

                    remainingValue = remainingValue.sub(diff);
                    newCollectedEthers = newCollectedEthers.add(diff);
                } else {
                    amount += remainingValue * 1 ether / phase.price;

                    newCollectedEthers += remainingValue;

                    remainingValue = 0;
                }
            }

            if (remainingValue == 0) {
                break;
            }
        }
        
        if (remainingValue > 0) {
            return 0;
        }

        return amount;
    }

    function buy(address _address, uint256 time, uint256 value) internal returns (bool) {
        if (locked == true) {
            return false;
        }

        if (time < icoSince || time > icoTill) {
            return false;
        }

        if (value == 0) {
            return false;
        }

        uint256 amount = getIcoTokensAmount(collectedEthers, value);

        if (amount == 0) {
            return false;
        }

        uint256 selfBalance = valueAt(loggedBalances[this], block.number);
        uint256 holderBalance = valueAt(loggedBalances[_address], block.number);

        if (selfBalance < amount) {
            return false;
        }

        setBalance(_address, holderBalance.add(amount));
        setBalance(this, selfBalance.sub(amount));

        collectedEthers = collectedEthers.add(value);

        Transfer(this, _address, amount);

        return true;
    }
}

contract Cajutel is PhaseICO {

    address public migrateAddress;

    modifier onlyMigrate() {
        require(migrateAddress == msg.sender);
        _;
    }

    function Cajutel(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint256 icoSince,
        uint256 icoTill
    ) PhaseICO(icoSince, icoTill, initialSupply, tokenName, tokenSymbol, 18, false, false) {
        standard = "Cajutel 0.1";

        phases.push(Phase(0.05 ether, 500 ether));
        phases.push(Phase(0.075 ether, 750 ether + 500 ether));
        phases.push(Phase(0.1 ether, 10000 ether + 750 ether + 500 ether));
        phases.push(Phase(0.15 ether, 30000 ether + 10000 ether + 750 ether + 500 ether));
        phases.push(Phase(0.2 ether, 80000 ether + 30000 ether + 10000 ether + 750 ether + 500 ether));
    
    }

    /* public methods */
    function setMigrateAddress(address _address) public onlyOwner {
        migrateAddress = _address;
    }

    function transferEthers() public onlyOwner {
        owner.transfer(this.balance);
    }

    function setLocked(bool _locked) public onlyOwner {
        locked = _locked;
    }

    function setIcoDates(uint256 _icoSince, uint256 _icoTill) public onlyOwner {
        icoSince = _icoSince;
        icoTill = _icoTill;
    }

    function setMigratedBalance(address _holderAddress, uint256 _value) public onlyMigrate {
        require(balanceOf[this].sub(_value) >= 0);
        setBalance(_holderAddress, _value);
        setBalance(this, balanceOf[this].sub(_value));
        Transfer(this, _holderAddress, _value);
    }
}

contract MigrateBalances is Ownable {

    Balance[] public balances;

    bool public balancesSet;

    struct Balance {
        address holderAddress;
        uint256 amount;
        bool migrated;
    }

    Cajutel public newCajutel;

    function MigrateBalances(address _newCajutel) public {
        require(_newCajutel != address(0));
        newCajutel = Cajutel(_newCajutel);


    }
    // 0-82
    //  1 function
    function setBalances() public onlyOwner {
        require(false == balancesSet);
        balancesSet = true;
        balances.push(Balance(0x15d9250358489Ceb509121963Ff80e747c7F981f, 900246000000000000000000, false));
        balances.push(Balance(0x21C5DfD6FccA838634D0039c9B15B7bA57Bd6298, 100000000000000000000000, false));
        balances.push(Balance(0x716134814fD704C3b7C2d829068d70962D942FdA, 49888300000000000000000, false));
        balances.push(Balance(0xb719f3A03293A71fB840b1e32C79EE6885A9C771, 8290600000000000000000, false));
        balances.push(Balance(0x9e1F7671149a6888DCf3882c6Ab1408aBdE6E102, 3000000000000000000000, false));
        balances.push(Balance(0xAF691ED473eBE4fbF90A7Ceaf0E29b2D82c293fC, 2000000000000000000000, false));
        balances.push(Balance(0x255e1dAB5bA7c575951E12286f7c3B6714CFeE92, 1000000000000000000000, false));
        balances.push(Balance(0x8d12A197cB00D4747a1fe03395095ce2A5CC6819, 1000000000000000000000, false));
        balances.push(Balance(0xBcEa2d09C05691B0797DeD95D07836aD5551Cb78, 500000000000000000000, false));
        balances.push(Balance(0x6270e2C43d89AcED92955b6D47b455627Ba75B57, 380000000000000000000, false));
        balances.push(Balance(0x2321A30FF9dFD1edE3718b11a2C74118Eb673f75, 200000000000000000000, false));
        balances.push(Balance(0x9BE1c7a1F118F61740f01e96d292c0bae90360aB, 171000000000000000000, false));
        balances.push(Balance(0x390bef0e73e51C4daaF70fDA390fa8da6EA07D88, 145000000000000000000, false));
        balances.push(Balance(0xA79dfeaE0D50d723fc333995C664Fcf3Ca8d7455, 113000000000000000000, false));
        balances.push(Balance(0x4aB7dA32F383e618522eD9724b1c19C63d409FbE, 111625924457445000000, false));
        balances.push(Balance(0xb00D6EDDF69dCcE079bd615196967CE596661951, 108000000000000000000, false));
        balances.push(Balance(0x9c60b97Cb5A10182fd69B5D022A75F1A74e598cF, 102359033442992000000, false));
        balances.push(Balance(0xbCf6e1fa53243f319788E63E91F89e9A43F5D8B4, 100000000000000000000, false));
        balances.push(Balance(0x5870d3b1e32721cAB6804e6497092f0f38804f14, 100000000000000000000, false));
        balances.push(Balance(0x00BC7d1910Bc4424AEd7EDDF5E5a008931625C28, 100000000000000000000, false));
        balances.push(Balance(0xcbFb05E6Ff8054663959dFD842f80BDAC06B40D7, 99000000000000000000, false));
        balances.push(Balance(0xFdF758e6c2dE14a056d96B06f2c55333FBB089c8, 80000000000000000000, false));
        balances.push(Balance(0xcE735a5c6FEB88DD7D13b5Faa7c27894eb4E5AE0, 80000000000000000000, false));
        balances.push(Balance(0x3B1D9FD8862AED71BC56fffE45a74F110ee4bB30, 76324349107581500000, false));
        balances.push(Balance(0xD649F8260C194bBC02302c6360398678482B484A, 76000000000000000000, false));
        balances.push(Balance(0xc3e53F02FEcdB6D1EfeDAA4e5bb504b74EDbDc2B, 64000000000000000000, false));
        balances.push(Balance(0x74a6Fd23EFEABd5C1ec6DB56A012124Bb8096326, 60000000000000000000, false));
        balances.push(Balance(0x15AD355116A4Ce684B26f67A9458924976a3A895, 60000000000000000000, false));
        balances.push(Balance(0x7B120968eEdd48865CA44b913A2437B876f5e295, 60000000000000000000, false));
        balances.push(Balance(0x4ECABB300a16Ec35AF215BDA39637F9993A3c7Ac, 58666666666666700000, false));
        balances.push(Balance(0x807D077060A71b9d84A6a53a67369177BdFc61DD, 52292213506666700000, false));
        balances.push(Balance(0x6D8864eEB5e292e49F9E65276296691f935d93F8, 51986666666666600000, false));
        balances.push(Balance(0x404C0d6424EF6A07843dF75fdeE528918387ca05, 50000000000000000000, false));
        balances.push(Balance(0x7D8679e2681B69F73D87DB4CD72477738D9CDB28, 50000000000000000000, false));
        balances.push(Balance(0x57B734d29122882570Ee2FcBD75F6c438CBD1c5F, 49078842800000000000, false));
        balances.push(Balance(0xf818d8a6588fdc5eF13c62D63Adb477f242F2225, 48000000000000000000, false));
        balances.push(Balance(0x3AA5F7CfeAc40495C8e89551B716DEa4a61BB6C1, 45200000000000000000, false));
        balances.push(Balance(0x70057E29C1c1166EB4f5625DDCf2AAC3AffAC682, 41666666666666700000, false));
        balances.push(Balance(0x623B56D702468AA253cF81383765A510998b3A3F, 41400000000000000000, false));
        balances.push(Balance(0xc2Fe74A950b7b657ddB8D23B143e02CB2806EC8D, 41000000000000000000, false));
        balances.push(Balance(0x433D67a103661159d6867e96867c18D2292B093B, 40060026820483100000, false));
        balances.push(Balance(0xeE526282ad8Ab39a43F3202DBBA380762A92667E, 40000000000000000000, false));
        balances.push(Balance(0xdbf9d1127AD20B14Df8f5b19719831bF0496d443, 40000000000000000000, false));
        balances.push(Balance(0xDBADecbb2e5d5e70a488830296a8918920a4D41F, 40000000000000000000, false));
        balances.push(Balance(0x82d2Edb5024A255bFdbCE618E7f341D1DEe14a4B, 40000000000000000000, false));
        balances.push(Balance(0x8cF84382DB1Ccf1ed1b32c0187db644b35cbc299, 40000000000000000000, false));
        balances.push(Balance(0x68C9D9912cd56E415Bfd3A31651f98006F89b410, 38666666666666700000, false));
        balances.push(Balance(0x0e9691088A658DDF416DB57d02ad7DeF173ef74C, 38000000000000000000, false));
        balances.push(Balance(0x078cfD085962f8dB8B3eaD10Ce9009f366CF51d8, 37000000000000000000, false));
        balances.push(Balance(0xe553D979278bDBc0927c1667C2314A5446315be8, 35000000000000000000, false));
        balances.push(Balance(0xa1D6A35d3B13Cca6d56cB7D07Da9a89F4c3C0C4a, 35000000000000000000, false));
        balances.push(Balance(0x5BE78822bb773112969Aac90BBfc837fAE8D2ac7, 32600000000000000000, false));
        balances.push(Balance(0x3e9719f94F7BFBcDD2F1D66a18236D942fF4a087, 30082572981493200000, false));
        balances.push(Balance(0xea9C95FB771De9e1E19aA25cA2E190aE96466CDD, 30000000000000000000, false));
        balances.push(Balance(0xfFFd54E22263F13447032E3941729884e03F4d58, 29280000000000000000, false));
        balances.push(Balance(0xC5E522c2aAbAcf8182EA97277f60Ef9E6787f03d, 29000000000000000000, false));
        balances.push(Balance(0x5105BA072ADCe7D7F993Eec00a1deEA82015422f, 27000000000000000000, false));
        balances.push(Balance(0xb7A4E02F126fbD35e9365a4D51c414697DceF063, 26666666666666700000, false));
        balances.push(Balance(0x909B749D2330c3b374FcDb4B9B599942583F4E1E, 26666666666666600000, false));
        balances.push(Balance(0x8FddF2D321A5F6d3DAc50c3Cfe0b773e78BBe79D, 26400000000000000000, false));
        balances.push(Balance(0xbFA4fA007b5B0C946e740334A4Ff7d977244e705, 26000000000000000000, false));
        balances.push(Balance(0x802e2a1CfdA97311009D9b0CC253CfB7f824c40c, 25333333333333300000, false));
        balances.push(Balance(0x5d8d29BEFe9eB053aF67D776b7E3cECdA07A9E10, 25000000000000000000, false));
        balances.push(Balance(0x51908426DE197677a73963581952dFf87E825480, 24000000000000000000, false));
        balances.push(Balance(0x893b6CF80B613A394220BEBe01Cd4C616470B0C7, 24000000000000000000, false));
        balances.push(Balance(0xC08A6c874E43B4AA42DE6591E8be593f2557fF8C, 23700000000000000000, false));
        balances.push(Balance(0xFD2CF1F76a931D441F67fB73D05E211E89b0d9C7, 22000000000000000000, false));
        balances.push(Balance(0xF828be1B6e274FfB28E1Ea948cBde24efE8948e9, 22000000000000000000, false));
        balances.push(Balance(0x8ecDd5B4bD04d3b33B6591D9083AFAA6EBf9171b, 20800000000000000000, false));
        balances.push(Balance(0x19d51226d74fbe6367601039235598745EC2907c, 20181333333333300000, false));
        balances.push(Balance(0xfC73413D8dCc28D271cdE376835EdF6690Fa91a8, 20000000000000000000, false));
        balances.push(Balance(0xD24D4B5f7Ea0ECF4664FE3E5efF357E4abAe9faA, 20000000000000000000, false));
        balances.push(Balance(0xC9e29bacE9f74baFff77919A803852C553BC89E5, 20000000000000000000, false));
        balances.push(Balance(0xbEADCd526616ffBF31A613Ca95AC0F665986C90A, 20000000000000000000, false));
        balances.push(Balance(0xa88c9a308B920090427B8814ae0E79ce294B2F6F, 20000000000000000000, false));
        balances.push(Balance(0x8630F7577dd24afD574f6ddB4A4c640d2abae482, 20000000000000000000, false));
        balances.push(Balance(0x787e6870754Cc306C1758db62DC6Cd334bA76345, 20000000000000000000, false));
        balances.push(Balance(0x146cA2f2b923517EabE39367B9bAb530ab6114B6, 20000000000000000000, false));
        balances.push(Balance(0x7Ff7c0630227442C1428d55aDca6A722e442c364, 20000000000000000000, false));
        balances.push(Balance(0x00CfbBb1609C6F183a4bc7061fA72c09F62d7691, 20000000000000000000, false));
        balances.push(Balance(0x1ABfAB721Ff6317F8bD3bc3BCDAED8F794B4b03e, 19800000000000000000, false));
        balances.push(Balance(0xC4f4361035d7E646E09F910e94a5D9F200D697d1, 19773874840000000000, false));
        balances.push(Balance(0x4AB9fC8553793cedC64b9562F41701eBF49d7Bb8, 19000000000000000000, false));
    }
    /*
        // 0-82
        //  2 function
        function setBalances() public onlyOwner {
            require(false == balancesSet);
            balancesSet = true;
            balances.push(Balance(0x2E7C4Eeffe28577752BeD70Afc7f947c47f2328b, 18400000000000000000, false));
            balances.push(Balance(0xD5C04965bc6bbED679f5FC0f0a26c28065fD8F9B, 18266666666666600000, false));
            balances.push(Balance(0x902B340Bba04327be29750AFA2cD1439E6D83a66, 18027999999999900000, false));
            balances.push(Balance(0x1Be09cAB2460e60b3A04F681C80c98FFA10623Bb, 18000000000000000000, false));
            balances.push(Balance(0xC885Bc9707B3634c2456000DFa5156c8D9A325A8, 17136353173333300000, false));
            balances.push(Balance(0xd62ef0997700d3a8f1f803f3e33B9E2398975c24, 17000000000000000000, false));
            balances.push(Balance(0x43A3Ba1EE0481252071ECAf83c0FA1a05b0fA80d, 17000000000000000000, false));
            balances.push(Balance(0x8dE91C8F86c74b5dDf5cD39153cB323329533A66, 16510128700706000000, false));
            balances.push(Balance(0x55E6ac8f44240379e7FD86E74fC7f7fD1925D877, 15733333333333300000, false));
            balances.push(Balance(0x9FAb44AAd10922100B5e4Ea6e347C01bC4A6e82f, 15000000000000000000, false));
            balances.push(Balance(0x6F45cf56760ED1A988d7D845687AdB01D6C42E86, 15000000000000000000, false));
            balances.push(Balance(0x1E8401E810236F08756868CE8b8bB6bF5Faf6F14, 15000000000000000000, false));
            balances.push(Balance(0xd1fd8a89ED8ce301A8058a9027110E0B3c204607, 14961634413333300000, false));
            balances.push(Balance(0x1b48c80B8BBD5Cb2a6dFfe0b0f73fEffeD85d287, 14875815053333300000, false));
            balances.push(Balance(0xcd71468FD73f68C3A519Dbab7cc745Aa61C8aEE9, 14666666666666600000, false));
            balances.push(Balance(0x5FAdadDA4b539BE9Ab11DA615264fe22a5BCbC9e, 14666666666666600000, false));
            balances.push(Balance(0x2E5F427293CD42a967C4A29809FaFCc526991977, 14533333333333300000, false));
            balances.push(Balance(0x5e029DEC60b608FdA9097D6A302a04F80EC6F082, 13400000000000000000, false));
            balances.push(Balance(0xfF383360Ab9a6112bee27e2D968877b5B206922a, 13333333333333300000, false));
            balances.push(Balance(0xFd21d911492889277C253Bc9Bd6B91BeC0d6a06B, 13333333333333300000, false));
            balances.push(Balance(0xF0D11121Ba96b5a44d6b25Aca5d84e70235510a1, 13333333333333300000, false));
            balances.push(Balance(0xAeEAAa501F50D217dcf2e65a044095E3e5b8b60E, 13333333333333300000, false));
            balances.push(Balance(0x22e627A19016F0a10226997F5961e79a3E400824, 13333333333333300000, false));
            balances.push(Balance(0x11f50fdFBB7B58558Af2628d4E0086B10ad6d2F4, 13333333333333300000, false));
            balances.push(Balance(0x3c1Affc2f98Fee9a919Fd9EF4BDC6B334Cf4d971, 13267234778933300000, false));
            balances.push(Balance(0xa5F7087a0c3164DdC4e4AcfBf2771aCdDbC23923, 13200000000000000000, false));
            balances.push(Balance(0x73A1e0e35BEe4F778Eea32db1982F62A8a3Ea7b7, 13173333333333300000, false));
            balances.push(Balance(0x691d3e097D9fcA5388771EcB5eC31a18dF6D7699, 12286799893333300000, false));
            balances.push(Balance(0xC04B58Ebb894E67c84bdE0d99dC2Ab150DAAD9B9, 12000000000000000000, false));
            balances.push(Balance(0x7Fe3239b89A39212ca944118c2f2E3d8B513d369, 12000000000000000000, false));
            balances.push(Balance(0x3ebeCe83E121086307cAD746E5C8e685B7f97f07, 12000000000000000000, false));
            balances.push(Balance(0x0d32975dF4F220f43DB58787F9c7416eb8D25531, 12000000000000000000, false));
            balances.push(Balance(0x92C5E9E40D2F4706fE40aC9E5d1a237C9e9b33d9, 11800000000000000000, false));
            balances.push(Balance(0x7eD1E469fCb3EE19C0366D829e291451bE638E59, 11782517834753000000, false));
            balances.push(Balance(0x4feF09dD155627CB5cAC5e339175C1c8E01446Da, 11518665901333300000, false));
            balances.push(Balance(0x5Ee5B9B4D4ED0C98fB96b54B4e4EDe7fa9ec505D, 11400000000000000000, false));
            balances.push(Balance(0xD421b473d29438fEff49aFAE6d71d7b33f40aa1F, 11333333333333300000, false));
            balances.push(Balance(0xe99C2E8552C9272e0665735Bd49E918D6359D81c, 11000000000000000000, false));
            balances.push(Balance(0xa7608a906aB12421Bfc28d8c0B19b47132Ee6a49, 10582756106666600000, false));
            balances.push(Balance(0x0f235e81D55372Bd50a12a6D67790fbc355774A2, 10133333333333300000, false));
            balances.push(Balance(0xE99Fd2ae593C26e9D6B82123833178eC8934bDf8, 10000000000000000000, false));
            balances.push(Balance(0xdC7e911178BBBdBB32c29fcAf8Fd01D611049371, 10000000000000000000, false));
            balances.push(Balance(0xd5c10eD5e93Bd7411cE9E5939E47a8c2A35bE703, 10000000000000000000, false));
            balances.push(Balance(0xACE457acDAC762E266284B2d8009eD5329929f13, 10000000000000000000, false));
            balances.push(Balance(0xa5a03220f753D0153330b70870dF298d0dF2DEaD, 10000000000000000000, false));
            balances.push(Balance(0x545edd24149bEDf3E1F9da318A919334182C3338, 10000000000000000000, false));
            balances.push(Balance(0x27F8d64A716a82132B21bFeEA122674A6F238E85, 10000000000000000000, false));
            balances.push(Balance(0x14e359817845Cf8167b58F9aBd2a8c50A1d90859, 10000000000000000000, false));
            balances.push(Balance(0x8bEFC3c5940Cf146d066810cf17C6D28f9141BEe, 10000000000000000000, false));
            balances.push(Balance(0x8A11D3d03629fBd5cAE5f8Ef0743BaE86868d040, 10000000000000000000, false));
            balances.push(Balance(0x6f81097A3584646ed9E75A60CCCD76AB76A8A97E, 10000000000000000000, false));
            balances.push(Balance(0x5BDc4BDCF5Dc447D01d0DF474D0D192a620068d2, 9654511980000000000, false));
            balances.push(Balance(0x5478423C0177C910DDea3e9Bc15C534009ef400F, 9491436740000000000, false));
            balances.push(Balance(0xFBB1ca1C13d78a9940Fe3c907039D7dD5B6fe383, 9000000000000000000, false));
            balances.push(Balance(0x0697F258FE4B0Fc4998c5CC1A04E5099b3423da2, 9000000000000000000, false));
            balances.push(Balance(0x10C7794aC7b7826743DC6A24CAAbCeDd29D63875, 9000000000000000000, false));
            balances.push(Balance(0xF77c1683B1E190c96247D981F445CA1c3C3785C4, 8666666666666670000, false));
            balances.push(Balance(0xf7b3c582E4CA9BFe54a617520840Ec5A95efa0A4, 8620106666666660000, false));
            balances.push(Balance(0xF234d0fe4197D5Fa698B778f04e5C9E4417E6717, 8333333333333330000, false));
            balances.push(Balance(0x8C7BD48e7721F9d4E2bB43dac7d1e0DF748366d8, 8319831560000000000, false));
            balances.push(Balance(0xA0Fea79Cb49C391EAc284bf2CEC7BE4f3c3Ca689, 8280354240000000000, false));
            balances.push(Balance(0xe80CcC716aC60d0FEc87e72C3d3946C893065bBd, 8000000000000000000, false));
            balances.push(Balance(0xA5B4fC1aF71356f2a6de00175FDE5150F4F720BA, 8000000000000000000, false));
            balances.push(Balance(0x360EaEfa7723B2219adAF46D046555b490dB4B16, 8000000000000000000, false));
            balances.push(Balance(0x1995f8Ec00BcF0Cb7C91274f1B5719e70CF60f79, 7960000000000000000, false));
            balances.push(Balance(0xfD2f23421d70df082b8b9A0E9dC216D4A75f49B7, 7866666666666670000, false));
            balances.push(Balance(0x007796e342A02667912164F0E92eA1B9996c6A77, 7866666666666670000, false));
            balances.push(Balance(0xBD9898a3c6b2eeD503741e2FBAF56fE20a2D3691, 7840000000000000000, false));
            balances.push(Balance(0xb807052d90fFBA5435cBf3861aEB7B5285058F06, 7600000000000000000, false));
            balances.push(Balance(0x6C813527d52EF56E0dCdFb2Aa95dDa103294ee33, 7466666666666670000, false));
            balances.push(Balance(0x33fe15c42a9b038C81652D95AA3482962CcAa065, 7333333333333330000, false));
            balances.push(Balance(0xE89688A255aCbA59F75D9C378c87E12CB8d5B6DD, 6867366653333330000, false));
            balances.push(Balance(0xF82cAC3c9Af16d15226638186F2B011813ed5446, 6762764640000000000, false));
            balances.push(Balance(0xD3a1653F3A4812C63594FA33ed15426FBc7fEC18, 6666666666666670000, false));
            balances.push(Balance(0x4979e620Dee9c45B3801151e305Cc637E5E53979, 6610636133333330000, false));
            balances.push(Balance(0x4644d6e363d354dB6DB5b98030b969B69f3B69FF, 6600000000000000000, false));
            balances.push(Balance(0xeE1b9C8b520e054bb669f6f8891E296339ebBEc8, 6570666666666670000, false));
            balances.push(Balance(0x0dA58317be9Fa1A114311A274D6366Cc4880a6fF, 6550878359999990000, false));
            balances.push(Balance(0x033263376caEDc85dFC72FB61625ef0dcB1f0cA6, 6519999999999990000, false));
            balances.push(Balance(0x83de37d7a7e870a405fc406492fcEF9deE3328b0, 6449576773333330000, false));
            balances.push(Balance(0x9B7a8b471ad9A43e36d69aB971c7A03c6F5b5b41, 6300000000000000000, false));
            balances.push(Balance(0xa0Bc54f4c7904F27A02c87211863a5ea7F685CC0, 6293333333333330000, false));
            balances.push(Balance(0x386a7389a64b32a68844127587b859591371Ea33, 6273905293333330000, false));
        }

        // 0-81
        //  3 function
        function setBalances() public onlyOwner {
            require(false == balancesSet);
            balancesSet = true;
            balances.push(Balance(0x371fF0d66bAf9CaD9369C63d45562986E2B8F90C, 6266666666666670000, false));
            balances.push(Balance(0x76f9164341d1C869d051EafDB807BF2BBdcc1AA9, 6266666666666670000, false));
            balances.push(Balance(0x79da4243A0021b27daa5996a2673d95557b8e157, 6236993226666660000, false));
            balances.push(Balance(0xfFcDf5Dd495c560EFB41B827abC8445a17b2d4D3, 6000000000000000000, false));
            balances.push(Balance(0xf79Dfbc147361C69AE88Ff855603F428b567369c, 6000000000000000000, false));
            balances.push(Balance(0xDAA8482d30f47c9a662f481D586E0065c38Ec1c1, 6000000000000000000, false));
            balances.push(Balance(0xc046b59484843B2Af6Ca105aFD88A3aB60E9B7cD, 6000000000000000000, false));
            balances.push(Balance(0x700dD0Fd005232eC67d2B42744D647c9cF8dc345, 6000000000000000000, false));
            balances.push(Balance(0x81a39131384D27E64cDA76B5F0769DC642Cfc1a3, 6000000000000000000, false));
            balances.push(Balance(0x4c19Ca7e6898D0E408cB3a314Fd9ea24eBc65dDd, 6000000000000000000, false));
            balances.push(Balance(0x4c46B3233ac7367fdf9f8B2bE60C50AAE432a5Eb, 5946666666666670000, false));
            balances.push(Balance(0x1F61Ffadbdb6Bb24A1423B1A1B51e26d54AEf5F1, 5820000000000000000, false));
            balances.push(Balance(0x2917D828c305e4272C318d21E8DA369d2D11A6bA, 5800000000000000000, false));
            balances.push(Balance(0x7F4924590beA483375fC8E3809E43FDc9c812CDb, 5733333333333330000, false));
            balances.push(Balance(0xF59E21AfeE56927Cd6a9911459980f6FBe4Fb523, 5653333333333330000, false));
            balances.push(Balance(0x811ba42d34f34904551CDBC8056a3E9feAFBCcDC, 5428478826666670000, false));
            balances.push(Balance(0xf19A0CaaD22455dF01962B9af0dD314967E062E0, 5333333333333330000, false));
            balances.push(Balance(0x4e117b659FdDD5fcf3eeA1179181658C5E17E11f, 5333333333333330000, false));
            balances.push(Balance(0x4B3aF3f0Cae89149995d61d723C9bFE3FDf5D061, 5333333333333330000, false));
            balances.push(Balance(0xFD390993E85Dbe665eBE8dCF04DD363984897010, 5200000000000000000, false));
            balances.push(Balance(0x056Bc3f2Cc058B92CBbBA2F7f4b6fB2A0f931566, 5187309836290610000, false));
            balances.push(Balance(0x0fa258b052d5314A86285ed2456c68CC80cd36B7, 5166482352266670000, false));
            balances.push(Balance(0xFC56A208df3F77A49E349c6D64d9132e36112a49, 5000000000000000000, false));
            balances.push(Balance(0xf414A478B1fA0fc3C15F7D570171e54A4c160Cf1, 5000000000000000000, false));
            balances.push(Balance(0xdB08F4D86f3f51B02f77C742d25754d495D5c02F, 5000000000000000000, false));
            balances.push(Balance(0xAFce3d722A5988a4e3F9eAC3A8f0Eacf05a1b7bF, 5000000000000000000, false));
            balances.push(Balance(0x55A70EaE30Be140B07B4c2285388eA696bdeAC12, 5000000000000000000, false));
            balances.push(Balance(0x2E062Cb1256B22B1Ef14FBB559db28D6b3312331, 5000000000000000000, false));
            balances.push(Balance(0x1ec102092FA2f76a00D275a593581BaBb4b0d35e, 5000000000000000000, false));
            balances.push(Balance(0xc5a4E2F35f58c95561373a11eBC91BaDde37b301, 4880403374552850000, false));
            balances.push(Balance(0x59BfD269A95A3746F41265f20d9D20260659852c, 4800000000000000000, false));
            balances.push(Balance(0xD2f4eA8929fcBefD47458C80cCFA33c4C6773C26, 4720000000000000000, false));
            balances.push(Balance(0x6838ee2f0aA44Bfa3a94a8dab2D0C694c6bD37B4, 4666666666666670000, false));
            balances.push(Balance(0x438899E2c698AA504C59b438cB0626ac0E7E364A, 4533333333333330000, false));
            balances.push(Balance(0x97AD9D9E2f7b58A0D8B5DAb4f7BCc6A47cDcA387, 4400000000000000000, false));
            balances.push(Balance(0x4F66366A17E1c74Ade6621A62b11450c08b42123, 4280000000000000000, false));
            balances.push(Balance(0x0A9847F217364b7A410A9b089ae774492C9Bfcc6, 4053333333333330000, false));
            balances.push(Balance(0xaC82E7efe5b69734773a8665dA9d789BB31036d6, 4048299813333330000, false));
            balances.push(Balance(0x7FBa95a19b855C89819c28803d9782e494B03db8, 4013333333333340000, false));
            balances.push(Balance(0xC8472Fb6F3D94AE2881F337dcE159D0cb6E3A9e5, 4000000000000000000, false));
            balances.push(Balance(0xc2f6f54c997ccFdB16EAbC9439C38E566b5D8e94, 4000000000000000000, false));
            balances.push(Balance(0x4958Ebe8A02d4e0DCc821D52F87fb6ab60f1888b, 4000000000000000000, false));
            balances.push(Balance(0x34B62809DF67CA50355E34C62035F0F349e001c7, 4000000000000000000, false));
            balances.push(Balance(0x05d8B374E90763AA1373A5963aCdac062dc816F7, 4000000000000000000, false));
            balances.push(Balance(0x5CeA4B49F353a5A1431f3241453e17d502c40Ab4, 4000000000000000000, false));
            balances.push(Balance(0x5c9BcBbB185359d7afeda7fC9096F2027EBf6CAF, 4000000000000000000, false));
            balances.push(Balance(0x2DAA8a3775bea2F5CC836cc790fEe4810E97b8FA, 4000000000000000000, false));
            balances.push(Balance(0x3D783ef5Eff9Ec76353615036c17F9556aCa380b, 3887711800000000000, false));
            balances.push(Balance(0x4E1BE9868134b9cd9432F82904518cD34cB9a3B9, 3773687573333330000, false));
            balances.push(Balance(0x036057B70CbC3dEDBC259D5c6A8Ed3382A225bCf, 3720000000000000000, false));
            balances.push(Balance(0x48A445976b2fb495c95Fb56d6131bbc9e0D09Fca, 3623200000000000000, false));
            balances.push(Balance(0x4eD37d7555313Ec22d1B400ba798fdF7d011a9B6, 3600000000000000000, false));
            balances.push(Balance(0x24a82ed86118152c4fd0e9dEb06b1ebeC6BB9E6D, 3589761466666670000, false));
            balances.push(Balance(0xBDDE70d2084aDFE855403A12889714715a8C1e56, 3481209466666670000, false));
            balances.push(Balance(0x5C2Ed36050C1e4391BE80052732e2B370C618305, 3466666666666660000, false));
            balances.push(Balance(0x3b438278922B59bcd75d77A7567b43Eb78502b3b, 3421383440000000000, false));
            balances.push(Balance(0xdF1b73ACf7868F62b8E039A2Bc06e710748cE78E, 3407565920000000000, false));
            balances.push(Balance(0xeF9012D6999f0F5eA80aDEc41a334C9980152485, 3333333333333330000, false));
            balances.push(Balance(0x144266894Be83727aE107F30C48750cb5d373F89, 3333333333333330000, false));
            balances.push(Balance(0x031B2508d64748cBd9269EBe6db984a5190094c9, 3333333333333330000, false));
            balances.push(Balance(0xC53b57486911fe29c2312D6Cc038EE6B4F342B50, 3327312586666670000, false));
            balances.push(Balance(0x85F6DE00E308D620A87C0f1BE7098527758E4bc2, 3232612814723720000, false));
            balances.push(Balance(0x96fC4553a00C117C5b0bED950Dd625d1c16Dc894, 3210160567733330000, false));
            balances.push(Balance(0xD1b00A899C4ef80C00f38eEDa27E5C2E4818aAE3, 3200000000000000000, false));
            balances.push(Balance(0x685476666d67186ddA207A7900fd3CE42a3F8319, 3200000000000000000, false));
            balances.push(Balance(0x2449AfBeC7e84e462bCA730797CC0F943B0fF1C9, 3200000000000000000, false));
            balances.push(Balance(0x945dEFa8C0AF4620C50CEE663782E7BFd04659f9, 3186666666666670000, false));
            balances.push(Balance(0xe9a43F38D79F06c2f819b8d2c071a6F0E0afEBdc, 3150467965333330000, false));
            balances.push(Balance(0x1E59894B31f446f6fE17D248e0E1E2DB00aC7750, 3129639200000000000, false));
            balances.push(Balance(0x961d2ac3B73F70C797A7fDa4314b619f21f79c45, 3125333333333330000, false));
            balances.push(Balance(0x6ebC927713F5DeecEb419e00E8e15133Ed297f02, 3066666666666670000, false));
            balances.push(Balance(0xEeFfd610258662932571798d4776Da840F71f48E, 3042306493333330000, false));
            balances.push(Balance(0xaAebf97e7151C4C2E7BD1dA5067b4eF3AA56A58F, 3000000000000000000, false));
            balances.push(Balance(0x6CDdA861D14190942ecbB9DC604698f54EF3fFAC, 3000000000000000000, false));
            balances.push(Balance(0x2cC6f276a0d97a4DA731392436139ea50798a7c4, 2981662066666670000, false));
            balances.push(Balance(0x194D433811500f92ce0703C623fcBD9D22f0D20d, 2901856317579730000, false));
            balances.push(Balance(0x61873f7D0AA20714e9be262FdeCE4D00302A537B, 2860000000000000000, false));
            balances.push(Balance(0x97a2E8Fa7140B3C07AA9622556541AA3d0cCce24, 2854321156798670000, false));
            balances.push(Balance(0xbBba52db669b98993391bC6987E8A6F016900063, 2813092680000000000, false));
            balances.push(Balance(0xa7c66D322E7FA00F6fF4443C7D4b313dF11b9eCf, 2800000000000000000, false));
            balances.push(Balance(0x5994D61758C7E4A2212e14182960951Ee7A37F17, 2800000000000000000, false));
            balances.push(Balance(0x3a0A22f0815d97A7aE2b132Fe0B7Be0cc74D6d8e, 2785551880000000000, false));
        }

        // 0-65
        //  4 function
        function setBalances() public onlyOwner {
            require(false == balancesSet);
            balancesSet = true;
            balances.push(Balance(0x8484BF8F6454600ECa054185F53174BD784a6490, 2783764133333330000, false));
            balances.push(Balance(0xa85c961c1Fba50f11F5e0ADd12A000Bc03b043f7, 2666666666666670000, false));
            balances.push(Balance(0x150a96971F1c4c042c5CE8298EE7E5C5610e7332, 2666666666666670000, false));
            balances.push(Balance(0x66d6B446BEFA2e22Ebfb433f38FAD6F01B188224, 2666666666666670000, false));
            balances.push(Balance(0x2A92BB77E42D6D67155c77f1123015bCEaF8657F, 2666666666666670000, false));
            balances.push(Balance(0xdC8bbeBECb9732c0504882105F3434E364ad44bb, 2607915053333330000, false));
            balances.push(Balance(0x119Ebd2F5c92eadA1DFfb451c10D220C7f24e53a, 2519999999999990000, false));
            balances.push(Balance(0x1c8901f0D6Cd36b35B6eA4EE8Dd113383E711725, 2500000000000000000, false));
            balances.push(Balance(0x8588eD5CE596E42747DF186b1D26D95E6fbA69eb, 2472599540000000000, false));
            balances.push(Balance(0xA55f8a37fEefBD727bB8A3C4D8C44d5B00DdC141, 2400000000000000000, false));
            balances.push(Balance(0x485f444bFd453A73EF5cE6923b4D2CCa86ba513E, 2400000000000000000, false));
            balances.push(Balance(0x90f3F20dfc60a364AD6A6a3C1aDdd81003F77c82, 2400000000000000000, false));
            balances.push(Balance(0x3A28a3B783e606b1a22BeC608F1d40b4C4beD5ce, 2380000000000000000, false));
            balances.push(Balance(0xCfDcdA60766966d0c1E1d76a8817ddE0332F6a0c, 2268000000000000000, false));
            balances.push(Balance(0x072e88436b90c075f0344971Db8AB75cb41b5764, 2266666666666670000, false));
            balances.push(Balance(0x882d0A7c619B884F3d73b5133C9635e05370Ab38, 2266666666666660000, false));
            balances.push(Balance(0xa41B7F17Be829D34e92ACa5BE6BE4355e00cC0eb, 2226666666666660000, false));
            balances.push(Balance(0xB04f047A03a0e4f5db546dA3F01CDf18fdC98d20, 2200000000000000000, false));
            balances.push(Balance(0x455Ad5b479A721E4D6ce30c219Aa92c323d89F52, 2200000000000000000, false));
            balances.push(Balance(0xE9dEF4E1a49a6C6063711fC5c7Ba6bA092Ac5C0F, 2199999999999990000, false));
            balances.push(Balance(0x480E401c0BF0fF20411b94C5EfB2c878B34A8c82, 2094619756266660000, false));
            balances.push(Balance(0xf43454711605563856aeE726C8e50798768c282E, 2000000000000000000, false));
            balances.push(Balance(0xe02Fda32aC0C4CB0B4d8a9B5d903Ab9225d168Cf, 2000000000000000000, false));
            balances.push(Balance(0xd0741a61CcF1CF3B3AA2f013738877492257D9dB, 2000000000000000000, false));
            balances.push(Balance(0xBD7290743348EEA8c0c21765031440afE27b29AE, 2000000000000000000, false));
            balances.push(Balance(0x220F2361A468152f1724D71368DC82cfB66d5572, 2000000000000000000, false));
            balances.push(Balance(0x186d5F47d59cD7Df01A3bb850E7fA5362941ef99, 2000000000000000000, false));
            balances.push(Balance(0x3c6006171DCB541c22d5Aad0D7E4952be832ca2a, 2000000000000000000, false));
            balances.push(Balance(0x1fE15AbA927e0deBE7E98Ba19DdD19928e8b2Bde, 2000000000000000000, false));
            balances.push(Balance(0x5CF8fa10d538CFB31Dfa420cBA9bb94df563544A, 1933333333333330000, false));
            balances.push(Balance(0xdf5eB859a29Cc5400B5eE7d1108DBF487dabC631, 1866666666666670000, false));
            balances.push(Balance(0x6b025AF153568DE895385f62C9A8B0AAc3fb9A4C, 1850165503200000000, false));
            balances.push(Balance(0xBa14D4e004e31354C70320216F655A805C1c0670, 1773333333333330000, false));
            balances.push(Balance(0x76b0229FE7fA0a599E75947B90AbeC1883178F3D, 1754666666666670000, false));
            balances.push(Balance(0x8e45f1cdC764b6ee7D7c9Ac81220eD6c28CD6260, 1665121893333330000, false));
            balances.push(Balance(0xF05281a2b7Ca2281FA0b1DA28Cbf42C8604396D1, 1600000000000000000, false));
            balances.push(Balance(0x77c0016feA4b7C41CB7867518f23A5Cde66F8cD4, 1538005980000020000, false));
            balances.push(Balance(0x831F88027c17a18EF041f5F0c320604456A244b1, 1413333333333330000, false));
            balances.push(Balance(0x17C71585B380a980089cF4CAb946097D29c0A288, 1401933333333330000, false));
            balances.push(Balance(0x4644253383a1D07a4F844273aE1e8Bc45176C7Ba, 1400000000000000000, false));
            balances.push(Balance(0xF298A211C9B13E49d02727093D8F9cEc4b372080, 1333333333333330000, false));
            balances.push(Balance(0x58c6A53ed6edCe4aE2E52f1608aedB48b3a10131, 1333333333333330000, false));
            balances.push(Balance(0x6f336b5AeA97Fd3Fd2AEa190271E8fBfafE1B566, 1333333333333330000, false));
            balances.push(Balance(0x6ef15707916E8744A7c77D7Ea1E95261Ac38ABFc, 1200000000000000000, false));
            balances.push(Balance(0xbc9106E6bDCbcCb48Da71bC67Bd75F55C4f2a117, 1146666666666660000, false));
            balances.push(Balance(0x6A7AA8cdf5983d4520E5773b503d329aB7e68a0c, 1133333333333330000, false));
            balances.push(Balance(0xcceE5Cb8512D3aDc26d5a5185a4d47B0D02f1455, 1066666666666670000, false));
            balances.push(Balance(0xB1Fedad00E869D114becfe4517a25f0EA80886D5, 1066666666666670000, false));
            balances.push(Balance(0xba47Fb3679D3F017AC6e3f98331fDAccEAc4Ffca, 1066666666666660000, false));
            balances.push(Balance(0xEFf9244D85980aE28664755CCcD3b85Aa73d6dA3, 1000000000000000000, false));
            balances.push(Balance(0x3175eB1D23526DcE5C87867CBE849CBa41f3C5a5, 1000000000000000000, false));
            balances.push(Balance(0xa34D3461Ae04953489E9AA464689C022836751d0, 1000000000000000000, false));
            balances.push(Balance(0x895378a947CA5ec14a823cc3e2E384733Ee93bee, 1000000000000000000, false));
            balances.push(Balance(0x376Bf213522B7dfD7D33D9c30e2Caa10837c23E0, 1000000000000000000, false));
            balances.push(Balance(0x57bdC4635415fa66EBd3C64C09F24318281984e4, 1000000000000000000, false));
            balances.push(Balance(0x5ed397aBA0a34a5Fe27F9f1d7309934b2Ca9dfD0, 1000000000000000000, false));
            balances.push(Balance(0x2f3Cf16dB02326fCbFB9AbDc3ADd26F2f547284A, 1000000000000000000, false));
            balances.push(Balance(0xe2BB8aFbff30A4BE03426cf3589bf5c4Cd3F4367, 973333333333333000, false));
            balances.push(Balance(0xa785c232573D89A06B5A2aE9bEcc67Ab09a5981e, 920000000000000000, false));
            balances.push(Balance(0xAEc80673d9Eb052977eA1fEB68cce33499d80BF0, 880000000000000000, false));
            balances.push(Balance(0x3BbCb294029B7eD76E5feC2fefc6cf02B8B2B326, 866666666666667000, false));
            balances.push(Balance(0x7e9cEac8cBAb21A25337724221423B8A1Cb32a0E, 809787013333333000, false));
            balances.push(Balance(0x30D53503D1AdB861A1B0Cca6d3Efa0585d2e085d, 800000000000000000, false));
            balances.push(Balance(0x1E7f70dD818A7928DaD446Ae50758f39657B563A, 779880760000000000, false));
            balances.push(Balance(0xAc57675316F497837403e7702a8322aa64ccb2De, 713268034400000000, false));
            balances.push(Balance(0x5c10109694c3abEF570E70B45992470e781Ba009, 681696080000000000, false));
        }

        // 0-21
        //  5 function
        function setBalances() public onlyOwner {
            require(false == balancesSet);
            balancesSet = true;
            balances.push(Balance(0xa1773Ec142D3a88d413dEbF81f4b5fF53284D4EA, 680531360000000000, false));
            balances.push(Balance(0xDcAE45a3755962d349341C0d5f679d5e1EC5778a, 666666666666666000, false));
            balances.push(Balance(0x238FCFd88C6A48D0Ec55D040b70Ddc534730fC57, 666666666666666000, false));
            balances.push(Balance(0xaD2C2b0488e5fFFfC8d04fC8610f0692C7636A77, 600000000000000000, false));
            balances.push(Balance(0x482E251Ab0738deEDcf2FEFbF1Dd73eFAf14F1C0, 600000000000000000, false));
            balances.push(Balance(0x430683a1871B11506c2e40dF82733f175F29742e, 560000000000000000, false));
            balances.push(Balance(0xA230D922a31F6C956100d3e674630ac812E7d887, 466666666666667000, false));
            balances.push(Balance(0xFBb1b73C4f0BDa4f67dcA266ce6Ef42f520fBB98, 448000000000000000, false));
            balances.push(Balance(0xF13E3f4fF2782f01aeECb846979AAEb1F0bC452E, 400000000000000000, false));
            balances.push(Balance(0x5Cc1d3e2996BdfDeB4CfC079689E39D58c80f763, 400000000000000000, false));
            balances.push(Balance(0x52AB19a3cd7e5dFCF5447eB14EBD6162ca76C3c9, 366666666666670000, false));
            balances.push(Balance(0xABd03B1C1F84468579047bd0BD5Df023e5fbbA7B, 326999999999999000, false));
            balances.push(Balance(0x7594C284898bcFca0C7475dbAfE5Eaf131Ede3ff, 266666666666666000, false));
            balances.push(Balance(0x238afBfE3E401ad2e41980306C701D1978cB9cB3, 240000000000000000, false));
            balances.push(Balance(0xb03A1ad4F138979319559A735877673379AaE5dB, 200000000000000000, false));
            balances.push(Balance(0x4d0Db0F1C043f5b53fE77153b39166a7Adf41707, 200000000000000000, false));
            balances.push(Balance(0xF769329A7fdaE282F1d0eA11E274E534BF0701aE, 133333333333333000, false));
            balances.push(Balance(0xa0D457a560bE0fFBCE524b582948E40eeE12fEB7, 133333333333333000, false));
            balances.push(Balance(0x31ab0770A38b97121f9f07E25a1E418010b8e3bE, 133333333333333000, false));
            balances.push(Balance(0x9c65Fc67acFADBb98498c1Fa07Cdb6E384fE94b5, 133333333333333000, false));
            balances.push(Balance(0x135c1CaC2138C2C34041E0a0978844FE2E03c8e5, 40000000000000000, false));
            balances.push(Balance(0xbe51b6Fa0110c007bC546dec21804C2bE542D1AE, 20000000000000000, false));
        }
    */

    function setNewCajutel(address _cajutel) public onlyOwner {
        require(_cajutel != address(0));
        newCajutel = Cajutel(_cajutel);
    }

    function getBalancesLength() public constant onlyOwner returns (uint256) {
        return balances.length;
    }

    function doMigration(uint256 _start, uint256 _finish) public onlyOwner {
        if (_finish == 0) {
            _finish = balances.length;
        }
        require(_finish < balances.length);
        for (uint i = _start; i <= _finish; i++) {
            Balance storage balance = balances[i];
            if (balance.migrated == true) {
                continue;
            }
            if (balance.amount > 0) {
                newCajutel.setMigratedBalance(balance.holderAddress, balance.amount);
                balance.migrated = true;
            }

        }
    }

    function doSingleMigration(uint256 _id) public onlyOwner {
        require(_id < balances.length);
        Balance storage balance = balances[_id];
        require(false == balance.migrated);
        if (balance.amount > 0) {
            newCajutel.setMigratedBalance(balance.holderAddress, balance.amount);
            balance.migrated = true;
        }

    }

    function checkStatus(uint256 _id) public constant onlyOwner returns (bool){
        require(_id < balances.length);
        Balance storage balance = balances[_id];
        return balance.migrated;
    }
}