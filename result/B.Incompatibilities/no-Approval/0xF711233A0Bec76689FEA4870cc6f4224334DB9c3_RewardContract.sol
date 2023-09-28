/*

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

BETA/DRAFT - NOT TESTED !!! - DO NOT USE THIS SOURCE FOR LIVE-REVARD
Draft 0.3 - 06.feb.2018
      0.4 - 08.feb.2018 .... unused

*/

/*

LoveCoin reward contract (DRAFT)
------------------------

Use case:
Token holders can receive rewards that are bound to a ERC-20 token (see Constructor).
The Token-creator (or several DApps) can deposit profits to this reward-smart-contract.
The Token-holder can deposit his tokens in this SC and can later (see Constructor) withdraw 
his tokens plus the reward in ETH. 

Features of this Contract:
1) No gas-costs for token creator. Every user is self-responsible for receiving rewards by interacting with
   this smart contract.
2) compatible with any existing ERC-20 token.


Example in detail: How a Token-Holder can get rewards in ETH for his tokens?
* Six day's in a week this Reward-SC can receive profits in ETH from (TokenCreator or DApp's).
  In this period the SC can receive ETH and tokens.
  - ETH are received by normal ETH transactions ( function () payable )
  - Tokens are received by 1) calling the approve-function of the ERC-20 token contract,
                           2) calling the confirm_token_deposit() of this smart contract.
 
                           
* One day in a week is 'claiming day' for 24 hours. In this period all token deposits should
  have done. By calling (...to be continued)

withdraw_token_and_eth()
                     _________________                          ____________
                    /                 \                        /
o------------------o                   o-----------------------0 


bool claim_period = true
function bool claim_eth_by_address(adr)
(function bool claim_eth_by_id_id_range( int start_id, int stop_id )

*/

pragma solidity ^0.4.19;


library SafeMath {
  //internals

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  
 function safeDiv(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }  

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

} // library SafeMath



// We need this interface to interact with our ERC20 tokencontract
contract ERC20Interface 
{
         // function totalSupply() public constant returns (uint256);
      function balanceOf(address tokenOwner) public constant returns (uint256 balance);
      function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
      function transfer(address to, uint256 tokens) public returns (bool success);
         // function approve(address spender, uint256 tokens) public returns (bool success);
         // function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
         // event Transfer(address indexed from, address indexed to, uint256 tokens);
         // event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
} 






