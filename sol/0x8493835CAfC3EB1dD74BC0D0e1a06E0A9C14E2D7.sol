/*

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

https://www.lovco.in/
https://lovcoin.github.io/

Version 1.0 - 21.feb.2018

LoveLock smart contract - https://www.lovelock-online.com.

*/




// We need this interface to interact with our ERC20 tokencontract
contract ERC20Interface 
{
         // function totalSupply() public constant returns (uint256);
      function balanceOf(address tokenOwner) public constant returns (uint256 balance);
      function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
      function transfer(address to, uint256 tokens) public returns (bool success);
         // function approve(address spender, uint256 tokens) public returns (bool success);
      function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
         // event Transfer(address indexed from, address indexed to, uint256 tokens);
         // event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
} 




// ---
// Main LoveLock class
//
contract LoveLock
{
address public owner;                    // The owner of this contract

uint    public lastrecordindex;          // The highest record index, number of lovelocks
uint    public lovelock_price;           // Lovelock price (starts with ~ $9.99 in ETH, 0.0119 ETH)
uint    public lovelock_price_LOV;       // Lovelock price (in LOV!)

address public last_buyer;               // Last buyer of a lovelock.
bytes32 public last_hash;                // Last index hash

address TokenContractAddress;            // The address of the ERC20-Token, rewards are paying for
ERC20Interface TokenContract;            // Interface of the ERC20-Token
address public thisAddress;              // The address of this contract

uint    public debug_last_approved;


//
// Datasets for the lovelocks.
//
struct DataRecord
{
string name1;
string name2;
string lovemessage;
uint   locktype;
uint   timestamp;
} // struct DataRecord

mapping(bytes32 => DataRecord) public DataRecordStructs;

//
// Dataset for indexes
//
struct DataRecordIndex
{
bytes32 index_hash;
} // DataRecordIndex

mapping(uint256 => DataRecordIndex) public DataRecordIndexStructs;



// ---
// Constructor
// 
function LoveLock () public
{
// Today 20.Feb.2018 - 1 ETH=$950, 0.01 ~ $9.99

lovelock_price           = 10000000000000000;

lovelock_price_LOV       = 1000000000000000000*5000; // 5000 LOV
                           
owner                    = msg.sender;

// Address of TokenContract
TokenContractAddress     = 0x26B1FBE292502da2C8fCdcCF9426304d0900b703; // Mainnet
TokenContract            = ERC20Interface(TokenContractAddress); 

thisAddress              = address(this);

lastrecordindex          = 0;
} // Constructor
 



// ---
// withdraw_to_owner
// 
function withdraw_to_owner() public returns (bool)
{
if (msg.sender != owner) return (false);

// Transfer tokens to owner
uint256 balance = TokenContract.balanceOf(this);
TokenContract.transfer(owner, balance); 

// Transfer ETH to owner
owner.transfer( this.balance );

return(true);
} // withdraw_to_owner



// ---
// number_to_hash
//
function number_to_hash( uint param ) public constant returns (bytes32)
{
bytes32 ret = keccak256(param);
return(ret);
} // number_to_hash





// ---
// Web3 event 'LovelockPayment'
//
event LovelockPayment
(
address indexed _from,
bytes32 hashindex,
uint _value2
);
    
    
// ---
// buy lovelock (with ETH)
//
function buy_lovelock( bytes32 index_hash, string name1, string name2, string lovemessage, uint locktype ) public payable returns (uint)
{
last_buyer = msg.sender;


// Overwrite protection
if (DataRecordStructs[index_hash].timestamp > 1000)
   {
   return 0;
   }
   

// only if payed the full price.
if ( msg.value >= lovelock_price )
   {
   
   // ----- Create the lock ---------------------------------
    // Increment the record index.
    lastrecordindex = lastrecordindex + 1;  
       
    last_hash = index_hash;
        
    // Store the lovelock data into the record for the eternity.
    DataRecordStructs[last_hash].name1       = name1;
    DataRecordStructs[last_hash].name2       = name2;
    DataRecordStructs[last_hash].lovemessage = lovemessage;
    DataRecordStructs[last_hash].locktype    = locktype;
    DataRecordStructs[last_hash].timestamp   = now;
   
    DataRecordIndexStructs[lastrecordindex].index_hash = last_hash;
   
    // The Web3-Event!!!
    LovelockPayment(msg.sender, last_hash, lastrecordindex);  
   // --- END lock creation --------------------------------------
   
   return(1);
   } else
     {
     revert();
     }

 
return(0);
} // buy_lovelock




// ---
// buy buy_lovelock_withLOV
//
function buy_lovelock_withLOV( bytes32 index_hash, string name1, string name2, string lovemessage, uint locktype ) public returns (uint)
{
last_buyer = msg.sender;
uint256      amount_token = 0; 


// Overwrite protection
if (DataRecordStructs[index_hash].timestamp > 1000)
   {
   return 0;
   }

    
// Check token allowance   
amount_token = TokenContract.allowance( msg.sender, thisAddress );
debug_last_approved = amount_token;
   

if (amount_token >= lovelock_price_LOV)
   {

   // Transfer token to this contract
   bool success = TokenContract.transferFrom(msg.sender, thisAddress, amount_token);
          
   if (success == true)
      {   

      // ----- Create the lock ------------------------------
      // Increment the record index.
      lastrecordindex = lastrecordindex + 1;  
            
      last_hash = index_hash;
        
      // Store the lovelock data into the record for the eternity.
      DataRecordStructs[last_hash].name1       = name1;
      DataRecordStructs[last_hash].name2       = name2;
      DataRecordStructs[last_hash].lovemessage = lovemessage;
      DataRecordStructs[last_hash].locktype    = locktype;
      DataRecordStructs[last_hash].timestamp   = now;

      DataRecordIndexStructs[lastrecordindex].index_hash = last_hash;
   
      // The Web3-Event!!!
      LovelockPayment(msg.sender, last_hash, lastrecordindex);  
      // --- END creation -----------------------------------
       
      } // if (success == true)
      else 
         {
         //debug = "transferFrom returns FALSE";   
         }
       
      
     
   return(1); 
   } else
     {
     // low balance  
     //revert();
     }

return(0);
} // buy_lovelock_withLOV




//
// Transfer owner
//
function transfer_owner( address new_owner ) public returns (uint)
{
if (msg.sender != owner) return(0);
require(new_owner != 0);

owner = new_owner;
return(1);
} // function transfer_owner()





} // contract LoveLock