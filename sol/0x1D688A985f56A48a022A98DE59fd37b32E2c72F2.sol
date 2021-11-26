pragma solidity ^0.4.16;


contract ERC20Token {
    event Transfer(address indexed from, address indexed _to, uint256 _value);
	event Approval(address indexed owner, address indexed _spender, uint256 _value);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0 && _to != address(this));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
}


contract Owned {
    address public owner;

    /**
     * Construct the Owned contract and
     * make the sender the owner
     */
    function Owned() public {
        owner = msg.sender;
    }

    /**
     * Restrict to the owner only
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * Transfer the ownership to another address
     *
     * @param newOwner the new owner's address
     */
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}


contract Beercoin is ERC20Token, Owned {
    event Produce(uint256 value, string caps);
	event Burn(uint256 value);

    string public name = "Beercoin";
    string public symbol = "🍺";
	uint8 public decimals = 18;
	uint256 public totalSupply = 15496000000 * 10 ** uint256(decimals);

    // In addition to the initial total supply of 15496000000 Beercoins,
    // more Beercoins will only be added by scanning bottle caps.
    // 20800000000 bottle caps will be eventually produced.
    //
    // Within 10000 bottle caps,
    // 1 (i.e. every 10000th cap in total) has a value of 10000 ("Diamond") Beercoins,
    // 9 (i.e. every 1000th cap in total) have a value of 100 ("Gold") Beercoins,
    // 990 (i.e. every 10th cap in total) have a value of 10 ("Silver") Beercoins,
    // 9000 (i.e. every remaining cap) have a value of 1 ("Bronze") Beercoin.
    //
    // Therefore one bottle cap has an average Beercoin value of
    // (1 * 10000 + 9 * 100 + 990 * 10 + 9000 * 1) / 10000 = 2.98.
    //
    // This means the Beercoin value of all bottle caps that
    // will be produced in total is 20800000000 * 2.98 = 61984000000.
    uint256 public unproducedCaps = 20800000000;
    uint256 public producedCaps = 0;

    // Stores whether users disallow the owner to
    // pull Beercoins for the use of redemption.
    mapping (address => bool) public redemptionLocked;

    /**
     * Construct the Beercoin contract and
     * assign the initial supply to the owner.
     */
    function Beercoin() public {
		balanceOf[owner] = totalSupply;
    }

    /**
     * Lock or unlock the redemption functionality
     *
     * If a user doesn't want to redeem Beercoins on the owner's
     * website and doesn't trust the owner, the owner's capability
     * of pulling Beercoin from the user's account can be locked
     *
     * @param lock whether to lock the redemption capability or not
     */
    function lockRedemption(bool lock) public returns (bool success) {
        redemptionLocked[msg.sender] = lock;
        return true;
    }

    /**
     * Generate a sequence of bottle cap values to be used
     * for production and send the respective total Beercoin
     * value to the contract for keeping until a scan is recognized
     *
     * We hereby declare that this function is called if and only if
     * we need to generate codes intended for beer bottle production
     *
     * @param numberOfCaps the number of bottle caps to be produced
     */
	function produce(uint256 numberOfCaps) public onlyOwner returns (bool success) {
        require(numberOfCaps <= unproducedCaps);

        uint256 value = 0;
        bytes memory caps = bytes(new string(numberOfCaps));
        
        for (uint256 i = 0; i < numberOfCaps; ++i) {
            uint256 currentCoin = producedCaps + i;

            if (currentCoin % 10000 == 0) {
                value += 10000;
                caps[i] = "D";
            } else if (currentCoin % 1000 == 0) {
                value += 100;
                caps[i] = "G";
            } else if (currentCoin % 10 == 0) {
                value += 10;
                caps[i] = "S";
            } else {
                value += 1;
                caps[i] = "B";
            }
        }

        unproducedCaps -= numberOfCaps;
        producedCaps += numberOfCaps;

        value = value * 10 ** uint256(decimals);
        totalSupply += value;
        balanceOf[this] += value;
        Produce(value, string(caps));

        return true;
	}

	/**
     * Grant Beercoins to a user who scanned a bottle cap code
     *
     * We hereby declare that this function is called if and only if
	 * our server registers a valid code scan by the given user
     *
     * @param user the address of the user who scanned a codes
     * @param cap a bottle cap value ("D", "G", "S", or "B")
     */
	function scan(address user, byte cap) public onlyOwner returns (bool success) {
        if (cap == "D") {
            _transfer(this, user, 10000 * 10 ** uint256(decimals));
        } else if (cap == "G") {
            _transfer(this, user, 100 * 10 ** uint256(decimals));
        } else if (cap == "S") {
            _transfer(this, user, 10 * 10 ** uint256(decimals));
        } else {
            _transfer(this, user, 1 * 10 ** uint256(decimals));
        }
        
        return true;
	}

    /**
     * Grant Beercoins to users who scanned bottle cap codes
     *
     * We hereby declare that this function is called if and only if
	 * our server registers valid code scans by the given users
     *
     * @param users the addresses of the users who scanned a codes
     * @param caps bottle cap values ("D", "G", "S", or "B")
     */
	function scanMany(address[] users, byte[] caps) public onlyOwner returns (bool success) {
        require(users.length == caps.length);

        for (uint16 i = 0; i < users.length; ++i) {
            scan(users[i], caps[i]);
        }

        return true;
	}

	/**
     * Redeem tokens when the will to do so has been
	 * stated within the user interface of a Beercoin
	 * redemption system
	 *
	 * The owner calls this on behalf of the redeeming user
	 * so the latter does not need to pay transaction fees
	 * when redeeming
	 *
	 * We hereby declare that this function is called if and only if
     * a user deliberately wants to redeem Beercoins
     *
     * @param user the address of the user who wants to redeem
     * @param value the amount to redeem
     */
    function redeem(address user, uint256 value) public onlyOwner returns (bool success) {
        require(redemptionLocked[user] == false);
        _transfer(user, owner, value);
        return true;
    }

    /**
     * Redeem tokens when the will to do so has been
	 * stated within the user interface of a Beercoin
	 * redemption system
	 *
	 * The owner calls this on behalf of the redeeming users
	 * so the latter do not need to pay transaction fees
	 * when redeeming
	 *
	 * We hereby declare that this function is called if and only if
     * users deliberately want to redeem Beercoins
     *
     * @param users the addresses of the users who want to redeem
     * @param values the amounts to redeem
     */
    function redeemMany(address[] users, uint256[] values) public onlyOwner returns (bool success) {
        require(users.length == values.length);

        for (uint16 i = 0; i < users.length; ++i) {
            redeem(users[i], values[i]);
        }

        return true;
    }

    /**
     * Transfer Beercoins to multiple recipients
     *
     * @param recipients the addresses of the recipients
     * @param values the amounts to send
     */
    function transferMany(address[] recipients, uint256[] values) public onlyOwner returns (bool success) {
        require(recipients.length == values.length);

        for (uint16 i = 0; i < recipients.length; ++i) {
            transfer(recipients[i], values[i]);
        }

        return true;
    }

    /**
     * Destroy Beercoins by removing them from the system irreversibly
     *
     * @param value the amount of Beercoins to burn
     */
    function burn(uint256 value) public onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
		Burn(value);
        return true;
    }
}