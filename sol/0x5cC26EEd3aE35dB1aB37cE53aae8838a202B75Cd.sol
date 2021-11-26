pragma solidity ^0.4.20;

contract Token {
    function totalSupply() public constant returns (uint256 supply) {}
    function balanceOf(address _owner) public constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) public returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
    function approve(address _spender, uint256 _value) public returns (bool success) {}
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract ERC827 is StandardToken {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}

contract ERC827Token is ERC827 {
  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call(_data));

    return true;
  }

  
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call(_data));
    return true;
  }

  
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call(_data));
    return true;
  }

}

contract D7Contributor is ERC827Token {

    /* Combined Certificate of Value and Acknowledgment
 2001 Virtual Land Parcels Located in the Virtual World DECENTRALAND​ in form of
 District Contributor Tokens.
Issued to Contributors of District Red Lights​ aka TheSeven7vr​,
IDf5d8e722-fdce-4d41-b38b-adfed2e0cf6c ,Map Designator 31
a District in the Virtual World Known as DECENTRALAND​.
 Valuation of Land Parcels of DISTRICT RED LIGHTS (2/23/2018)
 By: Jeffrey Paquin aka SAAM.I.AM
Registered Owner/District Leader https://gist.github.com/BlacksheepAries/7ba33d10c2ae5765fc8aa384b6520938
To: ALL CONTRIBUTING DISTRICT MEMBERS
OFFICIAL DISTRICT Order Number 001

    The Value assessed by this document is Verified
and documented by the DECENTRALAND End of
Auction Statistics and utilizing the Average Price
per parcel near center. Due to the strategic Location
in relation to Center and proximity to the Vegas
district, these assesed VALUES are mild and lower
than actual potential values once commercialized.
And so for all legal reference and purpose the value
per Parcel is 46,149MANA x .20USD =
$9,229.80 USD

I declare that the assessed Values assigned to the District Red Lights Membership Tokens
are of fair and true value, documented and verifiable as per supporting documentation herein mentioned;
and further backed by contract address 0x0f5d2fb29fb7d3cfee444a200298f468908cc942 as the currency
address utilized in the purchase/staking period.
Signature…Jeffrey Paquin Owner/District Leader
    For more details, reference our District CCVO document at http://www.the7vr.org/pdf/CCVOredlightsvaluation.pdf
    */
    
    string public name;                  
    uint8 public decimals;                
    string public symbol;                 

    function D7Contributor() public {
        balances[msg.sender] = 4002;
        totalSupply = 4002;
        name = "District 7 Contributor";
        decimals = 0;
        symbol = "D7C";
    }

}