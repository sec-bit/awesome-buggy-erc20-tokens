pragma solidity ^0.4.18;


// inspired by
// https://github.com/axiomzen/cryptokitties-bounty/blob/master/contracts/KittyAccessControl.sol
contract AccessControl {
    /// @dev The addresses of the accounts (or contracts) that can execute actions within each roles
    address public ceoAddress;
    address public cooAddress;

    /// @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev The AccessControl constructor sets the original C roles of the contract to the sender account
    function AccessControl() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Access modifier for any CLevel functionality
    modifier onlyCLevel() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }

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

    /// @dev Pause the smart contract. Only can be called by the CEO
    function pause() public onlyCEO whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Only can be called by the CEO
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}


// https://github.com/dharmaprotocol/NonFungibleToken/blob/master/contracts/ERC721.sol
// https://github.com/dharmaprotocol/NonFungibleToken/blob/master/contracts/DetailedERC721.sol

/**
 * Interface for required functionality in the ERC721 standard
 * for non-fungible tokens.
 *
 * Author: Nadav Hollander (nadav at dharma.io)
 */
contract ERC721 {
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    /// For querying totalSupply of token.
    function totalSupply() public view returns (uint256 _totalSupply);

    /// For querying balance of a particular account.
    /// @param _owner The address for balance query.
    /// @dev Required for ERC-721 compliance.
    function balanceOf(address _owner) public view returns (uint256 _balance);

    /// For querying owner of token.
    /// @param _tokenId The tokenID for owner inquiry.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId) public view returns (address _owner);

    /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom()
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(address _to, uint256 _tokenId) public;

    // NOT IMPLEMENTED
    // function getApproved(uint256 _tokenId) public view returns (address _approved);

    /// Third-party initiates transfer of token from address _from to address _to.
    /// @param _from The address for the token to be transferred from.
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    /// Owner initates the transfer of the token to another account.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the token to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _tokenId) public;

    ///
    function implementsERC721() public view returns (bool _implementsERC721);

    // EXTRA
    /// @notice Allow pre-approved user to take ownership of a token.
    /// @param _tokenId The ID of the token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint256 _tokenId) public;
}


/**
 * Interface for optional functionality in the ERC721 standard
 * for non-fungible tokens.
 *
 * Author: Nadav Hollander (nadav at dharma.io)
 */
contract DetailedERC721 is ERC721 {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    // function tokenMetadata(uint256 _tokenId) public view returns (string _infoUrl);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
}


