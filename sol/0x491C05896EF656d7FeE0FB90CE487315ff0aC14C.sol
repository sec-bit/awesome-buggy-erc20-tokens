pragma solidity ^0.4.11;


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


contract ERC721 {
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
}

contract GeneScienceInterface {
    function isGeneScience() public pure returns (bool);
    function mixGenes(uint256 genes1, uint256 genes2, uint256 targetBlock) public returns (uint256);
}

contract BotAccessControl {
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


contract BotBase is BotAccessControl {
    event Birth(
      address owner,
      uint256 botId,
      uint256 matronId,
      uint256 sireId,
      uint256 genes,
      uint256 birthTime
    );

    event Transfer(address from, address to, uint256 tokenId);

    struct Bot {
        uint256 genes;
        uint64 birthTime;
        uint64 cooldownEndBlock;
        uint32 matronId;
        uint32 sireId;
        uint32 siringWithId;
        uint16 cooldownIndex;
        uint16 generation;
    }

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

    uint256 public secondsPerBlock = 15;

    Bot[] bots;

    mapping (uint256 => address) public botIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public botIndexToApproved;
    mapping (uint256 => address) public sireAllowedToAddress;
    uint32 public destroyedBots;
    SaleClockAuction public saleAuction;
    SiringClockAuction public siringAuction;

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_to == address(0)) {
            delete botIndexToOwner[_tokenId];
        } else {
            ownershipTokenCount[_to]++;
            botIndexToOwner[_tokenId] = _to;
        }
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete sireAllowedToAddress[_tokenId];
            delete botIndexToApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }

    function _createBot(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
        internal
        returns (uint)
    {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));

        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Bot memory _bot = Bot({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndBlock: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: 0,
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation)
        });
        uint256 newBotId = bots.push(_bot) - 1;

        require(newBotId == uint256(uint32(newBotId)));

        Birth(
            _owner,
            newBotId,
            uint256(_bot.matronId),
            uint256(_bot.sireId),
            _bot.genes,
            uint256(_bot.birthTime)
       );

        _transfer(0, _owner, newBotId);

        return newBotId;
    }

    function _destroyBot(uint256 _botId) internal {
        require(_botId > 0);
        address from = botIndexToOwner[_botId];
        require(from != address(0));
        destroyedBots++;
        _transfer(from, 0, _botId);
    }

    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}


