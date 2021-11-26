pragma solidity ^0.4.8;

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);

    function approve(address _to, uint256 _tokenId) public returns(bool success);
    function transferFrom(address _from, address _to, uint256 _tokenId) public returns(bool success);
    function transfer(address _to, uint256 _tokenId) public returns(bool success);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed approved, uint256 amount);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

contract SingleTransferToken is ERC721 {

    string public symbol = "STT";

    string public name = "SingleTransferToken";

    uint256 _totalSupply = 1;

    uint256 currentPrice;

    uint256 sellingPrice;

    uint256 stepLimit = 1 ether;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    // Owner of this contract
    
    address owner;

    // Current owner of the token
    address public tokenOwner;

    // Allowed to transfer to this address
    address allowedTo = address(0);

    modifier onlyOwner() {

        require(msg.sender == owner);
        _;

    }

    modifier onlySingle(uint256 amount){
        require(amount == 1);
        _;
    }

    function implementsERC721() public pure returns (bool)
    {
        return true;
    }

    // Constructor

    function SingleTransferToken(string tokenName, string tokenSymbol, uint256 initialPrice, uint256 sLimit) public{

        name = tokenName;
        
        symbol = tokenSymbol;

        owner = msg.sender;

        tokenOwner = msg.sender;

        stepLimit = sLimit;

        sellingPrice = initialPrice;

        currentPrice = initialPrice;

    }

    function totalSupply() constant public returns (uint256 total) {

        total = _totalSupply;

    }

    // What is the balance of a particular account?

    function balanceOf(address _owner) constant public returns (uint256 balance) {

        return _owner == tokenOwner ? 1 : 0;

    }

    // Transfer the balance from owner's account to another account

    function transfer(address _to, uint256 _amount) onlySingle(_amount) public returns (bool success) {

        if(balanceOf(msg.sender) > 0){
         
            tokenOwner = _to;
        
            Transfer(msg.sender, _to, _amount);

            success = true;

        }else {

            success = false;

        }

    }

    // Send _value amount of tokens from address _from to address _to

    function transferFrom(

        address _from,

        address _to,

        uint256 _amount

    ) onlySingle(_amount) public returns (bool success) {

        require(balanceOf(_from) > 0 && allowedTo == _to);

        tokenOwner = _to;
        
        Transfer(_from, _to, _amount);

        success = true;
    }

 
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.

    // If this function is called again it overwrites the current allowance with _value.

    function approve(address _spender, uint256 _amount) public onlySingle(_amount) returns (bool success) {

        require(tokenOwner == msg.sender);

        allowedTo = _spender;

        Approval(msg.sender, _spender, _amount);

        success = true;

    }

 
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {

        return _owner == tokenOwner && allowedTo == _spender? 1 : 0;

    }

    // Allows someone to send ether and obtain the token

    function() public payable {

        //making sure token owner is not sending
        assert(tokenOwner != msg.sender);
        
        //making sure sent amount is greater than or equal to the sellingPrice
        assert(msg.value >= sellingPrice);
        
        //if sent amount is greater than sellingPrice refund extra
        if(msg.value > sellingPrice){
            
            msg.sender.transfer(msg.value - sellingPrice);

        }

        //update prices
        currentPrice = sellingPrice;

        if(currentPrice >= stepLimit){

            sellingPrice = (currentPrice * 120)/94; //adding commission amount //1.2/(1-0.06)
        
        }else{

            sellingPrice = (currentPrice * 2 * 100)/94;//adding commission amount
        
        }  
        
        transferToken(tokenOwner, msg.sender);

        //if contact balance is greater than 1000000000000000 wei,
        //transfer balance to the contract owner
        //if (this.balance >= 1000000000000000) {

        //    owner.transfer(this.balance);

        //}

    } 

    function transferToken(address prevOwner, address newOwner) internal {

        //pay previous owner        
        prevOwner.transfer((currentPrice*94)/100); //(1-0.06) 

        tokenOwner = newOwner;

        Transfer(prevOwner, newOwner, 1);
        

    }

    function payout(address _to) onlyOwner public{
    	if(this.balance > 1 ether){
    		if(_to == address(0)){
    			owner.transfer(this.balance - 1 ether);
    		}else{
    			_to.transfer(this.balance - 1 ether);
    		}
    		
    	}
    }

}