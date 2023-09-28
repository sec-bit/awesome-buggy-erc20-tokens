// VERSION M(A)

pragma solidity ^0.4.8;


//
// FOR REFERENCE - INCLUDE  iE4RowEscrow  (interface) CONTRACT at the top .....
//

contract iE4RowEscrow {
	function getNumGamesStarted() constant returns (int ngames);
}

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

// ---------------------------------
// ABSTRACT standard token class
// ---------------------------------
contract Token { 
    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


// --------------------------
//  E4RowRewards - abstract e4 dividend contract
// --------------------------
contract E4RowRewards
{
	function checkDividends(address _addr) constant returns(uint _amount);
	function withdrawDividends() public returns (uint namount);
}

// --------------------------
//  Finney Chip - token contract
// --------------------------
contract E4Token is Token, E4RowRewards {
    	event StatEvent(string msg);
    	event StatEventI(string msg, uint val);

	enum SettingStateValue  {debug, release, lockedRelease}
	enum IcoStatusValue {anouncement, saleOpen, saleClosed, failed, succeeded}




	struct tokenAccount {
		bool alloced; // flag to ascert prior allocation
		uint tokens; // num tokens
		uint balance; // rewards balance
	}
// -----------------------------
//  data storage
// ----------------------------------------
	address developers; // developers token holding address
	address public owner; // deployer executor
	address founderOrg; // founder orginaization contract
	address auxPartner; // aux partner (pr/auditing) - 1 percent upon close
	address e4_partner; // e4row  contract addresses


	mapping (address => tokenAccount) holderAccounts ; // who holds how many tokens (high two bytes contain curPayId)
	mapping (uint => address) holderIndexes ; // for iteration thru holder
	uint numAccounts;

	uint partnerCredits; // amount partner (e4row)  has paid
	mapping (address => mapping (address => uint256)) allowed; // approvals


	uint maxMintableTokens; // ...
	uint minIcoTokenGoal;// token goal by sale end
	uint minUsageGoal; //  num games goal by usage deadline
	uint public  tokenPrice; // price per token
	uint public payoutThreshold; // threshold till payout

	uint totalTokenFundsReceived; 	// running total of token funds received
	uint public totalTokensMinted; 	// total number of tokens minted
	uint public holdoverBalance; 		// hold this amount until threshhold before reward payout
	int public payoutBalance; 		// hold this amount until threshhold before reward payout
	int prOrigPayoutBal;			// original payout balance before run
	uint prOrigTokensMint; 			// tokens minted at start of pay run
	uint public curPayoutId;		// current payout id
	uint public lastPayoutIndex;		// payout idx between run segments
	uint public maxPaysPer;			// num pays per segment
	uint public minPayInterval;		// min interval between start pay run


	uint fundingStart; 		// funding start time immediately after anouncement
	uint fundingDeadline; 		// funding end time
	uint usageDeadline; 		// deadline where minimum usage needs to be met before considered success
	uint public lastPayoutTime; 	// timestamp of last payout time
	uint vestTime; 		// 1 year past sale vest developer tokens
	uint numDevTokens; 	// 10 per cent of tokens after close to developers
	bool developersGranted; 		// flag
	uint remunerationStage; 	// 0 for not yet, 1 for 10 percent, 2 for remaining  upon succeeded.
	uint public remunerationBalance; 	// remuneration balance to release token funds
	uint auxPartnerBalance; 	// aux partner balance - 1 percent
	uint rmGas; // remuneration gas
	uint rwGas; // reward gas
	uint rfGas; // refund gas

	IcoStatusValue icoStatus;  // current status of ico
	SettingStateValue public settingsState;


	// --------------------
	// contract constructor
	// --------------------
	function E4Token() 
	{
		owner = msg.sender;
		developers = msg.sender;
	}

	// -----------------------------------
	// use this to reset everything, will never be called after lockRelease
	// -----------------------------------
	function applySettings(SettingStateValue qState, uint _saleStart, uint _saleEnd, uint _usageEnd, uint _minUsage, uint _tokGoal, uint  _maxMintable, uint _threshold, uint _price, uint _mpp, uint _mpi )
	{
		if (msg.sender != owner) 
			return;

		// these settings are permanently tweakable for performance adjustments
		payoutThreshold = _threshold;
		maxPaysPer = _mpp;
		minPayInterval = _mpi;

		// this first test checks if already locked
		if (settingsState == SettingStateValue.lockedRelease)
			return;

 	 	settingsState = qState;

		// this second test allows locking without changing other permanent settings
		// WARNING, MAKE SURE YOUR'RE HAPPY WITH ALL SETTINGS 
		// BEFORE LOCKING

		if (qState == SettingStateValue.lockedRelease) {
			StatEvent("Locking!");
			return;
		}

		icoStatus = IcoStatusValue.anouncement;

		rmGas = 100000; // remuneration gas
		rwGas = 10000; // reward gas
		rfGas = 10000; // refund gas


		// zero out all token holders.  
		// leave alloced on, leave num accounts
		// cant delete them anyways
	
		if (totalTokensMinted > 0) {
			for (uint i = 0; i < numAccounts; i++ ) {
				address a = holderIndexes[i];
				if (a != address(0)) {
					holderAccounts[a].tokens = 0;
					holderAccounts[a].balance = 0;
				}
			}
		}
		// do not reset numAccounts!

		totalTokensMinted = 0; // this will erase
		totalTokenFundsReceived = 0; // this will erase.
		partnerCredits = 0; // reset all partner credits

		fundingStart =  _saleStart;
		fundingDeadline = _saleEnd;
		usageDeadline = _usageEnd;
		minUsageGoal = _minUsage;
		minIcoTokenGoal = _tokGoal;
		maxMintableTokens = _maxMintable;
		tokenPrice = _price;

		vestTime = fundingStart + (365 days);
		numDevTokens = 0;
		
		holdoverBalance = 0;
		payoutBalance = 0;
		curPayoutId = 1;
		lastPayoutIndex = 0;
		remunerationStage = 0;
		remunerationBalance = 0;
		auxPartnerBalance = 0;
		developersGranted = false;
		lastPayoutTime = 0;

		if (this.balance > 0) {
			if (!owner.call.gas(rfGas).value(this.balance)())
				StatEvent("ERROR!");
		}
		StatEvent("ok");

	}


	// ---------------------------------------------------
	// tokens held reserve the top two bytes for the payid last paid.
	// this is so holders at the top of the list dont transfer tokens 
	// to themselves on the bottom of the list thus scamming the 
	// system. this function deconstructs the tokenheld value.
	// ---------------------------------------------------
	function getPayIdAndHeld(uint _tokHeld) internal returns (uint _payId, uint _held)
	{
		_payId = (_tokHeld / (2 ** 48)) & 0xffff;
		_held = _tokHeld & 0xffffffffffff;
	}
	function getHeld(uint _tokHeld) internal  returns (uint _held)
	{
		_held = _tokHeld & 0xffffffffffff;
	}
	// ---------------------------------------------------
	// allocate a new account by setting alloc to true
	// set the top to bytes of tokens to cur pay id to leave out of current round
	// add holder index, bump the num accounts
	// ---------------------------------------------------
	function addAccount(address _addr) internal  {
		holderAccounts[_addr].alloced = true;
		holderAccounts[_addr].tokens = (curPayoutId * (2 ** 48));
		holderIndexes[numAccounts++] = _addr;
	}
	

// --------------------------------------
// BEGIN ERC-20 from StandardToken
// --------------------------------------
	function totalSupply() constant returns (uint256 supply)
	{
		if (icoStatus == IcoStatusValue.saleOpen
			|| icoStatus == IcoStatusValue.anouncement)
			supply = maxMintableTokens;
		else
			supply = totalTokensMinted;
	}

	function transfer(address _to, uint256 _value) returns (bool success) {

		if ((msg.sender == developers) 
			&&  (now < vestTime)) {
			//statEvent("Tokens not yet vested.");
			return false;
		}


	        //Default assumes totalSupply can't be over max (2^256 - 1).
	        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
	        //Replace the if with this one instead.
	        //if (holderAccounts[msg.sender] >= _value && balances[_to] + _value > holderAccounts[_to]) {

		var (pidFrom, heldFrom) = getPayIdAndHeld(holderAccounts[msg.sender].tokens);
	        if (heldFrom >= _value && _value > 0) {

	            holderAccounts[msg.sender].tokens -= _value;

		    if (!holderAccounts[_to].alloced) {
			addAccount(_to);
		    }

		    uint newHeld = _value + getHeld(holderAccounts[_to].tokens);
		    if (icoStatus == IcoStatusValue.saleOpen) // avoid mcgees gambit
		    	pidFrom = curPayoutId;
		    holderAccounts[_to].tokens = newHeld | (pidFrom * (2 ** 48));

	            Transfer(msg.sender, _to, _value);
	            return true;
	        } else { 
			return false; 
		}
    	}

    	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

		if ((_from == developers) 
			&&  (now < vestTime)) {
			//statEvent("Tokens not yet vested.");
			return false;
		}


        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

		var (pidFrom, heldFrom) = getPayIdAndHeld(holderAccounts[_from].tokens);
        	if (heldFrom >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
	            holderAccounts[_from].tokens -= _value;

		    if (!holderAccounts[_to].alloced)
			addAccount(_to);

		    uint newHeld = _value + getHeld(holderAccounts[_to].tokens);

		    if (icoStatus == IcoStatusValue.saleOpen) // avoid mcgees gambit
		    	pidFrom = curPayoutId;
		    holderAccounts[_to].tokens = newHeld | (pidFrom * (2 ** 48));

	            allowed[_from][msg.sender] -= _value;
	            Transfer(_from, _to, _value);
	            return true;
	        } else { 
		    return false; 
		}
	}


    	function balanceOf(address _owner) constant returns (uint256 balance) {
		// vars default to 0
		if (holderAccounts[_owner].alloced) {
	        	balance = getHeld(holderAccounts[_owner].tokens);
		} 
    	}

    	function approve(address _spender, uint256 _value) returns (bool success) {
        	allowed[msg.sender][_spender] = _value;
        	Approval(msg.sender, _spender, _value);
        	return true;
    	}

    	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      		return allowed[_owner][_spender];
    	}
