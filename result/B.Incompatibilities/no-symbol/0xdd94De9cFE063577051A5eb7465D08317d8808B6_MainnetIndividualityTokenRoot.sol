pragma solidity ^0.4.0;


library ECVerifyLib {
    // From: https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
    // Duplicate Solidity's ecrecover, but catching the CALL return value
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
        // We do our own memory management here. Solidity uses memory offset
        // 0x40 to store the current end of memory. We write past it (as
        // writes are memory extensions), but don't update the offset so
        // Solidity will reuse it. The memory used here is only needed for
        // this context.

        // FIXME: inline assembly can't access return values
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

            // NOTE: we can reuse the request memory because we deal with
            //       the return code
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

    function ecrecovery(bytes32 hash, bytes sig) returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

            // Here we are loading the last 32 bytes. We exploit the fact that
            // 'mload' will pad with zeroes if we overread.
            // There is no 'mload8' to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))

            // Alternative solution:
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            // v := and(mload(add(sig, 65)), 255)
        }

        // albeit non-transactional signatures are not specified by the YP, one would expect it
        // to match the YP range of [27, 28]
        //
        // geth uses [0, 1] and some clients have followed. This might change, see:
        //  https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }

    function ecverify(bytes32 hash, bytes sig, address signer) returns (bool) {
        bool ret;
        address addr;
        (ret, addr) = ecrecovery(hash, sig);
        return ret == true && addr == signer;
    }
}


contract IndividualityTokenInterface {
    /*
     *  Events
     */
    event Mint(address indexed _owner, bytes32 _tokenID);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /*
     * Read storage functions
     */

    /// @dev Return the number of tokens
    function totalSupply() constant returns (uint256 supply);

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

    /// @dev Returns the address of the owner of the given token id.
    /// @param _tokenID Bytes32 id of token to lookup.
    function ownerOf(bytes32 _tokenID) constant returns (address owner);

    /// @dev Returns the token ID for the given address or 0x0 if they are not a token owner.
    /// @param _owner Address of the owner to lookup.
    function tokenId(address _owner) constant returns (bytes32 tokenID);
}


contract IndividualityTokenRootInterface is IndividualityTokenInterface {
    /// @dev Imports a token from the Devcon2Token contract.
    function upgrade() public returns (bool success);

    /// @dev Upgrades a token from the previous contract
    /// @param _owner the address of the owner of the token on the original contract
    /// @param _newOwner the address that should own the token on the new contract.
    /// @param signature 65 byte signature of the tightly packed bytes (address(this) + _owner + _newOwner), signed by _owner
    function proxyUpgrade(address _owner,
                          address _newOwner,
                          bytes signature) public returns (bool);

    /// @dev Returns the number of tokens that have been upgraded.
    function upgradeCount() constant returns (uint256 amount);

    /// @dev Returns the number of tokens that have been upgraded.
    /// @param _tokenID the id of the token to query
    function isTokenUpgraded(bytes32 _tokenID) constant returns (bool isUpgraded);
}


library TokenEventLib {
    /*
     * When underlying solidity issue is fixed this library will not be needed.
     * https://github.com/ethereum/solidity/issues/1215
     */
    event Transfer(address indexed _from,
                   address indexed _to,
                   bytes32 indexed _tokenID);
    event Approval(address indexed _owner,
                   address indexed _spender,
                   bytes32 indexed _tokenID);

    function _Transfer(address _from, address _to, bytes32 _tokenID) public {
        Transfer(_from, _to, _tokenID);
    }

    function _Approval(address _owner, address _spender, bytes32 _tokenID) public {
        Approval(_owner, _spender, _tokenID);
    }
}


