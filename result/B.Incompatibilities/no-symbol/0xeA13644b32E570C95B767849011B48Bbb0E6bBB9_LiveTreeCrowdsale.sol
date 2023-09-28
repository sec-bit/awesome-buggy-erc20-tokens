pragma solidity 0.4.18;

contract CrowdsaleParameters {
    // Accounts (2017-11-30)
    address internal constant presalePoolAddress        = 0xF373BfD05C8035bE6dcB44CABd17557e49D5364C;
    address internal constant foundersAddress           = 0x0ED375dd94c878703147580F044B6B1CE6a7F053;
    address internal constant incentiveReserveAddress   = 0xD34121E853af290e61a0F0313B99abb24D4Dc6ea;
    address internal constant generalSaleAddress        = 0xC107EC2077BA7d65944267B64F005471A6c05692;
    address internal constant lotteryAddress            = 0x98631b688Bcf78D233C48E464fCfe6dC7aBd32A7;
    address internal constant marketingAddress          = 0x2C1C916a4aC3d0f2442Fe0A9b9e570eB656582d8;

    // PreICO and Main sale ICO Timing per requirements
    uint256 internal constant presaleStartDate      = 1512121500; // 2017-12-01 09:45 GMT
    uint256 internal constant presaleEndDate        = 1513382430; // 2017-12-16 00:00:30 GMT
    uint256 internal constant generalSaleStartDate  = 1515319200; // 2018-01-07 10:00 GMT
    uint256 internal constant generalSaleEndDate    = 1518602400; // 2018-02-14 10:00 GMT
}

contract TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    *  Constructor
    *
    *  Sets contract owner to address of constructor caller
    */
    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    *  Change Owner
    *
    *  Changes ownership of this contract. Only owner can call this method.
    *
    * @param newOwner - new owner's address
    */
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract SeedToken is Owned, CrowdsaleParameters {
    uint8 public decimals;

    function totalSupply() public  returns (uint256 result);

    function balanceOf(address _address) public returns (uint256 balance);

    function allowance(address _owner, address _spender) public returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function accountBalance(address _address) public returns (uint256 balance);
}

