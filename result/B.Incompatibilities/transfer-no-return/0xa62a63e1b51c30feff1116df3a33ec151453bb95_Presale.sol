pragma solidity ^0.4.16;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

interface token {
    function transfer(address receiver, uint amount) public;
}

contract TokenERC20 is token {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // Notifies clients about token transfers
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Notifies clients about spending approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
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
        require(_spender != 0x0);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
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




contract Presale is owned {
    address public operations;

    TokenERC20 public myToken;
    uint256 public distributionSupply;
    uint256 public priceOfToken;
    uint256 factor;
    uint public startBlock;
    uint public endBlock;

    uint256 defaultAuthorizedETH;
    mapping (address => uint256) public authorizedETH;

    uint256 public distributionRealized;
    mapping (address => uint256) public realizedETH;
    mapping (address => uint256) public realizedTokenBalance;

    /**
     * Constructor function
     *
     * Initializes the presale
     *
     */
    function Presale() public {
        operations = 0x249aAb680bAF7ed84e0ebE55cD078650A17162Ca;
        myToken = TokenERC20(0xeaAa3585ffDCc973a22929D09179dC06D517b84d);
        uint256 decimals = uint256(myToken.decimals());
        distributionSupply = 10 ** decimals * 600000;
        priceOfToken = 3980891719745222;
        startBlock = 4909000;
        endBlock   = 4966700;
        defaultAuthorizedETH = 8 ether;
        factor = 10 ** decimals * 3 / 2;
    }

    modifier onlyOperations {
        require(msg.sender == operations);
        _;
    }

    function transferOperationsFunction(address _operations) onlyOwner public {
        operations = _operations;
    }

    function authorizeAmount(address _account, uint32 _valueETH) onlyOperations public {
        authorizedETH[_account] = uint256(_valueETH) * 1 ether;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        if (msg.sender != owner)
        {
            require(startBlock <= block.number && block.number <= endBlock);

            uint256 senderAuthorizedETH = authorizedETH[msg.sender];
            uint256 effectiveAuthorizedETH = (senderAuthorizedETH > 0)? senderAuthorizedETH: defaultAuthorizedETH;
            require(msg.value + realizedETH[msg.sender] <= effectiveAuthorizedETH);

            uint256 amountETH = msg.value;
            uint256 amountToken = amountETH / priceOfToken * factor;
            distributionRealized += amountToken;
            realizedETH[msg.sender] += amountETH;
            require(distributionRealized <= distributionSupply);

            if (senderAuthorizedETH > 0)
            {
                myToken.transfer(msg.sender, amountToken);
            }
            else
            {
                realizedTokenBalance[msg.sender] += amountToken;
            }
        }
    }

    function transferBalance(address _account) onlyOperations public {
        uint256 amountToken = realizedTokenBalance[_account];
	if (amountToken > 0)
        {
            realizedTokenBalance[_account] = 0;
            myToken.transfer(_account, amountToken);
        }
    }

    function retrieveToken() onlyOwner public {
        myToken.transfer(owner, myToken.balanceOf(this));
    }

    function retrieveETH(uint256 _amount) onlyOwner public {
        owner.transfer(_amount);
    }

    function setBlocks(uint _startBlock, uint _endBlock) onlyOwner public {
        require (_endBlock > _startBlock);
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function setPrice(uint256 _priceOfToken) onlyOwner public {
        require (_priceOfToken > 0);
        priceOfToken = _priceOfToken;
    }
}