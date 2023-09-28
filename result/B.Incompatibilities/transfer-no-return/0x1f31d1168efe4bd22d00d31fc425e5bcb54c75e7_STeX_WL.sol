pragma solidity ^0.4.19;

contract owned {
    // Owner's address
    address public owner;

    // Hardcoded address of super owner (for security reasons)
    address internal super_owner = 0x630CC4c83fCc1121feD041126227d25Bbeb51959;
    
    // Hardcoded addresses of founders for withdraw after gracePeriod is succeed (for security reasons)
    address[2] internal foundersAddresses = [
        0x2f072F00328B6176257C21E64925760990561001,
        0x2640d4b3baF3F6CF9bB5732Fe37fE1a9735a32CE
    ];

    // Constructor of parent the contract
    function owned() public {
        owner = msg.sender;
        super_owner = msg.sender;
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


contract STeX_WL is owned {
	// ERC20 
	string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    // ---
    
    uint256 public ethRaised;
    uint256 public soldSupply;
    uint256 public curPrice;
    uint256 public minBuyPrice;
    uint256 public maxBuyPrice;
    
    // White list start and stop blocks
    uint256 public wlStartBlock;
    uint256 public wlStopBlock;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    // Constructor
    function STeX_WL() public {        
    	totalSupply = 1000000000000000; // 10M with decimal = 8
    	balanceOf[this] = totalSupply;
    	soldSupply = 0;
        decimals = 8;
        
        name = "STeX White List";
        symbol = "STE(WL)";
        
        minBuyPrice = 20500000; // min price is 0.00205 ETH for 1 STE
        maxBuyPrice = 24900000; // max price is 0.00249 ETH for 1 STE
        curPrice = minBuyPrice;
        
        wlStartBlock = 5071809;
        wlStopBlock = wlStartBlock + 287000;
    }
    
    // Calls when send Ethereum to the contract
    function() internal payable {
    	if ( msg.value < 100000000000000000 ) revert(); // min transaction is 0.1 ETH
    	if ( ( block.number >= wlStopBlock ) || ( block.number < wlStartBlock ) ) revert();    	
    	
    	uint256 add_by_blocks = (((block.number-wlStartBlock)*1000000)/(wlStopBlock-wlStartBlock)*(maxBuyPrice-minBuyPrice))/1000000;
    	uint256 add_by_solded = ((soldSupply*1000000)/totalSupply*(maxBuyPrice-minBuyPrice))/1000000;
    	
    	// The price is calculated from blocks and sold supply
    	if ( add_by_blocks > add_by_solded ) {
    		curPrice = minBuyPrice + add_by_blocks;
    	} else {
    		curPrice = minBuyPrice + add_by_solded;
    	}
    	
    	if ( curPrice > maxBuyPrice ) curPrice = maxBuyPrice;
    	
    	uint256 amount = msg.value / curPrice;
    	
    	if ( balanceOf[this] < amount ) revert();
    	
    	balanceOf[this] -= amount;
        balanceOf[msg.sender] += amount;
        soldSupply += amount;
        ethRaised += msg.value;
    	
        Transfer(0x0, msg.sender, amount);
    }
    
	// ERC20 transfer
    function transfer(address _to, uint256 _value) public {
    	revert();
    }

	// ERC20 approve
    function approve(address _spender, uint256 _value) public returns(bool success) {
        revert();
    }

	// ERC20 transferFrom
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
    	revert();
    }
    
    // Admin function
    function transferFromAdmin(address _from, address _to, uint256 _value) public onlyOwner returns(bool success) {
        if (_to == 0x0) revert();
        if (balanceOf[_from] < _value) revert();
        if ((balanceOf[_to] + _value) < balanceOf[_to]) revert(); // Check for overflows

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        Transfer(_from, _to, _value);
        return true;
    }
    
    // Set min/max prices
    function setPrices(uint256 _minBuyPrice, uint256 _maxBuyPrice) public onlyOwner {
    	minBuyPrice = _minBuyPrice;
    	maxBuyPrice = _maxBuyPrice;
    }
    
    // Set start and stop blocks of White List
    function setStartStopBlocks(uint256 _wlStartBlock, uint256 _wlStopBlock) public onlyOwner {
    	wlStartBlock = _wlStartBlock;
    	wlStopBlock = _wlStopBlock;
    }
    
    // Withdraw
    function withdrawToFounders(uint256 amount) public onlyOwner {
    	uint256 amount_to_withdraw = amount * 1000000000000000; // 0.001 ETH
        if (this.balance < amount_to_withdraw) revert();
        amount_to_withdraw = amount_to_withdraw / foundersAddresses.length;
        uint8 i = 0;
        uint8 errors = 0;
        
        for (i = 0; i < foundersAddresses.length; i++) {
			if (!foundersAddresses[i].send(amount_to_withdraw)) {
				errors++;
			}
		}
    }
    
    // Remove white list contract after STE will be distributed
    function afterSTEDistributed() public onlySuperOwner {
    	uint256 amount_to_withdraw = this.balance;
        amount_to_withdraw = amount_to_withdraw / foundersAddresses.length;
        uint8 i = 0;
        uint8 errors = 0;
        
        for (i = 0; i < foundersAddresses.length; i++) {
			if (!foundersAddresses[i].send(amount_to_withdraw)) {
				errors++;
			}
		}
		
    	suicide(foundersAddresses[0]);
    }
}