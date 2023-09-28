pragma solidity ^0.4.11;

/** ************************************************************************ **/
/** ************************ Abstract CK Core ****************************** **/
/** ************************************************************************ **/

/**
 * @dev This can be exchanged for any ERC721 contract if we don't want to rely on CK.
**/
contract KittyCore {
    function ownerOf(uint256 _tokenId) external view returns (address owner);
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/** ************************************************************************ **/
/** *************************** Cuddle Data ******************************** **/ 
/** ************************************************************************ **/
    
/**
 * @dev Holds the data for all kitty actions and all kitty effects.
 * @notice TO-DO: Haven't fully converted this to a format where effects are actions!
**/
contract CuddleData is Ownable {
    // Action/Effect Id => struct for actions and for effects.
    mapping (uint256 => Action) public actions;
    // Actions specific to personality types.
    mapping (uint256 => uint256[]) typeActions;
    // Actions that any personality can have.
    uint256[] anyActions;

    // This struct used for all moves a kitty may have.
    struct Action {
        uint256 energy;
        uint8[6] basePets; // Each owner is an index that has a base amount of pets.
        uint8[6] petsAddition; // Special effects may give extra pets.
        uint16[6] critChance; // Special effects may increase (or decrease?) crit chance.
        uint8[6] missChance; // Special effects may decrease (or increase?) miss chance.
        uint256 turnsAffected; // If an effect occurrs
    }
    
/** ************************** EXTERNAL VIEW ******************************* **/
    
    /**
     * @dev Used by CuddleScience to get relevant info for a sequence of moves.
     * @param _actions The 8 length array of the move sequence.
     * @param _cuddleOwner The owner Id that we need info for.
    **/
    function returnActions(uint256[8] _actions, uint256 _cuddleOwner)
      external
      view
    returns (uint256[8] energy, uint256[8] basePets, uint256[8] petsAddition,
             uint256[8] critChance, uint256[8] missChance, uint256[8] turnsAffected)
    {
        for (uint256 i = 0; i < 8; i++) {
            if (_actions[i] == 0) break;
            
            Action memory action = actions[_actions[i]];
            energy[i] = action.energy;
            basePets[i] = action.basePets[_cuddleOwner];
            petsAddition[i] = action.petsAddition[_cuddleOwner];
            critChance[i] = action.critChance[_cuddleOwner];
            missChance[i] = action.missChance[_cuddleOwner];
            turnsAffected[i] = action.turnsAffected;
        }
    }
    
    /**
     * @NOTICE This is hardcoded for announcement until launch.
     * No point in adding actions now that are just going to be changed.
    **/
    
    /**
     * @dev Returns the amount of kitty actions available.
     * @param _personality If we want personality actions, this is the personality index
    **/
    function getActionCount(uint256 _personality)
      external
      view
    returns (uint256 totalActions)
    {
        //if (_personality > 0) totalActions = typeActions[_personality].length;
        //else totalActions = anyActions.length;
        if (_personality == 0) return 10;
        else return 5;
    }
    
/** ******************************* ONLY OWNER ***************************** **/
    
    /**
     * @dev Used by the owner to create/edit a new action that kitties may learn.
     * @param _actionId The given ID of this action.
     * @param _newEnergy The amount of energy the action will cost.
     * @param _newPets The amount of base pets each owner will give to this action.
     * @param _petAdditions The amount of additional pets each owner will give.
     * @param _critChance The crit chance this move has against each owner.
     * @param _missChance The miss chance this move has against each owner.
     * @param _turnsAffected The amount of turns an effect, if any, will be applied.
     * @param _personality The type/personality this move is specific to (0 for any).
    **/
    function addAction(uint256 _actionId, uint256 _newEnergy, uint8[6] _newPets, uint8[6] _petAdditions,
            uint16[6] _critChance, uint8[6] _missChance, uint256 _turnsAffected, uint256 _personality)
      public // This is called in prepActions down below.
      onlyOwner
    {
        Action memory newAction = Action(_newEnergy, _newPets, _petAdditions, _critChance, _missChance, _turnsAffected);
        actions[_actionId] = newAction;
        
        if (_personality > 0) typeActions[_personality].push(_actionId);
        else anyActions.push(_actionId);
    }
    
}

/** ************************************************************************* **/
/** **************************** Kitty Data ********************************* **/
/** ************************************************************************* **/

/**
 * @dev Kitty data holds the core of all data for kitties. This is the most permanent
 * @dev of all contracts in the CryptoCuddles system. As simple as possible because of that.
**/
contract KittyData is Ownable {
    address public gymContract; // Address of the gym contract.
    address public specialContract; // Address of the contract used to train special kitties.
    address public arenaContract; // Address of the arena contract.
    
    // Mapping of all kitties by CK kitty Id
    mapping (uint256 => Kitty) public kitties;
    
    // All trained kitties
    struct Kitty {
        uint8[2] kittyType; // Personality/type of the kitty.
        uint32[12] actionsArray; // Array of all moves.
        uint16 level; // Current level of the kitty.
        uint16 totalBattles; // Total battles that the kitty has "fought".
    }
    
/** ******************************* DEFAULT ******************************** **/
    
    /**
     * @param _arenaContract The address of the Arena so that it may level up kitties.
     * @param _gymContract The address of the KittyGym so that it may train kitties.
     * @param _specialContract The address of the SpecialGym so it may train specials.
    **/
    function KittyData(address _arenaContract, address _gymContract, address _specialContract)
      public
    {
        arenaContract = _arenaContract;
        gymContract = _gymContract;
        specialContract = _specialContract;
    }
    
/** ***************************** ONLY VERIFIED **************************** **/
    
    /**
     * @dev Used by KittyGym to initially add a kitty.
     * @param _kittyId Unique CK Id of kitty to be added.
     * @param _kittyType The personality type of this kitty.
     * @param _actions Array of all actions to be added to kitty.
    **/
    function addKitty(uint256 _kittyId, uint256 _kittyType, uint256[5] _actions)
      external
      onlyVerified
    returns (bool success)
    {
        delete kitties[_kittyId]; // Wipe this kitty if it's already trained.
        
        kitties[_kittyId].kittyType[0] = uint8(_kittyType);
        for (uint256 i = 0; i < 5; i++) { 
            addAction(_kittyId, _actions[i], i);
        }

        return true;
    }
    
    /**
     * @dev Give this learned kitty with a wealthy owner a degree and new graduate-specific actions.
     * @param _kittyId The unique CK Id of the kitty to graduate.
     * @param _specialId The Id of the special type that is being trained.
     * @param _actions The graduate-specific actions that are being given to this kitty.
     * @param _slots The array indices where the new actions will go.
    **/
    function trainSpecial(uint256 _kittyId, uint256 _specialId, uint256[2] _actions, uint256[2] _slots)
      external
      onlyVerified
    returns (bool success)
    {
        kitties[_kittyId].kittyType[1] = uint8(_specialId);
        addAction(_kittyId, _actions[0], _slots[0]);
        addAction(_kittyId, _actions[1], _slots[1]);
        return true;
    }

    /**
     * @dev Used internally and externally to add an action or replace an action.
     * @param _kittyId The unique CK Id of the learning kitty.
     * @param _newAction The new action to learn.
     * @param _moveSlot The kitty's actionsArray index where the move shall go.
    **/
    function addAction(uint256 _kittyId, uint256 _newAction, uint256 _moveSlot)
      public
      onlyVerified
    returns (bool success)
    {
        kitties[_kittyId].actionsArray[_moveSlot] = uint32(_newAction);
        return true;
    }
    

    /**
     * @dev Arena contract uses this on either a win or lose.
     * @param _kittyId The unique CK Id for the kitty being edited.
     * @param _won Whether or not the kitty won the battle.
    **/
    function incrementBattles(uint256 _kittyId, bool _won)
      external
      onlyVerified
    returns (bool success)
    {
        if (_won) kitties[_kittyId].level++;
        kitties[_kittyId].totalBattles++;
        return true;
    }
    
/** ****************************** CONSTANT ******************************** **/
    
    /**
     * @dev Used on KittyGym when rerolling a move to ensure validity.
     * @param _kittyId Unique CK Id of the kitty.
     * @param _moveSlot The index of the kitty's actionsArray to check.
     * @return The move that occupies the _moveSlot.
    **/
    function fetchSlot(uint256 _kittyId, uint256 _moveSlot)
      external
      view
    returns (uint32)
    {
        return kitties[_kittyId].actionsArray[_moveSlot];
    }
    
    /**
     * @dev Used by frontend to get data for a kitty.
     * @param _kittyId The unique CK Id we're querying for.
    **/
    function returnKitty(uint256 _kittyId)
      external
      view
    returns (uint8[2] kittyType, uint32[12] actionsArray, uint16 level, uint16 totalBattles)
    {
        Kitty memory kitty = kitties[_kittyId];
        kittyType = kitty.kittyType;
        actionsArray = kitty.actionsArray;
        level = kitty.level;
        totalBattles = kitty.totalBattles;
    }
    
/** ***************************** ONLY OWNER ******************************* **/
    
    /**
     * @dev Owner of this contract may change the addresses of associated contracts.
     * @param _gymContract The address of the new KittyGym contract.
     * @param _arenaContract The address of the new Arena contract.
     * @param _specialContract The address of the new SpecialGym contract.
    **/
    function changeContracts(address _gymContract, address _specialContract, address _arenaContract)
      external
      onlyOwner
    {
        if (_gymContract != 0) gymContract = _gymContract;
        if (_specialContract != 0) specialContract = _specialContract;
        if (_arenaContract != 0) arenaContract = _arenaContract;
    }
    
/** ***************************** MODIFIERS ******************************** **/
    
    /**
     * @dev Only the KittyGym and Arena contracts may make changes to KittyData!
    **/
    modifier onlyVerified()
    {
        require(msg.sender == gymContract || msg.sender == specialContract || 
                msg.sender == arenaContract);
        _;
    }
    
}

/** ************************************************************************ **/
/** **************************** Kitty Gym ********************************* **/
/** ************************************************************************ **/

/**
 * @dev Allows players to train kitties, reroll the training, or reroll specific moves.
 * @dev Also holds all specific kitty data such as their available actions (but not action data!)
**/
contract KittyGym is Ownable {
    KittyCore public core;
    CuddleData public cuddleData;
    CuddleCoin public token;
    KittyData public kittyData;
    address public specialGym;

    uint256 public totalKitties = 1; // Total amount of trained kitties.
    uint256 public personalityTypes; // Number of personality types for randomization.

    uint256 public trainFee; // In wei
    uint256 public learnFee; // In CuddleCoin wei
    uint256 public rerollFee; // In CuddleCoin wei
    
    // Unique CK Id => action Id => true if the kitty knows the action.
    mapping (uint256 => mapping (uint256 => bool)) public kittyActions;

    event KittyTrained(uint256 indexed kittyId, uint256 indexed kittyNumber,
            uint256 indexed personality, uint256[5] learnedActions);
    event MoveLearned(uint256 indexed kittyId, uint256 indexed actionId);
    event MoveRerolled(uint256 indexed kittyId, uint256 indexed oldActionId,
                        uint256 indexed newActionId);

    /**
     * @dev Initialize contract.
    **/
    function KittyGym(address _kittyCore, address _cuddleData, address _cuddleCoin, 
                    address _specialGym, address _kittyData)
      public 
    {
        core = KittyCore(_kittyCore);
        cuddleData = CuddleData(_cuddleData);
        token = CuddleCoin(_cuddleCoin);
        kittyData = KittyData(_kittyData);
        specialGym = _specialGym;
        
        trainFee = 0;
        learnFee = 1;
        rerollFee = 1;
        personalityTypes = 5;
    }

/** ***************************** EXTERNAL ********************************* **/

    /**
     * @dev The owner of a kitty may train or retrain (reset everything) a kitty here.
     * @param _kittyId ID of Kitty to train or retrain.
    **/
    function trainKitty(uint256 _kittyId)
      external
      payable
      isNotContract
    {
        // Make sure trainer owns this kitty
        require(core.ownerOf(_kittyId) == msg.sender);
        require(msg.value == trainFee);
        
        // Make sure we delete all actions if the kitty has already been trained.
        if (kittyData.fetchSlot(_kittyId, 0) > 0) {
            var (,actionsArray,,) = kittyData.returnKitty(_kittyId);
            deleteActions(_kittyId, actionsArray); // A special kitty will be thrown here.
        }

        uint256 newType = random(totalKitties * 11, 1, personalityTypes); // upper is inclusive here
        kittyActions[_kittyId][(newType * 1000) + 1] = true;
        
        uint256[2] memory newTypeActions = randomizeActions(newType, _kittyId);
        uint256[2] memory newAnyActions = randomizeActions(0, _kittyId);

        uint256[5] memory newActions;
        newActions[0] = (newType * 1000) + 1;
        newActions[1] = newTypeActions[0];
        newActions[2] = newTypeActions[1];
        newActions[3] = newAnyActions[0];
        newActions[4] = newAnyActions[1];
        
        kittyActions[_kittyId][newActions[1]] = true;
        kittyActions[_kittyId][newActions[2]] = true;
        kittyActions[_kittyId][newActions[3]] = true;
        kittyActions[_kittyId][newActions[4]] = true;
 
        assert(kittyData.addKitty(_kittyId, newType, newActions));
        KittyTrained(_kittyId, totalKitties, newType, newActions);
        totalKitties++;
        
        owner.transfer(msg.value);
    }

    /**
     * @dev May teach your kitty a new random move for a fee.
     * @param _kittyId The ID of the kitty who shall get a move added.
     * @param _moveSlot The array index that the move shall be placed in.
    **/
    function learnMove(uint256 _kittyId, uint256 _moveSlot)
      external
      isNotContract
    {
        require(msg.sender == core.ownerOf(_kittyId));
        // Burn the learning fee from the trainer's balance
        assert(token.burn(msg.sender, learnFee));
        require(kittyData.fetchSlot(_kittyId, 0) > 0); // Cannot learn without training.
        require(kittyData.fetchSlot(_kittyId, _moveSlot) == 0); // Must be put in blank spot.
        
        uint256 upper = cuddleData.getActionCount(0);
        uint256 actionId = unduplicate(_kittyId * 11, 999, upper, 0); // * 11 and 99...are arbitrary
        
        assert(!kittyActions[_kittyId][actionId]); // Throw if a new move still wasn't found.
        kittyActions[_kittyId][actionId] = true;
        
        assert(kittyData.addAction(_kittyId, actionId, _moveSlot));
        MoveLearned(_kittyId, actionId);
    }

    /**
     * @dev May reroll one kitty move. Cheaper than buying a new one.
     * @param _kittyId The kitty who needs to retrain a move slot.
     * @param _moveSlot The index of the kitty's actionsArray to replace.
     * @param _typeId The personality Id of the kity.
    **/
    function reRollMove(uint256 _kittyId, uint256 _moveSlot, uint256 _typeId)
      external
      isNotContract
    {
        require(msg.sender == core.ownerOf(_kittyId));
        
        // Make sure the old action exists and is of the correct type (purposeful underflow).
        uint256 oldAction = kittyData.fetchSlot(_kittyId, _moveSlot);
        require(oldAction > 0);
        require(oldAction - (_typeId * 1000) < 1000);
        
        // Burn the rerolling fee from the trainer's balance
        assert(token.burn(msg.sender, rerollFee));

        uint256 upper = cuddleData.getActionCount(_typeId);
        uint256 actionId = unduplicate(_kittyId, oldAction, upper, _typeId);

        assert(!kittyActions[_kittyId][actionId]); 
        kittyActions[_kittyId][oldAction] = false;
        kittyActions[_kittyId][actionId] = true;
        
        assert(kittyData.addAction(_kittyId, actionId, _moveSlot));
        MoveRerolled(_kittyId, oldAction, actionId);
    }
    
/** ******************************* INTERNAL ******************************** **/
    
    /**
     * @dev Return two actions for training or hybridizing a kitty using the given type.
     * @param _actionType The type of actions that shall be learned. 0 for "any" actions.
     * @param _kittyId The unique CK Id of the kitty.
    **/ 
    function randomizeActions(uint256 _actionType, uint256 _kittyId)
      internal
      view
    returns (uint256[2])
    {
        uint256 upper = cuddleData.getActionCount(_actionType);
        uint256 action1 = unduplicate(_kittyId, 999, upper, _actionType);
        uint256 action2 = unduplicate(_kittyId, action1, upper, _actionType);
        return [action1,action2];
    }
    
    /**
     * @dev Used when a new action is chosen but the kitty already knows it.
     * @dev If no unique actions can be found, unduplicate throws.
     * @param _kittyId The unique CK Id of the kitty.
     * @param _action1 The action that is already known.
     * @param _upper The amount of actions that can be tried.
     * @param _type The type of action that these actions are.
     * @return The new action that is not a duplicate.
    **/
    function unduplicate(uint256 _kittyId, uint256 _action1, uint256 _upper, uint256 _type)
      internal
      view
    returns (uint256 newAction)
    {
        uint256 typeBase = _type * 1000; // The base thousand for this move's type.

        for (uint256 i = 1; i < 11; i++) {
            newAction = random(i * 666, 1, _upper) + typeBase;
            if (newAction != _action1 && !kittyActions[_kittyId][newAction]) break;
        }
        
        // If the kitty still knows the move, increment till we find one it doesn't.
        if (newAction == _action1 || kittyActions[_kittyId][newAction]) {
            for (uint256 j = 1; j < _upper + 1; j++) {
                uint256 incAction = ((newAction + j) % _upper) + 1;

                incAction += typeBase;
                if (incAction != _action1 && !kittyActions[_kittyId][incAction]) {
                    newAction = incAction;
                    break;
                }
            }
        }
    }
    
    /**
     * @dev Create a random number.
     * @param _rnd Seed to help randomize.
     * @param _lower The lower bound of the random number (inclusive).
     * @param _upper The upper bound of the random number (exclusive).
    **/ 
    function random(uint256 _rnd, uint256 _lower, uint256 _upper) 
      internal
      view
    returns (uint256) 
    {
        uint256 _seed = uint256(keccak256(keccak256(_rnd, _seed), now));
        return (_seed % _upper) + _lower;
    }
    
    /**
     * @dev Used by trainKitty to delete mapping values if the kitty has already been trained.
     * @param _kittyId The unique CK Id of the kitty.
     * @param _actions The list of all actions the kitty currently has.
    **/
    function deleteActions(uint256 _kittyId, uint32[12] _actions)
      internal
    {
        for (uint256 i = 0; i < _actions.length; i++) {
            // Make sure a special kitty isn't retrained. Purposeful underflow.
            require(uint256(_actions[i]) - 50000 > 10000000);
            
            delete kittyActions[_kittyId][uint256(_actions[i])];
        }
    }
    
/** ************************* EXTERNAL CONSTANT **************************** **/
    
    /**
     * @dev Confirms whether a kitty has chosen actions.
     * @param _kittyId The id of the kitty whose actions need to be checked.
     * @param _kittyActions The actions to be checked.
    **/
    function confirmKittyActions(uint256 _kittyId, uint256[8] _kittyActions) 
      external 
      view
    returns (bool)
    {
        for (uint256 i = 0; i < 8; i++) {
            if (!kittyActions[_kittyId][_kittyActions[i]]) return false; 
        }
        return true;
    }
    
/** ************************* ONLY VERIFIED/OWNER ************************** **/
    
    /**
     * @dev Used by the SpecialGym contract when a kitty learns new special moves.
     * @param _kittyId The Id of the now special kitty!
     * @param _moves A 2-length array with the new special moves.
    **/
    function addMoves(uint256 _kittyId, uint256[2] _moves)
      external
      onlyVerified
    returns (bool success)
    {
        kittyActions[_kittyId][_moves[0]] = true;
        kittyActions[_kittyId][_moves[1]] = true;
        return true;
    }
    
    /**
     * @dev Used by owner to change all fees on KittyGym.
     * @param _trainFee The new cost (IN ETHER WEI) of training a new cat.
     * @param _learnFee The new cost (IN TOKEN WEI) of learning a new move.
     * @param _rerollFee The new cost (IN TOKEN WEI) of rerolling a move.
    **/
    function changeFees(uint256 _trainFee, uint256 _learnFee, uint256 _rerollFee)
      external
      onlyOwner
    {
        trainFee = _trainFee;
        learnFee = _learnFee;
        rerollFee = _rerollFee;
    }

    /**
     * @dev Used by owner to change the amount of actions there are.
     * @param _newTypeCount The new number of personalities there are.
    **/
    function changeVariables(uint256 _newTypeCount)
      external
      onlyOwner
    {
        if (_newTypeCount != 0) personalityTypes = _newTypeCount;
    }
    
    /**
     * @dev Owner may use to change any/every connected contract address.
     * @dev Owner may leave params as null and nothing will happen to that variable.
     * @param _newData The address of the new cuddle data contract if desired.
     * @param _newCore The address of the new CK core contract if desired.
     * @param _newToken The address of the new cuddle token if desired.
     * @param _newKittyData The address of the new KittyData contract.
     * @param _newSpecialGym The address of the new SpecialGym contract.
    **/
    function changeContracts(address _newData, address _newCore, address _newToken, address _newKittyData,
                            address _newSpecialGym)
      external
      onlyOwner
    {
        if (_newData != 0) cuddleData = CuddleData(_newData);
        if (_newCore != 0) core = KittyCore(_newCore);
        if (_newToken != 0) token = CuddleCoin(_newToken);
        if (_newKittyData != 0) kittyData = KittyData(_newKittyData);
        if (_newSpecialGym != 0) specialGym = _newSpecialGym;
    }
    
/** ***************************** MODIFIERS ******************************** **/
    
    /**
    * @dev Ensure only the arena contract can call pet count.
    **/
    modifier onlyVerified()
    {
        require(msg.sender == specialGym);
        _;
    }
    
    /**
     * @dev Ensure the sender is not a contract. This removes most of 
     * @dev the possibility of abuse of our timestamp/blockhash randomizers.
    **/ 
    modifier isNotContract() {
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size == 0);
        _;
    }
    
}

