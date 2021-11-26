/*
This file is part of the NeuroDAO Contract.

The NeuroDAO Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The NeuroDAO Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the NeuroDAO Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <i.svirin@nordavind.ru>

IF YOU ARE ENJOYED IT DONATE TO 0x3Ad38D1060d1c350aF29685B2b8Ec3eDE527452B ! :)
*/


pragma solidity ^0.4.11;

contract owned {

    address public owner;
    address public candidate;

    function owned() public payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        require(_owner != 0);
        candidate = _owner;
    }
    
    function confirmOwner() public {
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract BaseNeuroDAO {
    struct SpecialTokenHolder {
        uint limit;
        bool isTeam;
    }
    mapping (address => SpecialTokenHolder) public specials;

    struct TokenHolder {
        uint balance;
        uint balanceBeforeUpdate;
        uint balanceUpdateTime;
    }
    mapping (address => TokenHolder) public holders;

    function freezedBalanceOf(address _who) constant public returns(uint);
}

contract ManualMigration is owned, ERC20, BaseNeuroDAO {

    uint    public freezedMoment;
    address public original;

    modifier enabled {
        require(original == 0);
        _;
    }
    
    function ManualMigration(address _original) payable public owned() {
        original = _original;
        totalSupply = ERC20(original).totalSupply();
        holders[this].balance = ERC20(original).balanceOf(original);
        holders[original].balance = totalSupply - holders[this].balance;
        Transfer(this, original, holders[original].balance);
    }

    function migrateManual(address _who) public onlyOwner {
        require(original != 0);
        require(holders[_who].balance == 0);
        bool isTeam;
        uint limit;
        uint balance = BaseNeuroDAO(original).freezedBalanceOf(_who);
        holders[_who].balance = balance;
        (limit, isTeam) = BaseNeuroDAO(original).specials(_who);
        specials[_who] = SpecialTokenHolder({limit: limit, isTeam: isTeam});
        holders[original].balance -= balance;
        Transfer(original, _who, balance);
    }
    
    function migrateManual2(address [] _who, uint count) public onlyOwner {
        for(uint i = 0; i < count; ++i) {
            migrateManual(_who[i]);
        }
    }
    
    function sealManualMigration(bool force) public onlyOwner {
        require(force || holders[original].balance == 0);
        delete original;
    }

    function beforeBalanceChanges(address _who) internal {
        if (holders[_who].balanceUpdateTime <= freezedMoment) {
            holders[_who].balanceUpdateTime = now;
            holders[_who].balanceBeforeUpdate = holders[_who].balance;
        }
    }
}

contract Token is ManualMigration {

    string  public standard    = 'Token 0.1';
    string  public name        = 'NeuroDAO 3.0';
    string  public symbol      = "NDAO";
    uint8   public decimals    = 0;

    uint    public startTime;

    mapping (address => mapping (address => uint256)) public allowed;

    event Burned(address indexed owner, uint256 value);

    function Token(address _original, uint _startTime)
        payable public ManualMigration(_original) {
        startTime = _startTime;    
    }

    function availableTokens(address _who) public constant returns (uint _avail) {
        _avail = holders[_who].balance;
        uint limit = specials[_who].limit;
        if (limit != 0) {
            uint blocked;
            uint periods = firstYearPeriods();
            if (specials[_who].isTeam) {
                if (periods != 0) {
                    blocked = limit * (500 - periods) / 500;
                } else {
                    periods = (now - startTime) / 1 years;
                    ++periods;
                    if (periods < 5) {
                        blocked = limit * (100 - periods * 20) / 100;
                    }
                }
            } else {
                if (periods != 0) {
                    blocked = limit * (100 - periods) / 100;
                }
            }
            if (_avail <= blocked) {
                _avail = 0;
            } else {
                _avail -= blocked;
            }
        }
    }
    
    function firstYearPeriods() internal constant returns (uint _periods) {
        _periods = 0;
        if (now < startTime + 1 years) {
            uint8[12] memory logic = [1, 2, 3, 4, 4, 4, 5, 6, 7, 8, 9, 10];
            _periods = logic[(now - startTime) / 28 days];
        }
    }

    function balanceOf(address _who) constant public returns (uint) {
        return holders[_who].balance;
    }

    function transfer(address _to, uint256 _value) public enabled {
        require(availableTokens(msg.sender) >= _value);
        require(holders[_to].balance + _value >= holders[_to].balance); // overflow
        beforeBalanceChanges(msg.sender);
        beforeBalanceChanges(_to);
        holders[msg.sender].balance -= _value;
        holders[_to].balance += _value;
        Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public enabled {
        require(availableTokens(_from) >= _value);
        require(holders[_to].balance + _value >= holders[_to].balance); // overflow
        require(allowed[_from][msg.sender] >= _value);
        beforeBalanceChanges(_from);
        beforeBalanceChanges(_to);
        holders[_from].balance -= _value;
        holders[_to].balance += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant
        returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function burn(uint256 _value) public enabled {
        require(holders[msg.sender].balance >= _value);
        beforeBalanceChanges(msg.sender);
        holders[msg.sender].balance -= _value;
        totalSupply -= _value;
        Burned(msg.sender, _value);
    }
}

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value) public;
}

contract TokenMigration is Token {
    
    address public migrationAgent;
    uint256 public totalMigrated;

    event Migrate(address indexed from, address indexed to, uint256 value);

    function TokenMigration(address _original, uint _startTime)
        payable public Token(_original, _startTime) {}

    // Migrate _value of tokens to the new token contract
    function migrate() external {
        require(migrationAgent != 0);
        uint value = holders[msg.sender].balance;
        require(value != 0);
        beforeBalanceChanges(msg.sender);
        beforeBalanceChanges(this);
        holders[msg.sender].balance -= value;
        holders[this].balance += value;
        totalMigrated += value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, value);
        Transfer(msg.sender, this, value);
        Migrate(msg.sender, migrationAgent, value);
    }

    function setMigrationAgent(address _agent) external onlyOwner enabled {
        require(migrationAgent == 0);
        migrationAgent = _agent;
    }
}

contract NeuroDAO is TokenMigration {

    function NeuroDAO(address _original, uint _startTime)
        payable public TokenMigration(_original, _startTime) {}
    
    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }
    
    function freezeTheMoment() public onlyOwner {
        freezedMoment = now;
    }

    /** Get balance of _who for freezed moment
     *  freezeTheMoment()
     */
    function freezedBalanceOf(address _who) constant public returns(uint) {
        if (holders[_who].balanceUpdateTime <= freezedMoment) {
            return holders[_who].balance;
        } else {
            return holders[_who].balanceBeforeUpdate;
        }
    }
    
    function killMe() public onlyOwner {
        require(totalSupply == 0);
        selfdestruct(owner);
    }

    function mintTokens(uint _tokens, address _who, bool _isTeam) enabled public onlyOwner {
        require(holders[this].balance > 0);
        require(holders[msg.sender].balance + _tokens > holders[msg.sender].balance); // overflow
        require(_tokens > 0);
        beforeBalanceChanges(_who);
        beforeBalanceChanges(this);
        if (holders[_who].balance == 0) {
            // set isTeam only once!
            specials[_who].isTeam = _isTeam;
        }
        holders[_who].balance += _tokens;
        specials[_who].limit += _tokens;
        holders[this].balance -= _tokens;
        Transfer(this, _who, _tokens);
    }
}