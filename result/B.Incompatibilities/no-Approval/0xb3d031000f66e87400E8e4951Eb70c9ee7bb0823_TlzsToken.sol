contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
    /* 令牌的公开变量 */
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* 所有账本的数组 */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* 定义一个事件，当交易发生时，通知客户端 */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* 初始化合约 */
    function token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              // 合约的创建者拥有这合约所有的初始令牌
        totalSupply = initialSupply;                        // 更新令牌供给总数
        name = tokenName;                                   // 设置令牌的名字
        symbol = tokenSymbol;                               // 设置令牌的符号
        decimals = decimalUnits;                            // 设置令牌的小数位
    }

    /* 发送令牌 */
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // 检查这发送者是否有足够多的令牌
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // 检查溢出
        balanceOf[msg.sender] -= _value;                     // 从发送者账户减去相应的额度
        balanceOf[_to] += _value;                            // 从接收者账户增加相应的额度
        Transfer(msg.sender, _to, _value);                   // 事件。通知所有正在监听这个合约的用户
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /* 匿名方法，预防有人向这合约发送以太币 */
    function () {
        throw;     
    }
}

contract TlzsToken is owned, token {


    mapping (address => bool) public frozenAccount;

    /* 定义一个事件，当有资产被冻结的时候，通知正在监听事件的客户端 */
    event FrozenFunds(address target, bool frozen);

    /* 初始化合约 */
    function TlzsToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

    /* 发送令牌 */
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // 检查发送者是否有足够多的令牌
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // 检查溢出
        if (frozenAccount[msg.sender]) throw;                // 检查冻结状态
        balanceOf[msg.sender] -= _value;                     // 从发送者的账户上减去相应的数额
        balanceOf[_to] += _value;                            // 从接收者的账户上增加相应的数额
        Transfer(msg.sender, _to, _value);                   // 事件通知
    }


    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                        // Check if frozen            
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
}