pragma solidity ^ 0.4.17;

contract SafeMath {
    function safeMul(uint a, uint b) pure internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) pure internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) pure internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}




contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) 
            owner = newOwner;
    }

    function kill() public {
        if (msg.sender == owner) 
            selfdestruct(owner);
    }

    modifier onlyOwner() {
        if (msg.sender == owner)
            _;
    }
}

contract Pausable is Ownable {
    bool public stopped;

    modifier stopInEmergency {
        if (stopped) {
            revert();
        }
        _;
    }

    modifier onlyInEmergency {
        if (!stopped) {
            revert();
        }
        _;
    }

    // Called by the owner in emergency, triggers stopped state
    function emergencyStop() external onlyOwner {
        stopped = true;
    }

    // Called by the owner to end of emergency, returns to normal state
    function release() external onlyOwner onlyInEmergency {
        stopped = false;
    }
}


contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns(uint);

    function allowance(address owner, address spender) public view returns(uint);

    function transfer(address to, uint value) public returns(bool ok);

    function transferFrom(address from, address to, uint value) public returns(bool ok);

    function approve(address spender, uint value) public returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract Token is ERC20, SafeMath, Ownable {

    function transfer(address _to, uint _value) public returns(bool);
}

// Presale Smart Contract
// This smart contract collects ETH and in return sends tokens to the backers
contract Presale is SafeMath, Pausable {

    struct Backer {
        uint weiReceived; // amount of ETH contributed
        uint tokensToSend; // amount of tokens  sent
        bool claimed;
        bool refunded;
    }
   
    address public multisig; // Multisig contract that will receive the ETH    
    uint public ethReceived; // Number of ETH received
    uint public tokensSent; // Number of tokens sent to ETH contributors
    uint public startBlock; // Presale start block
    uint public endBlock; // Presale end block

    uint public minInvestment; // Minimum amount to invest
    uint public maxInvestment; // Maximum investment
    bool public presaleClosed; // Is presale still on going     
    uint public tokenPriceWei; // price of token in wei
    Token public token; // addresss of token contract


    mapping(address => Backer) public backers; //backer list
    address[] public backersIndex;  // to be able to iterate through backer list
    uint public maxCap;  // max cap
    uint public claimCount;  // number of contributors claming tokens
    uint public refundCount;  // number of contributors receivig refunds
    uint public totalClaimed;  // total of tokens claimed
    uint public totalRefunded;  // total of tokens refunded
    bool public mainSaleSuccessfull; // true if main sale was successfull
    mapping(address => uint) public claimed; // Tokens claimed by contibutors
    mapping(address => uint) public refunded; // Tokens refunded to contributors


    // @notice to verify if action is not performed out of the campaing range
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) 
            revert();
        _;
    }

    // @notice overwrting this function to ensure that money if any     is returned to authorized party. 
    function kill() public {
        if (msg.sender == owner) 
            selfdestruct(multisig);
    }


    // Events
    event ReceivedETH(address backer, uint amount, uint tokenAmount);
    event TokensClaimed(address backer, uint count);
    event Refunded(address backer, uint amount);



    // Presale  {constructor}
    // @notice fired when contract is crated. Initilizes all needed variables.
    function Presale() public {        
        multisig = 0xF821Fd99BCA2111327b6a411C90BE49dcf78CE0f; 
        minInvestment = 5e17;  // 0.5 eth
        maxInvestment = 75 ether;      
        maxCap = 82500000e18;
        startBlock = 0; // Should wait for the call of the function start
        endBlock = 0; // Should wait for the call of the function start       
        tokenPriceWei = 1100000000000000;      
        tokensSent = 2534559883e16;         
    }

    // @notice​ ​return​ ​ number​ of​ ​contributors
    //​ ​@return​ ​ ​{uint}​ ​ number​ ​ of contributors
    function numberOfBackers() public view returns(uint) {
        return backersIndex.length;
    }

    // @notice to populate website with status of the sale 
    function returnWebsiteData() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, uint, bool, bool) {
    
        return (startBlock, endBlock, numberOfBackers(), ethReceived, maxCap, tokensSent, tokenPriceWei, minInvestment, maxInvestment, stopped, presaleClosed );
    }

    // @notice called to mark contributors when tokens are transfered to them after ICO manually. 
    // @param _backer {address} address of beneficiary
    function claimTokensForUser(address _backer) onlyOwner() external returns(bool) {

        require (!backer.refunded); // if refunded, don't allow tokens to be claimed           
        require (!backer.claimed); // if tokens claimed, don't allow to be claimed again            
        require (backer.tokensToSend != 0); // only continue if there are any tokens to send        
        Backer storage backer = backers[_backer];
        backer.claimed = true;  // mark record as claimed

        if (!token.transfer(_backer, backer.tokensToSend)) 
            revert(); // send claimed tokens to contributor account

        TokensClaimed(msg.sender, backer.tokensToSend);  
        return true;
    }


    // {fallback function}
    // @notice It will call internal function which handels allocation of Ether and calculates PPP tokens.
    function () public payable {
        contribute(msg.sender);
    }

    // @notice in case refunds are needed, money can be returned to the contract
    function fundContract() external payable onlyOwner() returns (bool) {
        mainSaleSuccessfull = false;
        return true;
    }

    // @notice It will be called by owner to start the sale    
    // block numbers will be calculated based on current block time average. 
    function start(uint _block) external onlyOwner() {
        require(_block < 54000);  // 2.5*60*24*15 days = 54000  
        startBlock = block.number;
        endBlock = safeAdd(startBlock, _block);   
    }

    // @notice Due to changing average of block time
    // this function will allow on adjusting duration of campaign closer to the end 
    // @param _block  number of blocks representing duration 
    function adjustDuration(uint _block) external onlyOwner() {
        
        require(_block <= 72000);  // 2.5*60*24*20 days = 72000     
        require(_block > safeSub(block.number, startBlock)); // ensure that endBlock is not set in the past
        endBlock = safeAdd(startBlock, _block);   
    }

    


    // @notice set the address of the token contract
    // @param _token  {Token} address of the token contract
    function setToken(Token _token) public onlyOwner() returns(bool) {

        token = _token;
        mainSaleSuccessfull = true;
        return true;
    }

    // @notice sets status of main ICO
    // @param _status {bool} true if public ICO was successful
    function setMainCampaignStatus(bool _status) public onlyOwner() {
        mainSaleSuccessfull = _status;
    }

    // @notice It will be called by fallback function whenever ether is sent to it
    // @param  _contributor {address} address of beneficiary
    // @return res {bool} true if transaction was successful

    function contribute(address _contributor) internal stopInEmergency respectTimeFrame returns(bool res) {
         
        require (msg.value >= minInvestment && msg.value <= maxInvestment);  // ensure that min and max contributions amount is met
                   
        uint tokensToSend = calculateNoOfTokensToSend();
        
        require (safeAdd(tokensSent, tokensToSend) <= maxCap);  // Ensure that max cap hasn't been reached

        Backer storage backer = backers[_contributor];

        if (backer.weiReceived == 0)
            backersIndex.push(_contributor);

        backer.tokensToSend = safeAdd(backer.tokensToSend, tokensToSend);
        backer.weiReceived = safeAdd(backer.weiReceived, msg.value);
        ethReceived = safeAdd(ethReceived, msg.value); // Update the total Ether recived
        tokensSent = safeAdd(tokensSent, tokensToSend);

        multisig.transfer(msg.value);  // send money to multisignature wallet

        ReceivedETH(_contributor, msg.value, tokensToSend); // Register event
        return true;
    }

    // @notice It is called by contribute to determine amount of tokens for given contribution    
    // @return tokensToPurchase {uint} value of tokens to purchase

    function calculateNoOfTokensToSend() view internal returns(uint) {
         
        uint tokenAmount = safeMul(msg.value, 1e18) / tokenPriceWei;
        uint ethAmount = msg.value;

        if (ethAmount >= 50 ether)
            return tokenAmount + (tokenAmount * 5) / 100;  // 5% percent bonus
        else if (ethAmount >= 15 ether)
            return tokenAmount + (tokenAmount * 25) / 1000; // 2.5% percent bonus
        else 
            return tokenAmount;
    }

    // @notice This function will finalize the sale.
    // It will only execute if predetermined sale time passed 

    function finalize() external onlyOwner() {

        require (!presaleClosed);           
        require (block.number >= endBlock);                          
        presaleClosed = true;
    }


    // @notice contributors can claim tokens after public ICO is finished
    // tokens are only claimable when token address is available. 

    function claimTokens() external {

        require(mainSaleSuccessfull);
       
        require (token != address(0));  // address of the token is set after ICO
                                        // claiming of tokens will be only possible once address of token
                                        // is set through setToken
           
        Backer storage backer = backers[msg.sender];

        require (!backer.refunded); // if refunded, don't allow for another refund           
        require (!backer.claimed); // if tokens claimed, don't allow refunding            
        require (backer.tokensToSend != 0);   // only continue if there are any tokens to send           

        claimCount++;
        claimed[msg.sender] = backer.tokensToSend;  // save claimed tokens
        backer.claimed = true;
        totalClaimed = safeAdd(totalClaimed, backer.tokensToSend);
        
        if (!token.transfer(msg.sender, backer.tokensToSend)) 
            revert(); // send claimed tokens to contributor account

        TokensClaimed(msg.sender, backer.tokensToSend);  
    }

    // @notice allow refund when ICO failed
    // In such a case contract will need to be funded. 
    // Until contract is funded this function will throw

    function refund() external {

        require(!mainSaleSuccessfull);  // ensure that ICO failed
        require(this.balance > 0);  // contract will hold 0 ether at the end of campaign.                                  
                                    // contract needs to be funded through fundContract() 
        Backer storage backer = backers[msg.sender];

        require (!backer.claimed); // check if tokens have been allocated already                   
        require (!backer.refunded); // check if user has been already refunded     
        require(backer.weiReceived != 0);  // check if user has actually sent any contributions        

        backer.refunded = true; // mark contributor as refunded. 
        totalRefunded = safeAdd(totalRefunded, backer.weiReceived);
        refundCount ++;
        refunded[msg.sender] = backer.weiReceived;

        msg.sender.transfer(backer.weiReceived);  // refund contribution        
        Refunded(msg.sender, backer.weiReceived); // log event
    }


    // @notice Failsafe drain
    function drain() external onlyOwner() {
        multisig.transfer(this.balance);
            
    }
}