pragma solidity ^0.4.15;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


contract tokenSPERT {
    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply = 0;


    function tokenSPERT (string _name, string _symbol, uint8 _decimals){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        
    }
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;


    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }
}

contract Presale is owned, tokenSPERT {

        string name = 'Pre-sale Eristica Token';
        string symbol = 'SPERT';
        uint8 decimals = 18;
        
        
function Presale ()
        tokenSPERT (name, symbol, decimals){}
    
    event Transfer(address _from, address _to, uint256 amount); 
    event Burned(address _from, uint256 amount);
        
    function mintToken(address investor, uint256 mintedAmount) public onlyOwner {
        balanceOf[investor] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(this, investor, mintedAmount);
        
    }

 function burnTokens(address _owner) public
        onlyOwner
    {   
        uint  tokens = balanceOf[_owner];
        if(balanceOf[_owner] == 0) throw;
        balanceOf[_owner] = 0;
        totalSupply -= tokens;
        Burned(_owner, tokens);
    }
}

library SafeMath {
    function div(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
     }
    function add(uint a, uint b) internal returns (uint) {
         uint c = a + b;
         assert(c >= a);
         return c;
     }
}


contract ERC20 {
    uint public totalSupply = 0;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    function balanceOf(address _owner) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

} // Functions of ERC20 standard



