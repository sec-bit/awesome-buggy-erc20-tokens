pragma solidity ^0.4.15;

contract Versionable {
    string public versionCode;

    function getVersionByte(uint index) constant returns (bytes1) { 
        return bytes(versionCode)[index];
    }

    function getVersionLength() constant returns (uint256) {
        return bytes(versionCode).length;
    }
}


contract Token {
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    function approve(address _spender, uint256 _value) returns (bool success);
}

contract ContractCatalog {
    uint256 public constant VERSION = 3;
    string public constant SEPARATOR = "-";

    Token public token;
    address public owner;
    
    event RegisteredPrefix(string _prefix, address _owner);
    event TransferredPrefix(string _prefix, address _from, address _to);
    event UnregisteredPrefix(string _prefix, address _from);
    event NewPrefixPrice(uint256 _length, uint256 _price);
    event RegisteredContract(string _version, address _by);

    struct ContractType {
        string code;
        address sample;
    }

    function ContractCatalog() {
        token = Token(address(0xF970b8E36e23F7fC3FD752EeA86f8Be8D83375A6));
        owner = address(0xA1091481AEde4adDe00C1a26992AE49a7e0E1FB0);

        // Set up all forgived chars
        addForgivedChar(" ");
        addForgivedChar("‐");
        addForgivedChar("‑");
        addForgivedChar("‒");
        addForgivedChar("–");
        addForgivedChar("﹘");
        addForgivedChar("۔");
        addForgivedChar("⁃");
        addForgivedChar("˗");
        addForgivedChar("−");
        addForgivedChar("➖");
        addForgivedChar("Ⲻ");
    }

    mapping(string => ContractType) types;
    mapping(string => address) prefixes;
    mapping(uint256 => uint256) prefixesPrices;

    string[] public forgivedChars;

    function getPrefixOwner(string prefix) constant returns (address) {
        return prefixes[prefix];
    }

    function getPrefixPrice(string prefix) constant returns (uint256) { 
        return prefixesPrices[stringLen(prefix)];
    }

    function transfer(address to) {
        require(to != address(0));
        require(msg.sender == owner);
        owner = to;
    }

    function replaceToken(Token _token) {
        require(_token != address(0));
        require(msg.sender == owner);
        token = _token;
    }

    function setPrefixPrice(uint256 lenght, uint256 price) {
        require(msg.sender == owner);
        require(lenght != 0);
        prefixesPrices[lenght] = price;
        NewPrefixPrice(lenght, price);
    }

    function loadVersion(Versionable from) private returns (string) {
        uint size = from.getVersionLength();
        bytes memory out = new bytes(size);
        for (uint i = 0; i < size; i++) {
            out[i] = from.getVersionByte(i);
        }
        return string(out);
    }

    function getContractOwner(string code) constant returns (address) {
        string memory prefix = splitFirst(code, "-");
        return prefixes[prefix];
    }

    function getContractSample(string code) constant returns (address) {
        return types[code].sample;
    }

    function getContractBytecode(string code) constant returns (bytes) {
        return getContractCode(types[code].sample);
    }

    function hasForgivedChar(string s) private returns (bool) {
        for (uint i = 0; i < forgivedChars.length; i++) {
            if (stringContains(s, forgivedChars[i]))
                return true;
        }
    }

    function addForgivedChar(string c) {
        require(msg.sender == owner || msg.sender == address(this));
        if (!hasForgivedChar(c)) {
            forgivedChars.push(c);
        }
    }

    function removeForgivedChar(uint256 index, string char) {
        require(msg.sender == owner);
        require(stringEquals(char, forgivedChars[index]));
        string storage lastChar = forgivedChars[forgivedChars.length - 1];
        delete forgivedChars[forgivedChars.length - 1];
        forgivedChars[index] = lastChar;
    }

    function registerPrefix(string prefix) returns (bool) {
        require(!stringContains(prefix, SEPARATOR));
        require(!hasForgivedChar(prefix));
        require(prefixes[prefix] == address(0));
        RegisteredPrefix(prefix, msg.sender);
        if (msg.sender == owner) {
            prefixes[prefix] = owner;
            return true;
        } else {
            uint256 price = prefixesPrices[stringLen(prefix)];
            require(price != 0);
            require(token.transferFrom(msg.sender, owner, price));
            prefixes[prefix] = msg.sender;
            return true;
        }
    }

    function transferPrefix(string prefix, address to) {
        require(to != address(0));
        require(prefixes[prefix] == msg.sender);
        prefixes[prefix] = to;
        TransferredPrefix(prefix, msg.sender, to);
    }

    function unregisterPrefix(string prefix) {
        require(prefixes[prefix] == msg.sender);
        prefixes[prefix] = address(0);
        UnregisteredPrefix(prefix, msg.sender);
    }

    function registerContract(string code, address sample) {
        var prefix = splitFirst(code, SEPARATOR);
        require(prefixes[prefix] == msg.sender);
        require(types[code].sample == address(0));
        require(getContractCode(sample).length != 0);
        types[code] = ContractType(code, sample);
        RegisteredContract(code, msg.sender);
    }

    function validateContract(Versionable target) constant returns (bool) {
        return validateContractWithCode(target, loadVersion(target));
    }

    function validateContractWithCode(address target, string code) constant returns (bool) {
        require(stringEquals(types[code].code, code)); // Sanity check
        bytes memory expected = getContractCode(types[code].sample);
        bytes memory bytecode = getContractCode(target);
        require(expected.length != 0);
        if (bytecode.length != expected.length) return false;
        for (uint i = 0; i < expected.length; i++) {
            if (bytecode[i] != expected[i]) return false;
        }
        return true;
    }

    function getContractCode(address _addr) private returns (bytes o_code) {
        assembly {
          let size := extcodesize(_addr)
          o_code := mload(0x40)
          mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
          mstore(o_code, size)
          extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }

    // @dev Returns the first slice of a split
    function splitFirst(string source, string point) private returns (string) {
        bytes memory s = bytes(source);
        if (s.length == 0) {
            return "";
        } else {
            int index = stringIndexOf(source, point);
            if (index == - 1) {
                return "";
            } else {
                bytes memory output = new bytes(uint(index));
                for (int i = 0; i < index; i++) {
                    output[uint(i)] = s[uint(i)];
                }
                return string(output);
            }
        }
    }

    function stringToBytes32(string memory source) private returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

        /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function stringLen(string s) private returns (uint) {
        var self = stringToBytes32(s);
        uint ret;
        if (self == 0)
            return 0;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function stringIndexOf(string _haystack, string _needle) private returns (int) {
    	bytes memory h = bytes(_haystack);
    	bytes memory n = bytes(_needle);
    	if (h.length < 1 || n.length < 1 || (n.length > h.length)) {
    		return -1;
    	} else if (h.length > (2**128 - 1)) { // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
    		return -1;									
    	} else {
    		uint subindex = 0;
    		for (uint i = 0; i < h.length; i ++) {
    			if (h[i] == n[0]) { // found the first char of b
    				subindex = 1;
    				while (subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) { // search until the chars don't match or until we reach the end of a or b
    					subindex++;
    				}	
    				if (subindex == n.length)
    					return int(i);
    			}
    		}
    		return -1;
    	}	
    }

    function stringEquals(string _a, string _b) private returns (bool) {
    	bytes memory a = bytes(_a);
    	bytes memory b = bytes(_b);
        if (a.length != b.length) return false;
        for (uint i = 0; i < a.length; i++) {
            if (a[i] != b[i]) return false;
        }
        return true;
    }

    function stringContains(string self, string needle) private returns (bool) {
        return stringIndexOf(self, needle) != int(-1);
    }
}