contract LiveTreeCrowdsale is Owned, CrowdsaleParameters {
    uint[] public ICOStagePeriod;

    bool public icoClosedManually = false;

    bool public allowRefunds = false;

    uint public totalCollected = 0;

    address private saleWalletAddress;

    address private presaleWalletAddress;

    uint private tokenMultiplier = 10;

    SeedToken private tokenReward;

    uint private reasonableCostsPercentage;

    mapping (address => uint256) private investmentRecords;

    event FundTransfer(address indexed _from, address indexed _to, uint _value);

    event TokenTransfer(address indexed baker, uint tokenAmount, uint pricePerToken);

    event Refund(address indexed backer, uint amount);

    enum Stage { PreSale, GeneralSale, Inactive }

    /**
    * Constructor
    *
    * @param _tokenAddress - address of SED token (deployed before this contract)
    */
    function LiveTreeCrowdsale(address _tokenAddress) public {
        tokenReward = SeedToken(_tokenAddress);
        tokenMultiplier = tokenMultiplier ** tokenReward.decimals();
        saleWalletAddress = CrowdsaleParameters.generalSaleAddress;
        presaleWalletAddress = CrowdsaleParameters.presalePoolAddress;

        ICOStagePeriod.push(CrowdsaleParameters.presaleStartDate);
        ICOStagePeriod.push(CrowdsaleParameters.presaleEndDate);
        ICOStagePeriod.push(CrowdsaleParameters.generalSaleStartDate);
        ICOStagePeriod.push(CrowdsaleParameters.generalSaleEndDate);
    }

    /**
    * Get active stage (pre-sale or general sale)
    *
    * @return stage - active stage
    */
    function getActiveStage() internal constant returns (Stage) {
        if (ICOStagePeriod[0] <= now && now < ICOStagePeriod[1])
            return Stage.PreSale;

        if (ICOStagePeriod[2] <= now && now < ICOStagePeriod[3])
            return Stage.GeneralSale;

        return Stage.Inactive;
    }

    /**
    *  Process received payment
    *
    *  Determine the number of tokens that was purchased considering current
    *  stage, bonus tier and remaining amount of tokens in the sale wallet.
    *  Transfer purchased tokens to bakerAddress and return unused portion of
    *  ether (change)
    *
    * @param bakerAddress - address that ether was sent from
    * @param amount - amount of Wei received
    */
    function processPayment(address bakerAddress, uint amount) internal {
        // Check current stage, either pre-sale or general sale should be active
        Stage currentStage = getActiveStage();
        require(currentStage != Stage.Inactive);

        // Validate if ICO is not closed manually or reached the threshold
        require(!icoClosedManually);

        // Before Metropolis update require will not refund gas, but
        // for some reason require statement around msg.value always throws
        assert(amount > 0 finney);

        // Validate that we received less than a billion ETH to prevent overflow
        require(amount < 1e27);

        // Tell everyone about the transfer
        FundTransfer(bakerAddress, address(this), amount);

        // Calculate tokens per ETH for this tier
        uint tokensPerEth = 1130;

        if (amount < 1.5 ether)
            tokensPerEth = 1000;
        else if (amount < 3 ether)
            tokensPerEth = 1005;
        else if (amount < 5 ether)
            tokensPerEth = 1010;
        else if (amount < 7 ether)
            tokensPerEth = 1015;
        else if (amount < 10 ether)
            tokensPerEth = 1020;
        else if (amount < 15 ether)
            tokensPerEth = 1025;
        else if (amount < 20 ether)
            tokensPerEth = 1030;
        else if (amount < 30 ether)
            tokensPerEth = 1035;
        else if (amount < 50 ether)
            tokensPerEth = 1040;
        else if (amount < 75 ether)
            tokensPerEth = 1045;
        else if (amount < 100 ether)
            tokensPerEth = 1050;
        else if (amount < 150 ether)
            tokensPerEth = 1055;
        else if (amount < 250 ether)
            tokensPerEth = 1060;
        else if (amount < 350 ether)
            tokensPerEth = 1070;
        else if (amount < 500 ether)
            tokensPerEth = 1075;
        else if (amount < 750 ether)
            tokensPerEth = 1080;
        else if (amount < 1000 ether)
            tokensPerEth = 1090;
        else if (amount < 1500 ether)
            tokensPerEth = 1100;
        else if (amount < 2000 ether)
            tokensPerEth = 1110;
        else if (amount < 3500 ether)
            tokensPerEth = 1120;

        if (currentStage == Stage.PreSale)
            tokensPerEth = tokensPerEth * 2;

        // Calculate token amount that is purchased,
        // truncate to integer
        uint weiPerEth = 1e18;
        uint tokenAmount = amount * tokensPerEth * tokenMultiplier / weiPerEth;

        // Check that stage wallet has enough tokens. If not, sell the rest and
        // return change.
        address tokenSaleWallet = currentStage == Stage.PreSale ? presaleWalletAddress : saleWalletAddress;
        uint remainingTokenBalance = tokenReward.accountBalance(tokenSaleWallet);
        if (remainingTokenBalance < tokenAmount) {
            tokenAmount = remainingTokenBalance;
        }

        // Calculate Wei amount that was received in this transaction
        // adjusted to rounding and remaining token amount
        uint acceptedAmount = tokenAmount * weiPerEth / (tokensPerEth * tokenMultiplier);

        // Transfer tokens to baker and return ETH change
        tokenReward.transferFrom(tokenSaleWallet, bakerAddress, tokenAmount);

        TokenTransfer(bakerAddress, tokenAmount, tokensPerEth);

        uint change = amount - acceptedAmount;
        if (change > 0) {
            if (bakerAddress.send(change)) {
                FundTransfer(address(this), bakerAddress, change);
            }
            else
                revert();
        }

        // Update crowdsale performance
        investmentRecords[bakerAddress] += acceptedAmount;
        totalCollected += acceptedAmount;
    }

    /**
    * Change pre-sale end date
    *
    * @param endDate - end date of pre-sale in milliseconds from unix epoch
    */
    function changePresaleEndDate(uint256 endDate) external onlyOwner {
        require(ICOStagePeriod[0] < endDate);
        require(ICOStagePeriod[2] >= endDate);

        ICOStagePeriod[1] = endDate;
    }

    /**
    * Change general sale start date
    *
    * @param startDate - start date of general sale in milliseconds from unix epoch
    */
    function changeGeneralSaleStartDate(uint256 startDate) external onlyOwner {
        require(now < startDate);
        require(ICOStagePeriod[1] <= startDate);

        ICOStagePeriod[2] = startDate;
    }

    /**
    * Change general sale end date
    *
    * @param endDate - end date of general sale in milliseconds from unix epoch
    */
    function changeGeneralSaleEndDate(uint256 endDate) external onlyOwner {
        require(ICOStagePeriod[2] < endDate);

        ICOStagePeriod[3] = endDate;
    }

    /**
    * Stop ICO manually
    */
    function pauseICO() external onlyOwner {
        require(!icoClosedManually);

        icoClosedManually = true;
    }

    /**
    * Reopen ICO
    */
    function unpauseICO() external onlyOwner {
        require(icoClosedManually);

        icoClosedManually = false;
    }

    /**
    * Close main sale and destroy unsold tokens
    */
    function closeMainSaleICO() external onlyOwner {
        var amountToDestroy = tokenReward.balanceOf(CrowdsaleParameters.generalSaleAddress);
        tokenReward.transferFrom(CrowdsaleParameters.generalSaleAddress, 0, amountToDestroy);
        ICOStagePeriod[3] = now;
        TokenTransfer(0, amountToDestroy, 0);
    }

    /**
    * Close pre ICO and transfer all unsold tokens to main sale wallet
    */
    function closePreICO() external onlyOwner {
        var amountToTransfer = tokenReward.balanceOf(CrowdsaleParameters.presalePoolAddress);
        ICOStagePeriod[1] = now;
        tokenReward.transferFrom(CrowdsaleParameters.presalePoolAddress, CrowdsaleParameters.generalSaleAddress, amountToTransfer);
    }


    /**
    * Allow or disallow refunds
    *
    * @param value - if true, refunds will be allowed; if false, disallowed
    * @param _reasonableCostsPercentage - non-refundable fraction of total
    *        collections in tens of a percent. Valid range is 0 to 1000:
    *        0 = 0.0%, 123 = 12.3%, 1000 = 100.0%
    */
    function setAllowRefunds(bool value, uint _reasonableCostsPercentage) external onlyOwner {
        require(isICOClosed());
        require(_reasonableCostsPercentage >= 1 && _reasonableCostsPercentage <= 999);

        allowRefunds = value;
        reasonableCostsPercentage = _reasonableCostsPercentage;
    }

    /**
    *  Transfer ETH amount from contract to owner's address.
    *
    * @param amount - ETH amount to transfer in Wei
    */
    function safeWithdrawal(uint amount) external onlyOwner {
        require(this.balance >= amount);

        if (owner.send(amount))
            FundTransfer(address(this), owner, amount);
    }

    /**
    function
    * Is ICO closed (either closed manually or not started)
    *
    * @return true if ICO is closed manually or stage is "Inactive", otherwise false
    */
    function isICOClosed() public constant returns (bool closed) {
        Stage currentStage = getActiveStage();
        return icoClosedManually || currentStage == Stage.Inactive;
    }

    /**
    *  Default method
    *
    *  Processes all ETH that it receives and credits SED tokens to sender
    *  according to current stage and tier bonus
    */
    function () external payable {
        processPayment(msg.sender, msg.value);
    }

    /**
    *  Kill method
    *
    *  Destructs this contract
    */
    function kill() external onlyOwner {
        require(isICOClosed());

        selfdestruct(owner);
    }

    /**
    *  Refund
    *
    *  Sends a partial refund to the sender who calls this method.
    *  Fraction of collected amount will not be refunded
    */
    function refund() external {
        require(isICOClosed() && allowRefunds && investmentRecords[msg.sender] > 0);

        var amountToReturn = investmentRecords[msg.sender] * (1000 - reasonableCostsPercentage) / 1000;

        require(this.balance >= amountToReturn);

        investmentRecords[msg.sender] = 0;
        msg.sender.transfer(amountToReturn);
        Refund(msg.sender, amountToReturn);
    }
}