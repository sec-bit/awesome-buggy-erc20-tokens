pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}


/// @dev Implements access control to the DWorld contract.
contract MetaGameAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;
    
    function MetaGameAccessControl() public {
        // The creator of the contract is the initial CFO.
        cfoAddress = msg.sender;
    }
    
    /// @dev Access modifier for CFO-only functionality.
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current contract owner.
    /// @param _newCFO The address of the new CFO.
    function setCFO(address _newCFO) external onlyOwner {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
}


/// @dev Defines base data structures for DWorld.
contract MetaGameBase is MetaGameAccessControl {
    using SafeMath for uint256;
    
    mapping (uint256 => address) identifierToOwner;
    mapping (uint256 => address) identifierToApproved;
    mapping (address => uint256) ownershipDeedCount;
    
    mapping (uint256 => uint256) identifierToParentIdentifier;
    
    /// @dev All existing identifiers.
    uint256[] public identifiers;
    
    /// @notice Get all minted identifiers;
    function getAllIdentifiers() external view returns(uint256[]) {
        return identifiers;
    }
    
    /// @notice Returns the identifier of the parent of an identifier.
    /// The parent identifier is 0 if the identifier has no parent.
    /// @param identifier The identifier to get the parent identifier of.
    function parentOf(uint256 identifier) external view returns (uint256 parentIdentifier) {
        parentIdentifier = identifierToParentIdentifier[identifier];
    }
}


/// @title Interface for contracts conforming to ERC-721: Deed Standard
/// @author William Entriken (https://phor.net), et al.
/// @dev Specification at https://github.com/ethereum/EIPs/pull/841 (DRAFT)
interface ERC721 {

    // COMPLIANCE WITH ERC-165 (DRAFT) /////////////////////////////////////////

    /// @dev ERC-165 (draft) interface signature for itself
    // bytes4 internal constant INTERFACE_SIGNATURE_ERC165 = // 0x01ffc9a7
    //     bytes4(keccak256('supportsInterface(bytes4)'));

    /// @dev ERC-165 (draft) interface signature for ERC721
    // bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = // 0xda671b9b
    //     bytes4(keccak256('ownerOf(uint256)')) ^
    //     bytes4(keccak256('countOfDeeds()')) ^
    //     bytes4(keccak256('countOfDeedsByOwner(address)')) ^
    //     bytes4(keccak256('deedOfOwnerByIndex(address,uint256)')) ^
    //     bytes4(keccak256('approve(address,uint256)')) ^
    //     bytes4(keccak256('takeOwnership(uint256)'));

