pragma solidity ^0.4.11;

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
    ERC20 public token = ERC20(0x05f4a42e251f2d52b8ed15e9fedaacfcef1fad27); // ZIL   

	// ETH to token exchange rate (in tokens)
	uint public ethToTokenRate = 129857; // ZIL Tokens

	// ICO multisig address
	address public multisig = 0x91e65a0e5ff0F0E8fBA65F3636a7cd74f4c9f0E2; // ZIL Wallet

	// Tokens to withhold per person (to cover gas costs)  // SEE ABOVE
	uint public withhold = 0;  // NOT USED WITH ZIL, SEE ABOVE

	// Payees
	struct Payee {
		address addr;
		uint contributionWei;
		bool paid;
	}

	Payee[] public payees;

	address[] public admins;

	// Token decimal multiplier - 12 decimals
	uint public tokenMultiplier = 1000000000000;

	// ETH to wei
	uint public ethToWei = 1000000000000000000;

	// Has withdrawal function been deployed to distribute tokens?
	bool public withdrawalDeployed = false;


	function Distribute() public {
		//--------------------------ADMINS--------------------------//
		
		admins.push(msg.sender);
		admins.push(0x91e65a0e5ff0F0E8fBA65F3636a7cd74f4c9f0E2);

		// ------------------------- PAYEES ----------------------- //

		payees.push(Payee({addr:0x9e7De6F979a72908a0Be23429433813D8bC94a83, contributionWei:40000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xEA8356f5e9B8206EaCDc3176B2AfEcB4F44DD1b8, contributionWei:40000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x739EB2b1eF52dF7eb8666D70b1608118AF8c2e30, contributionWei:40000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xb72b7B33Af65CF47785D70b02c7E896482b77205, contributionWei:40000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x491b972AC0E1B26ca9F382493Ce26a8c458a6Ca5, contributionWei:37000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xfBFcb29Ff159a686d2A0A3992E794A3660EAeFE4, contributionWei:30000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xBAB1033f57B5a4DdD009dd7cdB601b49ed5c0F58, contributionWei:30000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xecc996953e976a305ee585a9c7bbbcc85d1c467b, contributionWei:30000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x5BF688EEb7857748CdD99d269DFa08B3f56f900B, contributionWei:30000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x0eD760957da606b721D4E68238392a2EB03B940B, contributionWei:30000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xfa97c22a03d8522988c709c24283c0918a59c795, contributionWei:30000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x0AC776c3109f673B9737Ca1b208B20084cf931B8, contributionWei:25000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xF1BB2d74C9A0ad3c6478A3b87B417132509f673F, contributionWei:25000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xd71932c505beeb85e488182bcc07471a8cfa93cb, contributionWei:25000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xfBfE2A528067B1bb50B926D79e8575154C1dC961, contributionWei:25000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xe6c769559926F615CFe6bac952e28A40525c9CF6, contributionWei:22000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x6944bd031a455eF1db6f3b3761290D8200245f64, contributionWei:21000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xacedc52037D18C39f38E5A3A78a80e32ffFA34D3, contributionWei:20000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xeC6CAF005C7b8Db6b51dAf125443a6bCe292dFc3, contributionWei:20000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xe204f47c00bf581d3673b194ac2b1d29950d6ad3, contributionWei:20000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xf41Dcd2a852eC72440426EA70EA686E8b67e4922, contributionWei:20000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x589bD9824EA125BF59a76A6CB79468336955dCEa, contributionWei:20000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x1240Cd12B3A0F324272d729613473A5Aed241607, contributionWei:20000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xdD7194415d1095916aa54a301d954A9a82c591EC, contributionWei:20000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xce38acf94281f16259a1eee2a4f61ccc537296ff, contributionWei:20000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xD291Cd1ad826eF30D40aA44799b5BA6F33cC26de, contributionWei:15000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x7166C092902A0345d9124d90C7FeA75450E3e5b6, contributionWei:15000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xbbe343ED0E7823F4E0F3420D20c6Eb9789c14AD8, contributionWei:15000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xDC95764e664AA9f3E090494989231BD2486F5de0, contributionWei:15000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xA664beecd0e6E04EE48f5B4Fb5183bd548b4A912, contributionWei:15000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x00D7b44598E95Abf195e4276f42a3e07F9D130E3, contributionWei:15000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x48daFCfd4F76d6274039bc1c459E69A6daA434CC, contributionWei:12000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xADBD3F608677bEF61958C13Fd6d758bd7A9a25d6, contributionWei:10500000000000000000, paid:false}));		
		payees.push(Payee({addr:0x044a9c43e95aa9fd28eea25131a62b602d304f1f, contributionWei:10000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x20Ec8fE549CD5978bcCC184EfAeE20027eD0c154, contributionWei:10000000000000000000, paid:false}));		
		payees.push(Payee({addr:0xecFe6c6676a25Ee86f2B717011AA52394d43E17a, contributionWei:10000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x0D032b245004849D50cd3FF7a84bf9f8057f24F9, contributionWei:10000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x64CD180d8382b153e3acb6218c54b498819D3905, contributionWei:10000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x59FD8C50d174d9683DA90A515C30fc4997bDc556, contributionWei:10000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x83CA062Ea4a1725B9E7841DFCB1ae342a10d8c1F, contributionWei:6000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x2c1f43348d4bDFFdA271bD2b8Bae04f3d3542DAE, contributionWei:5000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x78d4F243a7F6368f1684C85eDBAC6F2C344B7739, contributionWei:5000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x8d4f315df4860758E559d63734BD96Fd3C9f86d8, contributionWei:5000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x0584e184Eb509FA6417371C8A171206658792Da0, contributionWei:2000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x861038738e10bA2963F57612179957ec521089cD, contributionWei:1800000000000000000, paid:false}));		
		payees.push(Payee({addr:0xCbB913B805033226f2c6b11117251c0FF1A3431D, contributionWei:1000000000000000000, paid:false}));		
		payees.push(Payee({addr:0x3E08FC7Cb11366c6E0091fb0fD64E0E5F8190bCa, contributionWei:1000000000000000000, paid:false}));		


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