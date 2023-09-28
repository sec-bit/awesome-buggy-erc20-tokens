pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

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
  uint256 public totalSupply;
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


/// @dev Implements access control to the DWorld contract.
contract DWorldAccessControl is Claimable, Pausable, CanReclaimToken {
    address public cfoAddress;

    function DWorldAccessControl() public {
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
contract DWorldBase is DWorldAccessControl {
    using SafeMath for uint256;
    
    /// @dev All minted plots (array of plot identifiers). There are
    /// 2^16 * 2^16 possible plots (covering the entire world), thus
    /// 32 bits are required. This fits in a uint32. Storing
    /// the identifiers as uint32 instead of uint256 makes storage
    /// cheaper. (The impact of this in mappings is less noticeable,
    /// and using uint32 in the mappings below actually *increases*
    /// gas cost for minting).
    uint32[] public plots;
    
    mapping (uint256 => address) identifierToOwner;
    mapping (uint256 => address) identifierToApproved;
    mapping (address => uint256) ownershipDeedCount;
    
    /// @dev Event fired when a plot's data are changed. The plot
    /// data are not stored in the contract directly, instead the
    /// data are logged to the block. This gives significant
    /// reductions in gas requirements (~75k for minting with data
    /// instead of ~180k). However, it also means plot data are
    /// not available from *within* other contracts.
    event SetData(uint256 indexed deedId, string name, string description, string imageUrl, string infoUrl);
    
    /// @notice Get all minted plots.
    function getAllPlots() external view returns(uint32[]) {
        return plots;
    }
    
    /// @dev Represent a 2D coordinate as a single uint.
    /// @param x The x-coordinate.
    /// @param y The y-coordinate.
    function coordinateToIdentifier(uint256 x, uint256 y) public pure returns(uint256) {
        require(validCoordinate(x, y));
        
        return (y << 16) + x;
    }
    
    /// @dev Turn a single uint representation of a coordinate into its x and y parts.
    /// @param identifier The uint representation of a coordinate.
    function identifierToCoordinate(uint256 identifier) public pure returns(uint256 x, uint256 y) {
        require(validIdentifier(identifier));
    
        y = identifier >> 16;
        x = identifier - (y << 16);
    }
    
    /// @dev Test whether the coordinate is valid.
    /// @param x The x-part of the coordinate to test.
    /// @param y The y-part of the coordinate to test.
    function validCoordinate(uint256 x, uint256 y) public pure returns(bool) {
        return x < 65536 && y < 65536; // 2^16
    }
    
    /// @dev Test whether an identifier is valid.
    /// @param identifier The identifier to test.
    function validIdentifier(uint256 identifier) public pure returns(bool) {
        return identifier < 4294967296; // 2^16 * 2^16
    }
    
    /// @dev Set a plot's data.
    /// @param identifier The identifier of the plot to set data for.
    function _setPlotData(uint256 identifier, string name, string description, string imageUrl, string infoUrl) internal {
        SetData(identifier, name, description, imageUrl, infoUrl);
    }
}


/// @dev Holds deed functionality such as approving and transferring. Implements ERC721.
contract DWorldDeed is DWorldBase, ERC721, ERC721Metadata {
    
    /// @notice Name of the collection of deeds (non-fungible token), as defined in ERC721Metadata.
    function name() public pure returns (string _deedName) {
        _deedName = "DWorld Plots";
    }
    
    /// @notice Symbol of the collection of deeds (non-fungible token), as defined in ERC721Metadata.
    function symbol() public pure returns (string _deedSymbol) {
        _deedSymbol = "DWP";
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
    
    /// @dev Checks if a given address owns a particular plot.
    /// @param _owner The address of the owner to check for.
    /// @param _deedId The plot identifier to check for.
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
        // The number of plots is capped at 2^16 * 2^16, so this cannot
        // be overflowed.
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
        return plots.length;
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
            
            // One can only transfer their own plots.
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
                uint256 identifier = plots[deedNumber];
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

        // Loop through all plots, accounting the number of plots of the owner we've seen.
        uint256 seen = 0;
        uint256 totalDeeds = countOfDeeds();
        
        for (uint256 deedNumber = 0; deedNumber < totalDeeds; deedNumber++) {
            uint256 identifier = plots[deedNumber];
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
        require(validIdentifier(_deedId));
    
        var (x, y) = identifierToCoordinate(_deedId);
    
        // Maximum coordinate length in decimals is 5 (65535)
        uri = "https://dworld.io/plot/xxxxx/xxxxx";
        bytes memory _uri = bytes(uri);
        
        for (uint256 i = 0; i < 5; i++) {
            _uri[27 - i] = byte(48 + (x / 10 ** i) % 10);
            _uri[33 - i] = byte(48 + (y / 10 ** i) % 10);
        }
    }
}


/// @dev Implements renting functionality.
contract DWorldRenting is DWorldDeed {
    event Rent(address indexed renter, uint256 indexed deedId, uint256 rentPeriodEndTimestamp, uint256 rentPeriod);
    mapping (uint256 => address) identifierToRenter;
    mapping (uint256 => uint256) identifierToRentPeriodEndTimestamp;

    /// @dev Checks if a given address rents a particular plot.
    /// @param _renter The address of the renter to check for.
    /// @param _deedId The plot identifier to check for.
    function _rents(address _renter, uint256 _deedId) internal view returns (bool) {
        return identifierToRenter[_deedId] == _renter && identifierToRentPeriodEndTimestamp[_deedId] >= now;
    }
    
    /// @dev Rent out a deed to an address.
    /// @param _to The address to rent the deed out to.
    /// @param _rentPeriod The rent period in seconds.
    /// @param _deedId The identifier of the deed to rent out.
    function _rentOut(address _to, uint256 _rentPeriod, uint256 _deedId) internal {
        // Set the renter and rent period end timestamp
        uint256 rentPeriodEndTimestamp = now.add(_rentPeriod);
        identifierToRenter[_deedId] = _to;
        identifierToRentPeriodEndTimestamp[_deedId] = rentPeriodEndTimestamp;
        
        Rent(_to, _deedId, rentPeriodEndTimestamp, _rentPeriod);
    }
    
    /// @notice Rents a plot out to another address.
    /// @param _to The address of the renter, can be a user or contract.
    /// @param _rentPeriod The rent time period in seconds.
    /// @param _deedId The identifier of the plot to rent out.
    function rentOut(address _to, uint256 _rentPeriod, uint256 _deedId) external whenNotPaused {
        uint256[] memory _deedIds = new uint256[](1);
        _deedIds[0] = _deedId;
        
        rentOutMultiple(_to, _rentPeriod, _deedIds);
    }
    
    /// @notice Rents multiple plots out to another address.
    /// @param _to The address of the renter, can be a user or contract.
    /// @param _rentPeriod The rent time period in seconds.
    /// @param _deedIds The identifiers of the plots to rent out.
    function rentOutMultiple(address _to, uint256 _rentPeriod, uint256[] _deedIds) public whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        
        // Disallow transfers to this contract to prevent accidental misuse.
        require(_to != address(this));
        
        for (uint256 i = 0; i < _deedIds.length; i++) {
            uint256 _deedId = _deedIds[i];
            
            require(validIdentifier(_deedId));
        
            // There should not be an active renter.
            require(identifierToRentPeriodEndTimestamp[_deedId] < now);
            
            // One can only rent out their own plots.
            require(_owns(msg.sender, _deedId));
            
            _rentOut(_to, _rentPeriod, _deedId);
        }
    }
    
    /// @notice Returns the address of the currently assigned renter and
    /// end time of the rent period of a given plot.
    /// @param _deedId The identifier of the deed to get the renter and 
    /// rent period for.
    function renterOf(uint256 _deedId) external view returns (address _renter, uint256 _rentPeriodEndTimestamp) {
        require(validIdentifier(_deedId));
    
        if (identifierToRentPeriodEndTimestamp[_deedId] < now) {
            // There is no active renter
            _renter = address(0);
            _rentPeriodEndTimestamp = 0;
        } else {
            _renter = identifierToRenter[_deedId];
            _rentPeriodEndTimestamp = identifierToRentPeriodEndTimestamp[_deedId];
        }
    }
}


/// @title The internal clock auction functionality.
/// Inspired by CryptoKitties' clock auction
contract ClockAuctionBase {

    // Address of the ERC721 contract this auction is linked to.
    ERC721 public deedContract;

    // Fee per successful auction in 1/1000th of a percentage.
    uint256 public fee;
    
    // Total amount of ether yet to be paid to auction beneficiaries.
    uint256 public outstandingEther = 0 ether;
    
    // Amount of ether yet to be paid per beneficiary.
    mapping (address => uint256) public addressToEtherOwed;
    
    /// @dev Represents a deed auction.
    /// Care has been taken to ensure the auction fits in
    /// two 256-bit words.
    struct Auction {
        address seller;
        uint128 startPrice;
        uint128 endPrice;
        uint64 duration;
        uint64 startedAt;
    }

    mapping (uint256 => Auction) identifierToAuction;
    
    // Events
    event AuctionCreated(address indexed seller, uint256 indexed deedId, uint256 startPrice, uint256 endPrice, uint256 duration);
    event AuctionSuccessful(address indexed buyer, uint256 indexed deedId, uint256 totalPrice);
    event AuctionCancelled(uint256 indexed deedId);
    
    /// @dev Modifier to check whether the value can be stored in a 64 bit uint.
    modifier fitsIn64Bits(uint256 _value) {
        require (_value == uint256(uint64(_value)));
        _;
    }
    
    /// @dev Modifier to check whether the value can be stored in a 128 bit uint.
    modifier fitsIn128Bits(uint256 _value) {
        require (_value == uint256(uint128(_value)));
        _;
    }
    
    function ClockAuctionBase(address _deedContractAddress, uint256 _fee) public {
        deedContract = ERC721(_deedContractAddress);
        
        // Contract must indicate support for ERC721 through its interface signature.
        require(deedContract.supportsInterface(0xda671b9b));
        
        // Fee must be between 0 and 100%.
        require(0 <= _fee && _fee <= 100000);
        fee = _fee;
    }
    
    /// @dev Checks whether the given auction is active.
    /// @param auction The auction to check for activity.
    function _activeAuction(Auction storage auction) internal view returns (bool) {
        return auction.startedAt > 0;
    }
    
    /// @dev Put the deed into escrow, thereby taking ownership of it.
    /// @param _deedId The identifier of the deed to place into escrow.
    function _escrow(uint256 _deedId) internal {
        // Throws if the transfer fails
        deedContract.takeOwnership(_deedId);
    }
    
    /// @dev Create the auction.
    /// @param _deedId The identifier of the deed to create the auction for.
    /// @param auction The auction to create.
    function _createAuction(uint256 _deedId, Auction auction) internal {
        // Add the auction to the auction mapping.
        identifierToAuction[_deedId] = auction;
        
        // Trigger auction created event.
        AuctionCreated(auction.seller, _deedId, auction.startPrice, auction.endPrice, auction.duration);
    }
    
    /// @dev Bid on an auction.
    /// @param _buyer The address of the buyer.
    /// @param _value The value sent by the sender (in ether).
    /// @param _deedId The identifier of the deed to bid on.
    function _bid(address _buyer, uint256 _value, uint256 _deedId) internal {
        Auction storage auction = identifierToAuction[_deedId];
        
        // The auction must be active.
        require(_activeAuction(auction));
        
        // Calculate the auction's current price.
        uint256 price = _currentPrice(auction);
        
        // Make sure enough funds were sent.
        require(_value >= price);
        
        address seller = auction.seller;
    
        if (price > 0) {
            uint256 totalFee = _calculateFee(price);
            uint256 proceeds = price - totalFee;
            
            // Assign the proceeds to the seller.
            // We do not send the proceeds directly, as to prevent
            // malicious sellers from denying auctions (and burning
            // the buyer's gas).
            _assignProceeds(seller, proceeds);
        }
        
        AuctionSuccessful(_buyer, _deedId, price);
        
        // The bid was won!
        _winBid(seller, _buyer, _deedId, price);
        
        // Remove the auction (we do this at the end, as
        // winBid might require some additional information
        // that will be removed when _removeAuction is
        // called. As we do not transfer funds here, we do
        // not have to worry about re-entry attacks.
        _removeAuction(_deedId);
    }

    /// @dev Perform the bid win logic (in this case: transfer the deed).
    /// @param _seller The address of the seller.
    /// @param _winner The address of the winner.
    /// @param _deedId The identifier of the deed.
    /// @param _price The price the auction was bought at.
    function _winBid(address _seller, address _winner, uint256 _deedId, uint256 _price) internal {
        _transfer(_winner, _deedId);
    }
    
    /// @dev Cancel an auction.
    /// @param _deedId The identifier of the deed for which the auction should be cancelled.
    /// @param auction The auction to cancel.
    function _cancelAuction(uint256 _deedId, Auction auction) internal {
        // Remove the auction
        _removeAuction(_deedId);
        
        // Transfer the deed back to the seller
        _transfer(auction.seller, _deedId);
        
        // Trigger auction cancelled event.
        AuctionCancelled(_deedId);
    }
    
    /// @dev Remove an auction.
    /// @param _deedId The identifier of the deed for which the auction should be removed.
    function _removeAuction(uint256 _deedId) internal {
        delete identifierToAuction[_deedId];
    }
    
    /// @dev Transfer a deed owned by this contract to another address.
    /// @param _to The address to transfer the deed to.
    /// @param _deedId The identifier of the deed.
    function _transfer(address _to, uint256 _deedId) internal {
        // Throws if the transfer fails
        deedContract.transfer(_to, _deedId);
    }
    
    /// @dev Assign proceeds to an address.
    /// @param _to The address to assign proceeds to.
    /// @param _value The proceeds to assign.
    function _assignProceeds(address _to, uint256 _value) internal {
        outstandingEther += _value;
        addressToEtherOwed[_to] += _value;
    }
    
    /// @dev Calculate the current price of an auction.
    function _currentPrice(Auction storage _auction) internal view returns (uint256) {
        require(now >= _auction.startedAt);
        
        uint256 secondsPassed = now - _auction.startedAt;
        
        if (secondsPassed >= _auction.duration) {
            return _auction.endPrice;
        } else {
            // Negative if the end price is higher than the start price!
            int256 totalPriceChange = int256(_auction.endPrice) - int256(_auction.startPrice);
            
            // Calculate the current price based on the total change over the entire
            // auction duration, and the amount of time passed since the start of the
            // auction.
            int256 currentPriceChange = totalPriceChange * int256(secondsPassed) / int256(_auction.duration);
            
            // Calculate the final price. Note this once again
            // is representable by a uint256, as the price can
            // never be negative.
            int256 price = int256(_auction.startPrice) + currentPriceChange;
            
            // This never throws.
            assert(price >= 0);
            
            return uint256(price);
        }
    }
    
    /// @dev Calculate the fee for a given price.
    /// @param _price The price to calculate the fee for.
    function _calculateFee(uint256 _price) internal view returns (uint256) {
        // _price is guaranteed to fit in a uint128 due to the createAuction entry
        // modifiers, so this cannot overflow.
        return _price * fee / 100000;
    }
}


contract ClockAuction is ClockAuctionBase, Pausable {
    function ClockAuction(address _deedContractAddress, uint256 _fee) 
        ClockAuctionBase(_deedContractAddress, _fee)
        public
    {}
    
    /// @notice Update the auction fee.
    /// @param _fee The new fee.
    function setFee(uint256 _fee) external onlyOwner {
        require(0 <= _fee && _fee <= 100000);
    
        fee = _fee;
    }
    
    /// @notice Get the auction for the given deed.
    /// @param _deedId The identifier of the deed to get the auction for.
    /// @dev Throws if there is no auction for the given deed.
    function getAuction(uint256 _deedId) external view returns (
            address seller,
            uint256 startPrice,
            uint256 endPrice,
            uint256 duration,
            uint256 startedAt
        )
    {
        Auction storage auction = identifierToAuction[_deedId];
        
        // The auction must be active
        require(_activeAuction(auction));
        
        return (
            auction.seller,
            auction.startPrice,
            auction.endPrice,
            auction.duration,
            auction.startedAt
        );
    }

    /// @notice Create an auction for a given deed.
    /// Must previously have been given approval to take ownership of the deed.
    /// @param _deedId The identifier of the deed to create an auction for.
    /// @param _startPrice The starting price of the auction.
    /// @param _endPrice The ending price of the auction.
    /// @param _duration The duration in seconds of the dynamic pricing part of the auction.
    function createAuction(uint256 _deedId, uint256 _startPrice, uint256 _endPrice, uint256 _duration)
        public
        fitsIn128Bits(_startPrice)
        fitsIn128Bits(_endPrice)
        fitsIn64Bits(_duration)
        whenNotPaused
    {
        // Get the owner of the deed to be auctioned
        address deedOwner = deedContract.ownerOf(_deedId);
    
        // Caller must either be the deed contract or the owner of the deed
        // to prevent abuse.
        require(
            msg.sender == address(deedContract) ||
            msg.sender == deedOwner
        );
    
        // The duration of the auction must be at least 60 seconds.
        require(_duration >= 60);
    
        // Throws if placing the deed in escrow fails (the contract requires
        // transfer approval prior to creating the auction).
        _escrow(_deedId);
        
        // Auction struct
        Auction memory auction = Auction(
            deedOwner,
            uint128(_startPrice),
            uint128(_endPrice),
            uint64(_duration),
            uint64(now)
        );
        
        _createAuction(_deedId, auction);
    }
    
    /// @notice Cancel an auction
    /// @param _deedId The identifier of the deed to cancel the auction for.
    function cancelAuction(uint256 _deedId) external whenNotPaused {
        Auction storage auction = identifierToAuction[_deedId];
        
        // The auction must be active.
        require(_activeAuction(auction));
        
        // The auction can only be cancelled by the seller
        require(msg.sender == auction.seller);
        
        _cancelAuction(_deedId, auction);
    }
    
    /// @notice Bid on an auction.
    /// @param _deedId The identifier of the deed to bid on.
    function bid(uint256 _deedId) external payable whenNotPaused {
        // Throws if the bid does not succeed.
        _bid(msg.sender, msg.value, _deedId);
    }
    
    /// @dev Returns the current price of an auction.
    /// @param _deedId The identifier of the deed to get the currency price for.
    function getCurrentPrice(uint256 _deedId) external view returns (uint256) {
        Auction storage auction = identifierToAuction[_deedId];
        
        // The auction must be active.
        require(_activeAuction(auction));
        
        return _currentPrice(auction);
    }
    
    /// @notice Withdraw ether owed to a beneficiary.
    /// @param beneficiary The address to withdraw the auction balance for.
    function withdrawAuctionBalance(address beneficiary) external {
        // The sender must either be the beneficiary or the core deed contract.
        require(
            msg.sender == beneficiary ||
            msg.sender == address(deedContract)
        );
        
        uint256 etherOwed = addressToEtherOwed[beneficiary];
        
        // Ensure ether is owed to the beneficiary.
        require(etherOwed > 0);
         
        // Set ether owed to 0   
        delete addressToEtherOwed[beneficiary];
        
        // Subtract from total outstanding balance. etherOwed is guaranteed
        // to be less than or equal to outstandingEther, so this cannot
        // underflow.
        outstandingEther -= etherOwed;
        
        // Transfer ether owed to the beneficiary (not susceptible to re-entry
        // attack, as the ether owed is set to 0 before the transfer takes place).
        beneficiary.transfer(etherOwed);
    }
    
    /// @notice Withdraw (unowed) contract balance.
    function withdrawFreeBalance() external {
        // Calculate the free (unowed) balance. This never underflows, as
        // outstandingEther is guaranteed to be less than or equal to the
        // contract balance.
        uint256 freeBalance = this.balance - outstandingEther;
        
        address deedContractAddress = address(deedContract);

        require(
            msg.sender == owner ||
            msg.sender == deedContractAddress
        );
        
        deedContractAddress.transfer(freeBalance);
    }
}


contract SaleAuction is ClockAuction {
    function SaleAuction(address _deedContractAddress, uint256 _fee) ClockAuction(_deedContractAddress, _fee) public {}
    
    /// @dev Allows other contracts to check whether this is the expected contract.
    bool public isSaleAuction = true;
}


contract RentAuction is ClockAuction {
    function RentAuction(address _deedContractAddress, uint256 _fee) ClockAuction(_deedContractAddress, _fee) public {}
    
    /// @dev Allows other contracts to check whether this is the expected contract.
    bool public isRentAuction = true;
    
    mapping (uint256 => uint256) public identifierToRentPeriod;
    
    /// @notice Create an auction for a given deed. Be careful when calling
    /// createAuction for a RentAuction, that this overloaded function (including
    /// the _rentPeriod parameter) is used. Otherwise the rent period defaults to
    /// a week.
    /// Must previously have been given approval to take ownership of the deed.
    /// @param _deedId The identifier of the deed to create an auction for.
    /// @param _startPrice The starting price of the auction.
    /// @param _endPrice The ending price of the auction.
    /// @param _duration The duration in seconds of the dynamic pricing part of the auction.
    /// @param _rentPeriod The rent period in seconds being auctioned.
    function createAuction(
        uint256 _deedId,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _duration,
        uint256 _rentPeriod
    )
        external
    {
        // Require the rent period to be at least one hour.
        require(_rentPeriod >= 3600);
        
        // Require there to be no active renter.
        DWorldRenting dWorldRentingContract = DWorldRenting(deedContract);
        var (renter,) = dWorldRentingContract.renterOf(_deedId);
        require(renter == address(0));
    
        // Set the rent period.
        identifierToRentPeriod[_deedId] = _rentPeriod;
    
        // Throws (reverts) if creating the auction fails.
        createAuction(_deedId, _startPrice, _endPrice, _duration);
    }
    
    /// @dev Perform the bid win logic (in this case: give renter status to the winner).
    /// @param _seller The address of the seller.
    /// @param _winner The address of the winner.
    /// @param _deedId The identifier of the deed.
    /// @param _price The price the auction was bought at.
    function _winBid(address _seller, address _winner, uint256 _deedId, uint256 _price) internal {
        DWorldRenting dWorldRentingContract = DWorldRenting(deedContract);
    
        uint256 rentPeriod = identifierToRentPeriod[_deedId];
        if (rentPeriod == 0) {
            rentPeriod = 604800; // 1 week by default
        }
    
        // Rent the deed out to the winner.
        dWorldRentingContract.rentOut(_winner, identifierToRentPeriod[_deedId], _deedId);
        
        // Transfer the deed back to the seller.
        _transfer(_seller, _deedId);
    }
    
    /// @dev Remove an auction.
    /// @param _deedId The identifier of the deed for which the auction should be removed.
    function _removeAuction(uint256 _deedId) internal {
        delete identifierToAuction[_deedId];
        delete identifierToRentPeriod[_deedId];
    }
}


/// @dev Holds functionality for minting new plot deeds.
contract DWorldMinting is DWorldRenting {
    uint256 public unclaimedPlotPrice = 0.0025 ether;
    mapping (address => uint256) freeClaimAllowance;
    
    /// @notice Sets the new price for unclaimed plots.
    /// @param _unclaimedPlotPrice The new price for unclaimed plots.
    function setUnclaimedPlotPrice(uint256 _unclaimedPlotPrice) external onlyCFO {
        unclaimedPlotPrice = _unclaimedPlotPrice;
    }
    
    /// @notice Set the free claim allowance for an address.
    /// @param addr The address to set the free claim allowance for.
    /// @param allowance The free claim allowance to set.
    function setFreeClaimAllowance(address addr, uint256 allowance) external onlyCFO {
        freeClaimAllowance[addr] = allowance;
    }
    
    /// @notice Get the free claim allowance of an address.
    /// @param addr The address to get the free claim allowance of.
    function freeClaimAllowanceOf(address addr) external view returns (uint256) {
        return freeClaimAllowance[addr];
    }
       
    /// @notice Buy an unclaimed plot.
    /// @param _deedId The unclaimed plot to buy.
    function claimPlot(uint256 _deedId) external payable whenNotPaused {
        claimPlotWithData(_deedId, "", "", "", "");
    }
       
    /// @notice Buy an unclaimed plot.
    /// @param _deedId The unclaimed plot to buy.
    /// @param name The name to give the plot.
    /// @param description The description to add to the plot.
    /// @param imageUrl The image url for the plot.
    /// @param infoUrl The info url for the plot.
    function claimPlotWithData(uint256 _deedId, string name, string description, string imageUrl, string infoUrl) public payable whenNotPaused {
        uint256[] memory _deedIds = new uint256[](1);
        _deedIds[0] = _deedId;
        
        claimPlotMultipleWithData(_deedIds, name, description, imageUrl, infoUrl);
    }
    
    /// @notice Buy unclaimed plots.
    /// @param _deedIds The unclaimed plots to buy.
    function claimPlotMultiple(uint256[] _deedIds) external payable whenNotPaused {
        claimPlotMultipleWithData(_deedIds, "", "", "", "");
    }
    
    /// @notice Buy unclaimed plots.
    /// @param _deedIds The unclaimed plots to buy.
    /// @param name The name to give the plots.
    /// @param description The description to add to the plots.
    /// @param imageUrl The image url for the plots.
    /// @param infoUrl The info url for the plots.
    function claimPlotMultipleWithData(uint256[] _deedIds, string name, string description, string imageUrl, string infoUrl) public payable whenNotPaused {
        uint256 buyAmount = _deedIds.length;
        uint256 etherRequired;
        if (freeClaimAllowance[msg.sender] > 0) {
            // The sender has a free claim allowance.
            if (freeClaimAllowance[msg.sender] > buyAmount) {
                // Subtract from allowance.
                freeClaimAllowance[msg.sender] -= buyAmount;
                
                // No ether is required.
                etherRequired = 0;
            } else {
                uint256 freeAmount = freeClaimAllowance[msg.sender];
                
                // The full allowance has been used.
                delete freeClaimAllowance[msg.sender];
                
                // The subtraction cannot underflow, as freeAmount <= buyAmount.
                etherRequired = unclaimedPlotPrice.mul(buyAmount - freeAmount);
            }
        } else {
            // The sender does not have a free claim allowance.
            etherRequired = unclaimedPlotPrice.mul(buyAmount);
        }
        
        // Ensure enough ether is supplied.
        require(msg.value >= etherRequired);
        
        uint256 offset = plots.length;
        
        // Allocate additional memory for the plots array
        // (this is more efficient than .push-ing each individual
        // plot, as that requires multiple dynamic allocations).
        plots.length = plots.length.add(_deedIds.length);
        
        for (uint256 i = 0; i < _deedIds.length; i++) { 
            uint256 _deedId = _deedIds[i];
            require(validIdentifier(_deedId));
            
            // The plot must be unowned (a plot deed cannot be transferred to
            // 0x0, so once a plot is claimed it will always be owned by a
            // non-zero address).
            require(identifierToOwner[_deedId] == address(0));
            
            // Create the plot
            plots[offset + i] = uint32(_deedId);
            
            // Transfer the new plot to the sender.
            _transfer(address(0), msg.sender, _deedId);
            
            // Set the plot data.
            _setPlotData(_deedId, name, description, imageUrl, infoUrl);
        }
        
        // Calculate the excess ether sent
        // msg.value is greater than or equal to etherRequired,
        // so this cannot underflow.
        uint256 excess = msg.value - etherRequired;
        
        if (excess > 0) {
            // Refund any excess ether (not susceptible to re-entry attack, as
            // the owner is assigned before the transfer takes place).
            msg.sender.transfer(excess);
        }
    }
}


/// @dev Implements DWorld auction functionality.
contract DWorldAuction is DWorldMinting {
    SaleAuction public saleAuctionContract;
    RentAuction public rentAuctionContract;
    
    /// @notice set the contract address of the sale auction.
    /// @param _address The address of the sale auction.
    function setSaleAuctionContractAddress(address _address) external onlyOwner {
        SaleAuction _contract = SaleAuction(_address);
    
        require(_contract.isSaleAuction());
        
        saleAuctionContract = _contract;
    }
    
    /// @notice Set the contract address of the rent auction.
    /// @param _address The address of the rent auction.
    function setRentAuctionContractAddress(address _address) external onlyOwner {
        RentAuction _contract = RentAuction(_address);
    
        require(_contract.isRentAuction());
        
        rentAuctionContract = _contract;
    }
    
    /// @notice Create a sale auction.
    /// @param _deedId The identifier of the deed to create a sale auction for.
    /// @param _startPrice The starting price of the sale auction.
    /// @param _endPrice The ending price of the sale auction.
    /// @param _duration The duration in seconds of the dynamic pricing part of the sale auction.
    function createSaleAuction(uint256 _deedId, uint256 _startPrice, uint256 _endPrice, uint256 _duration)
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _deedId));
        
        // Prevent creating a sale auction if no sale auction contract is configured.
        require(address(saleAuctionContract) != address(0));
    
        // Approve the deed for transferring to the sale auction.
        _approve(msg.sender, address(saleAuctionContract), _deedId);
    
        // Auction contract checks input values (throws if invalid) and places the deed into escrow.
        saleAuctionContract.createAuction(_deedId, _startPrice, _endPrice, _duration);
    }
    
    /// @notice Create a rent auction.
    /// @param _deedId The identifier of the deed to create a rent auction for.
    /// @param _startPrice The starting price of the rent auction.
    /// @param _endPrice The ending price of the rent auction.
    /// @param _duration The duration in seconds of the dynamic pricing part of the rent auction.
    /// @param _rentPeriod The rent period in seconds being auctioned.
    function createRentAuction(uint256 _deedId, uint256 _startPrice, uint256 _endPrice, uint256 _duration, uint256 _rentPeriod)
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _deedId));
        
        // Prevent creating a rent auction if no rent auction contract is configured.
        require(address(rentAuctionContract) != address(0));
        
        // Approve the deed for transferring to the rent auction.
        _approve(msg.sender, address(rentAuctionContract), _deedId);
        
        // Throws if the auction is invalid (e.g. deed is already rented out),
        // and places the deed into escrow.
        rentAuctionContract.createAuction(_deedId, _startPrice, _endPrice, _duration, _rentPeriod);
    }
    
    /// @notice Allow the CFO to capture the free balance available
    /// in the auction contracts.
    function withdrawFreeAuctionBalances() external onlyCFO {
        saleAuctionContract.withdrawFreeBalance();
        rentAuctionContract.withdrawFreeBalance();
    }
    
    /// @notice Allow withdrawing balances from the auction contracts
    /// in a single step.
    function withdrawAuctionBalances() external {
        // Withdraw from the sale contract if the sender is owed Ether.
        if (saleAuctionContract.addressToEtherOwed(msg.sender) > 0) {
            saleAuctionContract.withdrawAuctionBalance(msg.sender);
        }
        
        // Withdraw from the rent contract if the sender is owed Ether.
        if (rentAuctionContract.addressToEtherOwed(msg.sender) > 0) {
            rentAuctionContract.withdrawAuctionBalance(msg.sender);
        }
    }
    
    /// @dev This contract is only payable by the auction contracts.
    function() public payable {
        require(
            msg.sender == address(saleAuctionContract) ||
            msg.sender == address(rentAuctionContract)
        );
    }
}


