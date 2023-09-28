pragma solidity ^0.4.18;

// Potatoin (or potato coin) is the first of its kind, virtualized vegetable
// crypto-asset resistant to the inevitable crash of the world economy!
contract Potatoin {
    // name, symbol and decimals implement the ERC20 token standard.
    string public constant name     = "Potatoin";
    string public constant symbol   = "POIN";
    uint8  public constant decimals = 0;

    // genesis and relief define the start and duration of the potato relief
    // organized by the Potatoin foundation.
    uint public genesis;
    uint public relief;

    // donated contains the addresses the foundation already donated to.
    mapping(address => uint) public donated;

    // rot and grow contains the time intervals in which unsowed potatoes rot
    // away and sowed potatoes double.
    uint public decay;
    uint public growth;

    // farmers, cellars and recycled track the current unsowed potatoes owned by
    // individual famers and the last time rotten ones were recycled.
    address[]                farmers;
    mapping(address => uint) cellars;
    mapping(address => uint) trashes;
    mapping(address => uint) recycled;

    // field and fields define the potato fields owned by individual famers,
    // along with the number of potatoes in them and the sowing time/
    struct field {
        uint potatoes;
        uint sowed;
    }
    mapping(address => field[]) public fields;
    mapping(address => uint)    public empties;

    // Transfer implements ERC20, raising a token transfer event.
    event Transfer(address indexed _from, address indexed _to, uint _value);

    // Potatoin is the Potatoin foundation constructor. It configures the potato
    // relief and sets up the organizational oversight.
    function Potatoin(uint256 _relief, uint256 _decay, uint256 _growth) public {
        genesis = block.timestamp;
        relief  = _relief;
        decay   = _decay;
        growth  = _growth;
    }

    // totalSupply returns the total number of potatoes owned by all people,
    // taking into consideration those that already rotted away.
    function totalSupply() constant public returns (uint totalSupply) {
        for (uint i = 0; i < farmers.length; i++) {
            totalSupply += balanceOf(farmers[i]);
        }
        return totalSupply;
    }

    // balanceOf returns the current number of potatoes owned by a particular
    // account, taking into consideration those that already rotted away.
    function balanceOf(address farmer) constant public returns (uint256 balance) {
       return unsowed(farmer) + sowed(farmer);
    }

    // unsowed returns the current number of unsowed potatoes owned by a farmer,
    // taking into consideration those that already rotted away.
    function unsowed(address farmer) constant public returns (uint256 balance) {
        // Retrieve the number of non-rotten potatoes from the cellar
        var elapsed = block.timestamp - recycled[farmer];
        if (elapsed < decay) {
            balance = (cellars[farmer] * (decay - elapsed) + decay-1) / decay;
        }
        // Retrieve the number of non-rotten potatoes from the fields
        var list = fields[farmer];
        for (uint i = empties[farmer]; i < list.length; i++) {
            elapsed = block.timestamp - list[i].sowed;
            if (elapsed >= growth && elapsed - growth < decay) {
                balance += (2 * list[i].potatoes * (decay-elapsed+growth) + decay-1) / decay;
            }
        }
        return balance;
    }

    // sowed returns the current number of sowed potatoes owned by a farmer,
    // taking into consideration those that are currently growing.
    function sowed(address farmer) constant public returns (uint256 balance) {
        var list = fields[farmer];
        for (uint i = empties[farmer]; i < list.length; i++) {
            // If the potatoes are fully grown, assume the field harvested
            var elapsed = block.timestamp - list[i].sowed;
            if (elapsed >= growth) {
                continue;
            }
            // Otherwise calculate the number of potatoes "in the making"
            balance += list[i].potatoes + list[i].potatoes * elapsed / growth;
        }
        return balance;
    }

    // trashed returns the number of potatoes owned by a farmer that rot away,
    // taking into consideration the current storage and fields too.
    function trashed(address farmer) constant public returns (uint256 balance) {
        // Start with all the accounted for trash
        balance = trashes[farmer];

        // Calculate the rotten potatoes from storage
        var elapsed = block.timestamp - recycled[farmer];
        if (elapsed >= 0) {
            var rotten = cellars[farmer];
            if (elapsed < decay) {
               rotten = cellars[farmer] * elapsed / decay;
            }
            balance += rotten;
        }
        // Calculate the rotten potatoes from the fields
        var list = fields[farmer];
        for (uint i = empties[farmer]; i < list.length; i++) {
            elapsed = block.timestamp - list[i].sowed;
            if (elapsed >= growth) {
                rotten = 2 * list[i].potatoes;
                if  (elapsed - growth < decay) {
                    rotten = 2 * list[i].potatoes * (elapsed - growth) / decay;
                }
                balance += rotten;
            }
        }
        return balance;
    }

    // request asks the Potatoin foundation for a grant of one potato. Potatoes
    // are available only during the initial hunger relief phase.
    function request() public {
        // Farmers can only request potatoes during the relieve, one per person
        require(block.timestamp < genesis + relief);
        require(donated[msg.sender] == 0);

        // Farmer is indeed a new one, grant its potato
        donated[msg.sender] = block.timestamp;

        farmers.push(msg.sender);
        cellars[msg.sender] = 1;
        recycled[msg.sender] = block.timestamp;

        Transfer(this, msg.sender, 1);
    }

    // sow creates a new potato field with the requested number of potatoes in
    // it, doubling after the growing period ends. If the farmer doesn't have
    // the requested amount of potatoes, all existing ones will be sowed.
    function sow(uint potatoes) public {
        // Harvest any ripe fields
        harvest(msg.sender);

        // Make sure we have a meaningful amount to sow
        if (potatoes == 0) {
            return;
        }
        // If any potatoes are left for the farmer, sow them
        if (cellars[msg.sender] > 0) {
            if (potatoes > cellars[msg.sender]) {
                potatoes = cellars[msg.sender];
            }
            fields[msg.sender].push(field(potatoes, block.timestamp));
            cellars[msg.sender] -= potatoes;

            Transfer(msg.sender, this, potatoes);
        }
    }

    // harvest gathers all the potatoes of a user that have finished growing.
    // Any rotten ones are deduced from the final counter. The potatoes in the
    // cellar are also accounted for.
    function harvest(address farmer) internal {
        // Recycle any rotted away potatoes to update the recycle timer
        recycle(farmer);

        // Harvest all the ripe fields
        var list = fields[farmer];
        for (uint i = empties[farmer]; i < list.length; i++) {
            var elapsed = block.timestamp - list[i].sowed;
            if (elapsed >= growth) {
                if (elapsed - growth < decay) {
                    var harvested = (2 * list[i].potatoes * (decay-elapsed+growth) + decay-1) / decay;
                    var rotten    = 2 * list[i].potatoes - harvested;

                    cellars[farmer] += harvested;
                    Transfer(this, farmer, harvested);

                    if (rotten > 0) {
                        trashes[farmer] += rotten;
                        Transfer(this, 0, rotten);
                    }
                } else {
                    trashes[farmer] += 2 * list[i].potatoes;
                    Transfer(this, 0, 2 * list[i].potatoes);
                }
                empties[farmer]++;
            }
        }
        // If all the fields were harvested, rewind the accumulators
        if (empties[farmer] > 0 && empties[farmer] == list.length) {
            delete empties[farmer];
            delete fields[farmer];
        }
    }

    // recycle throws away the potatoes of a user that rotted away.
    function recycle(address farmer) internal {
        var elapsed = block.timestamp - recycled[farmer];
        if (elapsed == 0) {
            return;
        }
        var rotten = cellars[farmer];
        if (elapsed < decay) {
           rotten = cellars[farmer] * elapsed / decay;
        }
        if (rotten > 0) {
            cellars[farmer] -= rotten;
            trashes[farmer] += rotten;

            Transfer(farmer, 0, rotten);
        }
        recycled[farmer] = block.timestamp;
    }

    // transfer forwards a number of potatoes to the requested address.
    function transfer(address to, uint potatoes) public returns (bool success) {
        // Harvest own ripe fields and make sure we can transfer
        harvest(msg.sender);
        if (cellars[msg.sender] < potatoes) {
            return false;
        }
        // Recycle the remote rotten ones and execute the transfre
        recycle(to);
        cellars[msg.sender] -= potatoes;
        cellars[to]         += potatoes;

        Transfer(msg.sender, to, potatoes);
        return true;
    }

    // transferFrom implements ERC20, but is forbidden.
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        return false;
    }

    // approve implements ERC20, but is forbidden.
    function approve(address _spender, uint _value) returns (bool success) {
        return false;
    }

    // allowance implements ERC20, but is forbidden.
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return 0;
    }
}