pragma solidity ^0.4.13;

contract Ownable {

    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address newOwner;
    function transferOwnership(address _newOwner) onlyOwner {
        if (_newOwner != address(0)) {
            newOwner = _newOwner;
        }
    }
    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract ERC20 is Ownable {
    /* Public variables of the token */
    string public standard;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    bool public locked;
    uint256 public creationBlock;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ERC20(
    uint256 _initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol,
    bool transferAllSupplyToOwner,
    bool _locked
    ) {
        standard = 'ERC20 0.1';

        initialSupply = _initialSupply;

        if (transferAllSupplyToOwner) {
            setBalance(msg.sender, initialSupply);
        }
        else {
            setBalance(this, initialSupply);
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

    /* internal balances */

    function setBalance(address holder, uint256 amount) internal {
        balances[holder] = amount;
    }

    function transferInternal(address _from, address _to, uint256 value) internal returns (bool success) {
        if (value == 0) {
            return true;
        }

        if (balances[_from] < value) {
            return false;
        }

        if (balances[_to] + value <= balances[_to]) {
            return false;
        }

        setBalance(_from, balances[_from] - value);
        setBalance(_to, balances[_to] + value);

        Transfer(_from, _to, value);

        return true;
    }

    /* public methods */
    function totalSupply() public returns (uint256) {
        return initialSupply;
    }

    function balanceOf(address _address) public returns (uint256) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        require(locked == false);

        bool status = transferInternal(msg.sender, _to, _value);

        require(status == true);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if(locked) {
            return false;
        }

        allowance[msg.sender][_spender] = _value;

        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        if (locked) {
            return false;
        }

        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
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

}

contract MintingERC20 is ERC20 {

    mapping (address => bool) public minters;

    uint256 public maxSupply;

    function MintingERC20(
    uint256 _initialSupply,
    uint256 _maxSupply,
    string _tokenName,
    uint8 _decimals,
    string _symbol,
    bool _transferAllSupplyToOwner,
    bool _locked
    )
    ERC20(_initialSupply, _tokenName, _decimals, _symbol, _transferAllSupplyToOwner, _locked)

    {
        standard = "MintingERC20 0.1";
        minters[msg.sender] = true;
        maxSupply = _maxSupply;
    }


    function addMinter(address _newMinter) onlyOwner {
        minters[_newMinter] = true;
    }


    function removeMinter(address _minter) onlyOwner {
        minters[_minter] = false;
    }


    function mint(address _addr, uint256 _amount) onlyMinters returns (uint256) {
        if (locked == true) {
            return uint256(0);
        }

        if (_amount == uint256(0)) {
            return uint256(0);
        }
        if (initialSupply + _amount <= initialSupply){
            return uint256(0);
        }
        if (initialSupply + _amount > maxSupply) {
            return uint256(0);
        }

        initialSupply += _amount;
        balances[_addr] += _amount;
        Transfer(this, _addr, _amount);
        return _amount;
    }


    modifier onlyMinters () {
        require(true == minters[msg.sender]);
        _;
    }
}

contract Lamden is MintingERC20 {


    uint8 public decimals = 18;

    string public tokenName = "Lamden Tau";

    string public tokenSymbol = "TAU";

    uint256 public  maxSupply = 500 * 10 ** 6 * uint(10) ** decimals; // 500,000,000

    // We block token transfers till ICO end.
    bool public transferFrozen = true;

    function Lamden(
    uint256 initialSupply,
    bool _locked
    ) MintingERC20(initialSupply, maxSupply, tokenName, decimals, tokenSymbol, false, _locked) {
        standard = 'Lamden 0.1';
    }

    function setLocked(bool _locked) onlyOwner {
        locked = _locked;
    }

    // Allow token transfer.
    function freezing(bool _transferFrozen) onlyOwner {
        transferFrozen = _transferFrozen;
    }

    // ERC20 functions
    // =========================

    function transfer(address _to, uint _value) returns (bool) {
        require(!transferFrozen);
        return super.transfer(_to, _value);

    }

    // should  not have approve/transferFrom
    function approve(address, uint) returns (bool success)  {
        require(false);
        return false;
        //        super.approve(_spender, _value);
    }

    function approveAndCall(address, uint256, bytes) returns (bool success) {
        require(false);
        return false;
    }

    function transferFrom(address, address, uint)  returns (bool success) {
        require(false);
        return false;
        //        super.transferFrom(_from, _to, _value);
    }
}