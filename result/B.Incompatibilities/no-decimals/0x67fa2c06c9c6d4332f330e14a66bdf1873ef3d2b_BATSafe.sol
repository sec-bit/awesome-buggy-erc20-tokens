pragma solidity ^0.4.10;

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


// requires 133,650,000 BAT deposited here
contract BATSafe {
  mapping (address => uint256) allocations;
  uint256 public unlockDate;
  address public BAT;
  uint256 public constant exponent = 10**18;

  function BATSafe(address _BAT) {
    BAT = _BAT;
    unlockDate = now + 6 * 30 days;
    allocations[0xe0f6EF3D61255d1Bd7ad66987D2fBB3FE5Ee8Ea4] = 16000000;
    allocations[0xCB25966330044310ecD09634ea6B1f4190d5B10D] = 16000000;
    allocations[0xFf8e2295EF4Ad0db7aFaDC13743c227Bb0e82838] = 16000000;
    allocations[0x9Dc920118672c04645Eb2831A70d2aA1ccBF330c] = 16000000;
    allocations[0xb9FE2d16eBAD02Ba3A6f61F64e8506F1C80cec07] = 8000000;
    allocations[0x92C9304e826451a3Af0fc9f4d36Ae59920F80b0f] = 8000000;
    allocations[0x5cAe9Bc0C527f95CC6558D32EC5B931ad7328088] = 8000000;
    allocations[0xF94BE6b93432b39Bc1637FDD656740758736d935] = 4000000;
    allocations[0x4Fb65030536103EA718Fa37A3E05c76aDB3C5447] = 4000000;
    allocations[0x216C83DD2383e44cb9914C05aCd019dde429F201] = 2250000;
    allocations[0x460599DC0A5AF7b4bef0ee6fdDA23DBF8CC6cA70] = 2000000;
    allocations[0x06BdBDcCBeC95937b742c0EADf7B2f50c4f325C0] = 2000000;
    allocations[0x6eED129DD60251c7C839Bf0D161199a3A3FED959] = 2000000;
    allocations[0xAF6929A04651FE2fDa8eBBD18A6ed89ba6F7bb3b] = 2000000;
    allocations[0x74019652e7Bfe06e055f1424E8F695d85c5AdDDa] = 2000000;
    allocations[0x77D325161984D3A5835cfEB5dB4E6CF998904a84] = 2000000;
    allocations[0x7b28547b78e425AbaE8f472e2A77021e9b19B5ad] = 2000000;
    allocations[0xFF6Cb8161A55DB05F9B41F34F5A8B3dc1F1E1A7e] = 2000000;
    allocations[0x016078A5e18D9a2A4698e8623744556F09a9Ca15] = 2000000;
    allocations[0x5A471480d72D6a6Da75b7546D740F95387174c2D] = 2000000;
    allocations[0xb46De0168c02246C0C1C4Cf562E9003cBf01CdD7] = 2000000;
    allocations[0x9bbBD666B714C84764B1aE4012DD177526E63fB4] = 2000000;
    allocations[0xC6aD53B70d2cCEf579D0CC4a22Ed18a62ADD33b6] = 2000000;
    allocations[0x398aD5ed756C42758B33c4Ae36162E5C0cE787cE] = 2000000;
    allocations[0x4b93f57953D685F7241699a87F2464fA8B1b9bD9] = 2000000;
    allocations[0xFCdFdD838bAf60E53EAc5d86F3234854f7e0DDee] = 2000000;
    allocations[0x98949388D6c5e9B91a1F30e33595A5E6127036bE] = 2000000;
    allocations[0x7A5c1A532a89B50c84f9fFd7f915093f5C637081] = 700000;
    allocations[0x2cb8457Adde40aa7298C19Fa94426B94317C2744] = 700000;
  }

  function unlock() external {
    if(now < unlockDate) throw;
    uint256 entitled = allocations[msg.sender];
    allocations[msg.sender] = 0;
    if(!StandardToken(BAT).transfer(msg.sender, entitled * exponent)) throw;
  }

}