// ----------------------------------
// END ERC20
// ----------------------------------

  



	// -------------------------------------------
	// default payable function.
	// if sender is e4row  partner, this is a rake fee payment
	// otherwise this is a token purchase.
	// tokens only purchaseable between tokenfundingstart and end
	// -------------------------------------------
	function () payable {
		if (msg.sender == e4_partner) {
		     feePayment(); // from e4row game escrow contract
		} else {
		     purchaseToken();
		}
	}

	// -----------------------------
	// purchase token function - tokens only sold during sale period up until the max tokens
	// purchase price is tokenPrice.  all units in wei.
	// purchaser will not be included in current pay run
	// -----------------------------
	function purchaseToken() payable {

		uint nvalue = msg.value; // being careful to preserve msg.value
		address npurchaser = msg.sender;
		if (nvalue < tokenPrice) 
			throw;

		uint qty = nvalue/tokenPrice;
		updateIcoStatus();
		if (icoStatus != IcoStatusValue.saleOpen) // purchase is closed
			throw;
		if (totalTokensMinted + qty > maxMintableTokens)
			throw;
		if (!holderAccounts[npurchaser].alloced)
			addAccount(npurchaser);
		
		// purchaser waits for next payrun. otherwise can disrupt cur pay run
		uint newHeld = qty + getHeld(holderAccounts[npurchaser].tokens);
		holderAccounts[npurchaser].tokens = newHeld | (curPayoutId * (2 ** 48));

		totalTokensMinted += qty;
		totalTokenFundsReceived += nvalue;

		if (totalTokensMinted == maxMintableTokens) {
			icoStatus = IcoStatusValue.saleClosed;
			//test unnecessary -  if (getNumTokensPurchased() >= minIcoTokenGoal)
			doDeveloperGrant();
			StatEventI("Purchased,Granted", qty);
		} else
			StatEventI("Purchased", qty);

	}


	// ---------------------------
	// accept payment from e4row contract
	// WARNING! DO NOT CALL THIS FUNCTION LEST YOU LOSE YOUR MONEY
	// HOWEVER ADD THIS GIFT TO THE HOLDOVERBALANCE
	// YOU HAVE BEEN WARNED
	// ---------------------------
	function feePayment() payable  
	{
		if (msg.sender != e4_partner) {
			if (msg.value > 0)
				holdoverBalance += msg.value;
			StatEvent("forbidden");
			return; // thank you
		}
		uint nfvalue = msg.value; // preserve value in case changed in dev grant

		updateIcoStatus();

		holdoverBalance += nfvalue;
		partnerCredits += nfvalue;
		StatEventI("Payment", nfvalue);

		if (holdoverBalance > payoutThreshold
			|| payoutBalance > 0)
			doPayout(maxPaysPer);
		
	
	}

	// ---------------------------
	// set the e4row partner, this is only done once
	// ---------------------------
	function setE4RowPartner(address _addr) public	
	{
	// ONLY owner can set and ONLY ONCE! (unless "unlocked" debug)
	// once its locked. ONLY ONCE!
		if (msg.sender == owner) {
			if ((e4_partner == address(0)) || (settingsState == SettingStateValue.debug)) {
				e4_partner = _addr;
				partnerCredits = 0;
				//StatEventI("E4-Set", 0);
			} else {
				StatEvent("Already Set");
			}
		}
	}

	// ----------------------------
	// return the total tokens purchased
	// ----------------------------
	function getNumTokensPurchased() constant returns(uint _purchased)
	{
		_purchased = totalTokensMinted-numDevTokens;
	}

	// ----------------------------
	// return the num games as reported from the e4row  contract
	// ----------------------------
	function getNumGames() constant returns(uint _games)
	{
		//_games = 0;
		if (e4_partner != address(0)) {
			iE4RowEscrow pe4 = iE4RowEscrow(e4_partner);
			_games = uint(pe4.getNumGamesStarted());
		} 
		//else
		//StatEvent("Empty E4");
	}

	// ------------------------------------------------
	// get the founders, auxPartner, developer
	// --------------------------------------------------
	function getSpecialAddresses() constant returns (address _fndr, address _aux, address _dev, address _e4)
	{
		//if (_sender == owner) { // no msg.sender on constant functions at least in mew
			_fndr = founderOrg;
			_aux = auxPartner;
			_dev = developers;
			_e4  = e4_partner;
		//}
	}



	// ----------------------------
	// update the ico status
	// ----------------------------
	function updateIcoStatus() public
	{
		if (icoStatus == IcoStatusValue.succeeded 
			|| icoStatus == IcoStatusValue.failed)
			return;
		else if (icoStatus == IcoStatusValue.anouncement) {
			if (now > fundingStart && now <= fundingDeadline) {
				icoStatus = IcoStatusValue.saleOpen;
				
			} else if (now > fundingDeadline) {
				// should not be here - this will eventually fail
				icoStatus = IcoStatusValue.saleClosed;
			}
		} else {
			uint numP = getNumTokensPurchased();
			uint numG = getNumGames();
			if ((now > fundingDeadline && numP < minIcoTokenGoal)
				|| (now > usageDeadline && numG < minUsageGoal)) {
				icoStatus = IcoStatusValue.failed;
			} else if ((now > fundingDeadline) // dont want to prevent more token sales
				&& (numP >= minIcoTokenGoal)
				&& (numG >= minUsageGoal)) {
				icoStatus = IcoStatusValue.succeeded; // hooray
			}
			if (icoStatus == IcoStatusValue.saleOpen
				&& ((numP >= maxMintableTokens)
				|| (now > fundingDeadline))) {
					icoStatus = IcoStatusValue.saleClosed;
				}
		}

		if (!developersGranted
			&& icoStatus != IcoStatusValue.saleOpen 
			&& icoStatus != IcoStatusValue.anouncement
			&& getNumTokensPurchased() >= minIcoTokenGoal) {
				doDeveloperGrant(); // grant whenever status goes from open to anything...
		}

	
	}

	
	// ----------------------------
	// request refund. Caller must call to request and receive refund 
	// WARNING - withdraw rewards/dividends before calling.
	// YOU HAVE BEEN WARNED
	// ----------------------------
	function requestRefund()
	{
		address nrequester = msg.sender;
		updateIcoStatus();

		uint ntokens = getHeld(holderAccounts[nrequester].tokens);
		if (icoStatus != IcoStatusValue.failed)
			StatEvent("No Refund");
		else if (ntokens == 0)
			StatEvent("No Tokens");
		else {
			uint nrefund = ntokens * tokenPrice;
			if (getNumTokensPurchased() >= minIcoTokenGoal)
				nrefund -= (nrefund /10); // only 90 percent b/c 10 percent payout

			if (!holderAccounts[developers].alloced) 
				addAccount(developers);
			holderAccounts[developers].tokens += ntokens;
			holderAccounts[nrequester].tokens = 0;
			if (holderAccounts[nrequester].balance > 0) {
				// see above warning!!
				holderAccounts[developers].balance += holderAccounts[nrequester].balance;
				holderAccounts[nrequester].balance = 0;
			}

			if (!nrequester.call.gas(rfGas).value(nrefund)())
				throw;
			//StatEventI("Refunded", nrefund);
		}
	}



	// ---------------------------------------------------
	// payout rewards to all token holders
	// use a second holding variable called PayoutBalance to do 
	// the actual payout from b/c too much gas to iterate thru 
	// each payee. Only start a new run at most once per "minpayinterval".
	// Its done in runs of "_numPays"
	// we use special coding for the holderAccounts to avoid a hack
	// of getting paid at the top of the list then transfering tokens
	// to another address at the bottom of the list.
	// because of that each holderAccounts entry gets the payoutid stamped upon it (top two bytes)
	// also a token transfer will transfer the payout id.
	// ---------------------------------------------------
	function doPayout(uint _numPays)  internal
	{
		if (totalTokensMinted == 0)
			return;

		if ((holdoverBalance > 0) 
			&& (payoutBalance == 0)
			&& (now > (lastPayoutTime+minPayInterval))) {
			// start a new run
			curPayoutId++;
			if (curPayoutId >= 32768)
				curPayoutId = 1;
			lastPayoutTime = now;
			payoutBalance = int(holdoverBalance);
			prOrigPayoutBal = payoutBalance;
			prOrigTokensMint = totalTokensMinted;
			holdoverBalance = 0;
			lastPayoutIndex = 0;
			StatEventI("StartRun", uint(curPayoutId));
		} else if (payoutBalance > 0) {
			// work down the p.o.b
			uint nAmount;
			uint nPerTokDistrib = uint(prOrigPayoutBal)/prOrigTokensMint;
			uint paids = 0;
			uint i; // intentional
			for (i = lastPayoutIndex; (paids < _numPays) && (i < numAccounts) && (payoutBalance > 0); i++ ) {
				address a = holderIndexes[i];
				if (a == address(0)) {
					continue;
				}
				var (pid, held) = getPayIdAndHeld(holderAccounts[a].tokens);
				if ((held > 0) && (pid != curPayoutId)) {
					nAmount = nPerTokDistrib * held;
					if (int(nAmount) <= payoutBalance){
						holderAccounts[a].balance += nAmount; 
						holderAccounts[a].tokens = (curPayoutId * (2 ** 48)) | held;
						payoutBalance -= int(nAmount);					
						paids++;
					}
				}
			}
			lastPayoutIndex = i;
			if (lastPayoutIndex >= numAccounts || payoutBalance <= 0) {
				lastPayoutIndex = 0;
				if (payoutBalance > 0)
					holdoverBalance += uint(payoutBalance);// put back any leftovers
				payoutBalance = 0;
				StatEventI("RunComplete", uint(prOrigPayoutBal) );

			} else {
				StatEventI("PayRun", paids );
			}
		}
		
	}


	// ----------------------------
	// sender withdraw entire rewards/dividends
	// ----------------------------
	function withdrawDividends() public returns (uint _amount)
	{
		if (holderAccounts[msg.sender].balance == 0) { 
			//_amount = 0;
			StatEvent("0 Balance");
			return;
		} else {
			if ((msg.sender == developers) 
				&&  (now < vestTime)) {
				//statEvent("Tokens not yet vested.");
				//_amount = 0;
				return;
			}

			_amount = holderAccounts[msg.sender].balance; 
			holderAccounts[msg.sender].balance = 0; 
			if (!msg.sender.call.gas(rwGas).value(_amount)())
				throw;
			//StatEventI("Paid", _amount);
	
		}

	}

	// ----------------------------
	// set gas for operations
	// ----------------------------
	function setOpGas(uint _rm, uint _rf, uint _rw)
	{
		if (msg.sender != owner && msg.sender != developers) {
			//StatEvent("only owner calls");
			return;
		} else {
			rmGas = _rm;
			rfGas = _rf;
			rwGas = _rw;
		}
	}

	// ----------------------------
	// get gas for operations
	// ----------------------------
	function getOpGas() constant returns (uint _rm, uint _rf, uint _rw)
	{
		_rm = rmGas;
		_rf = rfGas;
		_rw = rwGas;
	}
 

	// ----------------------------
	// check rewards.  pass in address of token holder
	// ----------------------------
	function checkDividends(address _addr) constant returns(uint _amount)
	{
		if (holderAccounts[_addr].alloced)
			_amount = holderAccounts[_addr].balance;
	}		


	// ------------------------------------------------
	// icoCheckup - check up call for administrators
	// after sale is closed if min ico tokens sold, 10 percent will be distributed to 
	// company to cover various operating expenses
	// after sale and usage dealines have been met, remaining 90 percent will be distributed to
	// company.
	// ------------------------------------------------
	function icoCheckup() public
	{
		if (msg.sender != owner && msg.sender != developers)
			throw;

		uint nmsgmask;
		//nmsgmask = 0;
	
		if (icoStatus == IcoStatusValue.saleClosed) {
			if ((getNumTokensPurchased() >= minIcoTokenGoal)
				&& (remunerationStage == 0 )) {
				remunerationStage = 1;
				remunerationBalance = (totalTokenFundsReceived/100)*9; // 9 percent
				auxPartnerBalance =  (totalTokenFundsReceived/100); // 1 percent
				nmsgmask |= 1;
			} 
		}
		if (icoStatus == IcoStatusValue.succeeded) {
		
			if (remunerationStage == 0 ) {
				remunerationStage = 1;
				remunerationBalance = (totalTokenFundsReceived/100)*9; 
				auxPartnerBalance =  (totalTokenFundsReceived/100);
				nmsgmask |= 4;
			}
			if (remunerationStage == 1) { // we have already suceeded
				remunerationStage = 2;
				remunerationBalance += totalTokenFundsReceived - (totalTokenFundsReceived/10); // 90 percent
				nmsgmask |= 8;
			}

		}

		uint ntmp;

		if (remunerationBalance > 0) { 
		// only pay one entity per call, dont want to run out of gas
				ntmp = remunerationBalance;
				remunerationBalance = 0;
				if (!founderOrg.call.gas(rmGas).value(ntmp)()) {
					remunerationBalance = ntmp;
					nmsgmask |= 32;
				} else {
					nmsgmask |= 64;
				}	
		} else 	if (auxPartnerBalance > 0) {
		// note the "else" only pay one entity per call, dont want to run out of gas
			ntmp = auxPartnerBalance;
			auxPartnerBalance = 0;
			if (!auxPartner.call.gas(rmGas).value(ntmp)()) {
				auxPartnerBalance = ntmp;
				nmsgmask |= 128;
			}  else {
				nmsgmask |= 256;
			}

		} 
		
		StatEventI("ico-checkup", nmsgmask);
	}


	// ----------------------------
	// swap executor
	// ----------------------------
	function changeOwner(address _addr) 
	{
		if (msg.sender != owner
			|| settingsState == SettingStateValue.lockedRelease)
			 throw;

		owner = _addr;
	}

	// ----------------------------
	// swap developers account
	// ----------------------------
	function changeDevevoperAccont(address _addr) 
	{
		if (msg.sender != owner
			|| settingsState == SettingStateValue.lockedRelease)
			 throw;
		developers = _addr;
	}

	// ----------------------------
	// change founder
	// ----------------------------
	function changeFounder(address _addr) 
	{
		if (msg.sender != owner
			|| settingsState == SettingStateValue.lockedRelease)
			 throw;
		founderOrg = _addr;
	}

	// ----------------------------
	// change auxPartner
	// ----------------------------
	function changeAuxPartner(address _aux) 
	{
		if (msg.sender != owner
			|| settingsState == SettingStateValue.lockedRelease)
			 throw;
		auxPartner = _aux;
	}


	// ----------------------------
	// DEBUG ONLY - end this contract, suicide to developers
	// ----------------------------
	function haraKiri()
	{
		if (settingsState != SettingStateValue.debug)
			throw;
		if (msg.sender != owner)
			 throw;
		suicide(developers);
	}

	// ----------------------------
	// get all ico status, funding and usage info
	// ----------------------------
	function getIcoInfo() constant returns(IcoStatusValue _status, uint _saleStart, uint _saleEnd, uint _usageEnd, uint _saleGoal, uint _usageGoal, uint _sold, uint _used, uint _funds, uint _credits, uint _remuStage, uint _vest)
	{
		_status = icoStatus;
		_saleStart = fundingStart;
		_saleEnd = fundingDeadline;
		_usageEnd = usageDeadline;
		_vest = vestTime;
		_saleGoal = minIcoTokenGoal;
		_usageGoal = minUsageGoal;
		_sold = getNumTokensPurchased();
		_used = getNumGames();
		_funds = totalTokenFundsReceived;
		_credits = partnerCredits;
		_remuStage = remunerationStage;
	}

	// ----------------------------
	// NOTE! CALL AT THE RISK OF RUNNING OUT OF GAS.
	// ANYONE CAN CALL THIS FUNCTION BUT YOU HAVE TO SUPPLY 
	// THE CORRECT AMOUNT OF GAS WHICH MAY DEPEND ON 
	// THE _NUMPAYS PARAMETER.  WHICH MUST BE BETWEEN 1 AND 1000
	// THE STANDARD VALUE IS STORED IN "maxPaysPer"
	// ----------------------------
	function flushDividends(uint _numPays)
	{
		if ((_numPays == 0) || (_numPays > 1000)) {
			StatEvent("Invalid.");
		} else if (holdoverBalance > 0 || payoutBalance > 0) {
			doPayout(_numPays);
		} else {
			StatEvent("Nothing to do.");
		}
				
	}

	function doDeveloperGrant() internal
	{
		if (!developersGranted) {
			developersGranted = true;
			numDevTokens = (totalTokensMinted * 15)/100;
			totalTokensMinted += numDevTokens;
			if (!holderAccounts[developers].alloced) 
				addAccount(developers);
			uint newHeld = getHeld(holderAccounts[developers].tokens) + numDevTokens;
			holderAccounts[developers].tokens = newHeld |  (curPayoutId * (2 ** 48));

		}
	}


}