    /// @notice Query a contract to see if it supports a certain interface
    /// @dev Returns `true` the interface is supported and `false` otherwise,
    ///  returns `true` for INTERFACE_SIGNATURE_ERC165 and
    ///  INTERFACE_SIGNATURE_ERC721, see ERC-165 for other interface signatures.
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool);

    // PUBLIC QUERY FUNCTIONS //////////////////////////////////////////////////

    /// @notice Find the owner of a deed
    /// @param _deedId The identifier for a deed we are inspecting
    /// @dev Deeds assigned to zero address are considered destroyed, and
    ///  queries about them do throw.
    /// @return The non-zero address of the owner of deed `_deedId`, or `throw`
    ///  if deed `_deedId` is not tracked by this contract
    function ownerOf(uint256 _deedId) external view returns (address _owner);

    /// @notice Count deeds tracked by this contract
    /// @return A count of the deeds tracked by this contract, where each one of
    ///  them has an assigned and queryable owner
    function countOfDeeds() public view returns (uint256 _count);

    /// @notice Count all deeds assigned to an owner
    /// @dev Throws if `_owner` is the zero address, representing destroyed deeds.
    /// @param _owner An address where we are interested in deeds owned by them
    /// @return The number of deeds owned by `_owner`, possibly zero
    function countOfDeedsByOwner(address _owner) public view returns (uint256 _count);

    /// @notice Enumerate deeds assigned to an owner
    /// @dev Throws if `_index` >= `countOfDeedsByOwner(_owner)` or if
    ///  `_owner` is the zero address, representing destroyed deeds.
    /// @param _owner An address where we are interested in deeds owned by them
    /// @param _index A counter between zero and `countOfDeedsByOwner(_owner)`,
    ///  inclusive
    /// @return The identifier for the `_index`th deed assigned to `_owner`,
    ///   (sort order not specified)
    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId);

    // TRANSFER MECHANISM //////////////////////////////////////////////////////

    /// @dev This event emits when ownership of any deed changes by any
    ///  mechanism. This event emits when deeds are created (`from` == 0) and
    ///  destroyed (`to` == 0). Exception: during contract creation, any
    ///  transfers may occur without emitting `Transfer`.
    event Transfer(address indexed from, address indexed to, uint256 indexed deedId);

    /// @dev This event emits on any successful call to
    ///  `approve(address _spender, uint256 _deedId)`. Exception: does not emit
    ///  if an owner revokes approval (`_to` == 0x0) on a deed with no existing
    ///  approval.
    event Approval(address indexed owner, address indexed approved, uint256 indexed deedId);

    /// @notice Approve a new owner to take your deed, or revoke approval by
    ///  setting the zero address. You may `approve` any number of times while
    ///  the deed is assigned to you, only the most recent approval matters.
    /// @dev Throws if `msg.sender` does not own deed `_deedId` or if `_to` ==
    ///  `msg.sender`.
    /// @param _deedId The deed you are granting ownership of
    function approve(address _to, uint256 _deedId) external;

    /// @notice Become owner of a deed for which you are currently approved
    /// @dev Throws if `msg.sender` is not approved to become the owner of
    ///  `deedId` or if `msg.sender` currently owns `_deedId`.
    /// @param _deedId The deed that is being transferred
    function takeOwnership(uint256 _deedId) external;
    
    // SPEC EXTENSIONS /////////////////////////////////////////////////////////
    
    /// @notice Transfer a deed to a new owner.
    /// @dev Throws if `msg.sender` does not own deed `_deedId` or if
    ///  `_to` == 0x0.
    /// @param _to The address of the new owner.
    /// @param _deedId The deed you are transferring.
    function transfer(address _to, uint256 _deedId) external;
}


/// @title Metadata extension to ERC-721 interface
/// @author William Entriken (https://phor.net)
/// @dev Specification at https://github.com/ethereum/EIPs/pull/841 (DRAFT)
interface ERC721Metadata {

    /// @dev ERC-165 (draft) interface signature for ERC721
    // bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata = // 0x2a786f11
    //     bytes4(keccak256('name()')) ^
    //     bytes4(keccak256('symbol()')) ^
    //     bytes4(keccak256('deedUri(uint256)'));

    /// @notice A descriptive name for a collection of deeds managed by this
    ///  contract
    /// @dev Wallets and exchanges MAY display this to the end user.
    function name() public pure returns (string _deedName);

    /// @notice An abbreviated name for deeds managed by this contract
    /// @dev Wallets and exchanges MAY display this to the end user.
    function symbol() public pure returns (string _deedSymbol);

    /// @notice A distinct URI (RFC 3986) for a given token.
    /// @dev If:
    ///  * The URI is a URL
    ///  * The URL is accessible
    ///  * The URL points to a valid JSON file format (ECMA-404 2nd ed.)
    ///  * The JSON base element is an object
    ///  then these names of the base element SHALL have special meaning:
    ///  * "name": A string identifying the item to which `_deedId` grants
    ///    ownership
    ///  * "description": A string detailing the item to which `_deedId` grants
    ///    ownership
    ///  * "image": A URI pointing to a file of image/* mime type representing
    ///    the item to which `_deedId` grants ownership
    ///  Wallets and exchanges MAY display this to the end user.
    ///  Consider making any images at a width between 320 and 1080 pixels and
    ///  aspect ratio between 1.91:1 and 4:5 inclusive.
    function deedUri(uint256 _deedId) external pure returns (string _uri);
}