/** ************************************************************************ **/
/** **************************** Special Gym ******************************* **/
/** ************************************************************************ **/

/**
 * @dev Special Gym is used to train kitties with special
 * @dev personality types such as graduates.
**/
contract SpecialGym is Ownable {
    KittyCore public core;
    KittyData public kittyData;
    CuddleData public cuddleData;
    KittyGym public kittyGym;
    
    // Unique CK Id => true if they already have a special.
    mapping (uint256 => bool) public specialKitties;
    
    // Special personality Id => number left that may train. Graduates are Id 50.
    mapping (uint256 => SpecialPersonality) public specialInfo;
    
    struct SpecialPersonality {
        uint16 population; // Total amount of this special ever available.
        uint16 amountLeft; // The number of special personalities available to buy.
        uint256 price; // Price of this special.
    }
    
    event SpecialTrained(uint256 indexed kittyId, uint256 indexed specialId, 
        uint256 indexed specialRank, uint256[2] specialMoves);
    
    function SpecialGym(address _kittyCore, address _kittyData, address _cuddleData, address _kittyGym)
      public
    {
        core = KittyCore(_kittyCore);
        kittyData = KittyData(_kittyData);
        cuddleData = CuddleData(_cuddleData);
        kittyGym = KittyGym(_kittyGym);
    }
    
    /**
     * @dev Used to buy an exclusive special personality such as graduate.
     * @param _kittyId The unique CK Id of the kitty to train.
     * @param _specialId The Id of the special personality being trained.
     * @param _slots The two move slots where the kitty wants their new moves.
    **/
    function trainSpecial(uint256 _kittyId, uint256 _specialId, uint256[2] _slots)
      external
      payable
      isNotContract
    {
        SpecialPersonality storage special = specialInfo[_specialId];
        
        require(msg.sender == core.ownerOf(_kittyId));
        require(kittyData.fetchSlot(_kittyId, 0) > 0); // Require kitty has been trained.
        require(!specialKitties[_kittyId]);
        require(msg.value == special.price);
        require(special.amountLeft > 0);

        // Get two new random special moves.
        uint256[2] memory randomMoves = randomizeActions(_specialId);
        
        assert(kittyData.trainSpecial(_kittyId, _specialId, randomMoves, _slots));
        assert(kittyGym.addMoves(_kittyId, randomMoves));
        
        uint256 specialRank = special.population - special.amountLeft + 1;
        SpecialTrained(_kittyId, _specialId, specialRank, randomMoves);
    
        special.amountLeft--;
        specialKitties[_kittyId] = true;
        owner.transfer(msg.value);
    }
    
/** ******************************* INTERNAL ******************************* **/
    
    /**
     * @dev Return two actions for training or hybridizing a kitty using the given type.
     * @param _specialType The type of actions that shall be learned. 0 for "any" actions.
     * @return Two new special moves.
    **/ 
    function randomizeActions(uint256 _specialType)
      internal
      view
    returns (uint256[2])
    {
        uint256 upper = cuddleData.getActionCount(_specialType);
        
        uint256 action1 = random(_specialType, 1, upper);
        uint256 action2 = random(action1 + 1, 1, upper);
        if (action1 == action2) {
            action2 = unduplicate(action1, upper);
        }

        uint256 typeBase = 1000 * _specialType;
        return [action1 + typeBase, action2 + typeBase];
    }
    
    /**
     * @dev Used to make sure the kitty doesn't learn two of the same move.
     * @dev If no unique actions can be found, unduplicate throws.
     * @param _action1 The action that is already known.
     * @param _upper The amount of actions that can be tried.
     * @return The new action that is not a duplicate.
    **/
    function unduplicate(uint256 _action1, uint256 _upper)
      internal
      view
    returns (uint256)
    {
        uint256 action2;
        for (uint256 i = 1; i < 10; i++) { // Start at 1 to make sure _rnd is never 1.
            action2 = random(action2 + i, 1, _upper);
            if (action2 != _action1) break;
        }
        
        // If the kitty still knows the move, simply increment.
        if (action2 == _action1) {
            action2 = (_action1 % _upper) + 1;
        }
            
        return action2;
    }
    
    /**
     * @dev Create a random number.
     * @param _rnd Seed to help randomize.
     * @param _lower The lower bound of the random number (inclusive).
     * @param _upper The upper bound of the random number (exclusive).
     * @return Returns a fairly random number.
    **/ 
    function random(uint256 _rnd, uint256 _lower, uint256 _upper) 
      internal
      view
    returns (uint256) 
    {
        uint256 _seed = uint256(keccak256(keccak256(_rnd, _seed), now));
        return (_seed % _upper) + _lower;
    }
    
/** ******************************* CONSTANT ****************************** **/
    
    /**
     * @dev Used by frontend to get information on a special.
     * @param _specialId The unique identifier of the special personality.
    **/
    function specialsInfo(uint256 _specialId) 
      external 
      view 
    returns(uint256, uint256) 
    { 
        require(_specialId > 0); 
        return (specialInfo[_specialId].amountLeft, specialInfo[_specialId].price); 
    }
    
/** ****************************** ONLY OWNER ****************************** **/
    
    /**
     * @dev Used by owner to create and populate a new special personality.
     * @param _specialId The special's personality Id--starts at 50
     * @param _amountAvailable The maximum amount of this special that will ever be available.
     * @param _price The price that the special will be sold for.
    **/
    function addSpecial(uint256 _specialId, uint256 _amountAvailable, uint256 _price)
      external
      onlyOwner
    {
        SpecialPersonality storage special = specialInfo[_specialId];
        require(special.price == 0);
        
        special.population = uint16(_amountAvailable);
        special.amountLeft = uint16(_amountAvailable);
        special.price = _price; 
    }
    
    /**
     * @dev Used by owner to change price of a special kitty or lower available population.
     * @dev Owner may NOT increase available population to ensure their rarity to players.
     * @param _specialId The unique Id of the special to edit (graduate is 50).
     * @param _newPrice The desired new price of the special.
     * @param _amountToDestroy The amount of this special that we want to lower supply for.
    **/
    function editSpecial(uint256 _specialId, uint256 _newPrice, uint16 _amountToDestroy)
      external
      onlyOwner
    {
        SpecialPersonality storage special = specialInfo[_specialId];
        
        if (_newPrice != 0) special.price = _newPrice;
        if (_amountToDestroy != 0) {
            require(_amountToDestroy <= special.population && _amountToDestroy <= special.amountLeft);
            special.population -= _amountToDestroy;
            special.amountLeft -= _amountToDestroy;
        }
    }
    
    /**
     * @dev Owner may use to change any/every connected contract address.
     * @dev Owner may leave params as null and nothing will happen to that variable.
     * @param _newData The address of the new cuddle data contract if desired.
     * @param _newCore The address of the new CK core contract if desired.
     * @param _newKittyGym The address of the new KittyGym if desired.
     * @param _newKittyData The address of the new KittyData contract.
    **/
    function changeContracts(address _newData, address _newCore, address _newKittyData, address _newKittyGym)
      external
      onlyOwner
    {
        if (_newData != 0) cuddleData = CuddleData(_newData);
        if (_newCore != 0) core = KittyCore(_newCore);
        if (_newKittyData != 0) kittyData = KittyData(_newKittyData);
        if (_newKittyGym != 0) kittyGym = KittyGym(_newKittyGym);
    }
    
/** ****************************** MODIFIERS ******************************* **/

    /**
     * @dev Ensure the sender is not a contract. This removes most of 
     * @dev the possibility of abuse of our timestamp/blockhash randomizers.
    **/ 
    modifier isNotContract() {
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size == 0);
        _;
    }
    
}

