pragma solidity ^0.4.19;

contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() internal {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

/**
 * Interface for the standard token.
 * Based on https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
interface EIP20Token {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
  function approve(address spender, uint256 value) public returns (bool success);
  function allowance(address owner, address spender) public view returns (uint256 remaining);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


// The owner of this contract should be an externally owned account
contract PinProtocolInvestment is Ownable {

  // Address of the target contract
  address public investment_address = 0x77D0f9017304e53181d9519792887E78161ABD25;
  // Major partner address
  address public major_partner_address = 0x8f0592bDCeE38774d93bC1fd2c97ee6540385356;
  // Minor partner address
  address public minor_partner_address = 0xC787C3f6F75D7195361b64318CE019f90507f806;
  // Gas used for transfers.
  uint public gas = 1000;

  // Payments to this contract require a bit of gas. 100k should be enough.
  function() payable public {
    execute_transfer(msg.value);
  }

  // Transfer some funds to the target investment address.
  function execute_transfer(uint transfer_amount) internal {
    // Major fee is 60% * (1/11) * value = 6 * value / (10 * 11)
    uint major_fee = transfer_amount * 6 / (10 * 11);
    // Minor fee is 40% * (1/11) * value = 4 * value / (10 * 11)
    uint minor_fee = transfer_amount * 4 / (10 * 11);

    require(major_partner_address.call.gas(gas).value(major_fee)());
    require(minor_partner_address.call.gas(gas).value(minor_fee)());

    // Send the rest
    require(investment_address.call.gas(gas).value(transfer_amount - major_fee - minor_fee)());
  }

  // Sets the amount of gas allowed to investors
  function set_transfer_gas(uint transfer_gas) public onlyOwner {
    gas = transfer_gas;
  }

  // We can use this function to move unwanted tokens in the contract
  function approve_unwanted_tokens(EIP20Token token, address dest, uint value) public onlyOwner {
    token.approve(dest, value);
  }

  // This contract is designed to have no balance.
  // However, we include this function to avoid stuck value by some unknown mishap.
  function emergency_withdraw() public onlyOwner {
    require(msg.sender.call.gas(gas).value(this.balance)());
  }

}