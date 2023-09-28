pragma solidity ^0.4.18;

library itMaps {

    /* itMapAddressUint
         address =>  Uint
    */
    struct entryAddressUint {
    // Equal to the index of the key of this item in keys, plus 1.
    uint keyIndex;
    uint value;
    }

    struct itMapAddressUint {
    mapping(address => entryAddressUint) data;
    address[] keys;
    }

    function insert(itMapAddressUint storage self, address key, uint value) internal returns (bool replaced) {
        entryAddressUint storage e = self.data[key];
        e.value = value;
        if (e.keyIndex > 0) {
            return true;
        } else {
            e.keyIndex = ++self.keys.length;
            self.keys[e.keyIndex - 1] = key;
            return false;
        }
    }

    function remove(itMapAddressUint storage self, address key) internal returns (bool success) {
        entryAddressUint storage e = self.data[key];
        if (e.keyIndex == 0)
        return false;

        if (e.keyIndex <= self.keys.length) {
            // Move an existing element into the vacated key slot.
            self.data[self.keys[self.keys.length - 1]].keyIndex = e.keyIndex;
            self.keys[e.keyIndex - 1] = self.keys[self.keys.length - 1];
            self.keys.length -= 1;
            delete self.data[key];
            return true;
        }
    }

    function destroy(itMapAddressUint storage self) internal  {
        for (uint i; i<self.keys.length; i++) {
            delete self.data[ self.keys[i]];
        }
        delete self.keys;
        return ;
    }

    function contains(itMapAddressUint storage self, address key) internal constant returns (bool exists) {
        return self.data[key].keyIndex > 0;
    }

    function size(itMapAddressUint storage self) internal constant returns (uint) {
        return self.keys.length;
    }

    function get(itMapAddressUint storage self, address key) internal constant returns (uint) {
        return self.data[key].value;
    }

    function getKeyByIndex(itMapAddressUint storage self, uint idx) internal constant returns (address) {
        return self.keys[idx];
    }

    function getValueByIndex(itMapAddressUint storage self, uint idx) internal constant returns (uint) {
        return self.data[self.keys[idx]].value;
    }
}

contract ERC20 {
    function totalSupply() public constant returns (uint256 supply);
    function balanceOf(address who) public constant returns (uint value);
    function allowance(address owner, address spender) public constant returns (uint _allowance);

    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract IceRockMining is ERC20{
    using itMaps for itMaps.itMapAddressUint;


    uint256 initialSupply = 20000000;
    string public constant name = "ICE ROCK MINING";
    string public constant symbol = "ROCK2";
    uint currentUSDExchangeRate = 1340;
    uint bonus = 0;
    uint priceUSD = 1;
    address IceRockMiningAddress;

    itMaps.itMapAddressUint balances;


    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) approvedDividends;

    event Burned(address indexed from, uint amount);
    event DividendsTransfered(address to, uint amount);


    modifier onlyOwner {
        if (msg.sender == IceRockMiningAddress) {
            _;
        }
    }

    function totalSupply() public constant returns (uint256) {
        return initialSupply;
    }

    function balanceOf(address tokenHolder) public view returns (uint256 balance) {
        return balances.get(tokenHolder);
    }

    function allowance(address owner, address spender) public constant returns (uint256) {
        return allowed[owner][spender];
    }


    function transfer(address to, uint value) public returns (bool success) {
        if (balances.get(msg.sender) >= value && value > 0) {

            balances.insert(msg.sender, balances.get(msg.sender)-value);

            if (balances.contains(to)) {
                balances.insert(to, balances.get(to)+value);
            }
            else {
                balances.insert(to, value);
            }

            Transfer(msg.sender, to, value);

            return true;

        } else return false;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        if (balances.get(from) >= value && allowed[from][msg.sender] >= value && value > 0) {

            uint amountToInsert = value;

            if (balances.contains(to))
            amountToInsert = amountToInsert+balances.get(to);

            balances.insert(to, amountToInsert);
            balances.insert(from, balances.get(from) - value);
            allowed[from][msg.sender] = allowed[from][msg.sender] - value;
            Transfer(from, to, value);
            return true;
        } else
        return false;
    }

    function approve(address spender, uint value) public returns (bool success) {
        if ((value != 0) && (balances.get(msg.sender) >= value)){
            allowed[msg.sender][spender] = value;
            Approval(msg.sender, spender, value);
            return true;
        } else{
            return false;
        }
    }

    function IceRockMining() public {
        IceRockMiningAddress = msg.sender;
        balances.insert(IceRockMiningAddress, initialSupply);
    }

    function setCurrentExchangeRate (uint rate) public onlyOwner{
        currentUSDExchangeRate = rate;
    }

    function setBonus (uint value) public onlyOwner{
        bonus = value;
    }

    function send(address addr, uint amount) public onlyOwner {
        sendp(addr, amount);
    }

    function sendp(address addr, uint amount) internal {
        require(addr != IceRockMiningAddress);
        require(amount > 0);
        require (balances.get(IceRockMiningAddress)>=amount);


        if (balances.contains(addr)) {
            balances.insert(addr, balances.get(addr)+amount);
        }
        else {
            balances.insert(addr, amount);
        }

        balances.insert(IceRockMiningAddress, balances.get(IceRockMiningAddress)-amount);
        Transfer(IceRockMiningAddress, addr, amount);
    }

    function () public payable{
        uint amountInUSDollars = msg.value * currentUSDExchangeRate / 10**18;
        uint valueToPass = amountInUSDollars / priceUSD;
        valueToPass = (valueToPass * (100 + bonus))/100;

        if (balances.get(IceRockMiningAddress) >= valueToPass) {
            if (balances.contains(msg.sender)) {
                balances.insert(msg.sender, balances.get(msg.sender)+valueToPass);
            }
            else {
                balances.insert(msg.sender, valueToPass);
            }
            balances.insert(IceRockMiningAddress, balances.get(IceRockMiningAddress)-valueToPass);
            Transfer(IceRockMiningAddress, msg.sender, valueToPass);
        }
    }

    function approveDividends (uint totalDividendsAmount) public onlyOwner {
        uint256 dividendsPerToken = totalDividendsAmount*10**18 / initialSupply;
        for (uint256 i = 0; i<balances.size(); i += 1) {
            address tokenHolder = balances.getKeyByIndex(i);
            if (balances.get(tokenHolder)>0)
            approvedDividends[tokenHolder] = balances.get(tokenHolder)*dividendsPerToken;
        }
    }

    function burnUnsold() public onlyOwner returns (bool success) {
        uint burningAmount = balances.get(IceRockMiningAddress);
        initialSupply -= burningAmount;
        balances.insert(IceRockMiningAddress, 0);
        Burned(IceRockMiningAddress, burningAmount);
        return true;
    }

    function approvedDividendsOf(address tokenHolder) public view returns (uint256) {
        return approvedDividends[tokenHolder];
    }

    function transferAllDividends() public onlyOwner{
        for (uint256 i = 0; i< balances.size(); i += 1) {
            address tokenHolder = balances.getKeyByIndex(i);
            if (approvedDividends[tokenHolder] > 0)
            {
                tokenHolder.transfer(approvedDividends[tokenHolder]);
                DividendsTransfered (tokenHolder, approvedDividends[tokenHolder]);
                approvedDividends[tokenHolder] = 0;
            }
        }
    }

    function withdraw(uint amount) public onlyOwner{
        IceRockMiningAddress.transfer(amount);
    }
}