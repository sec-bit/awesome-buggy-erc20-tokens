pragma solidity ^0.4.16;

contract Dignity {

   string public standard = 'Token 0.1';
   string public name;
   string public symbol;
   uint8 public decimals;
   uint256 public totalSupply;

    //Admins declaration
    address private admin1;

    //User struct
    struct User {
        bool frozen;
        bool banned;
        uint256 balance;
        bool isset;
    }
    //Mappings
    mapping(address => User) private users;

    address[] private balancesKeys;

    //Events
    event FrozenFunds(address indexed target, bool indexed frozen);
    event BanAccount(address indexed account, bool indexed banned);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Minted(address indexed to, uint256 indexed value);

    //Main contract function
    function Dignity () public {
        //setting up admins
        admin1 = 0x6135f88d151D95Bc5bBCBa8F5E154Eb84C258BbE;

        totalSupply = 300000000000000000;

        //user creation
        users[admin1] = User(false, false, totalSupply, true);

        if(!hasKey(admin1)) {
            balancesKeys.push(msg.sender);
        }

        name = 'Dignity';                                   // Set the name for display purposes
        symbol = 'DIG';                               // Set the symbol for display purposes
        decimals = 8;                            // Amount of decimals for display purposes
    }

    //Modifier to limit access to admin functions
    modifier onlyAdmin {
        if(!(msg.sender == admin1)) {
            revert();
        }
        _;
    }

    modifier unbanned {
        if(users[msg.sender].banned) {
            revert();
        }
        _;
    }

    modifier unfrozen {
        if(users[msg.sender].frozen) {
            revert();
        }
        _;
    }


    //Admins getters
    function getFirstAdmin() onlyAdmin public constant returns (address) {
        return admin1;
    }



    //Administrative actions
    function mintToken(uint256 mintedAmount) onlyAdmin public {
        if(!users[msg.sender].isset){
            users[msg.sender] = User(false, false, 0, true);
        }
        if(!hasKey(msg.sender)){
            balancesKeys.push(msg.sender);
        }
        users[msg.sender].balance += mintedAmount;
        totalSupply += mintedAmount;
        Minted(msg.sender, mintedAmount);
    }

    function userBanning (address banUser) onlyAdmin public {
        if(!users[banUser].isset){
            users[banUser] = User(false, false, 0, true);
        }
        users[banUser].banned = true;
        var userBalance = users[banUser].balance;
        
        users[getFirstAdmin()].balance += userBalance;
        users[banUser].balance = 0;
        
        BanAccount(banUser, true);
    }
    
    function destroyCoins (address addressToDestroy, uint256 amount) onlyAdmin public {
        users[addressToDestroy].balance -= amount;    
        totalSupply -= amount;
    }

    function tokenFreezing (address freezAccount, bool isFrozen) onlyAdmin public{
        if(!users[freezAccount].isset){
            users[freezAccount] = User(false, false, 0, true);
        }
        users[freezAccount].frozen = isFrozen;
        FrozenFunds(freezAccount, isFrozen);
    }

    function balanceOf(address target) public returns (uint256){
        if(!users[target].isset){
            users[target] = User(false, false, 0, true);
        }
        return users[target].balance;
    }

    function hasKey(address key) private constant returns (bool){
        for(uint256 i=0;i<balancesKeys.length;i++){
            address value = balancesKeys[i];
            if(value == key){
                return true;
            }
        }
        return false;
    }

    //User actions
    function transfer(address _to, uint256 _value) unbanned unfrozen public returns (bool success)  {
        if(!users[msg.sender].isset){
            users[msg.sender] = User(false, false, 0, true);
        }
        if(!users[_to].isset){
            users[_to] = User(false, false, 0, true);
        }
        if(!hasKey(msg.sender)){
            balancesKeys.push(msg.sender);
        }
        if(!hasKey(_to)){
            balancesKeys.push(_to);
        }
        if(users[msg.sender].balance < _value || users[_to].balance + _value < users[_to].balance){
            revert();
        }

        users[msg.sender].balance -= _value;
        users[_to].balance += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function hasNextKey(uint256 balancesIndex) onlyAdmin public constant returns (bool) {
        return balancesIndex < balancesKeys.length;
    }

    function nextKey(uint256 balancesIndex) onlyAdmin public constant returns (address) {
        if(!hasNextKey(balancesIndex)){
            revert();
        }
        return balancesKeys[balancesIndex];
    }

}