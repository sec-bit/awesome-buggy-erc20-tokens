pragma solidity ^0.4.0;

library TokenEventLib {
    /*
     * When underlying solidity issue is fixed this library will not be needed.
     * https://github.com/ethereum/solidity/issues/1215
     */
    event Transfer(address indexed _from,
                   address indexed _to);
    event Approval(address indexed _owner,
                   address indexed _spender);

    function _Transfer(address _from, address _to) internal {
        Transfer(_from, _to);
    }

    function _Approval(address _owner, address _spender) internal {
        Approval(_owner, _spender);
    }
}

contract TokenInterface {
    /*
     *  Events
     */
    event Mint(address indexed _owner);
    event Destroy(address _owner);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event MinterAdded(address who);
    event MinterRemoved(address who);

    /*
     *  Minting
     */
    /// @dev Mints a new token.
    /// @param _owner Address of token owner.
    function mint(address _owner) returns (bool success);

    /// @dev Destroy a token
    /// @param _owner Bytes32 id of the owner of the token
    function destroy(address _owner) returns (bool success);

    /// @dev Add a new minter
    /// @param who Address the address that can now mint tokens.
    function addMinter(address who) returns (bool);

    /// @dev Remove a minter
    /// @param who Address the address that will no longer be a minter.
    function removeMinter(address who) returns (bool);

    /*
     *  Read and write storage functions
     */

    /// @dev Return the number of tokens
    function totalSupply() constant returns (uint supply);

    /// @dev Transfers sender token to given address. Returns success.
    /// @param _to Address of new token owner.
    /// @param _value Bytes32 id of the token to transfer.
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address of token owner.
    /// @param _to Address of new token owner.
    /// @param _value Bytes32 id of the token to transfer.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @dev Sets approval spender to transfer ownership of token. Returns success.
    /// @param _spender Address of spender..
    /// @param _value Bytes32 id of token that can be spend.
    function approve(address _spender, uint256 _value) returns (bool success);

    /*
     * Read storage functions
     */
    /// @dev Returns id of token owned by given address (encoded as an integer).
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @dev Returns the token id that may transfer from _owner account by _spender..
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    /*
     *  Extra non ERC20 functions
     */
    /// @dev Returns whether the address owns a token.
    /// @param _owner Address to check.
    function isTokenOwner(address _owner) constant returns (bool);
}

contract IndividualityTokenInterface {
    /*
     * Read storage functions
     */

    /// @dev Returns id of token owned by given address (encoded as an integer).
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @dev Returns the token id that may transfer from _owner account by _spender..
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    /*
     *  Write storage functions
     */

    /// @dev Transfers sender token to given address. Returns success.
    /// @param _to Address of new token owner.
    /// @param _value Bytes32 id of the token to transfer.
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transfer(address _to) public returns (bool success);

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address of token owner.
    /// @param _to Address of new token owner.
    /// @param _value Bytes32 id of the token to transfer.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to) public returns (bool success);

    /// @dev Sets approval spender to transfer ownership of token. Returns success.
    /// @param _spender Address of spender..
    /// @param _value Bytes32 id of token that can be spend.
    function approve(address _spender, uint256 _value) public returns (bool success);
    function approve(address _spender) public returns (bool success);

    /*
     *  Extra non ERC20 functions
     */

    /// @dev Returns whether the address owns a token.
    /// @param _owner Address to check.
    function isTokenOwner(address _owner) constant returns (bool);
}


