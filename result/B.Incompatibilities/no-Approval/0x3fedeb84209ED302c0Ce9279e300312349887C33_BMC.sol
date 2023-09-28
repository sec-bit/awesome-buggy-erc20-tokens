pragma solidity ^0.4.18;
/**
 * This smart contract code is Copyright 2017 Bitmart. For more information see https://www.bitmart.com
 *
 * Licensed under the Apache License, version 2.0
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert() on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically revert()s when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/*
 * BMC
 *
 * Abstract contract that create Bitmart Token based on ERC20.
 *
 */
contract BMC {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);

    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* This notifies the owner transfer */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function BMC( uint256 initialSupply, uint8 decimalUnits) public {
        balanceOf[msg.sender] = initialSupply; // Give the creator all initial tokens
        totalSupply = initialSupply; // Update total supply
        name = "BitMartToken";   // Set the name for display purposes
        symbol = "BMC";    // Set the symbol for display purposes
        decimals = decimalUnits;  // Amount of decimals for display purposes
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
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
      require(newOwner != address(0));
      OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }

    /* Send Coins */
    function transfer(address _to, uint256 _value) public {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value );// Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);  // Add the same to the recipient
        Transfer(msg.sender, _to, _value);   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[_from] >= _value );// Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        require(_value <= allowance[_from][msg.sender]); // Check allowance

        balanceOf[_from] = balanceOf[_from].sub(_value);   // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);  // Add the same to the recipient
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public onlyOwner returns (bool) {
        require(balanceOf[msg.sender] >= _value);// Check if the sender has enough
        require(_value > 0);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        totalSupply = totalSupply.sub(_value); // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function freeze(uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);// Check if the sender has enough
        require(_value > 0);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); // Subtract from the sender
        freezeOf[msg.sender] = freezeOf[msg.sender].add(_value);  // Updates totalSupply
        Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) public returns (bool) {
        require(freezeOf[msg.sender] >= _value); // Check if the sender has enough
        require(_value > 0);

        freezeOf[msg.sender] = freezeOf[msg.sender].sub(_value); // Subtract from the sender
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
        Unfreeze(msg.sender, _value);
        return true;
    }

    // transfer contract balance to owner
    function withdrawEther(uint256 amount) public onlyOwner {
        owner.transfer(amount);
    }

    // can accept ether
    function() payable public {
    }
}