// SIMPLECOIN TOKEN
// simplecoin.co
//
// SMP token is a virtual token, governed by ERC20-compatible Ethereum Smart Contract and secured by Ethereum Blockchain
// The official website is https://www.simplecoin.co
//
// The uints are all in wei and WEI tokens (*10^-18)

// The contract code itself, as usual, is at the end, after all the connected libraries

pragma solidity ^0.4.11;

/**
 * Math operations with safety checks
 */

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    validate(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    validate(b > 0);
    uint c = a / b;
    validate(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    validate(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    validate(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function validate(bool validation) internal {
    if (!validation) {
      revert();
    }
  }
}


/*
 * ERC20Basic
 * Simpler version of ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


/*
 * Basic token
 * Basic version of StandardToken, with no allowances
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /*
   * Fix for the ERC20 short address attack  
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
}

/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already revert() if this condition is not met
    // if (value > allowance) revert();

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract SIMPLECOIN is StandardToken, Ownable {
    using SafeMath for uint;

    //--------------   Info for ERC20 explorers  -----------------//
    string public name = "SIMPLECOIN";
    string public symbol = "SIM";
    uint public decimals = 18;

    //---------------------   Constants   ------------------------//
    uint public constant WEI = 1000000000000000000;
    uint public constant INITIAL_SUPPLY = 500000000 * WEI; // 500 mln SMP. Impossible to mint more than this
    uint public constant ICO_START_TIME = 1507572447;
    uint public constant PRICE = 600;

    uint public constant _ONE = 1 * WEI;
    uint public constant _FIFTY = 50 * WEI;
    uint public constant _HUNDRED = 100 * WEI;
    uint public constant _FIVEHUNDRED = 500 * WEI;
    uint public constant _THOUSAND = 1000 * WEI;
    uint public constant _FIVETHOUSAND = 5000 * WEI;

    address public TEAM_WALLET = 0x08FB9bF8645c5f1B2540436C6352dA23eE843b50;
    address public ICO_ADDRESS = 0x1c01C01C01C01c01C01c01c01c01C01c01c01c01;

    //----------------------  Variables  -------------------------//
    uint public current_supply = 0; // Holding the number of all the coins in existence
    uint public ico_starting_supply = 0; // How many WEI tokens were available for sale at the beginning of the ICO

    //-------------   Flags describing ICO stages   --------------//
    bool public preMarketingSharesDistributed = false; // Prevents accidental re-distribution of shares
    // private venture pre ico
    bool public isPreICOPrivateOpened = false;
    bool public isPreICOPrivateClosed = false;
    // public pre ico
    bool public isPreICOPublicOpened = false;
    bool public isPreICOPublicClosed = false;
    // public ico
    bool public isICOOpened = false;
    bool public isICOClosed = false;

    //----------------------   Events  ---------------------------//
    event PreICOPrivateOpened();
    event PreICOPrivateClosed();
    event PreICOPublicOpened();
    event PreICOPublicClosed();
    event ICOOpened();
    event ICOClosed();
    event SupplyChanged(uint supply, uint old_supply);
    event SMPAcquired(address account, uint amount_in_wei, uint amount_in_rkc);

    // *

    // Constructor
    function SIMPLECOIN() {
        // Some percentage of the tokens is already reserved by early employees and investors
        // Here we're initializing their balances
        distributeMarketingShares();
    }

    // Sending ether directly to the contract invokes buy() and assigns tokens to the sender
    function () payable {
        buy();
    }

    // *

    // Buy token by sending ether here
    //
    // You can also send the ether directly to the contract address
    function buy() payable {
        if (msg.value == 0) {
            revert();
        }

        // prevent from buying before starting preico or ico
        if (!isPreICOPrivateOpened && !isPreICOPublicOpened && !isICOOpened) {
            revert();
        }

        if (isICOClosed) {
            revert();
        }

        // Deciding how many tokens can be bought with the ether received
        uint tokens = getSMPTokensAmountPerEthInternal(msg.value);

        // Just in case
        if (tokens > balances[ICO_ADDRESS]) { 
            revert();
        }

        // Transfer from the ICO pool
        balances[ICO_ADDRESS] = balances[ICO_ADDRESS].sub(tokens); // if not enough, will revert()
        balances[msg.sender] = balances[msg.sender].add(tokens);

        // Broadcasting the buying event
        SMPAcquired(msg.sender, msg.value, tokens);
    }

    // *

    // Functions for the contract owner
    function openPreICOPrivate() onlyOwner {
        if (isPreICOPrivateOpened) revert();
        if (isPreICOPrivateClosed) revert();

        if (isPreICOPublicOpened) revert();
        if (isPreICOPublicClosed) revert();

        if (isICOOpened) revert();
        if (isICOClosed) revert();        

        isPreICOPrivateOpened = true;

        PreICOPrivateOpened();
    }

    function closePreICOPrivate() onlyOwner {
        if (!isPreICOPrivateOpened) revert();
        if (isPreICOPrivateClosed) revert();

        if (isPreICOPublicOpened) revert();
        if (isPreICOPublicClosed) revert();

        if (isICOOpened) revert();
        if (isICOClosed) revert();

        isPreICOPrivateOpened = false;
        isPreICOPrivateClosed = true;

        PreICOPrivateClosed();
    }

    function openPreICOPublic() onlyOwner {
        if (isPreICOPrivateOpened) revert();
        if (!isPreICOPrivateClosed) revert();

        if (isPreICOPublicOpened) revert();
        if (isPreICOPublicClosed) revert();

        if (isICOOpened) revert();
        if (isICOClosed) revert();        

        isPreICOPublicOpened = true;

        PreICOPublicOpened();
    }

    function closePreICOPublic() onlyOwner {
        if (isPreICOPrivateOpened) revert();
        if (!isPreICOPrivateClosed) revert();

        if (!isPreICOPublicOpened) revert();
        if (isPreICOPublicClosed) revert();

        if (isICOOpened) revert();
        if (isICOClosed) revert();

        isPreICOPublicOpened = false;
        isPreICOPublicClosed = true;

        PreICOPublicClosed();
    }

    function openICO() onlyOwner {
        if (isPreICOPrivateOpened) revert();
        if (!isPreICOPrivateClosed) revert();

        if (isPreICOPublicOpened) revert();
        if (!isPreICOPublicClosed) revert();

        if (isICOOpened) revert();
        if (isICOClosed) revert();

        isICOOpened = true;

        ICOOpened();
    }

    function closeICO() onlyOwner {
        if (isPreICOPrivateOpened) revert();
        if (!isPreICOPrivateClosed) revert();

        if (isPreICOPublicOpened) revert();
        if (!isPreICOPublicClosed) revert();

        if (!isICOOpened) revert();
        if (isICOClosed) revert();

        isICOOpened = false;
        isICOClosed = true;

        balances[ICO_ADDRESS] = 0;

        ICOClosed();
    }

    function pullEtherFromContractAfterPreICOPrivate() onlyOwner {       
        if (isPreICOPrivateOpened) revert();
        if (!isPreICOPrivateClosed) revert();

        if (isPreICOPublicOpened) revert();
        if (isPreICOPublicClosed) revert();

        if (isICOOpened) revert();
        if (isICOClosed) revert();

        if (!TEAM_WALLET.send(this.balance)) {
            revert();
        }
    }

    function pullEtherFromContractAfterPreICOPublic() onlyOwner {       
        if (isPreICOPrivateOpened) revert();
        if (!isPreICOPrivateClosed) revert();

        if (isPreICOPublicOpened) revert();
        if (!isPreICOPublicClosed) revert();

        if (isICOOpened) revert();
        if (isICOClosed) revert();

        if (!TEAM_WALLET.send(this.balance)) {
            revert();
        }
    }

    function pullEtherFromContractAfterICO() onlyOwner {
        if (isPreICOPrivateOpened) revert();
        if (!isPreICOPrivateClosed) revert();

        if (isPreICOPublicOpened) revert();
        if (!isPreICOPublicClosed) revert();

        if (isICOOpened) revert();
        if (!isICOClosed) revert();

        if (!TEAM_WALLET.send(this.balance)) {
            revert();
        }
    }

    // *

    // Some percentage of the tokens is already reserved for marketing
    function distributeMarketingShares() onlyOwner {
        // Making it impossible to call this function twice
        if (preMarketingSharesDistributed) {
            revert();
        }

        preMarketingSharesDistributed = true;

        // Values are in WEI tokens
        balances[0xAc5C2414dae4ADB07D82d40dE71B4Bc5E2b417fd] = 100000000 * WEI; // referral
        balances[0x603D3e11E88dD9aDdc4D9AbE205C7C02e9e13483] = 20000000 * WEI; // social marketing
        
        current_supply = (100000000 + 20000000) * WEI;

        // Sending the rest to ICO pool
        balances[ICO_ADDRESS] = INITIAL_SUPPLY.sub(current_supply);

        // Initializing the supply variables
        ico_starting_supply = balances[ICO_ADDRESS];
        current_supply = INITIAL_SUPPLY;
        SupplyChanged(0, current_supply);
    }

    // *

    // Some useful getters (although you can just query the public variables)

    function getPriceSMPTokensPerWei() public constant returns (uint result) {
        return PRICE;
    }

    /* function getSMPTokensAmountPerEthInternal(uint value) public payable returns (uint result) {     
        return value * PRICE;
    } */

    function getSMPTokensAmountPerEthInternal(uint value) public payable returns (uint result) {    
        if (isPreICOPrivateOpened) {
            if (value >= _FIFTY && value < _FIVEHUNDRED) {
                return (value + (value * 35) / 100) * PRICE;
            }

            if (value >= _FIVEHUNDRED && value < _THOUSAND) {
                return (value + (value * 40) / 100) * PRICE;
            }

            if (value >= _THOUSAND && value < _FIVETHOUSAND) {
                return (value + (value * 60) / 100) * PRICE;
            }

            if (value >= _FIVETHOUSAND) {
                return (value + value) * PRICE;
            }
        }

        if (isPreICOPublicOpened) {
            if (value >= _ONE && value < _HUNDRED) {
                return (value + (value * 20) / 100) * PRICE;
            }

            if (value >= _HUNDRED && value < _FIVEHUNDRED) {
                return (value + (value * 30) / 100) * PRICE;
            }

            if (value >= _FIVEHUNDRED && value < _THOUSAND) {
                return (value + (value * 40) / 100) * PRICE;
            }

            if (value >= _THOUSAND) {
                return (value + (value * 50) / 100) * PRICE;
            }
        }

        return value * PRICE;
    }

    function getSMPTokensAmountPerWei(uint value) public constant returns (uint result) {
        return getSMPTokensAmountPerEthInternal(value);
    }
    function getSupply() public constant returns (uint result) {
        return current_supply;
    }
    function getSMPTokensLeftForICO() public constant returns (uint result) {
        return balances[ICO_ADDRESS];
    }
    function getSMPTokensBoughtInICO() public constant returns (uint result) {
        return ico_starting_supply - getSMPTokensLeftForICO();
    }
    function getBalance(address addr) public constant returns (uint balance) {
        return balances[addr];
    }

    // *

    // Overriding payment functions to take control over the logic
    modifier allowedPayments(address payer, uint value) {
        // Don't allow to transfer coins until the ICO ends
        if (isPreICOPrivateOpened || isPreICOPublicOpened || isICOOpened) {
            revert();
        }

        if (!isPreICOPrivateClosed || !isPreICOPublicClosed || !isICOClosed) {
            revert();
        }

        if (block.timestamp < ICO_START_TIME) {
            revert();
        }

        _;
    }

    function transferFrom(address _from, address _to, uint _value) allowedPayments(_from, _value) {
        super.transferFrom(_from, _to, _value);
    }
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) allowedPayments(msg.sender, _value) {
        super.transfer(_to, _value);
    }

}