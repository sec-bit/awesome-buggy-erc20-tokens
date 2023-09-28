pragma solidity ^0.4.18;

contract Token {
    function totalSupply() constant public returns (uint supply);
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract TestIco {
    uint public constant ETH_PRICE = 1;

    address public manager;
    address public reserveManager;
    
    address public escrow;
    address public reserveEscrow;
    
    address[] public allowedTokens;
    mapping(address => bool) public tokenAllowed;
    mapping(address => uint) public tokenPrice;
    mapping(address => uint) public tokenAmount;
    
    mapping(address => uint) public ethBalances;
    mapping(address => uint) public balances;
    
    // user => token[]
    mapping(address => address[]) public userTokens;
    //  user => token => amount
    mapping(address => mapping(address => uint)) public userTokensValues;
    
    modifier onlyManager {
        assert(msg.sender == manager || msg.sender == reserveManager);
        _;
    }
    modifier onlyManagerOrContract {
        assert(msg.sender == manager || msg.sender == reserveManager || msg.sender == address(this));
        _;
    }

    function TestIco(
        address _manager, 
        address _reserveManager, 
        address _escrow, 
        address _reserveEscrow
    ) public {
        manager = _manager;
        reserveManager = _reserveManager;
        escrow = _escrow;
        reserveEscrow = _reserveEscrow;
    }
    
    // _price is price of amount of token
    function addToken(address _token, uint _amount, uint _price) onlyManager public {
        assert(_token != 0x0);
        assert(_amount > 0);
        assert(_price > 0);
        
        bool isNewToken = true;
        for (uint i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _token) {
                isNewToken = false;
            }
        }
        if (isNewToken) {
            allowedTokens.push(_token);
        }
        
        tokenAllowed[_token] = true;
        tokenPrice[_token] = _price;
        tokenAmount[_token] = _amount;
    }
    
    function removeToken(address _token) onlyManager public {
        for (uint i = 0; i < allowedTokens.length; i++) {
            if (_token == allowedTokens[i]) {
                if (i < allowedTokens.length - 1) {
                    allowedTokens[i] = allowedTokens[allowedTokens.length - 1];
                }
                allowedTokens[allowedTokens.length - 1] = 0x0;
                allowedTokens.length--;
                break;
            }
        }
    
        tokenAllowed[_token] = false;
        tokenPrice[_token] = 0;
        tokenAmount[_token] = 0;
    }
    
    function buyWithTokens(address _token) public {
        buyWithTokensBy(msg.sender, _token);
    }
    function addTokenToUser(address _user, address _token) private {
        for (uint i = 0; i < userTokens[_user].length; i++) {
            if (userTokens[_user][i] == _token) {
                return;
            }
        }
        userTokens[_user].push(_token);
    }
    function buyWithTokensBy(address _user, address _token) public {
        assert(tokenAllowed[_token]);
    
        Token token = Token(_token);
        
        uint tokensToSend = token.allowance(_user, address(this));
        assert(tokensToSend > 0);
        uint prevBalance = token.balanceOf(address(this));
        assert(token.transferFrom(_user, address(this), tokensToSend));
        assert(token.balanceOf(address(this)) - prevBalance == tokensToSend);
        balances[_user] += tokensToSend * tokenPrice[_token] / tokenAmount[_token];
        addTokenToUser(_user, _token);
        userTokensValues[_user][_token] += tokensToSend;
    }
    
    function returnFundsFor(address _user) public onlyManagerOrContract returns(bool) {
        if (ethBalances[_user] > 0) {
            _user.transfer(ethBalances[_user]);
            ethBalances[_user] = 0;
        }
        
        for (uint i = 0; i < userTokens[_user].length; i++) {
            address tokenAddress = userTokens[_user][i];
            uint userTokenValue = userTokensValues[_user][tokenAddress];
            if (userTokenValue > 0) {
                Token token = Token(tokenAddress);
                assert(token.transfer(_user, userTokenValue));
                userTokensValues[_user][tokenAddress] = 0;
            }
        }
    }
    
    
    function returnFundsForUsers(address[] _users) public onlyManager {
        for (uint i = 0; i < _users.length; i++) {
            returnFundsFor(_users[i]);
        }
    }
    
    function buyTokens(address _user, uint _value) private {
        assert(_user != 0x0);
        
        ethBalances[_user] += _value;
        balances[_user] += _value * ETH_PRICE;
    }
    
    function() public payable {
        assert(msg.value > 0);
        buyTokens(msg.sender, msg.value);
    }
    
    function withdrawEtherTo(address _escrow) private {
        if (this.balance > 0) {
            _escrow.transfer(this.balance);
        }
        
        for (uint i = 0; i < allowedTokens.length; i++) {
            Token token = Token(allowedTokens[i]);
            uint tokenBalance = token.balanceOf(address(this));
            if (tokenBalance > 0) {
                assert(token.transfer(_escrow, tokenBalance));
            }
        }
    }
    
    function withdrawEther() public onlyManager {
        withdrawEtherTo(escrow);
    }
    
    function withdrawEtherToReserveEscrow() public onlyManager {
        withdrawEtherTo(reserveEscrow);
    }
}