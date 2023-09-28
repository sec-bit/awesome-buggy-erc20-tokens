pragma solidity ^0.4.19;

contract Frikandel {
    address creator = msg.sender; //King Frikandel

    bool public Enabled = true; //Enable selling new Frikandellen
    bool internal Killable = true; //Enabled when the contract can commit suicide (In case of a problem with the contract in its early development, we will set this to false later on)

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply = 500000; //500k Frikandellen (y'all ready for some airdrop??)
    uint256 public hardLimitICO = 750000; //Do not allow more then 750k frikandellen to exist, ever. (The ICO will not sell past this)

    function name() public pure returns (string) { return "Frikandel"; } //Frikandellen zijn lekker
    function symbol() public pure returns (string) { return "FRKNDL"; }
    function decimals() public pure returns (uint8) { return 0; } //Imagine getting half of a frikandel, that must be pretty shitty... Lets not do that

    function balanceOf(address _owner) public view returns (uint256) { return balances[_owner]; }

	function Frikandel() public {
	    balances[creator] = totalSupply; //Lets get this started :)
	}
	
	function Destroy() public {
	    if (msg.sender != creator) { revert(); } //yo what why
	    
	    if ((balances[creator] > 25000) && Killable == true){ //Only if the owner has more then 25k (indicating the airdrop was not finished yet) and the contract is killable.. Go ahead
	        selfdestruct(creator);
	    }
	}
	
	function DisableSuicide() public returns (bool success){
	    if (msg.sender != creator) { revert(); } //u dont control me
	    
	    Killable = false;
	    return true;
	}

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if(msg.data.length < (2 * 32) + 4) { revert(); } //Something wrong yo

        if (_value == 0) { return false; } //y try to transfer without specifying any???

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];

        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true; //Smakelijk!
        } else { return false; } //Sorry man je hebt niet genoeg F R I K A N D E L L E N
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if(msg.data.length < (3 * 32) + 4) { revert(); } //Something wrong yo

        if (_value == 0) { return false; }

        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            allowed[_from][msg.sender] -= _value;
            
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function approve(address _spender, uint256 _value) internal returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function enable() public {
        if (msg.sender != creator) { revert(); } //Bro stay of my contract
        Enabled = true;
    }

    function disable() public {
        if (msg.sender != creator) { revert(); } //BRO what did I tell you
        Enabled = false;
    }

    function() payable public {
        if (!Enabled) { revert(); }
        if(balances[msg.sender]+(msg.value / 1e14) > 30000) { revert(); } //This would give you more then 30000 frikandellen, you can't buy from this account anymore through the ICO
        if(totalSupply+(msg.value / 1e14) > hardLimitICO) { revert(); } //Hard limit on Frikandellen
        if (msg.value == 0) { return; }

        creator.transfer(msg.value);

        uint256 tokensIssued = (msg.value / 1e14); //Since 1 token can be bought for 0.0001 ETH split the value (in Wei) through 1e14 to get the amount of tokens

        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;

        Transfer(address(this), msg.sender, tokensIssued);
    }
}