pragma solidity ^0.4.19;

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {

    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) onlyOwner external {
        require(_newOwner != address(0));
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}

/**
 * @title Upgradable
 * @dev The contract can be deprecated and the owner can set - only once - another address to advertise
 * clients of the existence of another more recent contract.
 */
contract Upgradable is Ownable {

    address public newAddress;

    uint    public deprecatedSince;

    string  public version;
    string  public newVersion;
    string  public reason;

    event Deprecated(address newAddress, string newVersion, string reason);

    /**
     */
    function Upgradable(string _version) public {
        version = _version;
    }

    /**
     */
    function setDeprecated(address _newAddress, string _newVersion, string _reason) external onlyOwner returns (bool success) {
        require(!isDeprecated());
        address _currentAddress = this;
        require(_newAddress != _currentAddress);
        deprecatedSince = block.timestamp;
        newAddress = _newAddress;
        newVersion = _newVersion;
        reason = _reason;
        Deprecated(_newAddress, _newVersion, _reason);
        require(!Upgradable(_newAddress).isDeprecated());
        return true;
    }

    /**
     * @notice check if the contract is deprecated
     */
    function isDeprecated() public view returns (bool deprecated) {
        return (deprecatedSince != 0);
    }
}

contract TokenERC20 {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract Managed is Upgradable {

    function Managed (string _version) Upgradable (_version) internal { }

    /**
    *
    */    
    function redeemEthers(address _to, uint _amount) onlyOwner external returns (bool success) {
        _to.transfer(_amount);
        return true;
    }

    /**
     *
     */
    function redeemTokens(TokenERC20 _tokenAddress, address _to, uint _amount) onlyOwner external returns (bool success) {
        return _tokenAddress.transfer(_to, _amount);
    }

}


/**
 * @title Airdrop
 * @notice Generic contract for token airdrop, initially used for BTL token (0x2accaB9cb7a48c3E82286F0b2f8798D201F4eC3f)
 */
contract TokenGiveaway is Managed {
    
    address private tokenContract   = 0x2accaB9cb7a48c3E82286F0b2f8798D201F4eC3f;
    address private donor           = 0xeA03Ee7110FAFb324d4a931979eF4578bffB6a00;
    uint    private etherAmount     = 0.0005 ether;
    uint    private tokenAmount     = 500;
    uint    private decimals        = 10**18;
    
    mapping (address => mapping (address => bool)) private receivers;

    event Airdropped(address indexed tokenContract, address receiver, uint tokenReceived);

    function TokenGiveaway () Managed("1.0.0") public { }

    /**
     *
     */
    function transferBatch(address[] _addresses) onlyOwner external {
        uint length = _addresses.length;
        for (uint i = 0; i < length; i++) {
            if (isOpenFor(_addresses[i])) {
                transferTokens(_addresses[i], tokenAmount * decimals);
            }            
        }
    }

    /**
     */
    function transferTokens(address _receiver, uint _tokenAmount) private {
        receivers[tokenContract][_receiver] = TokenERC20(tokenContract).transferFrom(donor, _receiver, _tokenAmount);
    }
        

    /**
     *
     */
    function isOpen() public view returns (bool open) {
        return TokenERC20(tokenContract).allowance(donor, this) >= tokenAmount * decimals;
    }

    /**
     *
     */
    function isOpenFor(address _receiver) public view returns (bool open) {
        return !receivers[tokenContract][_receiver] && isOpen();
    }

    /**
     */
    function () external payable {
        require(msg.value >= etherAmount && isOpenFor(msg.sender));
        transferTokens(msg.sender, tokenAmount * decimals);     
    }

    function updateTokenContract(address _tokenContract) external onlyOwner { tokenContract = _tokenContract; }

    function updateDonor(address _donor) external onlyOwner { donor = _donor; }
    
    function updateEtherAmount(uint _etherAmount) external onlyOwner { etherAmount = _etherAmount; }
    
    function updateTokenAmount(uint _tokenAmount) external onlyOwner { tokenAmount = _tokenAmount; }
    
    function updateDecimals(uint _decimals) external onlyOwner { decimals = _decimals; }
    
    function updateEtherAndtokenAmount(uint _etherAmount, uint _tokenAmount) external onlyOwner {
        etherAmount = _etherAmount;
        tokenAmount = _tokenAmount;
    }

    function updateEtherAndtokenAmount(address _donor, uint _etherAmount, uint _tokenAmount) external onlyOwner {
        donor = _donor;
        etherAmount = _etherAmount;
        tokenAmount = _tokenAmount;
    }

    function updateParameters(address _tokenContract, address _donor, uint _etherAmount, uint _tokenAmount, uint _decimals) external onlyOwner {
        tokenContract = _tokenContract;
        donor = _donor;
        etherAmount = _etherAmount;
        tokenAmount = _tokenAmount;
        decimals = _decimals;
    }

}