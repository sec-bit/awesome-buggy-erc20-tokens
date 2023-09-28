pragma solidity ^0.4.11;

/*

--------------------
Distribute PP Tokens
Token: ICX
Qty: 9722223  (9722223000000000000000000)
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
    ERC20 public token = ERC20(0xb5a5f22694352c15b00323844ad545abb2b11028); // ICX 0xb5a5f22694352c15b00323844ad545abb2b11028

	// ETH to token exchange rate (in tokens)
	uint public ethToTokenRate = 2777; // ICX tokens

	// ICO multisig address
	address public multisig = 0x76111676d01316099840A162cb45b8e28e39Cfce; // PP.eth 0x76111676d01316099840A162cb45b8e28e39Cfce

	// Tokens to withhold per person (to cover gas costs)  // SEE ABOVE
	uint public withhold = 0;  // NOT USED WITH ICX, SEE ABOVE

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
		admins.push(msg.sender);
		admins.push(0x8FB9A786BA4670AD13598b01576d247De09C79d1);
		admins.push(0x008bEd0B3e3a7E7122D458312bBf47B198D58A48);
		admins.push(0x006501524133105eF4C679c40c7df9BeFf8B0FED);
		admins.push(0xed4aEddAaEDA94a7617B2C9D4CBF9a9eDC781573);
		admins.push(0xff4C40e273b4fAB581428455b1148352D13CCbf1);

		// ------------------------- PAYEES ----------------------- //
		
		payees.push(Payee({addr:0x739EB2b1eF52dF7eb8666D70b1608118AF8c2e30, contributionWei:500000000000000000, paid:false}));
		payees.push(Payee({addr:0xaF2017C09a1713A36953232192FdBcd24a483ba6, contributionWei:881250000000000000000, paid:false}));
		payees.push(Payee({addr:0x4022Ced7511440480311CC4813FB38925e4dC40b, contributionWei:375000000000000000000, paid:false}));
		payees.push(Payee({addr:0x0b6DF62a52e9c60f07fc8B4d4F90Cab716367fb7, contributionWei:225000000000000000000, paid:false}));
		payees.push(Payee({addr:0x20A2F38c02a27292afEc7C90609e5Bd413Ab4DD9, contributionWei:187500000000000000000, paid:false}));
		payees.push(Payee({addr:0xA4f8506E30991434204BC43975079aD93C8C5651, contributionWei:150000000000000000000, paid:false}));
		payees.push(Payee({addr:0x00EbB687BF422b849cF96948c7a5eb9B3eEC79e2, contributionWei:150000000000000000000, paid:false}));
		payees.push(Payee({addr:0xf41Dcd2a852eC72440426EA70EA686E8b67e4922, contributionWei:112500000000000000000, paid:false}));
		payees.push(Payee({addr:0x002bC06b75aD3568DC693A26eEA1629035B45389, contributionWei:112500000000000000000, paid:false}));
		payees.push(Payee({addr:0xa6E78caa11Ad160c6287a071949bB899a009DafA, contributionWei:100010000000000000000, paid:false}));
		payees.push(Payee({addr:0x4d308C991859D59fA9086ad18cBdD9c4534C9FCd, contributionWei:90002000000000000000, paid:false}));
		payees.push(Payee({addr:0x000354015865e6A7F83B8973418c9a0CF6B6DA3C, contributionWei:84000000000000000000, paid:false}));
		payees.push(Payee({addr:0xE2Ae58AFecF6195D51DA29250f8Db4C8F3222440, contributionWei:78000000000000000000, paid:false}));
		payees.push(Payee({addr:0x384Fd61F4bEdC0eE1E2c5f91095620024B8e83EB, contributionWei:75000000000000000000, paid:false}));
		payees.push(Payee({addr:0x572a26bF9358c099CC2FB0Be9c8B99499acA42C5, contributionWei:74958003182000000000, paid:false}));
		payees.push(Payee({addr:0x8dCd6294cE580bc6D17304a0a5023289dffED7d6, contributionWei:60840000000000000000, paid:false}));
		payees.push(Payee({addr:0x46cCc6b127D6d4d04080Da2D3bb5Fa9Fb294708a, contributionWei:50000000000000000000, paid:false}));
		payees.push(Payee({addr:0xFf651EAD42b8EeA0B9cB88EDc92704ef6af372Ce, contributionWei:39000000000000000000, paid:false}));
		payees.push(Payee({addr:0x0007216e1eBC0E02B7A45448bECA6e3faA6E4694, contributionWei:39000000000000000000, paid:false}));
		payees.push(Payee({addr:0xbC306679FC4c3f51D91b1e8a55aEa3461675da18, contributionWei:31200000000000000000, paid:false}));
		payees.push(Payee({addr:0xaA03d7f016216f723ddDdE3A5A18e9F640766a5a, contributionWei:31200000000000000000, paid:false}));
		payees.push(Payee({addr:0x491b972AC0E1B26ca9F382493Ce26a8c458a6Ca5, contributionWei:25740000000000000000, paid:false}));
		payees.push(Payee({addr:0xfBFcb29Ff159a686d2A0A3992E794A3660EAeFE4, contributionWei:23400000000000000000, paid:false}));
		payees.push(Payee({addr:0x7993d82DCaaE05f60576AbA0F386994AebdEd764, contributionWei:23400000000000000000, paid:false}));
		payees.push(Payee({addr:0xa722F9F5D744D508C155fCEb9245CA57B5D13Bb5, contributionWei:23400000000000000000, paid:false}));
		payees.push(Payee({addr:0xBAB1033f57B5a4DdD009dd7cdB601b49ed5c0F58, contributionWei:23400000000000000000, paid:false}));
		payees.push(Payee({addr:0x0466A804c880Cd5F225486A5D0f556be25B6fCC8, contributionWei:23400000000000000000, paid:false}));
		payees.push(Payee({addr:0x22aAE1D3CaEbAAbAbe90016fCaDe68652414B0e0, contributionWei:22500000000000000000, paid:false}));
		payees.push(Payee({addr:0x0AC776c3109f673B9737Ca1b208B20084cf931B8, contributionWei:22500000000000000000, paid:false}));
		payees.push(Payee({addr:0x0584e184Eb509FA6417371C8A171206658792Da0, contributionWei:22500000000000000000, paid:false}));
		payees.push(Payee({addr:0xFDF13343F1E3626491066563aB6D787b9755cc17, contributionWei:22500000000000000000, paid:false}));
		payees.push(Payee({addr:0x00566011c133ccBD50aB7088DFA1434e31e42946, contributionWei:21600000000000000000, paid:false}));
		payees.push(Payee({addr:0x907F6fB76D13Fa7244851Ee390DfE9c6B2135ec5, contributionWei:18000000000000000000, paid:false}));
		payees.push(Payee({addr:0x7cC6eeDb3Ff2Fddd9bA63E6D09F919DaB7D00b5e, contributionWei:18000000000000000000, paid:false}));
		payees.push(Payee({addr:0x2c1f43348d4bDFFdA271bD2b8Bae04f3d3542DAE, contributionWei:18000000000000000000, paid:false}));
		payees.push(Payee({addr:0xd71932c505bEeb85e488182bCc07471a8CFa93Cb, contributionWei:18000000000000000000, paid:false}));
		payees.push(Payee({addr:0x9da457aEEae3FC6F30314a61b181228B6Ba4A446, contributionWei:18000000000000000000, paid:false}));
		payees.push(Payee({addr:0x87d9342b59734fa3cc54ef9be44a6cb469d8f477, contributionWei:18000000000000000000, paid:false}));
		payees.push(Payee({addr:0xfeFEaA909C40c40FFa8f1Ad85019496a04636642, contributionWei:18000000000000000000, paid:false}));
		payees.push(Payee({addr:0xCcEf913c5d5a017640DB181791C9E6256b264599, contributionWei:16000000000000000000, paid:false}));
		payees.push(Payee({addr:0xe6497414EB0b19BbeB1d41451cA096ad1656Fa17, contributionWei:14250000000000000000, paid:false}));
		payees.push(Payee({addr:0xecc996953e976a305ee585a9c7bbbcc85d1c467b, contributionWei:9500000000000000000, paid:false}));
		payees.push(Payee({addr:0x044a9c43e95AA9FD28EEa25131A62b602D304F1f, contributionWei:9500000000000000000, paid:false}));
		payees.push(Payee({addr:0xCAAd07A7712f720977660447463465a56543c681, contributionWei:9500000000000000000, paid:false}));
		payees.push(Payee({addr:0xfBfE2A528067B1bb50B926D79e8575154C1dC961, contributionWei:9500000000000000000, paid:false}));
		payees.push(Payee({addr:0xF1BB2d74C9A0ad3c6478A3b87B417132509f673F, contributionWei:9500000000000000000, paid:false}));
		payees.push(Payee({addr:0xBd59bB57dCa0ca22C5FcFb26A6EAaf64451bfB68, contributionWei:9500000000000000000, paid:false}));
		payees.push(Payee({addr:0xff4c40e273b4fab581428455b1148352d13ccbf1, contributionWei:39000000000000000000, paid:false}));
		payees.push(Payee({addr:0xe204f47c00bf581d3673b194ac2b1d29950d6ad3, contributionWei:8550000000000000000, paid:false}));
		payees.push(Payee({addr:0x85591bFABB18Be044fA98D72F7093469C588483C, contributionWei:16700000000000000000, paid:false}));
		payees.push(Payee({addr:0x2a7B8545c9f66e82Ac8237D47a609f0cb884C3cE, contributionWei:6650000000000000000, paid:false}));
		payees.push(Payee({addr:0x867D6B56809D4545A7F53E1d4faBE9086FDeb60B, contributionWei:9500000000000000000, paid:false}));
		payees.push(Payee({addr:0x9e7De6F979a72908a0Be23429433813D8bC94a83, contributionWei:4750000000000000000, paid:false}));
		payees.push(Payee({addr:0xb922C4e953F85972702af982A0a14e24867C7f8d, contributionWei:300000000000000000, paid:false}));

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