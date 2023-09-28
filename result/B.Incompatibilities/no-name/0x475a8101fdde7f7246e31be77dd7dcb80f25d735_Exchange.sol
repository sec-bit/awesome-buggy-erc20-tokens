pragma solidity ^0.4.19;

contract Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    uint8 public decimals;
}

contract Exchange {
    struct Order {
        address creator;
        address token;
        bool buy;
        uint price;
        uint amount;
    }
    
    address public owner;
    uint public feeDeposit = 500;
    
    mapping (uint => Order) orders;
    uint currentOrderId = 0;
    
    /* Token address (0x0 - Ether) => User address => balance */
    mapping (address => mapping (address => uint)) public balanceOf;
    
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    event PlaceSell(address indexed token, address indexed user, uint price, uint amount, uint id);
    event PlaceBuy(address indexed token, address indexed user, uint price, uint amount, uint id);
    event FillOrder(uint id, uint amount);
    event CancelOrder(uint id);
    event Deposit(address indexed token, address indexed user, uint amount);
    event Withdraw(address indexed token, address indexed user, uint amount);
    event BalanceChanged(address indexed token, address indexed user, uint value);

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
    
    function Exchange() public {
        owner = msg.sender;
    }
    
    function safeAdd(uint a, uint b) private pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
    
    function safeSub(uint a, uint b) private pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function safeMul(uint a, uint b) private pure returns (uint) {
        if (a == 0) {
          return 0;
        }
        
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function decFeeDeposit(uint delta) external onlyOwner {
        feeDeposit = safeSub(feeDeposit, delta);
    }
    
    function calcAmountEther(address tokenAddr, uint price, uint amount) private view returns (uint) {
        uint k = 10;
        k = k ** Token(tokenAddr).decimals();
        return safeMul(amount, price) / k;
    }
    
    function balanceAdd(address tokenAddr, address user, uint amount) private {
        balanceOf[tokenAddr][user] =
            safeAdd(balanceOf[tokenAddr][user], amount);
    }
    
    function balanceSub(address tokenAddr, address user, uint amount) private {
        require(balanceOf[tokenAddr][user] >= amount);
        balanceOf[tokenAddr][user] =
            safeSub(balanceOf[tokenAddr][user], amount);
    }
    
    function placeBuy(address tokenAddr, uint price, uint amount) external {
        require(price > 0 && amount > 0);
        uint amountEther = calcAmountEther(tokenAddr, price, amount);
        require(amountEther > 0);
        balanceSub(0x0, msg.sender, amountEther);
        BalanceChanged(0x0, msg.sender, balanceOf[0x0][msg.sender]);
        orders[currentOrderId] = Order({
            creator: msg.sender,
            token: tokenAddr,
            buy: true,
            price: price,
            amount: amount
        });
        PlaceBuy(tokenAddr, msg.sender, price, amount, currentOrderId);
        currentOrderId++;
    }
    
    function placeSell(address tokenAddr, uint price, uint amount) external {
        require(price > 0 && amount > 0);
        uint amountEther = calcAmountEther(tokenAddr, price, amount);
        require(amountEther > 0);
        balanceSub(tokenAddr, msg.sender, amount);
        BalanceChanged(tokenAddr, msg.sender, balanceOf[tokenAddr][msg.sender]);
        orders[currentOrderId] = Order({
            creator: msg.sender,
            token: tokenAddr,
            buy: false,
            price: price,
            amount: amount
        });
        PlaceSell(tokenAddr, msg.sender, price, amount, currentOrderId);
        currentOrderId++;
    }
    
    function fillOrder(uint id, uint amount) external {
        require(id < currentOrderId);
        require(orders[id].creator != msg.sender);
        require(orders[id].amount >= amount);
        uint amountEther = calcAmountEther(orders[id].token, orders[id].price, amount);
        if (orders[id].buy) {
            /* send tokens from sender to creator */
            // sub from sender
            balanceSub(orders[id].token, msg.sender, amount);
            BalanceChanged(
                orders[id].token,
                msg.sender,
                balanceOf[orders[id].token][msg.sender]
            );
            
            // add to creator
            balanceAdd(orders[id].token, orders[id].creator, amount);
            BalanceChanged(
                orders[id].token,
                orders[id].creator,
                balanceOf[orders[id].token][orders[id].creator]
            );
            
            /* send Ether to sender */
            balanceAdd(0x0, msg.sender, amountEther);
            BalanceChanged(
                0x0,
                msg.sender,
                balanceOf[0x0][msg.sender]
            );
        } else {
            /* send Ether from sender to creator */
            // sub from sender
            balanceSub(0x0, msg.sender, amountEther);
            BalanceChanged(
                0x0,
                msg.sender,
                balanceOf[0x0][msg.sender]
            );
            
            // add to creator
            balanceAdd(0x0, orders[id].creator, amountEther);
            BalanceChanged(
                0x0,
                orders[id].creator,
                balanceOf[0x0][orders[id].creator]
            );
            
            /* send tokens to sender */
            balanceAdd(orders[id].token, msg.sender, amount);
            BalanceChanged(
                orders[id].token,
                msg.sender,
                balanceOf[orders[id].token][msg.sender]
            );
        }
        orders[id].amount -= amount;
        FillOrder(id, orders[id].amount);
    }
    
    function cancelOrder(uint id) external {
        require(id < currentOrderId);
        require(orders[id].creator == msg.sender);
        require(orders[id].amount > 0);
        if (orders[id].buy) {
            uint amountEther = calcAmountEther(orders[id].token, orders[id].price, orders[id].amount);
            balanceAdd(0x0, msg.sender, amountEther);
            BalanceChanged(0x0, msg.sender, balanceOf[0x0][msg.sender]);
        } else {
            balanceAdd(orders[id].token, msg.sender, orders[id].amount);
            BalanceChanged(orders[id].token, msg.sender, balanceOf[orders[id].token][msg.sender]);
        }
        orders[id].amount = 0;
        CancelOrder(id);
    }
    
    function () external payable {
        require(msg.value > 0);
        uint fee = msg.value * feeDeposit / 10000;
        require(msg.value > fee);
        balanceAdd(0x0, owner, fee);
        
        uint toAdd = msg.value - fee;
        balanceAdd(0x0, msg.sender, toAdd);
        
        Deposit(0x0, msg.sender, toAdd);
        BalanceChanged(0x0, msg.sender, balanceOf[0x0][msg.sender]);
        
        FundTransfer(msg.sender, toAdd, true);
    }
    
    function depositToken(address tokenAddr, uint amount) external {
        require(tokenAddr != 0x0);
        require(amount > 0);
        Token(tokenAddr).transferFrom(msg.sender, this, amount);
        balanceAdd(tokenAddr, msg.sender, amount);
        
        Deposit(tokenAddr, msg.sender, amount);
        BalanceChanged(tokenAddr, msg.sender, balanceOf[tokenAddr][msg.sender]);
    }
    
    function withdrawEther(uint amount) external {
        require(amount > 0);
        balanceSub(0x0, msg.sender, amount);
        msg.sender.transfer(amount);
        
        Withdraw(0x0, msg.sender, amount);
        BalanceChanged(0x0, msg.sender, balanceOf[0x0][msg.sender]);
        
        FundTransfer(msg.sender, amount, false);
    }
    
    function withdrawToken(address tokenAddr, uint amount) external {
        require(tokenAddr != 0x0);
        require(amount > 0);
        balanceSub(tokenAddr, msg.sender, amount);
        Token(tokenAddr).transfer(msg.sender, amount);
        
        Withdraw(tokenAddr, msg.sender, amount);
        BalanceChanged(tokenAddr, msg.sender, balanceOf[tokenAddr][msg.sender]);
    }
}