/// @dev Holds deed functionality such as approving and transferring. Implements ERC721.
contract MetaGameDeed is MetaGameBase, ERC721, ERC721Metadata {
    
    /// @notice Name of the collection of deeds (non-fungible token), as defined in ERC721Metadata.
    function name() public pure returns (string _deedName) {
        _deedName = "MetaGame";
    }
    
    /// @notice Symbol of the collection of deeds (non-fungible token), as defined in ERC721Metadata.
    function symbol() public pure returns (string _deedSymbol) {
        _deedSymbol = "MG";
    }
    
    /// @dev ERC-165 (draft) interface signature for itself
    bytes4 internal constant INTERFACE_SIGNATURE_ERC165 = // 0x01ffc9a7
        bytes4(keccak256('supportsInterface(bytes4)'));

    /// @dev ERC-165 (draft) interface signature for ERC721
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = // 0xda671b9b
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('countOfDeeds()')) ^
        bytes4(keccak256('countOfDeedsByOwner(address)')) ^
        bytes4(keccak256('deedOfOwnerByIndex(address,uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('takeOwnership(uint256)'));
        
    /// @dev ERC-165 (draft) interface signature for ERC721
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata = // 0x2a786f11
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('deedUri(uint256)'));
    
    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    /// Returns true for any standardized interfaces implemented by this contract.
    /// (ERC-165 and ERC-721.)
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return (
            (_interfaceID == INTERFACE_SIGNATURE_ERC165)
            || (_interfaceID == INTERFACE_SIGNATURE_ERC721)
            || (_interfaceID == INTERFACE_SIGNATURE_ERC721Metadata)
        );
    }
    
    /// @dev Checks if a given address owns a particular deed.
    /// @param _owner The address of the owner to check for.
    /// @param _deedId The deed identifier to check for.
    function _owns(address _owner, uint256 _deedId) internal view returns (bool) {
        return identifierToOwner[_deedId] == _owner;
    }
    
    /// @dev Approve a given address to take ownership of a deed.
    /// @param _from The address approving taking ownership.
    /// @param _to The address to approve taking ownership.
    /// @param _deedId The identifier of the deed to give approval for.
    function _approve(address _from, address _to, uint256 _deedId) internal {
        identifierToApproved[_deedId] = _to;
        
        // Emit event.
        Approval(_from, _to, _deedId);
    }
    
    /// @dev Checks if a given address has approval to take ownership of a deed.
    /// @param _claimant The address of the claimant to check for.
    /// @param _deedId The identifier of the deed to check for.
    function _approvedFor(address _claimant, uint256 _deedId) internal view returns (bool) {
        return identifierToApproved[_deedId] == _claimant;
    }
    
    /// @dev Assigns ownership of a specific deed to an address.
    /// @param _from The address to transfer the deed from.
    /// @param _to The address to transfer the deed to.
    /// @param _deedId The identifier of the deed to transfer.
    function _transfer(address _from, address _to, uint256 _deedId) internal {
        // The number of deeds is capped at rows * cols, so this cannot
        // be overflowed if those parameters are sensible.
        ownershipDeedCount[_to]++;
        
        // Transfer ownership.
        identifierToOwner[_deedId] = _to;
        
        // When a new deed is minted, the _from address is 0x0, but we
        // do not track deed ownership of 0x0.
        if (_from != address(0)) {
            ownershipDeedCount[_from]--;
            
            // Clear taking ownership approval.
            delete identifierToApproved[_deedId];
        }
        
        // Emit the transfer event.
        Transfer(_from, _to, _deedId);
    }
    
    // ERC 721 implementation
    
    /// @notice Returns the total number of deeds currently in existence.
    /// @dev Required for ERC-721 compliance.
    function countOfDeeds() public view returns (uint256) {
        return identifiers.length;
    }
    
    /// @notice Returns the number of deeds owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function countOfDeedsByOwner(address _owner) public view returns (uint256) {
        return ownershipDeedCount[_owner];
    }
    
    /// @notice Returns the address currently assigned ownership of a given deed.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _deedId) external view returns (address _owner) {
        _owner = identifierToOwner[_deedId];

        require(_owner != address(0));
    }
    
    /// @notice Approve a given address to take ownership of a deed.
    /// @param _to The address to approve taking owernship.
    /// @param _deedId The identifier of the deed to give approval for.
    /// @dev Required for ERC-721 compliance.
    function approve(address _to, uint256 _deedId) external whenNotPaused {
        uint256[] memory _deedIds = new uint256[](1);
        _deedIds[0] = _deedId;
        
        approveMultiple(_to, _deedIds);
    }
    
    /// @notice Approve a given address to take ownership of multiple deeds.
    /// @param _to The address to approve taking ownership.
    /// @param _deedIds The identifiers of the deeds to give approval for.
    function approveMultiple(address _to, uint256[] _deedIds) public whenNotPaused {
        // Ensure the sender is not approving themselves.
        require(msg.sender != _to);
    
        for (uint256 i = 0; i < _deedIds.length; i++) {
            uint256 _deedId = _deedIds[i];
            
            // Require the sender is the owner of the deed.
            require(_owns(msg.sender, _deedId));
            
            // Perform the approval.
            _approve(msg.sender, _to, _deedId);
        }
    }
    
    /// @notice Transfer a deed to another address. If transferring to a smart
    /// contract be VERY CAREFUL to ensure that it is aware of ERC-721, or your
    /// deed may be lost forever.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _deedId The identifier of the deed to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _deedId) external whenNotPaused {
        uint256[] memory _deedIds = new uint256[](1);
        _deedIds[0] = _deedId;
        
        transferMultiple(_to, _deedIds);
    }
    
    /// @notice Transfers multiple deeds to another address. If transferring to
    /// a smart contract be VERY CAREFUL to ensure that it is aware of ERC-721,
    /// or your deeds may be lost forever.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _deedIds The identifiers of the deeds to transfer.
    function transferMultiple(address _to, uint256[] _deedIds) public whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));
    
        for (uint256 i = 0; i < _deedIds.length; i++) {
            uint256 _deedId = _deedIds[i];
            
            // One can only transfer their own deeds.
            require(_owns(msg.sender, _deedId));

            // Transfer ownership
            _transfer(msg.sender, _to, _deedId);
        }
    }
    
    /// @notice Transfer a deed owned by another address, for which the calling
    /// address has previously been granted transfer approval by the owner.
    /// @param _deedId The identifier of the deed to be transferred.
    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint256 _deedId) external whenNotPaused {
        uint256[] memory _deedIds = new uint256[](1);
        _deedIds[0] = _deedId;
        
        takeOwnershipMultiple(_deedIds);
    }
    
    /// @notice Transfer multiple deeds owned by another address, for which the
    /// calling address has previously been granted transfer approval by the owner.
    /// @param _deedIds The identifier of the deed to be transferred.
    function takeOwnershipMultiple(uint256[] _deedIds) public whenNotPaused {
        for (uint256 i = 0; i < _deedIds.length; i++) {
            uint256 _deedId = _deedIds[i];
            address _from = identifierToOwner[_deedId];
            
            // Check for transfer approval
            require(_approvedFor(msg.sender, _deedId));

            // Reassign ownership (also clears pending approvals and emits Transfer event).
            _transfer(_from, msg.sender, _deedId);
        }
    }
    
    /// @notice Returns a list of all deed identifiers assigned to an address.
    /// @param _owner The owner whose deeds we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. It's very
    /// expensive and is not supported in contract-to-contract calls as it returns
    /// a dynamic array (only supported for web3 calls).
    function deedsOfOwner(address _owner) external view returns(uint256[]) {
        uint256 deedCount = countOfDeedsByOwner(_owner);

        if (deedCount == 0) {
            // Return an empty array.
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](deedCount);
            uint256 totalDeeds = countOfDeeds();
            uint256 resultIndex = 0;
            
            for (uint256 deedNumber = 0; deedNumber < totalDeeds; deedNumber++) {
                uint256 identifier = identifiers[deedNumber];
                if (identifierToOwner[identifier] == _owner) {
                    result[resultIndex] = identifier;
                    resultIndex++;
                }
            }

            return result;
        }
    }
    
    /// @notice Returns a deed identifier of the owner at the given index.
    /// @param _owner The address of the owner we want to get a deed for.
    /// @param _index The index of the deed we want.
    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        // The index should be valid.
        require(_index < countOfDeedsByOwner(_owner));

        // Loop through all deeds, accounting the number of deeds of the owner we've seen.
        uint256 seen = 0;
        uint256 totalDeeds = countOfDeeds();
        
        for (uint256 deedNumber = 0; deedNumber < totalDeeds; deedNumber++) {
            uint256 identifier = identifiers[deedNumber];
            if (identifierToOwner[identifier] == _owner) {
                if (seen == _index) {
                    return identifier;
                }
                
                seen++;
            }
        }
    }
    
    /// @notice Returns an (off-chain) metadata url for the given deed.
    /// @param _deedId The identifier of the deed to get the metadata
    /// url for.
    /// @dev Implementation of optional ERC-721 functionality.
    function deedUri(uint256 _deedId) external pure returns (string uri) {
        // Assume a maximum deed id length.
        require (_deedId < 1000000);
        
        uri = "https://meta.quazr.io/card/xxxxxxx";
        bytes memory _uri = bytes(uri);
        
        for (uint256 i = 0; i < 7; i++) {
            _uri[33 - i] = byte(48 + (_deedId / 10 ** i) % 10);
        }
    }
}


