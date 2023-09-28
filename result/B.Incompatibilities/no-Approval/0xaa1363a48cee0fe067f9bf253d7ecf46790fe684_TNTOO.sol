pragma solidity ^0.4.18;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract token {
    string public standard = 'https://www.tntoo.com';
    string public name = 'Transaction Network';
    string public symbol = 'TNTOO';
    uint8 public decimals = 18;
    uint public totalSupply = 0;

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint value);

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);  
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
}

contract TNTOO is owned, token {
    uint public allEther;
    uint public ratio = 10000;
    uint public ratioUpdateTime = now;
    uint public windowPeriod = now + 180 days;
    bool public windowPeriodEnd;
    address[] public investors;
    uint _seed = now;

    struct Good {
        bytes32 preset;
        uint price;
        uint time;
        address seller;
    }

    mapping (bytes32 => Good) public goods;
    // withdraw quota
    mapping (address => uint) public quotaOf; 
    // trade decision result
    mapping (bytes32 => address) public decisionOf; 

    event WindowPeriodClosed(address target, uint time);
    event Decision(uint result, address finalAddress, address[] buyers, uint[] amounts);
    event Withdraw(address from, address target, uint ethAmount, uint amount, uint fee);

    function _random (uint _upper) internal returns (uint randomNumber) {
        _seed = uint(keccak256(keccak256(block.blockhash(block.number), _seed), now));
        return _seed % _upper;
    }

    function _stringToBytes32(string memory _source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(_source, 32))
        }
    }

    // get decision result address
    function _getFinalAddress(uint[] _amounts, address[] _buyers, uint result) internal pure returns (address finalAddress) {
        uint congest = 0;
        address _finalAddress = 0x0;
        for (uint j = 0; j < _amounts.length; j++) {
            congest += _amounts[j];
            if (result <= congest && _finalAddress == 0x0) {
                _finalAddress = _buyers[j];
            }
        }
        return _finalAddress;
    }

    // try to update ratio,  15 days limit
    function _checkRatio() internal {
        if (ratioUpdateTime <= now - 15 days && allEther != 0) {
            ratioUpdateTime = now;
            ratio = uint(totalSupply / allEther);
        }
    }

    // 500ETH investors, everyone 5%
    function _shareOut(uint feeAmount) internal {
        uint shareAmount;
        address investor;
        for (uint k = 0; k < investors.length; k++) {
            shareAmount = feeAmount * 5 / 100;
            investor = investors[k];
            balanceOf[investor] += shareAmount;
            quotaOf[investor] += shareAmount;
            balanceOf[owner] -= shareAmount;
            quotaOf[owner] -= shareAmount;
        }
    }

    // try to close window period
    function _checkWindowPeriod() internal {
        if (now >= windowPeriod) {
            windowPeriodEnd = true;
            WindowPeriodClosed(msg.sender, now);
        }
    }

    // mall application delegate transfer
    function delegateTransfer(address _from, address _to, uint _value, uint _fee) onlyOwner public {
        if (_fee > 0) {
            require(_fee < 100 * 10 ** uint256(decimals));
            quotaOf[owner] += _fee;
        }
        if (_from != owner && _to != owner) {
            _transfer(_from, owner, _fee);
        }
        _transfer(_from, _to, _value - _fee);
    }

    function postTrade(bytes32 _preset, uint _price, address _seller) onlyOwner public {
        // execute it only once
        require(goods[_preset].preset == "");
        goods[_preset] = Good({preset: _preset, price: _price, seller: _seller, time: now});
    }

    function decision(bytes32 _preset, string _presetSrc, address[] _buyers, uint[] _amounts) onlyOwner public {
        
        // execute it only once
        require(decisionOf[_preset] == 0x0);

        Good storage good = goods[_preset];
        // preset authenticity
        require(sha256(_presetSrc) == good.preset);

        // address added, parameter 1
        uint160 allAddress;
        for (uint i = 0; i < _buyers.length; i++) {
            allAddress += uint160(_buyers[i]);
        }
        
        // random, parameter 2
        uint random = _random(allAddress);

        // preset is parameter 3, add and take the remainder
        uint result = uint(uint(_stringToBytes32(_presetSrc)) + allAddress + random) % good.price;

        address finalAddress = _getFinalAddress(_amounts, _buyers, result);
        
        // save decision result
        decisionOf[_preset] = finalAddress;
        Decision(result, finalAddress, _buyers, _amounts);
        
        uint finalAmount = uint(good.price * 98 / 100);
        uint feeAmount = uint(good.price * 1 / 100);
        if (good.seller != 0x0) {
            // quota for seller
            quotaOf[good.seller] += finalAmount;
        } else {
            // quota for buyer
            quotaOf[finalAddress] += finalAmount;
            _transfer(owner, finalAddress, finalAmount); 
        }

        // destroy tokens
        balanceOf[owner] -= feeAmount;
        totalSupply -= feeAmount;
        quotaOf[owner] += feeAmount;
        
        _shareOut(feeAmount);
        
        _checkRatio();
    }

    // TNTOO withdraw as ETH
    function withdraw(address _target, uint _amount, uint _fee) public {
        require(_amount <= quotaOf[_target]);
        uint finalAmount = _amount - _fee;         
        uint ethAmount = finalAmount / ratio;
        require(ethAmount <= allEther);
        // fee
        if (msg.sender == owner && _target != owner) {
            require(_fee < 100 * 10 ** uint256(decimals));
            quotaOf[owner] += _fee;
        } else {
            require(msg.sender == _target);
        }
        quotaOf[_target] -= _amount;
        // destroy tokens
        totalSupply -= finalAmount;
        balanceOf[owner] -= finalAmount;
        // transfer ether
        _target.transfer(ethAmount);
        allEther -= ethAmount;
        Withdraw(msg.sender, _target, ethAmount, _amount, _fee);
    }

    function () payable public {
        // ethers
        uint etherAmount = msg.value;
        uint tntooAmount = etherAmount * ratio;
        allEther += etherAmount;
        // investors
        if (!windowPeriodEnd && investors.length < 5 && etherAmount >= 500 ether) {
            quotaOf[owner] += tntooAmount;
            investors.push(msg.sender);
        }
        totalSupply += tntooAmount;
        // unified management by the application
        balanceOf[owner] += tntooAmount;
        _checkWindowPeriod();

        Transfer(this, owner, tntooAmount);
    }
}