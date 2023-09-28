pragma solidity ^0.4.6;

/*
  MiniMeToken contract taken from https://github.com/Giveth/minime/

 */


/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) payable returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool);
}

// Minime interface
contract MiniMeToken {


    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount
    ) returns (bool);


}



// Taken from Zeppelin's standard contracts.
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract SWTConverter is TokenController {

    MiniMeToken public tokenContract;   // The new token
    ERC20 public arcToken;              // The ARC token address

    function SWTConverter(
        address _tokenAddress,          // the new MiniMe token address
        address _arctokenaddress        // the original ARC token address
    ) {
        tokenContract = MiniMeToken(_tokenAddress); // The Deployed Token Contract
        arcToken = ERC20(_arctokenaddress);
    }

/////////////////
// TokenController interface
/////////////////


 function proxyPayment(address _owner) payable returns(bool) {
        return false;
    }

/// @notice Notifies the controller about a transfer, for this SWTConverter all
///  transfers are allowed by default and no extra notifications are needed
/// @param _from The origin of the transfer
/// @param _to The destination of the transfer
/// @param _amount The amount of the transfer
/// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) returns(bool) {
        return true;
    }

/// @notice Notifies the controller about an approval, for this SWTConverter all
///  approvals are allowed by default and no extra notifications are needed
/// @param _owner The address that calls `approve()`
/// @param _spender The spender in the `approve()` call
/// @param _amount The amount in the `approve()` call
/// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool)
    {
        return true;
    }


/// @notice converts ARC tokens to new SWT tokens and forwards ARC to the vault address.
/// @param _amount The amount of ARC to convert to SWT
 function convert(uint _amount){

        // transfer ARC to the vault address. caller needs to have an allowance from
        // this controller contract for _amount before calling this or the transferFrom will fail.
        if (!arcToken.transferFrom(msg.sender, 0x0, _amount)) {
            throw;
        }

        // mint new SWT tokens
        if (!tokenContract.generateTokens(msg.sender, _amount)) {
            throw;
        }
    }


}