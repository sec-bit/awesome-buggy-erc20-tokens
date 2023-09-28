pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint32 _value, address _token, bytes _extraData) public; }

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // 實現所有權轉移
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}    
    contract x32323 is owned {
        function x32323(
            uint32 initialSupply,
            string tokenName,
            uint8 decimalUnits,
            string tokenSymbol,
            address centralMinter
        ) {
        if(centralMinter != 0 ) owner = centralMinter;
        }
        
        // Public variables of the token
        string public name;
        string public symbol;
        uint8 public decimals = 0;
        // 18 decimals is the strongly suggested default, avoid changing it
        uint32 public totalSupply;

        // This creates an array with all balances
        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

        // This generates a public event on the blockchain that will notify clients
        event Transfer(address indexed from, address indexed to, uint32 value);

        // This notifies clients about the amount burnt
        event Burn(address indexed from, uint32 value);



            /**
           * Constructor function
            *
            * Initializes contract with initial supply tokens to the creator of the contract
            */
        function TokenERC20(
            uint32 initialSupply,
            string tokenName,
            string tokenSymbol
        ) public {
            totalSupply =  23000000 ;  // Update total supply with the decimal amount
            balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
            name = "測試";                                   // Set the name for display purposes
            symbol = "測試";                               // Set the symbol for display purposes
        }

        /**
        * Internal transfer, only can be called by this contract
        */
    
        mapping (address => bool) public frozenAccount;
        event FrozenFunds(address target, bool frozen);

        function freezeAccount(address target, bool freeze) onlyOwner {
            frozenAccount[target] = freeze;
            FrozenFunds(target, freeze);
        }
    
        function _transfer(address _from, address _to, uint32 _value) internal {
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
            Transfer(_from, _to , _value);
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
        function transfer(address _to, uint32 _value) public {
            require(!frozenAccount[msg.sender]);
            _transfer(msg.sender, _to, _value);
        }

        /**
        * Transfer tokens from other address
        *
        * Send `_value` tokens to `_to` on behalf of `_from`
        *
        * @param _from The address of the sender
        * @param _to The address of the recipient
        * @param _value the amount to send
        */
        function transferFrom(address _from, address _to, uint32 _value) public returns (bool success) {
            require(_value <= allowance[_from][msg.sender]);     // Check allowance
            allowance[_from][msg.sender] -= _value;
            _transfer(_from, _to, _value);
            return true;
        }

        /**
        * Set allowance for other address
        *
        * Allows `_spender` to spend no more than `_value` tokens on your behalf
        *
        * @param _spender The address authorized to spend
        * @param _value the max amount they can spend
        */
        function approve(address _spender, uint32 _value) public
            returns (bool success) {
            allowance[msg.sender][_spender] = _value;
            return true;
        }

        /**
        * Set allowance for other address and notify
        *
        * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
        *
        * @param _spender The address authorized to spend
        * @param _value the max amount they can spend
        * @param _extraData some extra information to send to the approved contract
        */
        function approveAndCall(address _spender, uint32 _value, bytes _extraData)
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
        function burn(uint32 _value) public returns (bool success) {
            require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
            balanceOf[msg.sender] -= _value;            // Subtract from the sender
            totalSupply -= _value;                      // Updates totalSupply
            Burn(msg.sender,  _value);
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
        function burnFrom(address _from, uint32 _value) public returns (bool success) {
            require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
            require(_value <= allowance[_from][msg.sender]);    // Check allowance
            balanceOf[_from] -= _value;                         // Subtract from the targeted balance
            allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
            totalSupply -= _value;                              // Update totalSupply
            Burn(_from,  _value);
            return true;
        }
    }