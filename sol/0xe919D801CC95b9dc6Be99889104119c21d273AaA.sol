//File: node_modules/liquidpledging/contracts/ILiquidPledgingPlugin.sol
pragma solidity ^0.4.11;

/*
    Copyright 2017, Jordi Baylina
    Contributor: Adrià Massanet <adria@codecontext.io>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


/// @dev `ILiquidPledgingPlugin` is the basic interface for any
///  liquid pledging plugin
contract ILiquidPledgingPlugin {

    /// @notice Plugins are used (much like web hooks) to initiate an action
    ///  upon any donation, delegation, or transfer; this is an optional feature
    ///  and allows for extreme customization of the contract. This function
    ///  implements any action that should be initiated before a transfer.
    /// @param pledgeManager The admin or current manager of the pledge
    /// @param pledgeFrom This is the Id from which value will be transfered.
    /// @param pledgeTo This is the Id that value will be transfered to.    
    /// @param context The situation that is triggering the plugin:
    ///  0 -> Plugin for the owner transferring pledge to another party
    ///  1 -> Plugin for the first delegate transferring pledge to another party
    ///  2 -> Plugin for the second delegate transferring pledge to another party
    ///  ...
    ///  255 -> Plugin for the intendedProject transferring pledge to another party
    ///
    ///  256 -> Plugin for the owner receiving pledge to another party
    ///  257 -> Plugin for the first delegate receiving pledge to another party
    ///  258 -> Plugin for the second delegate receiving pledge to another party
    ///  ...
    ///  511 -> Plugin for the intendedProject receiving pledge to another party
    /// @param amount The amount of value that will be transfered.
    function beforeTransfer(
        uint64 pledgeManager,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount ) returns (uint maxAllowed);

    /// @notice Plugins are used (much like web hooks) to initiate an action
    ///  upon any donation, delegation, or transfer; this is an optional feature
    ///  and allows for extreme customization of the contract. This function
    ///  implements any action that should be initiated after a transfer.
    /// @param pledgeManager The admin or current manager of the pledge
    /// @param pledgeFrom This is the Id from which value will be transfered.
    /// @param pledgeTo This is the Id that value will be transfered to.    
    /// @param context The situation that is triggering the plugin:
    ///  0 -> Plugin for the owner transferring pledge to another party
    ///  1 -> Plugin for the first delegate transferring pledge to another party
    ///  2 -> Plugin for the second delegate transferring pledge to another party
    ///  ...
    ///  255 -> Plugin for the intendedProject transferring pledge to another party
    ///
    ///  256 -> Plugin for the owner receiving pledge to another party
    ///  257 -> Plugin for the first delegate receiving pledge to another party
    ///  258 -> Plugin for the second delegate receiving pledge to another party
    ///  ...
    ///  511 -> Plugin for the intendedProject receiving pledge to another party
    ///  @param amount The amount of value that will be transfered.
    function afterTransfer(
        uint64 pledgeManager,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount
    );
}

//File: node_modules/giveth-common-contracts/contracts/Owned.sol
pragma solidity ^0.4.15;


/// @title Owned
/// @author Adrià Massanet <adria@codecontext.io>
/// @notice The Owned contract has an owner address, and provides basic 
///  authorization control functions, this simplifies & the implementation of
///  user permissions; this contract has three work flows for a change in
///  ownership, the first requires the new owner to validate that they have the
///  ability to accept ownership, the second allows the ownership to be
///  directly transfered without requiring acceptance, and the third allows for
///  the ownership to be removed to allow for decentralization 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

    /// @dev The constructor sets the `msg.sender` as the`owner` of the contract
    function Owned() public {
        owner = msg.sender;
    }

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
    /// @dev In this 1st option for ownership transfer `proposeOwnership()` must
    ///  be called first by the current `owner` then `acceptOwnership()` must be
    ///  called by the `newOwnerCandidate`
    /// @notice `onlyOwner` Proposes to transfer control of the contract to a
    ///  new owner
    /// @param _newOwnerCandidate The address being proposed as the new owner
    function proposeOwnership(address _newOwnerCandidate) public onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

    /// @notice Can only be called by the `newOwnerCandidate`, accepts the
    ///  transfer of ownership
    function acceptOwnership() public {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

    /// @dev In this 2nd option for ownership transfer `changeOwnership()` can
    ///  be called and it will immediately assign ownership to the `newOwner`
    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner
    function changeOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

    /// @dev In this 3rd option for ownership transfer `removeOwnership()` can
    ///  be called and it will immediately assign ownership to the 0x0 address;
    ///  it requires a 0xdece be input as a parameter to prevent accidental use
    /// @notice Decentralizes the contract, this operation cannot be undone 
    /// @param _dac `0xdac` has to be entered for this function to work
    function removeOwnership(address _dac) public onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        OwnershipRemoved();     
    }
} 

//File: node_modules/giveth-common-contracts/contracts/ERC20.sol
pragma solidity ^0.4.15;


/**
 * @title ERC20
 * @dev A standard interface for tokens.
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20 {
  
    /// @dev Returns the total token supply
    function totalSupply() public constant returns (uint256 supply);

    /// @dev Returns the account balance of the account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);

    /// @dev Transfers _value number of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @dev Transfers _value number of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @dev Allows _spender to withdraw from the msg.sender's account up to the _value amount
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @dev Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

//File: node_modules/giveth-common-contracts/contracts/Escapable.sol
pragma solidity ^0.4.15;
/*
    Copyright 2016, Jordi Baylina
    Contributor: Adrià Massanet <adria@codecontext.io>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/





/// @dev `Escapable` is a base level contract built off of the `Owned`
///  contract; it creates an escape hatch function that can be called in an
///  emergency that will allow designated addresses to send any ether or tokens
///  held in the contract to an `escapeHatchDestination` as long as they were
///  not blacklisted
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist; // Token contract addresses

    /// @notice The Constructor assigns the `escapeHatchDestination` and the
    ///  `escapeHatchCaller`
    /// @param _escapeHatchCaller The address of a trusted account or contract
    ///  to call `escapeHatch()` to send the ether in this contract to the
    ///  `escapeHatchDestination` it would be ideal that `escapeHatchCaller`
    ///  cannot move funds out of `escapeHatchDestination`
    /// @param _escapeHatchDestination The address of a safe location (usu a
    ///  Multisig) to send the ether held in this contract; if a neutral address
    ///  is required, the WHG Multisig is an option:
    ///  0x8Ff920020c8AD673661c8117f2855C384758C572 
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) public {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

    /// @dev The addresses preassigned as `escapeHatchCaller` or `owner`
    ///  are the only addresses that can call a function with this modifier
    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

    /// @notice Creates the blacklist of tokens that are not able to be taken
    ///  out of the contract; can only be done at the deployment, and the logic
    ///  to add to the blacklist will be in the constructor of a child contract
    /// @param _token the token contract address that is to be blacklisted 
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        EscapeHatchBlackistedToken(_token);
    }

    /// @notice Checks to see if `_token` is in the blacklist of tokens
    /// @param _token the token address being queried
    /// @return False if `_token` is in the blacklist and can't be taken out of
    ///  the contract via the `escapeHatch()`
    function isTokenEscapable(address _token) constant public returns (bool) {
        return !escapeBlacklist[_token];
    }

    /// @notice The `escapeHatch()` should only be called as a last resort if a
    /// security issue is uncovered or something unexpected happened
    /// @param _token to transfer, use 0x0 for ether
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

        /// @dev Logic for ether
        if (_token == 0x0) {
            balance = this.balance;
            escapeHatchDestination.transfer(balance);
            EscapeHatchCalled(_token, balance);
            return;
        }
        /// @dev Logic for tokens
        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        require(token.transfer(escapeHatchDestination, balance));
        EscapeHatchCalled(_token, balance);
    }

    /// @notice Changes the address assigned to call `escapeHatch()`
    /// @param _newEscapeHatchCaller The address of a trusted account or
    ///  contract to call `escapeHatch()` to send the value in this contract to
    ///  the `escapeHatchDestination`; it would be ideal that `escapeHatchCaller`
    ///  cannot move funds out of `escapeHatchDestination`
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}

//File: node_modules/liquidpledging/contracts/LiquidPledgingBase.sol
pragma solidity ^0.4.11;
/*
    Copyright 2017, Jordi Baylina
    Contributors: Adrià Massanet <adria@codecontext.io>, RJ Ewing, Griff
    Green, Arthur Lunn

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/




/// @dev This is an interface for `LPVault` which serves as a secure storage for
///  the ETH that backs the Pledges, only after `LiquidPledging` authorizes
///  payments can Pledges be converted for ETH
interface LPVault {
    function authorizePayment(bytes32 _ref, address _dest, uint _amount);
    function () payable;
}

/// @dev `LiquidPledgingBase` is the base level contract used to carry out
///  liquidPledging's most basic functions, mostly handling and searching the
///  data structures
contract LiquidPledgingBase is Escapable {

    // Limits inserted to prevent large loops that could prevent canceling
    uint constant MAX_DELEGATES = 20;
    uint constant MAX_SUBPROJECT_LEVEL = 20;
    uint constant MAX_INTERPROJECT_LEVEL = 20;

    enum PledgeAdminType { Giver, Delegate, Project }
    enum PledgeState { Pledged, Paying, Paid }

    /// @dev This struct defines the details of a `PledgeAdmin` which are 
    ///  commonly referenced by their index in the `admins` array
    ///  and can own pledges and act as delegates
    struct PledgeAdmin { 
        PledgeAdminType adminType; // Giver, Delegate or Project
        address addr; // Account or contract address for admin
        string name;
        string url;  // Can be IPFS hash
        uint64 commitTime;  // In seconds, used for Givers' & Delegates' vetos
        uint64 parentProject;  // Only for projects
        bool canceled;      //Always false except for canceled projects

        /// @dev if the plugin is 0x0 then nothing happens, if its an address
        // than that smart contract is called when appropriate
        ILiquidPledgingPlugin plugin; 
    }

    struct Pledge {
        uint amount;
        uint64 owner; // PledgeAdmin
        uint64[] delegationChain; // List of delegates in order of authority
        uint64 intendedProject; // Used when delegates are sending to projects
        uint64 commitTime;  // When the intendedProject will become the owner  
        uint64 oldPledge; // Points to the id that this Pledge was derived from
        PledgeState pledgeState; //  Pledged, Paying, Paid
    }

    Pledge[] pledges;
    PledgeAdmin[] admins; //The list of pledgeAdmins 0 means there is no admin
    LPVault public vault;

    /// @dev this mapping allows you to search for a specific pledge's 
    ///  index number by the hash of that pledge
    mapping (bytes32 => uint64) hPledge2idx;
    mapping (bytes32 => bool) pluginWhitelist;
    
    bool public usePluginWhitelist = true;

/////////////
// Modifiers
/////////////


    /// @dev The `vault`is the only addresses that can call a function with this
    ///  modifier
    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }


///////////////
// Constructor
///////////////

    /// @notice The Constructor creates `LiquidPledgingBase` on the blockchain
    /// @param _vault The vault where the ETH backing the pledges is stored
    function LiquidPledgingBase(
        address _vault,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    ) Escapable(_escapeHatchCaller, _escapeHatchDestination) public {
        admins.length = 1; // we reserve the 0 admin
        pledges.length = 1; // we reserve the 0 pledge
        vault = LPVault(_vault); // Assigns the specified vault
    }


/////////////////////////
// PledgeAdmin functions
/////////////////////////

    /// @notice Creates a Giver Admin with the `msg.sender` as the Admin address
    /// @param name The name used to identify the Giver
    /// @param url The link to the Giver's profile often an IPFS hash
    /// @param commitTime The length of time in seconds the Giver has to
    ///   veto when the Giver's delegates Pledge funds to a project
    /// @param plugin This is Giver's liquid pledge plugin allowing for 
    ///  extended functionality
    /// @return idGiver The id number used to reference this Admin
    function addGiver(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) returns (uint64 idGiver) {

        require(isValidPlugin(plugin)); // Plugin check

        idGiver = uint64(admins.length);

        admins.push(PledgeAdmin(
            PledgeAdminType.Giver,
            msg.sender,
            name,
            url,
            commitTime,
            0,
            false,
            plugin));

        GiverAdded(idGiver);
    }

    event GiverAdded(uint64 indexed idGiver);

    /// @notice Updates a Giver's info to change the address, name, url, or 
    ///  commitTime, it cannot be used to change a plugin, and it must be called
    ///  by the current address of the Giver
    /// @param idGiver This is the Admin id number used to specify the Giver
    /// @param newAddr The new address that represents this Giver
    /// @param newName The new name used to identify the Giver
    /// @param newUrl The new link to the Giver's profile often an IPFS hash
    /// @param newCommitTime Sets the length of time in seconds the Giver has to
    ///   veto when the Giver's delegates Pledge funds to a project
    function updateGiver(
        uint64 idGiver,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime)
    {
        PledgeAdmin storage giver = findAdmin(idGiver);
        require(giver.adminType == PledgeAdminType.Giver); // Must be a Giver
        require(giver.addr == msg.sender); // Current addr had to send this tx
        giver.addr = newAddr;
        giver.name = newName;
        giver.url = newUrl;
        giver.commitTime = newCommitTime;
        GiverUpdated(idGiver);
    }

    event GiverUpdated(uint64 indexed idGiver);

    /// @notice Creates a Delegate Admin with the `msg.sender` as the Admin addr
    /// @param name The name used to identify the Delegate
    /// @param url The link to the Delegate's profile often an IPFS hash
    /// @param commitTime Sets the length of time in seconds that this delegate
    ///  can be vetoed. Whenever this delegate is in a delegate chain the time
    ///  allowed to veto any event must be greater than or equal to this time.
    /// @param plugin This is Delegate's liquid pledge plugin allowing for 
    ///  extended functionality
    /// @return idxDelegate The id number used to reference this Delegate within
    ///  the admins array
    function addDelegate(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) returns (uint64 idDelegate) { 

        require(isValidPlugin(plugin)); // Plugin check

        idDelegate = uint64(admins.length);

        admins.push(PledgeAdmin(
            PledgeAdminType.Delegate,
            msg.sender,
            name,
            url,
            commitTime,
            0,
            false,
            plugin));

        DelegateAdded(idDelegate);
    }

    event DelegateAdded(uint64 indexed idDelegate);

    /// @notice Updates a Delegate's info to change the address, name, url, or 
    ///  commitTime, it cannot be used to change a plugin, and it must be called
    ///  by the current address of the Delegate
    /// @param idDelegate The Admin id number used to specify the Delegate
    /// @param newAddr The new address that represents this Delegate
    /// @param newName The new name used to identify the Delegate
    /// @param newUrl The new link to the Delegate's profile often an IPFS hash
    /// @param newCommitTime Sets the length of time in seconds that this 
    ///  delegate can be vetoed. Whenever this delegate is in a delegate chain 
    ///  the time allowed to veto any event must be greater than or equal to
    ///  this time.
    function updateDelegate(
        uint64 idDelegate,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime) {
        PledgeAdmin storage delegate = findAdmin(idDelegate);
        require(delegate.adminType == PledgeAdminType.Delegate);
        require(delegate.addr == msg.sender);// Current addr had to send this tx
        delegate.addr = newAddr;
        delegate.name = newName;
        delegate.url = newUrl;
        delegate.commitTime = newCommitTime;
        DelegateUpdated(idDelegate);
    }

    event DelegateUpdated(uint64 indexed idDelegate);

    /// @notice Creates a Project Admin with the `msg.sender` as the Admin addr
    /// @param name The name used to identify the Project
    /// @param url The link to the Project's profile often an IPFS hash
    /// @param projectAdmin The address for the trusted project manager 
    /// @param parentProject The Admin id number for the parent project or 0 if
    ///  there is no parentProject
    /// @param commitTime Sets the length of time in seconds the Project has to
    ///   veto when the Project delegates to another Delegate and they pledge 
    ///   those funds to a project
    /// @param plugin This is Project's liquid pledge plugin allowing for 
    ///  extended functionality
    /// @return idProject The id number used to reference this Admin
    function addProject(
        string name,
        string url,
        address projectAdmin,
        uint64 parentProject,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) returns (uint64 idProject) {
        require(isValidPlugin(plugin));

        if (parentProject != 0) {
            PledgeAdmin storage pa = findAdmin(parentProject);
            require(pa.adminType == PledgeAdminType.Project);
            require(getProjectLevel(pa) < MAX_SUBPROJECT_LEVEL);
        }

        idProject = uint64(admins.length);

        admins.push(PledgeAdmin(
            PledgeAdminType.Project,
            projectAdmin,
            name,
            url,
            commitTime,
            parentProject,
            false,
            plugin));


        ProjectAdded(idProject);
    }

    event ProjectAdded(uint64 indexed idProject);


    /// @notice Updates a Project's info to change the address, name, url, or 
    ///  commitTime, it cannot be used to change a plugin or a parentProject,
    ///  and it must be called by the current address of the Project
    /// @param idProject The Admin id number used to specify the Project
    /// @param newAddr The new address that represents this Project
    /// @param newName The new name used to identify the Project
    /// @param newUrl The new link to the Project's profile often an IPFS hash
    /// @param newCommitTime Sets the length of time in seconds the Project has
    ///  to veto when the Project delegates to a Delegate and they pledge those
    ///  funds to a project
    function updateProject(
        uint64 idProject,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime)
    {
        PledgeAdmin storage project = findAdmin(idProject);
        require(project.adminType == PledgeAdminType.Project);
        require(project.addr == msg.sender);
        project.addr = newAddr;
        project.name = newName;
        project.url = newUrl;
        project.commitTime = newCommitTime;
        ProjectUpdated(idProject);
    }

    event ProjectUpdated(uint64 indexed idAdmin);


//////////
// Public constant functions
//////////

    /// @notice A constant getter that returns the total number of pledges
    /// @return The total number of Pledges in the system
    function numberOfPledges() constant returns (uint) {
        return pledges.length - 1;
    }

    /// @notice A getter that returns the details of the specified pledge
    /// @param idPledge the id number of the pledge being queried
    /// @return the amount, owner, the number of delegates (but not the actual
    ///  delegates, the intendedProject (if any), the current commit time and
    ///  the previous pledge this pledge was derived from
    function getPledge(uint64 idPledge) constant returns(
        uint amount,
        uint64 owner,
        uint64 nDelegates,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        PledgeState pledgeState
    ) {
        Pledge storage p = findPledge(idPledge);
        amount = p.amount;
        owner = p.owner;
        nDelegates = uint64(p.delegationChain.length);
        intendedProject = p.intendedProject;
        commitTime = p.commitTime;
        oldPledge = p.oldPledge;
        pledgeState = p.pledgeState;
    }

    /// @notice Getter to find Delegate w/ the Pledge ID & the Delegate index
    /// @param idPledge The id number representing the pledge being queried
    /// @param idxDelegate The index number for the delegate in this Pledge 
    function getPledgeDelegate(uint64 idPledge, uint idxDelegate) constant returns(
        uint64 idDelegate,
        address addr,
        string name
    ) {
        Pledge storage p = findPledge(idPledge);
        idDelegate = p.delegationChain[idxDelegate - 1];
        PledgeAdmin storage delegate = findAdmin(idDelegate);
        addr = delegate.addr;
        name = delegate.name;
    }

    /// @notice A constant getter used to check how many total Admins exist
    /// @return The total number of admins (Givers, Delegates and Projects) .
    function numberOfPledgeAdmins() constant returns(uint) {
        return admins.length - 1;
    }

    /// @notice A constant getter to check the details of a specified Admin  
    /// @return addr Account or contract address for admin
    /// @return name Name of the pledgeAdmin
    /// @return url The link to the Project's profile often an IPFS hash
    /// @return commitTime The length of time in seconds the Admin has to veto
    ///   when the Admin delegates to a Delegate and that Delegate pledges those
    ///   funds to a project
    /// @return parentProject The Admin id number for the parent project or 0
    ///  if there is no parentProject
    /// @return canceled 0 for Delegates & Givers, true if a Project has been 
    ///  canceled
    /// @return plugin This is Project's liquidPledging plugin allowing for 
    ///  extended functionality
    function getPledgeAdmin(uint64 idAdmin) constant returns (
        PledgeAdminType adminType,
        address addr,
        string name,
        string url,
        uint64 commitTime,
        uint64 parentProject,
        bool canceled,
        address plugin)
    {
        PledgeAdmin storage m = findAdmin(idAdmin);
        adminType = m.adminType;
        addr = m.addr;
        name = m.name;
        url = m.url;
        commitTime = m.commitTime;
        parentProject = m.parentProject;
        canceled = m.canceled;
        plugin = address(m.plugin);
    }

////////
// Private methods
///////

    /// @notice This creates a Pledge with an initial amount of 0 if one is not
    ///  created already; otherwise it finds the pledge with the specified
    ///  attributes; all pledges technically exist, if the pledge hasn't been
    ///  created in this system yet it simply isn't in the hash array
    ///  hPledge2idx[] yet
    /// @param owner The owner of the pledge being looked up
    /// @param delegationChain The list of delegates in order of authority
    /// @param intendedProject The project this pledge will Fund after the
    ///  commitTime has passed
    /// @param commitTime The length of time in seconds the Giver has to
    ///   veto when the Giver's delegates Pledge funds to a project
    /// @param oldPledge This value is used to store the pledge the current
    ///  pledge was came from, and in the case a Project is canceled, the Pledge
    ///  will revert back to it's previous state
    /// @param state The pledge state: Pledged, Paying, or state
    /// @return The hPledge2idx index number
    function findOrCreatePledge(
        uint64 owner,
        uint64[] delegationChain,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        PledgeState state
        ) internal returns (uint64)
    {
        bytes32 hPledge = sha3(
            owner, delegationChain, intendedProject, commitTime, oldPledge, state);
        uint64 idx = hPledge2idx[hPledge];
        if (idx > 0) return idx;
        idx = uint64(pledges.length);
        hPledge2idx[hPledge] = idx;
        pledges.push(Pledge(
            0, owner, delegationChain, intendedProject, commitTime, oldPledge, state));
        return idx;
    }

    /// @notice A getter to look up a Admin's details
    /// @param idAdmin The id for the Admin to lookup
    /// @return The PledgeAdmin struct for the specified Admin
    function findAdmin(uint64 idAdmin) internal returns (PledgeAdmin storage) {
        require(idAdmin < admins.length);
        return admins[idAdmin];
    }

    /// @notice A getter to look up a Pledge's details
    /// @param idPledge The id for the Pledge to lookup
    /// @return The PledgeA struct for the specified Pledge
    function findPledge(uint64 idPledge) internal returns (Pledge storage) {
        require(idPledge < pledges.length);
        return pledges[idPledge];
    }

    // a constant for when a delegate is requested that is not in the system
    uint64 constant  NOTFOUND = 0xFFFFFFFFFFFFFFFF;

    /// @notice A getter that searches the delegationChain for the level of
    ///  authority a specific delegate has within a Pledge
    /// @param p The Pledge that will be searched
    /// @param idDelegate The specified delegate that's searched for
    /// @return If the delegate chain contains the delegate with the
    ///  `admins` array index `idDelegate` this returns that delegates
    ///  corresponding index in the delegationChain. Otherwise it returns
    ///  the NOTFOUND constant
    function getDelegateIdx(Pledge p, uint64 idDelegate) internal returns(uint64) {
        for (uint i=0; i < p.delegationChain.length; i++) {
            if (p.delegationChain[i] == idDelegate) return uint64(i);
        }
        return NOTFOUND;
    }

    /// @notice A getter to find how many old "parent" pledges a specific Pledge
    ///  had using a self-referential loop
    /// @param p The Pledge being queried
    /// @return The number of old "parent" pledges a specific Pledge had
    function getPledgeLevel(Pledge p) internal returns(uint) {
        if (p.oldPledge == 0) return 0;
        Pledge storage oldN = findPledge(p.oldPledge);
        return getPledgeLevel(oldN) + 1; // a loop lookup
    }

    /// @notice A getter to find the longest commitTime out of the owner and all
    ///  the delegates for a specified pledge
    /// @param p The Pledge being queried
    /// @return The maximum commitTime out of the owner and all the delegates
    function maxCommitTime(Pledge p) internal returns(uint commitTime) {
        PledgeAdmin storage m = findAdmin(p.owner);
        commitTime = m.commitTime; // start with the owner's commitTime

        for (uint i=0; i<p.delegationChain.length; i++) {
            m = findAdmin(p.delegationChain[i]);

            // If a delegate's commitTime is longer, make it the new commitTime
            if (m.commitTime > commitTime) commitTime = m.commitTime;
        }
    }

    /// @notice A getter to find the level of authority a specific Project has
    ///  using a self-referential loop
    /// @param m The Project being queried
    /// @return The level of authority a specific Project has
    function getProjectLevel(PledgeAdmin m) internal returns(uint) {
        assert(m.adminType == PledgeAdminType.Project);
        if (m.parentProject == 0) return(1);
        PledgeAdmin storage parentNM = findAdmin(m.parentProject);
        return getProjectLevel(parentNM) + 1;
    }

    /// @notice A getter to find if a specified Project has been canceled
    /// @param projectId The Admin id number used to specify the Project
    /// @return True if the Project has been canceled
    function isProjectCanceled(uint64 projectId) constant returns (bool) {
        PledgeAdmin storage m = findAdmin(projectId);
        if (m.adminType == PledgeAdminType.Giver) return false;
        assert(m.adminType == PledgeAdminType.Project);
        if (m.canceled) return true;
        if (m.parentProject == 0) return false;
        return isProjectCanceled(m.parentProject);
    }

    /// @notice A getter to find the oldest pledge that hasn't been canceled
    /// @param idPledge The starting place to lookup the pledges 
    /// @return The oldest idPledge that hasn't been canceled (DUH!)
    function getOldestPledgeNotCanceled(uint64 idPledge
        ) internal constant returns(uint64) {
        if (idPledge == 0) return 0;
        Pledge storage p = findPledge(idPledge);
        PledgeAdmin storage admin = findAdmin(p.owner);
        if (admin.adminType == PledgeAdminType.Giver) return idPledge;

        assert(admin.adminType == PledgeAdminType.Project);

        if (!isProjectCanceled(p.owner)) return idPledge;

        return getOldestPledgeNotCanceled(p.oldPledge);
    }

    /// @notice A check to see if the msg.sender is the owner or the
    ///  plugin contract for a specific Admin
    /// @param m The Admin being checked
    function checkAdminOwner(PledgeAdmin m) internal constant {
        require((msg.sender == m.addr) || (msg.sender == address(m.plugin)));
    }
///////////////////////////
// Plugin Whitelist Methods
///////////////////////////

    function addValidPlugin(bytes32 contractHash) external onlyOwner {
        pluginWhitelist[contractHash] = true;
    }

    function removeValidPlugin(bytes32 contractHash) external onlyOwner {
        pluginWhitelist[contractHash] = false;
    }

    function useWhitelist(bool useWhitelist) external onlyOwner {
        usePluginWhitelist = useWhitelist;
    }

    function isValidPlugin(address addr) public returns(bool) {
        if (!usePluginWhitelist || addr == 0x0) return true;

        bytes32 contractHash = getCodeHash(addr);

        return pluginWhitelist[contractHash];
    }

    function getCodeHash(address addr) public returns(bytes32) {
        bytes memory o_code;
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(addr, add(o_code, 0x20), 0, size)
        }
        return keccak256(o_code);
    }
}

//File: node_modules/liquidpledging/contracts/LiquidPledging.sol
pragma solidity ^0.4.11;

/*
    Copyright 2017, Jordi Baylina
    Contributor: Adrià Massanet <adria@codecontext.io>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// Contract Imports


/// @dev `LiquidPleding` allows for liquid pledging through the use of
///  internal id structures and delegate chaining. All basic operations for
///  handling liquid pledging are supplied as well as plugin features
///  to allow for expanded functionality.
contract LiquidPledging is LiquidPledgingBase {


//////
// Constructor
//////

    /// @notice Basic constructor for LiquidPleding, also calls the
    ///  LiquidPledgingBase contract
    /// @dev This constructor  also calls the constructor 
    ///  for `LiquidPledgingBase`
    /// @param _vault The vault where ETH backing this pledge is stored
    function LiquidPledging(
        address _vault,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    ) LiquidPledgingBase(_vault, _escapeHatchCaller, _escapeHatchDestination) {

    }

    /// @notice This is how value enters into the system which creates pledges;
    ///  the token of value goes into the vault and the amount in the pledge
    ///  relevant to this Giver without delegates is increased, and a normal
    ///  transfer is done to the idReceiver
    /// @param idGiver Identifier of the giver thats donating.
    /// @param idReceiver To whom it's transfered. Can be the same giver,
    ///  another giver, a delegate or a project.
    function donate(uint64 idGiver, uint64 idReceiver) payable {
        if (idGiver == 0) {
            // default to 3 day commitTime
            idGiver = addGiver("", "", 259200, ILiquidPledgingPlugin(0x0));
        }

        PledgeAdmin storage sender = findAdmin(idGiver);

        checkAdminOwner(sender);

        require(sender.adminType == PledgeAdminType.Giver);

        uint amount = msg.value;

        require(amount > 0);

        vault.transfer(amount); // transfers the baseToken to the Vault
        uint64 idPledge = findOrCreatePledge(
            idGiver,
            new uint64[](0), //what is new?
            0,
            0,
            0,
            PledgeState.Pledged
        );


        Pledge storage nTo = findPledge(idPledge);
        nTo.amount += amount;

        Transfer(0, idPledge, amount);

        transfer(idGiver, idPledge, amount, idReceiver);
    }


    /// @notice Moves value between pledges
    /// @param idSender ID of the giver, delegate or project admin that is 
    ///  transferring the funds from Pledge to Pledge; this admin must have 
    ///  permissions to move the value
    /// @param idPledge Id of the pledge that's moving the value
    /// @param amount Quantity of value that's being moved
    /// @param idReceiver Destination of the value, can be a giver sending to 
    ///  a giver or a delegate, a delegate to another delegate or a project 
    ///  to pre-commit it to that project if called from a delegate,
    ///  or to commit it to the project if called from the owner. 
    function transfer(
        uint64 idSender,
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    )
    {

        idPledge = normalizePledge(idPledge);

        Pledge storage p = findPledge(idPledge);
        PledgeAdmin storage receiver = findAdmin(idReceiver);
        PledgeAdmin storage sender = findAdmin(idSender);

        checkAdminOwner(sender);
        require(p.pledgeState == PledgeState.Pledged);

        // If the sender is the owner
        if (p.owner == idSender) {
            if (receiver.adminType == PledgeAdminType.Giver) {
                transferOwnershipToGiver(idPledge, amount, idReceiver);
            } else if (receiver.adminType == PledgeAdminType.Project) {
                transferOwnershipToProject(idPledge, amount, idReceiver);
            } else if (receiver.adminType == PledgeAdminType.Delegate) {
                idPledge = undelegate(
                    idPledge,
                    amount,
                    p.delegationChain.length
                );
                appendDelegate(idPledge, amount, idReceiver);
            } else {
                assert(false);
            }
            return;
        }

        // If the sender is a delegate
        uint senderDIdx = getDelegateIdx(p, idSender);
        if (senderDIdx != NOTFOUND) {

            // If the receiver is another giver
            if (receiver.adminType == PledgeAdminType.Giver) {
                // Only accept to change to the original giver to
                // remove all delegates
                assert(p.owner == idReceiver);
                undelegate(idPledge, amount, p.delegationChain.length);
                return;
            }

            // If the receiver is another delegate
            if (receiver.adminType == PledgeAdminType.Delegate) {
                uint receiverDIdx = getDelegateIdx(p, idReceiver);

                // If the receiver is not in the delegate list
                if (receiverDIdx == NOTFOUND) {
                    idPledge = undelegate(
                        idPledge,
                        amount,
                        p.delegationChain.length - senderDIdx - 1
                    );
                    appendDelegate(idPledge, amount, idReceiver);

                // If the receiver is already part of the delegate chain and is
                // after the sender, then all of the other delegates after the
                // sender are removed and the receiver is appended at the
                // end of the delegation chain
                } else if (receiverDIdx > senderDIdx) {
                    idPledge = undelegate(
                        idPledge,
                        amount,
                        p.delegationChain.length - senderDIdx - 1
                    );
                    appendDelegate(idPledge, amount, idReceiver);

                // If the receiver is already part of the delegate chain and is
                // before the sender, then the sender and all of the other
                // delegates after the RECEIVER are removed from the chain,
                // this is interesting because the delegate is removed from the
                // delegates that delegated to this delegate. Are there game theory
                // issues? should this be allowed?
                } else if (receiverDIdx <= senderDIdx) {
                    undelegate(
                        idPledge,
                        amount,
                        p.delegationChain.length - receiverDIdx - 1
                    );
                }
                return;
            }

            // If the delegate wants to support a project, they remove all
            // the delegates after them in the chain and choose a project
            if (receiver.adminType == PledgeAdminType.Project) {
                idPledge = undelegate(
                    idPledge,
                    amount,
                    p.delegationChain.length - senderDIdx - 1
                );
                proposeAssignProject(idPledge, amount, idReceiver);
                return;
            }
        }
        assert(false);  // It is not the owner nor any delegate.
    }

    /// @notice This method is used to withdraw value from the system.
    ///  This can be used by the givers withdraw any un-commited donations.
    /// @param idPledge Id of the pledge that wants to be withdrawn.
    /// @param amount Quantity of Ether that wants to be withdrawn.
    function withdraw(uint64 idPledge, uint amount) {

        idPledge = normalizePledge(idPledge);

        Pledge storage p = findPledge(idPledge);

        require(p.pledgeState == PledgeState.Pledged);

        PledgeAdmin storage owner = findAdmin(p.owner);

        checkAdminOwner(owner);

        uint64 idNewPledge = findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            PledgeState.Paying
        );

        doTransfer(idPledge, idNewPledge, amount);

        vault.authorizePayment(bytes32(idNewPledge), owner.addr, amount);
    }

    /// @notice Method called by the vault to confirm a payment.
    /// @param idPledge Id of the pledge that wants to be withdrawn.
    /// @param amount Quantity of Ether that wants to be withdrawn.
    function confirmPayment(uint64 idPledge, uint amount) onlyVault {
        Pledge storage p = findPledge(idPledge);

        require(p.pledgeState == PledgeState.Paying);

        uint64 idNewPledge = findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            PledgeState.Paid
        );

        doTransfer(idPledge, idNewPledge, amount);
    }

    /// @notice Method called by the vault to cancel a payment.
    /// @param idPledge Id of the pledge that wants to be canceled for withdraw.
    /// @param amount Quantity of Ether that wants to be rolled back.
    function cancelPayment(uint64 idPledge, uint amount) onlyVault {
        Pledge storage p = findPledge(idPledge);

        require(p.pledgeState == PledgeState.Paying); //TODO change to revert

        // When a payment is canceled, never is assigned to a project.
        uint64 oldPledge = findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            PledgeState.Pledged
        );

        oldPledge = normalizePledge(oldPledge);

        doTransfer(idPledge, oldPledge, amount);
    }

    /// @notice Method called to cancel this project.
    /// @param idProject Id of the projct that wants to be canceled.
    function cancelProject(uint64 idProject) {
        PledgeAdmin storage project = findAdmin(idProject);
        checkAdminOwner(project);
        project.canceled = true;

        CancelProject(idProject);
    }

    /// @notice Method called to cancel specific pledge.
    /// @param idPledge Id of the pledge that should be canceled.
    /// @param amount Quantity of Ether that wants to be rolled back.
    function cancelPledge(uint64 idPledge, uint amount) {
        idPledge = normalizePledge(idPledge);

        Pledge storage p = findPledge(idPledge);
        require(p.oldPledge != 0);

        PledgeAdmin storage m = findAdmin(p.owner);
        checkAdminOwner(m);

        uint64 oldPledge = getOldestPledgeNotCanceled(p.oldPledge);
        doTransfer(idPledge, oldPledge, amount);
    }


////////
// Multi pledge methods
////////

    // @dev This set of functions makes moving a lot of pledges around much more
    // efficient (saves gas) than calling these functions in series
    
    
    /// Bit mask used for dividing pledge amounts in Multi pledge methods
    uint constant D64 = 0x10000000000000000;

    /// @notice `mTransfer` allows for multiple pledges to be transferred
    ///  efficiently
    /// @param idSender ID of the giver, delegate or project admin that is
    ///  transferring the funds from Pledge to Pledge. This admin must have 
    ///  permissions to move the value
    /// @param pledgesAmounts An array of pledge amounts and IDs which are extrapolated
    ///  using the D64 bitmask
    /// @param idReceiver Destination of the value, can be a giver sending
    ///  to a giver or a delegate or a delegate to another delegate or a
    ///  project to pre-commit it to that project
    function mTransfer(
        uint64 idSender,
        uint[] pledgesAmounts,
        uint64 idReceiver
    ) {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            transfer(idSender, idPledge, amount, idReceiver);
        }
    }

    /// @notice `mWithdraw` allows for multiple pledges to be
    ///  withdrawn efficiently
    /// @param pledgesAmounts An array of pledge amounts and IDs which are
    ///  extrapolated using the D64 bitmask
    function mWithdraw(uint[] pledgesAmounts) {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            withdraw(idPledge, amount);
        }
    }

    /// @notice `mConfirmPayment` allows for multiple pledges to be confirmed
    ///  efficiently
    /// @param pledgesAmounts An array of pledge amounts and IDs which are extrapolated
    ///  using the D64 bitmask
    function mConfirmPayment(uint[] pledgesAmounts) {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            confirmPayment(idPledge, amount);
        }
    }

    /// @notice `mCancelPayment` allows for multiple pledges to be canceled
    ///  efficiently
    /// @param pledgesAmounts An array of pledge amounts and IDs which are extrapolated
    ///  using the D64 bitmask
    function mCancelPayment(uint[] pledgesAmounts) {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            cancelPayment(idPledge, amount);
        }
    }

    /// @notice `mNormalizePledge` allows for multiple pledges to be
    ///  normalized efficiently
    /// @param pledges An array of pledge IDs
    function mNormalizePledge(uint64[] pledges) {
        for (uint i = 0; i < pledges.length; i++ ) {
            normalizePledge( pledges[i] );
        }
    }

////////
// Private methods
///////

    /// @notice `transferOwnershipToProject` allows for the transfer of
    ///  ownership to the project, but it can also be called by a project
    ///  to un-delegate everyone by setting one's own id for the idReceiver
    /// @param idPledge Id of the pledge to be transfered.
    /// @param amount Quantity of value that's being transfered
    /// @param idReceiver The new owner of the project (or self to un-delegate)
    function transferOwnershipToProject(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal {
        Pledge storage p = findPledge(idPledge);

        // Ensure that the pledge is not already at max pledge depth
        // and the project has not been canceled
        require(getPledgeLevel(p) < MAX_INTERPROJECT_LEVEL);
        require(!isProjectCanceled(idReceiver));

        uint64 oldPledge = findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            PledgeState.Pledged
        );
        uint64 toPledge = findOrCreatePledge(
            idReceiver,                     // Set the new owner
            new uint64[](0),                // clear the delegation chain
            0,
            0,
            oldPledge,
            PledgeState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);
    }   


    /// @notice `transferOwnershipToGiver` allows for the transfer of
    ///  value back to the Giver, value is placed in a pledged state
    ///  without being attached to a project, delegation chain, or time line.
    /// @param idPledge Id of the pledge to be transfered.
    /// @param amount Quantity of value that's being transfered
    /// @param idReceiver The new owner of the pledge
    function transferOwnershipToGiver(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal {
        uint64 toPledge = findOrCreatePledge(
            idReceiver,
            new uint64[](0),
            0,
            0,
            0,
            PledgeState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `appendDelegate` allows for a delegate to be added onto the
    ///  end of the delegate chain for a given Pledge.
    /// @param idPledge Id of the pledge thats delegate chain will be modified.
    /// @param amount Quantity of value that's being chained.
    /// @param idReceiver The delegate to be added at the end of the chain
    function appendDelegate(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal {
        Pledge storage p = findPledge(idPledge);

        require(p.delegationChain.length < MAX_DELEGATES);
        uint64[] memory newDelegationChain = new uint64[](
            p.delegationChain.length + 1
        );
        for (uint i = 0; i<p.delegationChain.length; i++) {
            newDelegationChain[i] = p.delegationChain[i];
        }

        // Make the last item in the array the idReceiver
        newDelegationChain[p.delegationChain.length] = idReceiver;

        uint64 toPledge = findOrCreatePledge(
            p.owner,
            newDelegationChain,
            0,
            0,
            p.oldPledge,
            PledgeState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `appendDelegate` allows for a delegate to be added onto the
    ///  end of the delegate chain for a given Pledge.
    /// @param idPledge Id of the pledge thats delegate chain will be modified.
    /// @param amount Quantity of value that's shifted from delegates.
    /// @param q Number (or depth) to remove as delegates
    function undelegate(
        uint64 idPledge,
        uint amount,
        uint q
    ) internal returns (uint64){
        Pledge storage p = findPledge(idPledge);
        uint64[] memory newDelegationChain = new uint64[](
            p.delegationChain.length - q
        );
        for (uint i=0; i<p.delegationChain.length - q; i++) {
            newDelegationChain[i] = p.delegationChain[i];
        }
        uint64 toPledge = findOrCreatePledge(
            p.owner,
            newDelegationChain,
            0,
            0,
            p.oldPledge,
            PledgeState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);

        return toPledge;
    }

    /// @notice `proposeAssignProject` proposes the assignment of a pledge
    ///  to a specific project.
    /// @dev This function should potentially be named more specifically.
    /// @param idPledge Id of the pledge that will be assigned.
    /// @param amount Quantity of value this pledge leader would be assigned.
    /// @param idReceiver The project this pledge will potentially 
    ///  be assigned to.
    function proposeAssignProject(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal {
        Pledge storage p = findPledge(idPledge);

        require(getPledgeLevel(p) < MAX_INTERPROJECT_LEVEL);
        require(!isProjectCanceled(idReceiver));

        uint64 toPledge = findOrCreatePledge(
            p.owner,
            p.delegationChain,
            idReceiver,
            uint64(getTime() + maxCommitTime(p)),
            p.oldPledge,
            PledgeState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `doTransfer` is designed to allow for pledge amounts to be 
    ///  shifted around internally.
    /// @param from This is the Id from which value will be transfered.
    /// @param to This is the Id that value will be transfered to.
    /// @param _amount The amount of value that will be transfered.
    function doTransfer(uint64 from, uint64 to, uint _amount) internal {
        uint amount = callPlugins(true, from, to, _amount);
        if (from == to) { 
            return;
        }
        if (amount == 0) {
            return;
        }
        Pledge storage nFrom = findPledge(from);
        Pledge storage nTo = findPledge(to);
        require(nFrom.amount >= amount);
        nFrom.amount -= amount;
        nTo.amount += amount;

        Transfer(from, to, amount);
        callPlugins(false, from, to, amount);
    }

    /// @notice `normalizePledge` only affects pledges with the Pledged PledgeState
    /// and does 2 things:
    ///   #1: Checks if the pledge should be committed. This means that
    ///       if the pledge has an intendedProject and it is past the
    ///       commitTime, it changes the owner to be the proposed project
    ///       (The UI will have to read the commit time and manually do what
    ///       this function does to the pledge for the end user
    ///       at the expiration of the commitTime)
    ///
    ///   #2: Checks to make sure that if there has been a cancellation in the
    ///       chain of projects, the pledge's owner has been changed
    ///       appropriately.
    ///
    /// This function can be called by anybody at anytime on any pledge.
    /// In general it can be called to force the calls of the affected 
    /// plugins, which also need to be predicted by the UI
    /// @param idPledge This is the id of the pledge that will be normalized
    function normalizePledge(uint64 idPledge) returns(uint64) {

        Pledge storage p = findPledge(idPledge);

        // Check to make sure this pledge hasn't already been used 
        // or is in the process of being used
        if (p.pledgeState != PledgeState.Pledged) {
            return idPledge;
        }

        // First send to a project if it's proposed and committed
        if ((p.intendedProject > 0) && ( getTime() > p.commitTime)) {
            uint64 oldPledge = findOrCreatePledge(
                p.owner,
                p.delegationChain,
                0,
                0,
                p.oldPledge,
                PledgeState.Pledged
            );
            uint64 toPledge = findOrCreatePledge(
                p.intendedProject,
                new uint64[](0),
                0,
                0,
                oldPledge,
                PledgeState.Pledged
            );
            doTransfer(idPledge, toPledge, p.amount);
            idPledge = toPledge;
            p = findPledge(idPledge);
        }

        toPledge = getOldestPledgeNotCanceled(idPledge);
        if (toPledge != idPledge) {
            doTransfer(idPledge, toPledge, p.amount);
        }

        return toPledge;
    }

/////////////
// Plugins
/////////////

    /// @notice `callPlugin` is used to trigger the general functions in the
    ///  plugin for any actions needed before and after a transfer happens.
    ///  Specifically what this does in relation to the plugin is something
    ///  that largely depends on the functions of that plugin. This function
    ///  is generally called in pairs, once before, and once after a transfer.
    /// @param before This toggle determines whether the plugin call is occurring
    ///  before or after a transfer.
    /// @param adminId This should be the Id of the *trusted* individual
    ///  who has control over this plugin.
    /// @param fromPledge This is the Id from which value is being transfered.
    /// @param toPledge This is the Id that value is being transfered to.
    /// @param context The situation that is triggering the plugin. See plugin
    ///  for a full description of contexts.
    /// @param amount The amount of value that is being transfered.
    function callPlugin(
        bool before,
        uint64 adminId,
        uint64 fromPledge,
        uint64 toPledge,
        uint64 context,
        uint amount
    ) internal returns (uint allowedAmount) {

        uint newAmount;
        allowedAmount = amount;
        PledgeAdmin storage admin = findAdmin(adminId);
        // Checks admin has a plugin assigned and a non-zero amount is requested
        if ((address(admin.plugin) != 0) && (allowedAmount > 0)) {
            // There are two seperate functions called in the plugin.
            // One is called before the transfer and one after
            if (before) {
                newAmount = admin.plugin.beforeTransfer(
                    adminId,
                    fromPledge,
                    toPledge,
                    context,
                    amount
                );
                require(newAmount <= allowedAmount);
                allowedAmount = newAmount;
            } else {
                admin.plugin.afterTransfer(
                    adminId,
                    fromPledge,
                    toPledge,
                    context,
                    amount
                );
            }
        }
    }

    /// @notice `callPluginsPledge` is used to apply plugin calls to
    ///  the delegate chain and the intended project if there is one.
    ///  It does so in either a transferring or receiving context based
    ///  on the `idPledge` and  `fromPledge` parameters.
    /// @param before This toggle determines whether the plugin call is occuring
    ///  before or after a transfer.
    /// @param idPledge This is the Id of the pledge on which this plugin
    ///  is being called.
    /// @param fromPledge This is the Id from which value is being transfered.
    /// @param toPledge This is the Id that value is being transfered to.
    /// @param amount The amount of value that is being transfered.
    function callPluginsPledge(
        bool before,
        uint64 idPledge,
        uint64 fromPledge,
        uint64 toPledge,
        uint amount
    ) internal returns (uint allowedAmount) {
        // Determine if callPlugin is being applied in a receiving
        // or transferring context
        uint64 offset = idPledge == fromPledge ? 0 : 256;
        allowedAmount = amount;
        Pledge storage p = findPledge(idPledge);

        // Always call the plugin on the owner
        allowedAmount = callPlugin(
            before,
            p.owner,
            fromPledge,
            toPledge,
            offset,
            allowedAmount
        );

        // Apply call plugin to all delegates
        for (uint64 i=0; i<p.delegationChain.length; i++) {
            allowedAmount = callPlugin(
                before,
                p.delegationChain[i],
                fromPledge,
                toPledge,
                offset + i+1,
                allowedAmount
            );
        }

        // If there is an intended project also call the plugin in
        // either a transferring or receiving context based on offset
        // on the intended project
        if (p.intendedProject > 0) {
            allowedAmount = callPlugin(
                before,
                p.intendedProject,
                fromPledge,
                toPledge,
                offset + 255,
                allowedAmount
            );
        }
    }


    /// @notice `callPlugins` calls `callPluginsPledge` once for the transfer
    ///  context and once for the receiving context. The aggregated 
    ///  allowed amount is then returned.
    /// @param before This toggle determines whether the plugin call is occurring
    ///  before or after a transfer.
    /// @param fromPledge This is the Id from which value is being transferred.
    /// @param toPledge This is the Id that value is being transferred to.
    /// @param amount The amount of value that is being transferred.
    function callPlugins(
        bool before,
        uint64 fromPledge,
        uint64 toPledge,
        uint amount
    ) internal returns (uint allowedAmount) {
        allowedAmount = amount;

        // Call the pledges plugins in the transfer context
        allowedAmount = callPluginsPledge(
            before,
            fromPledge,
            fromPledge,
            toPledge,
            allowedAmount
        );

        // Call the pledges plugins in the receive context
        allowedAmount = callPluginsPledge(
            before,
            toPledge,
            fromPledge,
            toPledge,
            allowedAmount
        );
    }

/////////////
// Test functions
/////////////

    /// @notice Basic helper function to return the current time
    function getTime() internal returns (uint) {
        return now;
    }

    // Event Delcerations
    event Transfer(uint64 indexed from, uint64 indexed to, uint amount);
    event CancelProject(uint64 indexed idProject);

}

//File: contracts/LPPCappedMilestones.sol
pragma solidity ^0.4.17;

/*
    Copyright 2017, RJ Ewing <perissology@protonmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/





contract LPPCappedMilestones is Escapable {
    uint constant TO_OWNER = 256;
    uint constant TO_INTENDEDPROJECT = 511;

    LiquidPledging public liquidPledging;

    struct Milestone {
        uint maxAmount;
        uint received;
        uint canCollect;
        address reviewer;
        address campaignReviewer;
        address recipient;
        bool accepted;
    }

    mapping (uint64 => Milestone) milestones;


    event MilestoneAccepted(uint64 indexed idProject);
    event PaymentCollected(uint64 indexed idProject);

    //== constructor

    function LPPCappedMilestones(
        LiquidPledging _liquidPledging,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    ) Escapable(_escapeHatchCaller, _escapeHatchDestination) public
    {
        liquidPledging = _liquidPledging;
    }

    //== fallback

    function() payable {}

    //== external

    /// @dev this is called by liquidPledging before every transfer to and from
    ///      a pledgeAdmin that has this contract as its plugin
    /// @dev see ILiquidPledgingPlugin interface for details about context param
    function beforeTransfer(
        uint64 pledgeManager,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount
    ) external returns (uint maxAllowed)
    {
        require(msg.sender == address(liquidPledging));
        var (, , , fromIntendedProject, , ,) = liquidPledging.getPledge(pledgeFrom);
        var (, toOwner, , toIntendedProject, , , toPledgeState) = liquidPledging.getPledge(pledgeTo);
        Milestone storage m;

        // if m is the intendedProject, make sure m is still accepting funds (not accepted or canceled)
        if (context == TO_INTENDEDPROJECT) {
            m = milestones[toIntendedProject];
            // don't need to check if canceled b/c lp does this
            if (m.accepted) {
                return 0;
            }
        // if the pledge is being transferred to m and is in the Pledged state, make
        // sure m is still accepting funds (not accepted or canceled)
        } else if (context == TO_OWNER &&
            (fromIntendedProject != toOwner &&
                toPledgeState == LiquidPledgingBase.PledgeState.Pledged)) {
            //TODO what if milestone isn't initialized? should we throw?
            // this can happen if someone adds a project through lp with this contracts address as the plugin
            // we can require(maxAmount > 0);
            // don't need to check if canceled b/c lp does this
            m = milestones[toOwner];
            if (m.accepted) {
                return 0;
            }
        }
        return amount;
    }

    /// @dev this is called by liquidPledging after every transfer to and from
    ///      a pledgeAdmin that has this contract as its plugin
    /// @dev see ILiquidPledgingPlugin interface for details about context param
    function afterTransfer(
        uint64 pledgeManager,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount
    ) external
    {
        require(msg.sender == address(liquidPledging));

        var (, fromOwner, , , , ,) = liquidPledging.getPledge(pledgeFrom);
        var (, toOwner, , , , , toPledgeState) = liquidPledging.getPledge(pledgeTo);

        if (context == TO_OWNER) {
            Milestone storage m;

            // If fromOwner != toOwner, the means that a pledge is being committed to
            // milestone m. We will accept any amount up to m.maxAmount, and return
            // the rest
            if (fromOwner != toOwner) {
                m = milestones[toOwner];
                uint returnFunds = 0;

                m.received += amount;
                // milestone is no longer accepting new funds
                if (m.accepted) {
                    returnFunds = amount;
                } else if (m.received > m.maxAmount) {
                    returnFunds = m.received - m.maxAmount;
                }

                // send any exceeding funds back
                if (returnFunds > 0) {
                    m.received -= returnFunds;
                    liquidPledging.cancelPledge(pledgeTo, returnFunds);
                }
            // if the pledge has been paid, then the vault should have transferred the
            // the funds to this contract. update the milestone with the amount the recipient
            // can collect. this is the amount of the paid pledge
            } else if (toPledgeState == LiquidPledgingBase.PledgeState.Paid) {
                m = milestones[toOwner];
                m.canCollect += amount;
            }
        }
    }

    //== public

    function addMilestone(
        string name,
        string url,
        uint _maxAmount,
        uint64 parentProject,
        address _recipient,
        address _reviewer,
        address _campaignReviewer
    ) public
    {
        uint64 idProject = liquidPledging.addProject(
            name,
            url,
            address(this),
            parentProject,
            uint64(0),
            ILiquidPledgingPlugin(this)
        );

        milestones[idProject] = Milestone(
            _maxAmount,
            0,
            0,
            _reviewer,
            _campaignReviewer,
            _recipient,
            false
        );
    }

    function acceptMilestone(uint64 idProject) public {
        bool isCanceled = liquidPledging.isProjectCanceled(idProject);
        require(!isCanceled);

        Milestone storage m = milestones[idProject];
        require(msg.sender == m.reviewer || msg.sender == m.campaignReviewer);
        require(!m.accepted);

        m.accepted = true;
        MilestoneAccepted(idProject);
    }

    function cancelMilestone(uint64 idProject) public {
        Milestone storage m = milestones[idProject];
        require(msg.sender == m.reviewer || msg.sender == m.campaignReviewer);
        require(!m.accepted);

        liquidPledging.cancelProject(idProject);
    }

    function withdraw(uint64 idProject, uint64 idPledge, uint amount) public {
        // we don't check if canceled here.
        // lp.withdraw will normalize the pledge & check if canceled
        Milestone storage m = milestones[idProject];
        require(msg.sender == m.recipient);
        require(m.accepted);

        liquidPledging.withdraw(idPledge, amount);
        collect(idProject);
    }

    /// Bit mask used for dividing pledge amounts in mWithdraw
    uint constant D64 = 0x10000000000000000;

    function mWithdraw(uint[] pledgesAmounts) public {
        uint64[] memory mIds = new uint64[](pledgesAmounts.length);

        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64(pledgesAmounts[i] & (D64-1));
            var (, idProject, , , , ,) = liquidPledging.getPledge(idPledge);

            mIds[i] = idProject;
            Milestone storage m = milestones[idProject];
            require(msg.sender == m.recipient);
            require(m.accepted);
        }

        liquidPledging.mWithdraw(pledgesAmounts);

        for (i = 0; i < mIds.length; i++ ) {
            collect(mIds[i]);
        }
    }

    function collect(uint64 idProject) public {
        Milestone storage m = milestones[idProject];
        require(msg.sender == m.recipient);

        if (m.canCollect > 0) {
            uint amount = m.canCollect;
            // TODO should this assert be removed?
            assert(this.balance >= amount);
            m.canCollect = 0;
            m.recipient.transfer(amount);
            PaymentCollected(idProject);
        }
    }

    function getMilestone(uint64 idProject) public view returns (
        uint maxAmount,
        uint received,
        uint canCollect,
        address reviewer,
        address campaignReviewer,
        address recipient,
        bool accepted
    ) {
        Milestone storage m = milestones[idProject];
        maxAmount = m.maxAmount;
        received = m.received;
        canCollect = m.canCollect;
        reviewer = m.reviewer;
        campaignReviewer = m.campaignReviewer;
        recipient = m.recipient;
        accepted = m.accepted;
    }
}