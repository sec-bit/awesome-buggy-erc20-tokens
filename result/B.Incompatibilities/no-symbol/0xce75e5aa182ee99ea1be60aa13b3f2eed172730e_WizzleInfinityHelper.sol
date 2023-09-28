pragma solidity ^0.4.18;

/// @title Ownable contract
contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    }
}
/// @title Mortal contract - used to selfdestruct once we have no use of this contract
contract Mortal is Ownable {
    function executeSelfdestruct() onlyOwner {
        selfdestruct(owner);
    }
}

/// @title ERC20 contract
/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/// @title WizzleInfinityHelper contract
contract WizzleInfinityHelper is Mortal {
    
    mapping (address => bool) public whitelisted;
    ERC20 public token;

    function WizzleInfinityHelper(address _token) public {
        token = ERC20(_token);
    }

    /// @dev Whitelist a single address
    /// @param addr Address to be whitelisted
    function whitelist(address addr) public onlyOwner {
        require(!whitelisted[addr]);
        whitelisted[addr] = true;
    }

    /// @dev Remove an address from whitelist
    /// @param addr Address to be removed from whitelist
    function unwhitelist(address addr) public onlyOwner {
        require(whitelisted[addr]);
        whitelisted[addr] = false;
    }

    /// @dev Whitelist array of addresses
    /// @param arr Array of addresses to be whitelisted
    function bulkWhitelist(address[] arr) public onlyOwner {
        for (uint i = 0; i < arr.length; i++) {
            whitelisted[arr[i]] = true;
        }
    }

    /// @dev Check if address is whitelisted
    /// @param addr Address to be checked if it is whitelisted
    /// @return Is address whitelisted?
    function isWhitelisted(address addr) public constant returns (bool) {
        return whitelisted[addr];
    }   

    /// @dev Transfer tokens to addresses registered for airdrop
    /// @param dests Array of addresses that have registered for airdrop
    /// @param values Array of token amount for each address that have registered for airdrop
    /// @return Number of transfers
    function airdrop(address[] dests, uint256[] values) public onlyOwner returns (uint256) {
        uint256 i = 0;
        while (i < dests.length) {
           token.transfer(dests[i], values[i]);
           whitelisted[dests[i]] = true;
           i += 1;
        }
        return (i); 
    }

}