pragma solidity ^0.4.19;


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
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause()
        public
        onlyOwner
        whenNotPaused
        returns (bool)
    {
        paused = true;
        Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause()
        public
        onlyOwner
        whenPaused
        returns (bool)
    {
        paused = false;
        Unpause();
        return true;
    }
}


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    // Required methods for ERC-721 Compatibility.
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);

    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 _balance);
}


contract MasterpieceAccessControl {
    /// - CEO: The CEO can reassign other roles, change the addresses of dependent smart contracts,
    /// and pause/unpause the MasterpieceCore contract.
    /// - CFO: The CFO can withdraw funds from its auction and sale contracts.
    /// - Curator: The Curator can mint regular and promo Masterpieces.

    /// @dev The addresses of the accounts (or contracts) that can execute actions within each role.
    address public ceoAddress;
    address public cfoAddress;
    address public curatorAddress;

    /// @dev Keeps track whether the contract is paused. When that is true, most actions are blocked.
    bool public paused = false;

    /// @dev Event is fired when contract is forked.
    event ContractFork(address newContract);

    /// @dev Access-modifier for CEO-only functionality.
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access-modifier for CFO-only functionality.
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access-modifier for Curator-only functionality.
    modifier onlyCurator() {
        require(msg.sender == curatorAddress);
        _;
    }

    /// @dev Access-modifier for C-level-only functionality.
    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == curatorAddress
        );
        _;
    }

    /// Assigns a new address to the CEO role. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// Assigns a new address to the Curator role. Only available to the current CEO.
    /// @param _newCurator The address of the new Curator
    function setCurator(address _newCurator) external onlyCEO {
        require(_newCurator != address(0));

        curatorAddress = _newCurator;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/
    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause()
        external
        onlyCLevel
        whenNotPaused
    {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause()
        public
        onlyCEO
        whenPaused
    {
        // can't unpause if contract was forked
        paused = false;
    }

}


/// Core functionality for CrytpoMasterpieces.
contract MasterpieceBase is MasterpieceAccessControl {

    /*** DATA TYPES ***/
    /// The main masterpiece struct.
    struct Masterpiece {
        /// Name of the masterpiece
        string name;
        /// Name of the artist who created the masterpiece
        string artist;
        // The timestamp from the block when this masterpiece was created
        uint64 birthTime;
    }

    /*** EVENTS ***/
    /// The Birth event is fired whenever a new masterpiece comes into existence.
    event Birth(address owner, uint256 tokenId, uint256 snatchWindow, string name, string artist);
    /// Transfer event as defined in current draft of ERC721. Fired every time masterpiece ownership
    /// is assigned, including births.
    event TransferToken(address from, address to, uint256 tokenId);
    /// The TokenSold event is fired whenever a token is sold.
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 price, address prevOwner, address owner, string name);

    /*** STORAGE ***/
    /// An array containing all Masterpieces in existence. The id of each masterpiece
    /// is an index in this array.
    Masterpiece[] masterpieces;

    /// @dev The address of the ClockAuction contract that handles sale auctions
    /// for Masterpieces that users want to sell for less than or equal to the
    /// next price, which is automatically set by the contract.
    SaleClockAuction public saleAuction;

    /// @dev A mapping from masterpiece ids to the address that owns them.
    mapping (uint256 => address) public masterpieceToOwner;

    /// @dev A mapping from masterpiece ids to their snatch window.
    mapping (uint256 => uint256) public masterpieceToSnatchWindow;

    /// @dev A mapping from owner address to count of masterpieces that address owns.
    /// Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) public ownerMasterpieceCount;

    /// @dev A mapping from masterpiece ids to an address that has been approved to call
    ///  transferFrom(). Each masterpiece can only have 1 approved address for transfer
    ///  at any time. A 0 value means no approval is outstanding.
    mapping (uint256 => address) public masterpieceToApproved;

    // @dev A mapping from masterpiece ids to their price.
    mapping (uint256 => uint256) public masterpieceToPrice;

    // @dev Returns the snatch window of the given token.
    function snatchWindowOf(uint256 _tokenId)
        public
        view
        returns (uint256 price)
    {
        return masterpieceToSnatchWindow[_tokenId];
    }

    /// @dev Assigns ownership of a specific masterpiece to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Transfer ownership and update owner masterpiece counts.
        ownerMasterpieceCount[_to]++;
        masterpieceToOwner[_tokenId] = _to;
        // When creating new tokens _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownerMasterpieceCount[_from]--;
            // clear any previously approved ownership exchange
            delete masterpieceToApproved[_tokenId];
        }
        // Fire the transfer event.
        TransferToken(_from, _to, _tokenId);
    }

    /// @dev An internal method that creates a new masterpiece and stores it.
    /// @param _name The name of the masterpiece, e.g. Mona Lisa
    /// @param _artist The artist who created this masterpiece, e.g. Leonardo Da Vinci
    /// @param _owner The initial owner of this masterpiece
    function _createMasterpiece(
        string _name,
        string _artist,
        uint256 _price,
        uint256 _snatchWindow,
        address _owner
    )
        internal
        returns (uint)
    {
        Masterpiece memory _masterpiece = Masterpiece({
            name: _name,
            artist: _artist,
            birthTime: uint64(now)
        });
        uint256 newMasterpieceId = masterpieces.push(_masterpiece) - 1;

        // Fire the birth event.
        Birth(
            _owner,
            newMasterpieceId,
            _snatchWindow,
            _masterpiece.name,
            _masterpiece.artist
        );

        // Set the price for the masterpiece.
        masterpieceToPrice[newMasterpieceId] = _price;

        // Set the snatch window for the masterpiece.
        masterpieceToSnatchWindow[newMasterpieceId] = _snatchWindow;

        // This will assign ownership, and also fire the Transfer event as per ERC-721 draft.
        _transfer(0, _owner, newMasterpieceId);

        return newMasterpieceId;
    }

}