contract TokenInterface {
    /*
     *  Events
     */
    event Mint(address indexed _to, bytes32 _id);
    event Destroy(bytes32 _id);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event MinterAdded(address who);
    event MinterRemoved(address who);

    /*
     *  Minting
     */
    /// @dev Mints a new token.
    /// @param _to Address of token owner.
    /// @param _identity String for owner identity.
    function mint(address _to, string _identity) returns (bool success);

    /// @dev Destroy a token
    /// @param _id Bytes32 id of the token to destroy.
    function destroy(bytes32 _id) returns (bool success);

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
    function totalSupply() returns (uint supply);

    /// @dev Transfers sender token to given address. Returns success.
    /// @param _to Address of new token owner.
    /// @param _value Bytes32 id of the token to transfer.
    function transfer(address _to, uint256 _value) returns (bool success);
    function transfer(address _to, bytes32 _value) returns (bool success);

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address of token owner.
    /// @param _to Address of new token owner.
    /// @param _value Bytes32 id of the token to transfer.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, bytes32 _value) returns (bool success);

    /// @dev Sets approval spender to transfer ownership of token. Returns success.
    /// @param _spender Address of spender..
    /// @param _value Bytes32 id of token that can be spend.
    function approve(address _spender, uint256 _value) returns (bool success);
    function approve(address _spender, bytes32 _value) returns (bool success);

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

    /// @dev Returns the identity of the given token id.
    /// @param _id Bytes32 id of token to lookup.
    function identityOf(bytes32 _id) constant returns (string identity);

    /// @dev Returns the address of the owner of the given token id.
    /// @param _id Bytes32 id of token to lookup.
    function ownerOf(bytes32 _id) constant returns (address owner);
}


