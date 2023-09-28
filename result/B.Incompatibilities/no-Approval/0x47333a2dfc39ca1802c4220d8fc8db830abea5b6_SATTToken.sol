pragma solidity ^0.4.16;

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

interface ERC223 {
 
  function transfer(address to, uint256 value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public  returns (bool ok);
  
  
}


interface ERC223Receiver {
    function tokenFallback(address _from, uint _value, bytes _data) public ;
}

contract TokenERC20 {
    // Public variables of the token
    
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    string public symbol = "SATT";
    string public name = "Smart Advertisement Transaction Token";
    

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

   event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);


    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
                                      // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value,bytes _data) internal {
       
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
        Transfer(_from, _to, _value,_data);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
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
         bytes memory empty;
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value,empty);
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
        allowance[msg.sender][_spender] = _value;
        return true;
    }

   
    
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract SATTToken is owned, TokenERC20,ERC223 {

    uint256 public sellPrice = 0;
    uint256 public buyPrice = 1500;
    

    /* This generates a public event on the blockchain that will notify clients */
  
    event Buy(address a,uint256 v);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function SATTToken() TokenERC20(420000000) public {    }
    
     function isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }
    
     function transfer(address to, uint256 value) public returns (bool success) {
          bytes memory empty;
        _transfer(msg.sender, to, value,empty);
        return true;
    }
    
     function transfer(address to, uint256 value,bytes data) public returns (bool success) {
        _transfer(msg.sender, to, value,data);
        return true;
    }
    
    function _transfer(address _from, address _to, uint _value,bytes _data) internal {
       
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
        
        if(isContract(_to))
        {
            ERC223Receiver receiver = ERC223Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        
        Transfer(_from, _to, _value,_data);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

   

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param givenAmount the amount of tokens it will receive
    function giveToken(address target, uint256 givenAmount) onlyOwner public {
         bytes memory empty;
         balanceOf[owner] -= givenAmount;
        balanceOf[target] += givenAmount;
        Transfer(owner, target, givenAmount,empty);


    }
    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
     function withdraw() onlyOwner public {
        owner.transfer(this.balance);
    }
    

     function() public payable  {
         require(buyPrice >0);
          bytes memory empty;
        // Buy(msg.sender, msg.value);
       // uint amount = msg.value * buyPrice; 
       // balanceOf[msg.sender] +=( msg.value * buyPrice);                         // Subtract from the sender
        //balanceOf[owner] -= -msg.value * buyPrice;// calculates the amount
        _transfer(owner, msg.sender, msg.value * buyPrice,empty);
       //owner.transfer(msg.value);
        
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        require(sellPrice >0);
         bytes memory empty;
        require(this.balance >= amount / sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, owner, amount,empty);              // makes the transfers
        //msg.sender.transfer(amount / sellPrice);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
    
    
}