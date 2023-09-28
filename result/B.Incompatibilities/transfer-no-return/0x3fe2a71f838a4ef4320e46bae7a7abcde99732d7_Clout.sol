pragma solidity ^0.4.16;

interface tokenRecipient {
function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

contract ERC20 {

string public name;
string public symbol;
uint8 public decimals = 18;
uint256 public totalSupply;

mapping (address => uint256) public balanceOf;
mapping (address => mapping (address => uint256)) public allowance;

event Transfer(address indexed from, address indexed to, uint256 value);

function ERC20(
uint256 initialSupply,
string tokenName,
string tokenSymbol
) public {
totalSupply = initialSupply * 10 ** uint256(decimals); 
balanceOf[msg.sender] = totalSupply; 
name = tokenName; 
symbol = tokenSymbol; 
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


function transfer(address _to, uint256 _value) public {
_transfer(msg.sender, _to, _value);
}


function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
require(_value <= allowance[_from][msg.sender]); // Check allowance
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

}
contract Clout is ERC20 {

function Clout() ERC20(100000000, "Clout", "Clout") public {}
function multisend(address[] dests, uint256[] values) public returns (uint256) {
uint256 i = 0;
while (i < dests.length) {
transfer(dests[i], values[i]);
i += 1;
}
return(i);
}

}