contract CryptoKittenToken is AccessControl, DetailedERC721 {
    using SafeMath for uint256;

    /// @dev The TokenCreated event is fired whenever a new token is created.
    event TokenCreated(uint256 tokenId, string name, uint256 price, address owner);

    /// @dev The TokenSold event is fired whenever a token is sold.
    event TokenSold(uint256 indexed tokenId, string name, uint256 sellingPrice,
    uint256 newPrice, address indexed oldOwner, address indexed newOwner);

    /// @dev A mapping from tokenIds to the address that owns them. All tokens have
    ///  some valid owner address.
    mapping (uint256 => address) private tokenIdToOwner;

    /// @dev A mapping from TokenIds to the price of the token.
    mapping (uint256 => uint256) private tokenIdToPrice;

    /// @dev A mapping from owner address to count of tokens that address owns.
    ///  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) private ownershipTokenCount;

    /// @dev A mapping from TokenIds to an address that has been approved to call
    ///  transferFrom(). Each Token can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding
    mapping (uint256 => address) public tokenIdToApproved;

    struct Kittens {
        string name;
    }

    Kittens[] private kittens;

    uint256 private startingPrice = 0.01 ether;
    bool private erc721Enabled = false;

    modifier onlyERC721() {
        require(erc721Enabled);
        _;
    }

    /// @dev Creates a new token with the given name and _price and assignes it to an _owner.
    function createToken(string _name, address _owner, uint256 _price) public onlyCLevel {
        require(_owner != address(0));
        require(_price >= startingPrice);

        _createToken(_name, _owner, _price);
    }

    /// @dev Creates a new token with the given name.
    function createToken(string _name) public onlyCLevel {
        _createToken(_name, address(this), startingPrice);
    }

    function _createToken(string _name, address _owner, uint256 _price) private {
        Kittens memory _kitten = Kittens({
            name: _name
        });
        uint256 newTokenId = kittens.push(_kitten) - 1;
        tokenIdToPrice[newTokenId] = _price;

        TokenCreated(newTokenId, _name, _price, _owner);

        // This will assign ownership, and also emit the Transfer event as per ERC721 draft
        _transfer(address(0), _owner, newTokenId);
    }

    function getToken(uint256 _tokenId) public view returns (
        string _tokenName,
        uint256 _price,
        uint256 _nextPrice,
        address _owner
    ) {
        _tokenName = kittens[_tokenId].name;
        _price = tokenIdToPrice[_tokenId];
        _nextPrice = nextPriceOf(_tokenId);
        _owner = tokenIdToOwner[_tokenId];
    }

    function getAllTokens() public view returns (
        uint256[],
        uint256[],
        address[]
    ) {
        uint256 total = totalSupply();
        uint256[] memory prices = new uint256[](total);
        uint256[] memory nextPrices = new uint256[](total);
        address[] memory owners = new address[](total);

        for (uint256 i = 0; i < total; i++) {
            prices[i] = tokenIdToPrice[i];
            nextPrices[i] = nextPriceOf(i);
            owners[i] = tokenIdToOwner[i];
        }

        return (prices, nextPrices, owners);
    }

    function tokensOf(address _owner) public view returns(uint256[]) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;

            for (uint256 i = 0; i < total; i++) {
                if (tokenIdToOwner[i] == _owner) {
                    result[resultIndex] = i;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    /// @dev This function withdraws the contract owner's cut.
    /// Any amount may be withdrawn as there is no user funds.
    /// User funds are immediately sent to the old owner in `purchase`
    function withdrawBalance(address _to, uint256 _amount) public onlyCEO {
        require(_amount <= this.balance);

        if (_amount == 0) {
            _amount = this.balance;
        }

        if (_to == address(0)) {
            ceoAddress.transfer(_amount);
        } else {
            _to.transfer(_amount);
        }
    }

    // Send ether and obtain the token
    function purchase(uint256 _tokenId) public payable whenNotPaused {
        address oldOwner = ownerOf(_tokenId);
        address newOwner = msg.sender;
        uint256 sellingPrice = priceOf(_tokenId);

        // active tokens
        require(oldOwner != address(0));
        // maybe one day newOwner's logic allows this to happen
        require(newOwner != address(0));
        // don't buy from yourself
        require(oldOwner != newOwner);
        // don't sell to contracts
        // but even this doesn't prevent bad contracts to become an owner of a token
        require(!_isContract(newOwner));
        // another check to be sure that token is active
        require(sellingPrice > 0);
        // min required amount check
        require(msg.value >= sellingPrice);

        // transfer to the new owner
        _transfer(oldOwner, newOwner, _tokenId);
        // update fields before emitting an event
        tokenIdToPrice[_tokenId] = nextPriceOf(_tokenId);
        // emit event
        TokenSold(_tokenId, kittens[_tokenId].name, sellingPrice, priceOf(_tokenId), oldOwner, newOwner);

        // extra ether which should be returned back to buyer
        uint256 excess = msg.value.sub(sellingPrice);
        // contract owner's cut which is left in contract and accesed by withdrawBalance
        uint256 contractCut = sellingPrice.mul(6).div(100); // 6%

        // no need to transfer if it's initial sell
        if (oldOwner != address(this)) {
            // transfer payment to seller minus the contract's cut
            oldOwner.transfer(sellingPrice.sub(contractCut));
        }

        // return extra ether
        if (excess > 0) {
            newOwner.transfer(excess);
        }
    }

    function priceOf(uint256 _tokenId) public view returns (uint256 _price) {
        return tokenIdToPrice[_tokenId];
    }

    uint256 private increaseLimit1 = 0.02 ether;
    uint256 private increaseLimit2 = 0.5 ether;
    uint256 private increaseLimit3 = 2.0 ether;
    uint256 private increaseLimit4 = 5.0 ether;

    function nextPriceOf(uint256 _tokenId) public view returns (uint256 _nextPrice) {
        uint256 _price = priceOf(_tokenId);
        if (_price < increaseLimit1) {
            return _price.mul(200).div(95);
        } else if (_price < increaseLimit2) {
            return _price.mul(135).div(96);
        } else if (_price < increaseLimit3) {
            return _price.mul(125).div(97);
        } else if (_price < increaseLimit4) {
            return _price.mul(117).div(97);
        } else {
            return _price.mul(115).div(98);
        }
    }


    /*** ERC-721 ***/
    // Unlocks ERC721 behaviour, allowing for trading on third party platforms.
    function enableERC721() onlyCEO public {
        erc721Enabled = true;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        _totalSupply = kittens.length;
    }

    function balanceOf(address _owner) public view returns (uint256 _balance) {
        _balance = ownershipTokenCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        _owner = tokenIdToOwner[_tokenId];
        // require(_owner != address(0));
    }

    function approve(address _to, uint256 _tokenId) public whenNotPaused onlyERC721 {
        require(_owns(msg.sender, _tokenId));

        tokenIdToApproved[_tokenId] = _to;

        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused onlyERC721 {
        require(_to != address(0));
        require(_owns(_from, _tokenId));
        require(_approved(msg.sender, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public whenNotPaused onlyERC721 {
        require(_to != address(0));
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    function implementsERC721() public view whenNotPaused returns (bool) {
        return erc721Enabled;
    }

    function takeOwnership(uint256 _tokenId) public whenNotPaused onlyERC721 {
        require(_approved(msg.sender, _tokenId));

        _transfer(tokenIdToOwner[_tokenId], msg.sender, _tokenId);
    }

    function name() public view returns (string _name) {
        _name = "CryptoKittens";
    }

    function symbol() public view returns (string _symbol) {
        _symbol = "CKTN";
    }

    /*** PRIVATES ***/
    /// @dev Check for token ownership.
    function _owns(address _claimant, uint256 _tokenId) private view returns (bool) {
        return tokenIdToOwner[_tokenId] == _claimant;
    }

    /// @dev For checking approval of transfer for address _to.
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return tokenIdToApproved[_tokenId] == _to;
    }

    /// @dev Assigns ownership of a specific token to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        // Since the number of tokens is capped to 2^32 we can't overflow this
        ownershipTokenCount[_to]++;
        // Transfer ownership
        tokenIdToOwner[_tokenId] = _to;

        // When creating new token _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete tokenIdToApproved[_tokenId];
        }

        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    /// @dev Checks if the address ia a contract or not
    function _isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}


// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// v1.6.0

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