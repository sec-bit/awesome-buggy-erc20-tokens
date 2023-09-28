pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// 'EVE' 'Devery EVE' crowdsale and token contracts
//
// Symbol      : EVE
// Name        : Devery EVE
// Total supply: Minted
// Decimals    : 18
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd for Devery 2018. The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// BokkyPooBah's Token Teleportation Service Interface v1.00
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------
contract BTTSTokenInterface is ERC20Interface {
    uint public constant bttsVersion = 100;

    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";
    bytes4 public constant signedApproveSig = "\xe9\xaf\xa7\xa1";
    bytes4 public constant signedTransferFromSig = "\x34\x4b\xcc\x7d";
    bytes4 public constant signedApproveAndCallSig = "\xf1\x6f\x9b\x53";

    event OwnershipTransferred(address indexed from, address indexed to);
    event MinterUpdated(address from, address to);
    event Mint(address indexed tokenOwner, uint tokens, bool lockAccount);
    event MintingDisabled();
    event TransfersEnabled();
    event AccountUnlocked(address indexed tokenOwner);

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);

    // ------------------------------------------------------------------------
    // signed{X} functions
    // ------------------------------------------------------------------------
    function signedTransferHash(address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferCheck(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedTransfer(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedApproveHash(address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveCheck(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedApprove(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedTransferFromHash(address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferFromCheck(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedTransferFrom(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedApproveAndCallHash(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveAndCallCheck(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedApproveAndCall(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function mint(address tokenOwner, uint tokens, bool lockAccount) public returns (bool success);
    function unlockAccount(address tokenOwner) public;
    function disableMinting() public;
    function enableTransfers() public;

    // ------------------------------------------------------------------------
    // signed{X}Check return status
    // ------------------------------------------------------------------------
    enum CheckResult {
        Success,                           // 0 Success
        NotTransferable,                   // 1 Tokens not transferable yet
        AccountLocked,                     // 2 Account locked
        SignerMismatch,                    // 3 Mismatch in signing account
        AlreadyExecuted,                   // 4 Transfer already executed
        InsufficientApprovedTokens,        // 5 Insufficient approved tokens
        InsufficientApprovedTokensForFees, // 6 Insufficient approved tokens for fees
        InsufficientTokens,                // 7 Insufficient tokens
        InsufficientTokensForFees,         // 8 Insufficient tokens for fees
        OverflowError                      // 9 Overflow error
    }
}


// ----------------------------------------------------------------------------
// Parity PICOPS Whitelist Interface
// ----------------------------------------------------------------------------
contract PICOPSCertifier {
    function certified(address) public constant returns (bool);
}


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// Devery Vesting Contract
// ----------------------------------------------------------------------------
contract DeveryVesting {
    using SafeMath for uint;

    DeveryCrowdsale public crowdsale;
    uint public totalProportion;
    uint public totalTokens;
    uint public startDate;

    struct Entry {
        uint proportion;
        uint periods;
        uint periodLength;
        uint withdrawn;
    }
    mapping (address => Entry) public entries;

    event NewEntry(address indexed holder, uint proportion, uint periods, uint periodLength);
    event Withdrawn(address indexed holder, uint withdrawn);

    function DeveryVesting(address _crowdsale) public {
        crowdsale = DeveryCrowdsale(_crowdsale);
    }

    function addEntryInDays(address holder, uint proportion, uint periods) public {
        addEntry(holder, proportion, periods, 1 days);
    }
    function addEntryInMonths(address holder, uint proportion, uint periods) public {
        addEntry(holder, proportion, periods, 30 days);
    }
    function addEntryInYears(address holder, uint proportion, uint periods) public {
        addEntry(holder, proportion, periods, 365 days);
    }

    function addEntry(address holder, uint proportion, uint periods, uint periodLength) internal {
        require(msg.sender == crowdsale.owner());
        require(holder != address(0));
        require(proportion > 0);
        require(periods > 0);
        require(entries[holder].proportion == 0);
        entries[holder] = Entry({
            proportion: proportion,
            periods: periods,
            periodLength: periodLength,
            withdrawn: 0
        });
        totalProportion = totalProportion.add(proportion);
        NewEntry(holder, proportion, periods, periodLength);
    }

    function tokenShare(address holder) public view returns (uint) {
        uint result = 0;
        Entry memory entry = entries[holder];
        if (entry.proportion > 0 && totalProportion > 0) {
            result = totalTokens.mul(entry.proportion).div(totalProportion);
        }
        return result;
    }
    function vested(address holder, uint time) public view returns (uint) {
        uint result = 0;
        if (startDate > 0 && time > startDate) {
            Entry memory entry = entries[holder];
            if (entry.proportion > 0 && totalProportion > 0) {
                uint _tokenShare = totalTokens.mul(entry.proportion).div(totalProportion);
                if (time >= startDate.add(entry.periods.mul(entry.periodLength))) {
                    result = _tokenShare;
                } else {
                    uint periods = time.sub(startDate).div(entry.periodLength);
                    result = _tokenShare.mul(periods).div(entry.periods);
                }
            }
        }
        return result;
    }
    function withdrawable(address holder) public view returns (uint) {
        uint result = 0;
        Entry memory entry = entries[holder];
        if (entry.proportion > 0 && totalProportion > 0) {
            uint _vested = vested(holder, now);
            result = _vested.sub(entry.withdrawn);
        }
        return result;
    }
    function withdraw() public {
        Entry storage entry = entries[msg.sender];
        require(entry.proportion > 0 && totalProportion > 0);
        uint _vested = vested(msg.sender, now);
        uint _withdrawn = entry.withdrawn;
        require(_vested > _withdrawn);
        uint _withdrawable = _vested.sub(_withdrawn);
        entry.withdrawn = _vested;
        require(crowdsale.bttsToken().transfer(msg.sender, _withdrawable));
        Withdrawn(msg.sender, _withdrawable);
    }
    function withdrawn(address holder) public view returns (uint) {
        Entry memory entry = entries[holder];
        return entry.withdrawn;
    }

    function finalise() public {
        require(msg.sender == address(crowdsale));
        totalTokens = crowdsale.bttsToken().balanceOf(address(this));
        startDate = now;
    }

}


// ----------------------------------------------------------------------------
// Devery Crowdsale Contract
// ----------------------------------------------------------------------------
contract DeveryCrowdsale is Owned {
    using SafeMath for uint;

    BTTSTokenInterface public bttsToken;
    uint8 public constant TOKEN_DECIMALS = 18;

    ERC20Interface public presaleToken = ERC20Interface(0x8ca1d9C33c338520604044977be69a9AC19d6E54);
    uint public presaleEthAmountsProcessed;
    bool public presaleProcessed;
    uint public constant PRESALE_BONUS_PERCENT = 5;

    uint public constant PER_ACCOUNT_ADDITIONAL_TOKENS = 200 * 10**uint(TOKEN_DECIMALS);
    mapping(address => bool) bonusTokensAllocate;

    PICOPSCertifier public picopsCertifier = PICOPSCertifier(0x1e2F058C43ac8965938F6e9CA286685A3E63F24E);

    address public wallet = 0x87410eE93BDa2445339c9372b20BF25e138F858C;
    address public reserveWallet = 0x87410eE93BDa2445339c9372b20BF25e138F858C;
    DeveryVesting public vestingTeamWallet;
    uint public constant TEAM_PERCENT_EVE = 15;
    uint public constant RESERVE_PERCENT_EVE = 25;
    uint public constant TARGET_EVE = 100000000 * 10**uint(TOKEN_DECIMALS);
    uint public constant PRESALEPLUSCROWDSALE_EVE = TARGET_EVE * (100 - TEAM_PERCENT_EVE - RESERVE_PERCENT_EVE) / 100;

    // Start 18 Jan 2018 16:00 UTC => "Fri, 19 Jan 2018 03:00:00 AEDT"
    // new Date(1516291200 * 1000).toUTCString() => "Thu, 18 Jan 2018 16:00:00 UTC"
    uint public startDate = 1516291200;
    uint public firstPeriodEndDate = startDate + 12 hours;
    uint public endDate = startDate + 14 days;

    // ETH/USD rate used 1,000
    uint public usdPerKEther = 1000000;
    uint public constant CAP_USD = 10000000;
    uint public constant MIN_CONTRIBUTION_ETH = 0.01 ether;
    uint public firstPeriodCap = 3 ether;

    uint public contributedEth;
    uint public contributedUsd;
    uint public generatedEve;

    mapping(address => uint) public accountEthAmount;

    bool public finalised;

    event BTTSTokenUpdated(address indexed oldBTTSToken, address indexed newBTTSToken);
    event PICOPSCertifierUpdated(address indexed oldPICOPSCertifier, address indexed newPICOPSCertifier);
    event WalletUpdated(address indexed oldWallet, address indexed newWallet);
    event ReserveWalletUpdated(address indexed oldReserveWallet, address indexed newReserveWallet);
    event StartDateUpdated(uint oldStartDate, uint newStartDate);
    event FirstPeriodEndDateUpdated(uint oldFirstPeriodEndDate, uint newFirstPeriodEndDate);
    event EndDateUpdated(uint oldEndDate, uint newEndDate);
    event UsdPerKEtherUpdated(uint oldUsdPerKEther, uint newUsdPerKEther);
    event FirstPeriodCapUpdated(uint oldFirstPeriodCap, uint newFirstPeriodCap);
    event Contributed(address indexed addr, uint ethAmount, uint ethRefund, uint accountEthAmount, uint usdAmount, uint bonusPercent, uint eveAmount, uint contributedEth, uint contributedUsd, uint generatedEve);

    function DeveryCrowdsale() public {
        vestingTeamWallet = new DeveryVesting(this);
    }

    function setBTTSToken(address _bttsToken) public onlyOwner {
        require(now <= startDate);
        BTTSTokenUpdated(address(bttsToken), _bttsToken);
        bttsToken = BTTSTokenInterface(_bttsToken);
    }
    function setPICOPSCertifier(address _picopsCertifier) public onlyOwner {
        require(now <= startDate);
        PICOPSCertifierUpdated(address(picopsCertifier), _picopsCertifier);
        picopsCertifier = PICOPSCertifier(_picopsCertifier);
    }
    function setWallet(address _wallet) public onlyOwner {
        WalletUpdated(wallet, _wallet);
        wallet = _wallet;
    }
    function setReserveWallet(address _reserveWallet) public onlyOwner {
        ReserveWalletUpdated(reserveWallet, _reserveWallet);
        reserveWallet = _reserveWallet;
    }
    function setStartDate(uint _startDate) public onlyOwner {
        require(_startDate >= now);
        StartDateUpdated(startDate, _startDate);
        startDate = _startDate;
    }
    function setFirstPeriodEndDate(uint _firstPeriodEndDate) public onlyOwner {
        require(_firstPeriodEndDate >= now);
        require(_firstPeriodEndDate >= startDate);
        FirstPeriodEndDateUpdated(firstPeriodEndDate, _firstPeriodEndDate);
        firstPeriodEndDate = _firstPeriodEndDate;
    }
    function setEndDate(uint _endDate) public onlyOwner {
        require(_endDate >= now);
        require(_endDate >= firstPeriodEndDate);
        EndDateUpdated(endDate, _endDate);
        endDate = _endDate;
    }
    function setUsdPerKEther(uint _usdPerKEther) public onlyOwner {
        require(now <= startDate);
        UsdPerKEtherUpdated(usdPerKEther, _usdPerKEther);
        usdPerKEther = _usdPerKEther;
    }
    function setFirstPeriodCap(uint _firstPeriodCap) public onlyOwner {
        require(_firstPeriodCap >= MIN_CONTRIBUTION_ETH);
        FirstPeriodCapUpdated(firstPeriodCap, _firstPeriodCap);
        firstPeriodCap = _firstPeriodCap;
    }

    // usdPerKEther = 1,000,000
    // capEth       = USD 10,000,000 / 1,000 = 10,000
    // presaleEth   = 4,561.764705882353
    // crowdsaleEth = capEth - presaleEth
    //              = 5,438.235294117647
    // totalEve     = 100,000,000
    // presalePlusCrowdsaleEve = 60% x totalEve = 60,000,000
    // evePerEth x presaleEth x 1.05 + evePerEth x crowdsaleEth = presalePlusCrowdsaleEve
    // evePerEth x (presaleEth x 1.05 + crowdsaleEth) = presalePlusCrowdsaleEve
    // evePerEth = presalePlusCrowdsaleEve / (presaleEth x 1.05 + crowdsaleEth)
    //           = 60,000,000/(4,561.764705882353*1.05 + 5,438.235294117647)
    //           = 5,866.19890440108697
    // usdPerEve = 1,000 / 5,866.19890440108697 = 0.170468137254902 

    function capEth() public view returns (uint) {
        return CAP_USD * 10**uint(3 + 18) / usdPerKEther;
    }
    function presaleEth() public view returns (uint) {
        return presaleToken.totalSupply();
    }
    function crowdsaleEth() public view returns (uint) {
        return capEth().sub(presaleEth());
    }
    function eveFromEth(uint ethAmount, uint bonusPercent) public view returns (uint) {
        uint adjustedEth = presaleEth().mul(100 + PRESALE_BONUS_PERCENT).add(crowdsaleEth().mul(100)).div(100);
        return ethAmount.mul(100 + bonusPercent).mul(PRESALEPLUSCROWDSALE_EVE).div(adjustedEth).div(100);
    }
    function evePerEth() public view returns (uint) {
        return eveFromEth(10**18, 0);
    }
    function usdPerEve() public view returns (uint) {
        uint evePerKEth = eveFromEth(10**(18 + 3), 0);
        return usdPerKEther.mul(10**(18 + 18)).div(evePerKEth);
    }

    function generateTokensForPresaleAccounts(address[] accounts) public onlyOwner {
        require(bttsToken != address(0));
        require(!presaleProcessed);
        for (uint i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint ethAmount = presaleToken.balanceOf(account);
            uint eveAmount = bttsToken.balanceOf(account);
            if (eveAmount == 0 && ethAmount != 0) {
                presaleEthAmountsProcessed = presaleEthAmountsProcessed.add(ethAmount);
                accountEthAmount[account] = accountEthAmount[account].add(ethAmount);
                eveAmount = eveFromEth(ethAmount, PRESALE_BONUS_PERCENT);
                eveAmount = eveAmount.add(PER_ACCOUNT_ADDITIONAL_TOKENS);
                bonusTokensAllocate[account] = true;
                uint usdAmount = ethAmount.mul(usdPerKEther).div(10**uint(3 + 18));
                contributedEth = contributedEth.add(ethAmount);
                contributedUsd = contributedUsd.add(usdAmount);
                generatedEve = generatedEve.add(eveAmount);
                Contributed(account, ethAmount, 0, ethAmount, usdAmount, PRESALE_BONUS_PERCENT, eveAmount,
                    contributedEth, contributedUsd, generatedEve);
                bttsToken.mint(account, eveAmount, false);
            }
        }
        if (presaleEthAmountsProcessed == presaleToken.totalSupply()) {
            presaleProcessed = true;
        }
    }

    function () public payable {
        require(!finalised);
        uint ethAmount = msg.value;
        if (msg.sender == owner) {
            require(msg.value == MIN_CONTRIBUTION_ETH);
        } else {
            require(now >= startDate && now <= endDate);
            if (now <= firstPeriodEndDate) {
                require(accountEthAmount[msg.sender].add(ethAmount) <= firstPeriodCap);
                require(picopsCertifier.certified(msg.sender));
            }
        }
        require(contributedEth < capEth());
        require(msg.value >= MIN_CONTRIBUTION_ETH);
        uint ethRefund = 0;
        if (contributedEth.add(ethAmount) > capEth()) {
            ethAmount = capEth().sub(contributedEth);
            ethRefund = msg.value.sub(ethAmount);
        }
        uint usdAmount = ethAmount.mul(usdPerKEther).div(10**uint(3 + 18));
        uint eveAmount = eveFromEth(ethAmount, 0);
        if (picopsCertifier.certified(msg.sender) && !bonusTokensAllocate[msg.sender]) {
            eveAmount = eveAmount.add(PER_ACCOUNT_ADDITIONAL_TOKENS);
            bonusTokensAllocate[msg.sender] = true;
        }
        generatedEve = generatedEve.add(eveAmount);
        contributedEth = contributedEth.add(ethAmount);
        contributedUsd = contributedUsd.add(usdAmount);
        accountEthAmount[msg.sender] = accountEthAmount[msg.sender].add(ethAmount);
        bttsToken.mint(msg.sender, eveAmount, false);
        if (ethAmount > 0) {
            wallet.transfer(ethAmount);
        }
        Contributed(msg.sender, ethAmount, ethRefund, accountEthAmount[msg.sender], usdAmount, 0, eveAmount,
            contributedEth, contributedUsd, generatedEve);
        if (ethRefund > 0) {
            msg.sender.transfer(ethRefund);
        }
    }

    function roundUp(uint a) internal pure returns (uint) {
        uint multiple = 10**uint(TOKEN_DECIMALS);
        uint remainder = a % multiple;
        if (remainder > 0) {
            return a.add(multiple).sub(remainder);
        }
    }
    function finalise() public onlyOwner {
        require(!finalised);
        require(now > endDate || contributedEth >= capEth());
        uint total = generatedEve.mul(100).div(uint(100).sub(TEAM_PERCENT_EVE).sub(RESERVE_PERCENT_EVE));
        uint amountTeam = total.mul(TEAM_PERCENT_EVE).div(100);
        uint amountReserve = total.mul(RESERVE_PERCENT_EVE).div(100);
        generatedEve = generatedEve.add(amountTeam).add(amountReserve);
        uint rounded = roundUp(generatedEve);
        if (rounded > generatedEve) {
            uint dust = rounded.sub(generatedEve);
            generatedEve = generatedEve.add(dust);
            amountReserve = amountReserve.add(dust);
        }
        if (generatedEve > TARGET_EVE) {
            uint diff = generatedEve.sub(TARGET_EVE);
            generatedEve = TARGET_EVE;
            amountReserve = amountReserve.sub(diff);
        }
        bttsToken.mint(address(vestingTeamWallet), amountTeam, false);
        bttsToken.mint(reserveWallet, amountReserve, false);
        bttsToken.disableMinting();
        vestingTeamWallet.finalise();
        finalised = true;
    }
}