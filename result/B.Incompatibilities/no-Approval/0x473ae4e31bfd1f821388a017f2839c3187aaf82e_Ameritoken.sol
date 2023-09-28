/**
 *  ATMX Ameritoken contract, ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
*/

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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Ameritoken {
    string public constant name = 'Ameritoken';                                 // Public variables of the token
    string public constant symbol = 'ATMX';                                     
    uint256 public constant decimals = 0;                                       // 0 decimals 
    string public constant version = 'ATMX-1.1';                                // Public Version
                                                                                // Corrected glitch of sending double qty to receiver. 
                                                                                // Fix provided by https://ethereum.stackexchange.com/users/19510/smarx
                                              
    uint256 private constant totalTokens = 41000000;                            // Fourty One million coins, NO FORK
                                                                                // This creates an array with all balances
    mapping (address => uint256) public balanceOf;                              // (ERC20)
    mapping (address => mapping (address => uint256)) public allowance;         // (ERC20)

                                                                                // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);    
 
    function Ameritoken () public {
        balanceOf[msg.sender] = totalTokens;                                    // Give the creator (Ameritoken, LLC) all initial tokens.
    }

  // See ERC20
    function totalSupply() constant returns (uint256) {                         // Returns the Total of Ameritokens
        return totalTokens;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                                    // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] >= _value);                                    // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);                      // Check for overflows
        uint previousBalances = balanceOf[_from] + balanceOf[_to];              // Save this for an assertion in the future
        balanceOf[_from] -= _value;                                             // Subtract from the sender
        balanceOf[_to] += _value;                                               // Add the same to the recipient
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);          // Asserts are used to use static analysis to find bugs in your code. They should never fail
    }

   
    function transfer(address _to, uint256 _value) public returns (bool) {
        if (balanceOf[msg.sender] >= _value) {
            _transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    if (balanceOf[_from] >= _value && allowance[_from][msg.sender] >= _value) {
      balanceOf[_from] -= _value;
      allowance[_from][msg.sender] -= _value;
      balanceOf[_to] += _value;
      Transfer(_from, _to, _value);
      return true;
    }
    return false;
  }


    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}