/**
 * @title Cuddle Coin
 * @dev A very straightforward ERC20 contract that also has minting abilities
 * @dev for people to be able to win coins and purchase coins. EFFECTIVELY CENTRALIZED!
**/

contract CuddleCoin is Ownable {
    string public constant symbol = "CDL";
    string public constant name = "CuddleCoin";

    address arenaContract; // Needed for minting.
    address vendingMachine; // Needed for minting and burning.
    address kittyGym; // Needed for burning.
    
    // Storing small numbers is cheaper.
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 1000000 * (10 ** 18);

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _amount);
    event Approval(address indexed _from, address indexed _spender, uint256 indexed _amount);
    event Mint(address indexed _to, uint256 indexed _amount);
    event Burn(address indexed _from, uint256 indexed _amount);

    /**
     * @dev Set owner and beginning balance.
    **/
    function CuddleCoin(address _arenaContract, address _vendingMachine)
      public
    {
        balances[msg.sender] = _totalSupply;
        arenaContract = _arenaContract;
        vendingMachine = _vendingMachine;
    }

    /**
     * @dev Return total supply of token
    **/
    function totalSupply() 
      external
      constant 
     returns (uint256) 
    {
        return _totalSupply;
    }

    /**
     * @dev Return balance of a certain address.
     * @param _owner The address whose balance we want to check.
    **/
    function balanceOf(address _owner)
      external
      constant 
    returns (uint256) 
    {
        return balances[_owner];
    }

    /**
     * @dev Transfers coins from one address to another.
     * @param _to The recipient of the transfer amount.
     * @param _amount The amount of tokens to transfer.
    **/
    function transfer(address _to, uint256 _amount) 
      external
    returns (bool success)
    {
        // Throw if insufficient balance
        require(balances[msg.sender] >= _amount);

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        Transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev An allowed address can transfer tokens from another's address.
     * @param _from The owner of the tokens to be transferred.
     * @param _to The address to which the tokens will be transferred.
     * @param _amount The amount of tokens to be transferred.
    **/
    function transferFrom(address _from, address _to, uint _amount)
      external
    returns (bool success)
    {
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount);

        allowed[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount;
        
        Transfer(_from, _to, _amount);
        return true;
    }

    /**
     * @dev Approves a wallet to transfer tokens on one's behalf.
     * @param _spender The wallet approved to spend tokens.
     * @param _amount The amount of tokens approved to spend.
    **/
    function approve(address _spender, uint256 _amount) 
      external
    {
        require(_amount == 0 || allowed[msg.sender][_spender] == 0);
        require(balances[msg.sender] >= _amount);
        
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
    }

    /**
     * @dev Allowed amount for a user to spend of another's tokens.
     * @param _owner The owner of the tokens approved to spend.
     * @param _spender The address of the user allowed to spend the tokens.
    **/
    function allowance(address _owner, address _spender) 
      external
      constant 
    returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
    
    /**
     * @dev Used only be vending machine and arena contract to mint to
     * @dev token purchases and cuddlers in a battle.
     * @param _to The address to which coins will be minted.
     * @param _amount The amount of coins to be minted to that address.
    **/
    function mint(address _to, uint256 _amount)
      external
      onlyMinter
    returns (bool success)
    {
        balances[_to] += _amount;
        
        Mint(_to, _amount);
        return true;
    }
    
    /**
     * @dev Used by kitty gym and vending machine to take coins from users.
     * @param _from The address that will have coins burned.
     * @param _amount The amount of coins that will be burned.
    **/
    function burn(address _from, uint256 _amount)
      external
      onlyMinter
    returns (bool success)
    {
        require(balances[_from] >= _amount);
        
        balances[_from] -= _amount;
        Burn(_from, _amount);
        return true;
    }
      
    /**
     * @dev Owner my change the contracts allowed to mint.
     * @dev This gives owner full control over these tokens but since they are
     * @dev not a normal cryptocurrency, centralization is not a problem.
     * @param _arenaContract The first contract allowed to mint coins.
     * @param _vendingMachine The second contract allowed to mint coins.
    **/
    function changeMinters(address _arenaContract, address _vendingMachine, address _kittyGym)
      external
      onlyOwner
    returns (bool success)
    {
        if (_arenaContract != 0) arenaContract = _arenaContract;
        if (_vendingMachine != 0) vendingMachine = _vendingMachine;
        if (_kittyGym != 0) kittyGym = _kittyGym;
        
        return true;
    }
    
    /**
     * @dev Arena contract and vending machine contract must be able to mint coins.
     * @dev This modifier ensures no other contract may be able to mint.
     * @dev Owner can change these permissions.
    **/
    modifier onlyMinter()
    {
        require(msg.sender == arenaContract || msg.sender == vendingMachine || msg.sender == kittyGym);
        _;
    }
}