/// Pricing logic for CrytpoMasterpieces.
contract MasterpiecePricing is MasterpieceBase {

    /*** CONSTANTS ***/
    // Pricing steps.
    uint128 private constant FIRST_STEP_LIMIT = 0.05 ether;
    uint128 private constant SECOND_STEP_LIMIT = 0.5 ether;
    uint128 private constant THIRD_STEP_LIMIT = 2.0 ether;
    uint128 private constant FOURTH_STEP_LIMIT = 5.0 ether;

    /// @dev Computes the next listed price.
    /// @notice This contract doesn't handle setting the Masterpiece's next listing price.
    /// This next price is only used from inside bid() in MasterpieceAuction and inside
    /// purchase() in MasterpieceSale to set the next listed price.
    function setNextPriceOf(uint256 tokenId, uint256 salePrice)
        external
        whenNotPaused
    {
        // The next price of any token can only be set by the sale auction contract.
        // To set the next price for a token sold through the regular sale, use only
        // computeNextPrice and directly update the mapping.
        require(msg.sender == address(saleAuction));
        masterpieceToPrice[tokenId] = computeNextPrice(salePrice);
    }

    /// @dev Computes next price of token given the current sale price.
    function computeNextPrice(uint256 salePrice)
        internal
        pure
        returns (uint256)
    {
        if (salePrice < FIRST_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 200), 95);
        } else if (salePrice < SECOND_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 135), 96);
        } else if (salePrice < THIRD_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 125), 97);
        } else if (salePrice < FOURTH_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 120), 97);
        } else {
            return SafeMath.div(SafeMath.mul(salePrice, 115), 98);
        }
    }

    /// @dev Computes the payment for the token, which is the sale price of the token
    /// minus the house's cut.
    function computePayment(uint256 salePrice)
        internal
        pure
        returns (uint256)
    {
        if (salePrice < FIRST_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 95), 100);
        } else if (salePrice < SECOND_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 96), 100);
        } else if (salePrice < FOURTH_STEP_LIMIT) {
            return SafeMath.div(SafeMath.mul(salePrice, 97), 100);
        } else {
            return SafeMath.div(SafeMath.mul(salePrice, 98), 100);
        }
    }

}


