pragma solidity ^0.4.15;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Drainable is Ownable {
	function withdrawToken(address tokenaddr) 
		onlyOwner 
	{
		ERC20 token = ERC20(tokenaddr);
		uint bal = token.balanceOf(address(this));
		token.transfer(msg.sender, bal);
	}

	function withdrawEther() 
		onlyOwner
	{
	    require(msg.sender.send(this.balance));
	}
}


contract ADXRegistry is Ownable, Drainable {
	string public name = "AdEx Registry";

	// Structure:
	// AdUnit (advertiser) - a unit of a single advertisement
	// AdSlot (publisher) - a particular property (slot) that can display an ad unit
	// Campaign (advertiser) - group of ad units ; not vital
	// Channel (publisher) - group of properties ; not vital
	// Each Account is linked to all the items they own through the Account struct

	mapping (address => Account) public accounts;

	// XXX: mostly unused, because solidity does not allow mapping with enum as primary type.. :( we just use uint
	enum ItemType { AdUnit, AdSlot, Campaign, Channel }

	// uint here corresponds to the ItemType
	mapping (uint => uint) public counts;
	mapping (uint => mapping (uint => Item)) public items;

	// Publisher or Advertiser (could be both)
	struct Account {		
		address addr;
		address wallet;

		bytes32 ipfs; // ipfs addr for additional (larger) meta
		bytes32 name; // name
		bytes32 meta; // metadata, can be JSON, can be other format, depends on the high-level implementation

		bytes32 signature; // signature in the off-blockchain state channel
		
		// Items, by type, then in an array of numeric IDs	
		mapping (uint => uint[]) items;
	}

	// Sub-item, such as AdUnit, AdSlot, Campaign, Channel
	struct Item {
		uint id;
		address owner;

		ItemType itemType;

		bytes32 ipfs; // ipfs addr for additional (larger) meta
		bytes32 name; // name
		bytes32 meta; // metadata, can be JSON, can be other format, depends on the high-level implementation
	}

	modifier onlyRegistered() {
		var acc = accounts[msg.sender];
		require(acc.addr != 0);
		_;
	}

	// can be called over and over to update the data
	// XXX consider entrance barrier, such as locking in some ADX
	function register(bytes32 _name, address _wallet, bytes32 _ipfs, bytes32 _sig, bytes32 _meta)
		external
	{
		require(_wallet != 0);
		// XXX should we ensure _sig is not 0? if so, also add test
		
		require(_name != 0);

		var isNew = accounts[msg.sender].addr == 0;

		var acc = accounts[msg.sender];

		if (!isNew) require(acc.signature == _sig);
		else acc.signature = _sig;

		acc.addr = msg.sender;
		acc.wallet = _wallet;
		acc.ipfs = _ipfs;
		acc.name = _name;
		acc.meta = _meta;

		if (isNew) LogAccountRegistered(acc.addr, acc.wallet, acc.ipfs, acc.name, acc.meta, acc.signature);
		else LogAccountModified(acc.addr, acc.wallet, acc.ipfs, acc.name, acc.meta, acc.signature);
	}

	// use _id = 0 to create a new item, otherwise modify existing
	function registerItem(uint _type, uint _id, bytes32 _ipfs, bytes32 _name, bytes32 _meta)
		onlyRegistered
	{
		// XXX _type sanity check?
		var item = items[_type][_id];

		if (_id != 0)
			require(item.owner == msg.sender);
		else {
			// XXX: what about overflow here?
			var newId = ++counts[_type];

			item = items[_type][newId];
			item.id = newId;
			item.itemType = ItemType(_type);
			item.owner = msg.sender;

			accounts[msg.sender].items[_type].push(item.id);
		}

		item.name = _name;
		item.meta = _meta;
		item.ipfs = _ipfs;

		if (_id == 0) LogItemRegistered(
			item.owner, uint(item.itemType), item.id, item.ipfs, item.name, item.meta
		);
		else LogItemModified(
			item.owner, uint(item.itemType), item.id, item.ipfs, item.name, item.meta
		);
	}

	// NOTE
	// There's no real point of un-registering items
	// Campaigns need to be kept anyway, as well as ad units
	// END NOTE

	//
	// Constant functions
	//
	function isRegistered(address who)
		public 
		constant
		returns (bool)
	{
		var acc = accounts[who];
		return acc.addr != 0;
	}

	// Functions exposed for web3 interface
	// NOTE: this is sticking to the policy of keeping static-sized values at the left side of tuples
	function getAccount(address _acc)
		constant
		public
		returns (address, bytes32, bytes32, bytes32)
	{
		var acc = accounts[_acc];
		require(acc.addr != 0);
		return (acc.wallet, acc.ipfs, acc.name, acc.meta);
	}

	function getAccountItems(address _acc, uint _type)
		constant
		public
		returns (uint[])
	{
		var acc = accounts[_acc];
		require(acc.addr != 0);
		return acc.items[_type];
	}

	function getItem(uint _type, uint _id) 
		constant
		public
		returns (address, bytes32, bytes32, bytes32)
	{
		var item = items[_type][_id];
		require(item.id != 0);
		return (item.owner, item.ipfs, item.name, item.meta);
	}

	function hasItem(uint _type, uint _id)
		constant
		public
		returns (bool)
	{
		var item = items[_type][_id];
		return item.id != 0;
	}

	// Events
	event LogAccountRegistered(address addr, address wallet, bytes32 ipfs, bytes32 accountName, bytes32 meta, bytes32 signature);
	event LogAccountModified(address addr, address wallet, bytes32 ipfs, bytes32 accountName, bytes32 meta, bytes32 signature);
	
	event LogItemRegistered(address owner, uint itemType, uint id, bytes32 ipfs, bytes32 itemName, bytes32 meta);
	event LogItemModified(address owner, uint itemType, uint id, bytes32 ipfs, bytes32 itemName, bytes32 meta);
}


