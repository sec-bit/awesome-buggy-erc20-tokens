pragma solidity ^0.4.2;

/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
/// @title Abstract token contract - Functions to be implemented by token contracts.
contract Token {
    // This is not an abstract function, because solc won't recognize generated getter functions for public variables as functions
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract HumaniqToken is Token {
    function issueTokens(address _for, uint tokenCount) payable returns (bool);
    function changeEmissionContractAddress(address newAddress) returns (bool);
}

/// @title HumaniqICO contract - Takes funds from users and issues tokens.
/// @author Evgeny Yurtaev - <evgeny@etherionlab.com>
contract HumaniqICO {

    /*
     * External contracts
     */
    HumaniqToken public humaniqToken = HumaniqToken(0x9734c136F5c63531b60D02548Bca73a3d72E024D);

    /*
     * Crowdfunding parameters
     */
    uint constant public CROWDFUNDING_PERIOD = 12 days;
    // Goal threshold, 10000 ETH
    uint constant public CROWDSALE_TARGET = 10000 ether;

    /*
     *  Storage
     */
    address public founder;
    address public multisig;
    uint public startDate = 0;
    uint public icoBalance = 0;
    uint public baseTokenPrice = 666 szabo; // 0.000666 ETH
    uint public discountedPrice = baseTokenPrice;
    bool public isICOActive = false;

    // participant address => value in Wei
    mapping (address => uint) public investments;

    /*
     *  Modifiers
     */
    modifier onlyFounder() {
        // Only founder is allowed to do this action.
        if (msg.sender != founder) {
            throw;
        }
        _;
    }

    modifier minInvestment() {
        // User has to send at least the ether value of one token.
        if (msg.value < baseTokenPrice) {
            throw;
        }
        _;
    }

    modifier icoActive() {
        if (isICOActive == false) {
            throw;
        }
        _;
    }

    modifier applyBonus() {
        uint icoDuration = now - startDate;
        if (icoDuration >= 248 hours) {
            discountedPrice = baseTokenPrice;
        }
        else if (icoDuration >= 176 hours) {
            discountedPrice = (baseTokenPrice * 100) / 107;
        }
        else if (icoDuration >= 104 hours) {
            discountedPrice = (baseTokenPrice * 100) / 120;
        }
        else if (icoDuration >= 32 hours) {
            discountedPrice = (baseTokenPrice * 100) / 142;
        }
        else if (icoDuration >= 12 hours) {
            discountedPrice = (baseTokenPrice * 100) / 150;
        }
        else {
            discountedPrice = (baseTokenPrice * 100) / 170;
        }
        _;
    }

    /// @dev Allows user to create tokens if token creation is still going
    /// and cap was not reached. Returns token count.
    function fund()
        public
        applyBonus
        icoActive
        minInvestment
        payable
        returns (uint)
    {
        // Token count is rounded down. Sent ETH should be multiples of baseTokenPrice.
        uint tokenCount = msg.value / discountedPrice;
        // Ether spent by user.
        uint investment = tokenCount * discountedPrice;
        // Send change back to user.
        if (msg.value > investment && !msg.sender.send(msg.value - investment)) {
            throw;
        }
        // Update fund's and user's balance and total supply of tokens.
        icoBalance += investment;
        investments[msg.sender] += investment;
        // Send funds to founders.
        if (!multisig.send(investment)) {
            // Could not send money
            throw;
        }
        if (!humaniqToken.issueTokens(msg.sender, tokenCount)) {
            // Tokens could not be issued.
            throw;
        }
        return tokenCount;
    }

    /// @dev Issues tokens for users who made BTC purchases.
    /// @param beneficiary Address the tokens will be issued to.
    /// @param _tokenCount Number of tokens to issue.
    function fundBTC(address beneficiary, uint _tokenCount)
        external
        applyBonus
        icoActive
        onlyFounder
        returns (uint)
    {
        // Approximate ether spent.
        uint investment = _tokenCount * discountedPrice;
        // Update fund's and user's balance and total supply of tokens.
        icoBalance += investment;
        investments[beneficiary] += investment;
        if (!humaniqToken.issueTokens(beneficiary, _tokenCount)) {
            // Tokens could not be issued.
            throw;
        }
        return _tokenCount;
    }

    /// @dev If ICO has successfully finished sends the money to multisig
    /// wallet.
    function finishCrowdsale()
        external
        onlyFounder
        returns (bool)
    {
        if (isICOActive == true) {
            isICOActive = false;
            // Founders receive 14% of all created tokens.
            uint founderBonus = ((icoBalance / baseTokenPrice) * 114) / 100;
            if (!humaniqToken.issueTokens(multisig, founderBonus)) {
                // Tokens could not be issued.
                throw;
            }
        }
    }

    /// @dev Sets token value in Wei.
    /// @param valueInWei New value.
    function changeBaseTokenPrice(uint valueInWei)
        external
        onlyFounder
        returns (bool)
    {
        baseTokenPrice = valueInWei;
        return true;
    }

    /// @dev Function that activates ICO.
    function startICO()
        external
        onlyFounder
    {
        if (isICOActive == false && startDate == 0) {
          // Start ICO
          isICOActive = true;
          // Set start-date of token creation
          startDate = now;
        }
    }

    /// @dev Contract constructor function sets founder and multisig addresses.
    function HumaniqICO(address _multisig) {
        // Set founder address
        founder = msg.sender;
        // Set multisig address
        multisig = _multisig;
    }

    /// @dev Fallback function. Calls fund() function to create tokens.
    function () payable {
        fund();
    }
}