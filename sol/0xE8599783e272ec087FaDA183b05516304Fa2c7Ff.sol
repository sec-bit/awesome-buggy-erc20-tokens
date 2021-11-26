pragma solidity 0.4.15;


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
            newOwner = address(0);
        }
    }
}


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

contract TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}


contract ERC20 is Ownable {
    using SafeMath for uint256;

    /* Public variables of the token */
    uint256 public initialSupply;

    uint256 public creationBlock;

    uint8 public decimals;

    string public name;

    string public symbol;

    string public standard;

    bool public locked;

    bool public transferFrozen;

    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) public allowed;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    modifier onlyPayloadSize(uint _numwords) {
        assert(msg.data.length == _numwords * 32 + 4);
        _;
    }

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ERC20(
        uint256 _initialSupply,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transferAllSupplyToOwner,
        bool _locked
    )
        public
    {
        standard = "ERC20 0.1";

        initialSupply = _initialSupply;

        if (_transferAllSupplyToOwner) {
            setBalance(msg.sender, initialSupply);
        } else {
            setBalance(this, initialSupply);
        }

        name = _tokenName;
        // Set the name for display purposes
        symbol = _tokenSymbol;
        // Set the symbol for display purposes
        decimals = _decimalUnits;
        // Amount of decimals for display purposes
        locked = _locked;
        creationBlock = block.number;
    }

    /* public methods */
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
        require(locked == false);
        require(transferFrozen == false);
    
        bool status = transferInternal(msg.sender, _to, _value);

        require(status == true);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (locked) {
            return false;
        }

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        if (locked) {
            return false;
        }

        TokenRecipient spender = TokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool success) {
        if (locked) {
            return false;
        }

        if (transferFrozen) {
            return false;
        }

        if (allowed[_from][msg.sender] < _value) {
            return false;
        }

        bool _success = transferInternal(_from, _to, _value);

        if (_success) {
            allowed[_from][msg.sender] -= _value;
        }

        return _success;
    }

    /*constant functions*/
    function totalSupply() public constant returns (uint256) {
        return initialSupply;
    }

    function balanceOf(address _address) public constant returns (uint256 balance) {
        return balances[_address];
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* internal functions*/
    function setBalance(address _holder, uint256 _amount) internal {
        balances[_holder] = _amount;
    }

    function transferInternal(address _from, address _to, uint256 _value) internal returns (bool success) {
        require(locked == false);
        require(transferFrozen == false);

        if (_value == 0) {
            Transfer(_from, _to, _value);

            return true;
        }

        if (balances[_from] < _value) {
            return false;
        }

        setBalance(_from, balances[_from].sub(_value));
        setBalance(_to, balances[_to].add(_value));

        Transfer(_from, _to, _value);

        return true;
    }
}

contract ERC223 {
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string customFallback) public returns (bool ok);
}


contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

/*
    Based on https://github.com/Dexaran/ERC223-token-standard/blob/Recommended/ERC223_Token.sol
*/