/// Methods required for Non-Fungible Token Transactions in adherence to ERC721.
contract MasterpieceOwnership is MasterpiecePricing, ERC721 {

    /// Name of the collection of NFTs managed by this contract, as defined in ERC721.
    string public constant NAME = "Masterpieces";
    /// Symbol referencing the entire collection of NFTs managed in this contract, as
    /// defined in ERC721.
    string public constant SYMBOL = "CMP";

    bytes4 public constant INTERFACE_SIGNATURE_ERC165 =
    bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 public constant INTERFACE_SIGNATURE_ERC721 =
    bytes4(keccak256("name()")) ^
    bytes4(keccak256("symbol()")) ^
    bytes4(keccak256("totalSupply()")) ^
    bytes4(keccak256("balanceOf(address)")) ^
    bytes4(keccak256("ownerOf(uint256)")) ^
    bytes4(keccak256("approve(address,uint256)")) ^
    bytes4(keccak256("transfer(address,uint256)")) ^
    bytes4(keccak256("transferFrom(address,address,uint256)")) ^
    bytes4(keccak256("tokensOfOwner(address)")) ^
    bytes4(keccak256("tokenMetadata(uint256,string)"));

    /// @dev Grant another address the right to transfer a specific Masterpiece via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Masterpiece that can be transferred if this call succeeds.
    /// @notice Required for ERC-20 and ERC-721 compliance.
    function approve(address _to, uint256 _tokenId)
        external
        whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Fire approval event upon successful approval.
        Approval(msg.sender, _to, _tokenId);
    }

    /// @dev Transfers a Masterpiece to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 or else your
    /// Masterpiece may be lost forever.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Masterpiece to transfer.
    /// @notice Required for ERC-20 and ERC-721 compliance.
    function transfer(address _to, uint256 _tokenId)
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any Masterpieces (except very briefly
        // after a Masterpiece is created.
        require(_to != address(this));
        // Disallow transfers to the auction contract to prevent accidental
        // misuse. Auction contracts should only take ownership of Masterpieces
        // through the approve and transferFrom flow.
        require(_to != address(saleAuction));
        // You can only send your own Masterpiece.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, fire Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @dev Transfer a Masterpiece owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Masterpiece to be transfered.
    /// @param _to The address that should take ownership of the Masterpiece. Can be any
    /// address, including the caller.
    /// @param _tokenId The ID of the Masterpiece to be transferred.
    /// @notice Required for ERC-20 and ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and fires Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @dev Returns a list of all Masterpiece IDs assigned to an address.
    /// @param _owner The owner whose Masterpieces we are interested in.
    ///  This method MUST NEVER be called by smart contract code. First, it is fairly
    ///  expensive (it walks the entire Masterpiece array looking for Masterpieces belonging
    /// to owner), but it also returns a dynamic array, which is only supported for web3
    /// calls, and not contract-to-contract calls. Thus, this method is external rather
    /// than public.
    function tokensOfOwner(address _owner)
        external
        view
        returns(uint256[] ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Returns an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalMasterpieces = totalSupply();
            uint256 resultIndex = 0;

            uint256 masterpieceId;
            for (masterpieceId = 0; masterpieceId <= totalMasterpieces; masterpieceId++) {
                if (masterpieceToOwner[masterpieceId] == _owner) {
                    result[resultIndex] = masterpieceId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool)
    {
        return ((_interfaceID == INTERFACE_SIGNATURE_ERC165) || (_interfaceID == INTERFACE_SIGNATURE_ERC721));
    }

    // @notice Optional for ERC-20 compliance.
    function name() external pure returns (string) {
        return NAME;
    }

    // @notice Optional for ERC-20 compliance.
    function symbol() external pure returns (string) {
        return SYMBOL;
    }

    /// @dev Returns the address currently assigned ownership of a given Masterpiece.
    /// @notice Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = masterpieceToOwner[_tokenId];
        require(owner != address(0));
    }

    /// @dev Returns the total number of Masterpieces currently in existence.
    /// @notice Required for ERC-20 and ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return masterpieces.length;
    }

    /// @dev Returns the number of Masterpieces owned by a specific address.
    /// @param _owner The owner address to check.
    /// @notice Required for ERC-20 and ERC-721 compliance.
    function balanceOf(address _owner)
        public
        view
        returns (uint256 count)
    {
        return ownerMasterpieceCount[_owner];
    }

    /// @dev Checks if a given address is the current owner of a particular Masterpiece.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId Masterpiece id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return masterpieceToOwner[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    /// approval. Setting _approved to address(0) clears all transfer approval.
    /// NOTE: _approve() does NOT send the Approval event. This is intentional because
    /// _approve() and transferFrom() are used together for putting Masterpieces on auction, and
    /// there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        masterpieceToApproved[_tokenId] = _approved;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Masterpiece.
    /// @param _claimant the address we are confirming Masterpiece is approved for.
    /// @param _tokenId Masterpiece id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return masterpieceToApproved[_tokenId] == _claimant;
    }

    /// Safety check on _to address to prevent against an unexpected 0x0 default.
    function _addressNotNull(address _to) internal pure returns (bool) {
        return _to != address(0);
    }
}


