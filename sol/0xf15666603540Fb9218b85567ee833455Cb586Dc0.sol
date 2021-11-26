pragma solidity ^0.4.19;

contract Card { 

    // the erc721 standard of an Ether Scrolls card
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event CardCreated(address indexed owner, uint cardNumber, uint craftedFromLeft, uint craftedFromRight);
    event Gift(uint cardId, address sender, address reciever);

    address public masterAddress1;
    address public masterAddress2;
    address public withdrawAddress;

    struct CardStructure {
        uint16[16] runes;
        uint16[16] powers;
        uint64 createdAt;
        uint64 canCraftAt;
        uint32 craftedFromLeft;
        uint32 craftedFromRight;
        uint difficulty;
        uint16 generation;
    }

    CardStructure[] allCards;

    // erc721 used to id owner
    mapping (uint => address) public indexToOwner; 

    // part of erc721. used for balanceOf
    mapping (address => uint) ownershipCount;

    // part of erc721 used for approval
    mapping (uint => address) public indexToApproved;

    function _transfer(address _from, address _to, uint _tokenId) internal {
     
        ownershipCount[_to]++;
        indexToOwner[_tokenId] = _to;
        // dont record any transfers from the contract itself
        if (_from != address(this)) {
            ownershipCount[_from]--;
        }
        Transfer(_from, _to, _tokenId);
    }
 
    modifier masterRestricted() {
        require(msg.sender == masterAddress1 || msg.sender == masterAddress2);
        _;
    }

   function getCard(uint _id) public view returns ( uint difficulty, uint canCraftAt, 
   uint createdAt, uint craftedFromLeft, uint craftedFromRight, uint generation, uint16[16] runes, uint16[16] powers,
   address owner) {
      CardStructure storage card = allCards[_id];
      difficulty = uint(card.difficulty);
      canCraftAt = uint(card.canCraftAt);
      createdAt = uint(card.createdAt);
      craftedFromLeft = uint(card.craftedFromLeft);
      craftedFromRight = uint(card.craftedFromRight);
      generation = uint(card.generation);
      runes = card.runes;
      powers = uint16[16](card.powers);
      owner = address(indexToOwner[_id]);
    }

    function _createCard(uint16[16] _runes, uint16[16] _powers, uint _craftedFromLeft, uint _craftedFromRight, uint _generation, 
    address _owner) internal returns (uint) {

        CardStructure memory card = CardStructure({
            runes: uint16[16](_runes),
            powers: uint16[16](_powers),
            createdAt: uint64(now),
            canCraftAt: 0,
            craftedFromLeft: uint32(_craftedFromLeft),
            craftedFromRight: uint32(_craftedFromRight),
            difficulty: 0,
            generation: uint16(_generation)
        });
        
        uint cardNumber = allCards.push(card) - 1;

        CardCreated(_owner, cardNumber, uint(card.craftedFromLeft), uint(card.craftedFromRight));
        _transfer(this, _owner, cardNumber);
        return cardNumber;
    }

    string public name = "EtherScrolls";
    string public symbol = "ES";

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function _owns(address _claimant, uint _tokenId) internal view returns (bool) {
        return indexToOwner[_tokenId] == _claimant;
    }

    function hasBeenApproved(address _claimant, uint _tokenId) public view returns (bool) {
        return indexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint _tokenId, address _approved) internal {
        indexToApproved[_tokenId] = _approved;
    }

    function balanceOf(address _owner) public view returns (uint count) {
        return ownershipCount[_owner];
    }

    function transfer(address _to, uint _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        require(_to != address(0));
        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _to, uint _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        _approve(_tokenId, _to);
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint _tokenId) public {
        require(_owns(_from, _tokenId));    
        require(hasBeenApproved(msg.sender, _tokenId));
        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return allCards.length - 1;
    }

    function ownerOf(uint _tokenId) public view returns (address) {
        address owner = indexToOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }
}

contract CraftingInterface {
    function craft(uint16[16] leftParentRunes, uint16[16] leftParentPowers, uint16[16] rightParentRunes, uint16[16] rightParentPowers) public view returns (uint16[16], uint16[16]);
}

contract DutchAuctionInterface {
    function DutchAuction(address etherScrollsAddressess, address _master1, address _master2) public;
    function payMasters() external;
    function isForAuction(uint card) public view returns (bool);
    function getCurrentPrice(uint cardNumber) public view returns (uint);
    function isValidAuction(uint card) public view returns (bool);
    function getAuction(uint cardNumber) public view returns(uint startingPrice, uint endingPrice, uint duration, address seller,uint startedAt );
    function getSellerOfToken(uint cardNumber) public view returns (address);
}

