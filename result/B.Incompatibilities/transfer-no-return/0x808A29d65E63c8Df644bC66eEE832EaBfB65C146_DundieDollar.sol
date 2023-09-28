pragma solidity ^0.4.16;

contract Owned {
    
    address public owner;
    mapping(address => bool) public owners;

    function Owned() public {
        owner = msg.sender;
        owners[msg.sender] = true;
    }

    modifier onlyOwners{
        address sen = msg.sender;
        require(owners[msg.sender] == true);
        _;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerOrigin{
        require(tx.origin == owner);
        _;
    }

    function addOwner(address newOwner) public onlyOwners{
        owners[newOwner] = true;
    }

    function removeOwner() public onlyOwners{
        owners[msg.sender] = false;
    }

    function removeOwner(address newOwner) public onlyOwner{
        owners[newOwner] = false;
    }

    function isOwner(address o) public view returns(bool){
        return owners[o] == true;
    }
}

//Can be used by other contracts to get approval to spend tokens
interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}


contract TokenERC20 is Owned {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    event Burn(address indexed from, uint256 value);

    function TokenERC20(uint256 initialSupply,
		string tokenName,
		string tokenSymbol,
		uint8 dec) public {
        // totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        totalSupply = initialSupply; // Update total supply with the decimal amount
        balanceOf[this] = totalSupply; // Give the creator all initial tokens
        name = tokenName; // Set the name for display purposes
        symbol = tokenSymbol; // Set the symbol for display purposes
        decimals = dec;
    }


    function transfer(address _from, address _to, uint _value) internal {
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

    function transfer(address _to, uint256 _value) public {
        transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        allowance[_from][msg.sender] -= _value;
        transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns(bool success){
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public
	returns(bool success){
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns(bool success){
        require(balanceOf[msg.sender] >= _value); // Check if the sender has enough
        balanceOf[msg.sender] -= _value; // Subtract from the sender
        totalSupply -= _value; // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns(bool success){
        require(balanceOf[_from] >= _value); // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        balanceOf[_from] -= _value; // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value; // Subtract from the sender's allowance
        totalSupply -= _value; // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}


contract MifflinToken is Owned, TokenERC20 {
    
    uint8 public tokenId;
    uint256 ethDolRate = 1000;
    uint256 weiRate = 1000000000000000000;
    address exchange;
    uint256 public buyPrice;
    uint256 public totalContribution = 0;
    uint256 public highestContribution = 0;
    uint256 public lowestContribution = 2 ** 256 - 1;
    uint256 public totalBought = 0;
    mapping(address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    function MifflinToken(address exad,
		uint8 tid,
		uint256 issue,
		string tokenName,
		string tokenSymbol,
		uint8 dec)
		TokenERC20(issue * 10 ** uint256(dec), tokenName, tokenSymbol, dec) public {
        tokenId = tid;
        MifflinMarket e = MifflinMarket(exad);
        e.setToken(tokenId,this);
        exchange = exad;
        addOwner(exchange);
    }

    function buy(uint _value) internal {
        transfer(this, msg.sender, _value);
        totalBought += _value;
    }

    function transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0); // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] >= _value); // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]); // Check if sender is frozen
        require(!frozenAccount[_to]); // Check if recipient is frozen
        balanceOf[_from] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

    // public methods to give and take that only owners can call
    function give(address _to, uint256 _value) public onlyOwners returns(bool success){
        transfer(this, _to, _value);
        return true;
    }

    function take(address _from, uint256 _value) public onlyOwners returns(bool success){
        transfer(_from, this, _value);
        return true;
    }

    // / @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    // / @param target Address to be frozen
    // / @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) public onlyOwners{
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    // / @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    // / @param newBuyPrice Price users can buy from the contract
    function setBuyPrice(uint256 newBuyPrice) public onlyOwners{
        buyPrice = newBuyPrice;
    }

    // RULE we always lower the price any time there is a new high contribution!
    function contribution(uint256 amount)internal returns(int highlow){
        owner.transfer(msg.value);
        totalContribution += msg.value;
        if (amount > highestContribution) {
            uint256 oneper = buyPrice * 99 / 100; // lower by 1%*
            uint256 fullper = buyPrice *  highestContribution / amount; // lower by how much you beat the prior contribution
            if(fullper > oneper) buyPrice = fullper;
            else buyPrice = oneper;
            highestContribution = amount;
            // give reward
            MifflinMarket(exchange).highContributionAward(msg.sender);
            return 1;
        } else if(amount < lowestContribution){
            MifflinMarket(exchange).lowContributionAward(msg.sender);
            lowestContribution = amount;
            return -1;
        } else return 0;
    }

    // sell tokens back to sender using owners ether
    function sell(uint256 amount) public {
        transfer(msg.sender, this, amount); // makes the transfers
    }
}


/******************************************/
/*       CUSTOM MIFFLIN TOKENS       */
/******************************************/

contract BeetBuck is Owned, MifflinToken {
    function BeetBuck(address exchange)MifflinToken(exchange, 2, 2000000, "Beet Buck", "BEET", 8) public {
        buyPrice = weiRate / ethDolRate / uint(10) ** decimals; // 1d
    }

    function () payable public {
        contribution(msg.value);
        uint256 amountToGive = 0;
        uint256 price = buyPrice;
        if (totalBought < 10000) {
            price -= price * 15 / 100;
        } else if (totalBought < 50000) {
            price -= price / 10;
        } else if (totalBought < 100000) {
            price -= price / 20;
        } else if (totalBought < 200000) {
            price -= price / 100;
        }
        amountToGive += msg.value / price;
        buy(amountToGive);
    }
}


contract NapNickel is Owned, MifflinToken {

    function NapNickel(address exchange)
	MifflinToken(exchange, 3, 1000000000, "Nap Nickel", "NAPP", 8) public {
        buyPrice = weiRate / ethDolRate /  uint(10) ** decimals / 20; // 5c
    }

    function () payable public {
        contribution(msg.value);
        uint256 price = buyPrice;
        uint256 estTime = block.timestamp - 5 * 60 * 60;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 weekday;
        (, month,day,hour,,,weekday) = parseTimestampParts(estTime);
        if (month == 4 && day == 26) {
            // its pretzel day
            price += buyPrice / 5;
        } else if (weekday == 0 || weekday == 6) {
            // buying during weekend, get off my property
            price += buyPrice * 15 / 100;
        } else if (hour < 9 || hour >= 17) {
            // buying outside of work hours, im in my hot tub
            price += buyPrice / 10;
        } else if (hour > 12 && hour < 13) {
            // buying during lunch, leave me alone dammit
            price += buyPrice / 20;
        }
        uint256 amountToGive = 0;
        amountToGive += msg.value / price;
        buy(amountToGive);
    }
    
    struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }
        
        function parseTimestampParts(uint timestamp) public pure returns (uint16 year,uint8 month,uint8 day, uint8 hour,uint8 minute,uint8 second,uint8 weekday) {
            _DateTime memory dt = parseTimestamp(timestamp);
            return (dt.year,dt.month,dt.day,dt.hour,dt.minute,dt.second,dt.weekday);
        }


        function parseTimestamp(uint timestamp) internal pure returns (_DateTime dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

}


contract QuabityQuarter is Owned, MifflinToken {
    uint lastContributionTime = 0;

    function QuabityQuarter(address exchange)
	MifflinToken(exchange, 4, 420000000, "Quabity Quarter", "QUAB", 8) public {
        buyPrice = weiRate / ethDolRate / uint(10) ** decimals / 4; // 25c
    }

    function () payable public {
        contribution(msg.value);
        uint256 amountToGive = 0;
        amountToGive += msg.value / buyPrice;
        uint256 time = block.timestamp;
        uint256 diff = time - lastContributionTime / 60 / 60;
        uint256 chance = 0;
        if (diff > 96)
			chance = 50;
        if (diff > 48)
			chance = 40;
        else if (diff > 24)
			chance = 30;
        else if (diff > 12)
			chance = 20;
        else if (diff > 1)
			chance = 10;
        else chance = 5;
        if (chance > 0) {
            uint256 lastBlockHash = uint256(keccak256(block.blockhash(block.number - 1), uint8(0)));
            if (lastBlockHash % 100 < chance) {
                // stole 10% extra!
                amountToGive += amountToGive / 10;
            }}
        buy(amountToGive);
    }
}


contract KelevinKoin is Owned, MifflinToken {
    
    function KelevinKoin(address exchange)
	MifflinToken(exchange, 5, 69000000, "Kelevin Koin", "KLEV", 8) public {
        buyPrice = weiRate / ethDolRate / uint(10) ** decimals / 50; // 2c
    }

    function () payable public {
        contribution(msg.value);
        // have to balance the books!
        uint256 lastBlockHash = uint256(keccak256(block.blockhash(block.number - 1), uint8(0)));
        uint256 newPrice = buyPrice + ((lastBlockHash % (buyPrice * 69 / 1000)) - (buyPrice * 69 * 2 / 1000));
        buyPrice = newPrice;
        uint256 amountToGive = msg.value / buyPrice;
        if (buyPrice % msg.value == 0)
			amountToGive += amountToGive * 69 / 1000; // add 6.9%
        buy(amountToGive);
    }
}


contract NnexNote is Owned, MifflinToken {
    
    function NnexNote(address exchange) 
	MifflinToken(exchange, 6, 666000000, "Nnex Note", "NNEX", 8) public {
        buyPrice = weiRate / ethDolRate / uint(10) ** decimals / 100; // 1c
    }

    // Do you really want a Nnex Note?
    function () payable public {
        // this is the only place I have human contact, so the more the better
        contribution(msg.value);
        // you can get up to a 50% discount
        uint maxDiscountRange = buyPrice * 100;
        uint discountPercent;
        if(msg.value >= maxDiscountRange) discountPercent = 100;
        else discountPercent = msg.value / maxDiscountRange * 100;
        uint price = buyPrice - (buyPrice / 2) * (discountPercent / 100);
        uint amountToGive = msg.value / price;
        buy(amountToGive);
    }
}


contract DundieDollar is Owned, MifflinToken {
    mapping(uint8 => string) public awards;
    uint8 public awardsCount;
    mapping(address => mapping(uint8 => uint256)) public awardsOf;

    function DundieDollar(address exchange)
	MifflinToken(exchange, 1, 1725000000, "Dundie Dollar", "DUND", 0) public {
        buyPrice = weiRate / ethDolRate * 10; // 10d
        awards[0] = "Best Dad Award";
        awards[1] = "Best Mom Award";
        awards[2] = "Hottest in the Office Award";
        awards[3] = "Diabetes Award";
        awards[4] = "Promising Assistant Manager Award";
        awards[5] = "Cutest Redhead in the Office Award";
        awards[6] = "Best Host Award";
        awards[7] = "Doobie Doobie Pothead Stoner of the Year Award";
        awards[8] = "Extreme Repulsiveness Award";
        awards[9] = "Redefining Beauty Award";
        awards[10] = "Kind of A Bitch Award";
        awards[11] = "Moving On Up Award";
        awards[12] = "Worst Salesman of the Year";
        awards[13] = "Busiest Beaver Award";
        awards[14] = "Tight-Ass Award";
        awards[15] = "Spicy Curry Award";
        awards[16] = "Don't Go in There After Me";
        awards[17] = "Fine Work Award";
        awards[18] = "Whitest Sneakers Award";
        awards[19] = "Great Work Award";
        awards[20] = "Longest Engagement Award";
        awards[21] = "Show Me the Money Award";
        awards[22] = "Best Boss Award";
        awards[23] = "Grace Under Fire Award";
        awardsCount = 24;
    }

    function addAward(string name) public onlyOwners{
        awards[awardsCount] = name;
        awardsCount++;
    }

    function () payable public {
        contribution(msg.value);
        uint256 amountToGive = msg.value / buyPrice;
        buy(amountToGive);
    }

    function transfer(address _from, address _to, uint _value) internal {
        super.transfer(_from,_to,_value);
        transferAwards(_from,_to,_value);
    }

	//This should only be called from the above function
    function transferAwards(address _from, address _to, uint _value) internal {
        uint256 lastBlockHash = uint256(keccak256(block.blockhash(block.number - 1), uint8(0))) + _value;
        uint8 award = uint8(lastBlockHash % awardsCount);
        if(_from == address(this)) {
            //dont need to loop through awards
            transferAwards(_from,_to,award,_value);

        } else { // only take awards that they have
            uint left = _value;
      
      		for (uint8 i = 0; i < awardsCount; i++) {
                uint256 bal = awardBalanceOf(_from,award);
                if(bal > 0){
                    if(bal < left) {
                        transferAwards(_from,_to,award,bal);
                        left -= bal;
                    } else {
                    	transferAwards(_from,_to,award,left);
                        left = 0;
                    }
                }
                if(left == 0) break;
                award ++;
                if(award == awardsCount - 1) award = 0; // reset
            }
        }
    }
    
    function transferAwards(address from, address to, uint8 award , uint value) internal {
        //dont try to take specific awards from the contract
        if(from != address(this)) {
            require(awardBalanceOf(from,award) >= value );
            awardsOf[from][award] -= value;
        }
        //dont try to send specific awards to the contract
        if(to != address(this)) awardsOf[to][award] += value;
    }
    

    function awardBalanceOf(address addy,uint8 award) view public returns(uint){
        return awardsOf[addy][award];
    }
    
    function awardName(uint8 id) view public returns(string) {
        return awards[id];
    }
}


contract MifflinMarket is Owned {
    mapping(uint8 => address) public tokenIds;
    //mapping(uint8 => mapping(uint8 => uint256)) exchangeRates;
    mapping(uint8 => mapping(uint8 => int256)) public totalExchanged;
    uint8 rewardTokenId = 1;
    bool active;
    
     function MifflinMarket() public {
         active = true;
     }
    
     modifier onlyTokens {
        MifflinToken mt = MifflinToken(msg.sender);
        // make sure sender is a token contract
        require(tokenIds[mt.tokenId()] == msg.sender);
        _;
    }

    function setToken(uint8 tid,address addy) public onlyOwnerOrigin { // Only add tokens that were created by exchange owner
        tokenIds[tid] = addy;
    }

    function removeToken(uint8 id) public onlyOwner { // Only add tokens that were created by owner
        tokenIds[id] = 0;
    }
    
    function setActive(bool act) public onlyOwner {
        active = act;
    }

    function getRewardToken() public view returns(MifflinToken){
        return getTokenById(rewardTokenId);
    }

    function getTokenById(uint8 id) public view returns(MifflinToken){
        require(tokenIds[id] > 0);
        return MifflinToken(tokenIds[id]);
    }
    
    function getTokenByAddress(address addy) public view returns(MifflinToken){
        MifflinToken token = MifflinToken(addy);
        uint8 tokenId = token.tokenId();
        require(tokenIds[tokenId] == addy);
        return token;
    }

    function exchangeTokensByAddress(uint256 fromAmount, address from, address to) public {
        require(active);
        uint256 takeAmount = fromAmount;
        MifflinToken fromToken = getTokenByAddress(from);
        MifflinToken toToken = getTokenByAddress(to);
        uint8 fromId = fromToken.tokenId();
        uint8 toId = toToken.tokenId();
        uint256 fromPrice = fromToken.buyPrice();
        uint256 toPrice = toToken.buyPrice();
        uint256 toAmount = fromAmount * fromPrice / toPrice;
        takeAmount = toAmount * toPrice / fromPrice;
        // take fromTokens back to contract
        fromToken.take(msg.sender, takeAmount);
        // give toTokens out from contract
        toToken.give(msg.sender, toAmount);
        // update some stats
        totalExchanged[fromId][toId] += int(toAmount);
        totalExchanged[toId][fromId] -= int(takeAmount);
    }

    // most basic exchange - just calculates price ratio
    function exchangeTokensById(uint256 fromAmount, uint8 from, uint8 to) public {
        address fromAddress = tokenIds[from];
        address toAddress = tokenIds[to];
        exchangeTokensByAddress(fromAmount,fromAddress,toAddress);
	    //adjust price?
    }

    function highContributionAward(address to) public onlyTokens {
        MifflinToken reward = getRewardToken();
        //dont throw an error if there are no more tokens
        if(reward.balanceOf(reward) > 0){
            reward.give(to, 1);
        }
    }

    function lowContributionAward(address to) public onlyTokens {
        MifflinToken reward = getRewardToken();
        //dont throw an error here since this is just sugar
        if(reward.balanceOf(to) > 0){
            reward.take(to, 1);
        }
    }
}