pragma solidity ^0.4.11;

contract LedgerLegendsToken {
  address public owner;
  mapping(address => bool) public minters;

  event Approval(address indexed owner, address indexed approved, uint256 tokenId);
  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Mint(address indexed owner, uint256 tokenId);

  uint256 public tokenIdCounter = 1;
  mapping (uint256 => address) public tokenIdToOwner;
  mapping (uint256 => bytes32) public tokenIdToData;
  mapping (uint256 => address) public tokenIdToApproved;
  mapping (address => uint256[]) public ownerToTokenIds;
  mapping (uint256 => uint256) public tokenIdToOwnerArrayIndex;

  function LedgerLegendsToken() public {
    owner = msg.sender;
  }

  /* Admin */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyMinters() {
    require(minters[msg.sender]);
    _;
  }

  function addMinter(address _minter) onlyOwner() public {
    minters[_minter] = true;
  }

  function removeMinter(address _minter) onlyOwner() public {
    delete minters[_minter];
  }

  /* Internal */
  function _addTokenToOwnersList(address _owner, uint256 _tokenId) internal {
    ownerToTokenIds[_owner].push(_tokenId);
    tokenIdToOwnerArrayIndex[_tokenId] = ownerToTokenIds[_owner].length - 1;
  }

  function _removeTokenFromOwnersList(address _owner, uint256 _tokenId) internal {
    uint256 length = ownerToTokenIds[_owner].length;
    uint256 index = tokenIdToOwnerArrayIndex[_tokenId];
    uint256 swapToken = ownerToTokenIds[_owner][length - 1];

    ownerToTokenIds[_owner][index] = swapToken;
    tokenIdToOwnerArrayIndex[swapToken] = index;

    delete ownerToTokenIds[_owner][length - 1];
    ownerToTokenIds[_owner].length--;
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    require(tokenExists(_tokenId));
    require(ownerOf(_tokenId) == _from);
    require(_to != address(0));
    require(_to != address(this));

    tokenIdToOwner[_tokenId] = _to;
    delete tokenIdToApproved[_tokenId];

    _removeTokenFromOwnersList(_from, _tokenId);
    _addTokenToOwnersList(_to, _tokenId);

    Transfer(msg.sender, _to, _tokenId);
  }

  /* Minting */
  function mint(address _owner, bytes32 _data) onlyMinters() public returns (uint256 tokenId) {
    tokenId = tokenIdCounter;
    tokenIdCounter += 1;
    tokenIdToOwner[tokenId] = _owner;
    tokenIdToData[tokenId] = _data;
    _addTokenToOwnersList(_owner, tokenId);
    Mint(_owner, tokenId);
  }

  /* ERC721 */
  function name() public pure returns (string) {
    return "Ledger Legends Cards";
  }

  function symbol() public pure returns (string) {
    return "LLC";
  }

  function totalSupply() public view returns (uint256) {
    return tokenIdCounter - 1;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return ownerToTokenIds[_owner].length;
  }

  function ownerOf(uint256 _tokenId) public view returns (address) {
    return tokenIdToOwner[_tokenId];
  }

  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenIdToApproved[_tokenId];
  }

  function tokenExists(uint256 _tokenId) public view returns (bool) {
    return _tokenId < tokenIdCounter;
  }

  function tokenData(uint256 _tokenId) public view returns (bytes32) {
    return tokenIdToData[_tokenId];
  }

  function tokensOfOwner(address _owner) public view returns (uint256[]) {
    return ownerToTokenIds[_owner];
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    return ownerToTokenIds[_owner][_index];
  }

  function approve(address _to, uint256 _tokenId) public {
    require(msg.sender != _to);
    require(tokenExists(_tokenId));
    require(ownerOf(_tokenId) == msg.sender);

    if (_to == 0) {
      if (tokenIdToApproved[_tokenId] != 0) {
        delete tokenIdToApproved[_tokenId];
        Approval(msg.sender, 0, _tokenId);
      }
    } else {
      tokenIdToApproved[_tokenId] = _to;
      Approval(msg.sender, _to, _tokenId);
    }
  }

  function transfer(address _to, uint256 _tokenId) public {
    _transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(tokenIdToApproved[_tokenId] == msg.sender);
    _transfer(_from, _to, _tokenId);
  }
}