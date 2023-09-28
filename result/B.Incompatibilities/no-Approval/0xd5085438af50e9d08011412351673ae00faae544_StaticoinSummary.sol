pragma solidity ^0.4.0;


//Dapp at http://www.staticoin.com
//https://github.com/genkifs/staticoin

/** @title owned. */
contract owned  {
  address owner;
  function owned() {
    owner = msg.sender;
  }
  function changeOwner(address newOwner) onlyOwner {
    owner = newOwner;
  }
  modifier onlyOwner() {
    require(msg.sender==owner); 
    _;
  }
}

/** @title I_Pricer. */
contract I_Pricer {
    uint128 public lastPrice;
    I_minter public mint;
    string public sURL;
    mapping (bytes32 => uint) RevTransaction;
    function __callback(bytes32 myid, string result) {}
    function queryCost() constant returns (uint128 _value) {}
    function QuickPrice() payable {}
    function requestPrice(uint _actionID) payable returns (uint _TrasID) {}
    function collectFee() returns(bool) {}
    function () {
        //if ether is sent to this address, send it back.
        revert();
    }
}
    

/** @title I_coin. */
contract I_coin {

    event EventClear();

	I_minter public mint;
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals=18;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = '';       //human 0.1 standard. Just an arbitrary versioning scheme.
	
    function mintCoin(address target, uint256 mintedAmount) returns (bool success) {}
    function meltCoin(address target, uint256 meltedAmount) returns (bool success) {}
    function approveAndCall(address _spender, uint256 _value, bytes _extraData){}

    function setMinter(address _minter) {}   
	function increaseApproval (address _spender, uint256 _addedValue) returns (bool success) {}    
	function decreaseApproval (address _spender, uint256 _subtractedValue) 	returns (bool success) {} 

    // @param _owner The address from which the balance will be retrieved
    // @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}    


    // @notice send `_value` token to `_to` from `msg.sender`
    // @param _to The address of the recipient
    // @param _value The amount of token to be transferred
    // @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}


    // @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    // @param _from The address of the sender
    // @param _to The address of the recipient
    // @param _value The amount of token to be transferred
    // @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    // @notice `msg.sender` approves `_addr` to spend `_value` tokens
    // @param _spender The address of the account able to transfer the tokens
    // @param _value The amount of wei to be approved for transfer
    // @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	// @param _owner The address of the account owning tokens
    // @param _spender The address of the account able to transfer the tokens
    // @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
	
	mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

	// @return total amount of tokens
    uint256 public totalSupply;
}