/// @title Auction Core
/// @dev Contains models, variables, and internal methods for the auction.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract ClockAuctionBase {

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
    }

    // Reference to contract tracking NFT ownership
    MasterpieceOwnership public nonFungibleContract;

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;

    // Map from token ID to their corresponding auction.
    mapping (uint256 => Auction) public tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 price, address winner);
    event AuctionCancelled(uint256 tokenId);

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        // Explicitly check that this auction is currently live.
        // (Because of how Ethereum mappings work, we can't just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        require(_isOnAuction(auction));
        // Check that the bid is greater than or equal to the current price
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);
        // Grab a reference to the seller before the auction struct gets deleted.
        address seller = auction.seller;
        // Remove the auction before sending the fees to the sender so we can't have a reentrancy attack.
        _removeAuction(_tokenId);
        if (price > 0) {
            // Calculate the auctioneer's cut.
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;
            // NOTE: Doing a transfer() in the middle of a complex
            // method like this is generally discouraged because of
            // reentrancy attacks and DoS attacks if the seller is
            // a contract with an invalid fallback function. We explicitly
            // guard against reentrancy attacks by removing the auction
            // before calling transfer(), and the only thing the seller
            // can DoS is the sale of their own asset! (And if it's an
            // accident, they can call cancelAuction(). )
            seller.transfer(sellerProceeds);
            _transfer(msg.sender, _tokenId);
            // Update the next listing price of the token.
            nonFungibleContract.setNextPriceOf(_tokenId, price);
        }

        // Calculate any excess funds included with the bid. If the excess
        // is anything worth worrying about, transfer it back to bidder.
        // NOTE: We checked above that the bid amount is greater than or
        // equal to the price so this cannot underflow.
        uint256 bidExcess = _bidAmount - price;

        // Return the funds. Similar to the previous transfer, this is
        // not susceptible to a re-entry attack because the auction is
        // removed before any transfers occur.
        msg.sender.transfer(bidExcess);

        // Tell the world!
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /// @dev Returns true if the NFT is on auction.
    /// @param _auction - Auction to check.
    function _isOnAuction(Auction storage _auction)
        internal
        view
        returns (bool)
    {
        return (_auction.startedAt > 0);
    }

    /// @dev Returns current price of an NFT on auction. Broken into two
    ///  functions (this one, that computes the duration from the auction
    ///  structure, and the other that does the price computation) so we
    ///  can easily test that the price computation works correctly.
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarnatees that the
        // now variable doesn't ever go backwards).
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

    /// @dev Computes the current price of an auction. Factored out
    ///  from _currentPrice so we can run extensive unit tests.
    ///  When testing, make this function public and turn on
    ///  `Current price computation` test suite.
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our public functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addAuction())
        if (_secondsPassed >= _duration) {
            // We've reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return _endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            // This multiplication can't overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * ownerCut / 10000;
    }

}


/// @title Clock auction for non-fungible tokens.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract ClockAuction is Pausable, ClockAuctionBase {

    /// @dev The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    bytes4 public constant INTERFACE_SIGNATURE_ERC721 = bytes4(0x9a20483d);

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000.
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        MasterpieceOwnership candidateContract = MasterpieceOwnership(_nftAddress);
        require(candidateContract.supportsInterface(INTERFACE_SIGNATURE_ERC721));
        nonFungibleContract = candidateContract;
    }

    /// @dev Remove all Ether from the contract, which is the owner's cuts
    ///  as well as any Ether sent directly to the contract address.
    ///  Always transfers to the NFT contract, but can be called either by
    ///  the owner or the NFT contract.
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        // We are using this boolean method to make sure that even if one fails it will still work
        bool res = nftAddress.send(this.balance);
    }

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
        whenNotPaused
    {
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the auction struct.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
        // _bid will throw if the bid or funds transfer fails
        _bid(_tokenId, msg.value);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId)
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(uint256 _tokenId)
        external
        whenPaused
        onlyOwner
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
            Auction storage auction = tokenIdToAuction[_tokenId];
            require(_isOnAuction(auction));
            return (
                auction.seller,
                auction.startingPrice,
                auction.endingPrice,
                auction.duration,
                auction.startedAt
            );
        }

    /// @dev Returns the current price of an auction.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

}


