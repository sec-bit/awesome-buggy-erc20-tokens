pragma solidity ^0.4.18;
/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// ERC20 token interface is implemented only partially.
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract NamiCrowdSale {
    using SafeMath for uint256;

    /// NAC Broker Presale Token
    /// @dev Constructor
    function NamiCrowdSale(address _escrow, address _namiMultiSigWallet, address _namiPresale) public {
        require(_namiMultiSigWallet != 0x0);
        escrow = _escrow;
        namiMultiSigWallet = _namiMultiSigWallet;
        namiPresale = _namiPresale;
    }


    /*/
     *  Constants
    /*/

    string public name = "Nami ICO";
    string public  symbol = "NAC";
    uint   public decimals = 18;

    bool public TRANSFERABLE = false; // default not transferable

    uint public constant TOKEN_SUPPLY_LIMIT = 1000000000 * (1 ether / 1 wei);
    
    uint public binary = 0;

    /*/
     *  Token state
    /*/

    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }

    Phase public currentPhase = Phase.Created;
    uint public totalSupply = 0; // amount of tokens already sold

    // escrow has exclusive priveleges to call administrative
    // functions on this contract.
    address public escrow;

    // Gathered funds can be withdrawn only to namimultisigwallet's address.
    address public namiMultiSigWallet;

    // nami presale contract
    address public namiPresale;

    // Crowdsale manager has exclusive priveleges to burn presale tokens.
    address public crowdsaleManager;
    
    // binary option address
    address public binaryAddress;
    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    modifier onlyCrowdsaleManager() {
        require(msg.sender == crowdsaleManager); 
        _; 
    }

    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }
    
    modifier onlyTranferable() {
        require(TRANSFERABLE);
        _;
    }
    
    modifier onlyNamiMultisig() {
        require(msg.sender == namiMultiSigWallet);
        _;
    }
    
    /*/
     *  Events
    /*/

    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogPhaseSwitch(Phase newPhase);
    // Log migrate token
    event LogMigrate(address _from, address _to, uint256 amount);
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /*/
     *  Public functions
    /*/

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    // Transfer the balance from owner's account to another account
    // only escrow can send token (to send token private sale)
    function transferForTeam(address _to, uint256 _value) public
        onlyEscrow
    {
        _transfer(msg.sender, _to, _value);
    }
    
    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public
        onlyTranferable
    {
        _transfer(msg.sender, _to, _value);
    }
    
       /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) 
        public
        onlyTranferable
        returns (bool success)
    {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        onlyTranferable
        returns (bool success) 
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        onlyTranferable
        returns (bool success) 
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    // allows transfer token
    function changeTransferable () public
        onlyEscrow
    {
        TRANSFERABLE = !TRANSFERABLE;
    }
    
    // change escrow
    function changeEscrow(address _escrow) public
        onlyNamiMultisig
    {
        require(_escrow != 0x0);
        escrow = _escrow;
    }
    
    // change binary value
    function changeBinary(uint _binary)
        public
        onlyEscrow
    {
        binary = _binary;
    }
    
    // change binary address
    function changeBinaryAddress(address _binaryAddress)
        public
        onlyEscrow
    {
        require(_binaryAddress != 0x0);
        binaryAddress = _binaryAddress;
    }
    
    /*
    * price in ICO:
    * first week: 1 ETH = 2400 NAC
    * second week: 1 ETH = 23000 NAC
    * 3rd week: 1 ETH = 2200 NAC
    * 4th week: 1 ETH = 2100 NAC
    * 5th week: 1 ETH = 2000 NAC
    * 6th week: 1 ETH = 1900 NAC
    * 7th week: 1 ETH = 1800 NAC
    * 8th week: 1 ETH = 1700 nac
    * time: 
    * 1517443200: Thursday, February 1, 2018 12:00:00 AM
    * 1518048000: Thursday, February 8, 2018 12:00:00 AM
    * 1518652800: Thursday, February 15, 2018 12:00:00 AM
    * 1519257600: Thursday, February 22, 2018 12:00:00 AM
    * 1519862400: Thursday, March 1, 2018 12:00:00 AM
    * 1520467200: Thursday, March 8, 2018 12:00:00 AM
    * 1521072000: Thursday, March 15, 2018 12:00:00 AM
    * 1521676800: Thursday, March 22, 2018 12:00:00 AM
    * 1522281600: Thursday, March 29, 2018 12:00:00 AM
    */
    function getPrice() public view returns (uint price) {
        if (now < 1517443200) {
            // presale
            return 3450;
        } else if (1517443200 < now && now <= 1518048000) {
            // 1st week
            return 2400;
        } else if (1518048000 < now && now <= 1518652800) {
            // 2nd week
            return 2300;
        } else if (1518652800 < now && now <= 1519257600) {
            // 3rd week
            return 2200;
        } else if (1519257600 < now && now <= 1519862400) {
            // 4th week
            return 2100;
        } else if (1519862400 < now && now <= 1520467200) {
            // 5th week
            return 2000;
        } else if (1520467200 < now && now <= 1521072000) {
            // 6th week
            return 1900;
        } else if (1521072000 < now && now <= 1521676800) {
            // 7th week
            return 1800;
        } else if (1521676800 < now && now <= 1522281600) {
            // 8th week
            return 1700;
        } else {
            return binary;
        }
    }


    function() payable public {
        buy(msg.sender);
    }
    
    
    function buy(address _buyer) payable public {
        // Available only if presale is running.
        require(currentPhase == Phase.Running);
        // require ICO time or binary option
        require(now <= 1522281600 || msg.sender == binaryAddress);
        require(msg.value != 0);
        uint newTokens = msg.value * getPrice();
        require (totalSupply + newTokens < TOKEN_SUPPLY_LIMIT);
        // add new token to buyer
        balanceOf[_buyer] = balanceOf[_buyer].add(newTokens);
        // add new token to totalSupply
        totalSupply = totalSupply.add(newTokens);
        LogBuy(_buyer,newTokens);
        Transfer(this,_buyer,newTokens);
    }
    

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function burnTokens(address _owner) public
        onlyCrowdsaleManager
    {
        // Available only during migration phase
        require(currentPhase == Phase.Migrating);

        uint tokens = balanceOf[_owner];
        require(tokens != 0);
        balanceOf[_owner] = 0;
        totalSupply -= tokens;
        LogBurn(_owner, tokens);
        Transfer(_owner, crowdsaleManager, tokens);

        // Automatically switch phase when migration is done.
        if (totalSupply == 0) {
            currentPhase = Phase.Migrated;
            LogPhaseSwitch(Phase.Migrated);
        }
    }


    /*/
     *  Administrative functions
    /*/
    function setPresalePhase(Phase _nextPhase) public
        onlyEscrow
    {
        bool canSwitchPhase
            =  (currentPhase == Phase.Created && _nextPhase == Phase.Running)
            || (currentPhase == Phase.Running && _nextPhase == Phase.Paused)
                // switch to migration phase only if crowdsale manager is set
            || ((currentPhase == Phase.Running || currentPhase == Phase.Paused)
                && _nextPhase == Phase.Migrating
                && crowdsaleManager != 0x0)
            || (currentPhase == Phase.Paused && _nextPhase == Phase.Running)
                // switch to migrated only if everyting is migrated
            || (currentPhase == Phase.Migrating && _nextPhase == Phase.Migrated
                && totalSupply == 0);

        require(canSwitchPhase);
        currentPhase = _nextPhase;
        LogPhaseSwitch(_nextPhase);
    }


    function withdrawEther(uint _amount) public
        onlyEscrow
    {
        require(namiMultiSigWallet != 0x0);
        // Available at any phase.
        if (this.balance > 0) {
            namiMultiSigWallet.transfer(_amount);
        }
    }
    
    function safeWithdraw(address _withdraw, uint _amount) public
        onlyEscrow
    {
        NamiMultiSigWallet namiWallet = NamiMultiSigWallet(namiMultiSigWallet);
        if (namiWallet.isOwner(_withdraw)) {
            _withdraw.transfer(_amount);
        }
    }


    function setCrowdsaleManager(address _mgr) public
        onlyEscrow
    {
        // You can't change crowdsale contract when migration is in progress.
        require(currentPhase != Phase.Migrating);
        crowdsaleManager = _mgr;
    }

    // internal migrate migration tokens
    function _migrateToken(address _from, address _to)
        internal
    {
        PresaleToken presale = PresaleToken(namiPresale);
        uint256 newToken = presale.balanceOf(_from);
        require(newToken > 0);
        // burn old token
        presale.burnTokens(_from);
        // add new token to _to
        balanceOf[_to] = balanceOf[_to].add(newToken);
        // add new token to totalSupply
        totalSupply = totalSupply.add(newToken);
        LogMigrate(_from, _to, newToken);
        Transfer(this,_to,newToken);
    }

    // migate token function for Nami Team
    function migrateToken(address _from, address _to) public
        onlyEscrow
    {
        _migrateToken(_from, _to);
    }

    // migrate token for investor
    function migrateForInvestor() public {
        _migrateToken(msg.sender, msg.sender);
    }

    // Nami internal exchange
    
    // event for Nami exchange
    event TransferToBuyer(address indexed _from, address indexed _to, uint _value, address indexed _seller);
    event TransferToExchange(address indexed _from, address indexed _to, uint _value, uint _price);
    
    
    /**
     * @dev Transfer the specified amount of tokens to the NamiExchange address.
     *      Invokes the `tokenFallbackExchange` function.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallbackExchange` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _price price to sell token.
     */
     
    function transferToExchange(address _to, uint _value, uint _price) public {
        uint codeLength;
        
        assembly {
            codeLength := extcodesize(_to)
        }
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender,_to,_value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallbackExchange(msg.sender, _value, _price);
            TransferToExchange(msg.sender, _to, _value, _price);
        }
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the NamiExchange address.
     *      Invokes the `tokenFallbackBuyer` function.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallbackBuyer` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _buyer address of seller.
     */
     
    function transferToBuyer(address _to, uint _value, address _buyer) public {
        uint codeLength;
        
        assembly {
            codeLength := extcodesize(_to)
        }
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender,_to,_value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallbackBuyer(msg.sender, _value, _buyer);
            TransferToBuyer(msg.sender, _to, _value, _buyer);
        }
    }
//-------------------------------------------------------------------------------------------------------
}


/*
* Binary option smart contract-------------------------------
*/
contract BinaryOption {
    /*
     * binary option controled by escrow to buy NAC with good price
     */
    // NamiCrowdSale address
    address public namiCrowdSaleAddr;
    address public escrow;
    
    // namiMultiSigWallet
    address public namiMultiSigWallet;
    
    Session public session;
    uint public timeInvestInMinute = 10;
    uint public timeOneSession = 15;
    uint public sessionId = 1;
    uint public rateWin = 100;
    uint public rateLoss = 20;
    uint public rateFee = 5;
    uint public constant MAX_INVESTOR = 20;
    uint public minimunEth = 10000000000000000; // minimunEth = 0.01 eth
    /**
     * Events for binany option system
     */
    event SessionOpen(uint timeOpen, uint indexed sessionId);
    event InvestClose(uint timeInvestClose, uint priceOpen, uint indexed sessionId);
    event Invest(address indexed investor, bool choose, uint amount, uint timeInvest, uint indexed sessionId);
    event SessionClose(uint timeClose, uint indexed sessionId, uint priceClose, uint nacPrice, uint rateWin, uint rateLoss, uint rateFee);

    event Deposit(address indexed sender, uint value);
    /// @dev Fallback function allows to deposit ether.
    function() public payable {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }
    // there is only one session available at one timeOpen
    // priceOpen is price of ETH in USD
    // priceClose is price of ETH in USD
    // process of one Session
    // 1st: escrow reset session by run resetSession()
    // 2nd: escrow open session by run openSession() => save timeOpen at this time
    // 3rd: all investor can invest by run invest(), send minimum 0.1 ETH
    // 4th: escrow close invest and insert price open for this Session
    // 5th: escrow close session and send NAC for investor
    struct Session {
        uint priceOpen;
        uint priceClose;
        uint timeOpen;
        bool isReset;
        bool isOpen;
        bool investOpen;
        uint investorCount;
        mapping(uint => address) investor;
        mapping(uint => bool) win;
        mapping(uint => uint) amountInvest;
    }
    
    function BinaryOption(address _namiCrowdSale, address _escrow, address _namiMultiSigWallet) public {
        require(_namiCrowdSale != 0x0 && _escrow != 0x0);
        namiCrowdSaleAddr = _namiCrowdSale;
        escrow = _escrow;
        namiMultiSigWallet = _namiMultiSigWallet;
    }
    
    
    modifier onlyEscrow() {
        require(msg.sender==escrow);
        _;
    }
    
        
    modifier onlyNamiMultisig() {
        require(msg.sender == namiMultiSigWallet);
        _;
    }
    
    // change escrow
    function changeEscrow(address _escrow) public
        onlyNamiMultisig
    {
        require(_escrow != 0x0);
        escrow = _escrow;
    }
    
    // chagne minimunEth
    function changeMinEth(uint _minimunEth) public 
        onlyEscrow
    {
        require(_minimunEth != 0);
        minimunEth = _minimunEth;
    }
    
    /// @dev Change time for investor can invest in one session, can only change at time not in session
    /// @param _timeInvest time invest in minutes
    ///---------------------------change time function------------------------------
    function changeTimeInvest(uint _timeInvest)
        public
        onlyEscrow
    {
        require(!session.isOpen && _timeInvest < timeOneSession);
        timeInvestInMinute = _timeInvest;
    }

    function changeTimeOneSession(uint _timeOneSession) 
        public
        onlyEscrow
    {
        require(!session.isOpen && _timeOneSession > timeInvestInMinute);
        timeOneSession = _timeOneSession;
    }

    /////------------------------change rate function-------------------------------
    
    function changeRateWin(uint _rateWin)
        public
        onlyEscrow
    {
        require(!session.isOpen);
        rateWin = _rateWin;
    }
    
    function changeRateLoss(uint _rateLoss)
        public
        onlyEscrow
    {
        require(!session.isOpen);
        rateLoss = _rateLoss;
    }
    
    function changeRateFee(uint _rateFee)
        public
        onlyEscrow
    {
        require(!session.isOpen);
        rateFee = _rateFee;
    }
    
    
    /// @dev withdraw ether to nami multisignature wallet, only escrow can call
    /// @param _amount value ether in wei to withdraw
    function withdrawEther(uint _amount) public
        onlyEscrow
    {
        require(namiMultiSigWallet != 0x0);
        // Available at any phase.
        if (this.balance > 0) {
            namiMultiSigWallet.transfer(_amount);
        }
    }
    
    /// @dev safe withdraw Ether to one of owner of nami multisignature wallet
    /// @param _withdraw address to withdraw
    function safeWithdraw(address _withdraw, uint _amount) public
        onlyEscrow
    {
        NamiMultiSigWallet namiWallet = NamiMultiSigWallet(namiMultiSigWallet);
        if (namiWallet.isOwner(_withdraw)) {
            _withdraw.transfer(_amount);
        }
    }
    
    // @dev Returns list of owners.
    // @return List of owner addresses.
    // MAX_INVESTOR = 20
    function getInvestors()
        public
        view
        returns (address[20])
    {
        address[20] memory listInvestor;
        for (uint i = 0; i < MAX_INVESTOR; i++) {
            listInvestor[i] = session.investor[i];
        }
        return listInvestor;
    }
    
    function getChooses()
        public
        view
        returns (bool[20])
    {
        bool[20] memory listChooses;
        for (uint i = 0; i < MAX_INVESTOR; i++) {
            listChooses[i] = session.win[i];
        }
        return listChooses;
    }
    
    function getAmount()
        public
        view
        returns (uint[20])
    {
        uint[20] memory listAmount;
        for (uint i = 0; i < MAX_INVESTOR; i++) {
            listAmount[i] = session.amountInvest[i];
        }
        return listAmount;
    }
    
    /// @dev reset all data of previous session, must run before open new session
    // only escrow can call
    function resetSession()
        public
        onlyEscrow
    {
        require(!session.isReset && !session.isOpen);
        session.priceOpen = 0;
        session.priceClose = 0;
        session.isReset = true;
        session.isOpen = false;
        session.investOpen = false;
        session.investorCount = 0;
        for (uint i = 0; i < MAX_INVESTOR; i++) {
            session.investor[i] = 0x0;
            session.win[i] = false;
            session.amountInvest[i] = 0;
        }
    }
    
    /// @dev Open new session, only escrow can call
    function openSession ()
        public
        onlyEscrow
    {
        require(session.isReset && !session.isOpen);
        session.isReset = false;
        // open invest
        session.investOpen = true;
        session.timeOpen = now;
        session.isOpen = true;
        SessionOpen(now, sessionId);
    }
    
    /// @dev Fuction for investor, minimun ether send is 0.1, one address can call one time in one session
    /// @param _choose choise of investor, true is call, false is put
    function invest (bool _choose)
        public
        payable
    {
        require(msg.value >= minimunEth && session.investOpen); // msg.value >= 0.1 ether
        require(now < (session.timeOpen + timeInvestInMinute * 1 minutes));
        require(session.investorCount < MAX_INVESTOR);
        session.investor[session.investorCount] = msg.sender;
        session.win[session.investorCount] = _choose;
        session.amountInvest[session.investorCount] = msg.value;
        session.investorCount += 1;
        Invest(msg.sender, _choose, msg.value, now, sessionId);
    }
    
    /// @dev close invest for escrow
    /// @param _priceOpen price ETH in USD
    function closeInvest (uint _priceOpen) 
        public
        onlyEscrow
    {
        require(_priceOpen != 0 && session.investOpen);
        require(now > (session.timeOpen + timeInvestInMinute * 1 minutes));
        session.investOpen = false;
        session.priceOpen = _priceOpen;
        InvestClose(now, _priceOpen, sessionId);
    }
    
    /// @dev get amount of ether to buy NAC for investor
    /// @param _ether amount ether which investor invest
    /// @param _status true for investor win and false for investor loss
    function getEtherToBuy (uint _ether, bool _status)
        public
        view
        returns (uint)
    {
        if (_status) {
            return _ether * rateWin / 100;
        } else {
            return _ether * rateLoss / 100;
        }
    }

    /// @dev close session, only escrow can call
    /// @param _priceClose price of ETH in USD
    function closeSession (uint _priceClose)
        public
        onlyEscrow
    {
        require(_priceClose != 0 && now > (session.timeOpen + timeOneSession * 1 minutes));
        require(!session.investOpen && session.isOpen);
        session.priceClose = _priceClose;
        bool result = (_priceClose>session.priceOpen)?true:false;
        uint etherToBuy;
        NamiCrowdSale namiContract = NamiCrowdSale(namiCrowdSaleAddr);
        uint price = namiContract.getPrice();
        require(price != 0);
        for (uint i = 0; i < session.investorCount; i++) {
            if (session.win[i]==result) {
                etherToBuy = (session.amountInvest[i] - session.amountInvest[i] * rateFee / 100) * rateWin / 100;
                uint etherReturn = session.amountInvest[i] - session.amountInvest[i] * rateFee / 100;
                (session.investor[i]).transfer(etherReturn);
            } else {
                etherToBuy = (session.amountInvest[i] - session.amountInvest[i] * rateFee / 100) * rateLoss / 100;
            }
            namiContract.buy.value(etherToBuy)(session.investor[i]);
            // reset investor
            session.investor[i] = 0x0;
            session.win[i] = false;
            session.amountInvest[i] = 0;
        }
        session.isOpen = false;
        SessionClose(now, sessionId, _priceClose, price, rateWin, rateLoss, rateFee);
        sessionId += 1;
        
        // require(!session.isReset && !session.isOpen);
        // reset state session
        session.priceOpen = 0;
        session.priceClose = 0;
        session.isReset = true;
        session.investOpen = false;
        session.investorCount = 0;
    }
}


contract PresaleToken {
    mapping (address => uint256) public balanceOf;
    function burnTokens(address _owner) public;
}

 /*
 * Contract that is working with ERC223 tokens
 */
 
 /**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract {
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool success);
    function tokenFallbackBuyer(address _from, uint _value, address _buyer) public returns (bool success);
    function tokenFallbackExchange(address _from, uint _value, uint _price) public returns (bool success);
}


 /*
 * Nami Internal Exchange smartcontract-----------------------------------------------------------------
 *
 */

contract NamiExchange {
    using SafeMath for uint;
    
    function NamiExchange(address _namiAddress) public {
        NamiAddr = _namiAddress;
    }

    event UpdateBid(address owner, uint price, uint balance);
    event UpdateAsk(address owner, uint price, uint volume);
    event BuyHistory(address indexed buyer, address indexed seller, uint price, uint volume, uint time);
    event SellHistory(address indexed seller, address indexed buyer, uint price, uint volume, uint time);

    
    mapping(address => OrderBid) public bid;
    mapping(address => OrderAsk) public ask;
    string public name = "NacExchange";
    
    /// address of Nami token
    address public NamiAddr;
    
    /// price of Nac = ETH/NAC
    uint public price = 1;
    // struct store order of user
    struct OrderBid {
        uint price;
        uint eth;
    }
    
    struct OrderAsk {
        uint price;
        uint volume;
    }
    
        
    // prevent lost ether
    function() payable public {
        require(msg.data.length != 0);
        require(msg.value == 0);
    }
    
    modifier onlyNami {
        require(msg.sender == NamiAddr);
        _;
    }
    
    /////////////////
    //---------------------------function about bid Order-----------------------------------------------------------
    
    function placeBuyOrder(uint _price) payable public {
        require(_price > 0 && msg.value > 0 && bid[msg.sender].eth == 0);
        if (msg.value > 0) {
            bid[msg.sender].eth = (bid[msg.sender].eth).add(msg.value);
            bid[msg.sender].price = _price;
            UpdateBid(msg.sender, _price, bid[msg.sender].eth);
        }
    }
    
    function sellNac(uint _value, address _buyer, uint _price) public returns (bool success) {
        require(_price == bid[_buyer].price && _buyer != msg.sender);
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        uint ethOfBuyer = bid[_buyer].eth;
        uint maxToken = ethOfBuyer.mul(bid[_buyer].price);
        require(namiToken.allowance(msg.sender, this) >= _value && _value > 0 && ethOfBuyer != 0 && _buyer != 0x0);
        if (_value > maxToken) {
            if (msg.sender.send(ethOfBuyer) && namiToken.transferFrom(msg.sender,_buyer,maxToken)) {
                // update order
                bid[_buyer].eth = 0;
                UpdateBid(_buyer, bid[_buyer].price, bid[_buyer].eth);
                BuyHistory(_buyer, msg.sender, bid[_buyer].price, maxToken, now);
                return true;
            } else {
                // revert anything
                revert();
            }
        } else {
            uint eth = _value.div(bid[_buyer].price);
            if (msg.sender.send(eth) && namiToken.transferFrom(msg.sender,_buyer,_value)) {
                // update order
                bid[_buyer].eth = (bid[_buyer].eth).sub(eth);
                UpdateBid(_buyer, bid[_buyer].price, bid[_buyer].eth);
                BuyHistory(_buyer, msg.sender, bid[_buyer].price, _value, now);
                return true;
            } else {
                // revert anything
                revert();
            }
        }
    }
    
    function closeBidOrder() public {
        require(bid[msg.sender].eth > 0 && bid[msg.sender].price > 0);
        // transfer ETH
        msg.sender.transfer(bid[msg.sender].eth);
        // update order
        bid[msg.sender].eth = 0;
        UpdateBid(msg.sender, bid[msg.sender].price, bid[msg.sender].eth);
    }
    

    ////////////////
    //---------------------------function about ask Order-----------------------------------------------------------
    
    // place ask order by send NAC to Nami Exchange contract
    // this function place sell order
    function tokenFallbackExchange(address _from, uint _value, uint _price) onlyNami public returns (bool success) {
        require(_price > 0 && _value > 0 && ask[_from].volume == 0);
        if (_value > 0) {
            ask[_from].volume = (ask[_from].volume).add(_value);
            ask[_from].price = _price;
            UpdateAsk(_from, _price, ask[_from].volume);
        }
        return true;
    }
    
    function closeAskOrder() public {
        require(ask[msg.sender].volume > 0 && ask[msg.sender].price > 0);
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        uint previousBalances = namiToken.balanceOf(msg.sender);
        // transfer token
        namiToken.transfer(msg.sender, ask[msg.sender].volume);
        // update order
        ask[msg.sender].volume = 0;
        UpdateAsk(msg.sender, ask[msg.sender].price, 0);
        // check balance
        assert(previousBalances < namiToken.balanceOf(msg.sender));
    }
    
    function buyNac(address _seller, uint _price) payable public returns (bool success) {
        require(msg.value > 0 && ask[_seller].volume > 0 && ask[_seller].price > 0);
        require(_price == ask[_seller].price && _seller != msg.sender);
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        uint maxEth = (ask[_seller].volume).div(ask[_seller].price);
        uint previousBalances = namiToken.balanceOf(msg.sender);
        if (msg.value > maxEth) {
            if (_seller.send(maxEth) && msg.sender.send(msg.value.sub(maxEth))) {
                // transfer token
                namiToken.transfer(msg.sender, ask[_seller].volume);
                SellHistory(_seller, msg.sender, ask[_seller].price, ask[_seller].volume, now);
                // update order
                ask[_seller].volume = 0;
                UpdateAsk(_seller, ask[_seller].price, 0);
                assert(previousBalances < namiToken.balanceOf(msg.sender));
                return true;
            } else {
                // revert anything
                revert();
            }
        } else {
            uint nac = (msg.value).mul(ask[_seller].price);
            if (_seller.send(msg.value)) {
                // transfer token
                namiToken.transfer(msg.sender, nac);
                // update order
                ask[_seller].volume = (ask[_seller].volume).sub(nac);
                UpdateAsk(_seller, ask[_seller].price, ask[_seller].volume);
                SellHistory(_seller, msg.sender, ask[_seller].price, nac, now);
                assert(previousBalances < namiToken.balanceOf(msg.sender));
                return true;
            } else {
                // revert anything
                revert();
            }
        }
    }
}

contract ERC23 {
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool success);
}



/*
* NamiMultiSigWallet smart contract-------------------------------
*/
/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
contract NamiMultiSigWallet {

    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(!(ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0));
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function() public payable {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function NamiMultiSigWallet(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i = 0; i < _owners.length; i++) {
            require(!(isOwner[_owners[i]] || _owners[i] == 0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param owner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            // Transaction tx = transactions[transactionId];
            transactions[transactionId].executed = true;
            // tx.executed = true;
            if (transactions[transactionId].destination.call.value(transactions[transactionId].value)(transactions[transactionId].data)) {
                Execution(transactionId);
            } else {
                ExecutionFailure(transactionId);
                transactions[transactionId].executed = false;
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination, 
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
        }
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed)
                count += 1;
        }
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
    }
}