contract EristicaICO {
    using SafeMath for uint;

    uint public constant Tokens_For_Sale = 482500000*1e18; // Tokens for Sale (HardCap)

    uint public Rate_Eth = 458; // Rate USD per ETH
    uint public Token_Price = 50 * Rate_Eth; // ERT per ETH
    uint public Sold = 0; //Sold tokens


    event LogStartICO();
    event LogPauseICO();
    event LogFinishICO(address bountyFund, address advisorsFund, address teamFund, address challengeFund);
    event LogBuyForInvestor(address investor, uint ertValue, string txHash);
    event LogReplaceToken(address investor, uint ertValue);

    ERT public ert = new ERT(this);
    Presale public presale;

    address public Company;
    address public BountyFund;
    address public AdvisorsFund;
    address public TeamFund;
    address public ChallengeFund;

    address public Manager; // Manager controls contract
    address public Controller_Address1; // First address that is used to buy tokens for other cryptos
    address public Controller_Address2; // Second address that is used to buy tokens for other cryptos
    address public Controller_Address3; // Third address that is used to buy tokens for other cryptos
    modifier managerOnly { require(msg.sender == Manager); _; }
    modifier controllersOnly { require((msg.sender == Controller_Address1) || (msg.sender == Controller_Address2) || (msg.sender == Controller_Address3)); _; }

    uint bountyPart = 150; // 1.5% of TotalSupply for BountyFund
    uint advisorsPart = 389; //3,89% of TotalSupply for AdvisorsFund
    uint teamPart = 1000; //10% of TotalSupply for TeamFund
    uint challengePart = 1000; //10% of TotalSupply for ChallengeFund
    uint icoAndPOfPart = 7461; // 74,61% of TotalSupply for PublicICO and PrivateOffer
    enum StatusICO { Created, Started, Paused, Finished }
    StatusICO statusICO = StatusICO.Created;


    function EristicaICO(address _presale, address _Company, address _BountyFund, address _AdvisorsFund, address _TeamFund, address _ChallengeFund, address _Manager, address _Controller_Address1, address _Controller_Address2, address _Controller_Address3){
       presale = Presale(_presale);
       Company = _Company;
       BountyFund = _BountyFund;
       AdvisorsFund = _AdvisorsFund;
       TeamFund = _TeamFund;
       ChallengeFund = _ChallengeFund;
       Manager = _Manager;
       Controller_Address1 = _Controller_Address1;
       Controller_Address2 = _Controller_Address2;
       Controller_Address3 = _Controller_Address3;
    }

// function for changing rate of ETH and price of token


    function setRate(uint _RateEth) external managerOnly {
       Rate_Eth = _RateEth;
       Token_Price = 50*Rate_Eth;
    }


//ICO status functions

    function startIco() external managerOnly {
       require(statusICO == StatusICO.Created || statusICO == StatusICO.Paused);
       LogStartICO();
       statusICO = StatusICO.Started;
    }

    function pauseIco() external managerOnly {
       require(statusICO == StatusICO.Started);
       statusICO = StatusICO.Paused;
       LogPauseICO();
    }


    function finishIco() external managerOnly { // Funds for minting of tokens

       require(statusICO == StatusICO.Started);

       uint alreadyMinted = ert.totalSupply(); //=PublicICO+PrivateOffer
       uint totalAmount = alreadyMinted * 10000 / icoAndPOfPart;


       ert.mint(BountyFund, bountyPart * totalAmount / 10000); // 1.5% for Bounty
       ert.mint(AdvisorsFund, advisorsPart * totalAmount / 10000); // 3.89% for Advisors
       ert.mint(TeamFund, teamPart * totalAmount / 10000); // 10% for Eristica team
       ert.mint(ChallengeFund, challengePart * totalAmount / 10000); // 10% for Challenge Fund

       ert.defrost();

       statusICO = StatusICO.Finished;
       LogFinishICO(BountyFund, AdvisorsFund, TeamFund, ChallengeFund);
    }

// function that buys tokens when investor sends ETH to address of ICO
    function() external payable {

       buy(msg.sender, msg.value * Token_Price);
    }

// function for buying tokens to investors who paid in other cryptos

    function buyForInvestor(address _investor, uint _ertValue, string _txHash) external controllersOnly {
       buy(_investor, _ertValue);
       LogBuyForInvestor(_investor, _ertValue, _txHash);
    }

//function for buying tokens for presale investors

    function replaceToken(address _investor) managerOnly{
         require(statusICO != StatusICO.Finished);
         uint spertTokens = presale.balanceOf(_investor);
         require(spertTokens > 0);
         presale.burnTokens(_investor);
         ert.mint(_investor, spertTokens);

         LogReplaceToken(_investor, spertTokens);
    }
// internal function for buying tokens

    function buy(address _investor, uint _ertValue) internal {
       require(statusICO == StatusICO.Started);
       require(_ertValue > 0);
       require(Sold + _ertValue <= Tokens_For_Sale);
       ert.mint(_investor, _ertValue);
       Sold = Sold.add(_ertValue);
    }



//function to withdraw ETH from smart contract

    function withdrawEther(uint256 _value) external managerOnly {
       require(statusICO == StatusICO.Finished);
       Company.transfer(_value);
    }

}

contract ERT  is ERC20 {
    using SafeMath for uint;

    string public name = "Eristica TOKEN";
    string public symbol = "ERT";
    uint public decimals = 18;

    address public ico;

    event Burn(address indexed from, uint256 value);

    bool public tokensAreFrozen = true;

    modifier icoOnly { require(msg.sender == ico); _; }

    function ERT(address _ico) {
       ico = _ico;
    }


    function mint(address _holder, uint _value) external icoOnly {
       require(_value != 0);
       balances[_holder] = balances[_holder].add(_value);
       totalSupply = totalSupply.add(_value);
       Transfer(0x0, _holder, _value);
    }


    function defrost() external icoOnly {
       tokensAreFrozen = false;
    }

    function burn(uint256 _value) {
       require(!tokensAreFrozen);
       balances[msg.sender] = balances[msg.sender].sub(_value);
       totalSupply = totalSupply.sub(_value);
       Burn(msg.sender, _value);
    }


    function balanceOf(address _owner) constant returns (uint256) {
         return balances[_owner];
    }


    function transfer(address _to, uint256 _amount) returns (bool) {
        require(!tokensAreFrozen);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _amount) returns (bool) {
        require(!tokensAreFrozen);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
     }


    function approve(address _spender, uint256 _amount) returns (bool) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }
}