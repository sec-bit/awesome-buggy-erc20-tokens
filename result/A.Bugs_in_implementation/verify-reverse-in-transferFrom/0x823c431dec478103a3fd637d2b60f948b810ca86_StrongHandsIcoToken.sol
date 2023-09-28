pragma solidity ^0.4.17;


contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract ForeignToken {
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}


contract StrongHandsIcoToken is Owned {
    bool public purchasingAllowed = false;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    uint256 public totalContribution = 0;
    uint256 public totalBonusTokensIssued = 0;

    uint256 public totalSupply = 0;

    function name() public pure returns (string) { return "Strong Hands ICO Token"; }
    function symbol() public pure returns (string) { return "SHIT"; }
    function decimals() public pure returns (uint8) { return 18; }
    
    function balanceOf(address _owner) public constant returns (uint256) { return balances[_owner]; }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(msg.data.length >= (2 * 32) + 4);

        if (_value == 0) { return false; }

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        
        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(msg.data.length >= (3 * 32) + 4);

        if (_value == 0) { return false; }
        
        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            allowed[_from][msg.sender] -= _value;
            
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function enablePurchasing() public onlyOwner {
        purchasingAllowed = true;
    }

    function disablePurchasing() public onlyOwner {
        purchasingAllowed = false;
    }

    function withdrawForeignTokens(address _tokenContract) public onlyOwner returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);

        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function getStats() public constant returns (uint256, uint256, uint256, bool) {
        return (totalContribution, totalSupply, totalBonusTokensIssued, purchasingAllowed);
    }

    function _randomNumber(uint64 upper) internal view returns (uint64 randomNumber) {
        uint64 _seed = uint64(keccak256(keccak256(block.blockhash(block.number), _seed), now));
        return _seed % upper;
    }

    function() public payable {
        require(purchasingAllowed);
        require(msg.value > 0);

        uint256 rate = 10000;
        if (totalContribution < 100 ether) {
            rate = 12500;
        } else if (totalContribution < 200 ether) {
            rate = 11500;
        } else if (totalContribution < 300 ether) {
            rate = 10500;
        }
        owner.transfer(msg.value);
        totalContribution += msg.value;

        uint256 tokensIssued = (msg.value * rate);

        if (msg.value >= 10 finney) {
            uint64 multiplier = 1;
            if (_randomNumber(10000) == 1) {
                multiplier *= 10;
            }
            if (_randomNumber(1000) == 1) {
                multiplier *= 5;
            }
            if (_randomNumber(100) == 1) {
                multiplier *= 2;
            }

            uint256 bonusTokensIssued = (tokensIssued * multiplier) - tokensIssued;
            tokensIssued *= multiplier;

            totalBonusTokensIssued += bonusTokensIssued;
        }

        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;
        
        Transfer(address(this), msg.sender, tokensIssued);
    }
}