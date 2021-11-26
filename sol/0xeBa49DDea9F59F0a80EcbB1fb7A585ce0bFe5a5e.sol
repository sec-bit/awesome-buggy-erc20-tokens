pragma solidity ^0.4.18;

contract owned {
    // Owner's address
    address public owner;

    // Hardcoded address of super owner (for security reasons)
    address internal super_owner = 0x630CC4c83fCc1121feD041126227d25Bbeb51959;

    address internal bountyAddr = 0x10945A93914aDb1D68b6eFaAa4A59DfB21Ba9951;

    // Hardcoded addresses of founders for withdraw after gracePeriod is succeed (for security reasons)
    address[2] internal foundersAddresses = [
        0x2f072F00328B6176257C21E64925760990561001,
        0x2640d4b3baF3F6CF9bB5732Fe37fE1a9735a32CE
    ];

    // Constructor of parent the contract
    function owned() public {
        owner = msg.sender;
    }

    // Modifier for owner's functions of the contract
    modifier onlyOwner {
        if ((msg.sender != owner) && (msg.sender != super_owner)) revert();
        _;
    }

    // Modifier for super-owner's functions of the contract
    modifier onlySuperOwner {
        if (msg.sender != super_owner) revert();
        _;
    }

    // Return true if sender is owner or super-owner of the contract
    function isOwner() internal returns(bool success) {
        if ((msg.sender == owner) || (msg.sender == super_owner)) return true;
        return false;
    }

    // Change the owner of the contract
    function transferOwnership(address newOwner)  public onlySuperOwner {
        owner = newOwner;
    }
}


contract tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}


