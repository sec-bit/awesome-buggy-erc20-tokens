pragma solidity 0.4.18;

/// @title LRC Foundation Icebox Program
/// @author Daniel Wang - <daniel@loopring.org>.
/// For more information, please visit https://loopring.org.

/// Loopring Foundation's LRC (20% of total supply) will be locked during the first two years，
/// two years later, 1/24 of all locked LRC fund can be unlocked every month.

/// @title ERC20 ERC20 Interface
/// @dev see https://github.com/ethereum/EIPs/issues/20
/// @author Daniel Wang - <daniel@loopring.org>
contract ERC20 {
    uint public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address who) view public returns (uint256);
    function allowance(address owner, address spender) view public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

contract AirDropContract {

    event AirDropped(address addr, uint amount);

    function drop(
        address tokenAddress,
        uint amount,
        uint minTokenBalance,
        uint maxTokenBalance,
        uint minEthBalance,
        uint maxEthBalance,
        address[] recipients) public {

        require(tokenAddress != 0x0);
        require(amount > 0);
        require(maxTokenBalance >= minTokenBalance);
        require(maxEthBalance >= minEthBalance);

        ERC20 token = ERC20(tokenAddress);

        uint balance = token.balanceOf(msg.sender);
        uint allowance = token.allowance(msg.sender, address(this));
        uint available = balance > allowance ? allowance : balance;

        for (uint i = 0; i < recipients.length; i++) {
            require(available >= amount);
            address recipient = recipients[i];
            if (isQualitifiedAddress(
                token,
                recipient,
                minTokenBalance,
                maxTokenBalance,
                minEthBalance,
                maxEthBalance
            )) {
                available -= amount;
                require(token.transferFrom(msg.sender, recipient, amount));

                AirDropped(recipient, amount);
            }
        }
    }

    function isQualitifiedAddress(
        ERC20 token,
        address addr,
        uint minTokenBalance,
        uint maxTokenBalance,
        uint minEthBalance,
        uint maxEthBalance
        )
        public
        view
        returns (bool result)
    {
        result = addr != 0x0 && addr != msg.sender && !isContract(addr);

        uint ethBalance = addr.balance;
        uint tokenBbalance = token.balanceOf(addr);

        result = result && (ethBalance>= minEthBalance &&
            ethBalance <= maxEthBalance &&
            tokenBbalance >= minTokenBalance &&
            tokenBbalance <= maxTokenBalance);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function () payable public {
        revert();
    }
}