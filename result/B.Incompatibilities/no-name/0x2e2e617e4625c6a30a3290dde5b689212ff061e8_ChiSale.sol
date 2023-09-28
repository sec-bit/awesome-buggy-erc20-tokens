pragma solidity ^0.4.19;

interface ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * Owned Contract
 * 
 * This is a contract trait to inherit from. Contracts that inherit from Owned 
 * are able to modify functions to be only callable by the owner of the
 * contract.
 * 
 * By default it is impossible to change the owner of the contract.
 */
contract Owned {
    /**
     * Contract owner.
     * 
     * This value is set at contract creation time.
     */
    address owner;

    /**
     * Contract constructor.
     * 
     * This sets the owner of the Owned contract at the time of contract
     * creation.
     */
    function Owned() public {
        owner = msg.sender;
    }

    /**
     * Modify method to only allow the owner to call it.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

/**
 * Aethia Chi Token Sale
 * 
 * This contract represent the 50% off sale for the in-game currency of Aethia.
 * The normal exchange rate in-game is 0.001 ETH for 1 CHI. During the sale, the
 * exchange rate will be 0.0005 ETH for 1 CHI.
 * 
 * The contract only exchanges whole (integer) values of CHI. If the sender
 * sends a value of 0.00051 ETH, the sender will get 1 CHI and 0.00001 ETH back.
 * 
 * In the case not enough CHI tokens remain to fully exchange the sender's value
 * from ETH to CHI, the remaining CHI will be paid out, and the remaining ETH
 * will be returned to the sender.
 */
contract ChiSale is Owned {
    /**
     * The CHI token contract.
     */
    ERC20 chiTokenContract;

    /**
     * The start date of the CHI sale in seconds since the UNIX epoch.
     * 
     * This is equivalent to February 17th, 12:00:00 UTC.
     */
    uint256 constant START_DATE = 1518868800;

    /**
     * The end date of the CHI sale in seconds since the UNIX epoch.
     * 
     * This is equivalent to February 19th, 12:00:00 UTC.
     */
    uint256 constant END_DATE = 1519041600;

    /**
     * The price per CHI token in ETH.
     */
    uint256 tokenPrice = 0.0005 ether;
    
    /**
     * The number of Chi tokens for sale.
     */
    uint256 tokensForSale = 10000000;

    /**
     * Chi token sale event.
     * 
     * For audit and logging purposes, all chi token sales are logged by 
     * acquirer.
     */
    event LogChiSale(address indexed _acquirer, uint256 _amount);

    /**
     * Contract constructor.
     * 
     * This passes the address of the Chi token contract address to the
     * Chi sale contract. Additionally it sets the owner to the contract 
     * creator.
     */
    function ChiSale(address _chiTokenAddress) Owned() public {
        chiTokenContract = ERC20(_chiTokenAddress);
    }

    /**
     * Buy Chi tokens.
     * 
     * The cost of a Chi token during the sale is 0.0005 ether per token. This
     * contract accepts any amount equal to or above 0.0005 ether. It tries to
     * exchange as many Chi tokens for the sent value as possible. The remaining
     * ether is sent back.
     *
     * In the case where not enough Chi tokens are available for the to exchange
     * for the entirety of the sent value, an attempt will be made to exchange
     * as much as possible. The remaining ether is then sent back.
     * 
     * The sale starts at February 17th, 12:00:00 UTC, and ends at February
     * 19th, 12:00:00 UTC, lasting a total of 48 hours. Transactions that occur
     * outside this time period are rejected.
     */
    function buy() payable external {
        require(START_DATE <= now);
        require(END_DATE >= now);
        require(tokensForSale > 0);
        require(msg.value >= tokenPrice);

        uint256 tokens = msg.value / tokenPrice;
        uint256 remainder;

        // If there aren't enough tokens to exchange, try to exchange as many
        // as possible, and pay out the remainder. Else, if there are enough
        // tokens, pay the remaining ether that couldn't be exchanged for tokens 
        // back to the sender.
        if (tokens > tokensForSale) {
            tokens = tokensForSale;

            remainder = msg.value - tokens * tokenPrice;
        } else {
            remainder = msg.value % tokenPrice;
        }
        
        tokensForSale -= tokens;

        LogChiSale(msg.sender, tokens);

        chiTokenContract.transfer(msg.sender, tokens);

        if (remainder > 0) {
            msg.sender.transfer(remainder);
        }
    }

    /**
     * Fallback payable method.
     *
     * This is in the case someone calls the contract without specifying the
     * correct method to call. This method will ensure the failure of a
     * transaction that was wrongfully executed.
     */
    function () payable external {
        revert();
    }

    /**
     * Withdraw all funds from contract.
     * 
     * Additionally, this moves all remaining Chi tokens back to the original
     * owner to be used for redistribution.
     */
    function withdraw() onlyOwner external {
        uint256 currentBalance = chiTokenContract.balanceOf(this);

        chiTokenContract.transfer(owner, currentBalance);

        owner.transfer(this.balance);
    }
    
    function remainingTokens() external view returns (uint256) {
        return tokensForSale;
    }
}