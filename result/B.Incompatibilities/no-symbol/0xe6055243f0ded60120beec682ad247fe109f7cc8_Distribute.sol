pragma solidity ^0.4.11;

/*

--------------------
Distribute PP Tokens
Token: GMT
Qty: 25813000
--------------------
METHODS:
withdrawAll() -- Withdraws tokens to all payee addresses, withholding a quantity for gas cost
changeToken(address _token) -- Changes ERC20 token contract address
returnToSender() -- Returns all tokens and ETH to the multisig address
abort() -- Returns all tokens and ETH to the multisig address, then suicides
--------------------

*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
	function transfer(address _to, uint _value) returns (bool success);
	function balanceOf(address _owner) constant returns (uint balance);
	function approve(address _spender, uint256 value) public returns (bool);
	function transferFrom(address _from, address _to, uint _value) returns (bool success);
	function allowance(address _owner, address _spender) constant returns (uint remaining);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Distribute {

	// The ICO token address
    ERC20 public token = ERC20(0xb3Bd49E28f8F832b8d1E246106991e546c323502);  // GMT 

	// ETH to token exchange rate (in tokens)
	uint public ethToTokenRate = 7774; // GMT tokens.  3320 withheld for gas at this rate.

	// ICO multisig address
	address public multisig = 0x37764Fe50340F0158B9FAceFb3dBaf5222E34a3D; // GMT Multisig 

	// Tokens to withhold per person (to cover gas costs)  // SEE ABOVE
	uint public withhold = 0;  // NOT USED WITH GMT, SEE ABOVE

	// Payees
	struct Payee {
		address addr;
		uint contributionWei;
		bool paid;
	}

	Payee[] public payees;

	address[] public admins;

	// Token decimal multiplier - 18 decimals
	uint public tokenMultiplier = 1000000000000000000;

	// ETH to wei
	uint public ethToWei = 1000000000000000000;

	// Has withdrawal function been deployed to distribute tokens?
	bool public withdrawalDeployed = false;


	function Distribute() public {
		//--------------------------ADMINS--------------------------//
		admins.push(0x8FB9A786BA4670AD13598b01576d247De09C79d1);
		admins.push(0x008bEd0B3e3a7E7122D458312bBf47B198D58A48);
		admins.push(0x006501524133105eF4C679c40c7df9BeFf8B0FED);
		admins.push(0xed4aEddAaEDA94a7617B2C9D4CBF9a9eDC781573);
		admins.push(0xff4C40e273b4fAB581428455b1148352D13CCbf1);

		// ------------------------- PAYEES ----------------------- //
		payees.push(Payee({addr:0x8FB9A786BA4670AD13598b01576d247De09C79d1, contributionWei:250000000000000000, paid:false})); // .25 ETH to contract deployer for gas cost
		payees.push(Payee({addr:0x20A2F38c02a27292afEc7C90609e5Bd413Ab4DD9, contributionWei:500000000000000000000, paid:false}));
		payees.push(Payee({addr:0x296b436529DC64C03E9cEB77F032a04071D6c057, contributionWei:400000000000000000000, paid:false}));
		payees.push(Payee({addr:0xDAf99f1E196245c364Cde16cAbAE8BEbbe24476b, contributionWei:400000000000000000000, paid:false}));
		payees.push(Payee({addr:0x9ebab12563968d8255f546831ec4833449234fFa, contributionWei:250000000000000000000, paid:false}));
		payees.push(Payee({addr:0xF4C5787170bCe287F86367963A3E932Dd7D389Ee, contributionWei:135000000000000000000, paid:false}));
		payees.push(Payee({addr:0xA534F5b9a5D115563A28FccC5C92ada771da236E, contributionWei:120000000000000000000, paid:false}));
		payees.push(Payee({addr:0x0466A804c880Cd5F225486A5D0f556be25B6fCC8, contributionWei:100000000000000000000, paid:false}));
		payees.push(Payee({addr:0xff651ead42b8eea0b9cb88edc92704ef6af372ce, contributionWei:100000000000000000000, paid:false}));
		payees.push(Payee({addr:0x5F0f119419b528C804C9BbBF15455d36450406B4, contributionWei:100000000000000000000, paid:false}));
		payees.push(Payee({addr:0x7868f5E14ad4e69BdB80e6c96E6890BC43118E00, contributionWei:100000000000000000000, paid:false}));
		payees.push(Payee({addr:0x0d82CcaacDAF8DA2cca723f7203BE3ac57B6C3E7, contributionWei:100000000000000000000, paid:false}));
		payees.push(Payee({addr:0xa6E78caa11Ad160c6287a071949bB899a009DafA, contributionWei:74500000000000000000, paid:false}));
		payees.push(Payee({addr:0x00694c41975e95e435461192abb86c56a3c2e66f, contributionWei:75000000000000000000, paid:false}));
		payees.push(Payee({addr:0x660E067602dC965F10928B933F21bA6dCb2ece9C, contributionWei:75000000000000000000, paid:false}));
		payees.push(Payee({addr:0x5Bc788e50c6EB950fEd19dDb488fad9Bbb22300E, contributionWei:75000000000000000000, paid:false}));
		payees.push(Payee({addr:0x6113952cf5eed648e1aea0bee279933f72515c8d, contributionWei:50000000000000000000, paid:false}));
		payees.push(Payee({addr:0x8F212180bF6B8178559a67268502057Fb0043Dd9, contributionWei:50000000000000000000, paid:false}));
		payees.push(Payee({addr:0xbD9Fa48f74258AcA384fADebcc0340C74Bd4272B, contributionWei:50000000000000000000, paid:false}));
		payees.push(Payee({addr:0xFB6c8369065b834d8907406feAe7D331c0e77e07, contributionWei:40000000000000000000, paid:false}));
		payees.push(Payee({addr:0x82e4D78C6c62D461251fA5A1D4Deb9F0fE378E30, contributionWei:40000000000000000000, paid:false}));
		payees.push(Payee({addr:0x007fC6a6D1E6Ec2c952bAedAb047D3fd87D59256, contributionWei:35000000000000000000, paid:false}));
		payees.push(Payee({addr:0xc51fda81966704aD304a4D733a0306CB1ea76729, contributionWei:30000000000000000000, paid:false}));
		payees.push(Payee({addr:0x907F6fB76D13Fa7244851Ee390DfE9c6B2135ec5, contributionWei:30000000000000000000, paid:false}));
		payees.push(Payee({addr:0x00505d0a66a0646c85095bbfd75f57c4e1c431ba, contributionWei:30000000000000000000, paid:false}));
		payees.push(Payee({addr:0xe204f47c00bf581d3673b194ac2b1d29950d6ad3, contributionWei:25000000000000000000, paid:false}));
		payees.push(Payee({addr:0xf69819e5cadb4b08ef2b905df3ec6bd5f5b1a985, contributionWei:20000000000000000000, paid:false}));
		payees.push(Payee({addr:0xf094bf5a13C34d86F800Fa5B3cd41f7e29A716CE, contributionWei:20000000000000000000, paid:false}));
		payees.push(Payee({addr:0x5BF688EEb7857748CdD99d269DFa08B3f56f900B, contributionWei:20000000000000000000, paid:false}));
		payees.push(Payee({addr:0xfBFcb29Ff159a686d2A0A3992E794A3660EAeFE4, contributionWei:20000000000000000000, paid:false}));
		payees.push(Payee({addr:0x8dCd6294cE580bc6D17304a0a5023289dffED7d6, contributionWei:20000000000000000000, paid:false}));
		payees.push(Payee({addr:0x22aAE1D3CaEbAAbAbe90016fCaDe68652414B0e0, contributionWei:20000000000000000000, paid:false}));
		payees.push(Payee({addr:0xd71932c505bEeb85e488182bCc07471a8CFa93Cb, contributionWei:15000000000000000000, paid:false}));
		payees.push(Payee({addr:0xfBfE2A528067B1bb50B926D79e8575154C1dC961, contributionWei:15000000000000000000, paid:false}));
		payees.push(Payee({addr:0xb922C4e953F85972702af982A0a14e24867C7f8d, contributionWei:14000000000000000000, paid:false}));
		payees.push(Payee({addr:0x8083Eaf0Aa4DeB322f45a39A38e9615CAE6BBe18, contributionWei:11000000000000000000, paid:false}));
		payees.push(Payee({addr:0x37038849339b399c4AA6b07B745e249378b33089, contributionWei:10000000000000000000, paid:false}));
		payees.push(Payee({addr:0xBd042914c93361E248a56db78403E99ef01a1c14, contributionWei:10000000000000000000, paid:false}));
		payees.push(Payee({addr:0x3e638AE8AAc0dB1DfF2f36C399A4621DB064d43a, contributionWei:10000000000000000000, paid:false}));
		payees.push(Payee({addr:0x6595732468A241312bc307F327bA0D64F02b3c20, contributionWei:10000000000000000000, paid:false}));
		payees.push(Payee({addr:0x85591bFABB18Be044fA98D72F7093469C588483C, contributionWei:10000000000000000000, paid:false}));
		payees.push(Payee({addr:0xff4C40e273b4fAB581428455b1148352D13CCbf1, contributionWei:10000000000000000000, paid:false}));
		payees.push(Payee({addr:0x7993d82DCaaE05f60576AbA0F386994AebdEd764, contributionWei:10000000000000000000, paid:false}));
		payees.push(Payee({addr:0x0007216e1eBC0E02B7A45448bECA6e3faA6E4694, contributionWei:10000000000000000000, paid:false}));
		payees.push(Payee({addr:0x87d9342b59734fa3cc54ef9be44a6cb469d8f477, contributionWei:10000000000000000000, paid:false}));
		payees.push(Payee({addr:0x00E2D9F005a1d631591C5BA047232A6516890a9d, contributionWei:10000000000000000000, paid:false}));
		payees.push(Payee({addr:0x2c1f43348d4bDFFdA271bD2b8Bae04f3d3542DAE, contributionWei:7000000000000000000, paid:false}));
		payees.push(Payee({addr:0xA664beecd0e6E04EE48f5B4Fb5183bd548b4A912, contributionWei:6000000000000000000, paid:false}));
		payees.push(Payee({addr:0xBd59bB57dCa0ca22C5FcFb26A6EAaf64451bfB68, contributionWei:6000000000000000000, paid:false}));
		payees.push(Payee({addr:0x808264eeb886d37b706C8e07172d5FdF40dF71A8, contributionWei:6000000000000000000, paid:false}));
		payees.push(Payee({addr:0xDC95764e664AA9f3E090494989231BD2486F5de0, contributionWei:6000000000000000000, paid:false}));
		payees.push(Payee({addr:0x867D6B56809D4545A7F53E1d4faBE9086FDeb60B, contributionWei:5000000000000000000, paid:false}));
		payees.push(Payee({addr:0xecFe6c6676a25Ee86f2B717011AA52394d43E17a, contributionWei:5000000000000000000, paid:false}));
		payees.push(Payee({addr:0xB2cd0402Bc1C5e2d064C78538dF5837b93d7cC99, contributionWei:5000000000000000000, paid:false}));
		payees.push(Payee({addr:0x59FD8C50d174d9683DA90A515C30fc4997bDc556, contributionWei:5000000000000000000, paid:false}));
		payees.push(Payee({addr:0x63DEFE2bC3567e3309a31b27261fE839Ed35ae3A, contributionWei:5000000000000000000, paid:false}));
		payees.push(Payee({addr:0x7166C092902A0345d9124d90C7FeA75450E3e5b6, contributionWei:2000000000000000000, paid:false}));
		payees.push(Payee({addr:0x410a99f620D6382ce5e78b697519668817aFbD5D, contributionWei:2000000000000000000, paid:false}));
		payees.push(Payee({addr:0xCbB913B805033226f2c6b11117251c0FF1A3431D, contributionWei:500000000000000000, paid:false}));
	}

	// Check if user is whitelisted admin
	modifier onlyAdmins() {
		uint8 isAdmin = 0;
		for (uint8 i = 0; i < admins.length; i++) {
			if (admins[i] == msg.sender)
        isAdmin = isAdmin | 1;
		}
		require(isAdmin == 1);
		_;
	}

	// Calculate tokens due
	function tokensDue(uint _contributionWei) public view returns (uint) {
		return _contributionWei*ethToTokenRate/ethToWei;
	}

	// Allow admins to change token contract address, in case the wrong token ends up in this contract
	function changeToken(address _token) public onlyAdmins {
		token = ERC20(_token);
	}

	// Withdraw all tokens to contributing members
	function withdrawAll() public onlyAdmins {
		// Prevent withdrawal function from being called simultaneously by two parties
		require(withdrawalDeployed == false);
		// Confirm sufficient tokens available
		require(validate());
		withdrawalDeployed = true;
		// Send all tokens
		for (uint i = 0; i < payees.length; i++) {
			// Confirm that contributor has not yet been paid is owed more than gas withhold
			if (payees[i].paid == false && tokensDue(payees[i].contributionWei) >= withhold) {
				// Withhold tokens to cover gas cost
				uint tokensToSend = tokensDue(payees[i].contributionWei) - withhold;
				// Send tokens to payee
				require(token.transferFrom(multisig,payees[i].addr, tokensToSend*tokenMultiplier));
				// Mark payee as paid
				payees[i].paid = true;
			}
		}
	}

	// Confirms that enough tokens are available to distribute to all addresses
	function validate() public view returns (bool) {
		// Calculate total tokens due to all contributors
		uint totalTokensDue = 0;
		for (uint i = 0; i < payees.length; i++) {
			if (!payees[i].paid) {
				// Calculate tokens based on ETH contribution
				totalTokensDue += tokensDue(payees[i].contributionWei)*tokenMultiplier;
			}
		}
		return token.balanceOf(multisig) >= totalTokensDue && token.allowance(multisig,address(this)) >= totalTokensDue;
	}

  
	// Return all ETH and tokens to original multisig
	function returnToSender() public onlyAdmins returns (bool) {
		require(token.transfer(multisig, token.balanceOf(address(this))));
		require(multisig.send(this.balance));
		return true;
	}

	// Return all ETH and tokens to original multisig and then suicide
	function abort() public onlyAdmins {
		require(returnToSender());
		selfdestruct(multisig);
	}


}