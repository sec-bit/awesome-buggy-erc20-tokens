pragma solidity ^0.4.11;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract PylonToken is owned {
    // Public variables of the token
    string public standard = "Pylon Token - The first decentralized energy exchange platform powered by renewable energy";
    string public name = 'Pylon Token';
    string public symbol = 'PYLNT';
    uint8 public decimals = 18;
    uint256 public totalSupply = 3750000000000000000000000;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public frozenAccount;

    // This notifies about accounts locked
    event FrozenFunds(address target, bool frozen);

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    using SafeMath for uint256;

    address public beneficiary = 0xAE0151Ca8C9b6A1A7B50Ce80Bf7436400E22b535;  //Chip-chap Klenergy Address of ether beneficiary account
    uint256 public fundingGoal = 21230434782608700000000;     // Foundig goal in weis = 21230,434782608700000000 Ethers
    uint256 public amountRaised;    // Quantity of weis investeds
    uint256 public deadline; // durationInMinutes * 60 / 17 + 5000;        // Last moment to invest
    uint256 public price = 6608695652173910;           // Ether cost of each token in weis 0,006608695652173910 ethers

    uint256 public totalTokensToSend = 3250000000000000000000000; // Total tokens offered in the total ICO

    uint256 public maxEtherInvestment = 826086956521739000000; //Ethers. To mofify the day when starts crowdsale, equivalent to 190.000€ = 826,086956521739000000 ether
    uint256 public maxTokens = 297619047619048000000000; // 297,619.047619048000000000 PYLNT = 190.000 € + 56% bonus

    uint256 public bonusCap = 750000000000000000000000; // 750,000.000000000000000000 PYLNT last day before Crowdsale as 1,52€/token
    uint256 public pylonSelled = 0;

    uint256 public startBlockBonus;

    uint256 public endBlockBonus1;

    uint256 public endBlockBonus2;

    uint256 public endBlockBonus3;

    uint256 public qnt10k = 6578947368421050000000; // 6,578.947368421050000000 PYLNT = 10.000 €

    bool fundingGoalReached = false; // If founding goal is reached or not
    bool crowdsaleClosed = false;    // If crowdsale is closed or open

    event GoalReached(address deposit, uint256 amountDeposited);
    event FundTransfer(address backer, uint256 amount, bool isContribution);
    event LogQuantity(uint256 _amount, string _message);

    // Chequear
    uint256 public startBlock = getBlockNumber();

    bool public paused = false;

    //uint256 public balanceInvestor;
    //uint256 public ultimosTokensEntregados;

    modifier contributionOpen() {
        require(getBlockNumber() >= startBlock && getBlockNumber() <= deadline);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    function crowdsale() onlyOwner{
        paused = false;
    }

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param investor who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed investor, uint256 value, uint256 amount);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function PylonToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        address centralMinter,
        address ifSuccessfulSendTo,
        uint256 fundingGoalInWeis,
        uint256 durationInMinutes,
        uint256 weisCostOfEachToken
    ) {
        if (centralMinter != 0) owner = centralMinter;

        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes

        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInWeis;
        startBlock = getBlockNumber();
        startBlockBonus = getBlockNumber();
        endBlockBonus1 = getBlockNumber() + 15246 + 12600 + 500;    // 3 days + 35,5h + margen error = 15246 + 12600 + 500
        endBlockBonus2 = getBlockNumber() + 30492 + 12600 + 800;    // 6 days + 35,5h + margen error = 30492 + 12600 + 800
        endBlockBonus3 = getBlockNumber() + 45738 + 12600 + 1100;   // 9 days + 35,5h + margen error = 45738 + 12600 + 1100
        deadline = getBlockNumber() + (durationInMinutes * 60 / 17) + 5000; // durationInMinutes * 60 / 17 + 12600 + 5000 = Calculo bloques + margen error
        price = weisCostOfEachToken;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] >= _value);                // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other ccount
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) onlyOwner returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }

    /**
     * Mine new tokens
     *
     * Mine `mintedAmount` tokens from the system to send to the `target`.
     * This function will only be used from a future contract to invest in new renewable installations
     *
     * @param target the address of the recipient
     * @param mintedAmount the amount of money to send
     */
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }

    /**
     * Lock or unlock accounts
     *
     * Lock or unlock `target` accounts which don't use the token correctly.
     *
     * @param target the address of the locked or unlicked account
     * @param freeze if this account has to be freeze or not
     */
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable notPaused{
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address investor) payable notPaused {
        require (!crowdsaleClosed); // Check if crowdsale is open or not
        require(investor != 0x0);  // Check the address
        require(validPurchase()); //Validate the transfer
        require(maxEtherInvestment >= msg.value); //Check if It's more than maximum to invest
        require(balanceOf[investor] <= maxTokens); // Check if the investor has more tokens than 5% of total supply
        require(amountRaised <= fundingGoal); // Check if fundingGoal is rised
        require(pylonSelled <= totalTokensToSend); //Check if pylons we have sell is more or equal than total tokens ew have


        //Check if It's time for pre ICO or ICO
        if(startBlockBonus <= getBlockNumber() && startBlock <= getBlockNumber() && endBlockBonus3 >= getBlockNumber() && pylonSelled <= bonusCap){
          buyPreIco(investor);
        } else if(deadline >= getBlockNumber()){
          buyIco(investor);
        }

    }

    function buyIco(address investor) internal{
      uint256 weiAmount = msg.value;

      // calculate token amount to be sent
      uint256 tokens = weiAmount.mul(10**18).div(price);

      require((balanceOf[investor] + tokens) <= maxTokens);         // Check if the investor has more tokens than 5% of total supply
      require(balanceOf[this] >= tokens);             // checks if it has enough to sell
      require(pylonSelled + tokens <= totalTokensToSend); //Overflow - Check if pylons we have sell is more or equal than total tokens ew have

      balanceOf[this] -= tokens;
      balanceOf[investor] += tokens;
      amountRaised += weiAmount; // update state amount raised
      pylonSelled += tokens; // Total tokens selled

      beneficiary.transfer(weiAmount); //Transfer ethers to beneficiary

      frozenAccount[investor] = true;
      FrozenFunds(investor, true);

      TokenPurchase(msg.sender, investor, weiAmount, tokens);
    }

    function buyPreIco(address investor) internal{
      uint256 weiAmount = msg.value;

      uint256 bonusPrice = 0;
      uint256 tokens = weiAmount.mul(10**18).div(price);

      if(endBlockBonus1 >= getBlockNumber()){
        if(tokens == qnt10k.mul(19) ){
          bonusPrice = 2775652173913040;
        }else if(tokens >= qnt10k.mul(18) && tokens < qnt10k.mul(19)){
          bonusPrice = 2907826086956520;
        }else if(tokens >= qnt10k.mul(17) && tokens < qnt10k.mul(18)){
          bonusPrice = 3040000000000000;
        }else if(tokens >= qnt10k.mul(16) && tokens < qnt10k.mul(17)){
          bonusPrice = 3172173913043480;
        }else if(tokens >= qnt10k.mul(15) && tokens < qnt10k.mul(16)){
          bonusPrice = 3304347826086960;
        }else if(tokens >= qnt10k.mul(14) && tokens < qnt10k.mul(15)){
          bonusPrice = 3436521739130430;
        }else if(tokens >= qnt10k.mul(13) && tokens < qnt10k.mul(14)){
          bonusPrice = 3568695652173910;
        }else if(tokens >= qnt10k.mul(12) && tokens < qnt10k.mul(13)){
          bonusPrice = 3700869565217390;
        }else if(tokens >= qnt10k.mul(11) && tokens < qnt10k.mul(12)){
          bonusPrice = 3833043478260870;
        }else if(tokens >= qnt10k.mul(10) && tokens < qnt10k.mul(11)){
          bonusPrice = 3965217391304350;
        }else if(tokens >= qnt10k.mul(9) && tokens < qnt10k.mul(10)){
          bonusPrice = 4097391304347830;
        }else if(tokens >= qnt10k.mul(8) && tokens < qnt10k.mul(9)){
          bonusPrice = 4229565217391300;
        }else if(tokens >= qnt10k.mul(7) && tokens < qnt10k.mul(8)){
          bonusPrice = 4361739130434780;
        }else if(tokens >= qnt10k.mul(6) && tokens < qnt10k.mul(7)){
          bonusPrice = 4493913043478260;
        }else if(tokens >= qnt10k.mul(5) && tokens < qnt10k.mul(6)){
          bonusPrice = 4626086956521740;
        }else{
          bonusPrice = 5286956521739130;
        }
      }else if(endBlockBonus2 >= getBlockNumber()){
        if(tokens == qnt10k.mul(19) ){
          bonusPrice = 3436521739130430;
        }else if(tokens >= qnt10k.mul(18) && tokens < qnt10k.mul(19)){
          bonusPrice = 3568695652173910;
        }else if(tokens >= qnt10k.mul(17) && tokens < qnt10k.mul(18)){
          bonusPrice = 3700869565217390;
        }else if(tokens >= qnt10k.mul(16) && tokens < qnt10k.mul(17)){
          bonusPrice = 3833043478260870;
        }else if(tokens >= qnt10k.mul(15) && tokens < qnt10k.mul(16)){
          bonusPrice = 3965217391304350;
        }else if(tokens >= qnt10k.mul(14) && tokens < qnt10k.mul(15)){
          bonusPrice = 4097391304347830;
        }else if(tokens >= qnt10k.mul(13) && tokens < qnt10k.mul(14)){
          bonusPrice = 4229565217391300;
        }else if(tokens >= qnt10k.mul(12) && tokens < qnt10k.mul(13)){
          bonusPrice = 4361739130434780;
        }else if(tokens >= qnt10k.mul(11) && tokens < qnt10k.mul(12)){
          bonusPrice = 4493913043478260;
        }else if(tokens >= qnt10k.mul(10) && tokens < qnt10k.mul(11)){
          bonusPrice = 4626086956521740;
        }else if(tokens >= qnt10k.mul(9) && tokens < qnt10k.mul(10)){
          bonusPrice = 4758260869565220;
        }else if(tokens >= qnt10k.mul(8) && tokens < qnt10k.mul(9)){
          bonusPrice = 4890434782608700;
        }else if(tokens >= qnt10k.mul(7) && tokens < qnt10k.mul(8)){
          bonusPrice = 5022608695652170;
        }else if(tokens >= qnt10k.mul(6) && tokens < qnt10k.mul(7)){
          bonusPrice = 5154782608695650;
        }else if(tokens >= qnt10k.mul(5) && tokens < qnt10k.mul(6)){
          bonusPrice = 5286956521739130;
        }else{
          bonusPrice = 5947826086956520;
        }
      }else{
        if(tokens == qnt10k.mul(19) ){
          bonusPrice = 3766956521739130;
        }else if(tokens >= qnt10k.mul(18) && tokens < qnt10k.mul(19)){
          bonusPrice = 3899130434782610;
        }else if(tokens >= qnt10k.mul(17) && tokens < qnt10k.mul(18)){
          bonusPrice = 4031304347826090;
        }else if(tokens >= qnt10k.mul(16) && tokens < qnt10k.mul(17)){
          bonusPrice = 4163478260869570;
        }else if(tokens >= qnt10k.mul(15) && tokens < qnt10k.mul(16)){
          bonusPrice = 4295652173913040;
        }else if(tokens >= qnt10k.mul(14) && tokens < qnt10k.mul(15)){
          bonusPrice = 4427826086956520;
        }else if(tokens >= qnt10k.mul(13) && tokens < qnt10k.mul(14)){
          bonusPrice = 4560000000000000;
        }else if(tokens >= qnt10k.mul(12) && tokens < qnt10k.mul(13)){
          bonusPrice = 4692173913043480;
        }else if(tokens >= qnt10k.mul(11) && tokens < qnt10k.mul(12)){
          bonusPrice = 4824347826086960;
        }else if(tokens >= qnt10k.mul(10) && tokens < qnt10k.mul(11)){
          bonusPrice = 4956521739130430;
        }else if(tokens >= qnt10k.mul(9) && tokens < qnt10k.mul(10)){
          bonusPrice = 5088695652173910;
        }else if(tokens >= qnt10k.mul(8) && tokens < qnt10k.mul(9)){
          bonusPrice = 5220869565217390;
        }else if(tokens >= qnt10k.mul(7) && tokens < qnt10k.mul(8)){
          bonusPrice = 5353043478260870;
        }else if(tokens >= qnt10k.mul(6) && tokens < qnt10k.mul(7)){
          bonusPrice = 5485217391304350;
        }else if(tokens >= qnt10k.mul(5) && tokens < qnt10k.mul(6)){
          bonusPrice = 5617391304347830;
        }else{
          bonusPrice = 6278260869565220;
        }
      }

      tokens = weiAmount.mul(10**18).div(bonusPrice);

      require(pylonSelled + tokens <= bonusCap); // Check if want to sell more than total tokens for pre-ico
      require(balanceOf[investor] + tokens <= maxTokens); // Check if the investor has more tokens than 5% of total supply
      require(balanceOf[this] >= tokens);             // checks if it has enough to sell

      balanceOf[this] -= tokens;
      balanceOf[investor] += tokens;
      amountRaised += weiAmount; // update state amount raised
      pylonSelled += tokens; // Total tokens selled

      beneficiary.transfer(weiAmount); //Transfer ethers to beneficiary

      frozenAccount[investor] = true;
      FrozenFunds(investor, true);

      TokenPurchase(msg.sender, investor, weiAmount, tokens);

    }

    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() afterDeadline onlyOwner {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        uint256 current = getBlockNumber();
        bool withinPeriod = current >= startBlock && current <= deadline;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    //////////
    // Testing specific methods
    //////////

    /// @notice This function is overridden by the test Mocks.
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

    /// @notice Pauses the contribution if there is any issue
    function pauseContribution() onlyOwner {
        paused = true;
    }

    /// @notice Resumes the contribution
    function resumeContribution() onlyOwner {
        paused = false;
    }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}