/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}


/// @dev Defines base data structures for DWorld.
contract MetaGameFinance is MetaGameDeed, PullPayment {
    /// @notice The dividend given to all parents of a deed, 
    /// in 1/1000th of a percentage.
    uint256 public dividendPercentage = 1000;
    
    /// @notice The minimum fee for the contract in 1/1000th
    /// of a percentage.
    uint256 public minimumFee = 2500;
    
    /// @notice The minimum total paid in fees and dividends.
    /// If there are (almost) no dividends to be paid, the fee
    /// for the contract is higher. This happens for deeds at
    /// or near the top of the hierarchy. In 1/1000th of a
    /// percentage.
    uint256 public minimumFeePlusDividends = 7000;
    
    // @dev A mapping from deed identifiers to the buyout price.
    mapping (uint256 => uint256) public identifierToPrice;
    
    /// @notice The threshold for a payment to be sent directly,
    /// instead of added to a beneficiary's balance.
    uint256 public directPaymentThreshold = 0 ether;
    
    /// @notice Boolean indicating whether deed price can be changed
    /// manually.
    bool public allowChangePrice = false;
    
    /// @notice The maximum depth for which dividends will be paid to parents.
    uint256 public maxDividendDepth = 6;
    
    /// @dev This event is emitted when a deed's buyout price is initially set or changed.
    event Price(uint256 indexed identifier, uint256 price, uint256 nextPrice);
    
    /// @dev This event is emitted when a deed is bought out.
    event Buy(address indexed oldOwner, address indexed newOwner, uint256 indexed identifier, uint256 price, uint256 ownerWinnings);
    
    /// @dev This event is emitted when a dividend is paid.
    event DividendPaid(address indexed beneficiary, uint256 indexed identifierBought, uint256 indexed identifier, uint256 dividend);
    
    /// @notice Set the threshold for a payment to be sent directly.
    /// @param threshold The threshold for a payment to be sent directly.
    function setDirectPaymentThreshold(uint256 threshold) external onlyCFO {
        directPaymentThreshold = threshold;
    }
    
    /// @notice Set whether prices can be changed manually.
    /// @param _allowChangePrice Bool indiciating wether prices can be changed manually.
    function setAllowChangePrice(bool _allowChangePrice) external onlyCFO {
        allowChangePrice = _allowChangePrice;
    }
    
    /// @notice Set the maximum dividend depth.
    /// @param _maxDividendDepth The maximum dividend depth.
    function setMaxDividendDepth(uint256 _maxDividendDepth) external onlyCFO {
        maxDividendDepth = _maxDividendDepth;
    }
    
    /// @notice Calculate the next price given the current price.
    /// @param currentPrice The current price.
    function nextPrice(uint256 currentPrice) public pure returns(uint256) {
        if (currentPrice < 1 ether) {
            return currentPrice.mul(200).div(100); // 100% increase
        } else if (currentPrice < 5 ether) {
            return currentPrice.mul(150).div(100); // 50% increase
        } else {
            return currentPrice.mul(135).div(100); // 35% increase
        }
    }
    
    /// @notice Set the price of a deed.
    /// @param identifier The identifier of the deed to change the price of.
    /// @param newPrice The new price of the deed.
    function changeDeedPrice(uint256 identifier, uint256 newPrice) public {
        // The message sender must be the deed owner.
        require(identifierToOwner[identifier] == msg.sender);
        
        // Price changes must be enabled.
        require(allowChangePrice);
        
        // The new price must be lower than the current price.
        require(newPrice < identifierToPrice[identifier]);
        
        // Set the new price.
        identifierToPrice[identifier] = newPrice;
        Price(identifier, newPrice, nextPrice(newPrice));
    }
    
    /// @notice Set the initial price of a deed.
    /// @param identifier The identifier of the deed to change the price of.
    /// @param newPrice The new price of the deed.
    function changeInitialPrice(uint256 identifier, uint256 newPrice) public onlyCFO {        
        // The deed must be owned by the contract.
        require(identifierToOwner[identifier] == address(this));
        
        // Set the new price.
        identifierToPrice[identifier] = newPrice;
        Price(identifier, newPrice, nextPrice(newPrice));
    }
    
    /// @dev Pay dividends to parents of a deed.
    /// @param identifierBought The identifier of the deed that was bought.
    /// @param identifier The identifier of the deed to pay its parents dividends for (recursed).
    /// @param dividend The dividend to be paid to parents of the deed.
    /// @param depth The depth of this dividend.
    function _payDividends(uint256 identifierBought, uint256 identifier, uint256 dividend, uint256 depth)
        internal
        returns(uint256 totalDividendsPaid)
    {
        uint256 parentIdentifier = identifierToParentIdentifier[identifier];
        
        if (parentIdentifier != 0 && depth < maxDividendDepth) {
            address parentOwner = identifierToOwner[parentIdentifier];
        
            if (parentOwner != address(this)) {            
                // Send dividend to the owner of the parent.
                _sendFunds(parentOwner, dividend);
                DividendPaid(parentOwner, identifierBought, parentIdentifier, dividend);
            }
            
            totalDividendsPaid = dividend;
        
            // Recursively pay dividends to parents of parents.
            uint256 dividendsPaid = _payDividends(identifierBought, parentIdentifier, dividend, depth + 1);
            
            totalDividendsPaid = totalDividendsPaid.add(dividendsPaid);
        } else {
            // Not strictly necessary to set this to 0 explicitly... but makes
            // it clearer to see what happens.
            totalDividendsPaid = 0;
        }
    }
    
    /// @dev Calculate the contract fee.
    /// @param price The price of the buyout.
    /// @param dividendsPaid The total amount paid in dividends.
    function calculateFee(uint256 price, uint256 dividendsPaid) public view returns(uint256 fee) {
        // Calculate the absolute minimum fee.
        fee = price.mul(minimumFee).div(100000);
        
        // Calculate the minimum fee plus dividends payable.
        // See also the explanation at the definition of
        // minimumFeePlusDividends.
        uint256 _minimumFeePlusDividends = price.mul(minimumFeePlusDividends).div(100000);
        
        if (_minimumFeePlusDividends > dividendsPaid) {
            uint256 feeMinusDividends = _minimumFeePlusDividends.sub(dividendsPaid);
        
            // The minimum total paid in 'fees plus dividends', minus dividends, is
            // greater than the minimum fee. Set the fee to this value.
            if (feeMinusDividends > fee) {
                fee = feeMinusDividends;
            }
        }
    }
    
    /// @dev Send funds to a beneficiary. If sending fails, assign
    /// funds to the beneficiary's balance for manual withdrawal.
    /// @param beneficiary The beneficiary's address to send funds to
    /// @param amount The amount to send.
    function _sendFunds(address beneficiary, uint256 amount) internal {
        if (amount < directPaymentThreshold) {
            // Amount is under send threshold. Send funds asynchronously
            // for manual withdrawal by the beneficiary.
            asyncSend(beneficiary, amount);
        } else if (!beneficiary.send(amount)) {
            // Failed to send funds. This can happen due to a failure in
            // fallback code of the beneficiary, or because of callstack
            // depth.
            // Send funds asynchronously for manual withdrawal by the
            // beneficiary.
            asyncSend(beneficiary, amount);
        }
    }
    
    /// @notice Withdraw (unowed) contract balance.
    function withdrawFreeBalance() external onlyCFO {
        // Calculate the free (unowed) balance. This never underflows, as
        // totalPayments is guaranteed to be less than or equal to the
        // contract balance.
        uint256 freeBalance = this.balance - totalPayments;
        
        cfoAddress.transfer(freeBalance);
    }
}


