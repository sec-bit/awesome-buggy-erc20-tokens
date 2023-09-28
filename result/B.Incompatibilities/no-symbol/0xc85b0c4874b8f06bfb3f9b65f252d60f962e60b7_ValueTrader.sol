pragma solidity ^0.4.0;

contract SafeMath {
  //internals

  function safeMul(uint256 a, uint256 b) internal returns (uint256 c) {
    c = a * b;
    assert(a == 0 || c / a == b);
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256 c) {
    assert(b <= a);
    c = a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256 c) {
    c = a + b;
    assert(c>=a && c>=b);
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

contract Token {
  /// @return total amount of tokens
  function totalSupply() constant returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

contract ValueToken is SafeMath,Token{
    
    string name = "Value";
    uint decimals = 0;
    
    uint256 supplyNow = 0; 
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function totalSupply() constant returns (uint256 totalSupply){
        return supplyNow;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) returns (bool success){
        if (balanceOf(msg.sender) >= _value) {
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
        
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] = safeAdd(balanceOf(_to), _value);
            balances[_from] = safeSub(balanceOf(_from), _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success){
        if(balances[msg.sender] >= _value){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
        } else { return false; }
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    
    function createValue(address _owner, uint256 _value) internal returns (bool success){
        balances[_owner] = safeAdd(balances[_owner], _value);
        supplyNow = safeAdd(supplyNow, _value);
        Mint(_owner, _value);
    }
    
    function destroyValue(address _owner, uint256 _value) internal returns (bool success){
        balances[_owner] = safeSub(balances[_owner], _value);
        supplyNow = safeSub(supplyNow, _value);
        Burn(_owner, _value);
    }
    
    event Mint(address indexed _owner, uint256 _value);
    
    event Burn(address indexed _owner, uint256 _value);
    
}

/// @title Quick trading and interest-yielding savings.
contract ValueTrader is SafeMath,ValueToken{
    
    function () payable {
        // this contract eats any money sent to it incorrectly.
        // thank you for the donation.
    }
    
    // use this to manage tokens
    struct TokenData {
        bool isValid; // is this token currently accepted
        uint256 basePrice; //base price of this token
        uint256 baseLiquidity; //target liquidity of this token (price = basePrice +psf)
        uint256 priceScaleFactor; //how quickly does price increase above base
        bool hasDividend;
        address divContractAddress;
        bytes divData;
    }
    
    address owner;
    address etherContract;
    uint256 tradeCoefficient; // 1-(this/10000) = fee for instant trades, "negative" fees possible.
    mapping (address => TokenData) tokenManage;
    bool public burning = false; //after draining is finished, burn to retrieve tokens, allow suicide.
    bool public draining = false; //prevent creation of new value
    
    modifier owned(){
        assert(msg.sender == owner);
        _;
    }
    
    modifier burnBlock(){
        assert(!burning);
        _;
    }
    
    modifier drainBlock(){
        assert(!draining);
        _;
    }
    
    //you cannot turn off draining without turning off burning first.
    function toggleDrain() burnBlock owned {
        draining = !draining;
    }
    
    function toggleBurn() owned {
        assert(draining);
        assert(balanceOf(owner) == supplyNow);
        burning = !burning;
    }
    
    function die() owned burnBlock{
        //MAKE SURE TO RETRIEVE TOKEN BALANCES BEFORE DOING THIS!
        selfdestruct(owner);
    }
    
    function validateToken(address token_, uint256 bP_, uint256 bL_, uint256 pF_) owned {
        
        tokenManage[token_].isValid = true;
        tokenManage[token_].basePrice = bP_;
        tokenManage[token_].baseLiquidity = bL_;
        tokenManage[token_].priceScaleFactor = pF_;
        
    }
    
    function configureTokenDividend(address token_, bool hD_, address dA_, bytes dD_) owned {
    
        tokenManage[token_].hasDividend = hD_;
        tokenManage[token_].divContractAddress = dA_;
        tokenManage[token_].divData = dD_;
    }
    
    function callDividend(address token_) owned {
        //this is a dangerous and irresponsible feature,
        //gives owner ability to do virtually anything 
        //(bar running away with all the ether)
        //I can't think of a better solution until there is a standard for dividend-paying contracts.
        assert(tokenManage[token_].hasDividend);
        assert(tokenManage[token_].divContractAddress.call.value(0)(tokenManage[token_].divData));
    }
    
    function invalidateToken(address token_) owned {
        tokenManage[token_].isValid = false;
    }
    
    function changeOwner(address owner_) owned {
        owner = owner_;
    }
    
    function changeFee(uint256 tradeFee) owned {
        tradeCoefficient = tradeFee;
    }
    
    function changeEtherContract(address eC) owned {
        etherContract = eC;
    }
    
    event Buy(address tokenAddress, address buyer, uint256 amount, uint256 remaining);
    event Sell(address tokenAddress, address buyer, uint256 amount, uint256 remaining);
    event Trade(address fromTokAddress, address toTokAddress, address buyer, uint256 amount);

    function ValueTrader(){
        owner = msg.sender;
        burning = false;
        draining = false;
    }
    
    
    
    function valueWithFee(uint256 tempValue) internal returns (uint256 doneValue){
        doneValue = safeMul(tempValue,tradeCoefficient)/10000;
        if(tradeCoefficient < 10000){
            //send fees to owner (in value tokens).
            createValue(owner,safeSub(tempValue,doneValue));
        }
    }
    
    function currentPrice(address token) constant returns (uint256 price){
        if(draining){
            price = 1;
        } else {
        assert(tokenManage[token].isValid);
        uint256 basePrice = tokenManage[token].basePrice;
        uint256 baseLiquidity = tokenManage[token].baseLiquidity;
        uint256 priceScaleFactor = tokenManage[token].priceScaleFactor;
        uint256 currentLiquidity;
        if(token == etherContract){
            currentLiquidity = this.balance;
        }else{
            currentLiquidity = Token(token).balanceOf(this);
        }
        price = safeAdd(basePrice,safeMul(priceScaleFactor,baseLiquidity/currentLiquidity));
        }
    }
    
    function currentLiquidity(address token) constant returns (uint256 liquidity){
        liquidity = Token(token).balanceOf(this);
    }
    
    function valueToToken(address token, uint256 amount) constant internal returns (uint256 value){
        value = amount/currentPrice(token);
        assert(value != 0);
    }
    
    function tokenToValue(address token, uint256 amount) constant internal returns (uint256 value){
        value = safeMul(amount,currentPrice(token));
    }
    
    function sellToken(address token, uint256 amount) drainBlock {
    //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        assert(verifiedTransferFrom(token,msg.sender,amount));
        assert(createValue(msg.sender, tokenToValue(token,amount)));
        Sell(token, msg.sender, amount, balances[msg.sender]);
    }

    function buyToken(address token, uint256 amount) {
        assert(!(valueToToken(token,balances[msg.sender]) < amount));
        assert(destroyValue(msg.sender, tokenToValue(token,amount)));
        assert(Token(token).transfer(msg.sender, amount));
        Buy(token, msg.sender, amount, balances[msg.sender]);
    }
    
    function sellEther() payable drainBlock {
        assert(createValue(msg.sender, tokenToValue(etherContract,msg.value)));
        Sell(etherContract, msg.sender, msg.value, balances[msg.sender]);
    }
    
    function buyEther(uint256 amount) {
        assert(valueToToken(etherContract,balances[msg.sender]) >= amount);
        assert(destroyValue(msg.sender, tokenToValue(etherContract,amount)));
        assert(msg.sender.call.value(amount)());
        Buy(etherContract, msg.sender, amount, balances[msg.sender]);
    }
    
    //input a mixture of a token and ether, recieve the output token
    function quickTrade(address tokenFrom, address tokenTo, uint256 input) payable drainBlock {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the (token) transfer on your behalf.
        uint256 inValue;
        uint256 tempInValue = safeAdd(tokenToValue(etherContract,msg.value),
        tokenToValue(tokenFrom,input));
        inValue = valueWithFee(tempInValue);
        uint256 outValue = valueToToken(tokenTo,inValue);
        assert(verifiedTransferFrom(tokenFrom,msg.sender,input));
        if (tokenTo == etherContract){
          assert(msg.sender.call.value(outValue)());  
        } else assert(Token(tokenTo).transfer(msg.sender, outValue));
        Trade(tokenFrom, tokenTo, msg.sender, inValue);
    }
    
    function verifiedTransferFrom(address tokenFrom, address senderAdd, uint256 amount) internal returns (bool success){
    uint256 balanceBefore = Token(tokenFrom).balanceOf(this);
    success = Token(tokenFrom).transferFrom(senderAdd, this, amount);
    uint256 balanceAfter = Token(tokenFrom).balanceOf(this);
    assert((safeSub(balanceAfter,balanceBefore)==amount));
    }

    
}

//manage ValueTrader in an automated way!
//fixed amount of (2) holders/managers,
//because I'm too lazy to make anything more complex.
contract ShopKeeper is SafeMath{
    
    ValueTrader public shop;
    address holderA; //actually manages the trader, recieves equal share of profits
    address holderB; //only recieves manages own profits, (for profit-container type contracts)
    
    
    modifier onlyHolders(){
        assert(msg.sender == holderA || msg.sender == holderB);
        _;
    }
    
    modifier onlyA(){
        assert(msg.sender == holderA);
        _;
    }
    
    function(){
        //this contract is not greedy, should not hold any value.
        throw;
    }
    
    function ShopKeeper(address other){
        shop = new ValueTrader();
        holderA = msg.sender;
        holderB = other;
    }
    
    function giveAwayOwnership(address newHolder) onlyHolders {
        if(msg.sender == holderB){
            holderB = newHolder;
        } else {
            holderA = newHolder;
        }
    }
    
    function splitProfits(){
        uint256 unprocessedProfit = shop.balanceOf(this);
        uint256 equalShare = unprocessedProfit/2;
        assert(shop.transfer(holderA,equalShare));
        assert(shop.transfer(holderB,equalShare));
    }
    
    //Management interface below
    
    function toggleDrain() onlyA {
        shop.toggleDrain();
    }
    
    function toggleBurn() onlyA {
        shop.toggleBurn();
    }
    
    function die() onlyA {
        shop.die();
    }
    
    function validateToken(address token_, uint256 bP_, uint256 bL_, uint256 pF_) onlyHolders {
        shop.validateToken(token_,bP_,bL_,pF_);
    }
    
    function configureTokenDividend(address token_, bool hD_, address dA_, bytes dD_) onlyA {
        shop.configureTokenDividend(token_,hD_,dA_,dD_);
    }
    
    function callDividend(address token_) onlyA {
        shop.callDividend(token_);
    }
    
    function invalidateToken(address token_) onlyHolders {
        shop.invalidateToken(token_);
    }
    
    function changeOwner(address owner_) onlyA {
        if(holderB == holderA){ 
            //if holder has full ownership, they can discard this management contract
            shop.changeOwner(owner_); 
        }
        holderA = owner_;
    }
    
    function changeShop(address newShop) onlyA {
        if(holderB == holderA){
            //if holder has full ownership, they can reengage the shop contract
            shop = ValueTrader(newShop);
        }
    }
    
    function changeFee(uint256 tradeFee) onlyHolders {
        shop.changeFee(tradeFee);
    }
    
    function changeEtherContract(address eC) onlyHolders {
        shop.changeEtherContract(eC);
    }
}

//this contract should be holderB in the shopKeeper contract.
contract ProfitContainerAdapter is SafeMath{
    
    address owner;
    address shopLocation;
    address shopKeeperLocation;
    address profitContainerLocation;
    
    modifier owned(){
        assert(msg.sender == owner);
        _;
    }
    
    function changeShop(address newShop) owned {
        shopLocation = newShop;
    }
    
    
    function changeKeeper(address newKeeper) owned {
        shopKeeperLocation = newKeeper;
    }
    
    
    function changeContainer(address newContainer) owned {
        profitContainerLocation = newContainer;
    }
    
    function ProfitContainerAdapter(address sL, address sKL, address pCL){
        owner = msg.sender;
        shopLocation = sL;
        shopKeeperLocation = sKL;
        profitContainerLocation = pCL;
    }
    
    function takeEtherProfits(){
        ShopKeeper(shopKeeperLocation).splitProfits();
        ValueTrader shop = ValueTrader(shopLocation);
        shop.buyEther(shop.balanceOf(this));
        assert(profitContainerLocation.call.value(this.balance)());
    }
    
    //warning: your profit container needs to be able to handle tokens or this is lost forever
    function takeTokenProfits(address token){
        ShopKeeper(shopKeeperLocation).splitProfits();
        ValueTrader shop = ValueTrader(shopLocation);
        shop.buyToken(token,shop.balanceOf(this));
        assert(Token(token).transfer(profitContainerLocation,Token(token).balanceOf(this)));
    }
    
    function giveAwayHoldership(address holderB) owned {
        ShopKeeper(shopKeeperLocation).giveAwayOwnership(holderB);
    }
    
    function giveAwayOwnership(address newOwner) owned {
        owner = newOwner;
    }
    
}