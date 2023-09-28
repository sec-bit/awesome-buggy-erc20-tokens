pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract AccountRegistry is Ownable {
  mapping(address => bool) public accounts;

  // Inviter + recipient pair
  struct Invite {
    address creator;
    address recipient;
  }

  // Mapping of public keys as Ethereum addresses to invite information
  // NOTE: the address keys here are NOT Ethereum addresses, we just happen
  // to work with the public keys in terms of Ethereum address strings because
  // this is what `ecrecover` produces when working with signed text.
  mapping(address => Invite) public invites;

  InviteCollateralizer public inviteCollateralizer;
  ERC20 public blt;
  address private inviteAdmin;

  event InviteCreated(address indexed inviter);
  event InviteAccepted(address indexed inviter, address indexed recipient);
  event AccountCreated(address indexed newUser);

  function AccountRegistry(ERC20 _blt, InviteCollateralizer _inviteCollateralizer) public {
    blt = _blt;
    accounts[owner] = true;
    inviteAdmin = owner;
    inviteCollateralizer = _inviteCollateralizer;
  }

  function setInviteCollateralizer(InviteCollateralizer _newInviteCollateralizer) public nonZero(_newInviteCollateralizer) onlyOwner {
    inviteCollateralizer = _newInviteCollateralizer;
  }

  function setInviteAdmin(address _newInviteAdmin) public onlyOwner nonZero(_newInviteAdmin) {
    inviteAdmin = _newInviteAdmin;
  }

  /**
   * @dev Create an account instantly. Reserved for the "invite admin" which is managed by the Bloom team
   * @param _newUser Address of the user receiving an account
   */
  function createAccount(address _newUser) public onlyInviteAdmin {
    require(!accounts[_newUser]);
    createAccountFor(_newUser);
  }

  /**
   * @dev Create an invite using the signing model described in the contract description
   * @param _sig Signature for `msg.sender`
   */
  function createInvite(bytes _sig) public onlyUser {
    require(inviteCollateralizer.takeCollateral(msg.sender));

    address signer = recoverSigner(_sig);
    require(inviteDoesNotExist(signer));

    invites[signer] = Invite(msg.sender, address(0));
    InviteCreated(msg.sender);
  }

  /**
   * @dev Accept an invite using the signing model described in the contract description
   * @param _sig Signature for `msg.sender` via the same key that issued the initial invite
   */
  function acceptInvite(bytes _sig) public onlyNonUser {
    address signer = recoverSigner(_sig);
    require(inviteExists(signer) && inviteHasNotBeenAccepted(signer));

    invites[signer].recipient = msg.sender;
    createAccountFor(msg.sender);
    InviteAccepted(invites[signer].creator, msg.sender);
  }

  /**
   * @dev Check if an invite has not been set on the struct meaning it hasn't been accepted
   */
  function inviteHasNotBeenAccepted(address _signer) internal view returns (bool) {
    return invites[_signer].recipient == address(0);
  }

  /**
   * @dev Check that an invite hasn't already been created with this signer
   */
  function inviteDoesNotExist(address _signer) internal view returns (bool) {
    return !inviteExists(_signer);
  }

  /**
   * @dev Check that an invite has already been created with this signer
   */
  function inviteExists(address _signer) internal view returns (bool) {
    return invites[_signer].creator != address(0);
  }

  /**
   * @dev Recover the address associated with the public key that signed the provided signature
   * @param _sig Signature of `msg.sender`
   */
  function recoverSigner(bytes _sig) private view returns (address) {
    address signer = ECRecovery.recover(keccak256(msg.sender), _sig);
    require(signer != address(0));

    return signer;
  }

  /**
   * @dev Create an account and emit an event
   * @param _newUser Address of the new user
   */
  function createAccountFor(address _newUser) private {
    accounts[_newUser] = true;
    AccountCreated(_newUser);
  }

  /**
   * @dev Addresses with Bloom accounts already are not allowed
   */
  modifier onlyNonUser {
    require(!accounts[msg.sender]);
    _;
  }

  /**
   * @dev Addresses without Bloom accounts already are not allowed
   */
  modifier onlyUser {
    require(accounts[msg.sender]);
    _;
  }

  modifier nonZero(address _address) {
    require(_address != 0);
    _;
  }

  modifier onlyInviteAdmin {
    require(msg.sender == inviteAdmin);
    _;
  }
}

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using his signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Extracting these values isn't possible without assembly
    // solhint-disable no-inline-assembly
    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}