/// @dev Defines core meta game functionality.
contract MetaGameCore is MetaGameFinance {
    
    function MetaGameCore() public {
        // Start the contract paused.
        paused = true;
    }
    
    /// @notice Create a collectible.
    /// @param identifier The identifier of the collectible that is to be created.
    /// @param owner The address of the initial owner. Blank if this contract should
    /// be the initial owner.
    /// @param parentIdentifier The identifier of the parent of the collectible, which
    /// receives dividends when this collectible trades.
    /// @param price The initial price of the collectible.
    function createCollectible(uint256 identifier, address owner, uint256 parentIdentifier, uint256 price) external onlyCFO {
        // The identifier must be valid. Identifier 0 is reserved
        // to mark a collectible as having no parent.
        require(identifier >= 1);
    
        // The identifier must not exist yet.
        require(identifierToOwner[identifier] == 0x0);
        
        // Add the identifier to the list of existing identifiers.
        identifiers.push(identifier);
        
        address initialOwner = owner;
        
        if (initialOwner == 0x0) {
            // Set the initial owner to be the contract itself.
            initialOwner = address(this);
        }
        
        // Transfer the collectible to the initial owner.
        _transfer(0x0, initialOwner, identifier);
        
        // Set the parent identifier.
        identifierToParentIdentifier[identifier] = parentIdentifier;
        
        // Set the initial price.
        identifierToPrice[identifier] = price;
        
        // Emit price event.
        Price(identifier, price, nextPrice(price));
    }
    
    /// @notice Set the parent collectible of a collectible.
    function setParent(uint256 identifier, uint256 parentIdentifier) external onlyCFO {
        // The deed must exist.
        require(identifierToOwner[identifier] != 0x0);
        
        identifierToParentIdentifier[identifier] = parentIdentifier;
    }
    
    /// @notice Buy a collectible.
    function buy(uint256 identifier) external payable whenNotPaused {
        // The collectible must exist.
        require(identifierToOwner[identifier] != 0x0);
        
        address oldOwner = identifierToOwner[identifier];
        uint256 price = identifierToPrice[identifier];
        
        // The old owner must not be the same as the buyer.
        require(oldOwner != msg.sender);
        
        // Enough ether must be provided.
        require(msg.value >= price);
        
        // Set the new price.
        uint256 newPrice = nextPrice(price);
        identifierToPrice[identifier] = newPrice;
        
        // Transfer the collectible.
        _transfer(oldOwner, msg.sender, identifier);
        
        // Emit price change event.
        Price(identifier, newPrice, nextPrice(newPrice));
        
        // Pay dividends.
        uint256 dividend = price.mul(dividendPercentage).div(100000);
        uint256 dividendsPaid = _payDividends(identifier, identifier, dividend, 0);
        
        // Calculate the contract fee.
        uint256 fee = calculateFee(price, dividendsPaid);
        
        // Calculate the winnings for the previous owner.
        uint256 oldOwnerWinnings = price.sub(dividendsPaid).sub(fee);
        
        // Emit buy event.
        Buy(oldOwner, msg.sender, identifier, price, oldOwnerWinnings);
        
        if (oldOwner != address(this)) {
            // The old owner is not this contract itself.
            // Pay the old owner.
            _sendFunds(oldOwner, oldOwnerWinnings);
        }
        
        // Calculate overspent ether. This cannot underflow, as the require
        // guarantees price to be greater than or equal to msg.value.
        uint256 excess = price - msg.value;
        
        if (excess > 0) {
            // Refund overspent Ether.
            msg.sender.transfer(excess);
        }
    }
    
    /// @notice Return a collectible's details.
    /// @param identifier The identifier of the collectible to get details for.
    function getDeed(uint256 identifier)
        external
        view
        returns(uint256 deedId, address owner, uint256 buyPrice, uint256 nextBuyPrice)
    {
        deedId = identifier;
        owner = identifierToOwner[identifier];
        buyPrice = identifierToPrice[identifier];
        nextBuyPrice = nextPrice(buyPrice);
    }
}