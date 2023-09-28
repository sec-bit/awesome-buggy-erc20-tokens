pragma solidity ^0.4.18;


 /// @title Ownable contract - base contract with an owner
contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}


 /// @title ERC20 interface see https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  function decimals() public constant returns (uint);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


/*
The SilentNotary Smart-Contract is specifically developed and designed to provide users 
the opportunity to fix any fact of evidence in a variety of many digital forms, including 
but not limited: photo, video, sound recording, chat, multi-user chat by uploading hash of 
the User’s data to the Ethereum blockchain.
*/
/// @title SilentNotary contract - store SHA-384 file hash in blockchain
contract SilentNotary is Ownable {
	uint public price;
	ERC20 public token;

	struct Entry {
		uint blockNumber;
		uint timestamp;
	}

	mapping (bytes32 => Entry) public entryStorage;

	event EntryAdded(bytes32 hash, uint blockNumber, uint timestamp);
	event EntryExistAlready(bytes32 hash, uint timestamp);

	/// Fallback method
	function () public {
	  	// If ether is sent to this address, send it back
	  	revert();
	}

	/// @dev Set price in SNTR tokens for storing
	/// @param _price price in SNTR tokens
	function setRegistrationPrice(uint _price) public onlyOwner {
		price = _price;
	}

	/// @dev Set SNTR token address
	/// @param _token Address SNTR tokens contract
		function setTokenAddress(address _token) public onlyOwner {
		    token = ERC20(_token);
	}

	/// @dev Register file hash in contract, web3 integration
	/// @param hash SHA-256 file hash
	function makeRegistration(bytes32 hash) onlyOwner public {
			makeRegistrationInternal(hash);
	}

	/// @dev Payable registration in SNTR tokens
	/// @param hash SHA-256 file hash
	function makePayableRegistration(bytes32 hash) public {
		address sender = msg.sender;
	    uint allowed = token.allowance(sender, owner);
	    assert(allowed >= price);

	    if(!token.transferFrom(sender, owner, price))
          revert();
			makeRegistrationInternal(hash);
	}

	/// @dev Internal registation method
	/// @param hash SHA-256 file hash
	function makeRegistrationInternal(bytes32 hash) internal {
			uint timestamp = now;
	    // Checks documents isn't already registered
	    if (exist(hash)) {
	        EntryExistAlready(hash, timestamp);
	        revert();
	    }
	    // Registers the proof with the timestamp of the block
	    entryStorage[hash] = Entry(block.number, timestamp);
	    // Triggers a EntryAdded event
	    EntryAdded(hash, block.number, timestamp);
	}

	/// @dev Check hash existance
	/// @param hash SHA-256 file hash
	/// @return Returns true if hash exist
	function exist(bytes32 hash) internal constant returns (bool) {
	    return entryStorage[hash].blockNumber != 0;
	}
}