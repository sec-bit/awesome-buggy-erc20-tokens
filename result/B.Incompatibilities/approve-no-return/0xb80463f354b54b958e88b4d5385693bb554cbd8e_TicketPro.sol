//params: 100,"MJ comeback", 1603152000, 0, "21/10/2020", "MGM grand", "MJC", 100000000, 10
// "0x000000000000000000000000000000000000000000000000016a6075a7170002", 27, "0xE26D930533CF5E36051C576E1988D096727F28A4AB638DBE7729BCC067BD06C8", "0x76EBAA64A541D1DE054F4B63B586E7FEB485C1B3E85EA463F873CA69307EEEAA"
pragma solidity ^0.4.17;

contract ERC20
{
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     //function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     //function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
 }

contract TicketPro is ERC20
{
    //erc20 wiki: https://theethereum.wiki/w/index.php/ERC20_Token_Standard
    //maybe allow tickets to be purchased through contract??
    uint totalTickets;
    mapping(address => uint) balances;
    uint expiryTimeStamp;
    address admin;
    uint transferFee;
    uint numOfTransfers = 0;
    string public name;
    string public symbol;
    string public date;
    string public venue;
    bytes32[] orderHashes;
    uint startPrice;
    uint limitOfStartTickets;
    uint8 public constant decimals = 0; //no decimals as tickets cannot be split

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event TransferFrom(address indexed _from, address indexed _to, uint _value);

    modifier eventNotExpired()
    {
        //not perfect but probably good enough
        if(block.timestamp > expiryTimeStamp)
        {
            revert();
        }
        else _;
    }

    modifier adminOnly()
    {
        if(msg.sender != admin) revert();
        else _;
    }

    function() public { revert(); } //should not send any ether directly

    function TicketPro(uint numberOfTickets, string evName, uint expiry,
            uint fee, string evDate, string evVenue, string eventSymbol,
             uint price, uint startTicketLimit) public
    {
        totalTickets = numberOfTickets;
        //event organizer has all the tickets in the beginning
        balances[msg.sender] = totalTickets;
        expiryTimeStamp = expiry;
        admin = msg.sender;
        //100 fee = 1 ether
        transferFee = (1 ether * fee) / 100;
        symbol = eventSymbol;
        name = evName;
        date = evDate;
        venue = evVenue;
        startPrice = price;
        limitOfStartTickets= startTicketLimit;
    }

    //note that tickets cannot be split, it has to be a whole number
    function buyATicketFromContract(uint numberOfTickets) public payable returns (bool)
    {
        //no decimal points allowed in a token
        if(msg.value != startPrice * numberOfTickets
            || numberOfTickets % 1 != 0) revert();
        admin.transfer(msg.value);
        balances[msg.sender] += 1;
        return true;
    }

    function getTicketStartPrice() public view returns(uint)
    {
        return startPrice;
    }

    function getDecimals() public pure returns(uint)
    {
        return decimals;
    }

    function getNumberOfAvailableStartTickets() public view returns (uint)
    {
        return limitOfStartTickets;
    }

    //buyer pays all the fees, seller doesn't even need to have ether to do trade
    function deliveryVSpayment(bytes32 offer, uint8 v, bytes32 r,
        bytes32 s) public payable returns(bool)
    {
	    var (seller, quantity, price, agreementIsValid) = recover(offer, v, r, s);
        //if the agreement hash matches then the trade can take place
        uint cost = price * quantity;
        if(agreementIsValid && msg.value == cost)
        {
            //send over ether and tokens
            balances[msg.sender] += uint(quantity);
            balances[seller] -= uint(quantity);
            uint commission = (msg.value / 100) * transferFee;
            uint sellerAmt = msg.value - commission;
            seller.transfer(sellerAmt);
            admin.transfer(commission);
            numOfTransfers++;
            return true;
        }
        else revert();
    }

    // to test: suppose the offer is to sell 2 tickets at 0.102ETH
    // which is 0x16A6075A7170000 WEI
    // the parameters are:
    // "0x000000000000000000000000000000000000000000000000016a6075a7170002", 27, "0x0071d8bc2f3c9b8102bc03660d525ab872070eb036cd75f0c503bdba8a9406d8","0xb1649086e9df334e9831dc7d57cb61808f7c07d1422ef150a43f9df92c48665c"
    // I generated the test parameter with this:
/*
#!/usr/bin/python3

import ecdsa, binascii

secexp = 0xc64031ec35f5fc700264f6bb2d6342f63e020673f79ed70dbbd56fb8d46351ed
sk = ecdsa.SigningKey.from_secret_exponent(secexp, curve=ecdsa.SECP256k1)
# 1 tickets at the price of 2 wei
offer = b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x6A\x60\x75\xA7\x17\x00\x02'
r, s = sk.sign_digest(offer, sigencode=ecdsa.util.sigencode_strings)
## 27 can be any of 27, 28, 29, 30. Use proper algorithm in production
print('"0x{}", {}, "0x{}","0x{}"'.format(
    binascii.hexlify(offer).decode("ascii"), 27,
    binascii.hexlify(r).decode("ascii"), binascii.hexlify(s).decode("ascii")))
*/
    function recover(bytes32 offer, uint8 v, bytes32 r, bytes32 s) public view
        returns (address seller, uint16 quantity, uint256 price, bool agreementIsValid) {
        quantity = uint16(offer & 0xffff);
        price = uint256(offer >> 16 << 16);
        seller = ecrecover(offer, v, r, s);
        agreementIsValid = balances[seller] >= quantity;
    }

    function totalSupply() public constant returns(uint)
    {
        return totalTickets;
    }

    function eventName() public constant returns(string)
    {
        return name;
    }

    function eventVenue() public constant returns(string)
    {
        return venue;
    }

    function eventDate() public constant returns(string)
    {
        return date;
    }

    function getAmountTransferred() public view returns (uint)
    {
        return numOfTransfers;
    }

    function isContractExpired() public view returns (bool)
    {
        if(block.timestamp > expiryTimeStamp)
        {
            return true;
        }
        else return false;
    }

    function balanceOf(address _owner) public constant returns (uint)
    {
        return balances[_owner];
    }

    //transfers can be free but at the users own risk
    function transfer(address _to, uint _value) public returns(bool)
    {
        if(balances[msg.sender] < _value) revert();
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        numOfTransfers++;
        return true;
    }

    //good for revoking tickets, for refunds etc.
    function transferFrom(address _from, address _to, uint _value)
        adminOnly public returns (bool)
    {
        if(balances[_from] >= _value)
        {
            balances[_from] -= _value;
            balances[_to] += _value;
            TransferFrom(_from,_to, _value);
            numOfTransfers++;
            return true;
        }
        else return false;
    }
}