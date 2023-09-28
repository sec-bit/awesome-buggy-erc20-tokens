pragma solidity ^ 0.4.15;


/**
*contract name : tokenRecipient
*/
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }


/**
*contract name : GodzStartupBasicInformation
*purpose : be the smart contract for the erc20 tokenof the startup
*goal : to achieve to be the smart contract that the startup use for his stokcs
*/
contract GodzStartupBasicInformation {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 public amount;
    uint256 public reward; /*reward offered for the voters*/
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function GodzStartupBasicInformation(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        uint256 _amount,
        uint256 _reward, /*reward offered for the voters*/
        address _GodzSwapTokens /*address of the smart contract token swap*/
    ) {
        owner = tx.origin; /*becasuse the contract creation is controlled by the smart contract controller we use tx.origin*/
        balanceOf[owner] = initialSupply;

        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;

        amount = _amount; /*amount of the erc20 token*/
        reward = _reward; /*reward offered for the voters*/

        allowance[owner][_GodzSwapTokens] = initialSupply; /*here will allow the tokens transfer to the smart contract swap token*/
    }

     /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) revert();                               /* Prevent transfer to 0x0 address. Use burn() instead*/
        if (balanceOf[msg.sender] < _value) revert();           /* Check if the sender has enough*/
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); /* Check for overflows*/
        balanceOf[msg.sender] -= _value;                        /* Subtract from the sender*/
        balanceOf[_to] += _value;                               /* Add the same to the recipient*/
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts to get the coins but transfer from the origin*/
    function transferFromOrigin(address _to, uint256 _value)  returns (bool success) {
        address origin = tx.origin;
        if (origin == 0x0) revert();
        if (_to == 0x0) revert();                                /* Prevent transfer to 0x0 address.*/
        if (balanceOf[origin] < _value) revert();                /* Check if the sender has enough*/
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  /* Check for overflows*/
        balanceOf[origin] -= _value;                             /* Subtract from the sender*/
        balanceOf[_to] += _value;                                /* Add the same to the recipient*/
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert();                                /* Prevent transfer to 0x0 address.*/
        if (balanceOf[_from] < _value) revert();                 /* Check if the sender has enough*/
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  /* Check for overflows*/
        if (_value > allowance[_from][msg.sender]) revert();     /* Check allowance*/
        balanceOf[_from] -= _value;                              /* Subtract from the sender*/
        balanceOf[_to] += _value;                                /* Add the same to the recipient*/
        allowance[_from][msg.sender] -= _value;
        return true;
    }
}