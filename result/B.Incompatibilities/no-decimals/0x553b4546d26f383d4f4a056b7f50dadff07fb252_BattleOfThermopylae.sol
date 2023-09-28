/*******************************************************************************
*********************    BATTLE OF THERMOPYLAE v1.1  ***************************
********************************************************************************

Battle smart contract is a platform/ecosystem for gaming built on top of a
decentralized smart contract, allowing anyone to use a Warrior tokens: entities
which exists on the Ethereum Network, which can be traded or used to enter the
battle with other Warrior tokens holders, for profit or just for fun!

********************************************************************************
**************************           RULES           ***************************
********************************************************************************

- This first battle contract accepts Persians, Spartans (300 Tokens), Immortals
  and Athenians as warriors.
- Every warrior token has a proper value in **Battle Point (BP)** that represent
  his strength on the battle contract.
- Persians and Immortals represent the Persian faction, Spartans and Athenians
  the Greek one.
- During the first phase players send tokens to the battle contract
  (NOTE: before calling the proper contract's function that assigning warriors
  to the battlefiled, players NEED TO CALL APPROVE on their token contract to
  allow Battle contract to move their tokens.
- Once sent, troops can't be retired form the battlefield
- The battle will last for several days
- When the battle period is over, following results can happpen:
    -- When the battle ends in a draw:
        (*) 10% of main troops of both sides lie on the ground
        (*) 90% of them can be retrieved by each former owner
        (*) No slaves are assigned
    -- When the battle ends with a winning factions:
        (*) 10% of main troops of both sides lie on the ground
        (*) 90% of them can be retrieved by each former owner
        (*) Surviving warriors of the loosing faction are assigned as slaves
            to winners
        (*) Slaves are computed based on the BP contributed by each sender
- Persians and Spartans are main troops.
- Immortals and Athenians are support troops: there will be no casualties in
  their row, and they will be retrieved without losses by original senders.
- Only Persians and Spartans can be slaves. Immortals and Athenians WILL NOT
  be sent back as slaves to winners.

********************************************************************************
**************************      TOKEN ADDRESSES      ***************************
********************************************************************************

        Persians    (PRS)   0x163733bcc28dbf26B41a8CfA83e369b5B3af741b
        Immortals   (IMT)   0x22E5F62D0FA19974749faa194e3d3eF6d89c08d7
        Spartans    (300)   0xaEc98A708810414878c3BCDF46Aad31dEd4a4557
        Athenians   (ATH)   0x17052d51E954592C1046320c2371AbaB6C73Ef10
        Battles     (BTL)   Set after the deployment of this contract

*******************************************************************************/
pragma solidity ^0.4.15;

contract TokenEIP20 {

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

contract Timed {
    
    uint256 public startTime;           //seconds since Unix epoch time
    uint256 public endTime;             //seconds since Unix epoch time
    uint256 public avarageBlockTime;    //seconds

    // This check is an helper function for ÐApp to check the effect of the NEXT transaction, NOT simply the current state of the contract
    function isInTime() constant returns (bool inTime) {
        return block.timestamp >= (startTime - avarageBlockTime) && !isTimeExpired();
    }

    // This check is an helper function for ÐApp to check the effect of the NEXT transacion, NOT simply the current state of the contract
    function isTimeExpired() constant returns (bool timeExpired) {
        return block.timestamp + avarageBlockTime >= endTime;
    }

    modifier onlyIfInTime {
        require(block.timestamp >= startTime && block.timestamp <= endTime); _;
    }

    modifier onlyIfTimePassed {
        require(block.timestamp > endTime); _;
    }

    function Timed(uint256 _startTime, uint256 life, uint8 _avarageBlockTime) {
        startTime = _startTime;
        endTime = _startTime + life;
        avarageBlockTime = _avarageBlockTime;
    }
}

library SafeMathLib {

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function add(uint x, uint y) internal returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal returns (uint z) {
        require((z = x - y) <= x);
    }

    function mul(uint x, uint y) internal returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function per(uint x, uint y) internal constant returns (uint z) {
        return mul((x / 100), y);
    }

    function min(uint x, uint y) internal returns (uint z) {
        return x <= y ? x : y;
    }

    function max(uint x, uint y) internal returns (uint z) {
        return x >= y ? x : y;
    }

    function imin(int x, int y) internal returns (int z) {
        return x <= y ? x : y;
    }

    function imax(int x, int y) internal returns (int z) {
        return x >= y ? x : y;
    }

    function wmul(uint x, uint y) internal returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint x, uint y) internal returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint x, uint y) internal returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint x, uint y) internal returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wper(uint x, uint y) internal constant returns (uint z) {
        return wmul(wdiv(x, 100), y);
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

}