contract InviteCollateralizer is Ownable {
  // We need to rely on time for lockup periods. The amount that miners can manipulate
  // a timestamp is not a concern for this behavior since token lockups are for several months
  // solhint-disable not-rely-on-time

  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  ERC20 public blt;
  address public seizedTokensWallet;
  mapping (address => Collateralization[]) public collateralizations;
  uint256 public collateralAmount = 1e17;
  uint64 public lockupDuration = 1 years;

  address private collateralTaker;
  address private collateralSeizer;

  struct Collateralization {
    uint256 value; // Amount of BLT
    uint64 releaseDate; // Date BLT can be withdrawn
    bool claimed; // Has the original owner or the network claimed the collateral
  }

  event CollateralPosted(address indexed owner, uint64 releaseDate, uint256 amount);
  event CollateralSeized(address indexed owner, uint256 collateralId);

  function InviteCollateralizer(ERC20 _blt, address _seizedTokensWallet) public {
    blt = _blt;
    seizedTokensWallet = _seizedTokensWallet;
    collateralTaker = owner;
    collateralSeizer = owner;
  }

  function takeCollateral(address _owner) public onlyCollateralTaker returns (bool) {
    require(blt.transferFrom(_owner, address(this), collateralAmount));

    uint64 releaseDate = uint64(now) + lockupDuration;
    CollateralPosted(_owner, releaseDate, collateralAmount);
    collateralizations[_owner].push(Collateralization(collateralAmount, releaseDate, false));

    return true;
  }

  function reclaim() public returns (bool) {
    require(collateralizations[msg.sender].length > 0);

    uint256 reclaimableAmount = 0;

    for (uint256 i = 0; i < collateralizations[msg.sender].length; i++) {
      if (collateralizations[msg.sender][i].claimed) {
        continue;
      } else if (collateralizations[msg.sender][i].releaseDate > now) {
        break;
      }

      reclaimableAmount = reclaimableAmount.add(collateralizations[msg.sender][i].value);
      collateralizations[msg.sender][i].claimed = true;
    }

    require(reclaimableAmount > 0);

    return blt.transfer(msg.sender, reclaimableAmount);
  }

  function seize(address _subject, uint256 _collateralId) public onlyCollateralSeizer {
    require(collateralizations[_subject].length >= _collateralId + 1);
    require(!collateralizations[_subject][_collateralId].claimed);

    collateralizations[_subject][_collateralId].claimed = true;
    blt.transfer(seizedTokensWallet, collateralizations[_subject][_collateralId].value);
    CollateralSeized(_subject, _collateralId);
  }

  function changeCollateralTaker(address _newCollateralTaker) public nonZero(_newCollateralTaker) onlyOwner {
    collateralTaker = _newCollateralTaker;
  }

  function changeCollateralSeizer(address _newCollateralSeizer) public nonZero(_newCollateralSeizer) onlyOwner {
    collateralSeizer = _newCollateralSeizer;
  }

  function changeCollateralAmount(uint256 _newAmount) public onlyOwner {
    require(_newAmount > 0);
    collateralAmount = _newAmount;
  }

  function changeSeizedTokensWallet(address _newSeizedTokensWallet) public nonZero(_newSeizedTokensWallet) onlyOwner {
    seizedTokensWallet = _newSeizedTokensWallet; 
  }

  function changeLockupDuration(uint64 _newLockupDuration) public onlyOwner {
    lockupDuration = _newLockupDuration;
  }

  modifier nonZero(address _address) {
    require(_address != 0);
    _;
  }

  modifier onlyCollateralTaker {
    require(msg.sender == collateralTaker);
    _;
  }

  modifier onlyCollateralSeizer {
    require(msg.sender == collateralSeizer);
    _;
  }
}