contract BotExtension is BotBase {
    event Lock(uint256 botId, uint16 mask);
    mapping (address => bool) extensions;
    mapping (uint256 => uint16) locks;
    uint16 constant LOCK_BREEDING = 1;
    uint16 constant LOCK_TRANSFER = 2;
    uint16 constant LOCK_ALL = LOCK_BREEDING | LOCK_TRANSFER;

    function addExtension(address _contract) external onlyCEO {
        extensions[_contract] = true;
    }

    function removeExtension(address _contract) external onlyCEO {
        delete extensions[_contract];
    }

    modifier onlyExtension() {
        require(extensions[msg.sender] == true);
        _;
    }

    function extCreateBot(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
        public
        onlyExtension
        returns (uint)
    {
        return _createBot(_matronId, _sireId, _generation, _genes, _owner);
    }

    function extDestroyBot(uint256 _botId)
        public
        onlyExtension
    {
        require(locks[_botId] == 0);

        _destroyBot(_botId);
    }

    function extLockBot(uint256 _botId, uint16 _mask)
        public
        onlyExtension
    {
        _lockBot(_botId, _mask);
    }

    function _lockBot(uint256 _botId, uint16 _mask)
        internal
    {
        require(_mask > 0);

        uint16 mask = locks[_botId];
        require(mask & _mask == 0);

        if (_mask & LOCK_BREEDING > 0) {
            Bot storage bot = bots[_botId];
            require(bot.siringWithId == 0);
        }

        if (_mask & LOCK_TRANSFER > 0) {
            address owner = botIndexToOwner[_botId];
            require(owner != address(saleAuction));
            require(owner != address(siringAuction));
        }

        mask |= _mask;

        locks[_botId] = mask;

        Lock(_botId, mask);
    }

    function extUnlockBot(uint256 _botId, uint16 _mask)
        public
        onlyExtension
        returns (uint16)
    {
        _unlockBot(_botId, _mask);
    }

    function _unlockBot(uint256 _botId, uint16 _mask)
        internal
    {
        require(_mask > 0);

        uint16 mask = locks[_botId];
        require(mask & _mask == _mask);
        mask ^= _mask;

        locks[_botId] = mask;

        Lock(_botId, mask);
    }

    function extGetLock(uint256 _botId)
        public
        view
        onlyExtension
        returns (uint16)
    {
        return locks[_botId];
    }
}


contract BotOwnership is BotExtension, ERC721 {
    string public constant name = "CryptoBots";
    string public constant symbol = "CBT";

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return botIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return botIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        botIndexToApproved[_tokenId] = _approved;
    }

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
        require(_to != address(saleAuction));
        require(_to != address(siringAuction));
        require(_owns(msg.sender, _tokenId));
        require(locks[_tokenId] & LOCK_TRANSFER == 0);
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
        require(locks[_tokenId] & LOCK_TRANSFER == 0);
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
        require(locks[_tokenId] & LOCK_TRANSFER == 0);
        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return bots.length - destroyedBots;
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = botIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalBots = bots.length - 1;
            uint256 resultIndex = 0;
            uint256 botId;
            for (botId = 0; botId <= totalBots; botId++) {
                if (botIndexToOwner[botId] == _owner) {
                    result[resultIndex] = botId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
}


contract BotBreeding is BotOwnership {
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 cooldownEndBlock);
    uint256 public autoBirthFee = 2 finney;
    uint256 public pregnantBots;
    GeneScienceInterface public geneScience;

    function setGeneScienceAddress(address _address) external onlyCEO {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);
        require(candidateContract.isGeneScience());
        geneScience = candidateContract;
    }

    function _isReadyToBreed(uint256 _botId, Bot _bot) internal view returns (bool) {
        return
            (_bot.siringWithId == 0) &&
            (_bot.cooldownEndBlock <= uint64(block.number)) &&
            (locks[_botId] & LOCK_BREEDING == 0);
    }

    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
        address matronOwner = botIndexToOwner[_matronId];
        address sireOwner = botIndexToOwner[_sireId];
        return (matronOwner == sireOwner || sireAllowedToAddress[_sireId] == matronOwner);
    }

    function _triggerCooldown(Bot storage _bot) internal {
        _bot.cooldownEndBlock = uint64((cooldowns[_bot.cooldownIndex]/secondsPerBlock) + block.number);
        if (_bot.cooldownIndex < 13) {
            _bot.cooldownIndex += 1;
        }
    }

    function approveSiring(address _addr, uint256 _sireId)
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _sireId));
        sireAllowedToAddress[_sireId] = _addr;
    }

    function setAutoBirthFee(uint256 val) external onlyCOO {
        autoBirthFee = val;
    }

    function _isReadyToGiveBirth(Bot _matron) private view returns (bool) {
        return (_matron.siringWithId != 0) && (_matron.cooldownEndBlock <= uint64(block.number));
    }

    function isReadyToBreed(uint256 _botId)
        public
        view
        returns (bool)
    {
        Bot storage bot = bots[_botId];
        return _botId > 0 && _isReadyToBreed(_botId, bot);
    }

    function isPregnant(uint256 _botId)
        public
        view
        returns (bool)
    {
        return _botId > 0 && bots[_botId].siringWithId != 0;
    }

    function _isValidMatingPair(
        Bot storage _matron,
        uint256 _matronId,
        Bot storage _sire,
        uint256 _sireId
    )
        private
        view
        returns(bool)
    {
        if (_matronId == _sireId) {
            return false;
        }
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }
        return true;
    }

    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
        internal
        view
        returns (bool)
    {
        Bot storage matron = bots[_matronId];
        Bot storage sire = bots[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

    function canBreedWith(uint256 _matronId, uint256 _sireId)
        external
        view
        returns(bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        Bot storage matron = bots[_matronId];
        Bot storage sire = bots[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
            _isSiringPermitted(_sireId, _matronId);
    }

    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
        Bot storage sire = bots[_sireId];
        Bot storage matron = bots[_matronId];
        matron.siringWithId = uint32(_sireId);
        _triggerCooldown(sire);
        _triggerCooldown(matron);
        delete sireAllowedToAddress[_matronId];
        delete sireAllowedToAddress[_sireId];
        pregnantBots++;
        Pregnant(botIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndBlock);
    }

    function breedWithAuto(uint256 _matronId, uint256 _sireId)
        external
        payable
        whenNotPaused
    {
        require(msg.value >= autoBirthFee);
        require(_owns(msg.sender, _matronId));
        require(_isSiringPermitted(_sireId, _matronId));
        Bot storage matron = bots[_matronId];
        require(_isReadyToBreed(_matronId, matron));
        Bot storage sire = bots[_sireId];
        require(_isReadyToBreed(_sireId, sire));
        require(_isValidMatingPair(
            matron,
            _matronId,
            sire,
            _sireId
        ));
        _breedWith(_matronId, _sireId);
    }

    function giveBirth(uint256 _matronId)
        external
        whenNotPaused
        returns(uint256)
    {
        Bot storage matron = bots[_matronId];
        require(matron.birthTime != 0);
        require(_isReadyToGiveBirth(matron));
        uint256 sireId = matron.siringWithId;
        Bot storage sire = bots[sireId];
        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }
        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes, matron.cooldownEndBlock - 1);
        address owner = botIndexToOwner[_matronId];
        uint256 botId = _createBot(_matronId, matron.siringWithId, parentGen + 1, childGenes, owner);
        delete matron.siringWithId;
        pregnantBots--;
        msg.sender.send(autoBirthFee);
        return botId;
    }
}


