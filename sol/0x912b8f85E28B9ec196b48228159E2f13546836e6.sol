pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Drainable is Ownable {
	function withdrawToken(address tokenaddr) 
		onlyOwner
		public
	{
		ERC20 token = ERC20(tokenaddr);
		uint bal = token.balanceOf(address(this));
		token.transfer(msg.sender, bal);
	}

	function withdrawEther() 
		onlyOwner
		public
	{
	    require(msg.sender.send(this.balance));
	}
}

contract ADXExchangeInterface {
	// events
	event LogBidAccepted(bytes32 bidId, address advertiser, bytes32 adunit, address publisher, bytes32 adslot, uint acceptedTime);
	event LogBidCanceled(bytes32 bidId);
	event LogBidExpired(bytes32 bidId);
	event LogBidConfirmed(bytes32 bidId, address advertiserOrPublisher, bytes32 report);
	event LogBidCompleted(bytes32 bidId, bytes32 advReport, bytes32 pubReport);

	event LogDeposit(address _user, uint _amnt);
	event LogWithdrawal(address _user, uint _amnt);

	function acceptBid(address _advertiser, bytes32 _adunit, uint _opened, uint _target, uint _rewardAmount, uint _timeout, bytes32 _adslot, uint8 v, bytes32 r, bytes32 s, uint8 sigMode) public;
	function cancelBid(bytes32 _adunit, uint _opened, uint _target, uint _rewardAmount, uint _timeout, uint8 v, bytes32 r, bytes32 s, uint8 sigMode) public;
	function giveupBid(bytes32 _bidId) public;
	function refundBid(bytes32 _bidId) public;
	function verifyBid(bytes32 _bidId, bytes32 _report) public;

	function deposit(uint _amount) public;
	function withdraw(uint _amount) public;

	// constants 
	function getBid(bytes32 _bidId) 
		constant external 
		returns (
			uint, uint, uint, uint, uint, 
			// advertiser (advertiser, ad unit, confiration)
			address, bytes32, bytes32,
			// publisher (publisher, ad slot, confirmation)
			address, bytes32, bytes32
		);

	function getBalance(address _user)
		constant
		external
		returns (uint, uint);

	function getBidID(address _advertiser, bytes32 _adunit, uint _opened, uint _target, uint _amount, uint _timeout)
		constant
		public
		returns (bytes32);
}


