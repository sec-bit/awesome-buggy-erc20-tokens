/*
This file is part of the BREMP Contract.

The BREMP Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The BREMP Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the BREMP Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <i.svirin@nordavind.ru>
IF YOU ARE ENJOYED IT DONATE TO 0x3Ad38D1060d1c350aF29685B2b8Ec3eDE527452B ! :)
*/


pragma solidity ^0.4.0;

contract NeuroDAO {
    function balanceOf(address who) constant returns (uint);
    function freezedBalanceOf(address _who) constant returns(uint);
}

contract owned {

    address public owner;
    address public newOwner;

    function owned() payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        require(_owner != 0);
        newOwner = _owner;
    }
    
    function confirmOwner() public {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}

contract Crowdsale is owned {

    uint constant totalTokens    = 25000000;
    uint constant neurodaoTokens = 1250000;
    uint constant totalLimitUSD  = 500000;
    
    uint                         public totalSupply;
    mapping (address => uint256) public balanceOf;
    address                      public neurodao;
    uint                         public etherPrice;

    mapping (address => bool)    public holders;
    mapping (uint => address)    public holdersIter;
    uint                         public numberOfHolders;
    
    uint                         public collectedUSD;
    address                      public presaleOwner;
    uint                         public collectedNDAO;
    
    mapping (address => bool)    public gotBonus;
    
    enum State {Disabled, Presale, Bonuses, Enabled}
    State                        public state;

    modifier enabledState {
        require(state == State.Enabled);
        _;
    }

    event NewState(State _state);
    event Transfer(address indexed from, address indexed to, uint value);

    function Crowdsale(address _neurodao, uint _etherPrice) payable owned() {
        neurodao = _neurodao;
        etherPrice = _etherPrice;
        totalSupply = totalTokens;
        balanceOf[owner] = neurodaoTokens;
        balanceOf[this] = totalSupply - balanceOf[owner];
        Transfer(this, owner, balanceOf[owner]);
    }

    function setEtherPrice(uint _etherPrice) public {
        require(presaleOwner == msg.sender || owner == msg.sender);
        etherPrice = _etherPrice;
    }

    function startPresale(address _presaleOwner) public onlyOwner {
        require(state == State.Disabled);
        presaleOwner = _presaleOwner;
        state = State.Presale;
        NewState(state);
    }
    
    function startBonuses() public onlyOwner {
        require(state == State.Presale);
        state = State.Bonuses;
        NewState(state);
    }
    
    function finishCrowdsale() public onlyOwner {
        require(state == State.Bonuses);
        state = State.Enabled;
        NewState(state);
    }

    function () payable {
        uint tokens;
        address tokensSource;
        if (state == State.Presale) {
            require(balanceOf[this] > 0);
            require(collectedUSD < totalLimitUSD);
            uint valueWei = msg.value;
            uint valueUSD = valueWei * etherPrice / 1 ether;
            if (collectedUSD + valueUSD > totalLimitUSD) {
                valueUSD = totalLimitUSD - collectedUSD;
                valueWei = valueUSD * 1 ether / etherPrice;
                require(msg.sender.call.gas(3000000).value(msg.value - valueWei)());
                collectedUSD = totalLimitUSD;
            } else {
                collectedUSD += valueUSD;
            }
            uint centsForToken;
            if (now <= 1506815999) {        // 30/09/2017 11:59pm (UTC)
                centsForToken = 50;
            } else if (now <= 1507247999) { // 05/10/2017 11:59pm (UTC)
                centsForToken = 50;
            } else if (now <= 1507766399) { // 11/10/2017 11:59pm (UTC)
                centsForToken = 65;
            } else {
                centsForToken = 70;
            }
            tokens = valueUSD * 100 / centsForToken;
            if (NeuroDAO(neurodao).balanceOf(msg.sender) >= 1000) {
                collectedNDAO += tokens;
            }
            tokensSource = this;
        } else if (state == State.Bonuses) {
            require(gotBonus[msg.sender] != true);
            gotBonus[msg.sender] = true;
            uint freezedBalance = NeuroDAO(neurodao).freezedBalanceOf(msg.sender);
            if (freezedBalance >= 1000) {
                tokens = (neurodaoTokens / 10) * freezedBalance / 21000000 + (9 * neurodaoTokens / 10) * balanceOf[msg.sender] / collectedNDAO;                
            }
            tokensSource = owner;
        }        
        require(tokens > 0);
        require(balanceOf[msg.sender] + tokens > balanceOf[msg.sender]);
        require(balanceOf[tokensSource] >= tokens);        
        if (holders[msg.sender] != true) {
            holders[msg.sender] = true;
            holdersIter[numberOfHolders++] = msg.sender;
        }
        balanceOf[msg.sender] += tokens;
        balanceOf[tokensSource] -= tokens;
        Transfer(tokensSource, msg.sender, tokens);
    }
}

contract Token is Crowdsale {
    
    string  public standard    = 'Token 0.1';
    string  public name        = 'BREMP';
    string  public symbol      = "BREMP";
    uint8   public decimals    = 0;

    mapping (address => mapping (address => uint)) public allowed;
    event Approval(address indexed owner, address indexed spender, uint value);

    // Fix for the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function Token(address _neurodao, uint _etherPrice)
        payable Crowdsale(_neurodao, _etherPrice) {}

    function transfer(address _to, uint256 _value)
        public enabledState onlyPayloadSize(2 * 32) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        if (holders[_to] != true) {
            holders[_to] = true;
            holdersIter[numberOfHolders++] = _to;
        }
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value)
        public enabledState onlyPayloadSize(3 * 32) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]); // overflow
        require(allowed[_from][msg.sender] >= _value);
        if (holders[_to] != true) {
            holders[_to] = true;
            holdersIter[numberOfHolders++] = _to;
        }
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public enabledState {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant enabledState
        returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

contract PresaleBREMP is Token {
    
    function PresaleBREMP(address _neurodao, uint _etherPrice)
        payable Token(_neurodao, _etherPrice) {}
    
    function withdraw() public {
        require(presaleOwner == msg.sender || owner == msg.sender);
        msg.sender.transfer(this.balance);
    }
    
    function killMe() public onlyOwner {
        presaleOwner.transfer(this.balance);
        selfdestruct(owner);
    }
}