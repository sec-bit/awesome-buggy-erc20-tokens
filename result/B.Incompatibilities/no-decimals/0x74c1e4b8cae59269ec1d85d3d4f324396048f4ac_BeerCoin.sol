/**
 * Author: Nick Johnson (arachnid at notdot.net)
 * Copyright 2016; licensed CC-BY-SA.
 * 
 * BeerCoin is a new cryptocurrency intended to encapsulate and record the
 * concept of "I owe you a beer". Did someone answer a difficult question you
 * had? Send them a BeerCoin. Did they help you carry something heavy? Send
 * them a BeerCoin. Someone buy you a beer? Send them a BeerCoin.
 * 
 * Unlike traditional currency, anyone can issue BeerCoin simply by sending it
 * to someone else. A person's BeerCoin is only as valuable as the recipient's
 * belief that they're good for the beer, should it ever be redeemed; a beer
 * owed to you by Vitalik Buterin is probably worth more than a beer owed to you
 * by the DAO hacker (but your opinions may differ on that point).
 * 
 * BeerCoin is implemented as an ERC20 compatible token, with a few extensions.
 * Regular ERC20 transfers will create or resolve obligations between the two
 * parties; they will never transfer third-party BeerCoins. Additional methods
 * are provided to allow you transfer beers someone owes you to a third party;
 * if Satoshi Nakamoto owes you a beer, you can transfer that obligation to your
 * friend who just bought you one down at the pub. Methods are also provided for
 * determining the total number of beers a person owes, to help determine if
 * they're good for it, and for getting a list of accounts that owe someone a
 * beer.
 * 
 * BeerCoin may confuse some wallets, such as Mist, that expect you can only
 * send currency up to your current total balance; since BeerCoin operates as
 * individual IOUs, that restriction doesn't apply. As a result, you will
 * sometimes need to call the 'transfer' function on the contract itself
 * instead of using the wallet's built in token support.
 * 
 * If anyone finds a bug in the contract, I'll buy you a beer. If you find a bug
 * you can exploit to adjust balances without users' consent, I'll buy you two
 * (or more).
 * 
 * If you feel obliged to me for creating this, send me a ? at
 * 0x5fC8A61e097c118cE43D200b3c4dcf726Cf783a9. Don't do it unless you mean it;
 * if we meet I'll surely redeem it.
 */
