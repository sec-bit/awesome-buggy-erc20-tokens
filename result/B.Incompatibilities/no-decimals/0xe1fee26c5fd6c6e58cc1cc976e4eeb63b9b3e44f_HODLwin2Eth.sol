pragma solidity ^0.4.16;

// ------------------------------------------------------------------------
// HODLwin2Eth_exchanger
//  This HODL2eth exchanger contract created by the www.HODLwin.com team
//  is heavily based on the tokentraderfactory created by
//  JonnyLatte & BokkyPooBah 2017. released under The MIT licence.
//  big appreciation and respect to those two
//
//  This is a Decentralised trustless contract and when launched will only accept 
//  the token input at launch, in our case the HODLwin token and return ETH
//  in exchange. 
//
//  Once it has been released on the blockchain only the rate of Ethereum
//  swapped in return for the HODLwin tokens and also the owner of the contract 
//  can be changed. 
//  
//  No one including the owner can turn it off or set the price below
//  the original crowdsale price of the token the price can only ever be 
//  set higher than this public crowdsale price. 
//  It is intended that the only way to get Eth out of this contract is to
//  exchange HODLwin tokens for it. It is also setup to receive any Eth sent
//  to store for exchanging for HODLwin tokens.
//
//  original code licensed under:
//   Enjoy. (c) JonnyLatte & BokkyPooBah 2017. The MIT licence.
//  modified code by www.HODLwin.com team
// ------------------------------------------------------------------------

contract ERC20 {
    
  // Events ---------------------------

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

  // Functions ------------------------

  function totalSupply() public constant returns (uint);
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint remaining);

}