/// @dev Implements highest-level DWorld functionality.
contract DWorldCore is DWorldAuction {
    /// If this contract is broken, this will be used to publish the address at which an upgraded contract can be found
    address public upgradedContractAddress;
    event ContractUpgrade(address upgradedContractAddress);

    /// @notice Only to be used when this contract is significantly broken,
    /// and an upgrade is required.
    function setUpgradedContractAddress(address _upgradedContractAddress) external onlyOwner whenPaused {
        upgradedContractAddress = _upgradedContractAddress;
        ContractUpgrade(_upgradedContractAddress);
    }

    /// @notice Set the data associated with a plot.
    function setPlotData(uint256 _deedId, string name, string description, string imageUrl, string infoUrl)
        public
        whenNotPaused
    {
        // The sender requesting the data update should be
        // the owner (without an active renter) or should
        // be the active renter.
        require(_owns(msg.sender, _deedId) && identifierToRentPeriodEndTimestamp[_deedId] < now || _rents(msg.sender, _deedId));
    
        // Set the data
        _setPlotData(_deedId, name, description, imageUrl, infoUrl);
    }
    
    /// @notice Set the data associated with multiple plots.
    function setPlotDataMultiple(uint256[] _deedIds, string name, string description, string imageUrl, string infoUrl)
        external
        whenNotPaused
    {
        for (uint256 i = 0; i < _deedIds.length; i++) {
            uint256 _deedId = _deedIds[i];
        
            setPlotData(_deedId, name, description, imageUrl, infoUrl);
        }
    }
    
    /// @notice Allow the CFO to withdraw balance available to this contract.
    function withdrawBalance() external onlyCFO {
        cfoAddress.transfer(this.balance);
    }
}