/** @title I_minter. */
contract I_minter { 
    event EventCreateStatic(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventRedeemStatic(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventCreateRisk(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventRedeemRisk(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventBankrupt();
    
	uint128 public PendingETH; 
    uint public TransCompleted;
	
    function Leverage() constant returns (uint128)  {}
    function RiskPrice(uint128 _currentPrice,uint128 _StaticTotal,uint128 _RiskTotal, uint128 _ETHTotal) constant returns (uint128 price)  {}
    function RiskPrice(uint128 _currentPrice) constant returns (uint128 price)  {}     
    function PriceReturn(uint _TransID,uint128 _Price) {}
	function StaticEthAvailable() public constant returns (uint128 StaticEthAvailable) {}
    function NewStatic() external payable returns (uint _TransID)  {}
    function NewStaticAdr(address _Risk) external payable returns (uint _TransID)  {}
    function NewRisk() external payable returns (uint _TransID)  {}
    function NewRiskAdr(address _Risk) external payable returns (uint _TransID)  {}
    function RetRisk(uint128 _Quantity) external payable returns (uint _TransID)  {}
    function RetStatic(uint128 _Quantity) external payable returns (uint _TransID)  {}
    function Strike() constant returns (uint128)  {}
}

contract StaticoinSummary is owned{

    function StaticoinSummary(){}

	address[] public mints;
	address[] public staticoins; 
	address[] public riskcoins;
	address[] public pricers;

    function SetAddresses(address[] _mints, address[] _staticoins, address[] _riskcoins,  address[] _pricers) onlyOwner external {
		require(_mints.length > 0);
		require(_staticoins.length == _mints.length);
        require(_riskcoins.length == _mints.length);
		require(_pricers.length == _mints.length);
		mints=_mints;
		staticoins=_staticoins;
		riskcoins=_riskcoins;
		pricers=_pricers;
	}

	function balancesStaticoin() view public returns (uint[]) {
		return balances(msg.sender, staticoins);
	}

	function balancesStaticoin(address user) view public returns (uint[]) {
		return balances(user, staticoins);
	}

	function balancesRiskcoins() view public returns (uint[]) {
		return balances(msg.sender, riskcoins);
	}
	
	function balancesRiskcoins(address user) view public returns (uint[]) {
		return balances(user, riskcoins);
	}
	
    function balances(address user,  address[] _coins) view public returns (uint[]) {
        require(_coins.length > 0);
        uint[] memory balances = new uint[](_coins.length);

        //as this is a call() function, we don't really care about gas cost, just dont make the array too large
        for(uint i = 0; i< _coins.length; i++){ 
            I_coin coin = I_coin(_coins[i]);
            balances[i] = coin.balanceOf(user);
        }    
        return balances;
    }
  
    function Totalbalance() view public returns (uint) {
		return Totalbalance(mints);
	}  
    
    function Totalbalance(address[] _mints) view public returns (uint) {
        require(_mints.length > 0);
        uint balance;

        //as this is a call() function, we don't really care about gas cost, just dont make the array too large
        for(uint i = 0; i< _mints.length; i++){ 
            I_minter coin = I_minter(_mints[i]);
            balance += coin.balance;
        }    
        return balance;
    }

	function totalStaticoinSupplys() view public returns (uint[]) {
		return totalSupplys(staticoins);
	}
	
	function totalriskcoinsSupplys() view public returns (uint[]) {
		return totalSupplys(riskcoins);
	}
	
    function totalSupplys(address[] _coins) view public returns (uint[]) {
        require(_coins.length > 0);
        uint[] memory totalSupplys = new uint[](_coins.length);

        for(uint i = 0; i< _coins.length; i++){
            I_coin coin = I_coin(_coins[i]);
            totalSupplys[i] = coin.totalSupply();
        }    
        return totalSupplys;
    }
 
    function Leverages() view public returns (uint128[]) {
		return Leverages(mints);
	}
 
    function Leverages(address[] _mints) view public returns (uint128[]) {
        require(_mints.length > 0);
        uint128[] memory Leverages = new uint128[](_mints.length);

        for(uint i = 0; i< _mints.length; i++){
            I_minter mint = I_minter(_mints[i]);
            Leverages[i] = mint.Leverage();
        }    
        return Leverages;
    }

    function Strikes() view public returns (uint128[]) {
		return Strikes(mints);
	}
	
    function Strikes(address[] _mints) view public returns (uint128[]) {
        require(_mints.length > 0);
        uint128[] memory Strikes = new uint128[](_mints.length);

        for(uint i = 0; i< _mints.length; i++){
            I_minter mint = I_minter(_mints[i]);
            Strikes[i] = mint.Strike();
        }    
        return Strikes;
    }   
    
	function StaticEthAvailables() view public returns (uint128[]) {
		return StaticEthAvailables(mints);
	}
	
    function StaticEthAvailables(address[] _mints) view public returns (uint128[]) {
        require(_mints.length > 0);
        uint128[] memory StaticEthAvailables = new uint128[](_mints.length);

        for(uint i = 0; i< _mints.length; i++){
            I_minter mint = I_minter(_mints[i]);
            StaticEthAvailables[i] = mint.StaticEthAvailable();
        }    
        return StaticEthAvailables;
    }

    function PendingETHs() view public returns (uint128[]) {
		return PendingETHs(mints);
	}
	
    function PendingETHs(address[] _mints) view public returns (uint128[]) {
        require(_mints.length > 0);
        uint128[] memory PendingETHs = new uint128[](_mints.length);

        for(uint i = 0; i< _mints.length; i++){
            I_minter mint = I_minter(_mints[i]);
            PendingETHs[i] = mint.PendingETH();
        }    
        return PendingETHs;
    }

	function RiskPrices(uint128[] prices) view public returns (uint[]) {
		return RiskPrices(mints,prices);
	}
	
    function RiskPrices(address[] _mints, uint128[] prices) view public returns (uint[]) {
        require(_mints.length > 0);
        require(_mints.length == prices.length);
        uint[] memory RiskPrices = new uint[](_mints.length);

        for(uint i = 0; i< _mints.length; i++){
            I_minter mint = I_minter(_mints[i]);
            RiskPrices[i] = mint.RiskPrice(prices[i]);
        }    
        return RiskPrices;
    }
 
    function TransCompleteds() view public returns (uint[]) {
		return TransCompleteds(mints);
	}

    function TransCompleteds(address[] _mints) view public returns (uint[]) {
        require(_mints.length > 0);
        uint[] memory TransCompleteds = new uint[](_mints.length);

        for(uint i = 0; i< _mints.length; i++){
            I_minter mint = I_minter(_mints[i]);
            TransCompleteds[i] = mint.TransCompleted();
        }    
        return TransCompleteds;
    }
    
    function queryCost() view public returns (uint[]) {
        return queryCost(pricers);
    }

    function queryCost(address[] _pricers) view public returns (uint[]) {
        require(_pricers.length > 0);
        uint[] memory queryCosts = new uint[](_pricers.length);

        for(uint i = 0; i< _pricers.length; i++){
            I_Pricer Pricer = I_Pricer(_pricers[i]);
            queryCosts[i] = Pricer.queryCost();
        }    
        return queryCosts;
    }
    
    function TotalFee() view returns(uint) {
        return TotalFee(pricers);
    }

	function TotalFee(address[] _pricers) view returns(uint) {
		uint size = (_pricers.length);
		uint fee;
		for(uint i = 0; i< size; i++){
			I_Pricer pricer = I_Pricer(_pricers[i]);
			fee += pricer.balance;
		}
		return fee;
	}

	function collectFee() onlyOwner returns(bool) {
		return collectFee(pricers);
	}
	
	function collectFee(address[] _pricers) onlyOwner returns(bool) {
		uint size = (_pricers.length);
		bool ans = true;
		for(uint i = 0; i< size; i++){
			I_Pricer pricer = I_Pricer(_pricers[i]);
			ans = ans && pricer.collectFee();
		}
		return ans;
	}

    function Summary(address user, uint128[] _prices) view public returns (uint[]){
		return Summary(user, mints, staticoins, riskcoins, _prices);
	}
    
    function Summary(address user, address[] _mints, address[] _staticoins, address[] _riskcoins, uint128[] _prices) view public returns (uint[]) {
        uint size = (_mints.length);
		require(size > 0);
        require(_staticoins.length == size);
        require(_riskcoins.length == size);
        require(_prices.length == size);
        uint step = 11;
        uint[] memory Summarys = new uint[](size*step+1);
        I_Pricer pricer = I_Pricer(pricers[0]);
		Summarys[0] = pricer.queryCost(); //can only pass in 4 arrays to the function.  This now assumes that all pricers have the same query cost

        for(uint i = 0; i< size; i++){
            I_coin staticoin = I_coin(_staticoins[i]);
            I_coin riskcoin = I_coin(_riskcoins[i]);
            I_minter mint = I_minter(_mints[i]);
            Summarys[i*step+1]  = staticoin.balanceOf(user);
            Summarys[i*step+2]  = riskcoin.balanceOf(user);
            Summarys[i*step+3]  = staticoin.totalSupply();
            Summarys[i*step+4]  = riskcoin.totalSupply();
            Summarys[i*step+5]  = mint.Leverage();
            Summarys[i*step+6]  = mint.Strike();
            Summarys[i*step+7]  = mint.StaticEthAvailable();
            Summarys[i*step+8]  = mint.PendingETH();
            Summarys[i*step+9]  = mint.RiskPrice(_prices[i]);
            Summarys[i*step+10]  = mint.TransCompleted();
            Summarys[i*step+11] = mint.balance;
        }    
        return Summarys;
    }
	
	function () {
        revert();
    }

}