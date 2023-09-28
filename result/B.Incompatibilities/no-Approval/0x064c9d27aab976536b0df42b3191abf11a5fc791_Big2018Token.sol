pragma solidity ^0.4.16;

/*
\/\/\/\/\/\/\/\WELCOME TO BIG 2018 TOKEN/\/\/\/\/\/\/\/
This token is the first stage in a revolutionary new 
distributed game where the odds are forever in your 
favour yet similar to poker where chip leads give you
the edge; BIG2018TOKEN will play a similar role.


\/\/\/\/\/\/\/\/THE PRICE CAN ONLY GO UP\/\/\/\/\/\/\/\/
This smart contract will only allow a limited number of 
tokens to be bought each day. Once they are gone, you 
will have to wait for the next days release, yet the 
price will go up each day. This is set so the price will
rise 2.7%/DAY (the best I can get from my bank each yr)
or x2.25 each month. Rounded this gives:
    Day001 = 0.00010 Eth
    Day050 = 0.00037 Eth
    Day100 = 0.00138 Eth
    Day150 = 0.00528 Eth
    Day200 = 0.02003 Eth
    Day250 = 0.07633 Eth
    Day300 = 0.28959 Eth
    Day350 = 1.10048 Eth
    Day365 = 1.64232 Eth
    Day366(2019) no longer available :(
 
 This price increase will be to benifit the super early
 birds who work closley with Ethereum and likely to find
 this smart contract hidden away and able to call it 
 directly before word spreads to the wider masses and a
 UI and promotion gets involved later in the year.
*/
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Big2018Token {
    ////////////////////////////////////////////////////////
    //Intitial Parameters
    /**********Admin**********/
    address public creator;  //keep track of creator
    /**********DailyRelease**********/
    uint256 public tokensDaily = 10000; //max tokens available each day
    uint256 tokensToday = 0; //no tokens given out today
    uint256 public leftToday = 10000; //tokens left to sell today
    uint startPrice = 100000000000000; //COMPOUND INCREASE: Wei starter price that will be compounded
    uint q = 37; //COMPOUND INCREASE: for (1+1/q) multipler rate of 1.027 per day
    uint countBuy = 0; //count times bought
    uint start2018 = 1514764800; //when tokens become available 
    uint end2018 = 1546300799; //last second tokens available
    uint day = 1; //what day is it
    uint d = 86400; //sedonds in a day
    uint dayOld = 1; //counter to kep track of last day tokens were given
    /**********GameUsage**********/
    address public game;  //address of Game later in year
    mapping (address => uint) public box; //record each persons box choice
    uint boxRand = 0; //To start with random assignment of box used later in year, ignore use for token
    uint boxMax = 5; //Max random random assignment to box used later in year, ignore use for token
    event BoxChange(address who, uint newBox); //event that notifies of a box change in game
    /**********ERC20**********/
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf; //record who owns what
    event Transfer(address indexed from, address indexed to, uint256 value);// This generates a public event on the blockchain that will notify clients
    event Burn(address indexed from, uint256 value); // This notifies clients about the amount burnt
    mapping (address => mapping (address => uint256)) public allowance;
    /**********EscrowTrades**********/
    struct EscrowTrade {
        uint256 value; //value of number or tokens for sale
        uint price; //min purchase price from seller
        address to; //specify who is to purchase the tokens
        bool open; //anyone can purchase rather than named buyer. false = closed. true = open to all.
    }
    mapping (address => mapping (uint => EscrowTrade)) public escrowTransferInfo;
    mapping (address => uint) userEscrowCount;
    event Escrow(address from, uint256 value, uint price, bool open, address to); // This notifies clients about the escrow
    struct EscrowTfr {
        address from; //who has defined this escrow trade
        uint tradeNo; //trade number this user has made
    }
    EscrowTfr[] public escrowTransferList; //make an array of the escrow trades to be looked up
    uint public escrowCount = 0;

    ////////////////////////////////////////////////////////
    //Run at start
    function Big2018Token() public {
        creator = msg.sender; //store sender as creator
        game = msg.sender; //to be updated once game released with game address
        totalSupply = 3650000 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[this] = totalSupply;     // Give the creator all initial tokens
        name = "BIG2018TOKEN";                // Set the name for display purposes
        symbol = "B18";                       // Set the symbol for display purposes
    }

    ////////////////////////////////////////////////////////
    //The Price of the Token Each Day. 0 = today
    function getPriceWei(uint _day) public returns (uint) {
        require(now >= start2018 && now <= end2018); //must be in 2018
        day = (now - start2018)/d + 1; //count number of days since opening
        if (day > dayOld) {  //resent counter if first tx per day
            uint256 _value = ((day - dayOld - 1)*tokensDaily + leftToday) * 10 ** uint256(decimals);
            _transfer(this, creator, _value); //give remaining tokens from previous day to creator
            tokensToday = 0; //reset no of tokens sold today, this wont stick as 'veiw' f(x). will be saved in buy f(x)
            dayOld = day; //reset dayOld counter
        }
        if (_day != 0) { //if _day = 0, calculate price for today
        day = _day; //which day should be calculated
        }
        // Computes 'startPrice * (1+1/q) ^ n' with precision p, needed as solidity does not allow decimal for compounding
            //q & startPrice defined at top
            uint n = day - 1; //n of days to compound the multipler by
            uint p = 3 + n * 5 / 100; //itterations to calculate compound daily multiplier. higher is greater precision but more expensive
            uint s = 0; //output. itterativly added to for result
            uint x = 1; //multiply side of binomial expansion
            uint y = 1; //divide side of binomial expansion
            //itterate top q lines binomial expansion to estimate compound multipler
            for (uint i = 0; i < p; ++i) { //each itteration gets closer, higher p = closer approximation but more costly
                s += startPrice * x / y / (q**i); //iterate adding each time to s
                x = x * (n-i); //calc multiply side
                y = y * (i+1); //calc divide side
            }
            return (s); //return priceInWei = s
    }

    ////////////////////////////////////////////////////////
    //Giving New Tokens To Buyer
    function () external payable {
        // must buy whole token when minting new here, but can buy/sell fractions between eachother
        require(now >= start2018 && now <= end2018); //must be in 2018
        uint priceWei = this.getPriceWei(0); //get todays price
        uint256 giveTokens = msg.value / priceWei; //rounds down to no of tokens that can afford
            if (tokensToday + giveTokens > tokensDaily) { //if asking for tokens than left today
                giveTokens = tokensDaily - tokensToday;    //then limit giving to remaining tokens
                }
        countBuy += 1; //count usage
        tokensToday += giveTokens; //count whole tokens issued today
        box[msg.sender] = this.boxChoice(0); //assign box number to buyer
        _transfer(this, msg.sender, giveTokens * 10 ** uint256(decimals)); //transfer tokens from this contract
        uint256 changeDue = msg.value - (giveTokens * priceWei) * 99 / 100; //calculate change due, charged 1% to disincentivise high volume full refund calls.
        require(changeDue < msg.value); //make sure refund is not more than input
        msg.sender.transfer(changeDue); //give change
        
    }

    ////////////////////////////////////////////////////////
    //To Find Users Token Ammount and Box number
    function getValueAndBox(address _address) view external returns(uint, uint) {
        return (balanceOf[_address], box[_address]);
    }

    ////////////////////////////////////////////////////////
    //For transfering tokens to others
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0); // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] >= _value); // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        uint previousbalanceOf = balanceOf[_from] + balanceOf[_to]; // Save this for an assertion in the future
        balanceOf[_from] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousbalanceOf); // Asserts are used to use static analysis to find bugs in your code. They should never fail
    }

    ////////////////////////////////////////////////////////
    //Transfer tokens
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    ////////////////////////////////////////////////////////
    //Transfer tokens from other address
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    ////////////////////////////////////////////////////////
    //Set allowance for other address
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    ////////////////////////////////////////////////////////
    //Set allowance for other address and notify
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    ////////////////////////////////////////////////////////
    //Decide or change box used in game
    function boxChoice(uint _newBox) public returns (uint) { 
        //for _newBox = 0 assign random 
        boxRand += 1; //count up for even start box assingment
        if (boxRand > boxMax) { //stop box assignment too high
                    boxRand = 1; //return to box 1
            }
        if (_newBox == 0) {
            box[msg.sender] = boxRand; //give new random assignment to owner (or this if buying)
        } else {
        box[msg.sender] = _newBox; //give new assignment to owner (or this if buying)
        }
        BoxChange(msg.sender, _newBox); //let everyone know
            return (box[msg.sender]); //output to console
    }

    ////////////////////////////////////////////////////////
    //Release the funds for expanding project
    //Payable to re-top up contract
    function fundsOut() payable public { 
        require(msg.sender == creator); //only alow creator to take out
        creator.transfer(this.balance); //take the lot, can pay back into this via different address if wished re-top up
    }

    ////////////////////////////////////////////////////////
    //Used to tweak and update for Game
    function update(uint _option, uint _newNo, address _newAddress) public returns (string, uint) {
        require(msg.sender == creator || msg.sender == game); //only alow creator or game to use
        //change Max Box Choice
        if (_option == 1) {
            require(_newNo > 0);
            boxMax = _newNo;
            return ("boxMax Updated", boxMax);
        }
        //change address of game smart contract
        if (_option == 2) {
            game = _newAddress;
            return ("Game Smart Contract Updated", 1);
        }
    }

    ////////////////////////////////////////////////////////
    //Destroy tokens
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    ////////////////////////////////////////////////////////
    //Destroy tokens from other account
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }

    ////////////////////////////////////////////////////////
    //For trsnsfering tokens to others using this SC to enure they pay    
    function setEscrowTransfer(address _to, uint _value, uint _price, bool _open) external returns (bool success) {
            //_to to specify a address who can purchase
            //_open if anyone can purchase (set _to to any address)
            //_price is min asking value for full value of tokens
            //_value is number of tokens available
            //_to, who will purchase value of tokens
        _transfer(msg.sender, this, _value); //store _value in this contract
        userEscrowCount[msg.sender] += 1;
        var escrowTrade = escrowTransferInfo[msg.sender][userEscrowCount[msg.sender]]; //record transfer option details
        escrowTrade.value += _value;//add value into retaining store for trade
        escrowTrade.price = _price; //set asking price
        escrowTrade.to = _to; //who will purchase
        escrowTrade.open = _open; //is trade open to all. false = closed. true = open to anyone.
        escrowCount += 1;
        escrowTransferList.push(EscrowTfr(msg.sender, userEscrowCount[msg.sender]));
        Escrow(msg.sender, _value, _price, _open, _to); // This notifies clients about the escrow
        return (true); //success!
    }
    
    ////////////////////////////////////////////////////////
    //For purchasing tokens from others using this SC to give trust to purchase
    function recieveEscrowTransfer(address _sender, uint _no) external payable returns (bool success) { 
            //_sender is person buying from
            require(escrowTransferInfo[_sender][_no].value != 0); //end if trade already completed
        box[msg.sender] = this.boxChoice(box[msg.sender]); //assign box number to buyer
        if (msg.sender == _sender) {
            _transfer(this, msg.sender, escrowTransferInfo[_sender][_no].value); //put tokens back to sender account
            escrowTransferInfo[_sender][_no].value = 0; //reset counter for escrow token
            Escrow(_sender, 0, msg.value, escrowTransferInfo[_sender][_no].open, msg.sender); // This notifies clients about the escrow
            return (true);
        } else {
            require(msg.value >= escrowTransferInfo[_sender][_no].price); //Check _to is Paying Enough
            if (escrowTransferInfo[_sender][_no].open == false) {
                require(msg.sender == escrowTransferInfo[_sender][_no].to); //Check _to is the intended purchaser
                }
            _transfer(this, msg.sender, escrowTransferInfo[_sender][_no].value);   
            _sender.transfer(msg.value); //Send the sender the value of the trade
            escrowTransferInfo[_sender][_no].value = 0; //no more in retaining store
            Escrow(_sender, 0, msg.value, escrowTransferInfo[_sender][_no].open, msg.sender); // This notifies clients about the escrow
            return (true); //success!
        }
    }
}