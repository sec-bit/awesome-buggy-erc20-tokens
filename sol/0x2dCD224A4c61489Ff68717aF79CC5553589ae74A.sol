pragma solidity ^0.4.18; // solhint-disable-line



/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function approve(address _to, uint256 _tokenId) public;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 _tokenId) public view returns (address addr);
    function takeOwnership(uint256 _tokenId) public;
    function totalSupply() public view returns (uint256 total);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}


contract SportStarToken is ERC721 {

    // ***** EVENTS

    // @dev Transfer event as defined in current draft of ERC721.
    //  ownership is assigned, including births.
    event Transfer(address from, address to, uint256 tokenId);



    // ***** STORAGE

    // @dev A mapping from token IDs to the address that owns them. All tokens have
    //  some valid owner address.
    mapping (uint256 => address) public tokenIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) private ownershipTokenCount;

    // @dev A mapping from TokenIDs to an address that has been approved to call
    //  transferFrom(). Each Token can only have one approved address for transfer
    //  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public tokenIndexToApproved;

    // Additional token data
    mapping (uint256 => bytes32) public tokenIndexToData;

    address public ceoAddress;
    address public masterContractAddress;

    uint256 public promoCreatedCount;



    // ***** DATATYPES

    struct Token {
        string name;
    }

    Token[] private tokens;



    // ***** ACCESS MODIFIERS

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyMasterContract() {
        require(msg.sender == masterContractAddress);
        _;
    }



    // ***** CONSTRUCTOR

    function SportStarToken() public {
        ceoAddress = msg.sender;
    }



    // ***** PRIVILEGES SETTING FUNCTIONS

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setMasterContract(address _newMasterContract) public onlyCEO {
        require(_newMasterContract != address(0));

        masterContractAddress = _newMasterContract;
    }



    // ***** PUBLIC FUNCTIONS

    // @notice Returns all the relevant information about a specific token.
    // @param _tokenId The tokenId of the token of interest.
    function getToken(uint256 _tokenId) public view returns (
        string tokenName,
        address owner
    ) {
        Token storage token = tokens[_tokenId];
        tokenName = token.name;
        owner = tokenIndexToOwner[_tokenId];
    }

    // @param _owner The owner whose sport star tokens we are interested in.
    // @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    //  expensive (it walks the entire Tokens array looking for tokens belonging to owner),
    //  but it also returns a dynamic array, which is only supported for web3 calls, and
    //  not contract-to-contract calls.
    function tokensOfOwner(address _owner) public view returns (uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = totalSupply();
            uint256 resultIndex = 0;

            uint256 tokenId;
            for (tokenId = 0; tokenId <= totalTokens; tokenId++) {
                if (tokenIndexToOwner[tokenId] == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function getTokenData(uint256 _tokenId) public view returns (bytes32 tokenData) {
        return tokenIndexToData[_tokenId];
    }



    // ***** ERC-721 FUNCTIONS

    // @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
    // @param _to The address to be granted transfer approval. Pass address(0) to
    //  clear all approvals.
    // @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    function approve(address _to, uint256 _tokenId) public {
        // Caller must own token.
        require(_owns(msg.sender, _tokenId));

        tokenIndexToApproved[_tokenId] = _to;

        Approval(msg.sender, _to, _tokenId);
    }

    // For querying balance of a particular account
    // @param _owner The address for balance query
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }

    function name() public pure returns (string) {
        return "CryptoSportStars";
    }

    function symbol() public pure returns (string) {
        return "SportStarToken";
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    // For querying owner of token
    // @param _tokenId The tokenID for owner inquiry
    function ownerOf(uint256 _tokenId) public view returns (address owner)
    {
        owner = tokenIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    // @notice Allow pre-approved user to take ownership of a token
    // @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = tokenIndexToOwner[_tokenId];

        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));

        // Making sure transfer is approved
        require(_approved(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }

    // For querying totalSupply of token
    function totalSupply() public view returns (uint256 total) {
        return tokens.length;
    }

    // Owner initates the transfer of the token to another account
    // @param _to The address for the token to be transferred to.
    // @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    function transfer(address _to, uint256 _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

    // Third-party initiates transfer of token from address _from to address _to
    // @param _from The address for the token to be transferred from.
    // @param _to The address for the token to be transferred to.
    // @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }



    // ONLY MASTER CONTRACT FUNCTIONS

    function createToken(string _name, address _owner) public onlyMasterContract returns (uint256 _tokenId) {
        return _createToken(_name, _owner);
    }

    function updateOwner(address _from, address _to, uint256 _tokenId) public onlyMasterContract {
        _transfer(_from, _to, _tokenId);
    }

    function setTokenData(uint256 _tokenId, bytes32 tokenData) public onlyMasterContract {
        tokenIndexToData[_tokenId] = tokenData;
    }



    // PRIVATE FUNCTIONS

    // Safety check on _to address to prevent against an unexpected 0x0 default.
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

    // For checking approval of transfer for address _to
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return tokenIndexToApproved[_tokenId] == _to;
    }

    // For creating Token
    function _createToken(string _name, address _owner) private returns (uint256 _tokenId) {
        Token memory _token = Token({
            name: _name
            });
        uint256 newTokenId = tokens.push(_token) - 1;

        // It's probably never going to happen, 4 billion tokens are A LOT, but
        // let's just be 100% sure we never let this happen.
        require(newTokenId == uint256(uint32(newTokenId)));

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(address(0), _owner, newTokenId);

        return newTokenId;
    }

    // Check for token ownership
    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == tokenIndexToOwner[_tokenId];
    }

    // @dev Assigns ownership of a specific Token to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        // Since the number of tokens is capped to 2^32 we can't overflow this
        ownershipTokenCount[_to]++;
        //transfer ownership
        tokenIndexToOwner[_tokenId] = _to;

        // When creating new tokens _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete tokenIndexToApproved[_tokenId];
        }

        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }
}