pragma solidity ^0.4.18;

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused {
    require(paused);
    _;
  }

  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract TrueloveAccessControl {
  event ContractUpgrade(address newContract);

  address public ceoAddress;
  address public cfoAddress;
  address public cooAddress;

  bool public paused = false;

  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

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

  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

  function setCFO(address _newCFO) external onlyCEO {
    require(_newCFO != address(0));

    cfoAddress = _newCFO;
  }

  function setCOO(address _newCOO) external onlyCEO {
    require(_newCOO != address(0));

    cooAddress = _newCOO;
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused {
    require(paused);
    _;
  }

  function pause() external onlyCLevel whenNotPaused {
    paused = true;
  }

  function unpause() public onlyCEO whenPaused {
    paused = false;
  }
}

contract TrueloveBase is TrueloveAccessControl {
	Diamond[] diamonds;
	mapping (uint256 => address) public diamondIndexToOwner;
	mapping (address => uint256) ownershipTokenCount;
	mapping (uint256 => address) public diamondIndexToApproved;

	mapping (address => uint256) public flowerBalances;

	struct Diamond {
		bytes24 model;
		uint16 year;
		uint16 no;
		uint activateAt;
	}

	struct Model {
		bytes24 model;
		uint current;
		uint total;
		uint16 year;
		uint256 price;
	}

	Model diamond1;
	Model diamond2;
	Model diamond3;
	Model flower;

	uint sendGiftPrice;
	uint beginSaleTime;
	uint nextSaleTime;
	uint registerPrice;

	DiamondAuction public diamondAuction;
	FlowerAuction public flowerAuction;

	function TrueloveBase() internal {
		sendGiftPrice = 0.001 ether; // MARK: Modify it
		registerPrice = 0.01 ether; // MARK: Modify it
		_setVars();

		diamond1 = Model({model: "OnlyOne", current: 0, total: 1, year: 2018, price: 1000 ether}); // MARK: Modify it
		diamond2 = Model({model: "Eternity2018", current: 0, total: 5, year: 2018, price: 50 ether}); // MARK: Modify it
		diamond3 = Model({model: "Memorial", current: 0, total: 1000, year: 2018, price: 1 ether}); // MARK: Modify it
		flower = Model({model: "MySassyGirl", current: 0, total: 10000000, year: 2018, price: 0.01 ether}); // MARK: Modify it
	}

	function _setVars() internal {
		beginSaleTime = now;
		nextSaleTime = beginSaleTime + 300 days; // MARK: Modify it
	}

	function setSendGiftPrice(uint _sendGiftPrice) external onlyCOO {
		sendGiftPrice = _sendGiftPrice;
	}

	function setRegisterPrice(uint _registerPrice) external onlyCOO {
		registerPrice = _registerPrice;
	}

	function _getModel(uint _index) internal view returns(Model storage) {
		if (_index == 1) {
			return diamond1;
		} else if (_index == 2) {
			return diamond2;
		} else if (_index == 3) {
			return diamond3;
		} else if (_index == 4) {
			return flower;
		}
		revert();
	}
	function getModel(uint _index) external view returns(
		bytes24 model,
		uint current,
		uint total,
		uint16 year,
		uint256 price
	) {
		Model storage _model = _getModel(_index);
		model = _model.model;
		current = _model.current;
		total = _model.total;
		year = _model.year;
		price = _model.price;
	}
}

contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public flowerTotalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOfFlower(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFlower(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFromFlower(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approveFlower(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowanceFlower(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name  
    event TransferFlower(address from, address to, uint256 value); 
    event ApprovalFlower(address owner, address spender, uint256 value);

    function supportsEIP20Interface(bytes4 _interfaceID) external view returns (bool);
}
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

contract ERC721Metadata {
	function getMetadata(uint256 _tokenId, string) public pure returns (bytes32[4] buffer, uint256 count) {
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

contract TrueloveOwnership is TrueloveBase, ERC721 {
	string public constant name = "CryptoTruelove";
	string public constant symbol = "CT";

	// The contract that will return kitty metadata
	ERC721Metadata public erc721Metadata;

	bytes4 constant InterfaceSignature_ERC165 = bytes4(0x9a20483d);
			// bytes4(keccak256("supportsInterface(bytes4)"));

	bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);
			// bytes4(keccak256("name()")) ^
			// bytes4(keccak256("symbol()")) ^
			// bytes4(keccak256("totalSupply()")) ^
			// bytes4(keccak256("balanceOf(address)")) ^
			// bytes4(keccak256("ownerOf(uint256)")) ^
			// bytes4(keccak256("approve(address,uint256)")) ^
			// bytes4(keccak256("transfer(address,uint256)")) ^
			// bytes4(keccak256("transferFrom(address,address,uint256)")) ^
			// bytes4(keccak256("tokensOfOwner(address)")) ^
			// bytes4(keccak256("tokenMetadata(uint256,string)"));

	/// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
	///  Returns true for any standardized interfaces implemented by this contract. We implement
	///  ERC-165 (obviously!) and ERC-721.
	function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
		// DEBUG ONLY
		//require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

		return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
	}

	function setMetadataAddress(address _contractAddress) public onlyCEO {
		erc721Metadata = ERC721Metadata(_contractAddress);
	}

	function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
			return diamondIndexToOwner[_tokenId] == _claimant;
	}

	function _transfer(address _from, address _to, uint256 _tokenId) internal {
		ownershipTokenCount[_to]++;
		diamondIndexToOwner[_tokenId] = _to;
		if (_from != address(0)) {
			ownershipTokenCount[_from]--;
			delete diamondIndexToApproved[_tokenId];
		}
		Transfer(_from, _to, _tokenId);
	}

	function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
			return diamondIndexToApproved[_tokenId] == _claimant;
	}

	function _approve(uint256 _tokenId, address _approved) internal {
			diamondIndexToApproved[_tokenId] = _approved;
	}

	/// @notice Returns the number of Kitties owned by a specific address.
	/// @param _owner The owner address to check.
	/// @dev Required for ERC-721 compliance
	function balanceOf(address _owner) public view returns (uint256 count) {
			return ownershipTokenCount[_owner];
	}

	function transfer(
			address _to,
			uint256 _tokenId
	)
			external
			whenNotPaused
	{
			require(_to != address(0));
			require(_to != address(this));
			require(_to != address(diamondAuction));
			require(_owns(msg.sender, _tokenId));

			_transfer(msg.sender, _to, _tokenId);
	}

	function approve(
			address _to,
			uint256 _tokenId
	)
			external
			whenNotPaused
	{
			require(_owns(msg.sender, _tokenId));

			_approve(_tokenId, _to);

			Approval(msg.sender, _to, _tokenId);
	}

	function transferFrom(
			address _from,
			address _to,
			uint256 _tokenId
	)
			external
			whenNotPaused
	{
			require(_to != address(0));
			require(_to != address(this));
			require(_approvedFor(msg.sender, _tokenId));
			require(_owns(_from, _tokenId));

			_transfer(_from, _to, _tokenId);
	}

	function totalSupply() public view returns (uint) {
			return diamonds.length - 1;
	}

	function ownerOf(uint256 _tokenId)
			external
			view
			returns (address owner)
	{
			owner = diamondIndexToOwner[_tokenId];

			require(owner != address(0));
	}

	/// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
	///  expensive (it walks the entire Kitty array looking for cats belonging to owner),
	///  but it also returns a dynamic array, which is only supported for web3 calls, and
	///  not contract-to-contract calls.
	function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
			uint256 tokenCount = balanceOf(_owner);

			if (tokenCount == 0) {
					// Return an empty array
					return new uint256[](0);
			} else {
					uint256[] memory result = new uint256[](tokenCount);
					uint256 totalDiamonds = totalSupply();
					uint256 resultIndex = 0;

					uint256 diamondId;

					for (diamondId = 1; diamondId <= totalDiamonds; diamondId++) {
							if (diamondIndexToOwner[diamondId] == _owner) {
									result[resultIndex] = diamondId;
									resultIndex++;
							}
					}

					return result;
			}
	}

	function _memcpy(uint _dest, uint _src, uint _len) private pure {
			// Copy word-length chunks while possible
			for(; _len >= 32; _len -= 32) {
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

	function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private pure returns (string) {
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

	function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
			require(erc721Metadata != address(0));
			bytes32[4] memory buffer;
			uint256 count;
			(buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

			return _toString(buffer, count);
	}

	function getDiamond(uint256 _id)
		external
		view
		returns (
		bytes24 model,
		uint16 year,
		uint16 no,
		uint activateAt
	) {
		Diamond storage diamond = diamonds[_id];

		model = diamond.model;
		year = diamond.year;
		no = diamond.no;
		activateAt = diamond.activateAt;
	}
}

contract TrueloveFlowerOwnership is TrueloveBase, EIP20Interface {
	uint256 constant private MAX_UINT256 = 2**256 - 1;
	mapping (address => mapping (address => uint256)) public flowerAllowed;

	bytes4 constant EIP20InterfaceSignature = bytes4(0x98474109);
		// bytes4(keccak256("balanceOfFlower(address)")) ^
		// bytes4(keccak256("approveFlower(address,uint256)")) ^
		// bytes4(keccak256("transferFlower(address,uint256)")) ^
		// bytes4(keccak256("transferFromFlower(address,address,uint256)"));

	function supportsEIP20Interface(bytes4 _interfaceID) external view returns (bool) {
		return _interfaceID == EIP20InterfaceSignature;
	}

	function _transferFlower(address _from, address _to, uint256 _value) internal returns (bool success) {
		if (_from != address(0)) {
			require(flowerBalances[_from] >= _value);
			flowerBalances[_from] -= _value;
		}
		flowerBalances[_to] += _value;
		TransferFlower(_from, _to, _value);
		return true;
	}

	function transferFlower(address _to, uint256 _value) public returns (bool success) {
		require(flowerBalances[msg.sender] >= _value);
		flowerBalances[msg.sender] -= _value;
		flowerBalances[_to] += _value;
		TransferFlower(msg.sender, _to, _value);
		return true;
	}

	function transferFromFlower(address _from, address _to, uint256 _value) public returns (bool success) {
		uint256 allowance = flowerAllowed[_from][msg.sender];
		require(flowerBalances[_from] >= _value && allowance >= _value);
		flowerBalances[_to] += _value;
		flowerBalances[_from] -= _value;
		if (allowance < MAX_UINT256) {
			flowerAllowed[_from][msg.sender] -= _value;
		}
		TransferFlower(_from, _to, _value);
		return true;
	}

	function balanceOfFlower(address _owner) public view returns (uint256 balance) {
		return flowerBalances[_owner];
	}

	function approveFlower(address _spender, uint256 _value) public returns (bool success) {
		flowerAllowed[msg.sender][_spender] = _value;
		ApprovalFlower(msg.sender, _spender, _value);
		return true;
	}

	function allowanceFlower(address _owner, address _spender) public view returns (uint256 remaining) {
		return flowerAllowed[_owner][_spender];
	}

	function _addFlower(uint256 _amount) internal {
		flower.current += _amount;
		flowerTotalSupply += _amount;
	}
}

contract TrueloveNextSale is TrueloveOwnership, TrueloveFlowerOwnership {
	uint256 constant REMAINING_AMOUNT = 50000; // MARK: Modify it

	function TrueloveNextSale() internal {
		_giveRemainingFlower();
	}

	function openNextSale(uint256 _diamond1Price, bytes24 _diamond2Model, uint256 _diamond2Price, bytes24 _flowerModel, uint256 _flowerPrice)
		external onlyCOO
		{
		require(now >= nextSaleTime);

		_setVars();
		diamond1.price = _diamond1Price;
		_openSaleDiamond2(_diamond2Model, _diamond2Price);
		_openSaleFlower(_flowerModel, _flowerPrice);
		_giveRemainingFlower();
	}

	function _openSaleDiamond2(bytes24 _diamond2Model, uint256 _diamond2Price) private {
		diamond2.model = _diamond2Model;
		diamond2.current = 0;
		diamond2.year++;
		diamond2.price = _diamond2Price;
	}

	function _openSaleFlower(bytes24 _flowerModel, uint256 _flowerPrice) private {
		flower.model = _flowerModel;
		flower.current = 0;
		flower.year++;
		flower.price = _flowerPrice;
		flower.total = 1000000; // MARK: Modify it
	}

	function _giveRemainingFlower() internal {
		_transferFlower(0, msg.sender, REMAINING_AMOUNT);
		_addFlower(REMAINING_AMOUNT);
	}
}

contract TrueloveRegistration is TrueloveNextSale {
	mapping (address => RegistrationRight) public registrationRights;
	mapping (bytes32 => Registration) public registrations;

	struct RegistrationRight {
		bool able;
		bool used;
	}

	struct Registration {
		bool signed;
		string secret; // including both names
		string topSecret; // including SSN and birthdate
	}

	function giveRegistration(address _addr) external onlyCOO {
		if (registrationRights[_addr].able == false) {
			registrationRights[_addr].able = true;
		} else {
			revert();
		}
	}

	function buyRegistration() external payable whenNotPaused {
		require(registerPrice <= msg.value);
		if (registrationRights[msg.sender].able == false) {
			registrationRights[msg.sender].able = true;
		} else {
			revert();
		}
	}

	function _giveSenderRegistration() internal {
		if (registrationRights[msg.sender].able == false) {
			registrationRights[msg.sender].able = true;
		}
	}

	function getRegistrationRight(address _addr) external view returns (bool able, bool used) {
		able = registrationRights[_addr].able;
		used = registrationRights[_addr].used;
	}

	function getRegistration(bytes32 _unique) external view returns (bool signed, string secret, string topSecret) {
		signed = registrations[_unique].signed;
		secret = registrations[_unique].secret;
		topSecret = registrations[_unique].topSecret;
	}

	function signTruelove(bytes32 _registerID, string _secret, string _topSecret) public {
		require(registrationRights[msg.sender].able == true);
		require(registrationRights[msg.sender].used == false);
		registrationRights[msg.sender].used = true;
		_signTruelove(_registerID, _secret, _topSecret);
	}

	function signTrueloveByCOO(bytes32 _registerID, string _secret, string _topSecret) external onlyCOO {
		_signTruelove(_registerID, _secret, _topSecret);
	}

	function _signTruelove(bytes32 _registerID, string _secret, string _topSecret) internal {
		require(registrations[_registerID].signed == false);

		registrations[_registerID].signed = true;
		registrations[_registerID].secret = _secret;
		registrations[_registerID].topSecret = _topSecret;
	}
}

contract TrueloveShop is TrueloveRegistration {
	function buyDiamond(uint _index) external payable whenNotPaused returns(uint256) {
		require(_index == 1 || _index == 2 || _index == 3);
		Model storage model = _getModel(_index);

		require(model.current < model.total);
		require(model.price <= msg.value);
		_giveSenderRegistration();

		uint256 newDiamondId = diamonds.push(Diamond({model: model.model, year: model.year, no: uint16(model.current + 1), activateAt: 0})) - 1;
		_transfer(0, msg.sender, newDiamondId);
		
		model.current++;
		return newDiamondId;
	}

	function buyFlower(uint _amount) external payable whenNotPaused {
		require(flower.current + _amount < flower.total);
		uint256 price = currentFlowerPrice();
		require(price * _amount <= msg.value);
		_giveSenderRegistration();

		_transferFlower(0, msg.sender, _amount);
		_addFlower(_amount);
	}

	function currentFlowerPrice() public view returns(uint256) {
		if (flower.current < 10 + REMAINING_AMOUNT) { // MARK: Modify it
			return flower.price;
		} else if (flower.current < 30 + REMAINING_AMOUNT) { // MARK: Modify it
			return flower.price * 4;
		} else {
			return flower.price * 10;
		}
	}
}
contract TrueloveDelivery is TrueloveShop {
	enum GiftType { Diamond, Flower }

	event GiftSend(uint indexed index, address indexed receiver, address indexed from, bytes32 registerID, string letter, bytes16 date,
		GiftType gtype,
		bytes24 model,
		uint16 year,
		uint16 no,
		uint amount
		);

	uint public giftSendIndex = 1;
	
	modifier sendCheck(bytes32 _registerID) {
    require(sendGiftPrice <= msg.value);
		require(registrations[_registerID].signed);
    _;
  }

	function signSendDiamond(bytes32 _registerID, string _secret, string _topSecret, address _truelove, string _letter, bytes16 _date, uint _tokenId) external payable {
		signTruelove(_registerID, _secret, _topSecret);
		sendDiamond(_truelove, _registerID, _letter, _date, _tokenId);
	}

	function sendDiamond(address _truelove, bytes32 _registerID, string _letter, bytes16 _date, uint _tokenId) public payable sendCheck(_registerID) {
		require(_owns(msg.sender, _tokenId));
		require(now > diamonds[_tokenId].activateAt);
		
		_transfer(msg.sender, _truelove, _tokenId);
		
		diamonds[_tokenId].activateAt = now + 3 days;

		GiftSend(giftSendIndex, _truelove, msg.sender, _registerID, _letter, _date,
			GiftType.Diamond,
			diamonds[_tokenId].model,
			diamonds[_tokenId].year,
			diamonds[_tokenId].no,
			1
			);
		giftSendIndex++;
	}

	function signSendFlower(bytes32 _registerID, string _secret, string _topSecret, address _truelove, string _letter, bytes16 _date, uint _amount) external payable {
		signTruelove(_registerID, _secret, _topSecret);
		sendFlower(_truelove, _registerID, _letter, _date, _amount);
	}

	function sendFlower(address _truelove, bytes32 _registerID, string _letter, bytes16 _date, uint _amount) public payable sendCheck(_registerID) {
		require(flowerBalances[msg.sender] >= _amount);

		flowerBalances[msg.sender] -= _amount;
		flowerBalances[_truelove] += (_amount * 9 / 10);

		GiftSend(giftSendIndex, _truelove, msg.sender, _registerID, _letter, _date,
			GiftType.Flower,
			flower.model,
			flower.year,
			0,
			_amount
			);
		giftSendIndex++;
	}
}

contract TrueloveAuction is TrueloveDelivery {
	function setDiamondAuctionAddress(address _address) external onlyCEO {
		DiamondAuction candidateContract = DiamondAuction(_address);

		// NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
		require(candidateContract.isDiamondAuction());
		diamondAuction = candidateContract;
	}

	function createDiamondAuction(
		uint256 _tokenId,
		uint256 _startingPrice,
		uint256 _endingPrice,
		uint256 _duration
	)
		external
		whenNotPaused
	{
		require(_owns(msg.sender, _tokenId));
		// require(!isPregnant(_tokenId));
		_approve(_tokenId, diamondAuction);
		diamondAuction.createAuction(
			_tokenId,
			_startingPrice,
			_endingPrice,
			_duration,
			msg.sender
		);
	}

	function setFlowerAuctionAddress(address _address) external onlyCEO {
		FlowerAuction candidateContract = FlowerAuction(_address);

		// NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
		require(candidateContract.isFlowerAuction());
		flowerAuction = candidateContract;
	}

	function createFlowerAuction(
		uint256 _amount,
		uint256 _startingPrice,
		uint256 _endingPrice,
		uint256 _duration
	)
		external
		whenNotPaused
	{
		approveFlower(flowerAuction, _amount);
		flowerAuction.createAuction(
			_amount,
			_startingPrice,
			_endingPrice,
			_duration,
			msg.sender
		);
	}

	function withdrawAuctionBalances() external onlyCLevel {
		diamondAuction.withdrawBalance();
		flowerAuction.withdrawBalance();
	}
}

contract TrueloveCore is TrueloveAuction {
	address public newContractAddress;

	event Transfer(address from, address to, uint256 tokenId);
	event Approval(address owner, address approved, uint256 tokenId);

	event TransferFlower(address from, address to, uint256 value); 
	event ApprovalFlower(address owner, address spender, uint256 value);

	event GiftSend(uint indexed index, address indexed receiver, address indexed from, bytes32 registerID, string letter, bytes16 date,
		GiftType gtype,
		bytes24 model,
		uint16 year,
		uint16 no,
		uint amount
		);
		
	function TrueloveCore() public {
		paused = true;

		ceoAddress = msg.sender;
		cooAddress = msg.sender;
	}

	function setNewAddress(address _v2Address) external onlyCEO whenPaused {
    newContractAddress = _v2Address;
    ContractUpgrade(_v2Address);
  }

  function() external payable {
    require(
      msg.sender == address(diamondAuction) ||
      msg.sender == address(flowerAuction)
    );
  }
	function withdrawBalance(uint256 amount) external onlyCFO {
		cfoAddress.transfer(amount);
	}
}

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

    event AuctionCreated(uint256 indexed tokenId, address indexed seller, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 indexed tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 indexed tokenId);

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
            _auction.seller,
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
        // bool res = nftAddress.send(this.balance);
        nftAddress.send(this.balance);
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

contract DiamondAuction is ClockAuction {

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setSaleAuctionAddress() call.
    bool public isDiamondAuction = true;

    event AuctionCreated(uint256 indexed tokenId, address indexed seller, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 indexed tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 indexed tokenId);
    
    // Delegate constructor
    function DiamondAuction(address _nftAddr) public
        ClockAuction(_nftAddr, 0) {}

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
        tokenIdToAuction[_tokenId].seller;
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

}

contract FlowerAuction is Pausable {
    struct Auction {
        address seller;
        uint256 amount;
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        uint64 startedAt;
    }

    EIP20Interface public tokenContract;

    uint256 public ownerCut;

    mapping (uint256 => Auction) auctions;
    mapping (address => uint256) sellerToAuction;
    uint256 public currentAuctionId;

    event AuctionCreated(uint256 indexed auctionId, address indexed seller, uint256 amount, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 indexed auctionId, uint256 amount, address winner);
    event AuctionSoldOut(uint256 indexed auctionId);
    event AuctionCancelled(uint256 indexed auctionId);

    bytes4 constant InterfaceSignature_EIP20 = bytes4(0x98474109);

    bool public isFlowerAuction = true;

    function FlowerAuction(address _nftAddress) public {
        ownerCut = 0;

        EIP20Interface candidateContract = EIP20Interface(_nftAddress);
        require(candidateContract.supportsEIP20Interface(InterfaceSignature_EIP20));
        tokenContract = candidateContract;
    }

    function createAuction(
        uint256 _amount,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        external
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(tokenContract));
        _escrow(_seller, _amount);
        Auction memory auction = Auction(
            _seller,
            _amount,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(auction);
    }

    function bid(uint256 _auctionId, uint256 _amount)
        external
        payable
    {
        _bid(_auctionId, _amount, msg.value);
        _transfer(msg.sender, _amount);
    }




    function withdrawBalance() external {
        address nftAddress = address(tokenContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.send(this.balance);
    }


    function cancelAuction(uint256 _auctionId)
        external
    {
        Auction storage auction = auctions[_auctionId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_auctionId, seller);
    }

    function cancelAuctionWhenPaused(uint256 _auctionId)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = auctions[_auctionId];
        require(_isOnAuction(auction));
        _cancelAuction(_auctionId, auction.seller);
    }

    function getAuction(uint256 _auctionId)
        external
        view
        returns
    (
        address seller,
        uint256 amount,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = auctions[_auctionId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.amount,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    function getCurrentPrice(uint256 _auctionId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = auctions[_auctionId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }





    function _escrow(address _owner, uint256 _amount) internal {
        tokenContract.transferFromFlower(_owner, this, _amount);
    }

    function _transfer(address _receiver, uint256 _amount) internal {
        tokenContract.transferFlower(_receiver, _amount);
    }

    function _addAuction(Auction _auction) internal {
        require(_auction.duration >= 1 minutes);

        currentAuctionId++;
        auctions[currentAuctionId] = _auction;
        sellerToAuction[_auction.seller] = currentAuctionId;

        AuctionCreated(
            currentAuctionId,
            _auction.seller,
            _auction.amount,
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    function _cancelAuction(uint256 _auctionId, address _seller) internal {
        uint256 amount = auctions[_auctionId].amount;
        delete sellerToAuction[auctions[_auctionId].seller];
        delete auctions[_auctionId];
        _transfer(_seller, amount);
        AuctionCancelled(_auctionId);
    }

    function _bid(uint256 _auctionId, uint256 _amount, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        Auction storage auction = auctions[_auctionId];
        require(_isOnAuction(auction));
        uint256 price = _currentPrice(auction);
        uint256 totalPrice = price * _amount;
        require(_bidAmount >= totalPrice);
        auction.amount -= _amount;

        address seller = auction.seller;

        if (totalPrice > 0) {
            uint256 auctioneerCut = _computeCut(totalPrice);
            uint256 sellerProceeds = totalPrice - auctioneerCut;
            seller.transfer(sellerProceeds);
        }
        uint256 bidExcess = _bidAmount - totalPrice;
        msg.sender.transfer(bidExcess);

        if (auction.amount == 0) {
            AuctionSoldOut(_auctionId);
            delete auctions[_auctionId];
        } else {
            AuctionSuccessful(_auctionId, _amount, msg.sender);
        }

        return totalPrice;
    }

    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

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
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;
            return uint256(currentPrice);
        }
    }

    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }

}