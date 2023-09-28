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
        super_owner = msg.sender; // DEBUG !!! 
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


contract STE {
    function totalSupply() public returns(uint256);
    function balanceOf(address _addr) public returns(uint256);
}


contract STE_Poll is owned {
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
    
    // Poll start and stop blocks
    uint256 public pStartBlock;
    uint256 public pStopBlock;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    // Constructor
    function STE_Poll() public {        
    	totalSupply = 0;
    	balanceOf[this] = totalSupply;
    	decimals = 8;
        
        name = "STE Poll";
        symbol = "STE(poll)";
        
        pStartBlock = block.number;
        pStopBlock = block.number + 20;
    }
    
    // Calls when send Ethereum to the contract
    function() internal payable {
        if ( balanceOf[msg.sender] > 0 ) revert();
        if ( ( block.number >= pStopBlock ) || ( block.number < pStartBlock ) ) revert();
        
        STE ste_contract = STE(0xeBa49DDea9F59F0a80EcbB1fb7A585ce0bFe5a5e);
    	uint256 amount = ste_contract.balanceOf(msg.sender);
    	
    	balanceOf[msg.sender] += amount;
        totalSupply += amount;
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
    
    // Set start and stop blocks of poll
    function setStartStopBlocks(uint256 _pStartBlock, uint256 _pStopBlock) public onlyOwner {
    	pStartBlock = _pStartBlock;
    	pStopBlock = _pStopBlock;
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
    
    function killPoll() public onlySuperOwner {
    	selfdestruct(foundersAddresses[0]);
    }
}