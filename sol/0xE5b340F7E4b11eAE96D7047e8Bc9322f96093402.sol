contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Hodl {

    mapping(address => mapping(address => uint)) private amounts;
    mapping(address => mapping(address => uint)) private timestamps;

    event Hodling(address indexed sender, address indexed tokenAddress, uint256 amount);
    event TokenReturn(address indexed sender, address indexed tokenAddress, uint256 amount);

    function hodlTokens(address tokenAddress, uint256 amount, uint timestamp) public {
        assert(tokenAddress != address(0));
        assert(amount != uint256(0));
        assert(timestamp != uint(0));
        assert(amounts[msg.sender][tokenAddress] == 0);

        amounts[msg.sender][tokenAddress] = amount;
        timestamps[msg.sender][tokenAddress] = timestamp;

        ERC20 erc20 = ERC20(tokenAddress);
        assert(erc20.transferFrom(msg.sender, this, amount) == true);

        Hodling(msg.sender, tokenAddress, amount);
    }

    function getTokens(address tokenAddress) public {
        assert(tokenAddress != address(0));
        assert(amounts[msg.sender][tokenAddress] > 0);
        assert(now >= timestamps[msg.sender][tokenAddress]);

        ERC20 erc20 = ERC20(tokenAddress);
        uint256 amount = amounts[msg.sender][tokenAddress];

        delete amounts[msg.sender][tokenAddress];
        delete timestamps[msg.sender][tokenAddress];
        assert(erc20.transfer(msg.sender, amount) == true);

        TokenReturn(msg.sender, tokenAddress, amount);
    }

    function getTimestamp(address tokenAddress) public view returns (uint) {
        return timestamps[msg.sender][tokenAddress];
    }

    function getAmount(address tokenAddress) public view returns (uint256) {
        return amounts[msg.sender][tokenAddress];
    }

}