// ---
// Main reward class
//
contract RewardContract
{
using SafeMath for uint256;              // Make sure to use SafeMath

address public owner;                    // The owner of this contract
address public thisAddress;              // The address of this contract
address TokenContractAddress;            // The address of the ERC20-Token, rewards are paying for
ERC20Interface TokenContract;            // Interface of the ERC20-Token
uint256 public TokenTotal;               // Amount of all deposited tokens
uint256 public CLAIM_INTERVAL_DAYS;      // Interval of claiming_days, f.e. 7 for every thursday, if
                                         // thursday 0:00 is the start date of deploying this contract.

uint    public NumberAddresses;          // Number of registered addresses     
address public firstAddress;             // First Address (for chained Account-list)
address public recently_added_address;   // Recently (the last) added address

uint    public timestamp_contract_start; // First timestamp of constructor
   
string  public debug1;    // RAUS
string  public debug2;    // RAUS
string  public debug3;    // RAUS
address public debug4;    // RAUS
uint256 public debug_wei; // RAUS
 
 
// Stucture for a single account.
struct Account
{
uint256 id;                // Integer index of this entry in AccountStructs
uint256 amount_eth;        // Amount of ETH 
uint256 amount_token;      // Amount of Token
address prev_address;      // Previous address of added account
uint256 last_claimed_day;  // Remember the used claiming_day of this account
} // struct Account

// Public mapping of all accounts
mapping(address => Account) public AccountStructs;

    

// (FIN)
// ---
// Construktor
// 
function RewardContract () public
{
owner                    = msg.sender;
timestamp_contract_start = now;

// Global initialisation ------------------------------------------------------------

// Address of TokenContract (Lovcoin)
TokenContractAddress     = 0x26B1FBE292502da2C8fCdcCF9426304d0900b703;

// Interval to claimday - f.e. every 7 days (
//CLAIM_INTERVAL_DAYS      = 7; 
CLAIM_INTERVAL_DAYS      = 2; 

// ----------------------------------------------------------------------------------

TokenContract            = ERC20Interface(TokenContractAddress); // LOV's is 0x26B1FBE292502da2C8fCdcCF9426304d0900b703
NumberAddresses          = 0; // Solidity uses zero-state default values, only to make it more obvious

// Address of this contract
thisAddress              = address(this);

} // Construktor




// (FIN)
//
// Calculates 'percent' 
// (Inspired by https://stackoverflow.com/questions/42738640/division-in-ethereum-solidity)
//
function percent(uint numerator, uint denominator, uint precision) public 

  constant returns(uint quotient) {

         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
} // function percent
  


// (FIN)
//
// calc_wei_rewards
// Calculate the ether (wei) which the token holder may claim.
// This is a stand-alone function without recognizing global variables.
// Here the user can check, how many ETH he may claim for rewards 
//
function calc_wei_rewards( uint256 amountToken, uint256 TokenTotal, uint256 weiTotal ) public constant returns (uint256)
{
uint256 wei_reward = 0;

uint precision = 18;
uint faktor = 10 ** precision; // **-operator is exp

uint percent_big = percent(amountToken, TokenTotal, precision);

wei_reward = weiTotal * percent_big;

wei_reward = wei_reward / faktor;

/*
Example:
1 ETH = 1000000000000000000 WEI (18 Nullen)

amountToken = 256
TokenTotal = 1000

Beispielwerte: (4 ETH)
4000000000000000000


10000000000 - 10 Millarden
50000000
*/

return(wei_reward); 
} // calc_wei_rewards




// (FIN)
// ---
// claim_eth_by_address()
//
function claim_eth_by_address() public returns (bool)
{
bool ret;
uint256 wei_rewards;


if ( is_claim_period( now ) == true )
   {
   // Calculate current day number since starttime.
   uint seconds_since_start = now - timestamp_contract_start; // 'now' is a keyword in solidity - current timestamp / blocktime
   uint days_since_start    = seconds_since_start / 86400;    // A day has 86400 seconds.

   // A tokenholder may only claim one time during the claim period.
   if (AccountStructs[msg.sender].last_claimed_day != days_since_start)
      {
       
      wei_rewards = calc_wei_rewards( AccountStructs[msg.sender].amount_token, TokenTotal, this.balance );
      debug_wei = wei_rewards; // DEBUG - RAUS
      
    
    
      // Remember this claiming day
      AccountStructs[msg.sender].last_claimed_day = days_since_start;
   
      // Assign ETH-reward to account 
      AccountStructs[msg.sender].amount_eth = AccountStructs[msg.sender].amount_eth.safeAdd( wei_rewards ) ;

      ret = true;
      } // if (AccountStructs[msg.sender].last_claimed_day != days_since_start)
   
   } // if ( is_claim_period( now ) == true )
   
 
 
return(ret);
} // claim_eth_by_address


 

// (FIN)
// VORHER Externer Token-Aufruf: function (allowance)
// -> External call ERC20 Token
// approve(address _spender, uint256 _value)
// approve(0xab98cbeb247331ab72a924bd41ce6a3a64161a4e, 5042 ); // Einzahlung von 5042 Tokens
function confirm_token_deposit() public returns (bool)
//function confirm_token_deposit(address msg_sender, uint256 amount_token ) public returns (bool)
{
bool    ret          = false;
uint256 amount_token = 0;   



if ( is_claim_period( now ) == false )
   {
   //
   // if new Account
   //
   if ( AccountStructs[msg.sender].id <= 0 )
      {
      NumberAddresses++;
      if (NumberAddresses == 1) firstAddress  = msg.sender;
      AccountStructs[msg.sender].id           = NumberAddresses; 
      AccountStructs[msg.sender].prev_address = recently_added_address;
      recently_added_address                  = msg.sender; 
      }
   
   // Check token allowance   
   amount_token = TokenContract.allowance( msg.sender, thisAddress );

   // Transfer token to this contract
   TokenContract.transfer(thisAddress, amount_token);
   
   // Register the new token
   if (amount_token > 0)
      {      
      TokenTotal = TokenTotal.safeAdd(amount_token);
      AccountStructs[msg.sender].amount_token = AccountStructs[msg.sender].amount_token.safeAdd( amount_token ) ;
      ret = true;
      } 

   
   } // if ( is_claim_period() == true )
   else 
       {
       revert();
       }





return(ret);
} // confirm_token_deposit








// (FIN)
// ---
// get_account_id
// 
function get_account_id( address _address ) public constant returns (uint256)
{
uint256 ret = AccountStructs[_address].id;
return (ret);
} // get_account_id

 
 
// (FIN)  
// ---
// get_account_balance_eth
//  
function get_account_balance_eth( address _address ) public constant returns (uint256)
{
uint256 ret = AccountStructs[_address].amount_eth;
return (ret);
} // get_account_balance_eth



// (FIN)
// ---
// get_account_balance_token
// 
function get_account_balance_token( address _address ) public constant returns (uint256)
{
uint256 ret = AccountStructs[_address].amount_token;
return (ret);
} // get_account_balance_token




// (FIN)
// ---
// Payment
//
function () payable public
{
/// Nur ausserhalb der Claim-period, ansonsten error
 /// better do nothing here?
if ( is_claim_period( now ) == false )
   {
   // do nothing     
   } // if ( is_claim_period() == true )
   else 
       {
       revert();
       }
       
} // ()



// (FIN)
// ---
// withdraw_token_and_eth
// Komplette ETH und Token zurueckueberweisen
// Withdraw All or nothing.
// 
function withdraw_token_and_eth() public returns (bool)
{
bool ret = false;

if ( is_claim_period( now ) == false )
   {
   uint amount_token = AccountStructs[msg.sender].amount_token;
   uint amount_eth   = AccountStructs[msg.sender].amount_eth;
   
   AccountStructs[msg.sender].amount_token = 0;
   AccountStructs[msg.sender].amount_eth   = 0;

   // Subtract tokens from total amount
   TokenTotal = TokenTotal.safeSub( amount_token );
      
      
   TokenContract.transfer(msg.sender, amount_token );   
   msg.sender.transfer(amount_eth);
   ret = true;
   } // if...
   
return (ret);
} // withdraw_token_and_eth





// (FIN)
// is_claim_period - checks if now is the day for claiming
//
function is_claim_period( uint timestamp_to_check ) public constant returns (bool)
{
bool check = false;

uint seconds_since_start = timestamp_to_check - timestamp_contract_start;
uint days_since_start    = seconds_since_start / 86400; // A day has 86400 seconds

if ( ( days_since_start % CLAIM_INTERVAL_DAYS ) == 0) check = true; 
                                  
return( check );    
} // is_claim_period





// DEBUG - RAUS, wenn das hier live geht!!!
// Kill (owner only)
//
function kill () public
{
if (msg.sender != owner) return;

// Transfer tokens back to owner
uint256 balance = TokenContract.balanceOf(this);
assert(balance > 0);
TokenContract.transfer(owner, balance);
 
owner.transfer( this.balance );
selfdestruct(owner);
} // kill


} // contract RewardContract