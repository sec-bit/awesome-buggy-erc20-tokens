pragma solidity ^0.4.11;


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


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
        if (newOwner != address(0)) {
            owner = newOwner;
        }
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
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        Unpause();
        return true;
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
    ERC721 public nonFungibleContract;

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;

    // Map from token ID to their corresponding auction.
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
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

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address seller = auction.seller;

        // The bid is good! Remove the auction before sending the fees
        // to the sender so we can't have a reentrancy attack.
        _removeAuction(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            // Calculate the auctioneer's cut.
            // (NOTE: _computeCut() is guaranteed to return a
            // value <= price, so this subtraction can't go negative.)
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
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
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
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000.
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
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
        nftAddress.transfer(this.balance);
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
        _transfer(msg.sender, _tokenId);
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
    whenPaused
    onlyOwner
    external
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

//
contract GeneScience {

    uint64 _seed = 0;

    /// @dev simply a boolean to indicate this is the contract we expect to be
    /// pure means "they promise not to read from or modify the state."
    function isGeneScience() public pure returns (bool) {
        return true;
    }

    // return a pseudo random number between lower and upper bounds
    // given the number of previous blocks it should hash.
    function random(uint64 upper) internal returns (uint64) {
        _seed = uint64(keccak256(keccak256(block.blockhash(block.number), _seed), now));
        return _seed % upper;
    }

    function randomBetween(uint32 a, uint32 b) internal returns (uint32) {
        uint32 min;
        uint32 max;
        if(a < b) {
            min = a;
            max = b;
        } else {
            min = b;
            max = a;
        }

        return min + uint32(random(max - min + 1));
    }

    function randomCode() internal returns (uint8) {
        //
        uint64 r = random(1000000);

        if (r <= 163) return 151;
        if (r <= 327) return 251;
        if (r <= 490) return 196;
        if (r <= 654) return 197;
        if (r <= 817) return 238;
        if (r <= 981) return 240;
        if (r <= 1144) return 239;
        if (r <= 1308) return 173;
        if (r <= 1471) return 175;
        if (r <= 1635) return 174;
        if (r <= 1798) return 236;
        if (r <= 1962) return 172;
        if (r <= 2289) return 250;
        if (r <= 2616) return 249;
        if (r <= 2943) return 244;
        if (r <= 3270) return 243;
        if (r <= 3597) return 245;
        if (r <= 4087) return 145;
        if (r <= 4577) return 146;
        if (r <= 5068) return 144;
        if (r <= 5885) return 248;
        if (r <= 6703) return 149;
        if (r <= 7520) return 143;
        if (r <= 8337) return 112;
        if (r <= 9155) return 242;
        if (r <= 9972) return 212;
        if (r <= 10790) return 160;
        if (r <= 11607) return 6;
        if (r <= 12424) return 157;
        if (r <= 13242) return 131;
        if (r <= 14059) return 3;
        if (r <= 14877) return 233;
        if (r <= 15694) return 9;
        if (r <= 16511) return 154;
        if (r <= 17329) return 182;
        if (r <= 18146) return 176;
        if (r <= 19127) return 150;
        if (r <= 20762) return 130;
        if (r <= 22397) return 68;
        if (r <= 24031) return 65;
        if (r <= 25666) return 59;
        if (r <= 27301) return 94;
        if (r <= 28936) return 199;
        if (r <= 30571) return 169;
        if (r <= 32205) return 208;
        if (r <= 33840) return 230;
        if (r <= 35475) return 186;
        if (r <= 37110) return 36;
        if (r <= 38744) return 38;
        if (r <= 40379) return 192;
        if (r <= 42014) return 26;
        if (r <= 43649) return 237;
        if (r <= 45284) return 148;
        if (r <= 46918) return 247;
        if (r <= 48553) return 2;
        if (r <= 50188) return 5;
        if (r <= 51823) return 8;
        if (r <= 53785) return 134;
        if (r <= 55746) return 232;
        if (r <= 57708) return 76;
        if (r <= 59670) return 136;
        if (r <= 61632) return 135;
        if (r <= 63593) return 181;
        if (r <= 65555) return 62;
        if (r <= 67517) return 34;
        if (r <= 69479) return 31;
        if (r <= 71440) return 221;
        if (r <= 73402) return 71;
        if (r <= 75364) return 185;
        if (r <= 77325) return 18;
        if (r <= 79287) return 15;
        if (r <= 81249) return 12;
        if (r <= 83211) return 159;
        if (r <= 85172) return 189;
        if (r <= 87134) return 219;
        if (r <= 89096) return 156;
        if (r <= 91058) return 153;
        if (r <= 93510) return 217;
        if (r <= 95962) return 139;
        if (r <= 98414) return 229;
        if (r <= 100866) return 141;
        if (r <= 103319) return 210;
        if (r <= 105771) return 45;
        if (r <= 108223) return 205;
        if (r <= 110675) return 78;
        if (r <= 113127) return 224;
        if (r <= 115580) return 171;
        if (r <= 118032) return 164;
        if (r <= 120484) return 178;
        if (r <= 122936) return 195;
        if (r <= 125388) return 105;
        if (r <= 127840) return 162;
        if (r <= 130293) return 168;
        if (r <= 132745) return 184;
        if (r <= 135197) return 166;
        if (r <= 138467) return 103;
        if (r <= 141736) return 89;
        if (r <= 145006) return 99;
        if (r <= 148275) return 142;
        if (r <= 151545) return 80;
        if (r <= 154814) return 91;
        if (r <= 158084) return 115;
        if (r <= 161354) return 106;
        if (r <= 164623) return 73;
        if (r <= 167893) return 28;
        if (r <= 171162) return 241;
        if (r <= 174432) return 121;
        if (r <= 177701) return 55;
        if (r <= 180971) return 126;
        if (r <= 184241) return 82;
        if (r <= 187510) return 125;
        if (r <= 190780) return 110;
        if (r <= 194049) return 85;
        if (r <= 197319) return 57;
        if (r <= 200589) return 107;
        if (r <= 203858) return 97;
        if (r <= 207128) return 119;
        if (r <= 210397) return 227;
        if (r <= 213667) return 117;
        if (r <= 216936) return 49;
        if (r <= 220206) return 40;
        if (r <= 223476) return 101;
        if (r <= 226745) return 87;
        if (r <= 230015) return 215;
        if (r <= 233284) return 42;
        if (r <= 236554) return 22;
        if (r <= 239823) return 207;
        if (r <= 243093) return 24;
        if (r <= 246363) return 93;
        if (r <= 249632) return 47;
        if (r <= 252902) return 20;
        if (r <= 256171) return 53;
        if (r <= 259441) return 113;
        if (r <= 262710) return 198;
        if (r <= 265980) return 51;
        if (r <= 269250) return 108;
        if (r <= 272519) return 190;
        if (r <= 275789) return 158;
        if (r <= 279058) return 95;
        if (r <= 282328) return 1;
        if (r <= 285598) return 225;
        if (r <= 288867) return 4;
        if (r <= 292137) return 155;
        if (r <= 295406) return 7;
        if (r <= 298676) return 152;
        if (r <= 301945) return 25;
        if (r <= 305215) return 132;
        if (r <= 309302) return 67;
        if (r <= 313389) return 64;
        if (r <= 317476) return 75;
        if (r <= 321563) return 70;
        if (r <= 325650) return 180;
        if (r <= 329737) return 61;
        if (r <= 333824) return 33;
        if (r <= 337911) return 30;
        if (r <= 341998) return 17;
        if (r <= 346085) return 202;
        if (r <= 350172) return 188;
        if (r <= 354259) return 11;
        if (r <= 358346) return 14;
        if (r <= 362433) return 235;
        if (r <= 367337) return 214;
        if (r <= 372241) return 127;
        if (r <= 377146) return 124;
        if (r <= 382050) return 128;
        if (r <= 386954) return 123;
        if (r <= 391859) return 226;
        if (r <= 396763) return 234;
        if (r <= 401667) return 122;
        if (r <= 406572) return 211;
        if (r <= 411476) return 203;
        if (r <= 416381) return 200;
        if (r <= 421285) return 206;
        if (r <= 426189) return 44;
        if (r <= 431094) return 193;
        if (r <= 435998) return 222;
        if (r <= 440902) return 58;
        if (r <= 445807) return 83;
        if (r <= 450711) return 35;
        if (r <= 455615) return 201;
        if (r <= 460520) return 37;
        if (r <= 465424) return 218;
        if (r <= 470329) return 220;
        if (r <= 475233) return 213;
        if (r <= 481772) return 114;
        if (r <= 488311) return 137;
        if (r <= 494850) return 77;
        if (r <= 501390) return 138;
        if (r <= 507929) return 140;
        if (r <= 514468) return 209;
        if (r <= 521007) return 228;
        if (r <= 527546) return 170;
        if (r <= 534085) return 204;
        if (r <= 540624) return 92;
        if (r <= 547164) return 133;
        if (r <= 553703) return 104;
        if (r <= 560242) return 177;
        if (r <= 566781) return 246;
        if (r <= 573320) return 147;
        if (r <= 579859) return 46;
        if (r <= 586399) return 194;
        if (r <= 594573) return 111;
        if (r <= 602746) return 98;
        if (r <= 610920) return 88;
        if (r <= 619094) return 79;
        if (r <= 627268) return 66;
        if (r <= 635442) return 27;
        if (r <= 643616) return 74;
        if (r <= 651790) return 216;
        if (r <= 659964) return 231;
        if (r <= 668138) return 63;
        if (r <= 676312) return 102;
        if (r <= 684486) return 109;
        if (r <= 692660) return 81;
        if (r <= 700834) return 84;
        if (r <= 709008) return 118;
        if (r <= 717182) return 56;
        if (r <= 725356) return 96;
        if (r <= 733530) return 54;
        if (r <= 741703) return 90;
        if (r <= 749877) return 72;
        if (r <= 758051) return 120;
        if (r <= 766225) return 116;
        if (r <= 774399) return 69;
        if (r <= 782573) return 48;
        if (r <= 790747) return 86;
        if (r <= 798921) return 179;
        if (r <= 807095) return 100;
        if (r <= 815269) return 23;
        if (r <= 823443) return 223;
        if (r <= 831617) return 32;
        if (r <= 839791) return 29;
        if (r <= 847965) return 39;
        if (r <= 856139) return 60;
        if (r <= 864313) return 167;
        if (r <= 872487) return 21;
        if (r <= 880660) return 165;
        if (r <= 888834) return 163;
        if (r <= 897008) return 52;
        if (r <= 905182) return 19;
        if (r <= 913356) return 16;
        if (r <= 921530) return 41;
        if (r <= 929704) return 161;
        if (r <= 937878) return 187;
        if (r <= 946052) return 50;
        if (r <= 954226) return 183;
        if (r <= 962400) return 13;
        if (r <= 970574) return 10;
        if (r <= 978748) return 191;
        if (r <= 988556) return 43;
        if (r <= 1000000) return 129;

        return 129;
    }

    function getBaseStats(uint8 id) public pure returns (uint32 ra, uint32 rd, uint32 rs) {
        if (id == 151) return (210, 210, 200);
        if (id == 251) return (210, 210, 200);
        if (id == 196) return (261, 194, 130);
        if (id == 197) return (126, 250, 190);
        if (id == 238) return (153, 116, 90);
        if (id == 240) return (151, 108, 90);
        if (id == 239) return (135, 110, 90);
        if (id == 173) return (75, 91, 100);
        if (id == 175) return (67, 116, 70);
        if (id == 174) return (69, 34, 180);
        if (id == 236) return (64, 64, 70);
        if (id == 172) return (77, 63, 40);
        if (id == 250) return (239, 274, 193);
        if (id == 249) return (193, 323, 212);
        if (id == 244) return (235, 176, 230);
        if (id == 243) return (241, 210, 180);
        if (id == 245) return (180, 235, 200);
        if (id == 145) return (253, 188, 180);
        if (id == 146) return (251, 184, 180);
        if (id == 144) return (192, 249, 180);
        if (id == 248) return (251, 212, 200);
        if (id == 149) return (263, 201, 182);
        if (id == 143) return (190, 190, 320);
        if (id == 112) return (222, 206, 210);
        if (id == 242) return (129, 229, 510);
        if (id == 212) return (236, 191, 140);
        if (id == 160) return (205, 197, 170);
        if (id == 6) return (223, 176, 156);
        if (id == 157) return (223, 176, 156);
        if (id == 131) return (165, 180, 260);
        if (id == 3) return (198, 198, 160);
        if (id == 233) return (198, 183, 170);
        if (id == 9) return (171, 210, 158);
        if (id == 154) return (168, 202, 160);
        if (id == 182) return (169, 189, 150);
        if (id == 176) return (139, 191, 110);
        if (id == 150) return (300, 182, 193);
        if (id == 130) return (237, 197, 190);
        if (id == 68) return (234, 162, 180);
        if (id == 65) return (271, 194, 110);
        if (id == 59) return (227, 166, 180);
        if (id == 94) return (261, 156, 120);
        if (id == 199) return (177, 194, 190);
        if (id == 169) return (194, 178, 170);
        if (id == 208) return (148, 333, 150);
        if (id == 230) return (194, 194, 150);
        if (id == 186) return (174, 192, 180);
        if (id == 36) return (178, 171, 190);
        if (id == 38) return (169, 204, 146);
        if (id == 192) return (185, 148, 150);
        if (id == 26) return (193, 165, 120);
        if (id == 237) return (173, 214, 100);
        if (id == 148) return (163, 138, 122);
        if (id == 247) return (155, 133, 140);
        if (id == 2) return (151, 151, 120);
        if (id == 5) return (158, 129, 116);
        if (id == 8) return (126, 155, 118);
        if (id == 134) return (205, 177, 260);
        if (id == 232) return (214, 214, 180);
        if (id == 76) return (211, 229, 160);
        if (id == 136) return (246, 204, 130);
        if (id == 135) return (232, 201, 130);
        if (id == 181) return (211, 172, 180);
        if (id == 62) return (182, 187, 180);
        if (id == 34) return (204, 157, 162);
        if (id == 31) return (180, 174, 180);
        if (id == 221) return (181, 147, 200);
        if (id == 71) return (207, 138, 160);
        if (id == 185) return (167, 198, 140);
        if (id == 18) return (166, 157, 166);
        if (id == 15) return (169, 150, 130);
        if (id == 12) return (167, 151, 120);
        if (id == 159) return (150, 151, 130);
        if (id == 189) return (118, 197, 150);
        if (id == 219) return (139, 209, 100);
        if (id == 156) return (158, 129, 116);
        if (id == 153) return (122, 155, 120);
        if (id == 217) return (236, 144, 180);
        if (id == 139) return (207, 227, 140);
        if (id == 229) return (224, 159, 150);
        if (id == 141) return (220, 203, 120);
        if (id == 210) return (212, 137, 180);
        if (id == 45) return (202, 170, 150);
        if (id == 205) return (161, 242, 150);
        if (id == 78) return (207, 167, 130);
        if (id == 224) return (197, 141, 150);
        if (id == 171) return (146, 146, 250);
        if (id == 164) return (145, 179, 200);
        if (id == 178) return (192, 146, 130);
        if (id == 195) return (152, 152, 190);
        if (id == 105) return (144, 200, 120);
        if (id == 162) return (148, 130, 170);
        if (id == 168) return (161, 128, 140);
        if (id == 184) return (112, 152, 200);
        if (id == 166) return (107, 209, 110);
        if (id == 103) return (233, 158, 190);
        if (id == 89) return (190, 184, 210);
        if (id == 99) return (240, 214, 110);
        if (id == 142) return (221, 164, 160);
        if (id == 80) return (177, 194, 190);
        if (id == 91) return (186, 323, 100);
        if (id == 115) return (181, 165, 210);
        if (id == 106) return (224, 211, 100);
        if (id == 73) return (166, 237, 160);
        if (id == 28) return (182, 202, 150);
        if (id == 241) return (157, 211, 190);
        if (id == 121) return (210, 184, 120);
        if (id == 55) return (191, 163, 160);
        if (id == 126) return (206, 169, 130);
        if (id == 82) return (223, 182, 100);
        if (id == 125) return (198, 173, 130);
        if (id == 110) return (174, 221, 130);
        if (id == 85) return (218, 145, 120);
        if (id == 57) return (207, 144, 130);
        if (id == 107) return (193, 212, 100);
        if (id == 97) return (144, 215, 170);
        if (id == 119) return (175, 154, 160);
        if (id == 227) return (148, 260, 130);
        if (id == 117) return (187, 182, 110);
        if (id == 49) return (179, 150, 140);
        if (id == 40) return (156, 93, 280);
        if (id == 101) return (173, 179, 120);
        if (id == 87) return (139, 184, 180);
        if (id == 215) return (189, 157, 110);
        if (id == 42) return (161, 153, 150);
        if (id == 22) return (182, 135, 130);
        if (id == 207) return (143, 204, 130);
        if (id == 24) return (167, 158, 120);
        if (id == 93) return (223, 112, 90);
        if (id == 47) return (165, 146, 120);
        if (id == 20) return (161, 144, 110);
        if (id == 53) return (150, 139, 130);
        if (id == 113) return (60, 176, 500);
        if (id == 198) return (175, 87, 120);
        if (id == 51) return (167, 147, 70);
        if (id == 108) return (108, 137, 180);
        if (id == 190) return (136, 112, 110);
        if (id == 158) return (117, 116, 100);
        if (id == 95) return (85, 288, 70);
        if (id == 1) return (118, 118, 90);
        if (id == 225) return (128, 90, 90);
        if (id == 4) return (116, 96, 78);
        if (id == 155) return (116, 96, 78);
        if (id == 7) return (94, 122, 88);
        if (id == 152) return (92, 122, 90);
        if (id == 25) return (112, 101, 70);
        if (id == 132) return (91, 91, 96);
        if (id == 67) return (177, 130, 160);
        if (id == 64) return (232, 138, 80);
        if (id == 75) return (164, 196, 110);
        if (id == 70) return (172, 95, 130);
        if (id == 180) return (145, 112, 140);
        if (id == 61) return (130, 130, 130);
        if (id == 33) return (137, 112, 122);
        if (id == 30) return (117, 126, 140);
        if (id == 17) return (117, 108, 126);
        if (id == 202) return (60, 106, 380);
        if (id == 188) return (91, 127, 110);
        if (id == 11) return (45, 94, 100);
        if (id == 14) return (46, 86, 90);
        if (id == 235) return (40, 88, 110);
        if (id == 214) return (234, 189, 160);
        if (id == 127) return (238, 197, 130);
        if (id == 124) return (223, 182, 130);
        if (id == 128) return (198, 197, 150);
        if (id == 123) return (218, 170, 140);
        if (id == 226) return (148, 260, 130);
        if (id == 234) return (192, 132, 146);
        if (id == 122) return (192, 233, 80);
        if (id == 211) return (184, 148, 130);
        if (id == 203) return (182, 133, 140);
        if (id == 200) return (167, 167, 120);
        if (id == 206) return (131, 131, 200);
        if (id == 44) return (153, 139, 120);
        if (id == 193) return (154, 94, 130);
        if (id == 222) return (118, 156, 110);
        if (id == 58) return (136, 96, 110);
        if (id == 83) return (124, 118, 104);
        if (id == 35) return (107, 116, 140);
        if (id == 201) return (136, 91, 96);
        if (id == 37) return (96, 122, 76);
        if (id == 218) return (118, 71, 80);
        if (id == 220) return (90, 74, 100);
        if (id == 213) return (17, 396, 40);
        if (id == 114) return (183, 205, 130);
        if (id == 137) return (153, 139, 130);
        if (id == 77) return (170, 132, 100);
        if (id == 138) return (155, 174, 70);
        if (id == 140) return (148, 162, 60);
        if (id == 209) return (137, 89, 120);
        if (id == 228) return (152, 93, 90);
        if (id == 170) return (106, 106, 150);
        if (id == 204) return (108, 146, 100);
        if (id == 92) return (186, 70, 60);
        if (id == 133) return (104, 121, 110);
        if (id == 104) return (90, 165, 100);
        if (id == 177) return (134, 89, 80);
        if (id == 246) return (115, 93, 100);
        if (id == 147) return (119, 94, 82);
        if (id == 46) return (121, 99, 70);
        if (id == 194) return (75, 75, 110);
        if (id == 111) return (140, 157, 160);
        if (id == 98) return (181, 156, 60);
        if (id == 88) return (135, 90, 160);
        if (id == 79) return (109, 109, 180);
        if (id == 66) return (137, 88, 140);
        if (id == 27) return (126, 145, 100);
        if (id == 74) return (132, 163, 80);
        if (id == 216) return (142, 93, 120);
        if (id == 231) return (107, 107, 180);
        if (id == 63) return (195, 103, 50);
        if (id == 102) return (107, 140, 120);
        if (id == 109) return (119, 164, 80);
        if (id == 81) return (165, 128, 50);
        if (id == 84) return (158, 88, 70);
        if (id == 118) return (123, 115, 90);
        if (id == 56) return (148, 87, 80);
        if (id == 96) return (89, 158, 120);
        if (id == 54) return (122, 96, 100);
        if (id == 90) return (116, 168, 60);
        if (id == 72) return (97, 182, 80);
        if (id == 120) return (137, 112, 60);
        if (id == 116) return (129, 125, 60);
        if (id == 69) return (139, 64, 100);
        if (id == 48) return (100, 102, 120);
        if (id == 86) return (85, 128, 130);
        if (id == 179) return (114, 82, 110);
        if (id == 100) return (109, 114, 80);
        if (id == 23) return (110, 102, 70);
        if (id == 223) return (127, 69, 70);
        if (id == 32) return (105, 76, 92);
        if (id == 29) return (86, 94, 110);
        if (id == 39) return (80, 44, 230);
        if (id == 60) return (101, 82, 80);
        if (id == 167) return (105, 73, 80);
        if (id == 21) return (112, 61, 80);
        if (id == 165) return (72, 142, 80);
        if (id == 163) return (67, 101, 120);
        if (id == 52) return (92, 81, 80);
        if (id == 19) return (103, 70, 60);
        if (id == 16) return (85, 76, 80);
        if (id == 41) return (83, 76, 80);
        if (id == 161) return (79, 77, 70);
        if (id == 187) return (67, 101, 70);
        if (id == 50) return (109, 88, 20);
        if (id == 183) return (37, 93, 140);
        if (id == 13) return (63, 55, 80);
        if (id == 10) return (55, 62, 90);
        if (id == 191) return (55, 55, 60);
        if (id == 43) return (131, 116, 90);
        if (id == 129) return (29, 102, 40);
        return (0, 0, 0);

    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function maxCP(uint256 genes, uint16 generation) public pure returns (uint32 max_cp) {
        var code = uint8(genes & 0xFF);
        var a = uint32((genes >> 8) & 0xFF);
        var d = uint32((genes >> 16) & 0xFF);
        var s = uint32((genes >> 24) & 0xFF);
//      var gender = uint32((genes >> 32) & 0x1);
        var bgColor = uint8((genes >> 33) & 0xFF);
        var (ra, rd, rs) = getBaseStats(code);


        max_cp = uint32(sqrt(uint256(ra + a) * uint256(ra + a) * uint256(rd + d) * uint256(rs + s) * 3900927938993281/10000000000000000 / 100));
        if(max_cp < 10)
            max_cp = 10;

        if(generation < 10)
            max_cp += (10 - generation) * 50;

        // bgColor
        if(bgColor >= 8)
            bgColor = 0;

        max_cp += bgColor * 25;
        return max_cp;
    }

    function getCode(uint256 genes) pure public returns (uint8) {
        return uint8(genes & 0xFF);
    }

    function getAttack(uint256 genes) pure public returns (uint8) {
        return uint8((genes >> 8) & 0xFF);
    }

    function getDefense(uint256 genes) pure public returns (uint8) {
        return uint8((genes >> 16) & 0xFF);
    }

    function getStamina(uint256 genes) pure public returns (uint8) {
        return uint8((genes >> 24) & 0xFF);
    }

    /// @dev given genes of kitten 1 & 2, return a genetic combination - may have a random factor
    /// @param genes1 genes of mom
    /// @param genes2 genes of sire
    /// @return the genes that are supposed to be passed down the child
    function mixGenes(uint256 genes1, uint256 genes2, uint256 targetBlock) public returns (uint256) {

        uint8 code;
        var r = random(10);

        // 20% percent of parents DNA
        if(r == 0)
            code = getCode(genes1);
        else if(r == 1)
            code = getCode(genes2);
        else
            code = randomCode();

        // 70% percent of parents DNA
        var attack = random(3) == 0 ? uint8(random(32)) : uint8(randomBetween(getAttack(genes1), getAttack(genes2)));
        var defense = random(3) == 0 ? uint8(random(32)) : uint8(randomBetween(getDefense(genes1), getDefense(genes2)));
        var stamina = random(3) == 0 ? uint8(random(32)) : uint8(randomBetween(getStamina(genes1), getStamina(genes2)));
        var gender = uint8(random(2));
        var bgColor = uint8(random(8));
        var rand = random(~uint64(0));

        return uint256(code) // 8
        | (uint256(attack) << 8) // 8
        | (uint256(defense) << 16) // 8
        | (uint256(stamina) << 24) // 8
        | (uint256(gender) << 32) // 1
        | (uint256(bgColor) << 33) // 8
        | (uint256(rand) << 41) // 64
        ;
    }

    function randomGenes() public returns (uint256) {
        var code = randomCode();
        var attack = uint8(random(32));
        var defense = uint8(random(32));
        var stamina = uint8(random(32));
        var gender = uint8(random(2));
        var bgColor = uint8(random(8));
        var rand = random(~uint64(0));

        return uint256(code) // 8
        | (uint256(attack) << 8) // 8
        | (uint256(defense) << 16) // 8
        | (uint256(stamina) << 24) // 8
        | (uint256(gender) << 32) // 1
        | (uint256(bgColor) << 33) // 8
        | (uint256(rand) << 41) // 64
        ;
    }
}

/// @title Clock auction modified for sale of monsters
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract SaleClockAuction is ClockAuction {

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setSaleAuctionAddress() call.
    bool public isSaleClockAuction = true;

    // Tracks last 5 sale price of gen0 monster sales
    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;

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

    /// @dev Updates lastSalePrice if seller is the nft contract
    /// Otherwise, works the same as default bid method.
    function bid(uint256 _tokenId)
    external
    payable
    {
        // _bid verifies token ID size
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

        // If not a gen0 auction, exit
        if (seller == address(nonFungibleContract)) {
            // Track gen0 sale prices
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }

}

/// @title Reverse auction modified for siring
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract SiringClockAuction is ClockAuction {

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setSiringAuctionAddress() call.
    bool public isSiringClockAuction = true;

    // Delegate constructor
    function SiringClockAuction(address _nftAddr, uint256 _cut) public
    ClockAuction(_nftAddr, _cut) {}

    /// @dev Creates and begins a new auction. Since this function is wrapped,
    /// require sender to be MonsterCore contract.
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

    /// @dev Places a bid for siring. Requires the sender
    /// is the MonsterCore contract because all bid methods
    /// should be wrapped. Also returns the monster to the
    /// seller rather than the winner.
    function bid(uint256 _tokenId)
    external
    payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        // _bid checks that token ID is valid and will throw if bid fails
        _bid(_tokenId, msg.value);
        // We transfer the monster back to the seller, the winner will get
        // the offspring
        _transfer(seller, _tokenId);
    }

}







/// @title A facet of MonsterCore that manages special access privileges.
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev See the MonsterCore contract documentation to understand how the various contract facets are arranged.
contract MonsterAccessControl {
    // This facet controls access control for CryptoMonsters. There are four roles managed here:
    //
    //     - The CEO: The CEO can reassign other roles and change the addresses of our dependent smart
    //         contracts. It is also the only role that can unpause the smart contract. It is initially
    //         set to the address that created the smart contract in the MonsterCore constructor.
    //
    //     - The CFO: The CFO can withdraw funds from MonsterCore and its auction contracts.
    //
    //     - The COO: The COO can release gen0 monsters to auction, and mint promo monsters.
    //
    // It should be noted that these roles are distinct without overlap in their access abilities, the
    // abilities listed for each role above are exhaustive. In particular, while the CEO can assign any
    // address to any role, the CEO address itself doesn't have the ability to act in those roles. This
    // restriction is intentional so that we aren't tempted to use the CEO address frequently out of
    // convenience. The less we use an address, the less likely it is that we somehow compromise the
    // account.

    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
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
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}




/// @title Base contract for CryptoMonsters. Holds all common structs, events and base variables.
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev See the MonsterCore contract documentation to understand how the various contract facets are arranged.
contract MonsterBase is MonsterAccessControl {
    /*** EVENTS ***/

    /// @dev The Birth event is fired whenever a new monster comes into existence. This obviously
    ///  includes any time a monster is created through the giveBirth method, but it is also called
    ///  when a new gen0 monster is created.
    event Birth(address owner, uint256 monsterId, uint256 matronId, uint256 sireId, uint256 genes, uint16 generation);

    /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a monster
    ///  ownership is assigned, including births.
    event Transfer(address from, address to, uint256 tokenId);

    /*** DATA TYPES ***/

    /// @dev The main Monster struct. Every monster in CryptoMonsters is represented by a copy
    ///  of this structure, so great care was taken to ensure that it fits neatly into
    ///  exactly two 256-bit words. Note that the order of the members in this structure
    ///  is important because of the byte-packing rules used by Ethereum.
    ///  Ref: http://solidity.readthedocs.io/en/develop/miscellaneous.html
    struct Monster {
        // The Monster's genetic code is packed into these 256-bits, the format is
        // sooper-sekret! A monster's genes never change.
        uint256 genes;

        // The timestamp from the block when this monster came into existence.
        uint64 birthTime;

        // The minimum timestamp after which this monster can engage in breeding
        // activities again. This same timestamp is used for the pregnancy
        // timer (for matrons) as well as the siring cooldown.
        uint64 cooldownEndBlock;

        // The ID of the parents of this monster, set to 0 for gen0 monsters.
        // Note that using 32-bit unsigned integers limits us to a "mere"
        // 4 billion monsters. This number might seem small until you realize
        // that Ethereum currently has a limit of about 500 million
        // transactions per year! So, this definitely won't be a problem
        // for several years (even as Ethereum learns to scale).
        uint32 matronId;
        uint32 sireId;

        // Set to the ID of the sire monster for matrons that are pregnant,
        // zero otherwise. A non-zero value here is how we know a monster
        // is pregnant. Used to retrieve the genetic material for the new
        // monster when the birth transpires.
        uint32 siringWithId;

        // Set to the index in the cooldown array (see below) that represents
        // the current cooldown duration for this Monster. This starts at zero
        // for gen0 monsters, and is initialized to floor(generation/2) for others.
        // Incremented by one for each successful breeding action, regardless
        // of whether this monster is acting as matron or sire.
        uint16 cooldownIndex;

        // The "generation number" of this monster. Monsters minted by the CK contract
        // for sale are called "gen0" and have a generation number of 0. The
        // generation number of all other monsters is the larger of the two generation
        // numbers of their parents, plus one.
        // (i.e. max(matron.generation, sire.generation) + 1)
        uint16 generation;
    }

    /*** CONSTANTS ***/

    /// @dev A lookup table indimonstering the cooldown duration after any successful
    ///  breeding action, called "pregnancy time" for matrons and "siring cooldown"
    ///  for sires. Designed such that the cooldown roughly doubles each time a monster
    ///  is bred, encouraging owners not to just keep breeding the same monster over
    ///  and over again. Caps out at one week (a monster can breed an unbounded number
    ///  of times, and the maximum cooldown is always seven days).
    uint32[14] public cooldowns = [
    uint32(1 minutes),
    uint32(2 minutes),
    uint32(5 minutes),
    uint32(10 minutes),
    uint32(30 minutes),
    uint32(1 hours),
    uint32(2 hours),
    uint32(4 hours),
    uint32(8 hours),
    uint32(16 hours),
    uint32(1 days),
    uint32(2 days),
    uint32(4 days),
    uint32(7 days)
    ];

    // An approximation of currently how many seconds are in between blocks.
    uint256 public secondsPerBlock = 15;

    /*** STORAGE ***/

    /// @dev An array containing the Monster struct for all Monsters in existence. The ID
    ///  of each monster is actually an index into this array. Note that ID 0 is a negamonster,
    ///  the unMonster, the mythical beast that is the parent of all gen0 monsters. A bizarre
    ///  creature that is both matron and sire... to itself! Has an invalid genetic code.
    ///  In other words, monster ID 0 is invalid... ;-)
    Monster[] monsters;

    /// @dev A mapping from monster IDs to the address that owns them. All monsters have
    ///  some valid owner address, even gen0 monsters are created with a non-zero owner.
    mapping(uint256 => address) public monsterIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping(address => uint256) ownershipTokenCount;

    /// @dev A mapping from MonsterIDs to an address that has been approved to call
    ///  transferFrom(). Each Monster can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping(uint256 => address) public monsterIndexToApproved;

    /// @dev A mapping from MonsterIDs to an address that has been approved to use
    ///  this Monster for siring via breedWith(). Each Monster can only have one approved
    ///  address for siring at any time. A zero value means no approval is outstanding.
    mapping(uint256 => address) public sireAllowedToAddress;

    /// @dev The address of the ClockAuction contract that handles sales of Monsters. This
    ///  same contract handles both peer-to-peer sales as well as the gen0 sales which are
    ///  initiated every 15 minutes.
    SaleClockAuction public saleAuction;

    /// @dev The address of a custom ClockAuction subclassed contract that handles siring
    ///  auctions. Needs to be separate from saleAuction because the actions taken on success
    ///  after a sales and siring auction are quite different.
    SiringClockAuction public siringAuction;

    GeneScience public geneScience;

    /// @dev Assigns ownership of a specific Monster to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Since the number of monsters is capped to 2^32 we can't overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        monsterIndexToOwner[_tokenId] = _to;

        // When creating new monsters _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // once the monster is transferred also clear sire allowances
            delete sireAllowedToAddress[_tokenId];
            // clear any previously approved ownership exchange
            delete monsterIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    /// @dev An internal method that creates a new monster and stores it. This
    ///  method doesn't do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Birth event
    ///  and a Transfer event.
    /// @param _matronId The monster ID of the matron of this monster (zero for gen0)
    /// @param _sireId The monster ID of the sire of this monster (zero for gen0)
    /// @param _generation The generation number of this monster, must be computed by caller.
    /// @param _genes The monster's genetic code.
    /// @param _owner The inital owner of this monster, must be non-zero (except for the unMonster, ID 0)
    function _createMonster(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
    internal
    returns (uint)
    {
        // These requires are not strictly necessary, our calling code should make
        // sure that these conditions are never broken. However! _createMonster() is already
        // an expensive call (for storage), and it doesn't hurt to be especially careful
        // to ensure our data structures are always valid.
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));

        // New monster starts with the same cooldown as parent gen/2
        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Monster memory _monster = Monster({
            genes : _genes,
            birthTime : uint64(now),
            cooldownEndBlock : 0,
            matronId : uint32(_matronId),
            sireId : uint32(_sireId),
            siringWithId : 0,
            cooldownIndex : cooldownIndex,
            generation : uint16(_generation)
            });
        uint256 newKittenId = monsters.push(_monster) - 1;

        // It's probably never going to happen, 4 billion monsters is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(newKittenId == uint256(uint32(newKittenId)));

        // emit the birth event
        Birth(
            _owner,
            newKittenId,
            uint256(_monster.matronId),
            uint256(_monster.sireId),
            _monster.genes,
            uint16(_generation)
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newKittenId);

        return newKittenId;
    }

    // Any C-level can fix how many seconds per blocks are currently observed.
    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}





/// @title The external contract that is responsible for generating metadata for the monsters,
///  it has one function that will return the data as bytes.
contract ERC721Metadata {
    /// @dev Given a token Id, returns a byte array that is supposed to be converted into string.
    function getMetadata(uint256 _tokenId, string) public view returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}


/// @title The facet of the CryptoMonsters core contract that manages ownership, ERC-721 (draft) compliant.
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev Ref: https://github.com/ethereum/EIPs/issues/721
///  See the MonsterCore contract documentation to understand how the various contract facets are arranged.
contract MonsterOwnership is MonsterBase, ERC721 {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "Ethermon";
    string public constant symbol = "EM";

    // The contract that will return monster metadata
    ERC721Metadata public erc721Metadata;

    bytes4 constant InterfaceSignature_ERC165 =
    bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('tokensOfOwner(address)')) ^
    bytes4(keccak256('tokenMetadata(uint256,string)'));

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    /// @dev Set the address of the sibling contract that tracks metadata.
    ///  CEO only.
    function setMetadataAddress(address _contractAddress) public onlyCEO {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.

    /// @dev Checks if a given address is the current owner of a particular Monster.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId monster id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return monsterIndexToOwner[_tokenId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Monster.
    /// @param _claimant the address we are confirming monster is approved for.
    /// @param _tokenId monster id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return monsterIndexToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting Monsters on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        monsterIndexToApproved[_tokenId] = _approved;
    }

    /// @notice Returns the number of Monsters owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @notice Transfers a Monster to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  CryptoMonsters specifically) or your Monster may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Monster to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any monsters (except very briefly
        // after a gen0 monster is created and before it goes on auction).
        require(_to != address(this));
        // Disallow transfers to the auction contracts to prevent accidental
        // misuse. Auction contracts should only take ownership of monsters
        // through the allow + transferFrom flow.
        require(_to != address(saleAuction));
        require(_to != address(siringAuction));

        // You can only send your own monster.
        require(_owns(msg.sender, _tokenId));

            // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific Monster via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Monster that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a Monster owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Monster to be transfered.
    /// @param _to The address that should take ownership of the Monster. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Monster to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any monsters (except very briefly
        // after a gen0 monster is created and before it goes on auction).
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of Monsters currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return monsters.length - 1;
    }

    /// @notice Returns the address currently assigned ownership of a given Monster.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
    external
    view
    returns (address owner)
    {
        owner = monsterIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /// @notice Returns a list of all Monster IDs assigned to an address.
    /// @param _owner The owner whose Monsters we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire Monster array looking for monsters belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns (uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalMonsters = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all monsters have IDs starting at 1 and increasing
            // sequentially up to the totalMonster count.
            uint256 monsterId;

            for (monsterId = 1; monsterId <= totalMonsters; monsterId++) {
                if (monsterIndexToOwner[monsterId] == _owner) {
                    result[resultIndex] = monsterId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @dev Adapted from memcpy() by @arachnid (Nick Johnson <arachnid@notdot.net>)
    ///  This method is licenced under the Apache License.
    ///  Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
    function _memcpy(uint _dest, uint _src, uint _len) private view {
        // Copy word-length chunks while possible
        for (; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

    /// @dev Adapted from toString(slice) by @arachnid (Nick Johnson <arachnid@notdot.net>)
    ///  This method is licenced under the Apache License.
    ///  Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private view returns (string) {
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

    /// @notice Returns a URI pointing to a metadata package for this token conforming to
    ///  ERC-721 (https://github.com/ethereum/EIPs/issues/721)
    /// @param _tokenId The ID number of the Monster whose metadata should be returned.
    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
    }
}



/// @title A facet of MonsterCore that manages Monster siring, gestation, and birth.
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev See the MonsterCore contract documentation to understand how the various contract facets are arranged.
contract MonsterBreeding is MonsterOwnership {

    /// @dev The Pregnant event is fired when two monsters successfully breed and the pregnancy
    ///  timer begins for the matron.
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 cooldownEndBlock);

    /// @notice The minimum payment required to use breedWithAuto(). This fee goes towards
    ///  the gas cost paid by whatever calls giveBirth(), and can be dynamically updated by
    ///  the COO role as the gas price changes.
    uint256 public autoBirthFee = 8 finney;

    // Keeps track of number of pregnant monsters.
    uint256 public pregnantMonsters;

    /// @dev The address of the sibling contract that is used to implement the sooper-sekret
    ///  genetic combination algorithm.

    /// @dev Update the address of the genetic contract, can only be called by the CEO.
    /// @param _address An address of a GeneScience contract instance to be used from this point forward.
    function setGeneScienceAddress(address _address) external onlyCEO {
        GeneScience candidateContract = GeneScience(_address);

        require(candidateContract.isGeneScience());

        // Set the new contract address
        geneScience = candidateContract;
    }

    /// @dev Checks that a given monster is able to breed. Requires that the
    ///  current cooldown is finished (for sires) and also checks that there is
    ///  no pending pregnancy.
    function _isReadyToBreed(Monster _monster) internal view returns (bool) {
        // In addition to checking the cooldownEndBlock, we also need to check to see if
        // the monster has a pending birth; there can be some period of time between the end
        // of the pregnacy timer and the birth event.
        return (_monster.siringWithId == 0) && (_monster.cooldownEndBlock <= uint64(block.number));
    }

    /// @dev Check if a sire has authorized breeding with this matron. True if both sire
    ///  and matron have the same owner, or if the sire has given siring permission to
    ///  the matron's owner (via approveSiring()).
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
        address matronOwner = monsterIndexToOwner[_matronId];
        address sireOwner = monsterIndexToOwner[_sireId];

        // Siring is okay if they have same owner, or if the matron's owner was given
        // permission to breed with this sire.
        return (matronOwner == sireOwner || sireAllowedToAddress[_sireId] == matronOwner);
    }

    /// @dev Set the cooldownEndTime for the given Monster, based on its current cooldownIndex.
    ///  Also increments the cooldownIndex (unless it has hit the cap).
    /// @param _monster A reference to the Monster in storage which needs its timer started.
    function _triggerCooldown(Monster storage _monster) internal {
        // Compute an estimation of the cooldown time in blocks (based on current cooldownIndex).
        _monster.cooldownEndBlock = uint64((cooldowns[_monster.cooldownIndex] / secondsPerBlock) + block.number);

        // Increment the breeding count, clamping it at 13, which is the length of the
        // cooldowns array. We could check the array size dynamically, but hard-coding
        // this as a constant saves gas. Yay, Solidity!
        if (_monster.cooldownIndex < 13) {
            _monster.cooldownIndex += 1;
        }
    }

    /// @notice Grants approval to another user to sire with one of your Monsters.
    /// @param _addr The address that will be able to sire with your Monster. Set to
    ///  address(0) to clear all siring approvals for this Monster.
    /// @param _sireId A Monster that you own that _addr will now be able to sire with.
    /// KERNYS 외부에서 아빠가 호출할 수 있다. (meta mask로)
    function approveSiring(address _addr, uint256 _sireId)
    external
    whenNotPaused
    {
        require(_owns(msg.sender, _sireId));
        sireAllowedToAddress[_sireId] = _addr;
    }

    /// @dev Updates the minimum payment required for calling giveBirthAuto(). Can only
    ///  be called by the COO address. (This fee is used to offset the gas cost incurred
    ///  by the autobirth daemon).
    function setAutoBirthFee(uint256 val) external onlyCOO {
        autoBirthFee = val;
    }

    /// @dev Checks to see if a given Monster is pregnant and (if so) if the gestation
    ///  period has passed.
    function _isReadyToGiveBirth(Monster _matron) private view returns (bool) {
        return (_matron.siringWithId != 0) && (_matron.cooldownEndBlock <= uint64(block.number));
    }

    /// @notice Checks that a given monster is able to breed (i.e. it is not pregnant or
    ///  in the middle of a siring cooldown).
    /// @param _monsterId reference the id of the monster, any user can inquire about it
    function isReadyToBreed(uint256 _monsterId)
    public
    view
    returns (bool)
    {
        require(_monsterId > 0);
        Monster storage monster = monsters[_monsterId];
        return _isReadyToBreed(monster);
    }

    /// @dev Checks whether a monster is currently pregnant.
    /// @param _monsterId reference the id of the monster, any user can inquire about it
    function isPregnant(uint256 _monsterId)
    public
    view
    returns (bool)
    {
        require(_monsterId > 0);
        // A monster is pregnant if and only if this field is set
        return monsters[_monsterId].siringWithId != 0;
    }

    /// @dev Internal check to see if a given sire and matron are a valid mating pair. DOES NOT
    ///  check ownership permissions (that is up to the caller).
    /// @param _matron A reference to the Monster struct of the potential matron.
    /// @param _matronId The matron's ID.
    /// @param _sire A reference to the Monster struct of the potential sire.
    /// @param _sireId The sire's ID
    function _isValidMatingPair(
        Monster storage _matron,
        uint256 _matronId,
        Monster storage _sire,
        uint256 _sireId
    )
    private
    view
    returns (bool)
    {
        // A Monster can't breed with itself!
        if (_matronId == _sireId) {
            return false;
        }

        // Monsters can't breed with their parents.
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        // We can short circuit the sibling check (below) if either monster is
        // gen zero (has a matron ID of zero).
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        // Monsters can't breed with full or half siblings.
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        // Everything seems cool! Let's get DTF.
        return true;
    }

    /// @dev Internal check to see if a given sire and matron are a valid mating pair for
    ///  breeding via auction (i.e. skips ownership and siring approval checks).
    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
    internal
    view
    returns (bool)
    {
        Monster storage matron = monsters[_matronId];
        Monster storage sire = monsters[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

    /// @notice Checks to see if two monsters can breed together, including checks for
    ///  ownership and siring approvals. Does NOT check that both monsters are ready for
    ///  breeding (i.e. breedWith could still fail until the cooldowns are finished).
    ///  TODO: Shouldn't this check pregnancy and cooldowns?!?
    /// @param _matronId The ID of the proposed matron.
    /// @param _sireId The ID of the proposed sire.
    function canBreedWith(uint256 _matronId, uint256 _sireId)
    external
    view
    returns (bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        Monster storage matron = monsters[_matronId];
        Monster storage sire = monsters[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
        _isSiringPermitted(_sireId, _matronId);
    }

    /// @dev Internal utility function to initiate breeding, assumes that all breeding
    ///  requirements have been checked.
    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
        // Grab a reference to the Monsters from storage.
        Monster storage sire = monsters[_sireId];
        Monster storage matron = monsters[_matronId];

        // Mark the matron as pregnant, keeping track of who the sire is.
        matron.siringWithId = uint32(_sireId);

        // Trigger the cooldown for both parents.
        _triggerCooldown(sire);
        _triggerCooldown(matron);

        // Clear siring permission for both parents. This may not be strictly necessary
        // but it's likely to avoid confusion!
        delete sireAllowedToAddress[_matronId];
        delete sireAllowedToAddress[_sireId];

        // Every time a monster gets pregnant, counter is incremented.
        pregnantMonsters++;

        // Emit the pregnancy event.
        Pregnant(monsterIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndBlock);
    }

    /// @notice Breed a Monster you own (as matron) with a sire that you own, or for which you
    ///  have previously been given Siring approval. Will either make your monster pregnant, or will
    ///  fail entirely. Requires a pre-payment of the fee given out to the first caller of giveBirth()
    /// @param _matronId The ID of the Monster acting as matron (will end up pregnant if successful)
    /// @param _sireId The ID of the Monster acting as sire (will begin its siring cooldown if successful)
    function breedWithAuto(uint256 _matronId, uint256 _sireId)
    external
    payable
    whenNotPaused
    {
        // Checks for payment.
        require(msg.value >= autoBirthFee);

        // Caller must own the matron.
        require(_owns(msg.sender, _matronId));

        // Neither sire nor matron are allowed to be on auction during a normal
        // breeding operation, but we don't need to check that explicitly.
        // For matron: The caller of this function can't be the owner of the matron
        //   because the owner of a Monster on auction is the auction house, and the
        //   auction house will never call breedWith().
        // For sire: Similarly, a sire on auction will be owned by the auction house
        //   and the act of transferring ownership will have cleared any oustanding
        //   siring approval.
        // Thus we don't need to spend gas explicitly checking to see if either monster
        // is on auction.

        // Check that matron and sire are both owned by caller, or that the sire
        // has given siring permission to caller (i.e. matron's owner).
        // Will fail for _sireId = 0
        require(_isSiringPermitted(_sireId, _matronId));

        // Grab a reference to the potential matron
        Monster storage matron = monsters[_matronId];

        // Make sure matron isn't pregnant, or in the middle of a siring cooldown
        require(_isReadyToBreed(matron));

        // Grab a reference to the potential sire
        Monster storage sire = monsters[_sireId];

        // Make sure sire isn't pregnant, or in the middle of a siring cooldown
        require(_isReadyToBreed(sire));

        // Test that these monsters are a valid mating pair.
        require(_isValidMatingPair(
                matron,
                _matronId,
                sire,
                _sireId
            ));

        // All checks passed, monster gets pregnant!
        _breedWith(_matronId, _sireId);
    }

    /// @notice Have a pregnant Monster give birth!
    /// @param _matronId A Monster ready to give birth.
    /// @return The Monster ID of the new monster.
    /// @dev Looks at a given Monster and, if pregnant and if the gestation period has passed,
    ///  combines the genes of the two parents to create a new monster. The new Monster is assigned
    ///  to the current owner of the matron. Upon successful completion, both the matron and the
    ///  new monster will be ready to breed again. Note that anyone can call this function (if they
    ///  are willing to pay the gas!), but the new monster always goes to the mother's owner.
    function giveBirth(uint256 _matronId)
    external
    onlyCOO
    whenNotPaused
    returns (uint256)
    {
        // Grab a reference to the matron in storage.
        Monster storage matron = monsters[_matronId];

        // Check that the matron is a valid monster.
        require(matron.birthTime != 0);

        // Check that the matron is pregnant, and that its time has come!
        require(_isReadyToGiveBirth(matron));

        // Grab a reference to the sire in storage.
        uint256 sireId = matron.siringWithId;
        Monster storage sire = monsters[sireId];

        // Determine the higher generation number of the two parents
        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        // Call the sooper-sekret gene mixing operation.
        // targetBlock
        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes, matron.cooldownEndBlock - 1);

        // Make the new monster!
        address owner = monsterIndexToOwner[_matronId];
        uint256 monsterId = _createMonster(_matronId, matron.siringWithId, parentGen + 1, childGenes, owner);

        // Clear the reference to sire from the matron (REQUIRED! Having siringWithId
        // set is what marks a matron as being pregnant.)
        delete matron.siringWithId;

        // Every time a monster gives birth counter is decremented.
        pregnantMonsters--;

        // Send the balance fee to the person who made birth happen.
        msg.sender.send(autoBirthFee);

        // return the new monster's ID
        return monsterId;
    }
}












/// @title Handles creating auctions for sale and siring of monsters.
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract MonsterAuction is MonsterBreeding {

    // @notice The auction contract variables are defined in MonsterBase to allow
    //  us to refer to them in MonsterOwnership to prevent accidental transfers.
    // `saleAuction` refers to the auction for gen0 and p2p sale of monsters.
    // `siringAuction` refers to the auction for siring rights of monsters.

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
    }

    /// @dev Sets the reference to the siring auction.
    /// @param _address - Address of siring contract.
    function setSiringAuctionAddress(address _address) external onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSiringClockAuction());

        // Set the new contract address
        siringAuction = candidateContract;
    }

    /// @dev Put a monster up for auction.
    ///  Does some ownership trickery to create auctions in one tx.
    function createSaleAuction(
        uint256 _monsterId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
    external
    whenNotPaused
    {
        // Auction contract checks input sizes
        // If monster is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_owns(msg.sender, _monsterId));
        // Ensure the monster is not pregnant to prevent the auction
        // contract accidentally receiving ownership of the child.
        // NOTE: the monster IS allowed to be in a cooldown.
        require(!isPregnant(_monsterId));
        _approve(_monsterId, saleAuction);
        // Sale auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the monster.
        saleAuction.createAuction(
            _monsterId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    /// @dev Put a monster up for auction to be sire.
    ///  Performs checks to ensure the monster can be sired, then
    ///  delegates to reverse auction.
    function createSiringAuction(
        uint256 _monsterId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
    external
    whenNotPaused
    {
        // Auction contract checks input sizes
        // If monster is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_owns(msg.sender, _monsterId));
        require(isReadyToBreed(_monsterId));
        _approve(_monsterId, siringAuction);
        // Siring auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the monster.
        siringAuction.createAuction(
            _monsterId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    /// @dev Completes a siring auction by bidding.
    ///  Immediately breeds the winning matron with the sire on auction.
    /// @param _sireId - ID of the sire on auction.
    /// @param _matronId - ID of the matron owned by the bidder.
    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
    external
    payable
    whenNotPaused
    {
        // Auction contract checks input sizes
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

        // Define the current price of the auction.
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);

        // Siring auction will throw if the bid fails.
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
    }

    /// @dev Transfers the balance of the sale auction contract
    /// to the MonsterCore contract. We use two-step withdrawal to
    /// prevent two transfer calls in the auction bid function.
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
    }
}


/// @title all functions related to creating monsters
contract MonsterMinting is MonsterAuction {

    // Limits the number of monsters the contract owner can ever create.
    uint256 public constant PROMO_CREATION_LIMIT = 5000;
    uint256 public constant GEN0_CREATION_LIMIT = 45000;

    // Constants for gen0 auctions.
    uint256 public constant GEN0_STARTING_PRICE = 10 finney;
    uint256 public constant GEN0_AUCTION_DURATION = 1 days;

    // Counts the number of monsters the contract owner has created.
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    /// @dev we can create promo monsters, up to a limit. Only callable by COO
    /// @param _genes the encoded genes of the monster to be created, any value is accepted
    /// @param _owner the future owner of the created monsters. Default to contract COO
    function createPromoMonster(uint256 _genes, address _owner) external onlyCOO {
        address monsterOwner = _owner;
        if (monsterOwner == address(0)) {
            monsterOwner = cooAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createMonster(0, 0, 0, _genes, monsterOwner);
    }

    /// @dev Creates a new gen0 monster with the given genes and
    ///  creates an auction for it.
    function createGen0Auction(uint256 _genes) external onlyCOO {
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);

        uint256 genes = _genes;
        if(genes == 0)
            genes = geneScience.randomGenes();

        uint256 monsterId = _createMonster(0, 0, 0, genes, address(this));
        _approve(monsterId, saleAuction);

        saleAuction.createAuction(
            monsterId,
            _computeNextGen0Price(),
            0,
            GEN0_AUCTION_DURATION,
            address(this)
        );

        gen0CreatedCount++;
    }

    /// @dev Computes the next gen0 auction starting price, given
    ///  the average of the past 5 prices + 50%.
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        // Sanity check to ensure we don't overflow arithmetic
        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice / 2);

        // We never auction for less than starting price
        if (nextPrice < GEN0_STARTING_PRICE) {
            nextPrice = GEN0_STARTING_PRICE;
        }

        return nextPrice;
    }
}


/// @title CryptoMonsters: Collectible, breedable, and oh-so-adorable monsters on the Ethereum blockchain.
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev The main CryptoMonsters contract, keeps track of monsters so they don't wander around and get lost.
contract MonsterCore is MonsterMinting {

    // This is the main CryptoMonsters contract. In order to keep our code seperated into logical sections,
    // we've broken it up in two ways. First, we have several seperately-instantiated sibling contracts
    // that handle auctions and our super-top-secret genetic combination algorithm. The auctions are
    // seperate since their logic is somewhat complex and there's always a risk of subtle bugs. By keeping
    // them in their own contracts, we can upgrade them without disrupting the main contract that tracks
    // monster ownership. The genetic combination algorithm is kept seperate so we can open-source all of
    // the rest of our code without making it _too_ easy for folks to figure out how the genetics work.
    // Don't worry, I'm sure someone will reverse engineer it soon enough!
    //
    // Secondly, we break the core contract into multiple files using inheritence, one for each major
    // facet of functionality of CK. This allows us to keep related code bundled together while still
    // avoiding a single giant file with everything in it. The breakdown is as follows:
    //
    //      - MonsterBase: This is where we define the most fundamental code shared throughout the core
    //             functionality. This includes our main data storage, constants and data types, plus
    //             internal functions for managing these items.
    //
    //      - MonsterAccessControl: This contract manages the various addresses and constraints for operations
    //             that can be executed only by specific roles. Namely CEO, CFO and COO.
    //
    //      - MonsterOwnership: This provides the methods required for basic non-fungible token
    //             transactions, following the draft ERC-721 spec (https://github.com/ethereum/EIPs/issues/721).
    //
    //      - MonsterBreeding: This file contains the methods necessary to breed monsters together, including
    //             keeping track of siring offers, and relies on an external genetic combination contract.
    //
    //      - MonsterAuctions: Here we have the public methods for auctioning or bidding on monsters or siring
    //             services. The actual auction functionality is handled in two sibling contracts (one
    //             for sales and one for siring), while auction creation and bidding is mostly mediated
    //             through this facet of the core contract.
    //
    //      - MonsterMinting: This final facet contains the functionality we use for creating new gen0 monsters.
    //             We can make up to 5000 "promo" monsters that can be given away (especially important when
    //             the community is new), and all others can only be created and then immediately put up
    //             for auction via an algorithmically determined starting price. Regardless of how they
    //             are created, there is a hard limit of 50k gen0 monsters. After that, it's all up to the
    //             community to breed, breed, breed!

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    /// @notice Creates the main CryptoMonsters smart contract instance.
    function MonsterCore() public {
        // Starts paused.
        paused = false;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;

        //
        cfoAddress = msg.sender;

        // start with the mythical monster 0 - so we don't have generation-0 parent issues
        _createMonster(0, 0, 0, uint256(-1), address(0));
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indimonstering that the new address is set. It's up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here, unless it's from one of the
    ///  two auction contracts. (Hopefully, we can prevent user accidents.)
    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(siringAuction)
        );
    }

    /// @notice Returns all the relevant information about a specific monster.
    /// @param _id The ID of the monster of interest.
    function getMonster(uint256 _id)
    external
    view
    returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    ) {
        Monster storage monster = monsters[_id];

        // if this variable is 0 then it's not gestating
        isGestating = (monster.siringWithId != 0);
        isReady = (monster.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(monster.cooldownIndex);
        nextActionAt = uint256(monster.cooldownEndBlock);
        siringWithId = uint256(monster.siringWithId);
        birthTime = uint256(monster.birthTime);
        matronId = uint256(monster.matronId);
        sireId = uint256(monster.sireId);
        generation = uint256(monster.generation);
        genes = monster.genes;
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can't have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(geneScience != address(0));
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpause();
    }

    // @dev Allows the CFO to capture the balance available to the contract.
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
        // Subtract all the currently pregnant monsters we have, plus 1 of margin.
        uint256 subtractFees = (pregnantMonsters + 1) * autoBirthFee;

        if (balance > subtractFees) {
            cfoAddress.send(balance - subtractFees);
        }
    }
}