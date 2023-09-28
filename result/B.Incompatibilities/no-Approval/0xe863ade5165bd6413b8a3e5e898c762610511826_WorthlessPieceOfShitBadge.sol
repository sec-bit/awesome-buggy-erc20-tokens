pragma solidity ^0.4.10;


contract WorthlessPieceOfShitBadge
{


	address 	public owner;
	address     public app;


    string 		public standard = 'Token 0.1';
	string 		public name = "Worthless Piece of Shit Badge"; 
	string 		public symbol = "Worthless Piece of Shit Badge";
	uint8 		public decimals = 0; 
	uint256 	public totalSupply = 0;
	uint256     public price = 1 ether / 10; 
	uint256     public removalPrice = 1 ether;
	

	mapping (address => uint256) balances;	
	mapping (address => mapping (address => uint256)) allowed;


	modifier ownerOnly() 
	{
		require(msg.sender == owner);
		_;
	}
	
	
	modifier appOrOwner() 
	{
		require(msg.sender == app || msg.sender == owner);
		_;
	}		
	
	
	function _setRemovalPrice(uint256 _price) public appOrOwner returns(bool success) 
	{
	    
	    removalPrice = _price;
	    RemovalPriceSet(_price);
	    
	    return true;
	}
	
	
	function _setBuyPrice(uint256 _price) public appOrOwner returns(bool success) 
	{
	    
	    price = _price;
	    BuyPriceSet(_price);
	    
	    return true;
	}


	function _changeName(string _name) public ownerOnly returns(bool success) 
	{

		name = _name;
		NameChange(name);

		return true;
	}


	function _changeSymbol(string _symbol) public ownerOnly returns(bool success) 
	{

		symbol = _symbol;
		SymbolChange(symbol);

		return true;
	}
	
	
	function _mint(address _sendTo, uint256 _amount) public appOrOwner returns(bool success) 
	{
	    
	    balances[_sendTo] += _amount;
	    totalSupply += _amount;
	    Transfer(address(this), _sendTo, _amount);
	    
	    return true;
	}
	
	
	function _clear(address _address) public appOrOwner returns(bool success) 
	{
	    
	    uint256 amount = balances[_address];
	    totalSupply -= amount;
	    Transfer(_address, 0x0, amount);
	    balances[_address] = 0;
	    
	    return true;
	}


    function balanceOf(address _owner) public constant returns(uint256 tokens) 
	{

		require(_owner != 0x0);
		return balances[_owner];
	}
	
	
	function _transferOwnership(address _to) ownerOnly public returns(bool success) 
	{
	    
	    require(_to != 0x0);
	    owner = _to;
	    
	    return true;
	}
	
	
	function _setApp(address _to) ownerOnly public returns(bool success) 
	{
	    
	    app = _to;
	    AppSet(_to);
	    
	    return true;
	}
	
	
	function _withdraw() ownerOnly public returns(bool success) 
	{
	    
	    address token = address(this);
	    msg.sender.transfer(token.balance);
	    
	    Withdrawal(token.balance);
	    
	    return true;
	}
	
	
	function buy(address _sendTo, uint256 _amount) public payable returns(bool success) 
	{
	    
	    uint256 ethRequired = _amount * price;
	    
	    if (msg.value < ethRequired) {
	        require(false);
	    }
	    
	    uint256 refund = msg.value - ethRequired;
	    msg.sender.transfer(refund);
	    balances[_sendTo] += _amount;
	    totalSupply += _amount;
	    
	    Buy(_sendTo, _amount);
	    Transfer(address(this), _sendTo, _amount);
	    
	    return true;
	}
	
	
	function remove(address _address, uint256 _amount) public payable returns(bool success) 
	{
	    
	    require(balances[_address] >= _amount);
	    uint256 ethRequired = _amount * removalPrice;
	    
	    if (msg.value < ethRequired) {
	        require(false);
	    }
	    
	    uint256 refund = msg.value - ethRequired;
	    msg.sender.transfer(refund);
	    balances[_address] -= _amount;
	    totalSupply -= _amount;
	    
	    Removal(_address, _amount);
	    Transfer(_address, address(this), _amount);
	    
	    return true;
	}
	

    function transfer(address _to, uint256 _value) appOrOwner public returns(bool success)
	{ 

        require(false);
        return false;
	}

	
	function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) 
	{
	    
	    require(false);
    	return false;
    }

    
    function approve(address _spender, uint256 _value) appOrOwner public returns(bool success)  
    {

        require(false);
        return false;
    }


    function WorthlessPieceOfShitBadge() public
	{
		owner = msg.sender;
		TokenDeployed();
	}


	// ====================================================================================
	//
    // List of all events

    event NameChange(string _name);
    event SymbolChange(string _symbol);
    event AppSet(address indexed _to);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event TokenDeployed();
	event Buy(address indexed _to, uint256 _amount);
	event Removal(address indexed _address, uint256 _amount);
	event RemovalPriceSet(uint256 price);
	event BuyPriceSet(uint256 price);
	event Withdrawal(uint256 _value);

}