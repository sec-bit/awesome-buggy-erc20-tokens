pragma solidity ^0.4.16;

contract WEAToken {
    using SetLibrary for SetLibrary.Set;

    string public name;
    string public symbol;
    uint8 public decimals = 0;

    uint256 public totalSupply;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    SetLibrary.Set private allOwners;
    function amountOfOwners() public view returns (uint256)
    {
        return allOwners.size();
    }
    function ownerAtIndex(uint256 _index) public view returns (address)
    {
        return address(allOwners.values[_index]);
    }
    function getAllOwners() public view returns (uint256[])
    {
        return allOwners.values;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    function WEAToken() public {
        totalSupply = 18000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        Transfer(0x0, msg.sender, totalSupply);
        allOwners.add(msg.sender);
        name = "Weaste Coin";
        symbol = "WEA";
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        
        // Update the owner tracking
        if (balanceOf[_from] == 0)
        {
            allOwners.remove(_from);
        }
        if (_value > 0)
        {
            allOwners.add(_to);
        }
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        Burn(msg.sender, _value);
        return true;
    }
     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balanceOf[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        Burn(_from, _value);
        return true;
    }
}

/*
 * Written by Jesse Busman (info@jesbus.com) on 2017-11-30.
 * This software is provided as-is without warranty of any kind, express or implied.
 * This software is provided without any limitation to use, copy modify or distribute.
 * The user takes sole and complete responsibility for the consequences of this software's use.
 * Github repository: https://github.com/JesseBusman/SoliditySet
 * Please note that this container does not preserve the order of its contents!
 */

pragma solidity ^0.4.18;

library SetLibrary
{
    struct ArrayIndexAndExistsFlag
    {
        uint256 index;
        bool exists;
    }
    struct Set
    {
        mapping(uint256 => ArrayIndexAndExistsFlag) valuesMapping;
        uint256[] values;
    }
    function add(Set storage self, uint256 value) public returns (bool added)
    {
        // If the value is already in the set, we don't need to do anything
        if (self.valuesMapping[value].exists == true) return false;
        
        // Remember that the value is in the set, and remember the value's array index
        self.valuesMapping[value] = ArrayIndexAndExistsFlag({index: self.values.length, exists: true});
        
        // Add the value to the array of unique values
        self.values.push(value);
        
        return true;
    }
    function contains(Set storage self, uint256 value) public view returns (bool contained)
    {
        return self.valuesMapping[value].exists;
    }
    function remove(Set storage self, uint256 value) public returns (bool removed)
    {
        // If the value is not in the set, we don't need to do anything
        if (self.valuesMapping[value].exists == false) return false;
        
        // Remember that the value is not in the set
        self.valuesMapping[value].exists = false;
        
        // Now we need to remove the value from the array. To prevent leaking
        // storage space, we move the last value in the array into the spot that
        // contains the element we're removing.
        if (self.valuesMapping[value].index < self.values.length-1)
        {
            uint256 valueToMove = self.values[self.values.length-1];
            uint256 indexToMoveItTo = self.valuesMapping[value].index;
            self.values[indexToMoveItTo] = valueToMove;
            self.valuesMapping[valueToMove].index = indexToMoveItTo;
        }
        
        // Now we remove the last element from the array, because we just duplicated it.
        // We don't free the storage allocation of the removed last element,
        // because it will most likely be used again by a call to add().
        // De-allocating and re-allocating storage space costs more gas than
        // just keeping it allocated and unused.
        
        // Uncomment this line to save gas if your use case does not call add() after remove():
        // delete self.values[self.values.length-1];
        self.values.length--;
        
        // We do free the storage allocation in the mapping, because it is
        // less likely that the exact same value will added again.
        delete self.valuesMapping[value];
        
        return true;
    }
    function size(Set storage self) public view returns (uint256 amountOfValues)
    {
        return self.values.length;
    }
    
    // Also accept address and bytes32 types, so the user doesn't have to cast.
    function add(Set storage self, address value) public returns (bool added) { return add(self, uint256(value)); }
    function add(Set storage self, bytes32 value) public returns (bool added) { return add(self, uint256(value)); }
    function contains(Set storage self, address value) public view returns (bool contained) { return contains(self, uint256(value)); }
    function contains(Set storage self, bytes32 value) public view returns (bool contained) { return contains(self, uint256(value)); }
    function remove(Set storage self, address value) public returns (bool removed) { return remove(self, uint256(value)); }
    function remove(Set storage self, bytes32 value) public returns (bool removed) { return remove(self, uint256(value)); }
}