pragma solidity ^0.4.13;

contract ERC20 {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);
    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);



    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}


contract AirDrop{
    address owner;
    mapping(address => uint256) tokenBalance;
    
    function AirDrop(){
        owner=msg.sender;
    }
    
    function transfer(address _token,address _to,uint256 _amount) public returns(bool){
        require(msg.sender==owner);
        ERC20 token=ERC20(_token);
        return token.transfer(_to,_amount);
    }
    
    function doAirdrop(address _token,address[] _to,uint256 _amount) public{
        ERC20 token=ERC20(_token);
        for(uint256 i=0;i<_to.length;++i){
            token.transferFrom(msg.sender,_to[i],_amount);
        }
    }
    
    function doAirdrop2(address _token,address[] _to,uint256 _amount) public{
        ERC20 token=ERC20(_token);
        for(uint256 i=0;i<_to.length;++i){
            token.transfer(_to[i],_amount);
        }
    }
    
    function doCustomAirdrop(address _token,address[] _to,uint256[] _amount) public{
        ERC20 token=ERC20(_token);
        for(uint256 i=0;i<_to.length;++i){
            token.transferFrom(msg.sender,_to[i],_amount[i]);
        }
    }
    
    function doCustomAirdrop2(address _token,address[] _to,uint256[] _amount) public{
        ERC20 token=ERC20(_token);
        for(uint256 i=0;i<_to.length;++i){
            token.transfer(_to[i],_amount[i]);
        }
    }
}