contract BeerCoin {
    using Itmap for Itmap.AddressUintMap;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    struct UserAccount {
        bool exists;
        Itmap.AddressUintMap debtors; // People who owe you a beer
        mapping(address=>uint) allowances;
        uint maxCredit; // Most beers any individual may owe you
        uint beersOwed; // Beers owed by this person
        uint beersOwing; // Beers owed to this person
    }
    uint beersOwing;
    uint defaultMaxCredit;
    
    function() {
        throw;
    }
    
    function BeerCoin(uint _defaultMaxCredit) {
        defaultMaxCredit = _defaultMaxCredit;
    }
    
    mapping(address=>UserAccount) accounts;

    function maximumCredit(address owner) constant returns (uint) {
        if(accounts[owner].exists) {
            return accounts[owner].maxCredit;
        } else {
            return defaultMaxCredit;
        }
    }

    function setMaximumCredit(uint credit) {
        //640k ought to be enough for anyone
        if(credit > 655360)
            return;

        if(!accounts[msg.sender].exists)
            accounts[msg.sender].exists = true;
        accounts[msg.sender].maxCredit = credit;
    }
    
    function numDebtors(address owner) constant returns (uint) {
        return accounts[owner].debtors.size();
    }
    
    function debtor(address owner, uint idx) constant returns (address) {
        return accounts[owner].debtors.index(idx);
    }
    
    function debtors(address owner) constant returns (address[]) {
        return accounts[owner].debtors.keys;
    }

    function totalSupply() constant returns (uint256 supply) {
        return beersOwing;   
    }
    
    function balanceOf(address owner) constant returns (uint256 balance) {
        return accounts[owner].beersOwing;
    }
    
    function balanceOf(address owner, address debtor) constant returns (uint256 balance) {
        return accounts[owner].debtors.get(debtor);
    }
    
    function totalDebt(address owner) constant returns (uint256 balance) {
        return accounts[owner].beersOwed;
    }
    
    function transfer(address to, uint256 value) returns (bool success) {
        return doTransfer(msg.sender, to, value);
    }
    
    function transferFrom(address from, address to, uint256 value) returns (bool) {
        if(accounts[from].allowances[msg.sender] >= value && doTransfer(from, to, value)) {
            accounts[from].allowances[msg.sender] -= value;
            return true;
        }
        return false;
    }
    
    function doTransfer(address from, address to, uint value) internal returns (bool) {
        if(from == to)
            return false;
            
        if(!accounts[to].exists) {
            accounts[to].exists = true;
            accounts[to].maxCredit = defaultMaxCredit;
        }
        
        // Don't allow transfers that would exceed the recipient's credit limit.
        if(value > accounts[to].maxCredit + accounts[from].debtors.get(to))
            return false;
        
        Transfer(from, to, value);

        value -= reduceDebt(to, from, value);
        createDebt(from, to, value);

        return true;
    }
    
    // Transfers beers owed to you by `debtor` to `to`.
    function transferOther(address to, address debtor, uint value) returns (bool) {
        return doTransferOther(msg.sender, to, debtor, value);
    }

    // Allows a third party to transfer debt owed to you by `debtor` to `to`.    
    function transferOtherFrom(address from, address to, address debtor, uint value) returns (bool) {
        if(accounts[from].allowances[msg.sender] >= value && doTransferOther(from, to, debtor, value)) {
            accounts[from].allowances[msg.sender] -= value;
            return true;
        }
        return false;
    }
    
    function doTransferOther(address from, address to, address debtor, uint value) internal returns (bool) {
        if(from == to || to == debtor)
            return false;
            
        if(!accounts[to].exists) {
            accounts[to].exists = true;
            accounts[to].maxCredit = defaultMaxCredit;
        }
        
        if(transferDebt(from, to, debtor, value)) {
            Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    // Creates debt owed by `debtor` to `creditor` of amount `value`.
    // Returns false without making changes if this would exceed `creditor`'s
    // credit limit.
    function createDebt(address debtor, address creditor, uint value) internal returns (bool) {
        if(value == 0)
            return true;
        
        if(value > accounts[creditor].maxCredit)
            return false;

        accounts[creditor].debtors.set(
            debtor, accounts[creditor].debtors.get(debtor) + value);
        accounts[debtor].beersOwed += value;
        accounts[creditor].beersOwing += value;
        beersOwing += value;
        
        return true;
    }
    
    // Reduces debt owed by `debtor` to `creditor` by `value` or the total amount,
    // whichever is less. Returns the amount of debt erased.
    function reduceDebt(address debtor, address creditor, uint value) internal returns (uint) {
        var owed = accounts[creditor].debtors.get(debtor);
        if(value >= owed) {
            value = owed;
            
            accounts[creditor].debtors.remove(debtor);
        } else {
            accounts[creditor].debtors.set(debtor, owed - value);
        }
        
        accounts[debtor].beersOwed -= value;
        accounts[creditor].beersOwing -= value;
        beersOwing -= value;
        
        return value;
    }
    
    // Transfers debt owed by `debtor` from `oldCreditor` to `newCreditor`.
    // Returns false without making any changes if `value` exceeds the amount
    // owed or if the transfer would exceed `newCreditor`'s credit limit.
    function transferDebt(address oldCreditor, address newCreditor, address debtor, uint value) internal returns (bool) {
        var owedOld = accounts[oldCreditor].debtors.get(debtor);
        if(owedOld < value)
            return false;
        
        var owedNew = accounts[newCreditor].debtors.get(debtor);
        if(value + owedNew > accounts[newCreditor].maxCredit)
            return false;
        
        
        if(owedOld == value) {
            accounts[oldCreditor].debtors.remove(debtor);
        } else {
            accounts[oldCreditor].debtors.set(debtor, owedOld - value);
        }
        accounts[oldCreditor].beersOwing -= value;
        
        accounts[newCreditor].debtors.set(debtor, owedNew + value);
        accounts[newCreditor].beersOwing += value;
        
        return true;
    }

    function approve(address spender, uint256 value) returns (bool) {
        accounts[msg.sender].allowances[spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) constant returns (uint256) {
        return accounts[owner].allowances[spender];
    }
}


library Itmap {
    struct AddressUintMapEntry {
        uint value;
        uint idx;
    }
    
    struct AddressUintMap {
        mapping(address=>AddressUintMapEntry) entries;
        address[] keys;
    }
    
    function set(AddressUintMap storage self, address k, uint v) internal {
        var entry = self.entries[k];
        if(entry.idx == 0) {
            entry.idx = self.keys.length + 1;
            self.keys.push(k);
        }
        entry.value = v;
    }
    
    function get(AddressUintMap storage self, address k) internal returns (uint) {
        return self.entries[k].value;
    }
    
    function contains(AddressUintMap storage self, address k) internal returns (bool) {
        return self.entries[k].idx > 0;
    }
    
    function remove(AddressUintMap storage self, address k) internal {
        var entry = self.entries[k];
        if(entry.idx > 0) {
            var otherkey = self.keys[self.keys.length - 1];
            self.keys[entry.idx - 1] = otherkey;
            self.keys.length -= 1;
            
            self.entries[otherkey].idx = entry.idx;
            entry.idx = 0;
            entry.value = 0;
        }
    }
    
    function size(AddressUintMap storage self) internal returns (uint) {
        return self.keys.length;
    }
    
    function index(AddressUintMap storage self, uint idx) internal returns (address) {
        return self.keys[idx];
    }
}