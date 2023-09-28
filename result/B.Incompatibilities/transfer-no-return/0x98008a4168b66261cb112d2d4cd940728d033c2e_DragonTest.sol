contract Ownable {
  address public contractOwner;

  function Ownable() {
    contractOwner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == contractOwner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      contractOwner = newOwner;
    }
  }
}

contract ERC721 {
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address tokenOwner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address tokenOwner, address approved, uint256 tokenId);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract DragonBase is Ownable {
    event Birth(address tokenOwner, uint256 dragonId);
    event Transfer(address from, address to, uint256 tokenId);

    struct Dragon {
      // uint256 genes; TODO
      // string name; TODO
      uint8 attack;
      uint8 defence;
      uint8 color;
      uint8 bodyType;
      uint8 eyesType;
      uint8 mouthType;
      uint8 hornsType;
      uint8 wingsType;
      uint16 health;
      uint256 price;

      uint256 points;
    }

    Dragon[] dragons;

    uint256 dragonsOnSaleCount = 0;

    mapping (uint256 => address) public dragonIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public dragonIndexToApproved;

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        dragonIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete dragonIndexToApproved[_tokenId];
        }

        Transfer(_from, _to, _tokenId);
    }

    function _createDragon (
        uint8 _attack,
        uint8 _defence,
        uint8 _color,
        uint8 _bodyType,
        uint8 _eyesType,
        uint8 _mouthType,
        uint8 _hornsType,
        uint8 _wingsType,
        uint16 _health,
        uint256 _price
      ) internal returns (uint) {
        Dragon memory _dragon = Dragon({
          attack: _attack,
          defence: _defence,
          color: _color,
          bodyType: _bodyType,
          eyesType: _eyesType,
          mouthType: _mouthType,
          hornsType: _hornsType,
          wingsType: _wingsType,
          health: _health,
          price: _price,
          points: 0
        });

        uint256 newDragonId = dragons.push(_dragon) - 1;

        require(newDragonId == uint256(uint32(newDragonId)));

        dragonsOnSaleCount++;

        return newDragonId;
    }
}

