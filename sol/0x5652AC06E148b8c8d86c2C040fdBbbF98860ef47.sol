pragma solidity ^0.4.13;

contract DBC {

    // MODIFIERS

    modifier pre_cond(bool condition) {
        require(condition);
        _;
    }

    modifier post_cond(bool condition) {
        _;
        assert(condition);
    }

    modifier invariant(bool condition) {
        require(condition);
        _;
        assert(condition);
    }
}

contract Competition is DBC {

    // TYPES

    struct Hopeful { // Someone who wants to succeed or who seems likely to win
        address fund; // Address of the Melon fund
        address manager; // Address of the fund manager, as used in the ipfs-frontend
        address registrant; // Manager (== owner) of above Melon fund
        bool hasSigned; // Whether initial requirements passed and Hopeful signed Terms and Conditions; Does not mean Hopeful is competing yet
        address buyinAsset; // Asset (ERC20 Token) spent to take part in competition
        address payoutAsset; // Asset (usually Melon Token) to be received as prize
        uint buyinQuantity; // Quantity of buyinAsset spent
        uint payoutQuantity; // Quantity of payoutAsset received as prize
        address payoutAddress; // Address to payout in main chain
        bool isCompeting; // Whether outside oracle verified remaining requirements; If yes Hopeful is taking part in a competition
        bool isDisqualified; // Whether participant is disqualified
        uint finalSharePrice; // Performance of Melon fund at competition endTime; Can be changed for any other comparison metric
        uint finalCompetitionRank; // Rank of Hopeful at end of competition; Calculate by logic as set in terms and conditions
    }

    struct HopefulId {
      uint id; // Actual Hopeful Id
      bool exists; // Used to check if the mapping exists
    }

    // FIELDS

    // Constant fields
    // Competition terms and conditions as displayed on https://ipfs.io/ipfs/QmQ7DqjpxmTDbaxcH5qwv8QmGvJY7rhb8UV2QRfCEFBp8V
    // IPFS hash encoded using http://lenschulwitz.com/base58
    bytes32 public constant TERMS_AND_CONDITIONS = 0x1A46B45CC849E26BB3159298C3C218EF300D015ED3E23495E77F0E529CE9F69E;
    uint public MELON_BASE_UNIT = 10 ** 18;
    // Constructor fields
    address public oracle; // Information e.g. from Kovan can be passed to contract from this address
    uint public startTime; // Competition start time in seconds (Temporarily Set)
    uint public endTime; // Competition end time in seconds
    uint public maxbuyinQuantity; // Limit amount of deposit to participate in competition
    uint public maxHopefulsNumber; // Limit number of participate in competition
    uint public prizeMoneyAsset; // Equivalent to payoutAsset
    uint public prizeMoneyQuantity; // Total prize money pool
    address public MELON_ASSET; // Adresss of Melon asset contract
    ERC20Interface public MELON_CONTRACT; // Melon as ERC20 contract
    Certifier public CERTIFIER; // Parity KYC verification contract
    // Methods fields
    Hopeful[] public hopefuls; // List of all hopefuls, can be externally accessed
    mapping (address => address) public registeredFundToRegistrants; // For fund address indexed accessing of registrant addresses
    mapping(address => HopefulId) public registrantToHopefulIds; // For registrant address indexed accessing of hopeful ids

    //EVENTS

    event Register(uint withId, address fund, address manager);

    // PRE, POST, INVARIANT CONDITIONS

    /// @dev Proofs that terms and conditions have been read and understood
    /// @param byManager Address of the fund manager, as used in the ipfs-frontend
    /// @param v ellipitc curve parameter v
    /// @param r ellipitc curve parameter r
    /// @param s ellipitc curve parameter s
    /// @return Whether or not terms and conditions have been read and understood
    function termsAndConditionsAreSigned(address byManager, uint8 v, bytes32 r, bytes32 s) view returns (bool) {
        return ecrecover(
            // Parity does prepend \x19Ethereum Signed Message:\n{len(message)} before signing.
            //  Signature order has also been changed in 1.6.7 and upcoming 1.7.x,
            //  it will return rsv (same as geth; where v is [27, 28]).
            // Note that if you are using ecrecover, v will be either "00" or "01".
            //  As a result, in order to use this value, you will have to parse it to an
            //  integer and then add 27. This will result in either a 27 or a 28.
            //  https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethsign
            keccak256("\x19Ethereum Signed Message:\n32", TERMS_AND_CONDITIONS),
            v,
            r,
            s
        ) == byManager; // Has sender signed TERMS_AND_CONDITIONS
    }

    /// @return Whether message sender is oracle or not
    function isOracle() view returns (bool) { return msg.sender == oracle; }

    /// @dev Whether message sender is KYC verified through CERTIFIER
    /// @param x Address to be checked for KYC verification
    function isKYCVerified(address x) view returns (bool) { return CERTIFIER.certified(x); }

    // CONSTANT METHODS

    function getMelonAsset() view returns (address) { return MELON_ASSET; }

    /// @return Get HopefulId from registrant address
    function getHopefulId(address x) view returns (uint) { return registrantToHopefulIds[x].id; }

    /**
    @notice Returns an array of fund addresses and an associated array of whether competing and whether disqualified
    @return {
      "fundAddrs": "Array of addresses of Melon Funds",
      "fundManagers": "Array of addresses of Melon fund managers, as used in the ipfs-frontend",
      "areCompeting": "Array of boolean of whether or not fund is competing"
      "areDisqualified": "Array of boolean of whether or not fund is disqualified"
    }
    */
    function getCompetitionStatusOfHopefuls()
        view
        returns(
            address[] fundAddrs,
            address[] fundManagers,
            bool[] areCompeting,
            bool[] areDisqualified
        )
    {
        for (uint i = 0; i <= hopefuls.length - 1; i++) {
            fundAddrs[i] = hopefuls[i].fund;
            fundManagers[i] = hopefuls[i].manager;
            areCompeting[i] = hopefuls[i].isCompeting;
            areDisqualified[i] = hopefuls[i].isDisqualified;
        }
        return (fundAddrs, fundManagers, areCompeting, areDisqualified);
    }

    // NON-CONSTANT METHODS

    function Competition(
        address ofMelonAsset,
        address ofOracle,
        address ofCertifier,
        uint ofStartTime,
        uint ofMaxbuyinQuantity,
        uint ofMaxHopefulsNumber
    ) {
        MELON_ASSET = ofMelonAsset;
        MELON_CONTRACT = ERC20Interface(MELON_ASSET);
        oracle = ofOracle;
        CERTIFIER = Certifier(ofCertifier);
        startTime = ofStartTime;
        endTime = startTime + 2 weeks;
        maxbuyinQuantity = ofMaxbuyinQuantity;
        maxHopefulsNumber = ofMaxHopefulsNumber;
    }

    /// @notice Register to take part in the competition
    /// @param fund Address of the Melon fund
    /// @param buyinAsset Asset (ERC20 Token) spent to take part in competition
    /// @param payoutAsset Asset (usually Melon Token) to be received as prize
    /// @param buyinQuantity Quantity of buyinAsset spent
    /// @param v ellipitc curve parameter v
    /// @param r ellipitc curve parameter r
    /// @param s ellipitc curve parameter s
    function registerForCompetition(
        address fund,
        address manager,
        address buyinAsset,
        address payoutAsset,
        address payoutAddress,
        uint buyinQuantity,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        pre_cond(termsAndConditionsAreSigned(manager, v, r, s) && isKYCVerified(msg.sender))
        pre_cond(registeredFundToRegistrants[fund] == address(0) && registrantToHopefulIds[msg.sender].exists == false)
    {
        require(buyinAsset == MELON_ASSET && payoutAsset == MELON_ASSET);
        require(buyinQuantity <= maxbuyinQuantity && hopefuls.length <= maxHopefulsNumber);
        registeredFundToRegistrants[fund] = msg.sender;
        registrantToHopefulIds[msg.sender] = HopefulId({id: hopefuls.length, exists: true});
        Register(hopefuls.length, fund, msg.sender);
        hopefuls.push(Hopeful({
          fund: fund,
          manager: manager,
          registrant: msg.sender,
          hasSigned: true,
          buyinAsset: buyinAsset,
          payoutAsset: payoutAsset,
          payoutAddress: payoutAddress,
          buyinQuantity: buyinQuantity,
          payoutQuantity: 0,
          isCompeting: true,
          isDisqualified: false,
          finalSharePrice: 0,
          finalCompetitionRank: 0
        }));
    }

    /// @notice Disqualify and participant
    /// @dev Only the oracle can call this function
    /// @param withId Index of Hopeful to disqualify
    function disqualifyHopeful(
        uint withId
    )
        pre_cond(isOracle())
    {
        hopefuls[withId].isDisqualified = true;
    }

    /// @notice Closing oracle service, inputs final stats and triggers payouts
    /// @dev Only the oracle can call this function
    /// @param withId Index of Hopeful to be attest for
    /// @param payoutQuantity Quantity of payoutAsset received as prize
    /// @param finalSharePrice Performance of Melon fund at competition endTime; Can be changed for any other comparison metric
    /// @param finalCompetitionRank Rank of Hopeful at end of competition; Calculate by logic as set in terms and conditions
    function finalizeAndPayoutForHopeful(
        uint withId,
        uint payoutQuantity, // Quantity of payoutAsset received as prize
        uint finalSharePrice, // Performance of Melon fund at competition endTime; Can be changed for any other comparison metric
        uint finalCompetitionRank // Rank of Hopeful at end of competition; Calculate by logic as set in terms and conditions
    )
        pre_cond(isOracle())
        pre_cond(hopefuls[withId].isDisqualified == false)
        pre_cond(block.timestamp >= endTime)
    {
        hopefuls[withId].finalSharePrice = finalSharePrice;
        hopefuls[withId].finalCompetitionRank = finalCompetitionRank;
        hopefuls[withId].payoutQuantity = payoutQuantity;
        require(MELON_CONTRACT.transfer(hopefuls[withId].registrant, payoutQuantity));
    }

    /// @notice Changes certifier contract address
    /// @dev Only the oracle can call this function
    /// @param newCertifier Address of the new certifier
    function changeCertifier(
        address newCertifier
    )
        pre_cond(isOracle())
    {
        CERTIFIER = Certifier(newCertifier);
    }

}

contract ERC20Interface {

    // EVENTS

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // CONSTANT METHODS

    function totalSupply() constant returns (uint256 totalSupply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    // NON-CONSTANT METHODS

    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
}

contract Owned {
	modifier only_owner { if (msg.sender != owner) return; _; }

	event NewOwner(address indexed old, address indexed current);

	function setOwner(address _new) only_owner { NewOwner(owner, _new); owner = _new; }

	address public owner = msg.sender;
}

contract Certifier {
	event Confirmed(address indexed who);
	event Revoked(address indexed who);
	function certified(address _who) constant returns (bool);
	function get(address _who, string _field) constant returns (bytes32) {}
	function getAddress(address _who, string _field) constant returns (address) {}
	function getUint(address _who, string _field) constant returns (uint) {}
}

contract SimpleCertifier is Owned, Certifier {
	modifier only_delegate { if (msg.sender != delegate) return; _; }
	modifier only_certified(address _who) { if (!certs[_who].active) return; _; }

	struct Certification {
		bool active;
		mapping (string => bytes32) meta;
	}

	function certify(address _who) only_delegate {
		certs[_who].active = true;
		Confirmed(_who);
	}
	function revoke(address _who) only_delegate only_certified(_who) {
		certs[_who].active = false;
		Revoked(_who);
	}
	function certified(address _who) constant returns (bool) { return certs[_who].active; }
	function get(address _who, string _field) constant returns (bytes32) { return certs[_who].meta[_field]; }
	function getAddress(address _who, string _field) constant returns (address) { return address(certs[_who].meta[_field]); }
	function getUint(address _who, string _field) constant returns (uint) { return uint(certs[_who].meta[_field]); }
	function setDelegate(address _new) only_owner { delegate = _new; }

	mapping (address => Certification) certs;
	// So that the server posting puzzles doesn't have access to the ETH.
	address public delegate = msg.sender;
}