contract ADXExchange is ADXExchangeInterface, Drainable {
	string public name = "AdEx Exchange";

	ERC20 public token;

	uint public maxTimeout = 365 days;

 	mapping (address => uint) balances;

 	// escrowed on bids
 	mapping (address => uint) onBids; 

 	// bid info
	mapping (bytes32 => Bid) bids;
	mapping (bytes32 => BidState) bidStates;


	enum BidState { 
		DoesNotExist, // default state

		// There is no 'Open' state - the Open state is just a signed message that you're willing to place such a bid
		Accepted, // in progress

		// the following states MUST unlock the ADX amount (return to advertiser)
		// fail states
		Canceled,
		Expired,

		// success states
		Completed
	}

	struct Bid {
		// Links on advertiser side
		address advertiser;
		bytes32 adUnit;

		// Links on publisher side
		address publisher;
		bytes32 adSlot;

		// when was it accepted by a publisher
		uint acceptedTime;

		// Token reward amount
		uint amount;

		// Requirements
		uint target; // how many impressions/clicks/conversions have to be done
		uint timeout; // the time to execute

		// Confirmations from both sides; any value other than 0 is vconsidered as confirm, but this should usually be an IPFS hash to a final report
		bytes32 publisherConfirmation;
		bytes32 advertiserConfirmation;
	}

	// Schema hash 
	// keccak256(_advertiser, _adunit, _opened, _target, _amount, _timeout, this)
	bytes32 constant public SCHEMA_HASH = keccak256(
		"address Advertiser",
		"bytes32 Ad Unit ID",
		"uint Opened",
		"uint Target",
		"uint Amount",
		"uint Timeout",
		"address Exchange"
	);

	//
	// MODIFIERS
	//
	modifier onlyBidAdvertiser(bytes32 _bidId) {
		require(msg.sender == bids[_bidId].advertiser);
		_;
	}

	modifier onlyBidPublisher(bytes32 _bidId) {
		require(msg.sender == bids[_bidId].publisher);
		_;
	}

	modifier onlyBidState(bytes32 _bidId, BidState _state) {
		require(bidStates[_bidId] == _state);
		_;
	}

	// Functions

	function ADXExchange(address _token)
		public
	{
		token = ERC20(_token);
	}

	//
	// Bid actions
	// 

	// the bid is accepted by the publisher
	function acceptBid(address _advertiser, bytes32 _adunit, uint _opened, uint _target, uint _amount, uint _timeout, bytes32 _adslot, uint8 v, bytes32 r, bytes32 s, uint8 sigMode)
		public
	{
		require(_amount > 0);

		// It can be proven that onBids will never exceed balances which means this can't underflow
		// SafeMath can't be used here because of the stack depth
		require(_amount <= (balances[_advertiser] - onBids[_advertiser]));

		// _opened acts as a nonce here
		bytes32 bidId = getBidID(_advertiser, _adunit, _opened, _target, _amount, _timeout);

		require(bidStates[bidId] == BidState.DoesNotExist);

		require(didSign(_advertiser, bidId, v, r, s, sigMode));
		
		// advertier and publisher cannot be the same
		require(_advertiser != msg.sender);

		Bid storage bid = bids[bidId];

		bid.target = _target;
		bid.amount = _amount;

		// it is pretty much mandatory for a bid to have a timeout, else tokens can be stuck forever
		bid.timeout = _timeout > 0 ? _timeout : maxTimeout;
		require(bid.timeout <= maxTimeout);

		bid.advertiser = _advertiser;
		bid.adUnit = _adunit;

		bid.publisher = msg.sender;
		bid.adSlot = _adslot;

		bid.acceptedTime = now;

		bidStates[bidId] = BidState.Accepted;

		onBids[_advertiser] += _amount;

		// static analysis?
		// require(onBids[_advertiser] <= balances[advertiser]);

		LogBidAccepted(bidId, _advertiser, _adunit, msg.sender, _adslot, bid.acceptedTime);
	}

	// The bid is canceled by the advertiser
	function cancelBid(bytes32 _adunit, uint _opened, uint _target, uint _amount, uint _timeout, uint8 v, bytes32 r, bytes32 s, uint8 sigMode)
		public
	{
		// _opened acts as a nonce here
		bytes32 bidId = getBidID(msg.sender, _adunit, _opened, _target, _amount, _timeout);

		require(bidStates[bidId] == BidState.DoesNotExist);

		require(didSign(msg.sender, bidId, v, r, s, sigMode));

		bidStates[bidId] = BidState.Canceled;

		LogBidCanceled(bidId);
	}

	// The bid is canceled by the publisher
	function giveupBid(bytes32 _bidId)
		public
		onlyBidPublisher(_bidId)
		onlyBidState(_bidId, BidState.Accepted)
	{
		Bid storage bid = bids[_bidId];

		bidStates[_bidId] = BidState.Canceled;

		onBids[bid.advertiser] -= bid.amount;
	
		LogBidCanceled(_bidId);
	}


	// This can be done if a bid is accepted, but expired
	// This is essentially the protection from never settling on verification, or from publisher not executing the bid within a reasonable time
	function refundBid(bytes32 _bidId)
		public
		onlyBidAdvertiser(_bidId)
		onlyBidState(_bidId, BidState.Accepted)
	{
		Bid storage bid = bids[_bidId];

 		// require that we're past the point of expiry
		require(now > SafeMath.add(bid.acceptedTime, bid.timeout));

		bidStates[_bidId] = BidState.Expired;

		onBids[bid.advertiser] -= bid.amount;

		LogBidExpired(_bidId);
	}


	// both publisher and advertiser have to call this for a bid to be considered verified
	function verifyBid(bytes32 _bidId, bytes32 _report)
		public
		onlyBidState(_bidId, BidState.Accepted)
	{
		Bid storage bid = bids[_bidId];

		require(_report != 0);
		require(bid.publisher == msg.sender || bid.advertiser == msg.sender);

		if (bid.publisher == msg.sender) {
			require(bid.publisherConfirmation == 0);
			bid.publisherConfirmation = _report;
		}

		if (bid.advertiser == msg.sender) {
			require(bid.advertiserConfirmation == 0);
			bid.advertiserConfirmation = _report;
		}

		LogBidConfirmed(_bidId, msg.sender, _report);

		if (bid.advertiserConfirmation != 0 && bid.publisherConfirmation != 0) {
			bidStates[_bidId] = BidState.Completed;

			onBids[bid.advertiser] = SafeMath.sub(onBids[bid.advertiser], bid.amount);
			balances[bid.advertiser] = SafeMath.sub(balances[bid.advertiser], bid.amount);
			balances[bid.publisher] = SafeMath.add(balances[bid.publisher], bid.amount);

			LogBidCompleted(_bidId, bid.advertiserConfirmation, bid.publisherConfirmation);
		}
	}

	// Deposit and withdraw
	function deposit(uint _amount)
		public
	{
		balances[msg.sender] = SafeMath.add(balances[msg.sender], _amount);
		require(token.transferFrom(msg.sender, address(this), _amount));

		LogDeposit(msg.sender, _amount);
	}

	function withdraw(uint _amount)
		public
	{
		uint available = SafeMath.sub(balances[msg.sender], onBids[msg.sender]);
		require(_amount <= available);

		balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
		require(token.transfer(msg.sender, _amount));

		LogWithdrawal(msg.sender, _amount);
	}

	function didSign(address addr, bytes32 hash, uint8 v, bytes32 r, bytes32 s, uint8 mode)
		public
		pure
		returns (bool)
	{
		bytes32 message = hash;
		
		if (mode == 1) {
			// Geth mode
			message = keccak256("\x19Ethereum Signed Message:\n32", hash);
		} else if (mode == 2) {
			// Trezor mode
			message = keccak256("\x19Ethereum Signed Message:\n\x20", hash);
		}

		return ecrecover(message, v, r, s) == addr;
	}

	//
	// Public constant functions
	//
	function getBid(bytes32 _bidId) 
		constant
		external
		returns (
			uint, uint, uint, uint, uint, 
			// advertiser (advertiser, ad unit, confiration)
			address, bytes32, bytes32,
			// publisher (publisher, ad slot, confirmation)
			address, bytes32, bytes32
		)
	{
		Bid storage bid = bids[_bidId];
		return (
			uint(bidStates[_bidId]), bid.target, bid.timeout, bid.amount, bid.acceptedTime,
			bid.advertiser, bid.adUnit, bid.advertiserConfirmation,
			bid.publisher, bid.adSlot, bid.publisherConfirmation
		);
	}

	function getBalance(address _user)
		constant
		external
		returns (uint, uint)
	{
		return (balances[_user], onBids[_user]);
	}

	function getBidID(address _advertiser, bytes32 _adunit, uint _opened, uint _target, uint _amount, uint _timeout)
		constant
		public
		returns (bytes32)
	{
		return keccak256(
			SCHEMA_HASH,
			keccak256(_advertiser, _adunit, _opened, _target, _amount, _timeout, this)
		);
	}
}