contract ERC223Token is ERC223, ERC20 {
    function ERC223Token(
        uint256 _initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        bool transferAllSupplyToOwner,
        bool _locked
    )
        public
        ERC20(_initialSupply, tokenName, decimalUnits, tokenSymbol, transferAllSupplyToOwner, _locked)
    {
        
    }

    function transfer(address to, uint256 value, bytes data) public returns (bool success) {
        require(locked == false);
        
        bool status = transferInternal(msg.sender, to, value, data);

        return status;
    }

    function transfer(address to, uint value, bytes data, string customFallback) public returns (bool success) {
        require(locked == false);

        bool status = transferInternal(msg.sender, to, value, data, true, customFallback);

        return status;
    }

// rollback changes to transferInternal for transferFrom
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool success) {
        if (locked) {
            return false;
        }

        if (transferFrozen) {
            return false;
        }

        if (allowed[_from][msg.sender] < _value) {
            return false;
        }

        bool _success = super.transferInternal(_from, _to, _value);

        if (_success) {
            allowed[_from][msg.sender] -= _value;
        }

        return _success;
    }

    function transferInternal(address from, address to, uint256 value, bytes data) internal returns (bool success) {
        return transferInternal(from, to, value, data, false, "");
    }

    function transferInternal(
        address from,
        address to,
        uint256 value,
        bytes data,
        bool useCustomFallback,
        string customFallback
    )
        internal returns (bool success)
    {
        bool status = super.transferInternal(from, to, value);

        if (status) {
            if (isContract(to)) {
                ContractReceiver receiver = ContractReceiver(to);

                if (useCustomFallback) {
                    // solhint-disable-next-line avoid-call-value
                    require(receiver.call.value(0)(bytes4(keccak256(customFallback)), from, value, data) == true);
                } else {
                    receiver.tokenFallback(from, value, data);
                }
            }

            Transfer(from, to, value, data);
        }

        return status;
    }

    function transferInternal(address from, address to, uint256 value) internal returns (bool success) {
        require(locked == false);

        bytes memory data;

        return transferInternal(from, to, value, data, false, "");
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private returns (bool) {
        uint length;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
}

/*
This contract manages the minters and the modifier to allow mint to happen only if called by minters
This contract contains basic minting functionality though
*/
contract MintingERC20 is ERC223Token {

    using SafeMath for uint256;

    uint256 public maxSupply;

    mapping (address => bool) public minters;

    modifier onlyMinters () {
        require(true == minters[msg.sender]);
        _;
    }

    function MintingERC20(
        uint256 _initialSupply,
        uint256 _maxSupply,
        string _tokenName,
        uint8 _decimals,
        string _symbol,
        bool _transferAllSupplyToOwner,
        bool _locked
    )
        ERC223Token(_initialSupply, _tokenName, _decimals, _symbol, _transferAllSupplyToOwner, _locked)
    {
        minters[msg.sender] = true;
        maxSupply = _maxSupply;
    }

    function addMinter(address _newMinter) public onlyOwner {
        minters[_newMinter] = true;
    }

    function removeMinter(address _minter) public onlyOwner {
        minters[_minter] = false;
    }

    function mint(address _addr, uint256 _amount) public onlyMinters returns (uint256) {
        return internalMint(_addr, _amount);
    }

    function internalMint(address _addr, uint256 _amount) internal returns (uint256) {
        if (_amount == uint256(0)) {
            return uint256(0);
        }

        if (totalSupply().add(_amount) > maxSupply) {
            return uint256(0);
        }

        initialSupply = initialSupply.add(_amount);
        balances[_addr] = balances[_addr].add(_amount);
        Transfer(0, _addr, _amount);

        return _amount;
    }
}


contract AbstractClaimableToken {
    function claimedTokens(address _holder, uint256 _tokens) public;
}


contract GenesisToken is MintingERC20 {
    using SafeMath for uint256;

    /* variables */
    uint256 public emitTokensSince;

    TokenEmission[] public emissions;

    mapping(address => uint256) public lastClaims;

    /* structs */
    struct TokenEmission {
        uint256 blockDuration;      // duration of block in secs
        uint256 blockTokens;        // tokens per block
        uint256 periodEndsAt;     // duration in secs
        bool removed;
    }

    /* events */
    event ClaimedTokens(address _holder, uint256 _since, uint256 _till, uint256 _tokens);

    /* constructor */
    function GenesisToken(
        uint256 _totalSupply,
        uint8 _precision,
        string _name,
        string _symbol,
        bool _transferAllSupplyToOwner,
        bool _locked,
        uint256 _emitTokensSince,
        uint256 _maxSupply
    )
        public
        MintingERC20(_totalSupply, _maxSupply, _name, _precision, _symbol, _transferAllSupplyToOwner, _locked)
    {
        standard = "GenesisToken 0.1";
        emitTokensSince = _emitTokensSince;
    }

    function addTokenEmission(uint256 _blockDuration, uint256 _blockTokens, uint256 _periodEndsAt) public onlyOwner {
        emissions.push(TokenEmission(_blockDuration, _blockTokens, _periodEndsAt, false));
    }

    function removeTokenEmission(uint256 _i) public onlyOwner {
        require(_i < emissions.length);

        emissions[_i].removed = true;
    }

    function updateTokenEmission(uint256 _i, uint256 _blockDuration, uint256 _blockTokens, uint256 _periodEndsAt)
        public
        onlyOwner
    {
        require(_i < emissions.length);

        emissions[_i].blockDuration = _blockDuration;
        emissions[_i].blockTokens = _blockTokens;
        emissions[_i].periodEndsAt = _periodEndsAt;
    }

    function claim() public returns (uint256) {
        require(false == locked);

        uint256 currentBalance = balanceOf(msg.sender);
        uint256 currentTotalSupply = totalSupply();

        return claimInternal(block.timestamp, msg.sender, currentBalance, currentTotalSupply);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        return claimableTransferFrom(block.timestamp, _from, _to, _value);
    }

    function calculateEmissionTokens(
        uint256 _lastClaimedAt,
        uint256 _currentTime,
        uint256 _currentBalance,
        uint256 _totalSupply
    )
        public constant returns (uint256 tokens)
    {
        uint256 totalTokens = 0;

        uint256 newCurrentTime = _lastClaimedAt;
        uint256 remainingSeconds = _currentTime.sub(_lastClaimedAt);

        uint256 collectedTokensPerPeriod;

        for (uint256 i = 0; i < emissions.length; i++) {
            TokenEmission storage emission = emissions[i];

            if (emission.removed) {
                continue;
            }

            if (newCurrentTime < emission.periodEndsAt) {
                if (newCurrentTime.add(remainingSeconds) > emission.periodEndsAt) {
                    uint256 diff = emission.periodEndsAt.sub(newCurrentTime);

                    collectedTokensPerPeriod = getPeriodMinedTokens(
                    diff, _currentBalance,
                    emission.blockDuration, emission.blockTokens,
                    _totalSupply);

                    totalTokens += collectedTokensPerPeriod;

                    newCurrentTime += diff;
                    remainingSeconds -= diff;
                } else {
                    collectedTokensPerPeriod = getPeriodMinedTokens(
                        remainingSeconds, _currentBalance,
                        emission.blockDuration, emission.blockTokens,
                        _totalSupply
                    );

                    totalTokens += collectedTokensPerPeriod;

                    newCurrentTime += remainingSeconds;
                    remainingSeconds = 0;
                }
            }

            if (remainingSeconds == 0) {
                break;
            }
        }

        return totalTokens;
    }

    /* internal methods */
    function getPeriodMinedTokens(
        uint256 _duration, uint256 _balance,
        uint256 _blockDuration, uint256 _blockTokens,
        uint256
    )
    internal returns (uint256)
    {
        uint256 blocks = _duration.div(_blockDuration);

        return blocks.mul(_blockTokens).mul(_balance).div(maxSupply);
    }

    function tokensClaimedHook(address _holder, uint256 _since, uint256 _till, uint256 _tokens) internal {
        ClaimedTokens(_holder, _since, _till, _tokens);
    }

    function claimInternal(
        uint256 _time,
        address _address,
        uint256 _currentBalance,
        uint256 _currentTotalSupply
    )
    internal returns (uint256)
    {
        if (_time < emitTokensSince) {
            lastClaims[_address] = emitTokensSince;

            return 0;
        }

        if (_currentBalance == 0) {
            lastClaims[_address] = _time;

            return 0;
        }

        uint256 lastClaimAt = lastClaims[_address];

        if (lastClaimAt == 0) {
            lastClaims[_address] = emitTokensSince;
            lastClaimAt = emitTokensSince;
        }

        if (lastClaimAt >= _time) {
            return 0;
        }

        uint256 tokens = calculateEmissionTokens(lastClaimAt, _time, _currentBalance, _currentTotalSupply);

        if (tokens > 0) {
            tokensClaimedHook(_address, lastClaimAt, _time, tokens);

            lastClaims[_address] = _time;
        
            return tokens;
        }

        return 0;
    }

    function claimableTransfer(
        uint256 _time,
        address _from,
        address _to,
        uint256 _value,
        bytes _data,
        bool _useCustomFallback,
        string _customFallback
    )
    internal returns (bool success)
    {
        uint256 senderCurrentBalance = balanceOf(_from);
        uint256 receiverCurrentBalance = balanceOf(_to);

        uint256 _totalSupply = totalSupply();

        bool status = super.transferInternal(_from, _to, _value, _data, _useCustomFallback, _customFallback);

        require(status);

        claimInternal(_time, _from, senderCurrentBalance, _totalSupply);
        claimInternal(_time, _to, receiverCurrentBalance, _totalSupply);

        return true;
    }

    function transferInternal(
        address _from,
        address _to,
        uint256 _value,
        bytes _data,
        bool _useCustomFallback,
        string _customFallback
    )
    internal returns (bool success)
    {
        return claimableTransfer(block.timestamp, _from, _to, _value, _data, _useCustomFallback, _customFallback);
    }

    function claimableTransferFrom(
        uint256 _time,
        address _from,
        address _to,
        uint256 _value
    )
    internal returns (bool success)
    {
        uint256 senderCurrentBalance = balanceOf(_from);
        uint256 receiverCurrentBalance = balanceOf(_to);

        uint256 _totalSupply = totalSupply();

        bool status = super.transferFrom(_from, _to, _value);

        if (status) {
            claimInternal(_time, _from, senderCurrentBalance, _totalSupply);
            claimInternal(_time, _to, receiverCurrentBalance, _totalSupply);
        }
        
        return status;
    }

    function internalMint(address _addr, uint256 _amount) internal returns (uint256) {
        claimInternal(now, _addr, balanceOf(_addr), totalSupply());

        uint256 minted = super.internalMint(_addr, _amount);

        return minted;
    }
}

contract CLC is MintingERC20, AbstractClaimableToken {
    uint256 public createdAt;
    Clout public genesisToken;

    function CLC(uint256 _maxSupply, uint8 decimals, Clout _genesisToken, bool transferAllSupplyToOwner) public
        MintingERC20(0, _maxSupply, "CLC", decimals, "CLC", transferAllSupplyToOwner, false)
    {
        createdAt = now;
        standard = "CLC 0.1";
        genesisToken = _genesisToken;
    }

    function claimedTokens(address _holder, uint256 _tokens) public {
        require(msg.sender == address(genesisToken));

        uint256 minted = internalMint(_holder, _tokens);

        require(minted == _tokens);
    }

    function setGenesisToken(Clout _genesisToken) public onlyOwner {
        genesisToken = _genesisToken;
    }

    function setTransferFrozen(bool _frozen) public onlyOwner {
        transferFrozen = _frozen;
    }

    function setLocked(bool _locked) public onlyOwner {
        locked = _locked;
    }
}


contract Clout is GenesisToken {
    AbstractClaimableToken public claimableToken;
    uint256 public createdAt;

    mapping (address => bool) public issuers;

    function Clout(uint256 emitTokensSince,
        bool init,
        uint256 initialSupply,
        uint8 decimals,
        string tokenName,
        string tokenSymbol,
        bool transferAllSupplyToOwner
    )
        public
        GenesisToken(
            0,
            decimals,
            tokenName,
            tokenSymbol,
            transferAllSupplyToOwner,
            false,
            emitTokensSince,
            initialSupply
        )
        // solhint-disable-next-line function-max-lines
    {
        standard = "Clout 0.1";

        createdAt = now;

        // emissions
        if (init) {
//            uint256 period0 = createdAt;
//            uint256 period1 = 1514764800; // 2018-01-01T00:00:00Z
//            uint256 period2 = 1577836800; // 2020-01-01T00:00:00Z
//            uint256 period3 = 1672531200; // 2023-01-01T00:00:00Z
//            uint256 period4 = 1798761600; // 2027-01-01T00:00:00Z
//            uint256 period5 = 1956528000; // 2032-01-01T00:00:00Z
//            uint256 period6 = 2145916800; // 2038-01-01T00:00:00Z
//            uint256 period7 = 2366841600; // 2045-01-01T00:00:00Z
//            uint256 period8 = 2619302400; // 2053-01-01T00:00:00Z
//            uint256 period9 = 2903299200; // 2062-01-01T00:00:00Z

            uint256 blockDuration = 15;

            // after ico till 2018-01-01
            emissions.push(
                TokenEmission(
                    blockDuration,
                    100000000 * 10 ** 18 / ((1514764800 - emitTokensSince) / blockDuration), // tokens
                    1514764800, // till
                    false // removed
                )
            );

            // till 2020-01-01. blocks 4,204,800, tokens per block 2.378234399E19
            emissions.push(
                TokenEmission(
                    blockDuration,
                    100000000 * 10 ** 18 / ((1577836800 - 1514764800) / blockDuration), // tokens
                    1577836800, // till
                    false // removed
                )
            );

            // till 2023-01-01, blocks 6,312,960, tokens per block 1.584042985E19
            emissions.push(
                TokenEmission(
                    blockDuration,
                    100000000 * 10 ** 18 / ((1672531200 - 1577836800) / blockDuration), // tokens
                    1672531200, // till
                    false // removed
                )
            );

            // till 2027-01-01, blocks 8,415,360, tokens per block 1.188303293E19
            emissions.push(
                TokenEmission(
                    blockDuration,
                    100000000 * 10 ** 18 / ((1798761600 - 1672531200) / blockDuration), // tokens
                    1798761600, // till
                    false // removed
                )
            );

            // till 2032-01-01, blocks 10,517,760, tokens per block 9.507727881E18
            emissions.push(
                TokenEmission(
                    blockDuration,
                    100000000 * 10 ** 18 / ((1956528000 - 1798761600) / blockDuration), // tokens
                    1956528000, // till
                    false // removed
                )
            );

            // till 2038-01-01, blocks 12,625,920, tokens per block 7.920214923E18
            emissions.push(
                TokenEmission(
                    blockDuration,
                    100000000 * 10 ** 18 / ((2145916800 - 1956528000) / blockDuration), // tokens
                    2145916800, // till
                    false // removed
                )
            );

            // till 2045-01-01, blocks 14,728,320, tokens per block 6.789640638E18
            emissions.push(
                TokenEmission(
                    blockDuration,
                    100000000 * 10 ** 18 / ((2366841600 - 2145916800) / blockDuration), // tokens
                    2366841600, // till
                    false // removed
                )
            );

            // till 2053-01-01, blocks 16,830,720, tokens per block 5.941516465E18
            emissions.push(
                TokenEmission(
                    blockDuration,
                    100000000 * 10 ** 18 / ((2619302400 - 2366841600) / blockDuration), // tokens
                    2619302400, // till
                    false // removed
                )
            );

            // till 2062-01-01, blocks 18,933,120, tokens per block 5.281749654E18
            emissions.push(
                TokenEmission(
                    blockDuration,
                    100000000 * 10 ** 18 / ((2903299200 - 2619302400) / blockDuration), // tokens
                    2903299200, // till
                    false // removed
                )
            );
        }
    }

    function setEmissions(uint256[] array) public onlyOwner {
        require(array.length % 4 == 0);

        delete emissions;

        for (uint256 i = 0; i < array.length; i += 4) {
            emissions.push(TokenEmission(array[i], array[i + 1], array[i + 2], array[i + 3] == 0 ? false : true));
        }
    }

    function setClaimableToken(AbstractClaimableToken _token) public onlyOwner {
        claimableToken = _token;
    }

    function setTransferFrozen(bool _frozen) public onlyOwner {
        transferFrozen = _frozen;
    }

    function setLocked(bool _locked) public onlyOwner {
        locked = _locked;
    }

    function tokensClaimedHook(address _holder, uint256 since, uint256 till, uint256 amount) internal {
        if (claimableToken != address(0)) {
            claimableToken.claimedTokens(_holder, amount);
        }

        ClaimedTokens(_holder, since, till, amount);
    }
}

contract Multivest is Ownable {
    /* public variables */
    mapping (address => bool) public allowedMultivests;

    /* events */
    event MultivestSet(address multivest);

    event MultivestUnset(address multivest);

    event Contribution(address _holder, uint256 value, uint256 tokens);

    modifier onlyAllowedMultivests() {
        require(true == allowedMultivests[msg.sender]);
        _;
    }

    /* constructor */
    function Multivest(address multivest) {
        allowedMultivests[multivest] = true;
    }

    /* public methods */
    function setAllowedMultivest(address _address) public onlyOwner {
        allowedMultivests[_address] = true;
    }

    function unsetAllowedMultivest(address _address) public onlyOwner {
        allowedMultivests[_address] = false;
    }

    function multivestBuy(
        address _holder,
        uint256 _value
    )
    public
    onlyAllowedMultivests
    {
        bool status = buy(_holder, block.timestamp, _value);

        require(status == true);
    }

    function multivestBuy(
        bytes32 _hash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public payable
    {
        require(_hash == keccak256(msg.sender));
        require(allowedMultivests[verify(_hash, _v, _r, _s)] == true);
        bool status = buy(msg.sender, block.timestamp, msg.value);

        require(status == true);
    }

    function verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public constant returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";

        return ecrecover(keccak256(prefix, hash), v, r, s);
    }

    function buy(address _address, uint256 _time, uint256 _value) internal returns (bool);
}



contract ICO is Ownable, Multivest {
    uint256 public icoSince;
    uint256 public icoTill;

    uint8 public decimals;

    mapping(address => uint256) public holderEthers;
    uint256 public collectedEthers;
    uint256 public soldTokens;

    uint256 public minEthToContribute;

    Phase[] public phases;

    bool public locked;

    Clout public clout;
    CLC public clc;

    address[] public etherReceivers;
    address public etherMasterWallet;

    struct Phase {
        uint256 price;
        uint256 maxAmount;
    }

    event Contribution(address _holder, uint256 _ethers, uint256 _clouts, uint256 _clcs);

    function ICO(
        uint256 _icoSince,
        uint256 _icoTill,
        uint8 _decimals,
        uint256 price1,
        uint256 price2,
        uint256 price3,
        Clout _clout,
        CLC _clc,
        uint256 _minEthToContribute,
        bool _locked
    )
        public
        Multivest(msg.sender)
    {
        icoSince = _icoSince;
        icoTill = _icoTill;
        decimals = _decimals;
        locked = _locked;

        clout = _clout;
        clc = _clc;

        if (_minEthToContribute > 0) {
            minEthToContribute = _minEthToContribute;
        } else {
            minEthToContribute = 0;
        }

        phases.push(Phase(price1, 5000000 * (uint256(10) ** decimals)));
        phases.push(Phase(price2, 3000000 * (uint256(10) ** decimals)));
        phases.push(Phase(price3, 2000000 * (uint256(10) ** decimals)));
    }

    function () payable {
        bool status = buy(msg.sender, block.timestamp, msg.value);

        require(status == true);
    }

    function setEtherReceivers(
        address _masterWallet,
        address[] _etherReceivers
    )
        public onlyOwner
    {
        require(_masterWallet != address(0));
        require(_etherReceivers.length == 4);
        require(_etherReceivers[0] != address(0));
        require(_etherReceivers[1] != address(0));
        require(_etherReceivers[2] != address(0));
        require(_etherReceivers[3] != address(0));

        etherMasterWallet = _masterWallet;
        etherReceivers = _etherReceivers;
    }

    function setPrice(uint256 price1, uint256 price2, uint256 price3) public onlyOwner {
        phases[0].price = price1;
        phases[1].price = price2;
        phases[2].price = price3;
    }

    function setPeriod(uint256 since, uint256 till) public onlyOwner {
        icoSince = since;
        icoTill = till;
    }

    function setClout(Clout _clout) public onlyOwner {
        clout = _clout;
    }

    function setCLC(CLC _clc) public onlyOwner {
        clc = _clc;
    }

    function setLocked(bool _locked) public onlyOwner {
        locked = _locked;
    }

    function getIcoTokensAmount(uint256 _soldTokens, uint256 _value) public constant returns (uint256) {
        uint256 amount;

        uint256 newSoldTokens = _soldTokens;
        uint256 remainingValue = _value;
    
        for (uint i = 0; i < phases.length; i++) {
            Phase storage phase = phases[i];

            uint256 tokens = remainingValue * (uint256(10) ** decimals) / phase.price;

            if (phase.maxAmount > newSoldTokens) {
                if (newSoldTokens + tokens > phase.maxAmount) {
                    uint256 diff = phase.maxAmount - tokens;

                    amount += diff;

                    // get optimal amount of ethers for this phase
                    uint256 phaseEthers = diff * phase.price / (uint256(10) ** decimals);

                    remainingValue -= phaseEthers;
                    newSoldTokens += (phaseEthers * (uint256(10) ** decimals) / phase.price);
                } else {
                    amount += tokens;

                    newSoldTokens += tokens;

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

    // solhint-disable-next-line code-complexity
    function transferEthers() public onlyOwner {
        require(this.balance > 0);
        require(etherReceivers.length == 4);
        require(etherMasterWallet != address(0));

        // ether balance on smart contract
        if (this.balance > 0) {
            uint256 balance = this.balance;

            etherReceivers[0].transfer(balance * 15 / 100);

            etherReceivers[1].transfer(balance * 15 / 100);

            etherReceivers[2].transfer(balance * 10 / 100);

            etherReceivers[3].transfer(balance * 10 / 100);

            // send rest to master wallet

            etherMasterWallet.transfer(this.balance);
        }
    }

    function buy(address _address, uint256 _time, uint256 _value) internal returns (bool) {
        if (locked == true) {
            return false;
        }

        if (_time < icoSince) {
            return false;
        }

        if (_time > icoTill) {
            return false;
        }

        if (_value < minEthToContribute || _value == 0) {
            return false;
        }

        uint256 amount = getIcoTokensAmount(soldTokens, _value);

        if (amount == 0) {
            return false;
        }

        uint256 cloutMinted = clout.mint(_address, amount);
        uint256 clcMinted = clc.mint(_address, amount);

        require(cloutMinted == amount);
        require(clcMinted == amount);

        soldTokens += amount;
        collectedEthers += _value;
        holderEthers[_address] += _value;

        Contribution(_address, _value, amount, amount);

        return true;
    }
}