contract IndividualityTokenRoot is IndividualityTokenRootInterface {
    TokenInterface public devcon2Token;

    function IndividualityTokenRoot(address _devcon2Token) {
        devcon2Token = TokenInterface(_devcon2Token);
    }

    // owner => token
    mapping (address => bytes32) ownerToToken;

    // token => owner
    mapping (bytes32 => address) tokenToOwner;

    // owner => spender => token
    mapping (address => mapping (address => bytes32)) approvals;

    uint _upgradeCount;

    /*
     * Internal Helpers
     */
    function isEligibleForUpgrade(address _owner) internal returns (bool) {
        if (ownerToToken[_owner] != 0x0) {
            // already a token owner
            return false;
        } else if (!devcon2Token.isTokenOwner(_owner)) {
            // not a token owner on the original devcon2Token contract.
            return false;
        } else if (isTokenUpgraded(bytes32(devcon2Token.balanceOf(_owner)))) {
            // the token has already been upgraded.
            return false;
        } else {
            return true;
        }
    }

    /*
     * Any function modified with this will perform the `upgrade` call prior to
     * execution which allows people to use this contract as-if they had
     * already processed the upgrade.
     */
    modifier silentUpgrade {
        if (isEligibleForUpgrade(msg.sender)) {
            upgrade();
        }
        _;
    }


    /// @dev Return the number of tokens
    function totalSupply() constant returns (uint256) {
        return devcon2Token.totalSupply();
    }

    /// @dev Returns id of token owned by given address (encoded as an integer).
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        if (_owner == 0x0) {
            return 0;
        } else if (ownerToToken[_owner] == 0x0) {
            // not a current token owner.  Check whether they are on the
            // original contract.
            if (devcon2Token.isTokenOwner(_owner)) {
                // pull the tokenID
                var tokenID = bytes32(devcon2Token.balanceOf(_owner));

                if (tokenToOwner[tokenID] == 0x0) {
                    // the token hasn't yet been upgraded so we can return 1.
                    return 1;
                }
            }
            return 0;
        } else {
            return 1;
        }
    }

    /// @dev Returns the token id that may transfer from _owner account by _spender..
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner,
                       address _spender) constant returns (uint256 remaining) {
        var approvedTokenID = approvals[_owner][_spender];

        if (approvedTokenID == 0x0) {
            return 0;
        } else if (_owner == 0x0 || _spender == 0x0) {
            return 0;
        } else if (tokenToOwner[approvedTokenID] == _owner) {
            return 1;
        } else {
            return 0;
        }
    }

    /// @dev Transfers sender token to given address. Returns success.
    /// @param _to Address of new token owner.
    /// @param _value Bytes32 id of the token to transfer.
    function transfer(address _to,
                      uint256 _value) public silentUpgrade returns (bool success) {
        if (_value != 1) {
            // 1 is the only value that makes any sense here.
            return false;
        } else if (_to == 0x0) {
            // cannot transfer to the null address.
            return false;
        } else if (ownerToToken[msg.sender] == 0x0) {
            // msg.sender is not a token owner
            return false;
        } else if (ownerToToken[_to] != 0x0) {
            // cannot transfer to an address that already owns a token.
            return false;
        } else if (isEligibleForUpgrade(_to)) {
            // cannot transfer to an account which is still holding their token
            // in the old system.
            return false;
        }

        // pull the token id.
        var tokenID = ownerToToken[msg.sender];

        // remove the token from the sender.
        ownerToToken[msg.sender] = 0x0;

        // assign the token to the new owner
        ownerToToken[_to] = tokenID;
        tokenToOwner[tokenID] = _to;

        // log the transfer
        Transfer(msg.sender, _to, 1);
        TokenEventLib._Transfer(msg.sender, _to, tokenID);

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
        } else if (ownerToToken[_from] == 0x0) {
            // Cannot transfer if _from is not a token owner
            return false;
        } else if (ownerToToken[_to] != 0x0) {
            // Cannot transfer to an existing token owner
            return false;
        } else if (approvals[_from][msg.sender] != ownerToToken[_from]) {
            // The approved token doesn't match the token being transferred.
            return false;
        } else if (isEligibleForUpgrade(_to)) {
            // cannot transfer to an account which is still holding their token
            // in the old system.
            return false;
        }

        // pull the tokenID
        var tokenID = ownerToToken[_from];

        // null out the approval
        approvals[_from][msg.sender] = 0x0;

        // remove the token from the sender.
        ownerToToken[_from] = 0x0;

        // assign the token to the new owner
        ownerToToken[_to] = tokenID;
        tokenToOwner[tokenID] = _to;

        // log the transfer
        Transfer(_from, _to, 1);
        TokenEventLib._Transfer(_from, _to, tokenID);

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
                     uint256 _value) public silentUpgrade returns (bool success) {
        if (_value != 1) {
            // cannot approve any value other than 1
            return false;
        } else if (_spender == 0x0) {
            // cannot approve the null address as a spender.
            return false;
        } else if (ownerToToken[msg.sender] == 0x0) {
            // cannot approve if not a token owner.
            return false;
        }

        var tokenID = ownerToToken[msg.sender];
        approvals[msg.sender][_spender] = tokenID;

        Approval(msg.sender, _spender, 1);
        TokenEventLib._Approval(msg.sender, _spender, tokenID);

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
        if (_owner == 0x0) {
            return false;
        } else if (ownerToToken[_owner] == 0x0) {
            // Check if the owner has a token on the main devcon2Token contract.
            if (devcon2Token.isTokenOwner(_owner)) {
                // pull the token ID
                var tokenID = bytes32(devcon2Token.balanceOf(_owner));

                if (tokenToOwner[tokenID] == 0x0) {
                    // They own an un-transfered token in the parent
                    // devcon2Token contract.
                    return true;
                }
            }
            return false;
        } else {
            return true;
        }
    }

    /// @dev Returns the address of the owner of the given token id.
    /// @param _tokenID Bytes32 id of token to lookup.
    function ownerOf(bytes32 _tokenID) constant returns (address owner) {
        if (_tokenID == 0x0) {
            return 0x0;
        } else if (tokenToOwner[_tokenID] != 0x0) {
            return tokenToOwner[_tokenID];
        } else {
            return devcon2Token.ownerOf(_tokenID);
        }
    }

    /// @dev Returns the token ID for the given address or 0x0 if they are not a token owner.
    /// @param _owner Address of the owner to lookup.
    function tokenId(address _owner) constant returns (bytes32 tokenID) {
        if (_owner == 0x0) {
            return 0x0;
        } else if (ownerToToken[_owner] != 0x0) {
            return ownerToToken[_owner];
        } else {
            tokenID = bytes32(devcon2Token.balanceOf(_owner));
            if (tokenToOwner[tokenID] == 0x0) {
                // this token has not been transfered yet so return the proxied
                // value.
                return tokenID;
            } else {
                // The token has already been transferred so ignore the parent
                // contract data.
                return 0x0;
            }
        }
    }

    /// @dev Upgrades a token from the previous contract
    function upgrade() public returns (bool success) {
        if (!devcon2Token.isTokenOwner(msg.sender)) {
            // not a token owner.
            return false;
        } else if (ownerToToken[msg.sender] != 0x0) {
            // already owns a token
            return false;
        }
        
        // pull the token ID
        var tokenID = bytes32(devcon2Token.balanceOf(msg.sender));

        if (tokenID == 0x0) {
            // (should not be possible but here as a sanity check)
            // null token is invalid.
            return false;
        } else if (tokenToOwner[tokenID] != 0x0) {
            // already upgraded.
            return false;
        } else if (devcon2Token.ownerOf(tokenID) != msg.sender) {
            // (should not be possible but here as a sanity check)
            // not the owner of the token.
            return false;
        }

        // Assign the new ownership.
        ownerToToken[msg.sender] = tokenID;
        tokenToOwner[tokenID] = msg.sender;

        // increment the number of tokens that have been upgraded.
        _upgradeCount += 1;

        // Log it
        Mint(msg.sender, tokenID);
        return true;
    }

    /// @dev Upgrades a token from the previous contract
    /// @param _owner the address of the owner of the token on the original contract
    /// @param _newOwner the address that should own the token on the new contract.
    /// @param signature 65 byte signature of the tightly packed bytes (address(this) + _owner + _newOwner), signed by _owner
    function proxyUpgrade(address _owner,
                          address _newOwner,
                          bytes signature) public returns (bool) {
        if (_owner == 0x0 || _newOwner == 0x0) {
            // cannot work with null addresses.
            return false;
        } else if (!devcon2Token.isTokenOwner(_owner)) {
            // not a token owner on the original devcon2Token contract.
            return false;
        }

        bytes32 tokenID = bytes32(devcon2Token.balanceOf(_owner));

        if (tokenID == 0x0) {
            // (should not be possible since we already checked isTokenOwner
            // but I like being explicit)
            return false;
        } else if (isTokenUpgraded(tokenID)) {
            // the token has already been upgraded.
            return false;
        } else if (ownerToToken[_newOwner] != 0x0) {
            // new owner already owns a token
            return false;
        } else if (_owner != _newOwner && isEligibleForUpgrade(_newOwner)) {
            // cannot upgrade to account that is still has an upgradable token
            // on the old system.
            return false;
        }

        bytes32 signatureHash = sha3(address(this), _owner, _newOwner);

        if (!ECVerifyLib.ecverify(signatureHash, signature, _owner)) {
            return false;
        }

        // Assign the new token
        tokenToOwner[tokenID] = _newOwner;
        ownerToToken[_newOwner] = tokenID;

        // increment the number of tokens that have been upgraded.
        _upgradeCount += 1;

        // Log it
        Mint(_newOwner, tokenID);

        return true;
    }

    /// @dev Returns the number of tokens that have been upgraded.
    function upgradeCount() constant returns (uint256 _amount) {
        return _upgradeCount;
    }

    /// @dev Returns the number of tokens that have been upgraded.
    /// @param _tokenID the id of the token to query
    function isTokenUpgraded(bytes32 _tokenID) constant returns (bool isUpgraded) {
        return (tokenToOwner[_tokenID] != 0x0);
    }
}


contract MainnetIndividualityTokenRoot is 
         IndividualityTokenRoot(0x0a43edfe106d295e7c1e591a4b04b5598af9474c) {
}