contract ERC721Metadata {
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


contract DragonOwnership is DragonBase, ERC721 {
    string public constant name = "DragonBit";
    string public constant symbol = "DB";
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

    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    function setMetadataAddress(address _contractAddress) public onlyOwner {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return dragonIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return dragonIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        dragonIndexToApproved[_tokenId] = _approved;
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_owns(msg.sender, _tokenId));
        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(
        address _to,
        uint256 _tokenId
    )
        external
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
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return dragons.length;
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address tokenOwner)
    {
        tokenOwner = dragonIndexToOwner[_tokenId];

        require(tokenOwner != address(0));
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalDragons = totalSupply();
            uint256 resultIndex = 0;
            uint256 dragonId;

            for (dragonId = 0; dragonId < totalDragons; dragonId++) {
                if (_owns(_owner, dragonId)) {
                    result[resultIndex] = dragonId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function tokensOnSale() external view returns(uint256[] availableTokens) {
        if (dragonsOnSaleCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](dragonsOnSaleCount);
            uint256 totalDragons = totalSupply();
            uint256 resultIndex = 0;
            uint256 dragonId;

            for (dragonId = 0; dragonId < totalDragons; dragonId++) {
                if (_owns(address(0), dragonId)) {
                    result[resultIndex] = dragonId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function tokensForFight() external view returns(uint256[] availableTokens) {
        uint256 dragonsForFightCount = dragons.length - dragonsOnSaleCount - ownershipTokenCount[msg.sender];

        if (dragonsForFightCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](dragonsForFightCount);
            uint256 totalDragons = totalSupply();
            uint256 resultIndex = 0;
            uint256 dragonId;

            for (dragonId = 0; dragonId < totalDragons; dragonId++) {
                if (!_owns(address(0), dragonId) && !_owns(address(msg.sender), dragonId)) {
                    result[resultIndex] = dragonId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function _memcpy(uint _dest, uint _src, uint _len) private view {
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

    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
    }
}

contract DragonCore is DragonOwnership {
    function getDragon(uint256 _id)
        external
        view
        returns (
          uint8 attack,
          uint8 defence,
          uint8 color,
          uint8 bodyType,
          uint8 eyesType,
          uint8 mouthType,
          uint8 hornsType,
          uint8 wingsType,
          uint16 health,
          uint256 price,
          uint256 points
    ) {
        Dragon memory d = dragons[_id];

        attack = d.attack;
        defence = d.defence;
        color = d.color;
        bodyType = d.bodyType;
        eyesType = d.eyesType;
        mouthType = d.mouthType;
        hornsType = d.hornsType;
        wingsType = d.wingsType;
        health = d.health;
        price = d.price;
        points = d.points;
    }

    function createDragon(
        uint8 _attack,
        uint8 _defence,
        uint8 _color,
        uint8 _bodyType,
        uint8 _eyesType,
        uint8 _mouthType,
        uint8 _hornsType,
        uint8 _wingsType,
        uint16 _health,
        uint16 _price
      ) external onlyOwner returns (uint) {
        return _createDragon(
          _attack,
          _defence,
          _color,
          _bodyType,
          _eyesType,
          _mouthType,
          _hornsType,
          _wingsType,
          _health,
          _price
        );
    }

    function buyDragon(uint256 _id) payable {
      Dragon memory d = dragons[_id];
      address dragonOwner = dragonIndexToOwner[_id];

      require(dragonOwner == address(0));
      require(msg.value >= d.price);

      Birth(msg.sender, _id);

      dragonsOnSaleCount--;

      _transfer(0, msg.sender, _id);
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = this.balance;
        contractOwner.transfer(balance);
    }
}

contract Random {
  uint64 _seed = 0;

  // return a pseudo random number between lower and upper bounds
  // given the number of previous blocks it should hash.
  function random(uint64 upper, uint8 step) public returns (uint64 randomNumber) {
    _seed = uint64(keccak256(keccak256(block.blockhash(block.number - step), _seed), now));

    return _seed % upper;
  }
}

contract DragonFight is DragonCore, Random {

    event Fight(uint256 _ownerDragonId,
                uint256 _opponentDragonId,
                bool firstAttack,
                bool secondAttack);

    function fight(uint256 _ownerDragonId, uint256 _opponentDragonId) external returns(
        bool attack1,
        bool attack2,
        bool attack3,
        bool attack4
      ) {
        require(_owns(msg.sender, _ownerDragonId));
        require(!_owns(msg.sender, _opponentDragonId));
        require(!_owns(address(0), _opponentDragonId));

        Dragon memory ownerDragon = dragons[_ownerDragonId];
        Dragon memory opponentDragon = dragons[_opponentDragonId];

        attack1 = _randomAttack(ownerDragon.attack, opponentDragon.defence, 1);
        attack2 = _randomAttack(ownerDragon.defence, opponentDragon.attack, 2);
        attack3 = _randomAttack(ownerDragon.attack, opponentDragon.defence, 3);
        attack4 = _randomAttack(ownerDragon.defence, opponentDragon.attack, 4);

        uint8 points = (attack1 ? 1 : 0) + (attack2 ? 1 : 0) + (attack3 ? 1 : 0) + (attack4 ? 1 : 0);

        ownerDragon.points += points;

        Fight(_ownerDragonId, _opponentDragonId, attack1, attack2);
    }

    function _randomAttack(uint8 _ownerDragonAmount, uint8 _opponentDragonAmount, uint8 _step) private
    returns(bool result) {
        uint64 ownerValue = random(uint64(_ownerDragonAmount), _step);
        uint64 opponentValue = random(uint64(_opponentDragonAmount), _step);

        return ownerValue > opponentValue;
    }
}

contract DragonTest is DragonFight {

    function createTestData() public onlyOwner {
        // 0.001 eth
        uint256 price = 1000000000000000;

        uint newDragon1Id = _createDragon(1, 2, 1, 1, 1, 1, 1, 1, 1, price);
        _transfer(0, msg.sender, newDragon1Id);
        dragonsOnSaleCount--;

        uint newDragon2Id = _createDragon(2, 6, 2, 2, 2, 2, 2, 2, 2, price);
        _transfer(0, msg.sender, newDragon2Id);
        dragonsOnSaleCount--;

        // Free dragons
        _createDragon(3, 2, 3, 3, 3, 1, 3, 3, 3, price);
        _createDragon(4, 4, 4, 4, 2, 2, 2, 4, 4, price);
    }
}