/// @title Clock auction
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract SaleClockAuction is ClockAuction {

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setSaleAuctionAddress() call.
    bool public isSaleClockAuction = true;

    // Delegate constructor
    function SaleClockAuction(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of auction (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the auction struct.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Places a bid for the Masterpiece. Requires the sender
    /// is the Masterpiece Core contract because all bid methods
    /// should be wrapped.
    function bid(uint256 _tokenId)
        external
        payable
    {
        /* require(msg.sender == address(nonFungibleContract)); */
        // _bid checks that token ID is valid and will throw if bid fails
        _bid(_tokenId, msg.value);
    }
}


contract MasterpieceAuction is MasterpieceOwnership {

    /// @dev Transfers the balance of the sale auction contract
    /// to the MasterpieceCore contract. We use two-step withdrawal to
    /// prevent two transfer calls in the auction bid function.
    function withdrawAuctionBalances()
        external
        onlyCLevel
    {
        saleAuction.withdrawBalance();
    }

    /// @notice The auction contract variable (saleAuction) is defined in MasterpieceBase
    /// to allow us to refer to them in MasterpieceOwnership to prevent accidental transfers.
    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address)
        external
        onlyCEO
    {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        // NOTE: verify that a contract is what we expect -
        // https://github.com/Lunyr/crowdsale-contracts/blob/
        // cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
    }

    /// @dev The owner of a Masterpiece can put it up for auction.
    function createSaleAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        // Check that the Masterpiece to be put on an auction sale is owned by
        // its current owner. If it's already in an auction, this validation
        // will fail because the MasterpieceAuction contract owns the
        // Masterpiece once it is put on an auction sale.
        require(_owns(msg.sender, _tokenId));
        _approve(_tokenId, saleAuction);
        // Sale auction throws if inputs are invalid and clears
        // transfer approval after escrow
        saleAuction.createAuction(
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

}


contract MasterpieceSale is MasterpieceAuction {

    // Allows someone to send ether and obtain the token
    function purchase(uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
        address newOwner = msg.sender;
        address oldOwner = masterpieceToOwner[_tokenId];
        uint256 salePrice = masterpieceToPrice[_tokenId];

        // Require that the masterpiece is either currently owned by the Masterpiece
        // Core contract or was born within the snatch window.
        require(
            (oldOwner == address(this)) ||
            (now - masterpieces[_tokenId].birthTime <= masterpieceToSnatchWindow[_tokenId])
        );

        // Require that the owner of the token is not sending to self.
        require(oldOwner != newOwner);

        // Require that the Masterpiece is not in an auction by checking that
        // the Sale Clock Auction contract is not the owner.
        require(address(oldOwner) != address(saleAuction));

        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));

        // Check that sent amount is greater than or equal to the sale price
        require(msg.value >= salePrice);

        uint256 payment = uint256(computePayment(salePrice));
        uint256 purchaseExcess = SafeMath.sub(msg.value, salePrice);

        // Set next listing price.
        masterpieceToPrice[_tokenId] = computeNextPrice(salePrice);

        // Transfer the Masterpiece to the buyer.
        _transfer(oldOwner, newOwner, _tokenId);

        // Pay seller of the Masterpiece if they are not this contract.
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }

        TokenSold(_tokenId, salePrice, masterpieceToPrice[_tokenId], oldOwner, newOwner, masterpieces[_tokenId].name);

        // Reimburse the buyer of any excess paid.
        msg.sender.transfer(purchaseExcess);
    }

    function priceOf(uint256 _tokenId)
        public
        view
        returns (uint256 price)
    {
        return masterpieceToPrice[_tokenId];
    }

}


