pragma solidity ^0.4.10;

// Token selling smart contract
// Inspired by https://github.com/bokkypoobah/TokenTrader

// https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// `owned` contracts allows us to specify an owner address
// which has admin right to this contract
contract owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// `halting` contracts allow us to stop activity on this contract,
// or even self-destruct if need be.
contract halting is owned {
    bool public running = true;

    function start() onlyOwner {
        running = true;
    }

    function stop() onlyOwner {
        running = false;
    }

    function destruct() onlyOwner {
        selfdestruct(owner);
    }

    modifier halting {
        assert(running);
        _;
    }
}

// contract can buy or sell tokens for ETH
// prices are in amount of wei per batch of token units
contract TokenVault is owned, halting {

    address public asset;    // address of token
    uint public sellPrice;   // contract sells lots at this price (in wei)
    uint public units;       // lot size (token-wei)

    event MakerWithdrewAsset(uint tokens);
    event MakerWithdrewEther(uint ethers);
    event SoldTokens(uint tokens);

    // Constructor - only to be called by the TokenTraderFactory contract
    function TokenVault (
        address _asset,
        uint _sellPrice,
        uint _units
    ) {
        asset       = _asset;
        sellPrice   = _sellPrice;
        units       = _units;

        require(asset != 0);
        require(sellPrice > 0);
        require(units > 0);
    }

    // Withdraw asset ERC20 Token
    function makerWithdrawAsset(uint tokens) onlyOwner returns (bool ok) {
        MakerWithdrewAsset(tokens);
        return ERC20(asset).transfer(owner, tokens);
    }

    // Withdraw all eth from this contract
    function makerWithdrawEther() onlyOwner {
        MakerWithdrewEther(this.balance);
        return owner.transfer(this.balance);
    }

    // Function to easily check this contracts balance
    function getAssetBalance() constant returns (uint) {
        return ERC20(asset).balanceOf(address(this));
    }

    function min(uint a, uint b) private returns (uint) {
        return a < b ? a : b;
    }

    // Primary function; called with Ether sent to contract
    function takerBuyAsset() payable halting {

        // Must request at least one asset
        require(msg.value >= sellPrice);

        uint order    = msg.value / sellPrice;
        uint can_sell = getAssetBalance() / units;
        // start with no change
        uint256 change = 0;
        if (msg.value > (can_sell * sellPrice)) {
            change  = msg.value - (can_sell * sellPrice);
            order = can_sell;
        }
        if (change > 0) {
            if (!msg.sender.send(change)) throw;
        }
        if (order > 0) {
            if (!ERC20(asset).transfer(msg.sender, order * units)) throw;
        }
        SoldTokens(order);

    }

    // Ether is sent to the contract; can be either Maker or Taker
    function () payable {
        if (msg.sender == owner) {
            // Allow owner to simply add eth to contract
            return;
        }
        else {
            // Otherwise, interpret as a buy request
            takerBuyAsset();
        }
    }
}