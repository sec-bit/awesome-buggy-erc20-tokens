/*
This file is part of the PROOF Contract.

The PROOF Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The PROOF Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the PROOF Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <i.svirin@prover.io>
*/

pragma solidity ^0.4.11;

contract owned {

    address public owner;
    address public candidate;

    function owned() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        candidate = _owner;
    }
    
    function confirmOwner() public {
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }
}

/**
 * @title Base of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract BaseERC20 {
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
}

contract ManualMigration is owned {

    address                      public original = 0x5B5d8A8A732A3c73fF0fB6980880Ef399ecaf72E;
    uint                         public totalSupply;
    mapping (address => uint256) public balanceOf;

    uint                         public numberOfInvestors;
    mapping (address => bool)    public investors;

    event Transfer(address indexed from, address indexed to, uint value);

    function ManualMigration() public owned() {}

    function migrateManual(address _who, bool _preico) public onlyOwner {
        require(original != 0);
        require(balanceOf[_who] == 0);
        uint balance = BaseERC20(original).balanceOf(_who);
        balance *= _preico ? 27 : 45;
        balance /= 10;
        balance *= 100000000;
        balanceOf[_who] = balance;
        totalSupply += balance;
        if (!investors[_who]) {
            investors[_who] = true;
            ++numberOfInvestors;
        }
        Transfer(original, _who, balance);
    }
    
    function migrateListManual(address [] _who, bool _preico) public onlyOwner {
        for(uint i = 0; i < _who.length; ++i) {
            migrateManual(_who[i], _preico);
        }
    }
    
    function sealManualMigration() public onlyOwner {
        delete original;
    }
}

contract Crowdsale is ManualMigration {

    address public backend;
    address public cryptaurToken = 0x88d50B466BE55222019D71F9E8fAe17f5f45FCA1;
    uint    public crowdsaleStartTime = 1517270400;  // 30 January 2018, GMT 00:00:00
    uint    public crowdsaleFinishTime = 1522454400; // 31 March 2018, 00:00:00
    uint    public etherPrice;
    uint    public collectedUSD;
    bool    public crowdsaleFinished;

    event Mint(address indexed minter, uint tokens, bytes32 originalTxHash);

    // Fix for the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier isCrowdsale() {
        require(now >= crowdsaleStartTime && now <= crowdsaleFinishTime);
        _;
    }

    function Crowdsale(address _backend, uint _etherPrice) public ManualMigration() {
        backend = _backend;
        etherPrice = _etherPrice;
    }

    function changeBackend(address _backend) public onlyOwner {
        backend = _backend;
    }
    
    function setEtherPrice(uint _etherPrice) public {
        require(msg.sender == owner || msg.sender == backend);
        etherPrice = _etherPrice;
    }

    function () payable public isCrowdsale {
        uint valueUSD = msg.value * etherPrice / 1 ether;
        collectedUSD += valueUSD;
        mintTokens(msg.sender, valueUSD);
    }

    function depositUSD(address _who, uint _valueUSD) public isCrowdsale {
        require(msg.sender == backend || msg.sender == owner);
        collectedUSD += _valueUSD;
        mintTokens(_who, _valueUSD);
    }

    function mintTokens(address _who, uint _valueUSD) internal {
        uint tokensPerUSD = 100;
        if (_valueUSD >= 50000) {
            tokensPerUSD = 120;
        } else if (now < crowdsaleStartTime + 1 days) {
            tokensPerUSD = 115;
        } else if (now < crowdsaleStartTime + 1 weeks) {
            tokensPerUSD = 110;
        }
        uint tokens = tokensPerUSD * _valueUSD * 100000000;
        require(balanceOf[_who] + tokens > balanceOf[_who]); // overflow
        require(tokens > 0);
        balanceOf[_who] += tokens;
        if (!investors[_who]) {
            investors[_who] = true;
            ++numberOfInvestors;
        }
        Transfer(this, _who, tokens);
        totalSupply += tokens;
    }

    function depositCPT(address _who, uint _valueCPT, bytes32 _originalTxHash) public isCrowdsale {
        require(msg.sender == backend || msg.sender == owner);
        // decimals in CPT and PROOF are the same and equal 8
        uint tokens = 15 * _valueCPT / 10;
        require(balanceOf[_who] + tokens > balanceOf[_who]); // overflow
        require(tokens > 0);
        balanceOf[_who] += tokens;
        totalSupply += tokens;
        collectedUSD += _valueCPT / 100;
        if (!investors[_who]) {
            investors[_who] = true;
            ++numberOfInvestors;
        }
        Transfer(this, _who, tokens);
        Mint(_who, tokens, _originalTxHash);
    }

    function withdraw() public onlyOwner {
        require(msg.sender.call.gas(3000000).value(this.balance)());
        uint balance = BaseERC20(cryptaurToken).balanceOf(this);
        BaseERC20(cryptaurToken).transfer(msg.sender, balance);
    }
    
    function finishCrowdsale() public onlyOwner {
        require(!crowdsaleFinished);
        uint extraTokens = totalSupply / 2;
        balanceOf[msg.sender] += extraTokens;
        totalSupply += extraTokens;
        if (!investors[msg.sender]) {
            investors[msg.sender] = true;
            ++numberOfInvestors;
        }
        Transfer(this, msg.sender, extraTokens);
        crowdsaleFinished = true;
    }
}

contract ProofToken is Crowdsale {

    string  public standard = 'Token 0.1';
    string  public name     = 'PROOF';
    string  public symbol   = 'PF';
    uint8   public decimals = 8;

    mapping (address => mapping (address => uint)) public allowed;
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed owner, uint value);

    function ProofToken(address _backend, uint _etherPrice) public
        payable Crowdsale(_backend, _etherPrice) {
    }

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]); // overflow
        require(allowed[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
    function burn(uint _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
    }
}