contract Owned {

    address owner;
    
    function Owned() { owner = msg.sender; }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Upgradable is Owned {

    string  public VERSION;
    bool    public deprecated;
    string  public newVersion;
    address public newAddress;

    function Upgradable(string _version) {
        VERSION = _version;
    }

    function setDeprecated(string _newVersion, address _newAddress) onlyOwner returns (bool success) {
        require(!deprecated);
        deprecated = true;
        newVersion = _newVersion;
        newAddress = _newAddress;
        return true;
    }
}

contract BattleOfThermopylae is Timed, Upgradable {
    using SafeMathLib for uint;
  
    uint    public constant MAX_PERSIANS            = 300000 * 10**18;  // 300.000
    uint    public constant MAX_SPARTANS            = 300 * 10**18;     // 300
    uint    public constant MAX_IMMORTALS           = 100;              // 100
    uint    public constant MAX_ATHENIANS           = 100 * 10**18;     // 100

    uint8   public constant BP_PERSIAN              = 1;                // Each Persian worths 1 Battle Point
    uint8   public constant BP_IMMORTAL             = 100;              // Each Immortal worths 100 Battle Points
    uint16  public constant BP_SPARTAN              = 1000;             // Each Spartan worths 1000 Battle Points
    uint8   public constant BP_ATHENIAN             = 100;              // Each Athenians worths 100 Battle Points

    uint8   public constant BTL_PERSIAN              = 1;               // Each Persian worths 1 Battle Token
    uint16  public constant BTL_IMMORTAL             = 2000;            // Each Immortal worths 2000 Battle Tokens
    uint16  public constant BTL_SPARTAN              = 1000;            // Each Spartan worths 1000 Battle Tokens
    uint16  public constant BTL_ATHENIAN             = 2000;            // Each Athenians worths 2000 Battle Tokens

    uint    public constant WAD                     = 10**18;           // Shortcut for 1.000.000.000.000.000.000
    uint8   public constant BATTLE_POINT_DECIMALS   = 18;               // Battle points decimal positions
    uint8   public constant BATTLE_CASUALTIES       = 10;               // Percentage of Persian and Spartan casualties
    
    address public persians;                                            // Address of the Persian Tokens
    address public immortals;                                           // Address of the Immortal Tokens
    address public spartans;                                            // Address of the 300 Tokens
    address public athenians;                                           // Address of the Athenian Tokens
    address public battles;                                             // Address of the Battle Tokens
    address public battlesOwner;                                        // Owner of the Battle Token contract

    mapping (address => mapping (address => uint))   public  warriorsByPlayer;               // Troops currently allocated by each player
    mapping (address => uint)                        public  warriorsOnTheBattlefield;       // Total troops fighting in the battle

    event WarriorsAssignedToBattlefield (address indexed _from, address _faction, uint _battlePointsIncrementForecast);
    event WarriorsBackToHome            (address indexed _to, address _faction, uint _survivedWarriors);

    function BattleOfThermopylae(uint _startTime, uint _life, uint8 _avarageBlockTime, address _persians, address _immortals, address _spartans, address _athenians) Timed(_startTime, _life, _avarageBlockTime) Upgradable("1.0.0") {
        persians = _persians;
        immortals = _immortals;
        spartans = _spartans;
        athenians = _athenians;
    }

    function setBattleTokenAddress(address _battleTokenAddress, address _battleTokenOwner) onlyOwner {
        battles = _battleTokenAddress;
        battlesOwner = _battleTokenOwner;
    }

    function assignPersiansToBattle(uint _warriors) onlyIfInTime external returns (bool success) {
        assignWarriorsToBattle(msg.sender, persians, _warriors, MAX_PERSIANS);
        sendBattleTokens(msg.sender, _warriors.mul(BTL_PERSIAN));
        // Persians are divisible with 18 decimals and their value is 1 BP
        WarriorsAssignedToBattlefield(msg.sender, persians, _warriors / WAD);
        return true;
    }

    function assignImmortalsToBattle(uint _warriors) onlyIfInTime external returns (bool success) {
        assignWarriorsToBattle(msg.sender, immortals, _warriors, MAX_IMMORTALS);
        sendBattleTokens(msg.sender, _warriors.mul(WAD).mul(BTL_IMMORTAL));
        // Immortals are not divisible and their value is 100 BP
        WarriorsAssignedToBattlefield(msg.sender, immortals, _warriors.mul(BP_IMMORTAL));
        return true;
    }

    function assignSpartansToBattle(uint _warriors) onlyIfInTime external returns (bool success) {
        assignWarriorsToBattle(msg.sender, spartans, _warriors, MAX_SPARTANS);
        sendBattleTokens(msg.sender, _warriors.mul(BTL_SPARTAN));
        // Spartans are divisible with 18 decimals and their value is 1.000 BP
        WarriorsAssignedToBattlefield(msg.sender, spartans, (_warriors / WAD).mul(BP_SPARTAN));
        return true;
    }

    function assignAtheniansToBattle(uint _warriors) onlyIfInTime external returns (bool success) {
        assignWarriorsToBattle(msg.sender, athenians, _warriors, MAX_ATHENIANS);
        sendBattleTokens(msg.sender, _warriors.mul(BTL_ATHENIAN));
        // Athenians are divisible with 18 decimals and their value is 100 BP
        WarriorsAssignedToBattlefield(msg.sender, athenians, (_warriors / WAD).mul(BP_ATHENIAN));
        return true;
    }

    function redeemWarriors() onlyIfTimePassed external returns (bool success) {
        if (getPersiansBattlePoints() > getGreeksBattlePoints()) {
            // Persians won, compute slaves
            uint spartanSlaves = computeSlaves(msg.sender, spartans);
            if (spartanSlaves > 0) {
                // Send back Spartan slaves to winner
                sendWarriors(msg.sender, spartans, spartanSlaves);
            }
            // Send back Persians but casualties
            retrieveWarriors(msg.sender, persians, BATTLE_CASUALTIES);
        } else if (getPersiansBattlePoints() < getGreeksBattlePoints()) {
            //Greeks won, send back Persian slaves
            uint persianSlaves = computeSlaves(msg.sender, persians);
            if (persianSlaves > 0) {
                // Send back Persians slaves to winner
                sendWarriors(msg.sender, persians, persianSlaves);                
            }
            // Send back Spartans but casualties
            retrieveWarriors(msg.sender, spartans, BATTLE_CASUALTIES);
        } else {
            // It's a draw, send back Persians and Spartans but casualties
            retrieveWarriors(msg.sender, persians, BATTLE_CASUALTIES);
            retrieveWarriors(msg.sender, spartans, BATTLE_CASUALTIES);
        }
        // Send back Immortals untouched
        retrieveWarriors(msg.sender, immortals, 0);
        // Send back Athenians untouched
        retrieveWarriors(msg.sender, athenians, 0);
        return true;
    }

    function assignWarriorsToBattle(address _player, address _faction, uint _warriors, uint _maxWarriors) private {
        require(warriorsOnTheBattlefield[_faction].add(_warriors) <= _maxWarriors);
        require(TokenEIP20(_faction).transferFrom(_player, address(this), _warriors));
        warriorsByPlayer[_player][_faction] = warriorsByPlayer[_player][_faction].add(_warriors);
        warriorsOnTheBattlefield[_faction] = warriorsOnTheBattlefield[_faction].add(_warriors);
    }

    function retrieveWarriors(address _player, address _faction, uint8 _deadPercentage) private {
        if (warriorsByPlayer[_player][_faction] > 0) {
            uint _warriors = warriorsByPlayer[_player][_faction];
            if (_deadPercentage > 0) {
                _warriors = _warriors.sub(_warriors.wper(_deadPercentage));
            }
            warriorsByPlayer[_player][_faction] = 0;
            sendWarriors(_player, _faction, _warriors);
            WarriorsBackToHome(_player, _faction, _warriors);
        }
    }

    function sendWarriors(address _player, address _faction, uint _warriors) private {
        require(TokenEIP20(_faction).transfer(_player, _warriors));
    }

    function sendBattleTokens(address _player, uint _value) private {
        require(TokenEIP20(battles).transferFrom(battlesOwner, _player, _value));
    }

    function getPersiansOnTheBattlefield(address _player) constant returns (uint persiansOnTheBattlefield) {
        return warriorsByPlayer[_player][persians];
    }

    function getImmortalsOnTheBattlefield(address _player) constant returns (uint immortalsOnTheBattlefield) {
        return warriorsByPlayer[_player][immortals];
    }

    function getSpartansOnTheBattlefield(address _player) constant returns (uint spartansOnTheBattlefield) {
        return warriorsByPlayer[_player][spartans];
    }

    function getAtheniansOnTheBattlefield(address _player) constant returns (uint atheniansOnTheBattlefield) {
        return warriorsByPlayer[_player][athenians];
    }

    function getPersiansBattlePoints() constant returns (uint persiansBattlePoints) {
        return (warriorsOnTheBattlefield[persians].mul(BP_PERSIAN) + warriorsOnTheBattlefield[immortals].mul(WAD).mul(BP_IMMORTAL));
    }

    function getGreeksBattlePoints() constant returns (uint greeksBattlePoints) {
        return (warriorsOnTheBattlefield[spartans].mul(BP_SPARTAN) + warriorsOnTheBattlefield[athenians].mul(BP_ATHENIAN));
    }

    function getPersiansBattlePointsBy(address _player) constant returns (uint playerBattlePoints) {
        return (getPersiansOnTheBattlefield(_player).mul(BP_PERSIAN) + getImmortalsOnTheBattlefield(_player).mul(WAD).mul(BP_IMMORTAL));
    }

    function getGreeksBattlePointsBy(address _player) constant returns (uint playerBattlePoints) {
        return (getSpartansOnTheBattlefield(_player).mul(BP_SPARTAN) + getAtheniansOnTheBattlefield(_player).mul(BP_ATHENIAN));
    }

    function computeSlaves(address _player, address _loosingMainTroops) constant returns (uint slaves) {
        if (_loosingMainTroops == spartans) {
            return getPersiansBattlePointsBy(_player).wdiv(getPersiansBattlePoints()).wmul(getTotalSlaves(spartans));
        } else {
            return getGreeksBattlePointsBy(_player).wdiv(getGreeksBattlePoints()).wmul(getTotalSlaves(persians));
        }
    }

    function getTotalSlaves(address _faction) constant returns (uint slaves) {
        return warriorsOnTheBattlefield[_faction].sub(warriorsOnTheBattlefield[_faction].wper(BATTLE_CASUALTIES));
    }

    function isInProgress() constant returns (bool inProgress) {
        return !isTimeExpired();
    }

    function isEnded() constant returns (bool ended) {
        return isTimeExpired();
    }

    function isDraw() constant returns (bool draw) {
        return (getPersiansBattlePoints() == getGreeksBattlePoints());
    }

    function getTemporaryWinningFaction() constant returns (string temporaryWinningFaction) {
        if (isDraw()) {
            return "It's currently a draw, but the battle is still in progress!";
        }
        return getPersiansBattlePoints() > getGreeksBattlePoints() ?
            "Persians are winning, but the battle is still in progress!" : "Greeks are winning, but the battle is still in progress!";
    }

    function getWinningFaction() constant returns (string winningFaction) {
        if (isInProgress()) {
            return "The battle is still in progress";
        }
        if (isDraw()) {
            return "The battle ended in a draw!";
        }
        return getPersiansBattlePoints() > getGreeksBattlePoints() ? "Persians" : "Greeks";
    }

}