contract IndividualityToken is TokenInterface, IndividualityTokenInterface {
    function IndividualityToken() {
        minters[msg.sender] = true;
        MinterAdded(msg.sender);
    }

    modifier minterOnly {
        if(!minters[msg.sender]) throw;
        _;
    }

    // address => canmint
    mapping (address => bool) minters;
    
    // owner => balance
    mapping (address => uint) balances;

    // owner => spender => balance
    mapping (address => mapping (address => uint)) approvals;

    uint numTokens;

    /// @dev Mints a new token.
    /// @param _to Address of token owner.
    function mint(address _to) minterOnly returns (bool success) {
        // ensure that the token owner doesn't already own a token.
        if (balances[_to] != 0x0) return false;

        balances[_to] = 1;

        // log the minting of this token.
        Mint(_to);
        Transfer(0x0, _to, 1);
        TokenEventLib._Transfer(0x0, _to);

        // increase the supply.
        numTokens += 1;

        return true;
    }
    
    // @dev Mint many new tokens
    function mint(address[] _to) minterOnly returns (bool success) {
        for(uint i = 0; i < _to.length; i++) {
            if(balances[_to[i]] != 0x0) return false;
            balances[_to[i]] = 1;
            Mint(_to[i]);
            Transfer(0x0, _to[i], 1);
            TokenEventLib._Transfer(0x0, _to[i]);
        }
        numTokens += _to.length;
        return true;
    }

    /// @dev Destroy a token
    /// @param _owner address owner of the token to destroy
    function destroy(address _owner) minterOnly returns (bool success) {
        if(balances[_owner] != 1) throw;
        
        balances[_owner] = 0;
        numTokens -= 1;
        Destroy(_owner);
        return true;
    }

    /// @dev Add a new minter
    /// @param who Address the address that can now mint tokens.
    function addMinter(address who) minterOnly returns (bool) {
        minters[who] = true;
        MinterAdded(who);
    }

    /// @dev Remove a minter
    /// @param who Address the address that will no longer be a minter.
    function removeMinter(address who) minterOnly returns (bool) {
        minters[who] = false;
        MinterRemoved(who);
    }

    /// @dev Return the number of tokens
    function totalSupply() constant returns (uint supply) {
        return numTokens;
    }

    /// @dev Returns id of token owned by given address (encoded as an integer).
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        if (_owner == 0x0) {
            return 0;
        } else {
            return balances[_owner];
        }
    }

    /// @dev Returns the token id that may transfer from _owner account by _spender..
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner,
                       address _spender) constant returns (uint256 remaining) {
        return approvals[_owner][_spender];
    }

    /// @dev Transfers sender token to given address. Returns success.
    /// @param _to Address of new token owner.
    /// @param _value Bytes32 id of the token to transfer.
    function transfer(address _to,
                      uint256 _value) public returns (bool success) {
        if (_value != 1) {
            // 1 is the only value that makes any sense here.
            return false;
        } else if (_to == 0x0) {
            // cannot transfer to the null address.
            return false;
        } else if (balances[msg.sender] == 0x0) {
            // msg.sender is not a token owner
            return false;
        } else if (balances[_to] != 0x0) {
            // cannot transfer to an address that already owns a token.
            return false;
        }

        balances[msg.sender] = 0;
        balances[_to] = 1;
        Transfer(msg.sender, _to, 1);
        TokenEventLib._Transfer(msg.sender, _to);

        return true;
    }

    /// @dev Transfers sender token to given address. Returns success.
    /// @param _to Address of new token owner.
    function transfer(address _to) public returns (bool success) {
        return transfer(_to, 1);
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address of token owner.
    /// @param _to Address of new token owner.
    /// @param _value Bytes32 id of the token to transfer.
    function transferFrom(address _from,
                          address _to,
                          uint256 _value) public returns (bool success) {
        if (_value != 1) {
            // Cannot transfer anything other than 1 token.
            return false;
        } else if (_to == 0x0) {
            // Cannot transfer to the null address
            return false;
        } else if (balances[_from] == 0x0) {
            // Cannot transfer if _from is not a token owner
            return false;
        } else if (balances[_to] != 0x0) {
            // Cannot transfer to an existing token owner
            return false;
        } else if (approvals[_from][msg.sender] == 0) {
            // The approved token doesn't match the token being transferred.
            return false;
        }

        // null out the approval
        approvals[_from][msg.sender] = 0x0;

        // remove the token from the sender.
        balances[_from] = 0;

        // assign the token to the new owner
        balances[_to] = 1;

        // log the transfer
        Transfer(_from, _to, 1);
        TokenEventLib._Transfer(_from, _to);

        return true;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address of token owner.
    /// @param _to Address of new token owner.
    function transferFrom(address _from, address _to) public returns (bool success) {
        return transferFrom(_from, _to, 1);
    }

    /// @dev Sets approval spender to transfer ownership of token. Returns success.
    /// @param _spender Address of spender..
    /// @param _value Bytes32 id of token that can be spend.
    function approve(address _spender,
                     uint256 _value) public returns (bool success) {
        if (_value != 1) {
            // cannot approve any value other than 1
            return false;
        } else if (_spender == 0x0) {
            // cannot approve the null address as a spender.
            return false;
        } else if (balances[msg.sender] == 0x0) {
            // cannot approve if not a token owner.
            return false;
        }

        approvals[msg.sender][_spender] = 1;

        Approval(msg.sender, _spender, 1);
        TokenEventLib._Approval(msg.sender, _spender);

        return true;
    }

    /// @dev Sets approval spender to transfer ownership of token. Returns success.
    /// @param _spender Address of spender..
    function approve(address _spender) public returns (bool success) {
        return approve(_spender, 1);
    }

    /*
     *  Extra non ERC20 functions
     */
    /// @dev Returns whether the address owns a token.
    /// @param _owner Address to check.
    function isTokenOwner(address _owner) constant returns (bool) {
        return balances[_owner] != 0;
    }
}