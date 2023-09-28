pragma solidity ^0.4.8;


/**
 * @title ERC20
 */
contract ERC20 {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
 * @title MainstreetToken
 */
contract MainstreetToken is ERC20 {
    
    mapping (address => uint) ownerMIT;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalMIT;
    uint public start;
    
    address public mainstreetCrowdfund;

    address public intellisys;
    
    bool public testing;

    modifier fromCrowdfund() {
        if (msg.sender != mainstreetCrowdfund) {
            throw;
        }
        _;
    }
    
    modifier isActive() {
        if (block.timestamp < start) {
            throw;
        }
        _;
    }

    modifier isNotActive() {
        if (!testing && block.timestamp >= start) {
            throw;
        }
        _;
    }

    modifier recipientIsValid(address recipient) {
        if (recipient == 0 || recipient == address(this)) {
            throw;
        }
        _;
    }

    modifier senderHasSufficient(uint MIT) {
        if (ownerMIT[msg.sender] < MIT) {
            throw;
        }
        _;
    }

    modifier transferApproved(address from, uint MIT) {
        if (allowed[from][msg.sender] < MIT || ownerMIT[from] < MIT) {
            throw;
        }
        _;
    }

    modifier allowanceIsZero(address spender, uint value) {
        // To change the approve amount you first have to reduce the addresses´
        // allowance to zero by calling `approve(_spender,0)` if it is not
        // already 0 to mitigate the race condition described here:
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((value != 0) && (allowed[msg.sender][spender] != 0)) {
            throw;
        }
        _;
    }

    /**
     * @dev Tokens have been added to an address by the crowdfunding contract.
     * @param recipient Address receiving the MIT.
     * @param MIT Amount of MIT added.
     */
    event TokensAdded(address indexed recipient, uint MIT);

    /**
     * @dev Constructor.
     * @param _mainstreetCrowdfund Address of crowdfund contract.
     * @param _intellisys Address to receive intellisys' tokens.
     * @param _start Timestamp when the token becomes active.
     */
    function MainstreetToken(address _mainstreetCrowdfund, address _intellisys, uint _start, bool _testing) {
        mainstreetCrowdfund = _mainstreetCrowdfund;
        intellisys = _intellisys;
        start = _start;
        testing = _testing;
    }
    
    /**
     * @dev Add to token balance on address. Must be from crowdfund.
     * @param recipient Address to add tokens to.
     * @return MIT Amount of MIT to add.
     */
    function addTokens(address recipient, uint MIT) external isNotActive fromCrowdfund {
        ownerMIT[recipient] += MIT;
        uint intellisysMIT = MIT / 10;
        ownerMIT[intellisys] += intellisysMIT;
        totalMIT += MIT + intellisysMIT;
        TokensAdded(recipient, MIT);
        TokensAdded(intellisys, intellisysMIT);
    }

    /**
     * @dev Implements ERC20 totalSupply()
     */
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = totalMIT;
    }

    /**
     * @dev Implements ERC20 balanceOf()
     */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        balance = ownerMIT[_owner];
    }

    /**
     * @dev Implements ERC20 transfer()
     */
    function transfer(address _to, uint256 _value) isActive recipientIsValid(_to) senderHasSufficient(_value) returns (bool success) {
        ownerMIT[msg.sender] -= _value;
        ownerMIT[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Implements ERC20 transferFrom()
     */
    function transferFrom(address _from, address _to, uint256 _value) isActive recipientIsValid(_to) transferApproved(_from, _value) returns (bool success) {
        ownerMIT[_to] += _value;
        ownerMIT[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Implements ERC20 approve()
     */
    function approve(address _spender, uint256 _value) isActive allowanceIsZero(_spender, _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Implements ERC20 allowance()
     */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
    }

}


/**
 * @title MainstreetCrowdfund
 */
contract MainstreetCrowdfund {
    
    uint public start;
    uint public end;

    mapping (address => uint) public senderETH;
    mapping (address => uint) public senderMIT;
    mapping (address => uint) public recipientETH;
    mapping (address => uint) public recipientMIT;
    mapping (address => uint) public recipientExtraMIT;

    uint public totalETH;
    uint public limitETH;

    uint public bonus1StartETH;
    uint public bonus2StartETH;

    mapping (address => bool) public whitelistedAddresses;
    
    address public exitAddress;
    address public creator;

    MainstreetToken public mainstreetToken;

    event MITPurchase(address indexed sender, address indexed recipient, uint ETH, uint MIT);

    modifier saleActive() {
        if (address(mainstreetToken) == 0) {
            throw;
        }
        if (block.timestamp < start || block.timestamp >= end) {
            throw;
        }
        if (totalETH + msg.value > limitETH) {
            throw;
        }
        _;
    }

    modifier hasValue() {
        if (msg.value == 0) {
            throw;
        }
        _;
    }
    
    modifier senderIsWhitelisted() {
        if (whitelistedAddresses[msg.sender] != true) {
            throw;
        }
        _;
    }

    modifier recipientIsValid(address recipient) {
        if (recipient == 0 || recipient == address(this)) {
            throw;
        }
        _;
    }

    modifier isCreator() {
        if (msg.sender != creator) {
            throw;
        }
        _;
    }

    modifier tokenContractNotSet() {
        if (address(mainstreetToken) != 0) {
            throw;
        }
        _;
    }

    /**
     * @dev Constructor.
     * @param _start Timestamp of when the crowdsale will start.
     * @param _end Timestamp of when the crowdsale will end.
     * @param _limitETH Maximum amount of ETH that can be sent to the contract in total. Denominated in wei.
     * @param _bonus1StartETH Amount of Ether (denominated in wei) that is required to qualify for the first bonus.
     * @param _bonus1StartETH Amount of Ether (denominated in wei) that is required to qualify for the second bonus.
     * @param _exitAddress Address that all ETH should be forwarded to.
     * @param whitelist1 First address that can send ETH.
     * @param whitelist2 Second address that can send ETH.
     * @param whitelist3 Third address that can send ETH.
     */
    function MainstreetCrowdfund(uint _start, uint _end, uint _limitETH, uint _bonus1StartETH, uint _bonus2StartETH, address _exitAddress, address whitelist1, address whitelist2, address whitelist3) {
        creator = msg.sender;
        start = _start;
        end = _end;
        limitETH = _limitETH;
        bonus1StartETH = _bonus1StartETH;
        bonus2StartETH = _bonus2StartETH;

        whitelistedAddresses[whitelist1] = true;
        whitelistedAddresses[whitelist2] = true;
        whitelistedAddresses[whitelist3] = true;
        exitAddress = _exitAddress;
    }
    
    /**
     * @dev Set the address of the token contract. Must be called by creator of this. Can only be set once.
     * @param _mainstreetToken Address of the token contract.
     */
    function setTokenContract(MainstreetToken _mainstreetToken) external isCreator tokenContractNotSet {
        mainstreetToken = _mainstreetToken;
    }

    /**
     * @dev Forward Ether to the exit address. Store all ETH and MIT information in public state and logs.
     * @param recipient Address that tokens should be attributed to.
     * @return MIT Amount of MIT purchased. This does not include the per-recipient quantity bonus.
     */
    function purchaseMIT(address recipient) external senderIsWhitelisted payable saleActive hasValue recipientIsValid(recipient) returns (uint increaseMIT) {
        
        // Attempt to send the ETH to the exit address.
        if (!exitAddress.send(msg.value)) {
            throw;
        }
        
        // Update ETH amounts.
        senderETH[msg.sender] += msg.value;
        recipientETH[recipient] += msg.value;
        totalETH += msg.value;

        // Calculate MIT purchased directly in this transaction.
        uint MIT = msg.value * 10;   // $1 / MIT based on $10 / ETH value

        // Calculate time-based bonus.
        if (block.timestamp - start < 1 weeks) {
            MIT += MIT / 10;    // 10% bonus
        }
        else if (block.timestamp - start < 5 weeks) {
            MIT += MIT / 20;    // 5% bonus
        }

        // Record directly-purchased MIT.
        senderMIT[msg.sender] += MIT;
        recipientMIT[recipient] += MIT;

        // Store previous value-based bonus for this address.
        uint oldExtra = recipientExtraMIT[recipient];

        // Calculate new value-based bonus.
        if (recipientETH[recipient] >= bonus2StartETH) {
            recipientExtraMIT[recipient] = (recipientMIT[recipient] * 8) / 100;      // 8% bonus
        }
        else if (recipientETH[recipient] >= bonus1StartETH) {
            recipientExtraMIT[recipient] = (recipientMIT[recipient] * 4) / 100;      // 4% bonus
        }

        // Calculate MIT increase for this address from this transaction.
        increaseMIT = MIT + (recipientExtraMIT[recipient] - oldExtra);

        // Tell the token contract about the increase.
        mainstreetToken.addTokens(recipient, increaseMIT);

        // Log this purchase.
        MITPurchase(msg.sender, recipient, msg.value, increaseMIT);
    }

}