pragma solidity ^0.4.18; // solhint-disable-line


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
  // Required methods
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  // function ownerOf(uint256 _tokenId) public view returns (address addr);
  // function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  // function transferFrom(address _from, address _to, uint256 _tokenId) public;
  // function transfer(address _to, uint256 _tokenId) public;

  // event Transfer(address indexed from, address indexed to, uint256 tokenId);
  // event Approval(address indexed owner, address indexed approved, uint256 tokenId);

  // Optional
  // function name() public view returns (string name);
  // function symbol() public view returns (string symbol);
  // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}


contract DailyEtherToken is ERC721 {

  /*** EVENTS ***/

  /// @dev Birth event fired whenever a new token is created
  event Birth(uint256 tokenId, string name, address owner);

  /// @dev TokenSold event fired whenever a token is sold
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in ERC721. Ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "DailyEther"; // solhint-disable-line
  string public constant SYMBOL = "DailyEtherToken"; // solhint-disable-line

  uint256 private ticketPrice = 0.2 ether;
  string private betTitle = "";     // Title of bet
  uint256 private answerID = 0;     // The correct answer id, set when the bet is closed

  // A bet can have the following states:
  // Opened -- Accepting new bets
  // Locked -- Not accepting new bets, waiting for final results
  // Closed -- Bet completed, results announced and payout completed for winners
  bool isLocked = false;
  bool isClosed = false;

  /*** STORAGE ***/

  // Used to implement proper ERC721 implementation
  mapping (address => uint256) private addressToBetCount;

  // Holds the number of participants who placed a bet on specific answer
  mapping (uint256 => uint256) private answerIdToParticipantsCount;

  // Addresses of the accounts (or contracts) that can execute actions within each roles.
  address public roleAdminAddress;

  /*** DATATYPES ***/
  struct Participant {
    address user_address;
    uint256 answer_id;
  }
  Participant[] private participants;

  /*** ACCESS MODIFIERS ***/

  /// @dev Access modifier for Admin-only
  modifier onlyAdmin() {
    require(msg.sender == roleAdminAddress);
    _;
  }

  /*** CONSTRUCTOR ***/

  function DailyEtherToken() public {
    roleAdminAddress = msg.sender;
  }

  /*** PUBLIC FUNCTIONS ***/

  /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
  /// @param _to The address to be granted transfer approval. Pass address(0) to
  ///  clear all approvals.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
    // Caller must own token.
    require(false);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return addressToBetCount[_owner];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /// @dev Required for ERC-721 compliance.
  function name() public pure returns (string) {
    return NAME;
  }

  function payout(address _to) public onlyAdmin {
    _payout(_to);
  }


  /// @notice Returns all the relevant information about a specific participant.
  function getParticipant(uint256 _index) public view returns (
    address participantAddress,
    uint256 participantAnswerId
  ) {
    Participant storage p = participants[_index];
    participantAddress = p.user_address;
    participantAnswerId = p.answer_id;
  }


  // Called to close the bet. Sets the correct bet answer and sends payouts to
  // the bet winners
  function closeBet(uint256 _answerId) public onlyAdmin {

    // Make sure bet is Locked
    require(isLocked == true);

    // Make sure bet was not closed already
    require(isClosed == false);

    // Store correct answer id
    answerID = _answerId;

    // Calculate total earnings to send winners
    uint256 totalPrize = uint256(SafeMath.div(SafeMath.mul((ticketPrice * participants.length), 94), 100));

    // Calculate the prize we need to transfer per winner
    uint256 paymentPerParticipant = uint256(SafeMath.div(totalPrize, answerIdToParticipantsCount[_answerId]));

    // Mark contract as closed so we won't close it again
    isClosed = true;

    // Transfer the winning amount to each of the winners
    for(uint i=0; i<participants.length; i++)
    {
        if (participants[i].answer_id == _answerId) {
            if (participants[i].user_address != address(this)) {
                participants[i].user_address.transfer(paymentPerParticipant);
            }
        }
    }
  }

  // Allows someone to send ether and obtain the token
  function bet(uint256 _answerId) public payable {

    // Make sure bet accepts new bets
    require(isLocked == false);

    // Answer ID not allowed to be 0, check it is 1 or greater
    require(_answerId >= 1);

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= ticketPrice);

    // Store new bet
    Participant memory _p = Participant({
      user_address: msg.sender,
      answer_id: _answerId
    });
    participants.push(_p);

    addressToBetCount[msg.sender]++;

    // Increase the count of participants who placed their bet on this answer
    answerIdToParticipantsCount[_answerId]++;
  }

  // Returns the ticket price for the bet
  function getTicketPrice() public view returns (uint256 price) {
    return ticketPrice;
  }

  // Returns the bet title
  function getBetTitle() public view returns (string title) {
    return betTitle;
  }

  /// @dev Assigns a new address to act as the Admin
  /// @param _newAdmin The address of the new Admin
  function setAdmin(address _newAdmin) public onlyAdmin {
    require(_newAdmin != address(0));
    roleAdminAddress = _newAdmin;
  }

  // Inits the bet data
  function initBet(uint256 _ticketPriceWei, string _betTitle) public onlyAdmin {
    ticketPrice = _ticketPriceWei;
    betTitle = _betTitle;
  }

  // Called to lock bet, new participants can no longer join
  function lockBet() public onlyAdmin {
    isLocked = true;
  }

  // Called to lock bet, new participants can no longer join
  function isBetLocked() public view returns (bool) {
    return isLocked;
  }

  // Called to lock bet, new participants can no longer join
  function isBetClosed() public view returns (bool) {
    return isClosed;
  }

  /// @dev Required for ERC-721 compliance.
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

  /// Returns the total of bets in contract
  function totalSupply() public view returns (uint256 total) {
    return participants.length;
  }


  /*** PRIVATE FUNCTIONS ***/

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      roleAdminAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

}

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