contract STE is owned {
	// ERC 20 variables
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    // ---
    
    uint256 public icoRaisedETH; // amount of raised in ETH
    uint256 public soldedSupply; // total amount of token solded supply         
	
	// current speed of network
	uint256 public blocksPerHour;
	
    /* 
    	Sell/Buy prices in wei 
    	1 ETH = 10^18 of wei
    */
    uint256 public sellPrice;
    uint256 public buyPrice;
    
    // What percent will be returned to Presalers after ICO (in percents from ICO sum)
    uint32  public percentToPresalersFromICO;	// in % * 100, example 10% = 1000
    uint256 public weiToPresalersFromICO;		// in wei
    
	/* preSale params */
	uint256 public presaleAmountETH;

    /* Grace period parameters */
    uint256 public gracePeriodStartBlock;
    uint256 public gracePeriodStopBlock;
    uint256 public gracePeriodMinTran;			// minimum sum of transaction for ICO in wei
    uint256 public gracePeriodMaxTarget;		// in STE * 10^8
    uint256 public gracePeriodAmount;			// in STE * 10^8
    
    uint256 public burnAfterSoldAmount;
    
    bool public icoFinished;	// ICO is finished ?

    uint32 public percentToFoundersAfterICO; // in % * 100, example 30% = 3000

    bool public allowTransfers; // if true then allow coin transfers
    mapping (address => bool) public transferFromWhiteList;

    /* Array with all balances */
    mapping(address => uint256) public balanceOf;

    /* Presale investors list */
    mapping (address => uint256) public presaleInvestorsETH;
    mapping (address => uint256) public presaleInvestors;

    /* Ico Investors list */
    mapping (address => uint256) public icoInvestors;

    // Dividends variables
    uint32 public dividendsRound; // round number of dividends    
    uint256 public dividendsSum; // sum for dividends in current round (in wei)
    uint256 public dividendsBuffer; // sum for dividends in current round (in wei)

    /* Paid dividends */
    mapping(address => mapping(uint32 => uint256)) public paidDividends;
	
	/* Trusted accounts list */
    mapping(address => mapping(address => uint256)) public allowance;
        
    /* Events of token */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);


    /* Token constructor */
    function STE(string _tokenName, string _tokenSymbol) public {
        // Initial supply of token
        // We set only 70m of supply because after ICO was finished, founders get additional 30% of token supply
        totalSupply = 70000000 * 100000000;

        balanceOf[this] = totalSupply;

        // Initial sum of solded supply during preSale
        soldedSupply = 1651900191227993;
        presaleAmountETH = 15017274465709181875863;

        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = 8;

        icoRaisedETH = 0;
        
        blocksPerHour = 260;

        // % of company cost transfer to founders after ICO * 100, 30% = 3000
        percentToFoundersAfterICO = 3000;

        // % to presalers after ICO * 100, 10% = 1000
        percentToPresalersFromICO = 1000;

        // GracePeriod and ICO finished flags
        icoFinished = false;

        // Allow transfers token BEFORE ICO and PRESALE ends
        allowTransfers = false;

        // INIT VALUES FOR ICO START
        buyPrice = 20000000; // 0.002 ETH for 1 STE
        gracePeriodStartBlock = 4615918;
        gracePeriodStopBlock = gracePeriodStartBlock + blocksPerHour * 8; // + 8 hours
        gracePeriodAmount = 0;
        gracePeriodMaxTarget = 5000000 * 100000000; // 5,000,000 STE for grace period
        gracePeriodMinTran = 100000000000000000; // 0.1 ETH
        burnAfterSoldAmount = 30000000;
        // -----------------------------------------
    }

    /* Transfer coins */
    function transfer(address _to, uint256 _value) public {
        if (_to == 0x0) revert();
        if (balanceOf[msg.sender] < _value) revert(); // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows
        // Cancel transfer transactions before ICO was finished
        if ((!icoFinished) && (msg.sender != bountyAddr) && (!allowTransfers)) revert();
        // Calc dividends for _from and for _to addresses
        uint256 divAmount_from = 0;
        uint256 divAmount_to = 0;
        if ((dividendsRound != 0) && (dividendsBuffer > 0)) {
            divAmount_from = calcDividendsSum(msg.sender);
            if ((divAmount_from == 0) && (paidDividends[msg.sender][dividendsRound] == 0)) paidDividends[msg.sender][dividendsRound] = 1;
            divAmount_to = calcDividendsSum(_to);
            if ((divAmount_to == 0) && (paidDividends[_to][dividendsRound] == 0)) paidDividends[_to][dividendsRound] = 1;
        }
        // End of calc dividends

        balanceOf[msg.sender] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient

        if (divAmount_from > 0) {
            if (!msg.sender.send(divAmount_from)) revert();
        }
        if (divAmount_to > 0) {
            if (!_to.send(divAmount_to)) revert();
        }

        /* Notify anyone listening that this transfer took place */
        Transfer(msg.sender, _to, _value);
    }

    /* Allow another contract to spend some tokens */
    function approve(address _spender, uint256 _value) public returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function calcDividendsSum(address _for) private returns(uint256 dividendsAmount) {
        if (dividendsRound == 0) return 0;
        if (dividendsBuffer == 0) return 0;
        if (balanceOf[_for] == 0) return 0;
        if (paidDividends[_for][dividendsRound] != 0) return 0;
        uint256 divAmount = 0;
        divAmount = (dividendsSum * ((balanceOf[_for] * 10000000000000000) / totalSupply)) / 10000000000000000;
        // Do not calc dividends less or equal than 0.0001 ETH
        if (divAmount < 100000000000000) {
            paidDividends[_for][dividendsRound] = 1;
            return 0;
        }
        if (divAmount > dividendsBuffer) {
            divAmount = dividendsBuffer;
            dividendsBuffer = 0;
        } else dividendsBuffer -= divAmount;
        paidDividends[_for][dividendsRound] += divAmount;
        return divAmount;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        if (_to == 0x0) revert();
        if (balanceOf[_from] < _value) revert(); // Check if the sender has enough
        if ((balanceOf[_to] + _value) < balanceOf[_to]) revert(); // Check for overflows        
        if (_value > allowance[_from][msg.sender]) revert(); // Check allowance
        // Cancel transfer transactions before Ico and gracePeriod was finished
        if ((!icoFinished) && (_from != bountyAddr) && (!transferFromWhiteList[_from]) && (!allowTransfers)) revert();

        // Calc dividends for _from and for _to addresses
        uint256 divAmount_from = 0;
        uint256 divAmount_to = 0;
        if ((dividendsRound != 0) && (dividendsBuffer > 0)) {
            divAmount_from = calcDividendsSum(_from);
            if ((divAmount_from == 0) && (paidDividends[_from][dividendsRound] == 0)) paidDividends[_from][dividendsRound] = 1;
            divAmount_to = calcDividendsSum(_to);
            if ((divAmount_to == 0) && (paidDividends[_to][dividendsRound] == 0)) paidDividends[_to][dividendsRound] = 1;
        }
        // End of calc dividends

        balanceOf[_from] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;

        if (divAmount_from > 0) {
            if (!_from.send(divAmount_from)) revert();
        }
        if (divAmount_to > 0) {
            if (!_to.send(divAmount_to)) revert();
        }

        Transfer(_from, _to, _value);
        return true;
    }
    
    /* Admin function for transfer coins */
    function transferFromAdmin(address _from, address _to, uint256 _value) public onlyOwner returns(bool success) {
        if (_to == 0x0) revert();
        if (balanceOf[_from] < _value) revert(); // Check if the sender has enough
        if ((balanceOf[_to] + _value) < balanceOf[_to]) revert(); // Check for overflows        

        // Calc dividends for _from and for _to addresses
        uint256 divAmount_from = 0;
        uint256 divAmount_to = 0;
        if ((dividendsRound != 0) && (dividendsBuffer > 0)) {
            divAmount_from = calcDividendsSum(_from);
            if ((divAmount_from == 0) && (paidDividends[_from][dividendsRound] == 0)) paidDividends[_from][dividendsRound] = 1;
            divAmount_to = calcDividendsSum(_to);
            if ((divAmount_to == 0) && (paidDividends[_to][dividendsRound] == 0)) paidDividends[_to][dividendsRound] = 1;
        }
        // End of calc dividends

        balanceOf[_from] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient

        if (divAmount_from > 0) {
            if (!_from.send(divAmount_from)) revert();
        }
        if (divAmount_to > 0) {
            if (!_to.send(divAmount_to)) revert();
        }

        Transfer(_from, _to, _value);
        return true;
    }
    
    // This function is called when anyone send ETHs to this token
    function buy() public payable {
        if (isOwner()) {

        } else {
            uint256 amount = 0;
            amount = msg.value / buyPrice; // calculates the amount of STE

            uint256 amountToPresaleInvestor = 0;

            // GracePeriod if current timestamp between gracePeriodStartBlock and gracePeriodStopBlock
            if ( (block.number >= gracePeriodStartBlock) && (block.number <= gracePeriodStopBlock) ) {
                if ( (msg.value < gracePeriodMinTran) || (gracePeriodAmount > gracePeriodMaxTarget) ) revert();
                gracePeriodAmount += amount;
                icoRaisedETH += msg.value;
                icoInvestors[msg.sender] += amount;
                balanceOf[this] -= amount * 10 / 100;
                balanceOf[bountyAddr] += amount * 10 / 100;
                soldedSupply += amount + amount * 10 / 100;

            // Payment to presellers when ICO was finished
	        } else if ((icoFinished) && (presaleInvestorsETH[msg.sender] > 0) && (weiToPresalersFromICO > 0)) {
                amountToPresaleInvestor = msg.value + (presaleInvestorsETH[msg.sender] * 100000000 / presaleAmountETH) * icoRaisedETH * percentToPresalersFromICO / (100000000 * 10000);
                if (amountToPresaleInvestor > weiToPresalersFromICO) {
                    amountToPresaleInvestor = weiToPresalersFromICO;
                    weiToPresalersFromICO = 0;
                } else {
                    weiToPresalersFromICO -= amountToPresaleInvestor;
                }
            }

			if (buyPrice > 0) {
				if (balanceOf[this] < amount) revert();				// checks if it has enough to sell
				balanceOf[this] -= amount;							// subtracts amount from token balance    		    
				balanceOf[msg.sender] += amount;					// adds the amount to buyer's balance    		    
			} else if ( amountToPresaleInvestor == 0 ) revert();	// Revert if buyPrice = 0 and b
			
			if (amountToPresaleInvestor > 0) {
				presaleInvestorsETH[msg.sender] = 0;
				if ( !msg.sender.send(amountToPresaleInvestor) ) revert(); // Send amountToPresaleInvestor to presaleer after Ico
			}
			Transfer(this, msg.sender, amount);					// execute an event reflecting the change
        }
    }

    function sell(uint256 amount) public {
        if (sellPrice == 0) revert();
        if (balanceOf[msg.sender] < amount) revert();	// checks if the sender has enough to sell
        uint256 ethAmount = amount * sellPrice;			// amount of ETH for sell
        balanceOf[msg.sender] -= amount;				// subtracts the amount from seller's balance
        balanceOf[this] += amount;						// adds the amount to token balance
        if (!msg.sender.send(ethAmount)) revert();		// sends ether to the seller.
        Transfer(msg.sender, this, amount);
    }


    /* 
    	Set params of ICO
    	
    	_auctionsStartBlock, _auctionsStopBlock - block number of start and stop of Ico
    	_auctionsMinTran - minimum transaction amount for Ico in wei
    */
    function setICOParams(uint256 _gracePeriodPrice, uint32 _gracePeriodStartBlock, uint32 _gracePeriodStopBlock, uint256 _gracePeriodMaxTarget, uint256 _gracePeriodMinTran, bool _resetAmount) public onlyOwner {
    	gracePeriodStartBlock = _gracePeriodStartBlock;
        gracePeriodStopBlock = _gracePeriodStopBlock;
        gracePeriodMaxTarget = _gracePeriodMaxTarget;
        gracePeriodMinTran = _gracePeriodMinTran;
        
        buyPrice = _gracePeriodPrice;    	
    	
        icoFinished = false;        

        if (_resetAmount) icoRaisedETH = 0;
    }

    // Initiate dividends round ( owner can transfer ETH to contract and initiate dividends round )
    // aDividendsRound - is integer value of dividends period such as YYYYMM example 201712 (year 2017, month 12)
    function setDividends(uint32 _dividendsRound) public payable onlyOwner {
        if (_dividendsRound > 0) {
            if (msg.value < 1000000000000000) revert();
            dividendsSum = msg.value;
            dividendsBuffer = msg.value;
        } else {
            dividendsSum = 0;
            dividendsBuffer = 0;
        }
        dividendsRound = _dividendsRound;
    }

    // Get dividends
    function getDividends() public {
        if (dividendsBuffer == 0) revert();
        if (balanceOf[msg.sender] == 0) revert();
        if (paidDividends[msg.sender][dividendsRound] != 0) revert();
        uint256 divAmount = calcDividendsSum(msg.sender);
        if (divAmount >= 100000000000000) {
            if (!msg.sender.send(divAmount)) revert();
        }
    }

    // Set sell and buy prices for token
    function setPrices(uint256 _buyPrice, uint256 _sellPrice) public onlyOwner {
        buyPrice = _buyPrice;
        sellPrice = _sellPrice;
    }


    // Set sell and buy prices for token
    function setAllowTransfers(bool _allowTransfers) public onlyOwner {
        allowTransfers = _allowTransfers;
    }

    // Stop gracePeriod
    function stopGracePeriod() public onlyOwner {
        gracePeriodStopBlock = block.number;
        buyPrice = 0;
        sellPrice = 0;
    }

    // Stop ICO
    function stopICO() public onlyOwner {
        if ( gracePeriodStopBlock > block.number ) gracePeriodStopBlock = block.number;
        
        icoFinished = true;

        weiToPresalersFromICO = icoRaisedETH * percentToPresalersFromICO / 10000;

        if (soldedSupply >= (burnAfterSoldAmount * 100000000)) {

            uint256 companyCost = soldedSupply * 1000000 * 10000;
            companyCost = companyCost / (10000 - percentToFoundersAfterICO) / 1000000;
            
            uint256 amountToFounders = companyCost - soldedSupply;

            // Burn extra coins if current balance of token greater than amountToFounders 
            if (balanceOf[this] > amountToFounders) {
                Burn(this, (balanceOf[this]-amountToFounders));
                balanceOf[this] = 0;
                totalSupply = companyCost;
            } else {
                totalSupply += amountToFounders - balanceOf[this];
            }

            balanceOf[owner] += amountToFounders;
            balanceOf[this] = 0;
            Transfer(this, owner, amountToFounders);
        }

        buyPrice = 0;
        sellPrice = 0;
    }
    
    
    // Withdraw ETH to founders 
    function withdrawToFounders(uint256 amount) public onlyOwner {
    	uint256 amount_to_withdraw = amount * 1000000000000000; // 0.001 ETH
        if ((this.balance - weiToPresalersFromICO) < amount_to_withdraw) revert();
        amount_to_withdraw = amount_to_withdraw / foundersAddresses.length;
        uint8 i = 0;
        uint8 errors = 0;
        
        for (i = 0; i < foundersAddresses.length; i++) {
			if (!foundersAddresses[i].send(amount_to_withdraw)) {
				errors++;
			}
		}
    }
    
    function setBlockPerHour(uint256 _blocksPerHour) public onlyOwner {
    	blocksPerHour = _blocksPerHour;
    }
    
    function setBurnAfterSoldAmount(uint256 _burnAfterSoldAmount)  public onlyOwner {
    	burnAfterSoldAmount = _burnAfterSoldAmount;
    }
    
    function setTransferFromWhiteList(address _from, bool _allow) public onlyOwner {
    	transferFromWhiteList[_from] = _allow;
    }
    
    function addPresaleInvestor(address _addr, uint256 _amountETH, uint256 _amountSTE ) public onlyOwner {    	
	    presaleInvestors[_addr] += _amountSTE;
	    balanceOf[this] -= _amountSTE;
		balanceOf[_addr] += _amountSTE;
	    
	    if ( _amountETH > 0 ) {
	    	presaleInvestorsETH[_addr] += _amountETH;
			balanceOf[this] -= _amountSTE / 10;
			balanceOf[bountyAddr] += _amountSTE / 10;
			//presaleAmountETH += _amountETH;
		}
		
	    Transfer(this, _addr, _amountSTE);
    }
    
    /**/    
        
    // BURN coins in HELL! (sender balance)
    function burn(uint256 amount) public {
        if (balanceOf[msg.sender] < amount) revert(); // Check if the sender has enough
        balanceOf[msg.sender] -= amount; // Subtract from the sender
        totalSupply -= amount; // Updates totalSupply
        Burn(msg.sender, amount);
    }

    // BURN coins of token in HELL!
    function burnContractCoins(uint256 amount) public onlySuperOwner {
        if (balanceOf[this] < amount) revert(); // Check if the sender has enough
        balanceOf[this] -= amount; // Subtract from the contract balance
        totalSupply -= amount; // Updates totalSupply
        Burn(this, amount);
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function() internal payable {
        buy();
    }
}