contract DutchAuctionToBuyInterface is DutchAuctionInterface {
    function DutchAuctionToBuy(address etherScrollsAddress, address master1, address master2) public;// DutchAuctionInterface(etherScrollsAddress, master1, master2);
    function startAuction(uint cardNumber, uint startPrice, uint endPrice, uint duration, address seller) public;
    function priceOfOfficalCardSold() public view returns (uint);
    function bidFromEtherScrolls(uint cardNumber, address buyer) public payable;
    function cancelBuyAuction(uint cardNumber, address requestor) public;
}

contract DutchAuctionToCraftInterface is DutchAuctionInterface {
    function DutchAuctionToCraft(address etherScrollsAddress, address master1, address master2) public;// DutchAuctionInterface(etherScrollsAddress, master1, master2);
    function startAuction(uint cardNumber, uint startPrice, uint endPrice, uint duration, address seller) public;
    function priceOfOfficalCardSold() public view returns (uint);
    function placeBidFromEtherScrolls(uint _tokenId) public payable;
    function cancelCraftAuction(uint cardNumber, address requestor) public;
}

contract CardMarket is Card { 

    mapping (uint => uint) public numberOfBasesSold;
    mapping (uint => uint) public numberOfAbilitiesSold;
    uint16 lastAbilityToBeAddedToCirculation;
    uint16 lastBaseToBeAddedToCirculation;
    uint16[] arrayOfPossibleBases;
    uint16[] arrayOfPossibleAbilities;
    CraftingInterface public crafting;
    uint maxRunes;
    uint numberOfSpecialCardsCreated;
     
    DutchAuctionToBuyInterface public dutchAuctionToBuy;
    DutchAuctionToCraftInterface public dutchAuctionToCraft;

    function CardMarket(address master1, address master2, address inputWithdrawAddress) public {
        
        masterAddress1 = master1;
        masterAddress2 = master2;
        withdrawAddress = inputWithdrawAddress;

        uint16[16] memory firstCard;

        _createCard(firstCard, firstCard, 0, 0, 0, master1);

        maxRunes = 300;

        arrayOfPossibleBases = [uint16(0),uint16(1),uint16(2),uint16(3),uint16(4),uint16(5),
        uint16(6),uint16(7),uint16(8),uint16(9),uint16(10),uint16(11),uint16(12),uint16(13),
        uint16(14),uint16(15),uint16(16),uint16(17),uint16(18),uint16(19)];

        lastBaseToBeAddedToCirculation = 19;

        arrayOfPossibleAbilities = [uint16(0),uint16(1),uint16(2),uint16(3),uint16(4),uint16(5),
        uint16(6),uint16(7),uint16(8),uint16(9),uint16(10),uint16(11),uint16(12),uint16(13),
        uint16(14),uint16(15),uint16(16),uint16(17),uint16(18),uint16(19)];

        lastAbilityToBeAddedToCirculation = 19;
    }

    function getBases() public view returns (uint16[]) {
        return arrayOfPossibleBases;
    }

     function getAbilities() public view returns (uint16[]) {
        return arrayOfPossibleAbilities;
    }

    // only a max of 250 Initial cards can ever be created
    function createInitialCards(uint32 count, uint16 base, uint16 ability) public masterRestricted {

        uint16[16] memory bases = [uint16(0), uint16(1), uint16(2), uint16(3), uint16(4), uint16(5),uint16(6), uint16(0),
        uint16(1), uint16(2), uint16(3),uint16(4), uint16(5),uint16(6), base, ability];
        uint16[16] memory powers = [uint16(35), uint16(20), uint16(10), uint16(5), uint16(5), uint16(5), uint16(1), uint16(35),
        uint16(21), uint16(14), uint16(10),uint16(9), uint16(8), uint16(3), uint16(9), uint16(7)];
      
        for (uint i = 0; i < count; i++) {
           
            if (base == 0) {
                bases[14] = uint16((uint(block.blockhash(block.number - i - 1)) % 20));
                bases[15] = uint16((uint(block.blockhash(block.number - i - 2)) % 20));
            }
            powers[14] = uint16((uint(block.blockhash(block.number - i - 3)) % 9) + 1);
            powers[15] = uint16((uint(block.blockhash(block.number - i - 4)) % 9) + 1);

            if (numberOfSpecialCardsCreated < 250) {
                _createCard(bases, powers, 0, 0, 0, msg.sender);
                numberOfSpecialCardsCreated++;
            }
        }
    }

    function withdraw() public {
        require(msg.sender == masterAddress1 || msg.sender == masterAddress2 || msg.sender == withdrawAddress);
        dutchAuctionToBuy.payMasters();
        dutchAuctionToCraft.payMasters();
        uint halfOfFunds = this.balance / 2;
        masterAddress1.transfer(halfOfFunds);
        masterAddress2.transfer(halfOfFunds);
    }   

    function setBuyAuctionAddress(address _address) public masterRestricted {
        dutchAuctionToBuy = DutchAuctionToBuyInterface(_address);
    }

    function setCraftAuctionAddress(address _address) public masterRestricted {
        dutchAuctionToCraft = DutchAuctionToCraftInterface(_address);
    }

    function setMasterAddress1(address _newMaster) public {
        require(msg.sender == masterAddress1);
        masterAddress1 = _newMaster;
    }

    function setMasterAddress2(address _newMaster) public {
        require(msg.sender == masterAddress2);
        masterAddress2 = _newMaster;
    }

    function cancelAuctionToBuy(uint cardId) public {
        dutchAuctionToBuy.cancelBuyAuction(cardId, msg.sender);
    }

    function cancelCraftingAuction(uint cardId) public {
        dutchAuctionToCraft.cancelCraftAuction(cardId, msg.sender);
    }

    function createDutchAuctionToBuy(uint _cardNumber, uint startPrice, 
    uint endPrice, uint _lentghOfTime) public {
        require(_lentghOfTime >= 10 minutes);
        require(dutchAuctionToBuy.isForAuction(_cardNumber) == false);
        require(dutchAuctionToCraft.isForAuction(_cardNumber) == false);
        require(_owns(msg.sender, _cardNumber));
        _approve(_cardNumber, dutchAuctionToBuy);
        dutchAuctionToBuy.startAuction(_cardNumber, startPrice, endPrice, _lentghOfTime, msg.sender);
    }

    function startCraftingAuction(uint _cardNumber, uint startPrice, uint endPrice,
    uint _lentghOfTime) public {
        require(_lentghOfTime >= 1 minutes);
        require(_owns(msg.sender, _cardNumber));
        CardStructure storage card = allCards[_cardNumber];
        require(card.canCraftAt <= now);
        require(dutchAuctionToBuy.isForAuction(_cardNumber) == false);
        require(dutchAuctionToCraft.isForAuction(_cardNumber) == false);
        _approve(_cardNumber, dutchAuctionToCraft);
        dutchAuctionToCraft.startAuction(_cardNumber, startPrice, endPrice, _lentghOfTime, msg.sender);
    }

      // craft two cards. you will get a new card. 
    function craftTwoCards(uint _craftedFromLeft, uint _craftedFromRight) public {
        require(_owns(msg.sender, _craftedFromLeft));
        require(_owns(msg.sender, _craftedFromRight));
        // make sure that the card that will produce a new card is not up for auction
        require((isOnAuctionToBuy(_craftedFromLeft) == false) && (isOnCraftingAuction(_craftedFromLeft) == false));
        require(_craftedFromLeft != _craftedFromRight);
        CardStructure storage leftCard = allCards[_craftedFromLeft];
        CardStructure storage rightCard = allCards[_craftedFromRight];
        require(leftCard.canCraftAt <= now);
        require(rightCard.canCraftAt <= now);
        spawnCard(_craftedFromLeft, _craftedFromRight);
    }

    function isOnCraftingAuction(uint cardNumber) public view returns (bool) {
        return (dutchAuctionToCraft.isForAuction(cardNumber) && dutchAuctionToCraft.isValidAuction(cardNumber));
    }

    function isOnAuctionToBuy(uint cardNumber) public view returns (bool) {
        return (dutchAuctionToBuy.isForAuction(cardNumber) && dutchAuctionToBuy.isValidAuction(cardNumber));
    }

    function getCardBuyAuction(uint cardNumber) public view returns( uint startingPrice, uint endPrice, uint duration, address seller,
    uint startedAt ) {
        return dutchAuctionToBuy.getAuction(cardNumber);
    }

    function getCraftingAuction(uint cardNumber) public view returns(uint startingPrice, uint endPrice, uint duration, address seller, 
    uint startedAt ) {
        return dutchAuctionToCraft.getAuction(cardNumber);
    }
    
    function getActualPriceOfCardOnBuyAuction (uint cardNumber) public view returns (uint) {
        return dutchAuctionToBuy.getCurrentPrice(cardNumber);
    }

    function getActualPriceOfCardOnCraftAuction (uint cardNumber) public view returns (uint) {
        return dutchAuctionToCraft.getCurrentPrice(cardNumber);
    }

    function setCraftingAddress(address _address) public masterRestricted {
        CraftingInterface candidateContract = CraftingInterface(_address);
        crafting = candidateContract;
    }

    function getDutchAuctionToCraftAddress() public view returns (address) {
        return address(dutchAuctionToCraft);
    }

     function getDutchAuctionToBuyAddress() public view returns (address) {
        return address(dutchAuctionToBuy);
    }

    function _startCraftRecovery(CardStructure storage card) internal {

        uint base = card.generation + card.difficulty + 1;
        if (base < 6) {
            base = base * (1 minutes);
        } else if ( base < 11) {
            base = (base - 5) * (1 hours);
        } else {
            base = (base - 10) * (1 days);
        }
        base = base * 2;
        
        card.canCraftAt = uint64(now + base);

        if (card.difficulty < 15) {
            card.difficulty++;
        }
    }

     function bidOnCraftAuction(uint cardIdToBidOn, uint cardIdToCraftWith) public payable {
        require(_owns(msg.sender, cardIdToCraftWith));
        CardStructure storage cardToBidOn = allCards[cardIdToBidOn];
        CardStructure storage cardToCraftWith = allCards[cardIdToCraftWith];
        require(cardToCraftWith.canCraftAt <= now);
        require(cardToBidOn.canCraftAt <= now);
        require(cardIdToBidOn != cardIdToCraftWith);
        uint bidAmount = msg.value;
        // the bid funciton ensures that the seller acutally owns the card being sold
        dutchAuctionToCraft.placeBidFromEtherScrolls.value(bidAmount)(cardIdToBidOn);
        spawnCard(cardIdToCraftWith, cardIdToBidOn);
    }
    
    function spawnCard(uint _craftedFromLeft, uint _craftedFromRight) internal returns(uint) {
        CardStructure storage leftCard = allCards[_craftedFromLeft];
        CardStructure storage rightCard = allCards[_craftedFromRight];

        _startCraftRecovery(rightCard);
        _startCraftRecovery(leftCard);

        uint16 parentGen = leftCard.generation;
        if (rightCard.generation > leftCard.generation) {
            parentGen = rightCard.generation;
        }

        parentGen += 1;
        if (parentGen > 18) {
            parentGen = 18;
        }

        uint16[16] memory runes;
        uint16[16] memory powers;

        (runes, powers) = crafting.craft(leftCard.runes, leftCard.powers, rightCard.runes, rightCard.powers);
        address owner = indexToOwner[_craftedFromLeft];
      
        return _createCard(runes, powers, _craftedFromLeft, _craftedFromRight, parentGen, owner);
    }

    function() external payable {}

    function bidOnAuctionToBuy(uint cardNumber) public payable {
        address seller = dutchAuctionToBuy.getSellerOfToken(cardNumber);
        // make sure that the seller still owns the card
        uint bidAmount = msg.value;
        dutchAuctionToBuy.bidFromEtherScrolls.value(bidAmount)(cardNumber, msg.sender);
        // if a zero generation card was just bought
        if (seller == address(this)) {
            spawnNewZeroCardInternal();
        }
    }

    // 250 is the max number of cards that the developers are allowed to print themselves
    function spawnNewZeroCard() public masterRestricted {
        if (numberOfSpecialCardsCreated < 250) {
            spawnNewZeroCardInternal();
            numberOfSpecialCardsCreated++;
        }
    }

    function spawnNewZeroCardInternal() internal {

        uint16[16] memory runes = generateRunes();
        uint16 x = uint16(uint(block.blockhash(block.number - 1)) % 9) + 1;
        uint16 y = uint16(uint(block.blockhash(block.number - 2)) % 9) + 1;
    
        uint16[16] memory powers = [uint16(25), uint16(10), uint16(5), uint16(0), uint16(0), uint16(0), uint16(0),
                                uint16(25), uint16(10), uint16(5), uint16(0), uint16(0), uint16(0), uint16(0), x, y];
        
        uint cardNumber = _createCard(runes, powers, 0, 0, 0, address(this));

        _approve(cardNumber, dutchAuctionToBuy);

        uint price = dutchAuctionToBuy.priceOfOfficalCardSold() * 2;
        // 11000000000000000 wei is .011 eth
        if (price < 11000000000000000 ) {
            price = 11000000000000000;
        }

        dutchAuctionToBuy.startAuction(cardNumber, price, 0, 2 days, address(this));

    }

    function giftCard(uint cardId, address reciever) public {
        require((isOnAuctionToBuy(cardId) == false) && (isOnCraftingAuction(cardId) == false));
        require(ownerOf(cardId) == msg.sender);
        transfer(reciever, cardId);
        Gift(cardId, msg.sender, reciever);
    }

    function generateRunes() internal returns (uint16[16]) {
        
        uint i = 1;
        uint lastBaseIndex = arrayOfPossibleBases.length;
        uint16 base1 = uint16(uint(block.blockhash(block.number - i)) % lastBaseIndex); 
        i++;
        uint16 base2 = uint16(uint(block.blockhash(block.number - i)) % lastBaseIndex);
        i++;
        uint16 base3 = uint16(uint(block.blockhash(block.number - i)) % lastBaseIndex);
        i++;
        
        // ensure that each rune is distinct
        while (base1 == base2 || base2 == base3 || base3 == base1) {
            base1 = uint16(uint(block.blockhash(block.number - i)) % lastBaseIndex);
            i++;
            base2 = uint16(uint(block.blockhash(block.number - i)) % lastBaseIndex);
            i++;
            base3 = uint16(uint(block.blockhash(block.number - i)) % lastBaseIndex);
            i++;
        }
        
        base1 = arrayOfPossibleBases[base1];
        base2 = arrayOfPossibleBases[base2];
        base3 = arrayOfPossibleBases[base3];

        uint lastAbilityIndex = arrayOfPossibleAbilities.length;
        uint16 ability1 = uint16(uint(block.blockhash(block.number - i)) % lastAbilityIndex);
        i++;
        uint16 ability2 = uint16(uint(block.blockhash(block.number - i)) % lastAbilityIndex);
        i++;
        uint16 ability3 = uint16(uint(block.blockhash(block.number - i)) % lastAbilityIndex);
        i++;

        // ensure that each rune is distinct
        while (ability1 == ability2 || ability2 == ability3 || ability3 == ability1) {
            ability1 = uint16(uint(block.blockhash(block.number - i)) % lastAbilityIndex);
            i++;
            ability2 = uint16(uint(block.blockhash(block.number - i)) % lastAbilityIndex);
            i++;
            ability3 = uint16(uint(block.blockhash(block.number - i)) % lastAbilityIndex);
            i++;
        }
        
        ability1 = arrayOfPossibleAbilities[ability1];
        ability2 = arrayOfPossibleAbilities[ability2];
        ability3 = arrayOfPossibleAbilities[ability3];

        numberOfBasesSold[base1]++;
        numberOfAbilitiesSold[ability1]++;

        // if we have reached the max number of runes
        if (numberOfBasesSold[base1] > maxRunes) {
            // remove the rune from the list of possible runes
            for (i = 0; i < arrayOfPossibleBases.length; i++ ) {
                if (arrayOfPossibleBases[i] == base1) {
                // add a new rune to the list
                // we dont need a check here to see if lastBaseCardToBeAddedToCirculation overflows because
                // the 50k max card limit will expire well before this limit is reached
                lastBaseToBeAddedToCirculation++;
                arrayOfPossibleBases[i] = lastBaseToBeAddedToCirculation;
                break;
                }
            }
        }

        if (numberOfAbilitiesSold[ability1] > maxRunes) {
            // remove the rune from the list of possible runes
            for (i = 0; i < arrayOfPossibleAbilities.length; i++) {
                if (arrayOfPossibleAbilities[i] == ability1) {
                // we dont need to check for overflow here because of the 300 rune limits
                lastAbilityToBeAddedToCirculation++;
                arrayOfPossibleAbilities[i] = lastAbilityToBeAddedToCirculation;
                break;
                }
            }
        }

        return [base1, base2, base3, uint16(0), uint16(0), uint16(0), uint16(0), 
                ability1, ability2, ability3, uint16(0), uint16(0), uint16(0), uint16(0),  base1, ability1];
    }
}

contract EtherScrolls is CardMarket {
    
    function EtherScrolls(address master1, address master2, address withdrawAddress) public CardMarket(master1, master2, withdrawAddress) {}

}