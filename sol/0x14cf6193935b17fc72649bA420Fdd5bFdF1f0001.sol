/*
This file is part of the Open Longevity Contract.

The Open Longevity Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The Open Longevity Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the Open Longevity Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <i.svirin@nordavind.ru>
*/


pragma solidity ^0.4.10;

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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function allowance(address owner, address spender) constant returns (uint);
    function transferFrom(address from, address to, uint value);
    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title Know your customer contract
 */
contract KYC is owned {

    mapping (address => bool) public known;
    address                   public confirmer;

    function setConfirmer(address _confirmer) public onlyOwner {
        confirmer = _confirmer;
    }

    function setToKnown(address _who) public {
        require(msg.sender == confirmer || msg.sender == owner);
        known[_who] = true;
    }
}

contract Presale is KYC, ERC20 {

    uint    public etherPrice;
    address public presaleOwner;
    uint    public totalLimitUSD;
    uint    public collectedUSD;

    enum State { Disabled, Presale, Finished }
    event NewState(State state);
    State   public state;
    uint    public presaleStartTime;
    uint    public ppFinishTime;
    uint    public presaleFinishTime;

    struct Investor {
        uint256 amountTokens;
        uint    amountWei;
    }
    mapping (address => Investor) public investors;
    mapping (uint => address)     public investorsIter;
    uint                          public numberOfInvestors;
    
    function () payable public {
        require(state == State.Presale);
        require(now < presaleFinishTime);
        require(now > ppFinishTime || known[msg.sender]);

        uint valueWei = msg.value;
        uint valueUSD = valueWei * etherPrice / 1000000000000000000;
        if (collectedUSD + valueUSD > totalLimitUSD) { // don't need so much ether
            valueUSD = totalLimitUSD - collectedUSD;
            valueWei = valueUSD * 1000000000000000000 / etherPrice;
            require(msg.sender.call.gas(3000000).value(msg.value - valueWei)());
            collectedUSD = totalLimitUSD; // to be sure!
        } else {
            collectedUSD += valueUSD;
        }

        uint256 tokensPer10USD = 100;
        if (now <= ppFinishTime) {
            if (valueUSD >= 100000) {
                tokensPer10USD = 200;
            } else {
                tokensPer10USD = 175;
            }
        } else {
            if (valueUSD >= 100000) {
                tokensPer10USD = 150;
            } else {
                tokensPer10USD = 130;
            }
        }

        uint256 tokens = tokensPer10USD * valueUSD / 10;
        require(tokens > 0);

        Investor storage inv = investors[msg.sender];
        if (inv.amountWei == 0) { // new investor
            investorsIter[numberOfInvestors++] = msg.sender;
        }
        require(inv.amountTokens + tokens > inv.amountTokens); // overflow
        inv.amountTokens += tokens;
        inv.amountWei += valueWei;
        totalSupply += tokens;
        Transfer(this, msg.sender, tokens);
    }
    
    function startPresale(address _presaleOwner, uint _etherPrice) public onlyOwner {
        require(state == State.Disabled);
        presaleStartTime = now;
        presaleOwner = _presaleOwner;
        etherPrice = _etherPrice;
        ppFinishTime = now + 3 days;
        presaleFinishTime = ppFinishTime + 60 days;
        state = State.Presale;
        totalLimitUSD = 500000;
        NewState(state);
    }
    
    function timeToFinishPresale() public constant returns(uint t) {
        require(state == State.Presale);
        if (now > presaleFinishTime) {
            t = 0;
        } else {
            t = presaleFinishTime - now;
        }
    }
    
    function finishPresale() public onlyOwner {
        require(state == State.Presale);
        require(now >= presaleFinishTime || collectedUSD == totalLimitUSD);
        require(presaleOwner.call.gas(3000000).value(this.balance)());
        state = State.Finished;
        NewState(state);
    }
    
    function withdraw() public onlyOwner {
        require(presaleOwner.call.gas(3000000).value(this.balance)());
    }
}

contract PresaleToken is Presale {
    
    string  public standard    = 'Token 0.1';
    string  public name        = 'OpenLongevity';
    string  public symbol      = "YEAR";
    uint8   public decimals    = 0;

    function PresaleToken() payable public Presale() {}

    function balanceOf(address _who) constant public returns (uint) {
        return investors[_who].amountTokens;
    }

    function transfer(address, uint256) public {revert();}
    function transferFrom(address, address, uint256) public {revert();}
    function approve(address, uint256) public {revert();}
    function allowance(address, address) public constant returns (uint256) {revert();}
}

contract OpenLongevityPresale is PresaleToken {

    function OpenLongevityPresale() payable public PresaleToken() {}

    function killMe() public onlyOwner {
        selfdestruct(owner);
    }
}