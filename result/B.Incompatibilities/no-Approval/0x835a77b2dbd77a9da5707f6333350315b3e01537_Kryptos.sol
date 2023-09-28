pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Kryptos {

	//***********************************************
	//*                 18.02.2018                  *
	//*               www.kryptos.ws                *
	//*        Kryptos - Secure Communication       *
	//* Egemen POLAT Tarafindan projelendirilmistir *
    //***********************************************
    
	bool public transferactive;
	bool public shareactive;
	bool public coinsaleactive;
    string public name;
    string public symbol;
    uint256 public buyPrice;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;
	address public reserve;
	
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
	
    function Kryptos(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address tokenowner,
		address tokenreserve,
		uint256 tokenbuyPrice,
		bool tokentransferactive,
		bool tokenshareactive,
		bool tokencoinsaleactive
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        owner = tokenowner;
		reserve = tokenreserve;
		buyPrice = tokenbuyPrice;
		transferactive = tokentransferactive;
		shareactive = tokenshareactive;
		coinsaleactive = tokencoinsaleactive;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function setOwner(address newdata) public {
        if (msg.sender == owner) {owner = newdata;}
    }
		
    function setTransferactive(bool newdata) public {
        if (msg.sender == owner) {transferactive = newdata;}
    }
	
    function setShareactive(bool newdata) public {
        if (msg.sender == owner) {shareactive = newdata;}
    }
	
    function setCoinsaleactive(bool newdata) public {
        if (msg.sender == owner) {coinsaleactive = newdata;}
    }

    function setPrices(uint256 newBuyPrice) public {
        if (msg.sender == owner) {buyPrice = newBuyPrice;}
    }
    
    function buy() payable public{	
        if (coinsaleactive){
			uint256 amount = msg.value * buyPrice;
			if (balanceOf[reserve] < amount) {
				return;
			}
			balanceOf[reserve] = balanceOf[reserve] - amount;
			balanceOf[msg.sender] = balanceOf[msg.sender] + amount;
			Transfer(reserve, msg.sender, amount);
			reserve.transfer(msg.value); 
		}
    }
    
    function ShareDATA(string SMS) public {
        bytes memory string_rep = bytes(SMS);
        if (shareactive){_transfer(msg.sender, reserve, string_rep.length * (2* 10 ** (uint256(decimals)-4)));}
    }
	
    function transfer(address _to, uint256 _value) public {
        if (transferactive){_transfer(msg.sender, _to, _value);}
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}