contract ClockAuctionBase {
    struct Auction {
        address seller;
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        uint64 startedAt;
    }
    ERC721 public nonFungibleContract;
    uint256 public ownerCut;
    mapping (uint256 => Auction) tokenIdToAuction;
    event AuctionCreated(
      address seller,
      uint256 tokenId,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 creationTime,
      uint256 duration
    );
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address seller, address winner, uint256 time);
    event AuctionCancelled(uint256 tokenId, address seller, uint256 time);

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        require(_auction.duration >= 1 minutes);
        tokenIdToAuction[_tokenId] = _auction;
        AuctionCreated(
            _auction.seller,
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.startedAt),
            uint256(_auction.duration)
        );
    }

    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId, _seller, uint256(now));
    }

    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);
        address seller = auction.seller;
        _removeAuction(_tokenId);
        if (price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;
            seller.transfer(sellerProceeds);
        }
        uint256 bidExcess = _bidAmount - price;
        msg.sender.transfer(bidExcess);
        AuctionSuccessful(_tokenId, price, seller, msg.sender, uint256(now));
        return price;
    }

    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
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


contract ClockAuction is Pausable, ClockAuctionBase {
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        nonFungibleContract = candidateContract;
    }

    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);
        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        bool res = nftAddress.send(this.balance);
    }

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

    function bid(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    function cancelAuction(uint256 _tokenId)
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    function cancelAuctionWhenPaused(uint256 _tokenId)
        external
        whenPaused
        onlyOwner
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

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
    )
    {
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


contract SiringClockAuction is ClockAuction {
    bool public isSiringClockAuction = true;

    function SiringClockAuction(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

    function createAuction(
        uint256 _tokenId,
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

    function bid(uint256 _tokenId)
        external
        payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        _bid(_tokenId, msg.value);
        _transfer(seller, _tokenId);
    }

}


contract SaleClockAuction is ClockAuction {
    bool public isSaleClockAuction = true;
    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;

    function SaleClockAuction(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}

    function createAuction(
        uint256 _tokenId,
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

    function bid(uint256 _tokenId)
        external
        payable
    {
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
        if (seller == address(nonFungibleContract)) {
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


contract BotAuction is BotBreeding {
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);
        require(candidateContract.isSaleClockAuction());
        saleAuction = candidateContract;
    }

    function setSiringAuctionAddress(address _address) external onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);
        require(candidateContract.isSiringClockAuction());
        siringAuction = candidateContract;
    }

    function createSaleAuction(
        uint256 _botId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _botId));
        require(!isPregnant(_botId));
        _approve(_botId, saleAuction);
        saleAuction.createAuction(
            _botId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    function createSiringAuction(
        uint256 _botId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _botId));
        require(isReadyToBreed(_botId));
        _approve(_botId, siringAuction);
        siringAuction.createAuction(
            _botId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
        external
        payable
        whenNotPaused
    {
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
    }

    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
    }
}


contract BotMinting is BotAuction {
    uint256 public constant PROMO_CREATION_LIMIT = 5000;
    uint256 public constant GEN0_CREATION_LIMIT = 45000;
    uint256 public constant GEN0_STARTING_PRICE = 10 finney;
    uint256 public constant GEN0_AUCTION_DURATION = 1 days;
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    function createPromoBot(uint256 _genes, address _owner) external onlyCOO {
        address botOwner = _owner;
        if (botOwner == address(0)) {
            botOwner = cooAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createBot(0, 0, 0, _genes, botOwner);
    }

    function createGen0Auction(uint256 _genes) external onlyCOO {
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);

        uint256 botId = _createBot(0, 0, 0, _genes, address(this));
        _approve(botId, saleAuction);

        saleAuction.createAuction(
            botId,
            _computeNextGen0Price(),
            0,
            GEN0_AUCTION_DURATION,
            address(this)
        );

        gen0CreatedCount++;
    }

    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();
        require(avePrice == uint256(uint128(avePrice)));
        uint256 nextPrice = avePrice + (avePrice / 2);
        if (nextPrice < GEN0_STARTING_PRICE) {
            nextPrice = GEN0_STARTING_PRICE;
        }
        return nextPrice;
    }
}


contract BotCore is BotMinting {
    address public newContractAddress;

    function BotCore() public {
        paused = true;
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        _createBot(0, 0, 0, uint256(-1), msg.sender);
    }

    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(siringAuction)
        );
    }

    function getBot(uint256 _id)
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
    )
    {
        require(botIndexToOwner[_id] != address(0));
        Bot storage bot = bots[_id];
        isGestating = (bot.siringWithId != 0);
        isReady = (bot.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(bot.cooldownIndex);
        nextActionAt = uint256(bot.cooldownEndBlock);
        siringWithId = uint256(bot.siringWithId);
        birthTime = uint256(bot.birthTime);
        matronId = uint256(bot.matronId);
        sireId = uint256(bot.sireId);
        generation = uint256(bot.generation);
        genes = bot.genes;
    }

    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(geneScience != address(0));
        require(newContractAddress == address(0));
        super.unpause();
    }

    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
        uint256 subtractFees = (pregnantBots + 1) * autoBirthFee;
        if (balance > subtractFees) {
            cfoAddress.send(balance - subtractFees);
        }
    }

    function destroyBot(uint256 _botId) external onlyCEO {
        require(locks[_botId] == 0);
        _destroyBot(_botId);
    }
}