contract Owned {
    address public owner;
    address public newOwner;
    
     event OwnershipTransferProposed(address indexed _from, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier checkpermission{
       require(msg.sender == owner && HODLwin2Eth(msg.sender).owner() == owner);
        _;
    }

       function transferOwnership(address _newOwner) public onlyOwner {
    require( _newOwner != owner );
    require( _newOwner != address(0x0) );
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

// contract can buy tokens for ETH
// prices are in amount of wei per batch of token units

contract HODLwin2Eth is Owned {

    address public HODLaddress;       // address of token
    uint256 public mktValue;    // contract buys lots of token at this price
    uint256 public units;       // lot size (token-wei)
    uint256 public origMktValue; //the original crowdsale price
    event HODLrSoldWin(address indexed seller, uint256 amountOfTokensToSell,
        uint256 tokensSold, uint256 etherValueOfTokensSold);
    event mktValueupdated(uint _mktValue);
    // Constructor - only to be called by the HODLwin2EthExchanger contract
    
    function HODLwin2Eth (
        address _HODLaddress,
        uint256 _mktValue,
        uint256 _units,
        uint256 _origMktValue
                ) public {
        HODLaddress       = _HODLaddress;
        mktValue    = _mktValue;
         units       = _units;
         origMktValue = _origMktValue;
           }

     // instructions for HODLr to sell Win tokens for ethers:
    // 1. Calling the HODLwin   approve() function with the following parameters
    //    _spender              is the address of this contract
    //    _value                is the number of tokens to be sold
    // 2. Call the HODLrSellWin() function with the following parameter
    //    amountOfTokensToSell  is the amount of asset tokens to be sold by
    //                          the taker
    //
    // The HODLrSoldWin() event is logged with the following parameters
    //   seller                  is the seller's address
    //   amountOfTokensToSell    is the amount of the asset tokens being
    //                           sold by the taker
    //   tokensSold              is the number of the asset tokens sold
    //   etherValueOfTokensSold  is the ether value of the asset tokens sold
    // Warning you cannot sell less than 1 full token only accepts 1 token or larger
    
    function HODLrSellWin(uint256 amountOfTokensToSell) public {
                // Maximum number of token the contract can buy
            // Note that mktValue has already been validated as > 0
            uint256 can_buy = this.balance / mktValue;
            // Token lots available
            // Note that units has already been validated as > 0
            uint256 order = amountOfTokensToSell / units;
            // Adjust order for funds available
            if(order > can_buy) order = can_buy;
           if(order > 0){
            // Extract user tokens
           
             require (ERC20(HODLaddress).transferFrom(msg.sender, address(this), order * units));
               //  Pay user
             require (msg.sender.send(order * mktValue));
           }
           
            HODLrSoldWin(msg.sender, amountOfTokensToSell, order * units, order * mktValue);
        
    }

function updatemktValue(uint _mktValue) public onlyOwner {
	
    require(_mktValue >= origMktValue);
	mktValue = _mktValue;
   mktValueupdated(_mktValue);
  }
  
    // Taker buys tokens by sending ethers
   function () public payable {
      
    }
}

// This contract deploys HODLwin2Eth contracts and logs the event
contract HODLwin2EthExchanger is Owned {

    event TradeListing(address indexed ownerAddress, address indexed HODLwin2EthAddress,
        address indexed HODLaddress, uint256 mktValue, uint256 units, uint256 origMktValue);
 

    mapping(address => bool) _verify;

    // Anyone can call this method to verify the settings of a
    // HODLwin2Eth contract. The parameters are:
    //   tradeContract  is the address of a HODLwin2Eth contract
    //
    // Return values:
    //   valid        did this HODLwin2EthExchanger create the HODLwin2Eth contract?
    //   owner        is the owner of the HODLwin2Eth contract
    //   HODLaddress  is the ERC20 HODLwin contract address
    //   mktValue     is the buy price in ethers per `units` of HODLwin tokens
    //   units        is the number of units of HODLwin tokens
    //   origMktValue is the original crowdsale price from the public crowdsale
    //
    function verify(address tradeContract) public  constant returns (
        bool    valid,
        address owner,
        address HODLaddress,
        uint256 mktValue,
        uint256 units,
        uint256 origMktValue
      
    ) {
        valid = _verify[tradeContract];
      require (valid);
            HODLwin2Eth t = HODLwin2Eth(tradeContract);
            owner         = t.owner();
            HODLaddress    = t.HODLaddress();
            mktValue      = t.mktValue();
            units         = t.units();
            origMktValue = t.origMktValue();
 }

    // Maker can call this method to create a new HODLwin2Eth contract
    // with the maker being the owner of this new contract
    //
    // Parameters:
    //   HODLaddress  is the address of the HODLwin contract
    //   mktValue     is the buy price in ethers per `units` of HODLwin tokens
    //   sellPrice    is the sell price in ethers per `units` of HODLwin tokens
    //   units        is the number of units of HODLwin tokens
    //
    // For example, setting up the HODLwin2Eth contract for the following
    // buy HODLwin tokens at a rate of 1*e15/1*e18= 0.001 ETH (1ETH=1000WIN)
    //   HODLaddress        0x48c80f1f4d53d5951e5d5438b54cba84f29f32a5
    //   mktValue     1*e15
    //   units        1*e18
    //  
    // The TradeListing() event is logged with the following parameters
    //   ownerAddress        is the Maker's address
    //   HODLwin2EthAddress  is the address of the newly created HODLwin2Eth contract
    //   HODLaddress         is the ERC20 HODLaddress address
    //   mktValue            is the buy price in ethers per `units` of HODLaddress tokens
    //   sellPrice           is the sell price in ethers per `units` of HODLaddress tokens
    //   unit                is the number of units of HODLaddress tokens
    //   buysTokens          is the HODLwin2Eth contract buying tokens?
    //   sellsTokens         is the HODLwin2Eth contract selling tokens?
    //
    function createTradeContract(
        address HODLaddress,
        uint256 mktValue,
        uint256 units,
        uint256 origMktValue
    ) public returns (address trader) {
        // Cannot have invalid HODLaddress
        require (HODLaddress != 0x0);
        // Check for ERC20 allowance function
        // This will throw an error if the allowance function
        // is undefined to prevent GNTs from being used
        // with this HODLwin
        uint256 allowance = ERC20(HODLaddress).allowance(msg.sender, this);
        allowance= allowance;
        // Cannot set zero or negative price
        require(mktValue > 0);
        // Must make profit on spread
       // Cannot buy or sell zero or negative units
        require(units > 0);

        trader = new HODLwin2Eth(
            HODLaddress,
            mktValue,
            units,
            origMktValue
            );
        // Record that this HODLwin created the trader
        _verify[trader] = true;
        // Set the owner to whoever called the function
        HODLwin2Eth(trader).transferOwnership(msg.sender);
        TradeListing(msg.sender, trader, HODLaddress, mktValue, units, origMktValue);
    }

   
    //Fallback Accepts ether even accidental sending 
   function () public payable {
    
  }
   
}