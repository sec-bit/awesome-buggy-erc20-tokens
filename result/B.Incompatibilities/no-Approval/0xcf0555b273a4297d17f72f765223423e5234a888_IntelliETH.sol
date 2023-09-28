pragma solidity ^0.4.10;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

/**
 * @title Owned
 * @dev Owner contract to add owner checks
 */
contract Owned {
	address public owner;

	function Owned () {
		owner = msg.sender;	
	}	

	function transferOwner(address newOwner) public onlyOwner {
		owner = newOwner;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
}

/**
 * @title Payload
 * @dev Fix for the ERC20 short address attack.
 */
contract Payload {
	modifier onlyPayloadSize(uint size) {
		// require(msg.data.length >= size + 4);
		_;
  	}
}

contract IntelliETHConstants {
	uint256 constant PRE_ICO_ALLOCATION = 6;
	uint256 constant ICO_ALLOCATION = 74;
	uint256 constant TEAM_ALLOCATION = 10;
	uint256 constant RESERVED_ALLOCATION = 10;

	uint256 constant PRE_ICO_BONUS = 50;
	uint256 constant ICO_PHASE_01_BONUS = 20;
	uint256 constant ICO_PHASE_02_BONUS = 10;
	uint256 constant ICO_PHASE_03_BONUS = 5;
	uint256 constant ICO_PHASE_04_BONUS = 0;

	uint256 constant BUY_RATE = 1500; 
	uint256 constant BUY_PRICE = (10 ** 18) / BUY_RATE;

	// 1 ETH = ? inETH
	uint256 constant PRE_ICO_RATE = 2250;
	uint256 constant ICO_PHASE_01_RATE = 1800;
	uint256 constant ICO_PHASE_02_RATE = 1650;
	uint256 constant ICO_PHASE_03_RATE = 1575;
	uint256 constant ICO_PHASE_04_RATE = 1500;

	// 1 inETH = ? ETH
	uint256 constant PRE_ICO_BUY_PRICE = uint256((10 ** 18) / 2250);
	uint256 constant ICO_PHASE_01_BUY_PRICE = uint256((10 ** 18) / 1800);
	uint256 constant ICO_PHASE_02_BUY_PRICE = uint256((10 ** 18) / 1650);
	uint256 constant ICO_PHASE_03_BUY_PRICE = uint256((10 ** 18) / 1575);
	uint256 constant ICO_PHASE_04_BUY_PRICE = uint256((10 ** 18) / 1500);
}

/**
 * @title IntelliETH
 * @dev IntelliETH implementation
 */
contract IntelliETH is Owned, Payload, IntelliETHConstants {
	using SafeMath for uint256;

	string public name;
	string public symbol;
	uint8 public decimals;
	address public wallet;

	uint256 public totalSupply;
	uint256 public transSupply;
	uint256 public availSupply;

	uint256 public totalContributors;
	uint256 public totalContribution;

	mapping (address => bool) developers;
	mapping (address => uint256) contributions;
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;

	mapping (address => bool) freezes;

	struct SpecialPrice {
        uint256 buyPrice;
        uint256 sellPrice;
        bool exists;
    }

	mapping (address => SpecialPrice) specialPrices;

	uint256 public buyPrice;
	uint256 public sellPrice;

	bool public tokenStatus = true;
	bool public transferStatus = true;
	bool public buyStatus = true;
	bool public sellStatus = false;
	bool public refundStatus = false;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed approver, address indexed spender, uint256 value);
	event Price(uint256 buy, uint256 sell);
	event Buy(address indexed addr , uint256 value , uint256 units);
	event Sell(address indexed addr , uint256 value , uint256 units);
	event Refund(address indexed addr , uint256 value);

	function IntelliETH () {
		name = "IntelliETH";
		symbol = "INETH";
		decimals = 18;
		wallet = 0x634dA488e1E122A9f2ED83e91ccb6Db3414e3984;
		
		totalSupply = 500000000 * (10 ** uint256(decimals));
		availSupply = totalSupply;
		transSupply = 0;

		buyPrice = 444444444444444;
		sellPrice = 0;

		balances[owner] = totalSupply;
		developers[owner] = true;
		developers[wallet] = true;
	}	

	function balanceOf(address addr) public constant returns (uint256) {
		return balances[addr];
	}

	function transfer(address to, uint256 value) public onlyPayloadSize(2 * 32) returns (bool) {
		return _transfer(msg.sender, to, value);
	}

	function allowance(address approver, address spender) public constant returns (uint256) {
		return allowed[approver][spender];
	}

	function transferFrom(address approver, address to, uint256 value) public onlyPayloadSize(3 * 32) returns (bool) {
		require(allowed[approver][msg.sender] - value >= 0);
		require(allowed[approver][msg.sender] - value < allowed[approver][msg.sender]);

		allowed[approver][msg.sender] = allowed[approver][msg.sender].sub(value);
		return _transfer(approver, to, value);
	}

	function approve(address spender, uint256 value) public returns (bool) {
		return _approve(msg.sender , spender , value);
	}

	function increaseApproval(address spender , uint256 value) public returns (bool) {
		require(value > 0);
		require(allowed[msg.sender][spender] + value > allowed[msg.sender][spender]);

		value = allowed[msg.sender][spender].add(value);
		return _approve(msg.sender , spender , value);
	}

	function decreaseApproval(address spender , uint256 value) public returns (bool) {
		require(value > 0);
		require(allowed[msg.sender][spender] - value >= 0);	
		require(allowed[msg.sender][spender] - value < allowed[msg.sender][spender]);	

		value = allowed[msg.sender][spender].sub(value);
		return _approve(msg.sender , spender , value);
	}

	function freeze(address addr, bool status) public onlyOwner returns (bool) {
		freezes[addr] = status;
		return true;
	}

	function frozen(address addr) public constant onlyOwner returns (bool) {
		return freezes[addr];
	}

	function setWallet(address addr) public onlyOwner returns (bool) {
		wallet = addr;
		return true;
	}

	function setDeveloper(address addr , bool status) public onlyOwner returns (bool) {
		developers[addr] = status;
		return true;
	}

	function getDeveloper(address addr) public constant onlyOwner returns (bool) {
		return developers[addr];
	}

	function getContribution(address addr) public constant onlyOwner returns (uint256) {
		return contributions[addr];
	}

	function setSpecialPrice(address addr, uint256 _buyPrice, uint256 _sellPrice) public onlyOwner returns (bool) {
        specialPrices[addr] = SpecialPrice(_buyPrice, _sellPrice, true);
        return true;
    }

    function delSpecialPrice(address addr) public onlyOwner returns (bool) {
        delete specialPrices[addr];
        return true;
    }

	function price(uint256 _buyPrice, uint256 _sellPrice) public onlyOwner returns (bool) {
		buyPrice = _buyPrice;
		sellPrice = _sellPrice;
		Price(buyPrice, sellPrice);
		return true;
	}

	function setBuyPrice(uint256 _buyPrice) public onlyOwner returns (bool) {
		buyPrice = _buyPrice;
		Price(buyPrice, sellPrice);
		return true;
	}

	function setSellPrice(uint256 _sellPrice) public onlyOwner returns (bool) {
		sellPrice = _sellPrice;
		Price(buyPrice, sellPrice);
		return true;
	}

	function getBuyPrice(address addr) public constant returns (uint256) {
		SpecialPrice memory specialPrice = specialPrices[addr];
		if(specialPrice.exists) {
			return specialPrice.buyPrice;
		}
		return buyPrice;
	}

	function getSellPrice(address addr) public constant returns (uint256) {
		SpecialPrice memory specialPrice = specialPrices[addr];
		if(specialPrice.exists) {
			return specialPrice.sellPrice;
		}
		return sellPrice;
	}

	function () public payable {
		buy();
	}

	function withdraw() public onlyOwner returns (bool) {
		msg.sender.transfer(this.balance);
		return true;
	}

	function buy() public payable returns(uint256) {
		require(msg.value > 0);
		require(tokenStatus == true || developers[msg.sender] == true);
		require(buyStatus == true);

		uint256 buyPriceSpecial = getBuyPrice(msg.sender);
		uint256 bigval = msg.value * (10 ** uint256(decimals));
		uint256 units =  bigval / buyPriceSpecial;

		_transfer(owner , msg.sender , units);
		Buy(msg.sender , msg.value , units);
		
		totalContributors = totalContributors.add(1);
		totalContribution = totalContribution.add(msg.value);
		contributions[msg.sender] = contributions[msg.sender].add(msg.value);

		_forward(msg.value);
		return units;
	}

	function sell(uint256 units) public payable returns(uint256) {
		require(units > 0);
		require(tokenStatus == true || developers[msg.sender] == true);
		require(sellStatus == true);

		uint256 sellPriceSpecial = getSellPrice(msg.sender);
		uint256 value = ((units * sellPriceSpecial) / (10 ** uint256(decimals)));
		_transfer(msg.sender , owner , units);

		Sell(msg.sender , value , units);
		msg.sender.transfer(value);	
		return value;
	}

	function refund() public payable returns(uint256) {
		require(contributions[msg.sender] > 0);
		require(tokenStatus == true || developers[msg.sender] == true);
		require(refundStatus == true);

		uint256 value = contributions[msg.sender];
		contributions[msg.sender] = 0;

		Refund(msg.sender, value);
		msg.sender.transfer(value);	
		return value;
	}

	function setTokenStatus(bool _tokenStatus) public onlyOwner returns (bool) {
		tokenStatus = _tokenStatus;
		return true;
	}

	function setTransferStatus(bool _transferStatus) public onlyOwner returns (bool) {
		transferStatus = _transferStatus;
		return true;
	}

	function setBuyStatus(bool _buyStatus) public onlyOwner returns (bool) {
		buyStatus = _buyStatus;
		return true;
	}

	function setSellStatus(bool _sellStatus) public onlyOwner returns (bool) {
		sellStatus = _sellStatus;
		return true;
	}

	function setRefundStatus(bool _refundStatus) public onlyOwner returns (bool) {
		refundStatus = _refundStatus;
		return true;
	}

	function _transfer(address from, address to, uint256 value) private onlyPayloadSize(3 * 32) returns (bool) {
		require(to != address(0));
		require(from != to);
		require(value > 0);

		require(balances[from] - value >= 0);
		require(balances[from] - value < balances[from]);
		require(balances[to] + value > balances[to]);

		require(freezes[from] == false);
		require(tokenStatus == true || developers[msg.sender] == true);
		require(transferStatus == true);

		balances[from] = balances[from].sub(value);
		balances[to] = balances[to].add(value);

		_addSupply(to, value);
		_subSupply(from, value);
		
		Transfer(from, to, value);
		return true;
	}

	function _forward(uint256 value) internal returns (bool) {
		wallet.transfer(value);
		return true;
	}

	function _approve(address owner, address spender, uint256 value) private returns (bool) {
		require(value > 0);
		allowed[owner][spender] = value;
		Approval(owner, spender, value);
		return true;
	}

	function _addSupply(address to, uint256 value) private returns (bool) {
		if(owner == to) {
			require(availSupply + value > availSupply);
			require(transSupply - value >= 0);
			require(transSupply - value < transSupply);
			availSupply = availSupply.add(value);
			transSupply = transSupply.sub(value);
			require(balances[owner] == availSupply);
		}
		return true;
	}

	function _subSupply(address from, uint256 value) private returns (bool) {
		if(owner == from) {
			require(availSupply - value >= 0);
			require(availSupply - value < availSupply);
			require(transSupply + value > transSupply);
			availSupply = availSupply.sub(value);
			transSupply = transSupply.add(value);
			require(balances[owner] == availSupply);
		}
		return true;
	}
}