contract MasterpieceMinting is MasterpieceSale {

    /*** CONSTANTS ***/
    /// @dev Starting price of a regular Masterpiece.
    uint128 private constant STARTING_PRICE = 0.001 ether;
    /// @dev Limit of number of promo masterpieces that can be created.
    uint16 private constant PROMO_CREATION_LIMIT = 10000;

    /// @dev Counts the number of Promotional Masterpieces the contract owner has created.
    uint16 public promoMasterpiecesCreatedCount;
    /// @dev Reference to contract tracking Non Fungible Token ownership
    ERC721 public nonFungibleContract;

    /// @dev Creates a new Masterpiece with the given name and artist.
    function createMasterpiece(
        string _name,
        string _artist,
        uint256 _snatchWindow
    )
        public
        onlyCurator
        returns (uint)
    {
        uint256 masterpieceId = _createMasterpiece(_name, _artist, STARTING_PRICE, _snatchWindow, address(this));
        return masterpieceId;
    }

    /// @dev Creates a new promotional Masterpiece with the given name, artist, starting
    /// price, and owner. If the owner or the price is not set, we default them to the
    /// curator's address and the starting price for all masterpieces.
    function createPromoMasterpiece(
        string _name,
        string _artist,
        uint256 _snatchWindow,
        uint256 _price,
        address _owner
    )
        public
        onlyCurator
        returns (uint)
    {
        require(promoMasterpiecesCreatedCount < PROMO_CREATION_LIMIT);

        address masterpieceOwner = _owner;
        if (masterpieceOwner == address(0)) {
            masterpieceOwner = curatorAddress;
        }

        if (_price <= 0) {
            _price = STARTING_PRICE;
        }

        uint256 masterpieceId = _createMasterpiece(_name, _artist, _price, _snatchWindow, masterpieceOwner);
        promoMasterpiecesCreatedCount++;
        return masterpieceId;
    }

}


/// CryptoMasterpieces: Collectible fine art masterpieces on the Ethereum blockchain.
contract MasterpieceCore is MasterpieceMinting {

    // - MasterpieceAccessControl: This contract defines which users are granted the given roles that are
    // required to execute specific operations.
    //
    // - MasterpieceBase: This contract inherits from the MasterpieceAccessControl contract and defines
    // the core functionality of CryptoMasterpieces, including the data types, storage, and constants.
    //
    // - MasterpiecePricing: This contract inherits from the MasterpieceBase contract and defines
    // the pricing logic for CryptoMasterpieces. With every purchase made through the Core contract or
    // through a sale auction, the next listed price will multiply based on 5 price tiers. This ensures
    // that the Masterpiece bought through CryptoMasterpieces will always be adjusted to its fair market
    // value.
    //
    // - MasterpieceOwnership: This contract inherits from the MasterpiecePricing contract and the ERC-721
    // (https://github.com/ethereum/EIPs/issues/721) contract and implements the methods required for
    //  Non-Fungible Token Transactions.
    //
    // - MasterpieceAuction: This contract inherits from the MasterpieceOwnership contract. It defines
    // the Dutch "clock" auction mechanism for owners of a masterpiece to place it on sale. The auction
    // starts off at the automatically generated next price and until it is sold, decrements the price
    // as time passes. The owner of the masterpiece can cancel the auction at any point and the price
    // cannot go lower than the price that the owner bought the masterpiece for.
    //
    // - MasterpieceSale: This contract inherits from the MasterpieceAuction contract. It defines the
    // tiered pricing logic and handles all sales. It also checks that a Masterpiece is not in an
    // auction before approving a purchase.
    //
    // - MasterpieceMinting: This contract inherits from the MasterpieceSale contract. It defines the
    // creation of new regular and promotional masterpieces.

    // Set in case the core contract is broken and a fork is required
    address public newContractAddress;

    function MasterpieceCore() public {
        // Starts paused.
        paused = true;

        // The creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // The creator of the contract is also the initial Curator
        curatorAddress = msg.sender;
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It's up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address)
        external
        onlyCEO
        whenPaused
    {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        ContractFork(_v2Address);
    }

    /// @dev Withdraw all Ether from the contract. This includes the fee on every
    /// masterpiece sold and any Ether sent directly to the contract address.
    /// Only the CFO can withdraw the balance or specify the address to send
    /// the balance to.
    function withdrawBalance(address _to) external onlyCFO {
        // We are using this boolean method to make sure that even if one fails it will still work
        if (_to == address(0)) {
            cfoAddress.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }

    /// @notice Returns all the relevant information about a specific masterpiece.
    /// @param _tokenId The tokenId of the masterpiece of interest.
    function getMasterpiece(uint256 _tokenId) external view returns (
        string name,
        string artist,
        uint256 birthTime,
        uint256 snatchWindow,
        uint256 sellingPrice,
        address owner
    ) {
        Masterpiece storage masterpiece = masterpieces[_tokenId];
        name = masterpiece.name;
        artist = masterpiece.artist;
        birthTime = uint256(masterpiece.birthTime);
        snatchWindow = masterpieceToSnatchWindow[_tokenId];
        sellingPrice = masterpieceToPrice[_tokenId];
        owner = masterpieceToOwner[_tokenId];
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can't have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive call.
    function unpause()
        public
        onlyCEO
        whenPaused
    {
        require(saleAuction != address(0));
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpause();
    }

}