contract ADXExchange is Ownable, Drainable {
	string public name = "AdEx Exchange";

	ERC20 public token;
	ADXRegistry public registry;

	uint public bidsCount;

	mapping (uint => Bid) bidsById;
	mapping (uint => uint[]) bidsByAdunit; // bids set out by ad unit
	mapping (uint => uint[]) bidsByAdslot; // accepted by publisher, by ad slot

	// TODO: some properties in the bid structure - achievedPoints/peers for example - are not used atm
	
	// CONSIDER: the bid having a adunitType so that this can be filtered out
	// WHY IT'S NOT IMPORTANT: you can get bids by ad units / ad slots, which is filter enough already considering we know their types

	// CONSIDER: locking ad units / ad slots or certain properties from them so that bids cannot be ruined by editing them
	// WHY IT'S NOT IMPORTANT: from a game theoretical point of view there's no incentive to do that

	// corresponds to enum types in ADXRegistry
	uint constant ADUNIT = 0;
	uint constant ADSLOT = 1;

	enum BidState { 
		Open, 
		Accepted, // in progress

		// the following states MUST unlock the ADX amount (return to advertiser)
		// fail states
		Canceled,
		Expired,

		// success states
		Completed,
		Claimed
	}

	struct Bid {
		uint id;
		BidState state;

		// ADX reward amount
		uint amount;

		// Links on advertiser side
		address advertiser;
		address advertiserWallet;
		uint adUnit;
		bytes32 adUnitIpfs;
		bytes32 advertiserPeer;

		// Links on publisher side
		address publisher;
		address publisherWallet;
		uint adSlot;
		bytes32 adSlotIpfs;
		bytes32 publisherPeer;

		uint acceptedTime; // when was it accepted by a publisher

		// Requirements

		//RequirementType type;
		uint requiredPoints; // how many impressions/clicks/conversions have to be done
		uint requiredExecTime; // essentially a timeout

		// Results
		bool confirmedByPublisher;
		bool confirmedByAdvertiser;

		// IPFS links to result reports 
		bytes32 publisherReportIpfs;
		bytes32 advertiserReportIpfs;
	}

	//
	// MODIFIERS
	//
	modifier onlyRegisteredAcc() {
		require(registry.isRegistered(msg.sender));
		_;
	}

	modifier onlyBidOwner(uint _bidId) {
		require(msg.sender == bidsById[_bidId].advertiser);
		_;
	}

	modifier onlyBidAceptee(uint _bidId) {
		require(msg.sender == bidsById[_bidId].publisher);
		_;
	}

	modifier onlyBidState(uint _bidId, BidState _state) {
		require(bidsById[_bidId].id != 0);
		require(bidsById[_bidId].state == _state);
		_;
	}

	modifier onlyExistingBid(uint _bidId) {
		require(bidsById[_bidId].id != 0);
		_;
	}

	// Functions

	function ADXExchange(address _token, address _registry)
	{
		token = ERC20(_token);
		registry = ADXRegistry(_registry);
	}

	//
	// Bid actions
	// 

	// the bid is placed by the advertiser
	function placeBid(uint _adunitId, uint _target, uint _rewardAmount, uint _timeout, bytes32 _peer)
		onlyRegisteredAcc
	{
		bytes32 adIpfs;
		address advertiser;
		address advertiserWallet;

		// NOTE: those will throw if the ad or respectively the account do not exist
		(advertiser,adIpfs,,) = registry.getItem(ADUNIT, _adunitId);
		(advertiserWallet,,,) = registry.getAccount(advertiser);

		// XXX: maybe it could be a feature to allow advertisers bidding on other advertisers' ad units, but it will complicate things...
		require(advertiser == msg.sender);

		Bid memory bid;

		bid.id = ++bidsCount; // start from 1, so that 0 is not a valid ID
		bid.state = BidState.Open; // XXX redundant, but done for code clarity

		bid.amount = _rewardAmount;

		bid.advertiser = advertiser;
		bid.advertiserWallet = advertiserWallet;

		bid.adUnit = _adunitId;
		bid.adUnitIpfs = adIpfs;

		bid.requiredPoints = _target;
		bid.requiredExecTime = _timeout;

		bid.advertiserPeer = _peer;

		bidsById[bid.id] = bid;
		bidsByAdunit[_adunitId].push(bid.id);

		require(token.transferFrom(advertiserWallet, address(this), _rewardAmount));

		LogBidOpened(bid.id, advertiser, _adunitId, adIpfs, _target, _rewardAmount, _timeout, _peer);
	}

	// the bid is canceled by the advertiser
	function cancelBid(uint _bidId)
		onlyRegisteredAcc
		onlyExistingBid(_bidId)
		onlyBidOwner(_bidId)
		onlyBidState(_bidId, BidState.Open)
	{
		Bid storage bid = bidsById[_bidId];
		bid.state = BidState.Canceled;
		require(token.transfer(bid.advertiserWallet, bid.amount));

		LogBidCanceled(bid.id);
	}

	// a bid is accepted by a publisher for a given ad slot
	function acceptBid(uint _bidId, uint _slotId, bytes32 _peer) 
		onlyRegisteredAcc 
		onlyExistingBid(_bidId) 
		onlyBidState(_bidId, BidState.Open)
	{
		address publisher;
		address publisherWallet;
		bytes32 adSlotIpfs;

		// NOTE: those will throw if the ad slot or respectively the account do not exist
		(publisher,adSlotIpfs,,) = registry.getItem(ADSLOT, _slotId);
		(publisherWallet,,,) = registry.getAccount(publisher);

		require(publisher == msg.sender);

		Bid storage bid = bidsById[_bidId];

		// should not happen when bid.state is BidState.Open, but just in case
		require(bid.publisher == 0);

		bid.state = BidState.Accepted;
		
		bid.publisher = publisher;
		bid.publisherWallet = publisherWallet;

		bid.adSlot = _slotId;
		bid.adSlotIpfs = adSlotIpfs;

		bid.publisherPeer = _peer;

		bid.acceptedTime = now;

		bidsByAdslot[_slotId].push(_bidId);

		LogBidAccepted(bid.id, publisher, _slotId, adSlotIpfs, bid.acceptedTime, bid.publisherPeer);
	}

	// the bid is given up by the publisher, therefore canceling it and returning the funds to the advertiser
	// same logic as cancelBid(), but different permissions
	function giveupBid(uint _bidId)
		onlyRegisteredAcc
		onlyExistingBid(_bidId)
		onlyBidAceptee(_bidId)
		onlyBidState(_bidId, BidState.Accepted)
	{
		var bid = bidsById[_bidId];
		bid.state = BidState.Canceled;
		require(token.transfer(bid.advertiserWallet, bid.amount));

		LogBidCanceled(bid.id);
	}

	// both publisher and advertiser have to call this for a bid to be considered verified
	function verifyBid(uint _bidId, bytes32 _report)
		onlyRegisteredAcc
		onlyExistingBid(_bidId)
		onlyBidState(_bidId, BidState.Accepted)
	{
		Bid storage bid = bidsById[_bidId];

		require(bid.publisher == msg.sender || bid.advertiser == msg.sender);

		if (bid.publisher == msg.sender) {
			bid.confirmedByPublisher = true;
			bid.publisherReportIpfs = _report;
		}

		if (bid.advertiser == msg.sender) {
			bid.confirmedByAdvertiser = true;
			bid.advertiserReportIpfs = _report;
		}

		if (bid.confirmedByAdvertiser && bid.confirmedByPublisher) {
			bid.state = BidState.Completed;
			LogBidCompleted(bid.id, bid.advertiserReportIpfs, bid.publisherReportIpfs);
		}
	}

	// now, claim the reward; callable by the publisher;
	// claimBidReward is a separate function so as to define clearly who pays the gas for transfering the reward 
	function claimBidReward(uint _bidId)
		onlyRegisteredAcc
		onlyExistingBid(_bidId)
		onlyBidAceptee(_bidId)
		onlyBidState(_bidId, BidState.Completed)
	{
		Bid storage bid = bidsById[_bidId];
		
		bid.state = BidState.Claimed;

		require(token.transfer(bid.publisherWallet, bid.amount));

		LogBidRewardClaimed(bid.id, bid.publisherWallet, bid.amount);
	}

	// This can be done if a bid is accepted, but expired
	// This is essentially the protection from never settling on verification, or from publisher not executing the bid within a reasonable time
	function refundBid(uint _bidId)
		onlyRegisteredAcc
		onlyExistingBid(_bidId)
		onlyBidOwner(_bidId)
		onlyBidState(_bidId, BidState.Accepted)
	{
		Bid storage bid = bidsById[_bidId];
		require(bid.requiredExecTime > 0); // you can't refund if you haven't set a timeout
		require(SafeMath.add(bid.acceptedTime, bid.requiredExecTime) < now);

		bid.state = BidState.Expired;
		require(token.transfer(bid.advertiserWallet, bid.amount));

		LogBidExpired(bid.id);
	}

	//
	// Public constant functions
	//

	function getBidsFromArr(uint[] arr, uint _state) 
		internal
		returns (uint[] _all)
	{
		BidState state = BidState(_state);

		// separate array is needed because of solidity stupidity (pun intended ))) )
		uint[] memory all = new uint[](arr.length);

		uint count = 0;
		uint i;

		for (i = 0; i < arr.length; i++) {
			var id = arr[i];
			var bid = bidsById[id];
			if (bid.state == state) {
				all[count] = id;
				count += 1;
			}
		}

		_all = new uint[](count);
		for (i = 0; i < count; i++) _all[i] = all[i];
	}

	function getAllBidsByAdunit(uint _adunitId) 
		constant 
		external
		returns (uint[])
	{
		return bidsByAdunit[_adunitId];
	}

	function getBidsByAdunit(uint _adunitId, uint _state)
		constant
		external
		returns (uint[])
	{
		return getBidsFromArr(bidsByAdunit[_adunitId], _state);
	}

	function getAllBidsByAdslot(uint _adslotId) 
		constant 
		external
		returns (uint[])
	{
		return bidsByAdslot[_adslotId];
	}

	function getBidsByAdslot(uint _adslotId, uint _state)
		constant
		external
		returns (uint[])
	{
		return getBidsFromArr(bidsByAdslot[_adslotId], _state);
	}

	function getBid(uint _bidId) 
		onlyExistingBid(_bidId)
		constant
		external
		returns (
			uint, uint, uint, uint, uint, 
			// advertiser (ad unit, ipfs, peer)
			uint, bytes32, bytes32,
			// publisher (ad slot, ipfs, peer)
			uint, bytes32, bytes32
		)
	{
		var bid = bidsById[_bidId];
		return (
			uint(bid.state), bid.requiredPoints, bid.requiredExecTime, bid.amount, bid.acceptedTime,
			bid.adUnit, bid.adUnitIpfs, bid.advertiserPeer,
			bid.adSlot, bid.adSlotIpfs, bid.publisherPeer
		);
	}

	function getBidReports(uint _bidId)
		onlyExistingBid(_bidId)
		constant
		external
		returns (
			bytes32, // advertiser report
			bytes32 // publisher report
		)
	{
		var bid = bidsById[_bidId];
		return (bid.advertiserReportIpfs, bid.publisherReportIpfs);
	}

	//
	// Events
	//
	event LogBidOpened(uint bidId, address advertiser, uint adunitId, bytes32 adunitIpfs, uint target, uint rewardAmount, uint timeout, bytes32 advertiserPeer);
	event LogBidAccepted(uint bidId, address publisher, uint adslotId, bytes32 adslotIpfs, uint acceptedTime, bytes32 publisherPeer);
	event LogBidCanceled(uint bidId);
	event LogBidExpired(uint bidId);
	event LogBidCompleted(uint bidId, bytes32 advReport, bytes32 pubReport);
	event LogBidRewardClaimed(uint _bidId, address _wallet, uint _amount);
}