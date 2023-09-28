pragma solidity ^ 0.4.16;


contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

   
}
contract tokenRecipient {
    function  receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ERC20 is Ownable{
    /* Public variables of the token */
    string public standard = 'CREDITS';
    string public name = 'CREDITS';
    string public symbol = 'CS';
    uint8 public decimals = 6;
    uint256 public totalSupply = 1000000000000000;
    bool public IsFrozen=false;
    address public ICOAddress;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
 modifier IsNotFrozen{
      require(!IsFrozen||msg.sender==owner
      ||msg.sender==0x0a6d9df476577C0D4A24EB50220fad007e444db8
      ||msg.sender==ICOAddress);
      _;
  }
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ERC20() public {
        balanceOf[msg.sender] = totalSupply;
    }
    function setICOAddress(address _address) public onlyOwner{
        ICOAddress=_address;
    }
    
   function setIsFrozen(bool _IsFrozen)public onlyOwner{
      IsFrozen=_IsFrozen;
    }
    /* Send coins */
    function transfer(address _to, uint256 _value) public IsNotFrozen {
        require(balanceOf[msg.sender] >= _value); // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient
        Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
    }
  
 
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)public
    returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        tokenRecipient spender = tokenRecipient(_spender);
        return true;
    }

    /* Approve and then comunicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public
    returns(bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value)public IsNotFrozen returns(bool success)  {
        require (balanceOf[_from] >= _value) ; // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]) ; // Check for overflows
        require (_value <= allowance[_from][msg.sender]) ; // Check allowance
      
        balanceOf[_from] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
 /* @param _value the amount of money to burn*/
    event Burn(address indexed from, uint256 value);
    function burn(uint256 _value) public onlyOwner  returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
     // Optional token name

    
    
    function setName(string name_) public onlyOwner {
        name = name_;
    }
    /* This unnamed function is called whenever someone tries to send ether to it */
    function () public {
     require(1==2) ; // Prevents accidental sending of ether
    }
}