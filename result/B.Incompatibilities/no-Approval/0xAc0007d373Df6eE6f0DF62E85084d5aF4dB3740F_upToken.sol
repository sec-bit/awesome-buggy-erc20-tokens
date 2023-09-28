pragma solidity ^0.4.18;

/*

Official ANN thread https://bitcointalk.org/index.php?topic=2785585.0
Official Website https://uptoken.online

IMAGINE a token that can only increase in price. 
A really truly cannot-go-down upToken.
This is an ERC20 token, an Ethereum based emulation of the Bitcoin ecosystem but with investor protection functions.
The purpose of this token is to show how Bitcoin works and provide an even better investment opportunity than Ethereum other than by simply holding on to the coin itself.

BUY: When you buy upTokens, your funds are stored in a contract and only you can retrieve them by sending upToken tokens back to the contract.
SEND: You can send tokens to another Ethereum address.
SELL: You can cash-out at any time and receive back the VALUE of the token, which is simply the exact share of all funds in the contract, less 10% discount. However, if there were no incoming transactions in the contract for the last 5,000 blocks (about 1 day) then you will receive your funds without a 10% discount.

There are no pre mined supplies and upToken tokens are  ONLY created in exchange for the ETH received.
There is No chance to cheat on the system, No admin rights to the contract - No holes.
The code is transparent and can be checked by everyone for validity and fairness.
The price of the upToken is set in ETH and CANNOT GO DOWN!

Every subsequent purchase transaction has a price that is slightly higher than the previous one.
It is  as SAFE as Ethereum, SECURE as Blockchain and as PROFITABLE as Bitcoin but with a LOWER RISK!
The most you can loose is 10% which is the premium paid at the purchase, and even with a "panic sale" you can NEVER lose more than the 10% discount.
If you wait, the VALUE of the upToken will grow with EVERY transaction.
Whenever there is a purchase of upTokens, 10% from this is divided between ALL token owners, including you.
When upTokens are sold early, the 10% discount is divided between ALL the remaining token owners.
Every time someone sells upTokens for the true value, the value of the remained token stays the same! No rush to go out.

As it is a valid ERC20 token, it can be traded and transferred without limitations. It can be listed on the exchanges. After the deployment, its future is in your hands - nobody can control the contract, except for all the token holders with their transactions. There are no administrators, no owners, no support and no possibility to be cheat on, it is a truly a decentralized autonomous system.

The longer you stay, the BIGGER your share. 
You cannot be late to cash-out.
Send ETH to this contract and upTokens will be sent in return with the same transaction to the wallet you sent ETH from. You should send only from your own wallet, not from an exchange's account.

*/

contract upToken{
	// This is ERC20 Token	
    string public name;
    string public symbol;
    uint8 public decimals;
    string public standard = 'Token 0.1';
    uint256 public totalSupply;
    
    /*
    	The price at which tokens are sold
    	
    	tokenPrice is multiplied on 10^9 for precision
		
		tokenPrice 100000000 = 1 ETH per 10000 PNS
    */
    uint256 public tokenPrice;

	/*
		The price at which the contract redeems tokens
		
		redeemPrice is multiplied on 10^9 for precision				
	*/
    uint256 public redeemPrice;
    
	/*
		Last transaction block number
	*/
    uint256 public lastTxBlockNum;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    /* 
    	Contract constructor, this token with decimal = 18 and init price = 1 ETH
    */
    function upToken() public {        
        name = "upToken";
        symbol = "UPT";
        decimals = 15;
        totalSupply = 0;

		// Initial pons price is 1 ETH per 10000 PNS
        tokenPrice = 100000000;
    }
    
	/*
		Transfer tokens and redeem
		
		When you transfer tokens to the contract it redeem it by current redeemPrice
	*/
    function transfer(address _to, uint256 _value) public {
    	if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        
        uint256 avp = 0;
        uint256 amount = 0;
        
        // Redeem tokens
        if ( _to == address(this) ) {
        	/*
				Calc amount of ETH, divide on 10^9 because reedemPrice is multiplied for precision
				
				If the block number after 5000 from the last transaction to the contract, then redeem price is average price
        	*/
        	if ( lastTxBlockNum < (block.number-5000) ) {
        		avp = this.balance * 1000000000 / totalSupply;
        		amount = ( _value * avp ) / 1000000000;
        	} else {
	        	amount = ( _value * redeemPrice ) / 1000000000;
	        }
        	balanceOf[msg.sender] -= _value;
        	totalSupply -= _value;
        	        	
        	/*
    			Calc new prices
	    	*/
	    	if ( totalSupply != 0 ) {
	    		avp = (this.balance-amount) * 1000000000 / totalSupply;
    			redeemPrice = ( avp * 900 ) / 1000;  // -10%
	    		tokenPrice = ( avp * 1100 ) / 1000;  // +10%
	    	} else {
				redeemPrice = 0;
	    		tokenPrice = 100000000;
        	}
        	if (!msg.sender.send(amount)) revert();
        	Transfer(msg.sender, 0x0, _value);
        } else {
        	balanceOf[msg.sender] -= _value;
	        balanceOf[_to] += _value;
        	Transfer(msg.sender, _to, _value);
        }        
    }

    function approve(address _spender, uint256 _value) public returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        if (balanceOf[_from] < _value) revert();
        if ((balanceOf[_to] + _value) < balanceOf[_to]) revert();
        if (_value > allowance[_from][msg.sender]) revert();

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);
        return true;
    }
    
    /*
    	Payable function, calls when send ETHs to the contract
    */
    function() internal payable {
    	// If sent ETH value of transaction less than 10 Gwei then revert tran
    	if ( msg.value < 10000000000 ) revert();
    	
    	lastTxBlockNum = block.number;
    	
    	uint256 amount = ( msg.value / tokenPrice ) * 1000000000;
    	balanceOf[msg.sender] += amount;
    	totalSupply += amount;
    	
    	/*
    		Calc new prices
    	*/
    	uint256 avp = this.balance * 1000000000 / totalSupply;
    	redeemPrice = avp * 900 / 1000;  // -10%
    	tokenPrice = avp * 1100 / 1000;  // +10%
    	
        Transfer(0x0, msg.sender, amount);
    }
}